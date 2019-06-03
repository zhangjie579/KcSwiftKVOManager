//
//  TwoViewController.swift
//  KcSwiftKVOManager_Example
//
//  Created by 张杰 on 2019/6/1.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import KcSwiftKVOManager

class TwoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        test2()
    }

    private func test1() {
        let a = Four()
        
        let kvo = KcSwiftKVOManager.objc(a)
        let dict = ["i1": "kc_i1", "i2": "kc_i2", "i3": 13, "i4": 14,
                    "i5": "kc_i5", "i6": "kc_i6", "i7": "kc_i7", "i8": 18,
                    "two.i5": "two_i5", "two.i6": "two.i6", "two.i7": "two.i7",
                    "f1.i1": "f1.i1", "f1.i2": "f1.i2", "f1.i3": 33, "f1.i4": 34,
                    "f1.i5": 35,
                    "f1.i6": "f1.i6", "f1.i7": "f1.i7"
            ] as [String : Any]

        dict.forEach {
            kvo.setValue(throughtType: .classInfo, value: $0.value, forKeyPath: $0.key)
//            kvo = KcSwiftKVOManager.objc(a)
        }
        kvo.setValue(throughtType: .mirror, value: 18, forKeyPath: "i8")
        kvo.setValue(throughtType: .mirror, value: 145, forKeyPath: "f1.i5")
        kvo.setValue(throughtType: .mirror, value: 987, forKeyPath: "two.a1.b")
        print(a.f1.i5)
        print(a.i6)
        print("------")
    }
    
    /// 元祖
    private func test2() {
        let a = Four()
        var kvo = KcSwiftKVOManager.objc(a)
        
        kvo.setValue(throughtType: .classInfo, value: ("kc.i9", 119), forKeyPath: "i9")
        kvo.setValue(throughtType: .classInfo, value: (a: "kc.izz", b: 120), forKeyPath: "two.a1")
        kvo.setValue(throughtType: .mirror, value: "lyh.i9", forKeyPath: "i9.0")
        kvo.setValue(throughtType: .mirror, value: 100, forKeyPath: "i9.1")
        kvo.setValue(throughtType: .mirror, value: 18, forKeyPath: "i8")
        kvo.setValue(throughtType: .mirror, value: 145, forKeyPath: "f1.i5")
        kvo.setValue(throughtType: .mirror, value: "two.a1.a", forKeyPath: "two.a1.a")
        kvo.setValue(throughtType: .mirror, value: 987, forKeyPath: "two.a1.b")
        print("------")
    }
}

extension TwoViewController {
    class One: UIView {
        var i1: String? = "i1"      // 16   480
        var i2: String? = "i2"      // 16   496
        var i3: Int? = 3            // 9    512
        var i4: Int32 = 4           // 4    524
    }
    
    class Two: One {
        var i5: String = "i5"
        var i6: String = "i6"
//        var a1: Three = Three()
        var i7: String? = "i7"
        
        var a1: (a: String, b: Int?) = (a: "a1", b: 1)
    }
    
    struct Three {
        var s1: Int = 10
        var s2: Int32 = 11
        var s3: String? = "s3"
    }
    
    class Four: Two {
        var i8: Int = 8
        var i9: (String, Int?) = ("i9", 9)
        var f1: Five = Five()
        var two: Two = Two()
    }
    
    struct Five {
        var i1: String? = "i1"      // 16   480
        var i2: String? = "i2"      // 16   496
        var i3: Int? = 3            // 9    512
        var i4: Int32 = 4           // 4    524
        var i5: Int = 5
        var i6: String = "i6"
        //        var a1: Three = Three()
        var i7: String? = "i7"
    }
}


