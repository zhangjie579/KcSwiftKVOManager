//
//  KcSwiftKVO.swift
//  test - 011
//
//  Created by 张杰 on 2019/5/21.
//  Copyright © 2019 张杰. All rights reserved.
//

import UIKit

/*
 1.不需要所有的class、struct、enum都遵守KcSwiftKVOAnyExtensionable
 * 只需要keyPath对应的value遵守即可
 * classInfo是借鉴的handyJSON, 不过它也只能处理key，不能keyPath
 */

public enum KcSwiftKVOManager<T> {
    /// 结构体的指针
    case value(UnsafeMutablePointer<T>)
    /// 对象
    case objc(T)
}

// MARK: - 通过class info/mirror获取property然后kvo
public extension KcSwiftKVOManager {
    /// 设置value, keyPath: a.b.c
    func setValue(throughtType: Mirror.KcGetPropertyListType = .classInfo,
                  handleAbnormal: KcSwiftKVOHandleAbnormalable = KcSwiftKVOHandelAbnormalDefault(),
                  value: Any,
                  forKeyPath keyPath: String) {
        let propertyList = Mirror.kc_classPropertyList(throughtType: throughtType, contentValue: self.value)
        _setValue(value: value, forKeyPath: keyPath, propertyList: propertyList, handleAbnormal: handleAbnormal)
    }
    
    /// 获取value, keyPath: a.b.c
    //    @_specialize(where U == Any, T == Any)
    func value(throughtType: Mirror.KcGetPropertyListType = .classInfo,
               handleAbnormal: KcSwiftKVOHandleAbnormalable = KcSwiftKVOHandelAbnormalDefault(),
               forKeyPath keyPath: String) -> Any? {
        let propertyList = Mirror.kc_classPropertyList(throughtType: throughtType, contentValue: value)
        return _value(forKeyPath: keyPath, propertyList: propertyList, handleAbnormal: handleAbnormal)
    }
}

private extension KcSwiftKVOManager {
    func _setValue(value: Any,
                   forKeyPath keyPath: String,
                   propertyList: [Property.Description],
                   handleAbnormal: KcSwiftKVOHandleAbnormalable = KcSwiftKVOHandelAbnormalDefault()) {
        let contentValue = self.value
        handleKeyPathForKVO(contentValue: contentValue, keyPath: keyPath, propertyList: propertyList, nextClosure: { (property, pointer, content) in
            content = pointer.kc_value(forKey: property.keyPath, type: property.type, offset: property.offset)
            pointer = nextPorpertyPointer(with: pointer, offset: property.offset, isClassOfCurrentProperty: Mirror.kc_isClass(type: property.type))
        }, finishClosure: { (property, pointer) in
            do {
                try pointer.kc_setValue(value: value, offset: property.offset)
            } catch {
                handleAbnormal.kc_setValue(value, forUndefinedKey: error as? String ?? "")
            }
        }, objcClosure: { (objc, keyPath) in
            objc.setValue(value, forKeyPath: keyPath)
        }) { (keyPath, key, any) in
            handleAbnormal.kc_setValue(value, forUndefinedKey: "keyPath: \(keyPath) \n, 找不到key: \(key) \n, value: \(any)")
        }
    }
    
    func _value(forKeyPath keyPath: String,
                propertyList: [Property.Description],
                handleAbnormal: KcSwiftKVOHandleAbnormalable = KcSwiftKVOHandelAbnormalDefault()) -> Any? {
        var result: Any? = nil
        let contentValue = self.value
        handleKeyPathForKVO(contentValue: contentValue, keyPath: keyPath, propertyList: propertyList, nextClosure: { (property, pointer, content) in
            content = pointer.kc_value(forKey: property.keyPath, type: property.type, offset: property.offset)
            pointer = nextPorpertyPointer(with: pointer, offset: property.offset, isClassOfCurrentProperty: Mirror.kc_isClass(type: property.type))
        }, finishClosure: { (property, pointer) in
            result = pointer.kc_value(forKey: property.keyPath, type: property.type, offset: property.offset)
        }, objcClosure: { (objc, keyPath) in
            result = objc.value(forKeyPath: keyPath)
        }) { (keyPath, key, any) in
            handleAbnormal.kc_value(forUndefinedKey: "keyPath: \(keyPath) \n, 找不到key: \(key) \n, value: \(any)")
        }
        return result
    }
    
