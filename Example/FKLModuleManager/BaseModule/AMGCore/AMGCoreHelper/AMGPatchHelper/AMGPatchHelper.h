//
//  AMGPatchHelper.h
//  FKLModuleManager
//
//  Created by amglfk on 16/11/8.
//  Copyright © 2016年 FKLam. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AMGPatchHelper : NSObject

/**
 初始化包工具类

 @param array 包数组
 @return 包工具类
 */
- (instancetype)initWithPatchArray:(NSMutableArray *)array;

/**
 加载包文件
 */
- (void)loadPatchFile;

@end
