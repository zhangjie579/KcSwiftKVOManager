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

        test1()
    }

    private func test1() {
        let label = UILabel()
        let a = Four()
//        let b = Mirror.kc_classPropertyList(throughtType: .mirror, contentValue: a)
//        b.forEach {
//            print("key: \($0.keyPath), offset: \($0.offset)")
//        }
        
        var kvo = KcSwiftKVOManager.objc(a)
//        let dict = ["i1": "kc_i1", "i2": "kc_i2", "i3": 13, "i4": 14,
//                    "i5": "kc_i5", "i6": "kc_i6", "i7": "kc_i7", "i8": 18,
//                    "two.i5": "two_i5", "two.i6": "two.i6", "two.i7": "two.i7",
//                    "f1.i1": "f1.i1", "f1.i2": "f1.i2", "f1.i3": 33, "f1.i4": 34,
//                    "f1.i5": 35,
//                    "f1.i6": "f1.i6", "f1.i7": "f1.i7"
//            ] as [String : Any]
//
//        dict.forEach {
//            kvo.setValue(throughtType: .classInfo, value: $0.value, forKeyPath: $0.key)
////            kvo = KcSwiftKVOManager.objc(a)
//        }
        kvo.setValue(throughtType: .classInfo, value: 14, forKeyPath: "f1.i4")
        kvo.setValue(throughtType: .classInfo, value: 145, forKeyPath: "f1.i5")
        kvo.setValue(throughtType: .classInfo, value: "lyh_i6", forKeyPath: "f1.i6")
        print(a.f1.i5)
        print(a.i6)
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
    }
    
    struct Three {
        var s1: Int = 10
        var s2: Int32 = 11
        var s3: String? = "s3"
    }
    
    class Four: Two {
        var i8: Int = 8
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
