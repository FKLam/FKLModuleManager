//
//  AMGPatchHelper.m
//  FKLModuleManager
//
//  Created by amglfk on 16/11/8.
//  Copyright © 2016年 FKLam. All rights reserved.
//

#import "AMGPatchHelper.h"
#import <CommonCrypto/CommonDigest.h>
#import "AMGPatchModel.h"
#import "AMGMacros.h"
#import <AFNetworking/AFNetworking.h>

@interface AMGPatchHelper ()

@property (nonatomic, strong) NSMutableArray *patchs;
@property (nonatomic, strong) NSMutableArray *localPatchs; // 本地补丁的信息
@property (nonatomic, readonly, copy) NSString *patchCancheKey; // 补丁缓存时用的key值

@end

@implementation AMGPatchHelper

- (instancetype)initWithPatchArray:(NSMutableArray *)array {
    self = [super init];
    if ( self ) {
        self.patchs = array;
    }
    return self;
}

- (void)setPatchs:(NSMutableArray *)patchs {
    if ( 0 == patchs.count ) {
        return;
    }
    
    if ( !_localPatchs ) {
        _localPatchs = [[NSMutableArray alloc] init];
    }
}

@end
