//
//  KcClassInfo.swift
//  test - 011
//
//  Created by 张杰 on 2019/5/22.
//  Copyright © 2019 张杰. All rights reserved.
//

import UIKit

struct KcClassInfo {}

extension KcClassInfo {
    struct _Class {
        var kind: Int
        var superclass: Any.Type?
        var reserveword1: Int
        var reserveword2: Int
        var databits: UInt
        // other fields we don't care
        
        var classFlags: UInt32
        var instanceAddressPoint: UInt32
        var instanceSize: UInt32
        var instanceAlignmentMask: UInt16
        var runtimeReservedField: UInt16
        var classObjectSize: UInt32
        var classObjectAddressPoint: UInt32
        var nominalTypeDescriptor: Int
        var ivarDestroyer: Int
        
        func class_rw_t() -> UnsafePointer<_class_rw_t>? {
            if MemoryLayout<Int>.size == MemoryLayout<Int64>.size {
                let fast_data_mask: UInt64 = 0x00007ffffffffff8
                let databits_t: UInt64 = UInt64(self.databits)
                return UnsafePointer<_class_rw_t>(bitPattern: UInt(databits_t & fast_data_mask))
            } else {
                return UnsafePointer<_class_rw_t>(bitPattern: self.databits & 0xfffffffc)
            }
        }
    }
    
    // class、struct、wrapper的meta对象(class的信息offset、count)
    struct _class_rw_t {
        var flags: Int32
        var version: Int32
        var ro: UInt
        // other fields we don't care
        
        func class_ro_t() -> UnsafePointer<_class_ro_t>? {
            return UnsafePointer<_class_ro_t>(bitPattern: self.ro)
        }
    }
    
    struct _class_ro_t {
        var flags: Int32
        // 这个是正确的当前class的第1个属性的offset，不管继承自swift class还是NSObject, 而且已经算上了class前面12、16的meta对象的内存0
        // 有super已经算上去了
        var instanceStart: Int32
        // 当前class所占的内存，包括super
        var instanceSize: Int32
        
        /// Only supports 64-bit
        var reserved: UInt32
    
        var ivarLayout: UnsafePointer<CChar>
        // 类名
        var name: UnsafePointer<CChar>
        var baseMethodList: Int
        var baseProtocols: Int
        // 成员变量列表
        var ivars: UnsafePointer<Ivar>
        var weakIvarLayout: UnsafePointer<CChar>
        var baseProperties: Int
    }
    
    struct Ivar {
        var type: UInt32
        var offset: UnsafePointer<CChar>
        var name: UnsafePointer<CChar>
        var alignment_raw: UInt32
        var size: UInt32
    }
}

extension KcClassInfo {
    struct _Struct {
        var kind: Int
        var contextDescriptorOffset: Int
        var parent: Metadata?
        
    }
}

extension KcClassInfo {
    class Property {
        var name: String?
        var type: Any.Type?
    }
}

public struct Property {
    let key: String
    let value: Any
    
    /// An instance property description
    public struct Description: Hashable {
        
        public let keyPath: String
        public let type: Any.Type
        public let offset: Int
        
        public var hashValue: Int {
            return keyPath.hashValue
        }
        
        public func write(_ value: Any, to storage: UnsafeMutableRawPointer) throws {
            return try kc_AnyExtensionType(of: type).write(value, to: storage.advanced(by: offset))
        }
        
        public func value(storage: UnsafeMutableRawPointer) -> Any {
            return kc_AnyExtensionType(of: type).read(from: storage.advanced(by: offset))
        }
        
        public static func == (lhs: Property.Description, rhs: Property.Description) -> Bool {
            return lhs.keyPath == rhs.keyPath
        }
    }
}
