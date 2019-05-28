//
//  Other-extension.swift
//  test - 011
//
//  Created by 张杰 on 2019/5/28.
//  Copyright © 2019 张杰. All rights reserved.
//

import UIKit

public extension UnsafeMutableRawPointer {
    // 获取实例起始指针
    static func headPointer<T>(value: KcSwiftKVOManager<T>) -> UnsafeMutableRawPointer {
        switch value {
        case .objc(let object):
            let object = object as AnyObject
            let p = Unmanaged.passRetained(object).toOpaque()
                .bindMemory(to: UInt8.self, capacity: MemoryLayout<T>.stride)
            return UnsafeMutableRawPointer(p)
        case .value(let p):
            let pointer = UnsafeMutableRawPointer(p)
                .bindMemory(to: UInt8.self, capacity: MemoryLayout<T>.stride)
            return UnsafeMutableRawPointer(pointer)
        }
        
    }
    
    func kc_setValue(value: Any, offset: Int = 0) throws {
        try kc_AnyExtensionType(of: type(of: value))
            .write(value, to: advanced(by: offset))
    }
    
    func kc_value(forKey key: String, type: Any.Type, offset: Int = 0) -> KcSwiftKVOAnyExtensionable {
        return kc_AnyExtensionType(of: type)
            .read(from: advanced(by: offset))
    }
}

/// 让string遵守error
extension String: Error { }

public extension String {
    /// string -> AnyClass
    var anyClassType: AnyClass? {
        if let classType = NSClassFromString(self) {
            return classType
        }
        let projectName = Bundle.kc_bundleName() ?? ""
        return NSClassFromString(projectName + "." + self)
    }
    
    /// value的类型 [Array, Optional, String]
    static func kc_classTypeToArray(value: Any) -> [String] {
        let typeString = "\(type(of: value))"
        // 1.没有>, 说明是单类型，既不是optional, 也不是[], [:]
        guard let firstIndex = typeString.firstIndex(of: ">") else {
            return [typeString]
        }
        // 2.Optional<Array<Optional<String>>>, 只截取到>的前一个, 然后通过<, 把它们分隔开  [Optional, Array, Optional, String]
        let arrayString = String(typeString[typeString.startIndex..<firstIndex])
            .split(separator: "<").map(String.init)
        return arrayString
    }
    
    /// [String?]?
    /// String, Optional<String>, Array<Optional<String>>, Optional<Array<Optional<String>>>
    /// 用空格替换< >, 然后分成数组, optional用?替代
    static func kc_classType(value: Any) -> String {
        let typeString = "\(type(of: value))"
        // 1.没有>, 说明是单类型，既不是optional, 也不是[], [:]
        guard typeString.firstIndex(of: ">") != nil else {
            return typeString
        }
        // 2.Optional<Array<Optional<String>>>, 只截取到>的前一个, 然后通过<, 把它们分隔开  [Optional, Array, Optional, String]
        let arrayString = String.kc_classTypeToArray(value: value)
        //        var typeResult = "?[]"
        var typeResult = ""
        // 3.从后开始遍历，一层一层处理, 因为最后一层是最里面的type
        for string in arrayString.reversed() {
            if string == "Optional" {
                typeResult = typeResult + "?"
            }
            else if string == "Array" {
                typeResult = "[" + typeResult + "]"
            }
            else {
                typeResult += string
            }
        }
        return typeResult
    }
}

public extension Bundle {
    /// 获取工程的名字
    class func kc_bundleName() -> String? {
        //这里也是坑，请不要翻译oc的代码，而是去NSBundle类里面看它的api
        guard var appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String else {
            return nil
        }
        var index = appName.startIndex
        while index != appName.endIndex {
            if appName[index] == " " || appName[index] == "-" {
                appName.replaceSubrange(index..<appName.index(after: index), with: "_")
            }
            index = appName.index(after: index)
        }
        return appName
    }
}

extension UnsafePointer {
    init<T>(_ pointer: UnsafePointer<T>) {
        self = UnsafeRawPointer(pointer).assumingMemoryBound(to: Pointee.self)
    }
}

