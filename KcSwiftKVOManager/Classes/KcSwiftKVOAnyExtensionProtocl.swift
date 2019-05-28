//
//  KcSwiftKVOAnyExtensionProtocl.swift
//  test - 011
//
//  Created by 张杰 on 2019/5/23.
//  Copyright © 2019 张杰. All rights reserved.
//  为了获取Any.Type的MemoryLayout信息

import UIKit

/// 由于UnsafeMutableRawPointer.assumingMemoryBound使用参数property.type: Any.Type会报错，直接传Any.Type获取value也会错，so用这个
public protocol KcSwiftKVOAnyExtensionable {}

public extension KcSwiftKVOAnyExtensionable {
    /// 求内存
    static var stride: Int {
        return MemoryLayout<Self>.stride
    }
    
    static var alignment: Int {
        return MemoryLayout<Self>.alignment
    }
    
    static var size: Int {
        return MemoryLayout<Self>.size
    }
    
    static func write(_ value: Any, to storage: UnsafeMutableRawPointer) throws {
        guard let this = value as? Self else {
            throw "类型转换失败, \(type(of: value))无法转为\(Self.self)"
        }
        storage.assumingMemoryBound(to: self).pointee = this
    }
    
    static func read(from storage: UnsafeMutableRawPointer) -> Self {
        let p = storage.assumingMemoryBound(to: self)
        return p.pointee
    }
}

public func kc_AnyExtensionType(value: Any) -> KcSwiftKVOAnyExtensionable.Type {
    return kc_AnyExtensionType(of: type(of: value))
}

public func kc_AnyExtensionType(of type: Any.Type) -> KcSwiftKVOAnyExtensionable.Type {
    struct ExtensionType: KcSwiftKVOAnyExtensionable { }
    var extensions: KcSwiftKVOAnyExtensionable.Type = ExtensionType.self
    // 修改extensions的指针 👍
    withUnsafePointer(to: &extensions) { pointer in
        UnsafeMutableRawPointer(mutating: pointer).assumingMemoryBound(to: Any.Type.self).pointee = type
    }
    return extensions
}

