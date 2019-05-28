//
//  KcSwiftKVOHandelAbnormalDefault.swift
//  test - 011
//
//  Created by 张杰 on 2019/5/28.
//  Copyright © 2019 张杰. All rights reserved.
//

import UIKit

// MARK: - KcSwiftKVOHandleAbnormalable 处理kvo处理异常的情况protocol
public struct KcSwiftKVOHandelAbnormalDefault: KcSwiftKVOHandleAbnormalable {
    public init() {}
}

public protocol KcSwiftKVOHandleAbnormalable {
    func kc_setValue(_ value: Any?, forUndefinedKey key: String)
    @discardableResult
    func kc_value(forUndefinedKey key: String) -> Any?
}

extension KcSwiftKVOHandleAbnormalable {
    @discardableResult
    public func kc_value(forUndefinedKey key: String) -> Any? {
        #if DEBUG
        fatalError(key)
        #else
        print(key)
        return nil
        #endif
    }
    
    public func kc_setValue(_ value: Any?, forUndefinedKey key: String) {
        #if DEBUG
        fatalError(key)
        #else
        print(key)
        #endif
    }
}
