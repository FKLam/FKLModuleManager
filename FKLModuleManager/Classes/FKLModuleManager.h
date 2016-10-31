//
//  FKLModuleManager.h
//  Pods
//
//  Created by amg on 16/10/31.
//
//

#import <Foundation/Foundation.h>

@protocol FKLModule <UIApplicationDelegate>

@end

@interface FKLModuleManager : NSObject<UIApplicationDelegate>

+ (instancetype)shareInstance;

- (void)loadModulesWithPlistFile:(NSString *)plistFile;

- (NSArray<id<FKLModule>> *)allModules;

@end
