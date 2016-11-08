//
//  AMGAlertView.m
//  FKLModuleManager
//
//  Created by amglfk on 16/11/8.
//  Copyright © 2016年 FKLam. All rights reserved.
//

#import "AMGAlertView.h"
#import <Accelerate/Accelerate.h>

NSString *const AMGAlertViewWillShowNotification = @"AMGAlertViewWillShowNotification";
NSString *const AMGAlertViewDidShowNotification = @"AMGAlertViewDidShowNotification";
NSString *const AMGAlertViewWillDismissNotification = @"AMGAlertViewWillDismissNotification";
NSString *const AMGAlertViewDidDismissNotification = @"AMGAlertViewDidDismissNotification";

#define AMGColor(r, g, b) [UIColor colorWithRed:(r/255.0) green:(g/255.0) blue:(b/255.0) alpha:1.0]
#define AMGScreenWidth [UIScreen mainScreen].bounds.size.width
#define AMGScreenHeight [UIScreen mainScreen].bounds.size.height
#define AMGAlertViewWidth 280
#define AMGAlertViewHeight 150
#define AMGAlertViewMaxHeight 440
#define AMGMargin 0
#define AMGContentMargin 15
#define AMGButtonHeight 44
#define AMGAlertViewTitleLabelHeight 40
#define AMGAlertViewTitleColor AMGColor(65, 65, 65)
#define AMGAlertViewTitleFont [UIFont boldSystemFontOfSize:20]
#define AMGAlertViewContentColor AMGColor(102, 102, 102)
#define AMGAlertViewContentFont [UIFont systemFontOfSize:14]
#define AMGAlertViewContentHeight (AMGAlertViewHeight - AMGAlertViewTitleLabelHeight - AMGButtonHeight - AMGMargin * 2)
#define AMGiOS7OrLater ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)

@class AMGiewController;

@protocol AMGViewControllerDelegate <NSObject>

@optional
- (void)coverViewTouched;

@end


@interface AMGViewController : UIViewController

@property (nonatomic, strong) UIImageView *screenShotView;
@property (nonatomic, strong) UIButton *coverView;
@property (nonatomic, weak) AMGAlertView *alertView;
@property (nonatomic, weak) id<AMGViewControllerDelegate> delegate;

@end

@interface AMGAlertView () <AMGViewControllerDelegate>

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, strong) NSArray *buttons;
@property (nonatomic, strong) NSArray *clicks;
@property (nonatomic, copy) clickHandleWithIndex clickWithIndex;
@property (nonatomic, weak) AMGViewController *vc;
@property (nonatomic, strong) UIImageView *screenShotView;
@property (nonatomic, getter=isCustomAlert) BOOL customAert;
@property (nonatomic, getter=isDismissWhenTouchBackground) BOOL dismissWhenTouchBackground;
@property (nonatomic, getter=isAlertReady) BOOL alertReady;

- (void)setup;

@end

@implementation AMGViewController

#pragma mark - AMGViewController lift cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addScreenShot];
    [self addCoverView];
    [self addAlertView];
}

#pragma mark - UITableViewDelegate UITableViewDataSource

#pragma mark - event response

- (void)coverViewClick{
    if ([self.delegate respondsToSelector:@selector(coverViewTouched)]) {
        [self.delegate coverViewTouched];
    }
}

#pragma mark - loadUI loadLayout

#pragma mark - private mehtods

