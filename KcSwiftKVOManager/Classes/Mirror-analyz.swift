//
//  Mirror-analyz.swift
//  test - 011
//
//  Created by 张杰 on 2019/5/23.
//  Copyright © 2019 张杰. All rights reserved.
//  获取property list

import UIKit

// MARK: - Mirror

/*
 1.属性
    * 属性: super + self; 协议protocol自己会加进去, 不用管
 2.MemoryLayout
    * size: 对象的占用空间
    * stride: 实际长度
         * 在一个 T 类型的数组中，其中任意一个元素从开始地址到结束地址所占用的连续内存字节的大小就是 stride
         * stride - size 个字节则为每个元素因为内存对齐而浪费的内存空间
    * alignment: 对齐模数
        * 要求当前数据类型相对于起始位置的偏移必须是alignment的整数倍
            * 比如前面已经占了20个了，而后面属性的alignment是8，so需要填充到24开始),so 类/结构体的成员声明顺序会影响占用空间
        * 对齐原则: 任何 K 字节的地址必须是 K 的倍数
             * 内存对齐是内存的优化
             * 内存大的变量写在前面，小的写在后面
        * MemoryLayout.offset(of: \kcTestP2.d1)获取d1偏移量，参数为keyPath👍
 3.内存
     * super + self，父类的字段在前
     * class 前面还有几个内存是meta(类型信息，引用计数), 32位 4 + 8， 64位 8 + 8，后8位是meta
         * 属性为class占8个
         * 属性为struct - 占的内存数就是这个结构体的内存数(struct属性内存之和)⚠️
         * optional需要在当前占内存的基础上再 + 1
         * 需要考虑内存对齐: 起始地址为alignment的倍数
         * 单个对象最大内存为16，不包括struct(它可以n个)
    * var i: 结构体、类..., 这个东西的属性的地址与self无关
 4.通过self，得出self.name(name可能是结构体可能是class)的指针
    * 作用: 这样就可以获取、修改属性下属性的value
    1. name是struct
        * name的第1个属性的地址是self的地址 + name的偏移地址offset
    2. name是class, class不是NSObject的子类
         * let point = p1.assumingMemoryBound(to: AnyObject.self)
         * 如果是UIView等等知道的类型，可以直接用point.pointee.属性名 = value来修改
         * let p4 = UnsafeMutableRawPointer.headPointerOfClass(value: point.pointee)
         * 再找到合适的地址偏移量offset，需要class前面还有几个内存
         * p5.initialize(to: ";lyh")
    3. name是class, class是NSObject的子类
         * 其实与普通的继承一样，都是class的属性在后，NSObject的在前
         * NSObject的所有变量所占的内存大小: class_getInstanceSize(AnyClass?), 这也是自定义继承自objc class的第1个property offset
    4.Array是连续型存储的，与c语言的一种，都是获取的第1个element的指针，后面的指针只需要加上对应的offset，为n * 类型的size
 作用
     * 可以获取属性的值
     * 不管是let还是var修饰都可以修改value👍👍👍
     * 这个是MemoryLayout.stride(ofValue: i3))属性实际占用的内存
     * 注意需要直接使用属性value来计算，而不能用let a = value来计算，因为它是值类型⚠️⚠️⚠️
     * 其实大小就是对于classType的MemoryLayout.stride，比如int，float类型…
 */

public extension Mirror {
    
    /// 是否为class
    static func kc_isClass(value: Any) -> Bool {
        return kc_isClass(type: type(of: value))
    }
    
    /// 是否为class
    static func kc_isClass(type: Any.Type) -> Bool {
        return type is AnyClass
    }
    
    /// 是否为NSObject 子类
    static func kc_isNSObjectSubClass(value: Any) -> Bool {
        return kc_isNSObjectSubClass(classType: type(of: value))
    }
    
    /// 是否为NSObject 子类
    static func kc_isNSObjectSubClass(classType: Any.Type) -> Bool {
        return classType is NSObject.Type
    }
    
    /// 是否为自定义的class
    static func kc_isCustomClass(for aClass: AnyClass) -> Bool {
        let bundle = Bundle.init(for: aClass)
        return bundle == Bundle.main
    }
    
    /// 对象地址的开始偏移offset
    static func kc_classStartOffset(with value: Any) -> Int {
        if kc_isClass(value: value) {
            return is64BitPlatform ? 16 : 12
        }
        return 0
    }
    
    /// 是否为64位
    static var is64BitPlatform: Bool {
        return MemoryLayout<Int>.size == MemoryLayout<Int64>.size
    }
    
    var hasChildren: Bool {
        return !children.isEmpty
    }
    
