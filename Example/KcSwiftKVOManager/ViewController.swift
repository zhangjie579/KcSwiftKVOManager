//
//  ViewController.swift
//  KcSwiftKVOManager
//
//  Created by zhangjie on 05/28/2019.
//  Copyright (c) 2019 zhangjie. All rights reserved.
//

import UIKit
import KcSwiftKVOManager

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        test1()
        
    }
    
    /// 通过mirror kvo
    func test1() {
        var a = KcThree1()
        var kvo = KcSwiftKVOManager.value(&a)
        
        let dict = ["s1": "s1",
                    "t1.i1": "t1.i1",
                    "t1.i2": "t1.i2",
                    "t1.i3": 3,
                    "t1.i4": 4,
                    "t1.i5": 5,
                    "t1.tag": 1001,
                    "t4.view": 1,
                    "s2": 23,
                    "t2.i1": "t2.i1",
                    "t2.i2": "t2.i2",
                    "t2.i3": 17,
                    "t2.i4": 27,
                    "t2.i5": 37,
                    "o1": "o1",
                    "t4.s1": 1,
                    "t4.s3": 30,
                    "t4.s4": "t4.s4",
                    "t5": 5
            ] as [String : Any]
        dict.forEach {
            let v = $0.value
            kvo.setValue(throughtType: .mirror, value: v, forKeyPath: $0.key)
            kvo = KcSwiftKVOManager.value(&a)
            
            let value = kvo.value(throughtType: .mirror, forKeyPath: $0.key)
            print("key: \($0.key), value: \(value)")
        }
        print(a)
        print("-------")
    }
    
    /// 通过class info kvo
    func test2() {
        var a = KcThree1()
        var kvo = KcSwiftKVOManager.value(&a)
        
        let dict = ["s1": "s1",
                    "t1.i1": "t1.i1",
                    "t1.i2": "t1.i2",
                    "t1.i3": 3,
                    "t1.i4": 4,
                    "t1.i5": 5,
                    "t1.tag": 1001,
                    "s2": 23,
                    "t2.i1": "t2.i1",
                    "t2.i2": "t2.i2",
                    "t2.i3": 17,
                    "t2.i4": 27,
                    "t2.i5": 37,
                    "o1": "o1",
                    "t4.s1": 1,
                    "t4.s3": 30,
                    "t4.s4": "t4.s4",
                    "t5": 5
            ] as [String : Any]
        dict.forEach {
            kvo.setValue(value: $0.value, forKeyPath: $0.key)
            kvo = KcSwiftKVOManager.value(&a)
            
            let value = kvo.value(forKeyPath: $0.key)
            print("key: \($0.key), value: \(value)")
        }
        print(a)
        print("-------")
    }
    
    /// 获取Property.Description
    func test3() {
        var a = KcThree1()
        let mirror = Mirror(reflecting: a)
        
        
        var propertyList = [Property.Description]()
        mirror.kc_classPropertyListHandle(reflecting: a, handldSelf: { content in
            if content.isBegin, let properties = Metadata.getProperties(forType: content.contentMirror.subjectType) {
                propertyList.append(contentsOf: properties)
            }
        })
        
        propertyList.forEach {
            print("key: \($0.keyPath), offset:\($0.offset), type: \($0.type)")
        }
        
        print("-------")
    }
}

protocol KcThreeProtocol1 {
    var s1: String { get set }
    var s2: Int { get set }
}

struct KcThree1: KcThreeProtocol1 {
    enum T: KcSwiftKVOAnyExtensionable {
        case a
        case b
    }
    
    var s1: String = "1"            // 16   0
    var t1: KcThree2 = .init()      // 8    16
    var s2: Int = 3                 // 8    24
    var t2: KcThree2 = .init()      // 8    32
    var o1: String = "2"            // 16   40
    var t: T? = .a                  // 1    56
    var t3: KcThree3 = KcThree3()   // 8    (64) 57再内存对齐
    var t4: KcThree4? = KcThree4()  // 49   72
    var t5: Int = 1                 // 8    (128)121再内存对齐
}

// UIView: 480  KcThree2: 64 + 480
class KcThree2: UIView {
    var i1: String = "10" // 16  480
    var i2: String = "11" // 16  496
    var i3: Int? = 1      // 16  512
    var i4: Int? = 2      // 9   521  528
    var i5: Int8 = 1      // 9   537
}

class KcThree3: KcThree2 {
    var s1: String = "s1"           // 16   544
    var s2: NSObject? = NSObject()  // 8    560
    var s3: Int8? = 1               // 2    568
    var s4: Int? = 2                // 9    5
    var s5: Int = 3                 // 8
    var s6: String = "s6"           // 16
}

// 48
struct KcThree4 {
    var s1: Int? = 2                // 0
    var s2: NSObject? = NSObject()  // 16
    var s3: Int = 3                 // 24
    var s4: String = "s1"           // 32
}