- (void)addScreenShot {
    UIWindow *screenWindow = [UIApplication sharedApplication].windows.firstObject;
    UIGraphicsBeginImageContext(screenWindow.frame.size);
    [screenWindow.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImage *originalImage = nil;
    if (AMGiOS7OrLater) {
        originalImage = viewImage;
    } else {
        originalImage = [UIImage imageWithCGImage:CGImageCreateWithImageInRect(viewImage.CGImage, CGRectMake(0, 20, 320, 460))];
    }
    
    CGFloat blurRadius = 4;
    UIColor *tintColor = [UIColor clearColor];
    CGFloat saturationDeltaFactor = 1;
    UIImage *maskImage = nil;
    
    CGRect imageRect = { CGPointZero, originalImage.size };
    UIImage *effectImage = originalImage;
    
    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDeltaFactor - 1.) > __FLT_EPSILON__;
    if (hasBlur || hasSaturationChange) {
        UIGraphicsBeginImageContextWithOptions(originalImage.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectInContext = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -originalImage.size.height);
        CGContextDrawImage(effectInContext, imageRect, originalImage.CGImage);
        
        vImage_Buffer effectInBuffer;
        effectInBuffer.data	 = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width	= CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);
        
        UIGraphicsBeginImageContextWithOptions(originalImage.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data	 = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width	= CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);
        
        if (hasBlur) {
            CGFloat inputRadius = blurRadius * [[UIScreen mainScreen] scale];
            uint32_t radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            if (radius % 2 != 1) {
                radius += 1;
            }
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, radius, radius, 0, kvImageEdgeExtend);
        }
        BOOL effectImageBuffersAreSwapped = NO;
        if (hasSaturationChange) {
            CGFloat s = saturationDeltaFactor;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                0,					0,					0,  1,
            };
            const int32_t divisor = 256;
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix)/sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
            for (NSUInteger i = 0; i < matrixSize; ++i) {
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            if (hasBlur) {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            }
            else {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        if (!effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    UIGraphicsBeginImageContextWithOptions(originalImage.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -originalImage.size.height);
    
    CGContextDrawImage(outputContext, imageRect, originalImage.CGImage);
    
    if (hasBlur) {
        CGContextSaveGState(outputContext);
        if (maskImage) {
            CGContextClipToMask(outputContext, imageRect, maskImage.CGImage);
        }
        CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
        CGContextRestoreGState(outputContext);
    }
    
    if (tintColor) {
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.screenShotView = [[UIImageView alloc] initWithImage:outputImage];
    
    [self.view addSubview:self.screenShotView];
}

- (void)addCoverView {
    self.coverView = [[UIButton alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.coverView.backgroundColor = AMGColor(5, 0, 10);
    [self.coverView addTarget:self action:@selector(coverViewClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.coverView];
}

- (void)addAlertView {
    [self.alertView setup];
    [self.view addSubview:self.alertView];
}

- (void)showAlert{
    [[NSNotificationCenter defaultCenter] postNotificationName:AMGAlertViewWillShowNotification object:self];
    self.alertView.alertReady = NO;
    
    CGFloat duration = 0.3;
    
    for (UIButton *btn in self.alertView.subviews) {
        btn.userInteractionEnabled = NO;
    }
    
    self.screenShotView.alpha = 0;
    self.coverView.alpha = 0;
    self.alertView.alpha = 0;
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.screenShotView.alpha = 1;
        self.coverView.alpha = 0.65;
        self.alertView.alpha = 1.0;
    } completion:^(BOOL finished) {
        for (UIButton *btn in self.alertView.subviews) {
            btn.userInteractionEnabled = YES;
        }
        self.alertView.alertReady = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:AMGAlertViewDidShowNotification object:self.alertView];
    }];
    
    if (AMGiOS7OrLater) {
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        animation.values = @[@(0.8), @(1.05), @(1.1), @(1)];
        animation.keyTimes = @[@(0), @(0.3), @(0.5), @(1.0)];
        animation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
        animation.duration = duration;
        [self.alertView.layer addAnimation:animation forKey:@"bouce"];
    } else {
        self.alertView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        [UIView animateWithDuration:duration * 0.3 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.alertView.transform = CGAffineTransformMakeScale(1.05, 1.05);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:duration * 0.2 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                self.alertView.transform = CGAffineTransformMakeScale(1.1, 1.1);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:duration * 0.5 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                    self.alertView.transform = CGAffineTransformMakeScale(1, 1);
                } completion:nil];
            }];
        }];
    }
}

- (void)hideAlertWithCompletion:(void(^)(void))completion{
    [[NSNotificationCenter defaultCenter] postNotificationName:AMGAlertViewWillDismissNotification object:self];
    self.alertView.alertReady = NO;
    
    CGFloat duration = 0.2;
    
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.coverView.alpha = 0;
        self.screenShotView.alpha = 0;
        self.alertView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.screenShotView removeFromSuperview];
        if (completion) {
            completion();
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:AMGAlertViewDidDismissNotification object:self];
    }];
    
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.alertView.transform = CGAffineTransformMakeScale(0.4, 0.4);
    } completion:^(BOOL finished) {
        self.alertView.transform = CGAffineTransformMakeScale(1, 1);
    }];
}

#pragma mark - getter methods

@end

@interface AMGCSingleTon : NSObject

@property (nonatomic, strong) UIWindow *backgroundWindow;
@property (nonatomic, weak) UIWindow *oldKeyWindow;
@property (nonatomic, strong) NSMutableArray *alertStack;
@property (nonatomic, strong) AMGAlertView *previousAlert;

@end

