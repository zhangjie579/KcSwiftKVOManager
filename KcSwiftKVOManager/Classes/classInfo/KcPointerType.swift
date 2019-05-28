//
//  KcPointerType.swift
//  test - 011
//
//  Created by 张杰 on 2019/5/27.
//  Copyright © 2019 张杰. All rights reserved.
//

import UIKit

/// 用户获取class、struct的info
protocol KcPointerType : Equatable {
    associatedtype Pointee
    var pointer: UnsafePointer<Pointee> { get set }
}

extension KcPointerType {
    init<T>(pointer: UnsafePointer<T>) {
        func cast<T, U>(_ value: T) -> U {
            return unsafeBitCast(value, to: U.self)
        }
        self = cast(UnsafePointer<Pointee>(pointer))
    }
}

func == <T: KcPointerType>(lhs: T, rhs: T) -> Bool {
    return lhs.pointer == rhs.pointer
}

protocol ContextDescriptorType: KcPointerType {
    /// 对象头部的meta属性的offset
    var contextDescriptorOffsetLocation: Int { get }
    static var kind: Metadata.Kind? { get }
    
    func propertyDescriptions() -> [Property.Description]?
}

extension ContextDescriptorType {
    /// 根据pointer确定对象的类型
    var kind: Metadata.Kind {
        return Metadata.Kind(flag: UnsafePointer<Int>(pointer).pointee)
    }
    
    init?(anyType: Any.Type) {
        self.init(pointer: unsafeBitCast(anyType, to: UnsafePointer<Int>.self))
        if let kind = type(of: self).kind, kind != self.kind {
            return nil
        }
    }
}

extension ContextDescriptorType {
    
    /// 对象头部的meta属性(包含: class的信息)
    var contextDescriptor: ContextDescriptorProtocol? {
        let pointer = UnsafePointer<Int>(self.pointer)
        let base = pointer.advanced(by: contextDescriptorOffsetLocation)
        if base.pointee == 0 {
            // swift class created dynamically in objc-runtime didn't have valid contextDescriptor
            return nil
        }
        if self.kind == .class {
            return ContextDescriptor<_ClassContextDescriptor>(pointer: relativePointer(base: base, offset: base.pointee - Int(bitPattern: base)))
        } else {
            return ContextDescriptor<_StructContextDescriptor>(pointer: relativePointer(base: base, offset: base.pointee - Int(bitPattern: base)))
        }
    }
    
    /// property的个数
    var numberOfFields: Int {
        return contextDescriptor?.numberOfFields ?? 0
    }
    
    /// property的offset
    var fieldOffsets: [Int]? {
        guard let contextDescriptor = contextDescriptor else {
            return nil
        }
        let vectorOffset = contextDescriptor.fieldOffsetVector
        guard vectorOffset != 0 else {
            return nil
        }
        if self.kind == .class {
            return (0..<contextDescriptor.numberOfFields).map {
                return UnsafePointer<Int>(pointer)[Int(vectorOffset + $0)]
            }
        } else {
            return (0..<contextDescriptor.numberOfFields).map {
                return Int(UnsafePointer<Int32>(pointer)[Int(vectorOffset * (Mirror.is64BitPlatform ? 2 : 1) + $0)])
            }
        }
    }
}

func relativePointer<T, U, V>(base: UnsafePointer<T>, offset: U) -> UnsafePointer<V> where U : FixedWidthInteger {
    return UnsafeRawPointer(base).advanced(by: Int(integer: offset)).assumingMemoryBound(to: V.self)
}

extension Int {
    fileprivate init<T : FixedWidthInteger>(integer: T) {
        switch integer {
        case let value as Int: self = value
        case let value as Int32: self = Int(value)
        case let value as Int16: self = Int(value)
        case let value as Int8: self = Int(value)
        default: self = 0
        }
    }
}




