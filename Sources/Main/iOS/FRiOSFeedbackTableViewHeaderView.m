//
//  FRiOSFeedbackTableViewHeaderView.m
//  F53FeedbackKit
//
//  Created by Brent Lord on 8/29/19.
//  Copyright 2019 Figure 53, LLC. All rights reserved.
//

#import "FRiOSFeedbackTableViewHeaderView.h"


NS_ASSUME_NONNULL_BEGIN

#define DEFAULT_FONT_SIZE           13.0
#define DEFAULT_TOP_MARGIN          14.0

NSString * const FRiOSFeedbackTableViewHeaderViewIdentifier = @"FRiOSFeedbackTableViewHeaderViewIdentifier";


@interface FRiOSFeedbackTableViewHeaderView ()

@property (nonatomic, strong, null_resettable)  UILabel *customTextLabel;
@property (nonatomic)                           CGFloat topMargin;

@property (nonatomic, strong)                   NSLayoutConstraint *customTextLabelConstraint_top;

+ (CGFloat) defaultTopMargin;

- (void) resetTextLabelFormat;
- (void) resetTopMargin;

@end


@implementation FRiOSFeedbackTableViewHeaderView

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
    
    self.textLabel.adjustsFontForContentSizeCategory = NO;
    self.detailTextLabel.adjustsFontForContentSizeCategory = NO;
    
    [self.contentView addSubview:self.customTextLabel];
    
    [self.customTextLabel.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor].active = YES;
    [self.customTextLabel.lastBaselineAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.bottomAnchor].active = YES;
    [self.customTextLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor].active = YES;
    
    NSLayoutConstraint *ctl_t = [self.customTextLabel.topAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.topAnchor constant:[[self class] defaultTopMargin]];
    ctl_t.priority = UILayoutPriorityDefaultHigh - 1; // needed to avoid ambiguity when contentView size is 0,0
    ctl_t.active = YES;
    self.customTextLabelConstraint_top = ctl_t;
    
    self.userInteractionEnabled = NO;
}

+ (UIFont *) defaultFont
{
    return [UIFont systemFontOfSize:DEFAULT_FONT_SIZE weight:UIFontWeightRegular];
}

+ (CGFloat) defaultTopMargin
{
    return DEFAULT_TOP_MARGIN;
}

#pragma mark - subclass overrides

- (void) prepareForReuse
{
    [super prepareForReuse];
    
    self.userInteractionEnabled = NO;
    
    self.textLabel.text = nil;
    self.detailTextLabel.text = nil;
    
    [self resetTextLabelFormat];
    [self resetTopMargin];
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
        [customTextLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        
        [customTextLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [customTextLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
        
        _customTextLabel = customTextLabel;
        
        [self resetTextLabelFormat];
    }
    return _customTextLabel;
}

- (CGFloat) topMargin
{
    return self.customTextLabelConstraint_top.constant;
}

- (void) setTopMargin:(CGFloat)topMargin
{
    self.customTextLabelConstraint_top.constant = topMargin;
}

#pragma mark -

- (void) resetTextLabelFormat
{
    _customTextLabel.font = [[self class] defaultFont];
    _customTextLabel.backgroundColor = [UIColor clearColor];
    _customTextLabel.opaque = NO;
    _customTextLabel.adjustsFontSizeToFitWidth = NO;
    _customTextLabel.textColor = [UIColor colorWithWhite:0.43 alpha:1.0];
    _customTextLabel.numberOfLines = 1;
    _customTextLabel.textAlignment = NSTextAlignmentLeft;
}

- (void) resetTopMargin
{
    self.topMargin = [[self class] defaultTopMargin];
}

@end

NS_ASSUME_NONNULL_END
