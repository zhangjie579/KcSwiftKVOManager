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
}

public extension Collection {
    /// 第几个满足predicate的索引
    func kc_index(where predicate: (Element) throws -> Bool, generations: Int) rethrows -> Index? {
        var count = 0
        var index = startIndex
        while index < endIndex {
            if try predicate(self[index]) {
                count += 1
                if generations == count {
                    return index
                }
            }
            formIndex(after: &index)
        }
        return nil
    }
    
    /// 满足这个条件predicate的Character有多少个
    func kc_count(where predicate: (Element) throws -> Bool) rethrows -> Int? {
        var count = 0
        var index = startIndex
        while index < endIndex {
            if try predicate(self[index]) {
                count += 1
            }
            formIndex(after: &index)
        }
        return count
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

