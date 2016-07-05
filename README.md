# EasyPrefs
![Language](https://img.shields.io/badge/language-objc-orange.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

Light weight & elegent NSUserDefaults wrapper

🇨🇳[中文介绍](https://github.com/cyanzhong/EasyPrefs/blob/master/README_CN.md)

# Purpose
Make NSUserDefaults more easy to use, treat preferences as properties

# Setup
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

# Usage
```objc
[[TINPrefs instance] setName:@"Katrine"];
[[TINPrefs instance] setAge:18];
```

# That's all
