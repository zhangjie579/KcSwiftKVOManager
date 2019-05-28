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

```
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

let viewController = UIViewController()
let kvo = KcSwiftKVOManager.objc(viewController)
kvo.setValue(value: UIColor.lightGray, forKeyPath: "view.backgroundColor")
```

## Author

zhangjie, 527512749@qq.com

## License

KcSwiftKVOManager is available under the MIT license. See the LICENSE file for more info.
