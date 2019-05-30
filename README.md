# KcSwiftKVOManager

[![CI Status](https://img.shields.io/travis/zhangjie/KcSwiftKVOManager.svg?style=flat)](https://travis-ci.org/zhangjie/KcSwiftKVOManager)
[![Version](https://img.shields.io/cocoapods/v/KcSwiftKVOManager.svg?style=flat)](https://cocoapods.org/pods/KcSwiftKVOManager)
[![License](https://img.shields.io/cocoapods/l/KcSwiftKVOManager.svg?style=flat)](https://cocoapods.org/pods/KcSwiftKVOManager)
[![Platform](https://img.shields.io/cocoapods/p/KcSwiftKVOManager.svg?style=flat)](https://cocoapods.org/pods/KcSwiftKVOManager)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

KcSwiftKVOManager is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'KcSwiftKVOManager'
```

## Sample Code

```swift
class Test1: UIView {
    var i1: String = "10" // 16  480
    var i2: String = "11" // 16  496
    var i3: Int? = 1      // 16  512
    var i4: Int? = 2      // 9   521  528
    var i5: Int8 = 1      // 9   537
}

let test = Test1()
let kvo = KcSwiftKVOManager.objc(test)
kvo.setValue(value: "i1", forKeyPath: "i1")
kvo.setValue(value: 100, forKeyPath: "tag")
```

```swift
let viewController = UIViewController()
let kvo = KcSwiftKVOManager.objc(viewController)
kvo.setValue(value: UIColor.lightGray, forKeyPath: "view.backgroundColor")
```

## 原理
```
 1.属性
     * 属性: super + self; 协议protocol自己会加进去, 不用管
 2.MemoryLayout
     * size: 对象的占用空间
     * stride: 实际长度
        * 在一个 T 类型的数组中，其中任意一个元素从开始地址到结束地址所占用的连续内存字节的大小就是 stride
        * stride - size 个字节则为每个元素因为内存对齐而浪费的内存空间
     * alignment: 对齐模数 
        * 要求当前数据类型相对于起始位置的偏移必须是alignment的整数倍
        	* 比如前面已经占了20个了，而后面属性的alignment是8，so需要填充到24开始),so 类/结构体的成员声明顺序会影响占用空间
        * 对齐原则: 任何 K 字节的地址必须是 K 的倍数
        	* 内存对齐是内存的优化
        	* 内存大的变量写在前面，小的写在后面
     * MemoryLayout.offset(of: \kcTestP2.d1)获取d1偏移量，参数为keyPath👍
 3.内存
    * super + self，父类的字段在前
    * class 前面还有几个内存是meta(类型信息，引用计数), 32位 4 + 8， 64位 8 + 8，后8位是meta
        * 属性为class占8个
        * 属性为struct - 占的内存数就是这个结构体的内存数(struct属性内存之和)⚠️
        * optional需要在当前占内存的基础上再 + 1
        * 需要考虑内存对齐: 起始地址为alignment的倍数
        * 单个对象最大内存为16，不包括struct(它可以n个)
    * var i: 结构体、类..., 这个东西的属性的地址与self无关
 4.通过self，得出self.name(name可能是结构体可能是class)的指针
    * 作用: 这样就可以获取、修改属性下属性的value
    1. name是struct
        * name的第1个属性的地址是self的地址 + name的偏移地址offset
    2. name是class, class不是NSObject的子类
        * let point = p1.assumingMemoryBound(to: AnyObject.self)
            * 如果是UIView等等知道的类型，可以直接用point.pointee.属性名 = value来修改
        * let p4 = UnsafeMutableRawPointer.headPointerOfClass(value: point.pointee)
        * 再找到合适的地址偏移量offset，需要class前面还有几个内存
        * p5.initialize(to: ";lyh")
    3. name是class, class是NSObject的子类
        * 其实与普通的继承一样，都是class的属性在后，NSObject的在前
        * 只不过不好求NSObject的所有变量所占的内存大小
    4.Array是连续型存储的，与c语言的一种，都是获取的第1个element的指针，后面的指针只需要加上对应的offset，为n * 类型的size
作用
    * 可以获取属性的值
    * 不管是let还是var修饰都可以修改value👍👍👍
    * 这个是MemoryLayout.stride(ofValue: i3))属性实际占用的内存
	* 注意需要直接使用属性value来计算，而不能用let a = value来计算，因为它是值类型⚠️⚠️⚠️
    	* 其实大小就是对于classType的MemoryLayout.stride，比如int，float类型…
```


## License

KcSwiftKVOManager is available under the MIT license. See the LICENSE file for more info.