    /// 处理kvo从propertyList
    ///
    /// - Parameters:
    ///   - contentValue: 需要kvo的对象
    ///   - keyPath: keyPath
    ///   - propertyList: property list属性列表
    ///   - nextClosure: 下一级处理，更新UnsafeMutableRawPointer、Any
    ///   - finishClosure: kvo处理
    ///   - objcClosure: objc的kvo处理
    ///   - notFoundClosure: 没有找到的处理 String: keyPath, String: 找不到的key, Any: 找不到key属性的对象
    func handleKeyPathForKVO(contentValue: Any,
                                      keyPath: String,
                                      propertyList: [Property.Description],
                                      nextClosure: (Property.Description, inout UnsafeMutableRawPointer, inout Any) -> Void,
                                      finishClosure: (Property.Description, UnsafeMutableRawPointer) -> Void,
                                      objcClosure: (NSObject, String) -> Void,
                                      notFoundClosure: (String, String, Any) -> Void) {
        /// 包括key、_key
        func isContain(set: Set<String>, key: String) -> Bool {
            if set.contains(key) {
                return true
            }
            if key.hasPrefix("_"), let index = key.index(key.startIndex, offsetBy: 1, limitedBy: key.endIndex), set.contains(String(key[index...])) {
                return true
            }
            if set.contains("_" + key) {
                return true
            }
            return false
        }
        // 1.keyPath: [a, b, c] -> keyArray: [a, a.b, a.b.c]
        let keyArray = transformKeyPath(keyPath)
        var pointer = tuple.point
        /// 为了处理下一级是NSObject的情况
        var content = contentValue
        // 2.
        for (index, key) in keyArray.enumerated() {
            if let property = propertyList.first(where: { $0.keyPath == key }) {
                if index == keyArray.count - 1 {
                    // 4.
                    finishClosure(property, pointer)
                }
                else {
                    // 3.
                    nextClosure(property, &pointer, &content)
                }
            }
            else {
                // 5.是否为NSObject子类
                let instanceIsNsObject = Mirror.kc_isNSObjectSubClass(value: content)
                // 6.dict中包含父类NSObject的属性列表, Set
                let bridgedPropertyList = Mirror.bridgedPropertyList(value: content)
                let key = keyPath.lazy.split(separator: ".")[index...].joined(separator: ".")
                // 7.系统定义的NSObject子类是否有这个属性
                if instanceIsNsObject,
                    let objc = content as? NSObject,
                    isContain(set: bridgedPropertyList, key: String(key)) {
                    objcClosure(objc, String(key))
                }
                else {
                    notFoundClosure(keyPath, String(key), content)
                    // print("keyPath: \(keyPath) \n, 找不到key: \(String(key)) \n, value: \(content)")
                }
            }
        }
    }
    
    /// 获取contentValue的property list
    func classPropertyList(contentValue: Any) -> [Property.Description] {
        /// 把key转换成keyPath
        func propertyKeyPath(prefix: String, key: String) -> String {
            return prefix == "" ? key : prefix + "." + key
        }
        
        var propertyList = [Property.Description]()
        let mirror = Mirror(reflecting: contentValue)
        // 前缀
        var keyPrefix = ""
        mirror.kc_classPropertyListHandle(reflecting: contentValue, handldSelf: { content in
            if content.isBegin, let properties = Metadata.getProperties(forType: content.contentMirror.subjectType), !properties.isEmpty {
                if let index = content.keyPath.lastIndex(of: ".") {
                    keyPrefix = String(content.keyPath[..<index])
                }
                propertyList.append(contentsOf: properties.lazy.map { Property.Description(keyPath: propertyKeyPath(prefix: keyPrefix, key: $0.keyPath), type: $0.type, offset: $0.offset) })
            }
        })
        return propertyList
    }
}

public extension KcSwiftKVOManager {
    var value: Any {
        switch self {
        case .value(let valuePoint):
            return valuePoint.pointee
        case .objc(let object):
            return object
        }
    }
    
    var tuple: (point: UnsafeMutableRawPointer, isClass: Bool) {
        let tuple: (point: UnsafeMutableRawPointer, isClass: Bool)
        let p = UnsafeMutableRawPointer.headPointer(value: self)
        switch self {
        case .value:
            tuple = (point: p, isClass: false)
        case .objc:
            tuple = (point: p, isClass: false)
        }
        return tuple
    }
}

extension KcSwiftKVOManager {
    /// keyPath转换， 比如a.b.c -> [a, a.b, a.b.c]
    func transformKeyPath(_ keyPath: String) -> [String] {
        var keyArray = [String]()
        var index = keyPath.startIndex
        while index != keyPath.endIndex {
            let c = String(keyPath[index])
            if c == "." {
                keyArray.append(String(keyPath[..<index]))
            }
            index = keyPath.index(after: index)
            if index == keyPath.endIndex {
                keyArray.append(keyPath)
            }
        }
        return keyArray
    }
    
    /// 通过当前pointer和到下一个point的offter，获取下一个属性的pointer
    ///
    /// - Parameters:
    ///   - currentPoint: 当前属性pointer
    ///   - offset: 当前属性到下一个属性的地址偏移量offset
    ///   - isClass: 当前属性是否为class
    /// - Returns: 下一个属性的pointer
    func nextPorpertyPointer(with currentPoint: UnsafeMutableRawPointer,
                             offset: Int,
                             isClassOfCurrentProperty: Bool) -> UnsafeMutableRawPointer {
        // 如果当前属性为class, 获取它下面的属性, 这个pointer就需要重写绑定到新类型(bindMemory)
        // 如果为struct, 只需要叠加offset即可
        switch isClassOfCurrentProperty {
        case true:
            let p = currentPoint.advanced(by: offset).assumingMemoryBound(to: AnyObject.self)
            // 不能到这处理p.pointee as? NSObject的情况，如果它是NSObject, but是使用者自己定义的属性，没有用dynamic修饰，走kvc会crash
            return UnsafeMutableRawPointer.headPointer(value: .objc(p.pointee))
        case false:
            return currentPoint.advanced(by: offset)
        }
    }
}