@implementation AMGCSingleTon

+ (instancetype)shareSingleTon {
    static AMGCSingleTon *shareSingleTonInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareSingleTonInstance = [AMGCSingleTon new];
    });
    return shareSingleTonInstance;
}

- (UIWindow *)backgroundWindow {
    if ( !_backgroundWindow ) {
        _backgroundWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _backgroundWindow.windowLevel = UIWindowLevelStatusBar - 1;
    }
    return _backgroundWindow;
}

- (NSMutableArray *)alertStack {
    if ( !_alertStack ) {
        _alertStack = [NSMutableArray array];
    }
    return _alertStack;
}

@end

@implementation AMGAlertView

- (NSArray *)buttons {
    if ( !_buttons ) {
        _buttons = [NSArray array];
    }
    return _buttons;
}

- (NSArray *)clicks {
    if ( !_clicks ) {
        _clicks = [NSArray array];
    }
    return _clicks;
}

- (instancetype)initWithCustomView:(UIView *)customView dismissWhenTouchedBackground:(BOOL)dismissWhenTouchBackground {
    self = [super initWithFrame:customView.bounds];
    if ( self ) {
        [self addSubview:customView];
        self.layer.masksToBounds = true;
        self.layer.cornerRadius = 8;
        self.center = CGPointMake(AMGScreenWidth / 2.0, AMGScreenHeight / 2.0);
        self.customAert = YES;
        self.dismissWhenTouchBackground = dismissWhenTouchBackground;
    }
    return self;
}

- (void)show {
    [[AMGCSingleTon shareSingleTon].alertStack addObject:self];
    
    [self showAlert];
}

- (void)dismissWithCompletion:(void (^)(void))completion {
    [self dismissWithCompletion:^{
        if ( completion ) {
            completion();
        }
    }];
}

+ (void)showOneButtonWithTitle:(NSString *)title Message:(NSString *)message ButtonType:(AMGAlertViewButtonType)buttonType ButtonTitle:(NSString *)buttonTitle Click:(clickHandle)click {
    id newClick = click;
    if ( !newClick ) {
        newClick = [NSNull null];
    }
    AMGAlertView *alertView = [AMGAlertView new];
    [alertView configAlertViewPropertyWithTitle:title Message:message Buttons:@[@{[NSString stringWithFormat:@"%zi", buttonType] : buttonTitle}] Clicks:@[newClick] ClickWithIndex:nil];
}

+ (void)showTwoButtonsWithTitle:(NSString *)title Message:(NSString *)message ButtonType:(AMGAlertViewButtonType)buttonType ButtonTitle:(NSString *)buttonTitle Click:(clickHandle)click ButtonType:(AMGAlertViewButtonType)buttonType1 ButtonTitle:(NSString *)buttonTitle1 Click:(clickHandle)click1 {
    id newClick = click;
    if ( !newClick ) {
        newClick = [NSNull null];
    }
    id newClick1 = click1;
    if ( !newClick1 ) {
        newClick1 = [NSNull null];
    }
    AMGAlertView *alertView = [AMGAlertView new];
    [alertView configAlertViewPropertyWithTitle:title Message:message Buttons:@[@{[NSString stringWithFormat:@"%zi", buttonType] : buttonTitle}, @{[NSString stringWithFormat:@"%zi", buttonType1] : buttonTitle1}] Clicks:@[newClick, newClick1] ClickWithIndex:nil];
}

+ (void)showMultipleButtonsWithTitle:(NSString *)title Message:(NSString *)message Click:(clickHandleWithIndex)click Buttons:(NSDictionary *)buttons, ... {
    NSMutableArray *btnArray = [NSMutableArray array];
    NSString *curStr;
    va_list list;
    if ( buttons ) {
        [btnArray addObject:buttons];
        
        va_start(list, buttons);
        while ( (curStr = va_arg(list, NSString *))) {
            [btnArray addObject:curStr];
        }
        va_end(list);
    }
    NSMutableArray *btns = [NSMutableArray array];
    for ( NSInteger i = 0; i < btnArray.count; i++ ) {
        NSDictionary *dic = btnArray[i];
        [btns addObject:@{dic.allKeys.firstObject : dic.allValues.firstObject}];
    }
    
    AMGAlertView *alertView = [AMGAlertView new];
    [alertView configAlertViewPropertyWithTitle:title Message:message Buttons:btns Clicks:nil ClickWithIndex:click];
    
}

