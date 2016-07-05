# EasyPrefs
![Language](https://img.shields.io/badge/language-objc-orange.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

一个轻量、优雅的 NSUserDefaults 封装

# 目的
让 NSUserDefaults 用起来更容易，使用 property 存储数据

# 设置
```objc
#import "EasyPrefs.h"

@interface TINPrefs : EasyPrefs

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) int age;

@end

#import "TINPrefs.h"

@implementation TINPrefs

EasyPrefsRegisterDefault(name, @"Cyan")
EasyPrefsRegisterDefault(age, @25)

@end
```

# 用法
```objc
[[TINPrefs instance] setName:@"Katrine"];
[[TINPrefs instance] setAge:18];
```

# 以上
