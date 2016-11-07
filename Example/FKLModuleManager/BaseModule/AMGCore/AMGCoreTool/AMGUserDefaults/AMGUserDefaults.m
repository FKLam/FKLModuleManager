//
//  AMGUserDefaults.m
//  FKLModuleManager
//
//  Created by amglfk on 16/11/7.
//  Copyright © 2016年 FKLam. All rights reserved.
//

#import "AMGUserDefaults.h"
#import <objc/runtime.h>

@interface AMGUserDefaults ()

@property (nonatomic, strong) NSMutableDictionary *mapping;
@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation AMGUserDefaults

#pragma mark - begin

+ (instancetype)standerdUserDefaults {
    static dispatch_once_t pred;
    static AMGUserDefaults *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wundeclared-selector"
#pragma GCC diagnostic ignored "-Warc-performSelector-leaks"

- (instancetype)init {
    self = [super init];
    if ( self ) {
        SEL setupDefaultSEL = NSSelectorFromString([NSString stringWithFormat:@"%@Defaults", @"setu"]);
        if ( [self respondsToSelector:setupDefaultSEL] ) {
            NSDictionary *defaults = [self performSelector:setupDefaultSEL];
            NSMutableDictionary *mutableDefaults = [NSMutableDictionary dictionaryWithCapacity:[defaults count]];
            for ( NSString *key in defaults ) {
                id value = [defaults objectForKey:key];
                NSString *transformedKey = [self _transformKey:key];
                [mutableDefaults setObject:value forKey:transformedKey];
            }
            [self.userDefaults registerDefaults:mutableDefaults];
        }
      [self generateAccessorMethods];
    }
    return self;
}

- (NSString *)_transformKey:(NSString *)key {
    if ( [self respondsToSelector:@selector(transformKey:)] ) {
        return [self performSelector:@selector(transformKey:) withObject:key];
    }
    return key;
}

- (NSString *)_suiteName {
    if ( [self respondsToSelector:@selector(suitName)] ) {
        return [self performSelector:@selector(suitName)];
    }
    
    if ( [self respondsToSelector:@selector(suitName)] ) {
        return [self performSelector:@selector(suitName)];
    }
    
    return nil;
}

#pragma GCC diagnostic pop

- (void)generateAccessorMethods {
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    
    self.mapping = [NSMutableDictionary dictionary];
    
    for ( int i = 0; i < count; ++i ) {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        const char *attributes = property_getAttributes(property);
        
        char *getter = strstr(attributes, ",G");
        if ( getter ) {
            getter = strdup(getter + 2);
            getter = strsep(&getter, ",");
        } else {
            getter = strdup(name);
        }
        
        SEL getterSEl = sel_registerName(getter);
        free(getter);
        
        char *setter = strstr(attributes, ",S");
        if ( setter ) {
            setter = strdup(setter + 2);
            setter = strsep(&setter, ",");
        } else {
            asprintf(&setter, "set%c%s:", toupper(name[0]), name + 1);
        }
        SEL setterSEL = sel_registerName(setter);
        free(setter);
        
        NSString *key = [self defaultsKeyForPropertyNamed:name];
        [self.mapping setValue:key forKey:NSStringFromSelector(getterSEl)];
        [self.mapping setValue:key forKey:NSStringFromSelector(setterSEL)];
        
        IMP getterIMP = NULL;
        IMP setterIMP = NULL;
        char type = attributes[1];
        switch ( type ) {
            case Short:
            case Long:
            case LongLong:
            case UnsignedChar:
            case UnsignedShort:
            case UnsignedInt:
            case UnsignedLong:
            case UnsignedLongLong: {
                getterIMP = (IMP)longLongGetter;
                setterIMP = (IMP)longLongSetter;
                break;
            }
                
            case Bool:
            case Char: {
                getterIMP = (IMP)boolGetter;
                setterIMP = (IMP)boolSetter;
                break;
            }
            case Int: {
                getterIMP = (IMP)integerGetter;
                setterIMP = (IMP)integerSetter;
                break;
            }
            case Float: {
                getterIMP = (IMP)floatGetter;
                setterIMP = (IMP)floatSetter;
                break;
            }
            case Double: {
                getterIMP = (IMP)doubleGetter;
                setterIMP = (IMP)doubleSetter;
                break;
            }
            case Object: {
                getterIMP = (IMP)objectGetter;
                setterIMP = (IMP)objectSetter;
                break;
            }
            default: {
                free(properties);
                [NSException raise:NSInternalInconsistencyException format:@"Unsupported type of property \"%s\" in class %@", name, self];
                break;
            }
        }
        char types[5];
        
        snprintf(types, 4, "%c@:", type);
        class_addMethod([self class], getterSEl, getterIMP, types);
        
        snprintf(types, 5, "v@:%c", type);
        class_addMethod([self class], setterSEL, setterIMP, types);
        
    }
    
    free(properties);
}

enum TypeEncodings {
    Char                = 'c',
    Bool                = 'B',
    Short               = 's',
    Int                 = 'i',
    Long                = 'l',
    LongLong            = 'q',
    UnsignedChar        = 'C',
    UnsignedShort       = 'S',
    UnsignedInt         = 'I',
    UnsignedLong        = 'L',
    UnsignedLongLong    = 'Q',
    Float               = 'f',
    Double              = 'd',
    Object              = '@'
};

- (NSUserDefaults *)userDefaults {
    if ( nil == _userDefaults ) {
        NSString *suiteName = nil;
        if ( [NSUserDefaults instancesRespondToSelector:@selector(initWithSuiteName:)] ) {
            suiteName = [self _suiteName];
        }
        
        if ( suiteName && suiteName.length ) {
            _userDefaults = [[NSUserDefaults alloc] initWithSuiteName:suiteName];
        } else {
            _userDefaults = [NSUserDefaults standardUserDefaults];
        }
    }
    return _userDefaults;
}

- (NSString *)defaultsKeyForPropertyNamed:(char const *)propertyName {
    NSString *key = [NSString stringWithFormat:@"%s", propertyName];
    return [self _transformKey:key];
}

- (NSString *)defaultsKeyForSelector:(SEL)selector {
    return [self.mapping objectForKey:NSStringFromSelector(selector)];
}

static long long longLongGetter(AMGUserDefaults *self, SEL _cmd) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [[self.userDefaults objectForKey:key] longLongValue];
}

