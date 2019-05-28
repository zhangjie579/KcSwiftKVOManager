//
//  MemoryLayout-extension.swift
//  test - 011
//
//  Created by 张杰 on 2019/5/28.
//  Copyright © 2019 张杰. All rights reserved.
//

import UIKit

public extension MemoryLayout {
    /// 内存对齐
    static func kc_layoutAlign(offset: Int, alignment: Int) -> Int {
        guard alignment != 0 else { return offset }
        let leave = offset % alignment
        if leave != 0 {
            return (offset / alignment + 1) * alignment
        }
        return offset
    }
    
    /// 求value内存的size和alignment
    static func kc_offset(value: Any) -> (size: Int, alignment: Int) {
        let anyType = kc_AnyExtensionType(value: value)
        return (size: anyType.size, alignment: anyType.alignment)
    }
}