    var hasSuper: Bool {
        return superclassMirror != nil
    }
    
    /// 有child或者super
    var hasChildOrSuper: Bool {
        return hasChildren || hasSuper
    }
    
    /// 对象是否为optional
    var isOptionalValue: Bool {
        return displayStyle == .optional
    }
    
    /// 去反射value的可选值的mirror: 当反射value为optional, 它为value去optional的mirror
    var mirror_filterOptionalReflectValue: Mirror {
        if isOptionalValue {
            for (key, value) in children where key == "some" {
                return Mirror(reflecting: value)
            }
        }
        return self
    }
    
    /// 获取AnyClass的size
    static func kc_clasInstanceSize(anyClass: AnyClass?) -> Int {
        return class_getInstanceSize(anyClass)
    }
    
    /// 属性在对象中所占内存
    static func sizeof(type: Any.Type) -> Int {
        // 对象不管可选不可选就是8个字节, struct需要计算
        if Mirror.kc_isClass(type: type) {
            return 8
        }
        else {
            return kc_AnyExtensionType(of: type).size
        }
    }
}

// MARK: - 遍历对象的属性、获取property list
public extension Mirror {
    /// 通过哪种类型来获取property list
    public enum KcGetPropertyListType {
        /// 通过class info获取property list
        case classInfo
        /// 通过mirror获取
        case mirror
    }
    
    /// 获取property list
    static func kc_classPropertyList(throughtType: KcGetPropertyListType = .classInfo, contentValue: Any) -> [Property.Description] {
        switch throughtType {
        case .classInfo:
            return kc_classPropertyListThroughClassInfo(contentValue: contentValue)
        case .mirror:
            return kc_classPropertyListThroughMirror(reflecting: contentValue)
        }
    }
    
    /// 获取对象属性list
    ///
    /// - Parameter valueKeyPath: 最开始属性的key, 默认为""
    /// - Returns: 属性list
    func kc_classPropertyList(valueKeyPath: String = "") -> [Property.Description] {
        // 1.处理reflecting是optional
        if displayStyle == .optional {
            for (key, value) in children where key == "some" {
                return Mirror.kc_classPropertyListThroughMirror(reflecting: value, valueKeyPath: valueKeyPath)
            }
        }
        // 2.instanceStartOffset
        var instanceStartOffset = 0
        if Mirror.kc_isClass(type: subjectType) {
            instanceStartOffset = Mirror.is64BitPlatform ? 16 : 12
        }
        return _kc_classPropertyList(instanceStartOffset: &instanceStartOffset, valueKeyPath: valueKeyPath)
    }
    
    /// 处理superclassMirror
    ///
    /// - Parameters:
    ///   - handleObjcClass: superclass是NSObject; Bool: 是否为系统的class、false为自定义的class
    ///   - handleSwiftClass: superclass是自定义的swift class
    func superclassMirrorHandle(handleSystemObjcClass: (Mirror, AnyClass) -> Void,
                                handleSwiftClass: (Mirror, Any.Type) -> Void) {
        if let superclassMirror = superclassMirror {
            /* 2.不处理objc系统的class
             * 是AnyClass - 说明是类
             * kc_isNSObjectSubClass: 是NSObject的子类,
             * !kc_isCustomClass: 不是自定义方法 - 是objc系统的class
             */
            // super是NSObject的子类, 并且是系统的class
            if let anyClass = superclassMirror.subjectType as? AnyClass,
                Mirror.kc_isNSObjectSubClass(classType: superclassMirror.subjectType),
                !Mirror.kc_isCustomClass(for: anyClass) {
                handleSystemObjcClass(superclassMirror, anyClass)
            }
            else if String(describing: superclassMirror.subjectType) != "SwiftObject" {
                handleSwiftClass(superclassMirror, superclassMirror.subjectType)
            }
        }
    }
    
    public struct KcHandleContent {
        public let keyPath: String
        public let value: Any
        /// 属性的容器的mirror
        public let contentMirror: Mirror
        public let mirror: Mirror
        /// 是否为同一个class内遍历的开始
        public let isBegin: Bool
        /// 是否为同一个class内遍历的结束
        public let isEnd: Bool
    }
    
    func kc_classPropertyListHandle(startKey: String = "",
                                    enableHandleObjcSystemClass: Bool = false,
                                    isHandleSuperClass: Bool = false) -> [KcHandleContent] {
        let mirror = mirror_filterOptionalReflectValue
        return mirror._kc_classPropertyListHandle(startKey: startKey, enableHandleObjcSystemClass: enableHandleObjcSystemClass, isHandleSuperClass: isHandleSuperClass, contentMirror: mirror)
    }
}