- (void)configAlertViewPropertyWithTitle:(NSString *)title Message:(NSString *)message Buttons:(NSArray *)buttons Clicks:(NSArray *)clicks ClickWithIndex:(clickHandleWithIndex)clickWithIndex {
    self.title = title;
    self.message = message;
    self.buttons = buttons;
    self.clicks = clicks;
    self.clickWithIndex = clickWithIndex;
    
    [[AMGCSingleTon shareSingleTon].alertStack addObject:self];
    
    [self showAlert];
}

- (void)showAlert {
    NSInteger count = [AMGCSingleTon shareSingleTon].alertStack.count;
    AMGAlertView *previousAlert = nil;
    if ( count > 1 ) {
        NSInteger index = [[AMGCSingleTon shareSingleTon].alertStack indexOfObject:self];
        previousAlert = [AMGCSingleTon shareSingleTon].alertStack[index - 1];
    }
    
    if ( previousAlert && previousAlert.vc ) {
        if ( previousAlert.isAlertReady ) {
            [previousAlert.vc hideAlertWithCompletion:^{
                [self showAlertHandle];
            }];
        } else {
            [self showAlertHandle];
        }
    } else {
        [self showAlertHandle];
    }
}

- (void)showAlertHandle {
    UIWindow *keywindow = [UIApplication sharedApplication].keyWindow;
    if ( keywindow != [AMGCSingleTon shareSingleTon].backgroundWindow ) {
        [AMGCSingleTon shareSingleTon].oldKeyWindow = [UIApplication sharedApplication].keyWindow;
    }
    
    AMGViewController *vc = [[AMGViewController alloc] init];
    vc.delegate = self;
    vc.alertView = self;
    self.vc = vc;
    
    [AMGCSingleTon shareSingleTon].backgroundWindow.frame = [UIScreen mainScreen].bounds;
    [[AMGCSingleTon shareSingleTon].backgroundWindow makeKeyAndVisible];
    [AMGCSingleTon shareSingleTon].backgroundWindow.rootViewController = self.vc;
    
    [self.vc showAlert];
}

- (void)coverViewTouched {
    if ( self.isDismissWhenTouchBackground ) {
        [self dismissWithCompletion:nil];
    }
}

- (void)alertBtnClick:(UIButton *)btn {
    [self dismissWithCompletion:^{
        if ( self.clicks.count > 0 ) {
            clickHandle handle = self.clicks[btn.tag];
            if ( ![handle isEqual:[NSNull null]] ) {
                handle();
            }
        } else {
            if ( self.clickWithIndex ) {
                self.clickWithIndex( btn.tag );
            }
        }
    }];
}

- (void)dismissAllertWithCompletion:(void (^)(void))completion {
    [self.vc hideAlertWithCompletion:^{
        [self stackHandle];
        
        if ( completion ) {
            completion();
        }
        
        NSInteger count = [AMGCSingleTon shareSingleTon].alertStack.count;
        if ( count > 0 ) {
            AMGAlertView *lastAlert = [AMGCSingleTon shareSingleTon].alertStack.lastObject;
            [lastAlert showAlert];
        }
    }];
}

- (void)stackHandle {
    [[AMGCSingleTon shareSingleTon].alertStack removeObject:self];
    
    NSInteger count = [AMGCSingleTon shareSingleTon].alertStack.count;
    if ( count == 0 ) {
        [self toggleKeyWindow];
    }
}

- (void)toggleKeyWindow {
    [[AMGCSingleTon shareSingleTon].oldKeyWindow makeKeyAndVisible];
    [AMGCSingleTon shareSingleTon].backgroundWindow.rootViewController = nil;
    [AMGCSingleTon shareSingleTon].backgroundWindow.frame = CGRectZero;
}

