//
//  FKLModuleManager.m
//  Pods
//
//  Created by amg on 16/10/31.
//
//

#import "FKLModuleManager.h"

@interface FKLModuleManager ()

@property (copy, nonatomic) NSMutableArray<id<FKLModule>> *modules;

@end

@implementation FKLModuleManager

+ (instancetype)shareInstance {
    static FKLModuleManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ( !_instance ) {
            _instance = [[self alloc] init];
        }
    });
    return _instance;
}

- (NSMutableArray<id<FKLModule>> *)modules {
    if ( !_modules ) {
        _modules = [NSMutableArray array];
    }
    return _modules;
}

- (void)addModule:(id<FKLModule>)module {
    if ( ![self.modules containsObject:module] ) {
        [self.modules addObject:module];
    }
}

- (void)loadModulesWithPlistFile:(NSString *)plistFile {
    NSArray<NSString *> *moduleNames = [NSArray arrayWithContentsOfFile:plistFile];
    for (NSString *moduleName in moduleNames) {
        id<FKLModule> module = [[NSClassFromString(moduleName) alloc] init];
        [self addModule:module];
    }
}

- (NSArray<id<FKLModule>> *)allModules {
    return self.modules;
}

#pragma mark - UIApplicationDelegate's methods
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    for ( id<FKLModule> module in self.modules ) {
        if ( [module respondsToSelector:_cmd] ) {
            [module application:application didFinishLaunchingWithOptions:launchOptions];
        }
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    for ( id<FKLModule> module in self.modules ) {
        if ( [module respondsToSelector:_cmd] ) {
            [module applicationWillResignActive:application];
        }
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    for ( id<FKLModule> module in self.modules ) {
        if ( [module respondsToSelector:_cmd] ) {
            [module applicationDidEnterBackground:application];
        }
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    for ( id<FKLModule> module in self.modules ) {
        if ( [module respondsToSelector:_cmd] ) {
            [module applicationWillEnterForeground:application];
        }
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    for ( id<FKLModule> module in self.modules ) {
        if ( [module respondsToSelector:_cmd] ) {
            [module applicationDidBecomeActive:application];
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    for ( id<FKLModule> module in self.modules ) {
        if ( [module respondsToSelector:_cmd] ) {
            [module applicationWillTerminate:application];
        }
    }
}
@end