private extension Mirror {
    
    /// 获取contentValue的property list - 通过class info
    static func kc_classPropertyListThroughClassInfo(contentValue: Any) -> [Property.Description] {
        var propertyList = [Property.Description]()
        let mirror = Mirror(reflecting: contentValue)
        // 前缀
        var keyPrefix = ""
//        mirror.mirror_filterOptionalReflectValue
        let handleArrays = mirror.kc_classPropertyListHandle()
        handleArrays.forEach { content in
            // 由于Metadata.getProperties得到的是这个type下面的所有属性，so只需要传入这个type的第1个属性即可
            if content.isBegin, let properties = Metadata.getProperties(forType: content.contentMirror.subjectType), !properties.isEmpty {
                if let index = content.keyPath.lastIndex(of: ".") {
                    keyPrefix = String(content.keyPath[..<index])
                }
                propertyList.append(contentsOf: properties.lazy.map { Property.Description(keyPath: propertyKeyPath(prefix: keyPrefix, key: $0.keyPath), type: $0.type, offset: $0.offset) })
            }
                // 属性是元祖tuple
            else if content.mirror.mirror_filterOptionalReflectValue.displayStyle == .tuple {
                let tuplePropertyList = kc_classPropertyList(throughtType: .mirror, contentValue: content.value)
                propertyList.append(contentsOf: tuplePropertyList)
            }
        }
        return propertyList
    }
    
    /// 获取对象属性list - 通过mirror
    ///
    /// - Parameters:
    ///   - reflecting: 获取属性的对象
    ///   - valueKeyPath: 最开始属性的key, 默认为""
    /// - Returns: 属性list
    static func kc_classPropertyListThroughMirror(reflecting: Any, valueKeyPath: String = "") -> [Property.Description] {
        let mirror = Mirror(reflecting: reflecting)
        return mirror.kc_classPropertyList(valueKeyPath: valueKeyPath)
    }
    
    func _kc_classPropertyList(instanceStartOffset : inout Int, valueKeyPath: String) -> [Property.Description] {
        /// 求value的内存size, 并把currentOffset对齐
        ///
        /// - Parameters:
        ///   - value: 对象
        ///   - currentOffset: 当前的offset
        /// - Returns: value的内存size
        func memoryLayoutAlignmentAndValueSize(with value: Any, currentOffset: inout Int) -> Int {
            // 1.求value的(size: Int, alignment: Int)
            let layout = MemoryLayout<Any>.kc_offset(value: value)
            // 2.currentOffset内存对齐得出的offset
            currentOffset = MemoryLayout<Any>.kc_layoutAlign(offset: currentOffset, alignment: layout.alignment)
            return layout.size
        }
        
//        func keyPath(startKey: String, key: String) -> String {
//            return startKey == "" ? key : startKey + "." + key
//        }
        
        var propertyList = [Property.Description]()
        
        // 1.有super
        superclassMirrorHandle(handleSystemObjcClass: { (superMirror, anyClass) in
            instanceStartOffset = class_getInstanceSize(anyClass)
        }) { (superclassMirror, type) in
            let superProperties = superclassMirror._kc_classPropertyList(instanceStartOffset: &instanceStartOffset, valueKeyPath: valueKeyPath)
            if !superProperties.isEmpty {
                propertyList.append(contentsOf: superProperties)
            }
        }
        
        // 2.child
        for (key, value) in children {
            guard let key = key, key != "some", key != "" else { continue }
            let name = Mirror.propertyKeyPath(prefix: valueKeyPath, key: key)
//            let name = keyPath(startKey: valueKeyPath, key: key)
            let childMirror = Mirror(reflecting: value)
            // 3.instanceStartOffset内存对齐，并返回value的size
            let valueSize = memoryLayoutAlignmentAndValueSize(with: value, currentOffset: &instanceStartOffset)
            let propertyInfo = Property.Description.init(keyPath: name, type: childMirror.subjectType, offset: instanceStartOffset)
            propertyList.append(propertyInfo)
            //            print("key: \(propertyInfo.keyPath), offset: \(propertyInfo.offset), type: \(propertyInfo.type)")
            
            
            // 4.更新instanceStartOffset(对象占8个内存, 结构体size就是valueSize)
            instanceStartOffset += Mirror.kc_isClass(type: childMirror.subjectType) ? 8 : valueSize
            
            // 5.child中child
            guard !childMirror.children.isEmpty else { continue }
            let grandChildProperties = childMirror.kc_classPropertyList(valueKeyPath: name)
            if !grandChildProperties.isEmpty {
                propertyList.append(contentsOf: grandChildProperties)
            }
        }
        return propertyList
    }
    
