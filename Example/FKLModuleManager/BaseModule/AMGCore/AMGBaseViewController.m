//
//  AMGBaseViewController.m
//  FKLModuleManager
//
//  Created by amglfk on 16/11/7.
//  Copyright © 2016年 FKLam. All rights reserved.
//

#import "AMGBaseViewController.h"
#import "RealReachability.h"
#import "MBProgressHUD+AMG.h"

@interface AMGBaseViewController () {
    CGFloat navigationY;
    CGFloat navBarY;
    CGFloat verticalY;
    BOOL _isShowMenu;
}

/**
 导航栏原始高度
 */
@property (nonatomic, assign) CGFloat original_height;

@end

@implementation AMGBaseViewController

#pragma mark - lift cycle

- (id)initWithRouterParams:(NSDictionary *)params {
    self = [super init];
    if ( self ) {
        _parameterDictionary = params;
    }
    return self;
}

- (id)init {
    self = [super init];
    if ( self ) {
        [self.navigationController.navigationBar setTranslucent:NO];
        [self.navigationController setNavigationBarHidden:YES];
        navBarY = 0;
        navigationY = 0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController setNavigationBarHidden:NO];
    
    if ( [self respondsToSelector:@selector(backgroundImage)] ) {
        UIImage *bgimage = [self navBackgroundImage];
        [self setNavigationBack:bgimage];
    }
    
    if ( [self respondsToSelector:@selector(setTitle)] ) {
        NSMutableAttributedString *titleAtt = [self setTitle];
        [self set_Title:titleAtt];
    }
    
    if ( ![self leftButton] ) {
        [self configLeftBarItemWithImage];
    }
    
    if ( ![self rightButton] ) {
        [self configRightBarItemWithImage];
    }
    
    // 添加一个通知监听网络状态切换
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkChanged:)
                                                 name:kRealReachabilityChangedNotification
                                               object:nil];
    [GLobalRealReachability startNotifier];
    
    ReachabilityStatus status = [GLobalRealReachability currentReachabilityStatus];
    // 当无网络时 每进入一个页面进行提示
    if ( status == RealStatusNotReachable ) {
        [MBProgressHUD showInfo:@"当前网络连接失败，请查看设置" ToView:self.view];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ( [self respondsToSelector:@selector(set_colorBackground)] ) {
        UIColor *backgroundColor = [self set_colorBackground];
        UIImage *bgImage = [self imageWithColor:backgroundColor];
        
        [self.navigationController.navigationBar setBackgroundImage:bgImage forBarMetrics:UIBarMetricsDefault];
    }
    
    UIImageView *blackLineImageView = [self findHairlineImageViewUnder:self.navigationController.navigationBar];
    // 默认显示黑线
    blackLineImageView.hidden = NO;
    if ( [self respondsToSelector:@selector(hideNavigationBottomLine)] ) {
        if ( [self hideNavigationBottomLine] ) {
            // 隐藏黑线
            blackLineImageView.hidden = YES;
        }
    }
}

- (void)dealloc {
    
    // 移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - interface methods

- (void)set_Title:(NSMutableAttributedString *)title {
    UILabel *naviTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 44)];
    naviTitleLabel.numberOfLines = 0;
    [naviTitleLabel setAttributedText:title];
    naviTitleLabel.textAlignment = NSTextAlignmentCenter;
    naviTitleLabel.backgroundColor = [UIColor clearColor];
    naviTitleLabel.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(titleClick:)];
    [naviTitleLabel addGestureRecognizer:tap];
    self.navigationItem.titleView = naviTitleLabel;
}

- (void)changeNavigationTranslationY:(CGFloat)translationY {
    self.navigationController.navigationBar.transform = CGAffineTransformMakeTranslation(0, translationY);
}

#pragma mark - UITableViewDelegate UITableViewDataSource

#pragma mark - event response

- (void)left_click:(id)sender {
    if ( [self respondsToSelector:@selector(left_button_event:)] ) {
        [self left_button_event:sender];
    }
}

- (void)right_click:(id)sender {
    if ( [self respondsToSelector:@selector(right_button_event:)] ) {
        [self right_button_event:sender];
    }
}

- (void)titleClick:(UIGestureRecognizer *)tap {
    UIView *view = tap.view;
    if ( [self respondsToSelector:@selector(title_click_event:)] ) {
        [self title_click_event:view];
    }
}

#pragma mark - loadUI loadLayout

#pragma mark - private mehtods

- (void)setNavigationBack:(UIImage *)image {
    
}

- (BOOL)leftButton {
    BOOL isLeft = [self respondsToSelector:@selector(set_leftButton)];
    if ( isLeft ) {
        UIButton *leftButton = [self set_leftButton];
        [leftButton addTarget:self action:@selector(left_click:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:leftButton];
        self.navigationItem.leftBarButtonItem = item;
    }
    return isLeft;
}

- (void)configLeftBarItemWithImage {
    if ( [self respondsToSelector:@selector(set_leftBarButtonItemWithImage)] ) {
        UIImage *image = [self set_leftBarButtonItemWithImage];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(left_click:)];
        self.navigationItem.backBarButtonItem = item;
    }
}

- (BOOL)rightButton {
    BOOL isRight = [self respondsToSelector:@selector(set_rightButton)];
    if ( isRight ) {
        UIButton *rightButton = [self set_rightButton];
        [rightButton addTarget:self action:@selector(right_click:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
        self.navigationItem.leftBarButtonItem = item;
    }
    return isRight;
}

- (void)configRightBarItemWithImage {
    if ( [self respondsToSelector:@selector(set_rightBarButtonItemWithImage)] ) {
        UIImage *image = [self set_rightBarButtonItemWithImage];
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(right_click:)];
        self.navigationItem.rightBarButtonItem = item;
    }
}

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImageView *)findHairlineImageViewUnder:(UIView *)view {
    if ( [view isKindOfClass:[UIImageView class]] && view.bounds.size.height <= 1.0 ) {
        return (UIImageView *)view;
    }
    
    for ( UIView *subview in view.subviews ) {
        UIImageView *imageView = [self findHairlineImageViewUnder:subview];
        if ( imageView ) {
            return imageView;
        }
    }
    return nil;
}

/**
 监听网络变化

 @param notification 网络变化的通知
 */
- (void)networkChanged:(NSNotification *)notification {
    RealReachability *reachability = (RealReachability *)notification.object;
    ReachabilityStatus status = [reachability currentReachabilityStatus];
    
    if ( status == RealStatusNotReachable ) {
        [MBProgressHUD showInfo:@"当前网络连接失败，请查看设置" ToView:self.view];
    } else if ( status == RealStatusViaWiFi ) {
        
    } else if ( status == RealStatusViaWWAN ) {
        
        WWANAccessType accessType = [GLobalRealReachability currentWWANtype];
        if ( accessType == WWANType2G ) {
            
        } else if ( accessType == WWANType3G ) {
            
        } else if ( accessType == WWANType4G ) {
            
        }
        
    } else if ( status == RealStatusUnknown ) {
        
    }
    
}

#pragma mark - getter methods

@end