static void longLongSetter(AMGUserDefaults *self, SEL _cmd, long long value) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    NSNumber *object = [NSNumber numberWithLongLong:value];
    [self.userDefaults setObject:object forKey:key];
}

static bool boolGetter(AMGUserDefaults *self, SEL _cmd) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [self.userDefaults boolForKey:key];
}

static void boolSetter(AMGUserDefaults *self, SEL _cmd, bool value) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    [self.userDefaults setBool:value forKey:key];
}

static int integerGetter(AMGUserDefaults *self, SEL _cmd) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return (int)[self.userDefaults integerForKey:key];
}

static void integerSetter(AMGUserDefaults *self, SEL _cmd, int value) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    [self.userDefaults setInteger:value forKey:key];
}

static float floatGetter(AMGUserDefaults *self, SEL _cmd) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [self.userDefaults floatForKey:key];
}

static void floatSetter(AMGUserDefaults *self, SEL _cmd, float value) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    [self.userDefaults setFloat:value forKey:key];
}

static double doubleGetter(AMGUserDefaults *self, SEL _cmd) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [self.userDefaults doubleForKey:key];
}

static void doubleSetter(AMGUserDefaults *self, SEL _cmd, double value) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    [self.userDefaults setDouble:value forKey:key];
}

static id objectGetter(AMGUserDefaults *self, SEL _cmd) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [self.userDefaults objectForKey:key];
}

static void objectSetter(AMGUserDefaults *self, SEL _cmd, id object) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    if (object) {
        [self.userDefaults setObject:object forKey:key];
    } else {
        [self.userDefaults removeObjectForKey:key];
    }
}

@end