    /// 遍历property (有属性返回true), isAlreadyAddPropertyInValue这个对象没有属性
    private func _kc_classPropertyListHandle(startKey: String = "",
                                             enableHandleObjcSystemClass: Bool = false,
                                             isHandleSuperClass: Bool = false,
                                             contentMirror: Mirror) -> [KcHandleContent] {
        func keyPath(startKey: String, key: String) -> String {
            return startKey == "" ? key : startKey + "." + key
        }
        
        var results = [KcHandleContent]()
        
        // 1.superMirror
        superclassMirrorHandle(handleSystemObjcClass: { (superclassMirror, anyClass) in
            if enableHandleObjcSystemClass {
                let superResults = superclassMirror._kc_classPropertyListHandle(startKey: startKey, enableHandleObjcSystemClass: enableHandleObjcSystemClass, isHandleSuperClass: true, contentMirror: contentMirror)
                results.append(contentsOf: superResults)
            }
        }) { (superclassMirror, type) in
            let superResults = superclassMirror._kc_classPropertyListHandle(startKey: startKey, enableHandleObjcSystemClass: enableHandleObjcSystemClass, isHandleSuperClass: true, contentMirror: contentMirror)
            results.append(contentsOf: superResults)
        }
        
        /// 处理property list
        ///
        /// - Parameters:
        ///   - isHandleSuperClass: 是否是处理super的property list, false的话是处理自己的
        func handelPropertyList(isHandleSuperClass: Bool) {
            // 2.到这说明没有super了
            for (index, element) in children.enumerated() {
                guard let key = element.label, key != "some", key != "" else { continue }
                let value = element.value
                let name = keyPath(startKey: startKey, key: key)
                let childMirror = Mirror(reflecting: value)
                
                // 3.不管有没有child、super都先处理自己
                let isEnd = isHandleSuperClass ? false : index == children.count - 1
                let isBegin: Bool
                // 判断同一个对象的族簇有没有添加过property
                if !results.isEmpty || superclassMirror?.children.isEmpty == false { // 已经添加过了 || super的children不为空
                    isBegin = false
                } else {
                    isBegin = index == 0 ? true : false
                }
                
                let handleContent = KcHandleContent.init(keyPath: name, value: value, contentMirror: contentMirror, mirror: childMirror, isBegin: isBegin, isEnd: isEnd)
                print("key: \(handleContent.keyPath), isBegin: \(handleContent.isBegin), isEnd: \(handleContent.isEnd),  self: \(self), content: \(contentMirror)")
                results.append(handleContent)
                
                // 4.处理superclassMirror、children
                if childMirror.superclassMirror != nil || !childMirror.children.isEmpty {
                    let childResults = childMirror.kc_classPropertyListHandle(startKey: name, enableHandleObjcSystemClass: enableHandleObjcSystemClass, isHandleSuperClass: false)
                    //                print("childmirror: \(childMirror), childResults: \(childResults.count)")
                    results.append(contentsOf: childResults)
                }
            }
        }
        handelPropertyList(isHandleSuperClass: isHandleSuperClass)
        // 2.到这说明处理好了super了的
        return results
    }
    
    /// 把key转换成keyPath
    static func propertyKeyPath(prefix: String, key: String) -> String {
        // 当key是tuple(元祖)的时候key为.0、.name, 后面加了., so需要去掉
        let key = key.replacingOccurrences(of: ".", with: "")
        return prefix == "" ? key : prefix + "." + key
    }
}

// MARK: - class_copyPropertyList获取属性
public extension Mirror {
    /// 通过class_copyPropertyList获取属性list
    static func bridgedPropertyList(value: Any) -> Set<String> {
        if let anyClass = type(of: value) as? AnyClass {
            return _bridgedPropertyList(anyClass: anyClass)
        }
        return []
    }
    
    private static func _bridgedPropertyList(anyClass: AnyClass) -> Set<String> {
        var propertyList = Set<String>()
        // 1.有super、但是super不是NSObject
        if let superClass = class_getSuperclass(anyClass), superClass != NSObject.self {
            propertyList = propertyList.union(_bridgedPropertyList(anyClass: superClass))
        }
        // 2.super是NSObject
        let count = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        if let props = class_copyPropertyList(anyClass, count) {
            for i in 0 ..< count.pointee {
                let name = String(cString: property_getName(props.advanced(by: Int(i)).pointee))
                propertyList.insert(name)
            }
            free(props)
        }
        #if swift(>=4.1)
        count.deallocate()
        #else
        count.deallocate(capacity: 1)
        #endif
        return propertyList
    }
}
