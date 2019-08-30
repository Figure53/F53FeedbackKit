//
//  FRiOSFeedbackTableViewFooterView.m
//  F53FeedbackKit
//
//  Created by Brent Lord on 8/29/19.
//  Copyright 2019 Figure 53, LLC. All rights reserved.
//

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "FRiOSFeedbackTableViewFooterView.h"


NS_ASSUME_NONNULL_BEGIN

#define DEFAULT_FONT_SIZE       14.0
#define DEFAULT_BOTTOM_MARGIN   12.0

NSString * const FRiOSFeedbackTableViewFooterViewIdentifier = @"FRiOSFeedbackTableViewFooterViewIdentifier";


@interface FRiOSFeedbackTableViewFooterView ()

@property (nonatomic, strong, null_resettable)  UILabel *customTextLabel;
@property (nonatomic)                           CGFloat bottomMargin;

@property (nonatomic, strong)                   NSLayoutConstraint *customTextLabelConstraint_bottom;

+ (CGFloat) defaultBottomMargin;

- (void) resetTextLabelFormat;
- (void) resetBottomMargin;

@end


@implementation FRiOSFeedbackTableViewFooterView

- (instancetype) initWithReuseIdentifier:(nullable NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if ( self )
    {
        [self finishInit];
    }
    return self;
}

- (nullable instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if ( self )
    {
        [self finishInit];
    }
    return self;
}

- (void) finishInit
{
    self.backgroundView = [UIView new];
    self.contentView.autoresizesSubviews = NO;
    self.contentView.backgroundColor = [UIColor clearColor];
    
    [self.contentView addSubview:self.customTextLabel];
    
    [self.customTextLabel.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor].active = YES;
    [self.customTextLabel.topAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.topAnchor].active = YES;
    [self.customTextLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor].active = YES;
    
    NSLayoutConstraint *ctl_b = [self.customTextLabel.lastBaselineAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.bottomAnchor constant:[[self class] defaultBottomMargin]];
    ctl_b.priority = UILayoutPriorityDefaultHigh - 1; // needed to avoid ambiguity when contentView size is 0,0
    ctl_b.active = YES;
    self.customTextLabelConstraint_bottom = ctl_b;
    
    self.userInteractionEnabled = NO;
}

+ (UIFont *) defaultFont
{
    return [UIFont systemFontOfSize:DEFAULT_FONT_SIZE weight:UIFontWeightRegular];
}

+ (CGFloat) defaultBottomMargin
{
    return DEFAULT_BOTTOM_MARGIN;
}

#pragma mark - subclass overrides

- (void) prepareForReuse
{
    [super prepareForReuse];
    
    self.userInteractionEnabled = NO;
    
    self.textLabel.text = nil;
    
    [self resetTextLabelFormat];
    [self resetBottomMargin];
}

- (nullable UILabel *) textLabel
{
    return self.customTextLabel;
}



#pragma mark - custom getters/setters

- (UILabel *) customTextLabel
{
    if ( !_customTextLabel )
    {
        UILabel *customTextLabel = [UILabel new];
        customTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        [customTextLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [customTextLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
        
        [customTextLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [customTextLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        
        _customTextLabel = customTextLabel;
        
        [self resetTextLabelFormat];
    }
    return _customTextLabel;
}

- (CGFloat) bottomMargin
{
    return self.customTextLabelConstraint_bottom.constant;
}

- (void) setBottomMargin:(CGFloat)bottomMargin
{
    self.customTextLabelConstraint_bottom.constant = bottomMargin;
}

#pragma mark -

- (void) resetTextLabelFormat
{
    _customTextLabel.font = [[self class] defaultFont];
    _customTextLabel.backgroundColor = [UIColor clearColor];
    _customTextLabel.opaque = NO;
    _customTextLabel.adjustsFontSizeToFitWidth = YES;
    _customTextLabel.textColor = [UIColor colorWithWhite:0.43 alpha:1.0];
    _customTextLabel.shadowColor = nil;
    _customTextLabel.numberOfLines = 0;
    _customTextLabel.textAlignment = NSTextAlignmentLeft;
}

- (void) resetBottomMargin
{
    self.bottomMargin = [[self class] defaultBottomMargin];
}

@end

NS_ASSUME_NONNULL_END
