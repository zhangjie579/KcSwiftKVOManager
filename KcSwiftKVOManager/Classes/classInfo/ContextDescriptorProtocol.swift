//
//  ContextDescriptorProtocol.swift
//  test - 011
//
//  Created by 张杰 on 2019/5/27.
//  Copyright © 2019 张杰. All rights reserved.
//  class、struct的meta对象(关于对象descriptor)

import UIKit

protocol ContextDescriptorProtocol {
    /// property的个数
    var numberOfFields: Int { get }
    var fieldOffsetVector: Int { get }
}

// 包装的class、struct的信息
struct ContextDescriptor<T: _ContextDescriptorProtocol>: ContextDescriptorProtocol, KcPointerType {
    
    var pointer: UnsafePointer<T>
    
    /// property的个数
    var numberOfFields: Int {
        return Int(pointer.pointee.numberOfFields)
    }
    
    var fieldOffsetVector: Int {
        return Int(pointer.pointee.fieldOffsetVector)
    }
}

protocol _ContextDescriptorProtocol {
    var mangledName: Int32 { get }
    /// 个数
    var numberOfFields: Int32 { get }
    /// 偏移量
    var fieldOffsetVector: Int32 { get }
    var fieldTypesAccessor: Int32 { get }
}

struct _StructContextDescriptor: _ContextDescriptorProtocol {
    var flags: Int32
    var parent: Int32
    var mangledName: Int32
    var fieldTypesAccessor: Int32
    var numberOfFields: Int32
    var fieldOffsetVector: Int32
}

struct _ClassContextDescriptor: _ContextDescriptorProtocol {
    var flags: Int32
    var parent: Int32
    var mangledName: Int32
    var fieldTypesAccessor: Int32
    var superClsRef: Int32
    var reservedWord1: Int32
    var reservedWord2: Int32
    var numImmediateMembers: Int32
    var numberOfFields: Int32
    var fieldOffsetVector: Int32
}


// 获取属性name, type
// 用于这func没公开, 需要这样声明
@_silgen_name("swift_getFieldAt")
func _getFieldAt(
    _ type: Any.Type,
    _ index: Int,
    _ callback: @convention(c) (UnsafePointer<CChar>, UnsafeRawPointer, UnsafeMutableRawPointer) -> Void,
    _ ctx: UnsafeMutableRawPointer
)
