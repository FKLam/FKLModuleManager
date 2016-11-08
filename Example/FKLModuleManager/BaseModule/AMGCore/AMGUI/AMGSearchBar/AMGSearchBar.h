//
//  AMGSearchBar.h
//  FKLModuleManager
//
//  Created by amglfk on 16/11/8.
//  Copyright © 2016年 FKLam. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, AMGSearchBarIconAlign) {
    AMGSearchBarIconAlignLeft,
    AMGSearchBarIconAlignCenter
};

@class AMGSearchBar;
@protocol AMGSearchBarDelegate <UIBarPositioningDelegate>

@optional

-(BOOL)searchBarShouldBeginEditing:(AMGSearchBar *)searchBar;                      // return NO to not become first responder
- (void)searchBarTextDidBeginEditing:(AMGSearchBar *)searchBar;                     // called when text starts editing
- (BOOL)searchBarShouldEndEditing:(AMGSearchBar *)searchBar;                        // return NO to not resign first responder
- (void)searchBarTextDidEndEditing:(AMGSearchBar *)searchBar;                       // called when text ends editing
- (void)searchBar:(AMGSearchBar *)searchBar textDidChange:(NSString *)searchText;   // called when text changes (including clear)
- (BOOL)searchBar:(AMGSearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text; // called before text changes

- (void)searchBarSearchButtonClicked:(AMGSearchBar *)searchBar;                     // called when keyboard search button pressed
- (void)searchBarCancelButtonClicked:(AMGSearchBar *)searchBar;                     // called when cancel button pressed
// called when cancel button pressed

@end

@interface AMGSearchBar : UIView<UITextInputTraits>

@property (nonatomic, assign) id<AMGSearchBarDelegate> delegate;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, strong) UIFont *textFont;
@property (nonatomic, copy) NSString *placeholder;
@property (nonatomic, strong) UIColor *placeholderColor;
@property (nonatomic, strong) UIImage *iconImage;
@property (nonatomic, strong) UIImage *backgroundImage;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, assign) UITextBorderStyle textBorderStyle;
@property (nonatomic, assign) UIKeyboardType keyboardType;
@property (nonatomic, assign) AMGSearchBarIconAlign iconAlign;
@property (nonatomic, readwrite, strong) UIView *inputAccessoryView;
@property (nonatomic, readwrite, strong) UIView *inputView;

- (BOOL)resignFirstResponder;
- (void)setAutoCapitalizationMode:(UITextAutocapitalizationType)type;

@end