- (void)setup {
    if (self.subviews.count > 0) {
        return;
    }
    
    if (self.isCustomAlert) {
        return;
    }
    
    self.layer.masksToBounds=true;
    self.layer.cornerRadius=8;
    
    self.frame = CGRectMake(0, 0, AMGAlertViewWidth, AMGAlertViewHeight);
    NSInteger count = self.buttons.count;
    
    if (count > 2) {
        self.frame = CGRectMake(0, 0, AMGAlertViewWidth, AMGAlertViewTitleLabelHeight + AMGAlertViewContentHeight + AMGMargin + (AMGMargin + AMGButtonHeight) * count);
    }
    self.center = CGPointMake(AMGScreenWidth / 2, AMGScreenHeight / 2);
    self.backgroundColor = [UIColor whiteColor];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(AMGMargin, 0, AMGAlertViewWidth - AMGMargin * 2, AMGAlertViewTitleLabelHeight)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = self.title;
    titleLabel.textColor = AMGAlertViewTitleColor;
    titleLabel.font = AMGAlertViewTitleFont;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:titleLabel];
    
    CGFloat contentLabelYValue=AMGAlertViewTitleLabelHeight;
    if (self.title.length==0||self.title==nil) {
        contentLabelYValue=10;
    }
    
    UILabel *contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(AMGContentMargin, contentLabelYValue, AMGAlertViewWidth - AMGContentMargin * 2, AMGAlertViewContentHeight)];
    contentLabel.backgroundColor = [UIColor clearColor];
    contentLabel.text = self.message;
    contentLabel.textColor = AMGAlertViewContentColor;
    contentLabel.font = AMGAlertViewContentFont;
    contentLabel.numberOfLines = 0;
    contentLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:contentLabel];
    
    CGFloat contentHeight = [contentLabel sizeThatFits:CGSizeMake(AMGAlertViewWidth-AMGContentMargin*2, CGFLOAT_MAX)].height;
    
    if (contentHeight > AMGAlertViewContentHeight) {
        [contentLabel removeFromSuperview];
        
        UITextView *contentView = [[UITextView alloc] initWithFrame:CGRectMake(AMGContentMargin, contentLabelYValue, AMGAlertViewWidth - AMGContentMargin * 2, AMGAlertViewContentHeight)];
        contentView.backgroundColor = [UIColor clearColor];
        contentView.text = self.message;
        contentView.textColor = AMGAlertViewContentColor;
        contentView.font = AMGAlertViewContentFont;
        contentView.editable = NO;
        if (AMGiOS7OrLater) {
            contentView.selectable = NO;
        }
        [self addSubview:contentView];
        
        CGFloat realContentHeight = 0;
        if (AMGiOS7OrLater) {
            [contentView.layoutManager ensureLayoutForTextContainer:contentView.textContainer];
            CGRect textBounds = [contentView.layoutManager usedRectForTextContainer:contentView.textContainer];
            CGFloat height = (CGFloat)ceil(textBounds.size.height + contentView.textContainerInset.top + contentView.textContainerInset.bottom);
            realContentHeight = height;
        }else {
            realContentHeight = contentView.contentSize.height;
        }
        
        if (realContentHeight > AMGAlertViewContentHeight) {
            CGFloat remainderHeight = AMGAlertViewMaxHeight - AMGAlertViewTitleLabelHeight - AMGMargin - (AMGMargin + AMGButtonHeight) * count;
            contentHeight = realContentHeight;
            if (realContentHeight > remainderHeight) {
                contentHeight = remainderHeight;
            }
            
            CGRect frame = contentView.frame;
            frame.size.height = contentHeight;
            contentView.frame = frame;
            
            CGRect selfFrame = self.frame;
            selfFrame.size.height = selfFrame.size.height + contentHeight - AMGAlertViewContentHeight;
            self.frame = selfFrame;
            self.center = CGPointMake(AMGScreenWidth / 2, AMGScreenHeight / 2);
        }
    }
    
    if (!AMGiOS7OrLater) {
        CGRect frame = self.frame;
        frame.origin.y -= 10;
        self.frame = frame;
    }
    
    if (count == 1) {
        
        //增加线条
        UIView *lineView=[[UIView alloc]initWithFrame:CGRectMake(AMGMargin, self.frame.size.height - AMGButtonHeight - AMGMargin, AMGAlertViewWidth - AMGMargin * 2, 0.3)];
        lineView.backgroundColor=[UIColor grayColor];
        [self addSubview:lineView];
        
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(AMGMargin, self.frame.size.height - AMGButtonHeight - AMGMargin, AMGAlertViewWidth - AMGMargin * 2, AMGButtonHeight)];
        NSDictionary *btnDict = [self.buttons firstObject];
        [btn setTitle:[btnDict.allValues firstObject] forState:UIControlStateNormal];
        [self setButton:btn BackgroundWithButonType:[[btnDict.allKeys firstObject] integerValue]];
        [self addSubview:btn];
        btn.tag = 0;
        [btn addTarget:self action:@selector(alertBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    } else if (count == 2) {
        CGFloat btnWidth = AMGAlertViewWidth / 2 - AMGMargin * 1.5;
        
        //增加两条线
        UIView *lineView=[[UIView alloc]initWithFrame:CGRectMake(AMGMargin, self.frame.size.height - AMGButtonHeight - AMGMargin, AMGAlertViewWidth - AMGMargin * 2, 0.3)];
        lineView.backgroundColor=[UIColor grayColor];
        [self addSubview:lineView];
        
        UIView *seperateLine=[[UIView alloc]initWithFrame:CGRectMake(AMGMargin + (AMGMargin + btnWidth), self.frame.size.height - AMGButtonHeight - AMGMargin,0.3, AMGButtonHeight)];
        seperateLine.backgroundColor=[UIColor grayColor];
        [self addSubview:seperateLine];
        
        for (int i = 0; i < 2; i++) {
            
            UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(AMGMargin + (AMGMargin + btnWidth) * i, self.frame.size.height - AMGButtonHeight - AMGMargin, btnWidth, AMGButtonHeight)];
            NSDictionary *btnDict = self.buttons[i];
            [btn setTitle:[btnDict.allValues firstObject] forState:UIControlStateNormal];
            [self setButton:btn BackgroundWithButonType:[[btnDict.allKeys firstObject] integerValue]];
            [self addSubview:btn];
            btn.tag = i;
            [btn addTarget:self action:@selector(alertBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        }
    } else if (count > 2) {
        if (contentHeight < AMGAlertViewContentHeight) {
            contentHeight = AMGAlertViewContentHeight;
        }
        for (int i = 0; i < count; i++) {
            UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(AMGMargin, contentLabelYValue + contentHeight + AMGMargin + (AMGMargin + AMGButtonHeight) * i, AMGAlertViewWidth - AMGMargin * 2, AMGButtonHeight)];
            NSDictionary *btnDict = self.buttons[i];
            [btn setTitle:[btnDict.allValues firstObject] forState:UIControlStateNormal];
            [self setButton:btn BackgroundWithButonType:[[btnDict.allKeys firstObject] integerValue]];
            [self addSubview:btn];
            btn.tag = i;
            [btn addTarget:self action:@selector(alertBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (void)setButton:(UIButton *)btn BackgroundWithButonType:(AMGAlertViewButtonType)buttonType {
    UIColor *textColor = nil;
    UIImage *normalImage = nil;
    UIImage *highImage = nil;
    // 可以不断的扩展 button 样式
    switch ( buttonType ) {
        case AMGAlertViewButtonTypeDefault:
            normalImage = [self imageFromColorWithColor:[UIColor blueColor]];
            highImage = [self imageFromColorWithColor:[UIColor blueColor]];
            textColor = AMGColor(255, 255, 255);
            [btn setBackgroundImage:[self resizeImage:normalImage] forState:UIControlStateNormal];
            [btn setBackgroundImage:[self resizeImage:highImage] forState:UIControlStateHighlighted];
            [btn setTitleColor:textColor forState:UIControlStateNormal];
            break;
        case AMGAlertViewButtonTypeCancel:
            normalImage = [self imageFromColorWithColor:AMGColor(105, 105, 105)];
            highImage = [self imageFromColorWithColor:AMGColor(105, 105, 105)];
            [btn setBackgroundImage:[self resizeImage:normalImage] forState:UIControlStateNormal];
            [btn setBackgroundImage:[self resizeImage:highImage] forState:UIControlStateHighlighted];
            [btn setTitleColor:textColor forState:UIControlStateNormal];
            textColor = AMGColor(255, 255, 255);
            break;
        case AMGAlertViewButtonTypeWarn:
            normalImage = [self imageFromColorWithColor:AMGColor(255, 99, 71)];
            highImage = [self imageFromColorWithColor:AMGColor(255, 99, 71)];
            [btn setBackgroundImage:[self resizeImage:normalImage] forState:UIControlStateNormal];
            [btn setBackgroundImage:[self resizeImage:highImage] forState:UIControlStateHighlighted];
            [btn setTitleColor:textColor forState:UIControlStateNormal];
            textColor = AMGColor(255, 255, 255);
            break;
        case AMGAlertViewButtonTypeNone:
            
            textColor = [UIColor blueColor];
            [btn setTitleColor:textColor forState:UIControlStateNormal];
            break;
        case AMGAlertViewButtonTypeHeight:
            
            textColor = [UIColor blueColor];
            [btn setTitleColor:textColor forState:UIControlStateNormal];
            break;
    }
}

- (UIImage *)resizeImage:(UIImage *)image{
    return [image stretchableImageWithLeftCapWidth:image.size.width / 2 topCapHeight:image.size.height / 2];
}

- (UIImage *)imageFromColorWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
@end
