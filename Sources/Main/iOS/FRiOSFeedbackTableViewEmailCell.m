//
//  FRiOSFeedbackTableViewEmailCell.m
//  F53FeedbackKit
//
//  Created by Brent Lord on 9/22/15.
//  Copyright © 2015-2019 Figure 53, LLC. All rights reserved.
//

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "FRiOSFeedbackTableViewEmailCell.h"


NS_ASSUME_NONNULL_BEGIN

@implementation FRiOSFeedbackTableViewEmailCell

#pragma mark UITextFieldDelegate

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    self.emailBox.textColor = nil;
    
    self.emailBox.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    if ( @available(iOS 10.0, *) )
    {
        self.emailBox.adjustsFontForContentSizeCategory = YES;
    }
    else
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUIContentSizeCategoryDidChange:) name:UIContentSizeCategoryDidChangeNotification object:nil];
    }
    
    self.emailBox.delegate = self;
}

- (void) dealloc
{
    if ( @available(iOS 10.0, *) )
    {
        // nuthin
    }
    else
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIContentSizeCategoryDidChangeNotification object:nil];
    }
}

- (CGSize) systemLayoutSizeFittingSize:(CGSize)targetSize
{
    CGSize size = [super systemLayoutSizeFittingSize:targetSize];
    CGSize sizeThatFits = [self sizeThatFits:size];
    return CGSizeMake( size.width, fmax( size.height, sizeThatFits.height ) );
}

- (CGSize) systemLayoutSizeFittingSize:(CGSize)targetSize withHorizontalFittingPriority:(UILayoutPriority)horizontalFittingPriority verticalFittingPriority:(UILayoutPriority)verticalFittingPriority
{
    CGSize size = [super systemLayoutSizeFittingSize:targetSize withHorizontalFittingPriority:horizontalFittingPriority verticalFittingPriority:verticalFittingPriority];
    CGSize sizeThatFits = [self sizeThatFits:size];
    return CGSizeMake( size.width, fmax( size.height, sizeThatFits.height ) );
}

#pragma mark - UITextFieldDelegate

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    if ( textField == self.emailBox ) {
        [[NSNotificationCenter defaultCenter] postNotificationName:FRiOSFeedbackTableViewEmailCellDidEndEditingNotification
                                                            object:textField];
    }
}

#pragma mark - Notification handlers

- (void) handleUIContentSizeCategoryDidChange:(NSNotification *)notification
{
    self.emailBox.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

@end

NS_ASSUME_NONNULL_END
