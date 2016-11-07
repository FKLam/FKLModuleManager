//
//  AMGMediator.h
//  FKLModuleManager
//
//  Created by amglfk on 16/11/7.
//  Copyright © 2016年 FKLam. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AMGMediator : NSObject

+ (instancetype)sharedInstance;

// 远程App调用入口
- (id)performActionWithUrl:(NSURL *)url completion:(void(^)(NSDictionary *info))completion;

// 本地组件调用入口
- (id)performTarget:(NSString *)targetName action:(NSString *)actionName params:(NSDictionary *)params;

@end
