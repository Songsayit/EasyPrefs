//
//  EasyPrefs.m
//  EasyPrefs
//
//  Created by cyan on 16/5/19.
//  Copyright © 2016年 cyan. All rights reserved.
//

#import "EasyPrefs.h"
#import "Aspects.h"
#import <objc/runtime.h>

static const NSString *const kEasyPrefsKeyPrefix = @"EasyPrefs";

typedef void (^EasyPrefsPropertyEnumerateBlock) (NSString *property);

@implementation NSString (EasyPrefs)

- (NSString *)setter {
    return [NSString stringWithFormat:@"set%@%@:", [[self substringToIndex:1] uppercaseString], [self substringFromIndex:1]];
}

@end

@implementation NSObject (EasyPrefs)

- (id)archive {
    if ([self isKindOfClass:[NSArray class]] ||
        [self isKindOfClass:[NSData class]] ||
        [self isKindOfClass:[NSString class]] ||
        [self isKindOfClass:[NSNumber class]] ||
        [self isKindOfClass:[NSDate class]] ||
        [self isKindOfClass:[NSDictionary class]] ||
        [self isKindOfClass:[NSURL class]]) {
        return self;
    } else {
        return [NSKeyedArchiver archivedDataWithRootObject:self];
    }
}

- (id)unarchive {
    if ([self isKindOfClass:[NSData class]]) {
        return [NSKeyedUnarchiver unarchiveObjectWithData:(NSData *)self];
    } else {
        return self;
    }
}

- (void)enumerateProperties:(EasyPrefsPropertyEnumerateBlock)block {
    uint count;
    objc_property_t *properties = class_copyPropertyList(self.class, &count);
    for (int i=0; i<count; ++i) {
        NSString *property = [NSString stringWithCString:property_getName(properties[i]) encoding:NSUTF8StringEncoding];
        if (block) {
            block(property);
        }
    }
    if (properties) {
        free(properties);
    }
}

- (id)valueForEasyPrefsSelecor:(SEL)selector {
    NSMethodSignature *signature = [self.class methodSignatureForSelector:selector];
    if (signature) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.selector = selector;
        invocation.target = self.class;
        __unsafe_unretained id returnValue = nil;
        [invocation invoke];
        [invocation getReturnValue:&returnValue];
        if ([returnValue isKindOfClass:[NSArray class]] && [returnValue count] == 2) {
            return [returnValue firstObject];
        }
    }
    return nil;
}

@end

@interface EasyPrefs()

@property (nonatomic, strong) NSUserDefaults *defaults;
@property (nonatomic, strong) NSMutableDictionary *registeredKeys;

@end

@implementation EasyPrefs

+ (instancetype)instance {
    static dispatch_once_t token = 0;
    __strong static id _sharedPrefs = nil;
    dispatch_once(&token, ^{
        _sharedPrefs = [[self alloc] init];
    });
    return _sharedPrefs;
}

- (instancetype)init {
    if (self = [super init]) {
        [self loadPrefs];
        [self observePrefs];
    }
    return self;
}

- (void)loadPrefs {
    
    _defaults = [NSUserDefaults standardUserDefaults];
    _registeredKeys = [NSMutableDictionary dictionary];
    
    [self enumerateProperties:^(NSString *property) {
        
        SEL keySelector = NSSelectorFromString([NSString stringWithFormat:@"%@Key", property]);
        id registeredKey = [self valueForEasyPrefsSelecor:keySelector];
        
        if (registeredKey) {
            self.registeredKeys[property] = registeredKey;
        }
        
        NSString *key = [self keyForProperty:property];
        id value = [self.defaults objectForKey:key];
        
        if (value) {
            Ivar ivar = class_getInstanceVariable(self.class, [@"_" stringByAppendingString:property].UTF8String);
            const char *type = ivar_getTypeEncoding(ivar);
            switch (type[0]) {
                case _C_STRUCT_B: {
                    NSUInteger ivarSize = 0;
                    NSUInteger ivarAlignment = 0;
                    NSGetSizeAndAlignment(type, &ivarSize, &ivarAlignment);
                    NSData *data = (NSData *)value;
                    char *sourceIvarLocation = (char *)((__bridge void *)self)+ ivar_getOffset(ivar);
                    [data getBytes:sourceIvarLocation length:ivarSize];
                    memcpy((char *)((__bridge void *)self) + ivar_getOffset(ivar), sourceIvarLocation, ivarSize);
                } break;
                default: {
                    id object = [value unarchive];
                    [self setValue:object forKey:property];
                } break;
            }
        } else {
            SEL defaultValueSelector = NSSelectorFromString([NSString stringWithFormat:@"%@DefaultValue", property]);
            id defaultValue = [self valueForEasyPrefsSelecor:defaultValueSelector];
            [self setValue:defaultValue forKey:property];
        }
    }];
}

- (void)observePrefs {
    
    [self enumerateProperties:^(NSString *property) {
        
        NSString *key = [self keyForProperty:property];
        SEL selector = NSSelectorFromString(property.setter);
        
        [self aspect_hookSelector:selector withOptions:AspectPositionAfter usingBlock:^{
            
            id value = [self valueForKey:property];
            
            if (value) {
                Ivar ivar = class_getInstanceVariable(self.class, [@"_" stringByAppendingString:property].UTF8String);
                const char *type = ivar_getTypeEncoding(ivar);
                switch (type[0]) {
                    case _C_STRUCT_B: {
                        NSUInteger ivarSize = 0;
                        NSUInteger ivarAlignment = 0;
                        NSGetSizeAndAlignment(type, &ivarSize, &ivarAlignment);
                        NSData *data = [NSData dataWithBytes:(const char *)((__bridge void *)self) + ivar_getOffset(ivar) length:ivarSize];
                        [self.defaults setObject:data forKey:key];
                    } break;
                    default: {
                        [self.defaults setObject:[value archive] forKey:key];
                    } break;
                }
            } else {
                [self.defaults removeObjectForKey:key];
            }
            
            [self.defaults synchronize];
        } error:nil];
    }];
}

- (NSString *)keyForProperty:(NSString *)property {
    NSString *registedKey = self.registeredKeys[property];
    if (registedKey) {
        return registedKey;
    } else {
        return [NSString stringWithFormat:@"%@.%@.%@", kEasyPrefsKeyPrefix, NSStringFromClass(self.class), property];
    }
}

@end
