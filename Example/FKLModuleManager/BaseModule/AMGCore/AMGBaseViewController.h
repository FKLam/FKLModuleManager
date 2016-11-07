//
//  AMGBaseViewController.h
//  FKLModuleManager
//
//  Created by amglfk on 16/11/7.
//  Copyright © 2016年 FKLam. All rights reserved.
//  所有 controller 的基类

#import <UIKit/UIKit.h>


/**
 数据源方法
 */
@protocol AMGBaseViewControllerDataSource <NSObject>

@optional

/**
 设置导航栏标题

 @return 标题字符串
 */
- (NSMutableAttributedString *)setTitle;

/**
 设置导航栏左边按钮

 @return 左边按钮
 */
- (UIButton *)set_leftButton;

/**
 设置导航栏右边按钮

 @return 右边按钮
 */
- (UIButton *)set_rightButton;

/**
 设置背景颜色

 @return 背景颜色
 */
- (UIColor *)set_colorBackground;

/**
 设置导航栏高度

 @return 导航栏高度
 */
- (CGFloat)set_navigationHeight;

/**
 设置底层视图

 @return 底层视图
 */
- (UIView *)set_bottomView;

/**
 设置导航栏背景图片

 @return 背景图片
 */
- (UIImage *)navBackgroundImage;

/**
 是否隐藏导航栏底部分割线

 @return 是否隐藏
 */
- (BOOL)hideNavigationBottomLine;

/**
 设置导航栏左边按钮的图片

 @return 左边按钮的图片
 */
- (UIImage *)set_leftBarButtonItemWithImage;

/**
 设置导航栏右边按钮的图片

 @return 右边按钮的图片
 */
- (UIImage *)set_rightBarButtonItemWithImage;

@end

/**
 代理方法
 */
@protocol AMGBaseViewControllerDelegate <NSObject>

@optional

/**
 点击导航栏左边按钮

 @param sender 左边按钮
 */
- (void)left_button_event:(UIButton *)sender;

/**
 点击导航栏右边按钮

 @param sender 右边按钮
 */
- (void)right_button_event:(UIButton *)sender;

/**
 点击导航栏标题

 @param sender 标题
 */
- (void)title_click_event:(UIView *)sender;

@end

@interface AMGBaseViewController : UIViewController<AMGBaseViewControllerDataSource, AMGBaseViewControllerDelegate>

/**
 页面接受参数
 */
@property (nonatomic, strong) NSDictionary *parameterDictionary;

/**
 初始化方法

 @param params 参数
 @return 返回控制器
 */
- (id)initWithRouterParams:(NSDictionary *)params;

/**
 改变 NavigationBar 的 Y 轴

 @param translationY 需要改变的 Y 轴的值
 */
- (void)changeNavigationTranslationY:(CGFloat)translationY;

/**
 设置标题

 @param title 标题字符串
 */
- (void)set_Title:(NSMutableAttributedString *)title;

@end
