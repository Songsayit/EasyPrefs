//
//  EasyPrefs.h
//  EasyPrefs
//
//  Created by cyan on 16/5/19.
//  Copyright © 2016年 cyan. All rights reserved.
//

#import <Foundation/Foundation.h>

#define EasyPrefsRegisterDefault(keyPath, value) \
+ (NSArray *)keyPath##DefaultValue { return @[value, @#keyPath]; }

#define EasyPrefsRegisterKey(keyPath, key) \
+ (NSArray *)keyPath##Key { return @[key, @#keyPath]; }

@interface EasyPrefs : NSObject

+ (instancetype)instance;

@end
