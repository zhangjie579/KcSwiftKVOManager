//
//  Metadata.swift
//  test - 011
//
//  Created by 张杰 on 2019/5/27.
//  Copyright © 2019 张杰. All rights reserved.
//  Class、struct、optional的class info

import UIKit

public struct Metadata {}

extension Metadata {
    struct Class: ContextDescriptorType {
        typealias Pointee = KcClassInfo._Class
        static var kind: Metadata.Kind? = .class
        
        var pointer: UnsafePointer<KcClassInfo._Class>
        
        var contextDescriptorOffsetLocation: Int {
            return Mirror.is64BitPlatform ? 8 : 11
        }
        
        /// 是否为swift class
        var isSwiftClass: Bool {
            get {
                let lowbit = self.pointer.pointee.databits & 1
                return lowbit == 1
            }
        }
        
        var superclass: Class? {
            guard let superClass = pointer.pointee.superclass else {
                return nil
            }
            return Metadata.Class(anyType: superClass)
        }
        
        /// 对象定义属性的第1个属性的offset
        var instanceStart: Int? {
            guard let instanceStart = pointer.pointee.class_rw_t()?.pointee.class_ro_t()?.pointee.instanceStart else {
                return nil
            }
            return Int(instanceStart)
        }
        
        func _propertyDescriptionsAndStartPoint() -> ([Property.Description], Int?)? {
            // 1.这个是正确的当前class的第1个属性的offset，不管继承自swift class还是NSObject, 而且已经算上了class前面12、16的meta对象的内存0
            var result: [Property.Description] = []
            let selfType = unsafeBitCast(self.pointer, to: Any.Type.self)
            if let offsets = self.fieldOffsets {
                for i in 0..<self.numberOfFields {
                    var nameAndType = KcClassInfo.Property()
                    Metadata.kc_propertyValue(classType: selfType, index: i, property: &nameAndType)
                    if let name = nameAndType.name, let type = nameAndType.type {
                        result.append(Property.Description(keyPath: name, type: type, offset: offsets[i]))
                    }
                }
            }
            
            /// 如果super也有property, 也add
            if let superclass = superclass {
                // ignore the root swift object
                let superclassName = String(describing: unsafeBitCast(superclass.pointer, to: Any.Type.self))
                if superclassName != "SwiftObject" && !superclassName.hasPrefix("NS") && !superclassName.hasPrefix("UI"), let superclassProperties = superclass._propertyDescriptionsAndStartPoint(),
                    superclassProperties.0.count > 0 {
                    return (superclassProperties.0 + result, superclassProperties.1)
                }
            }
            return (result, instanceStart)
        }
        
        func propertyDescriptions() -> [Property.Description]? {
            // 1.获取对象的property信息，注意⚠️offset可能不正确，如果继承自NSObject就不对
            let propsAndStp = _propertyDescriptionsAndStartPoint()
            // 2.跳转offset,  instanceStart这个是正确的第1个property的offset
            if let firstInstanceStart = propsAndStp?.1,
                // 对象第1个property的offset
                let firstProperty = propsAndStp?.0.first?.offset {
                return propsAndStp?.0.map{ (propertyDesc) in
                    /*
                     1.propertyDesc.offset - firstProperty求的是上一个对象的size
                     2.firstInstanceStart才是正确的第1个property的offset
                     */
                    // 这才是正确的offset
                    let offset = propertyDesc.offset - firstProperty + Int(firstInstanceStart)
                    return Property.Description(keyPath: propertyDesc.keyPath, type: propertyDesc.type, offset: offset)
                }
            } else {
                return propsAndStp?.0
            }
        }
    }
}

// MARK: - Struct
extension Metadata {
    struct Struct : ContextDescriptorType {
        static let kind: Kind? = .struct
        var pointer: UnsafePointer<KcClassInfo._Struct>
        
        var contextDescriptorOffsetLocation: Int {
            return 1
        }
        
        func propertyDescriptions() -> [Property.Description]? {
            guard let fieldOffsets = fieldOffsets else {
                return nil
            }
            var result: [Property.Description] = []
            let selfType = unsafeBitCast(self.pointer, to: Any.Type.self)
            for i in 0..<numberOfFields {
                var property = KcClassInfo.Property()
                Metadata.kc_propertyValue(classType: selfType, index: i, property: &property)
                if let name = property.name, let type = property.type {
                    result.append(Property.Description(keyPath: name, type: type, offset: fieldOffsets[i]))
                }
            }
            return result
        }
    }
}

// MARK: ObjcClassWrapper
extension Metadata {
    struct ObjcClassWrapper: ContextDescriptorType {
        typealias Pointee = KcClassInfo._ObjcClassWrapper
        static let kind: Kind? = .objCClassWrapper
        
        var pointer: UnsafePointer<KcClassInfo._ObjcClassWrapper>
        var contextDescriptorOffsetLocation: Int {
            return Mirror.is64BitPlatform ? 8 : 11
        }
        
        var targetType: Any.Type? {
            get {
                return pointer.pointee.targetType
            }
        }
        
        func propertyDescriptions() -> [Property.Description]? {
            return nil
        }
    }
}

extension KcClassInfo {
    struct _ObjcClassWrapper {
        var kind: Int
        var targetType: Any.Type?
    }
}

extension Metadata {
    /// 通过系统方法获取property的name、type
    static func kc_propertyValue(classType: Any.Type, index: Int, property: inout KcClassInfo.Property) {
        _getFieldAt(classType, index, { (name, type, nameAndTypePtr) in
            let name = String(cString: name)
            let type = unsafeBitCast(type, to: Any.Type.self)
            let nameAndType = nameAndTypePtr.assumingMemoryBound(to: KcClassInfo.Property.self).pointee
            nameAndType.name = name
            nameAndType.type = type
        }, &property)
    }
    
    /// 获取属性list(属性的keyPath: 只是key没有前缀)
    public static func getProperties(forType type: Any.Type) -> [Property.Description]? {
        if let structDescriptor = Metadata.Struct(anyType: type) {
            return structDescriptor.propertyDescriptions()
        } else if let classDescriptor = Metadata.Class.init(anyType: type) {
            return classDescriptor.propertyDescriptions()
        } else if let objcClassDescriptor = Metadata.ObjcClassWrapper(anyType: type),
            let targetType = objcClassDescriptor.targetType {
            return getProperties(forType: targetType)
        }
        return nil
    }
}

// MARK: - Kind
extension Metadata {
    /// 对象的类型
    enum Kind {
        case `struct`
        case `enum`
        case optional
        case opaque
        case tuple
        case function
        case existential
        case metatype
        case objCClassWrapper
        case existentialMetatype
        case foreignClass
        case heapLocalVariable
        case heapGenericLocalVariable
        case errorObject
        case `class`
        init(flag: Int) {
            switch flag {
            case 1: self = .struct
            case 2: self = .enum
            case 3: self = .optional
            case 8: self = .opaque
            case 9: self = .tuple
            case 10: self = .function
            case 12: self = .existential
            case 13: self = .metatype
            case 14: self = .objCClassWrapper
            case 15: self = .existentialMetatype
            case 16: self = .foreignClass
            case 64: self = .heapLocalVariable
            case 65: self = .heapGenericLocalVariable
            case 128: self = .errorObject
            default: self = .class
            }
        }
    }
}
