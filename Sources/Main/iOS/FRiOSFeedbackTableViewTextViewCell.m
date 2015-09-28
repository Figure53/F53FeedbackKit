//
//  FRiOSFeedbackTableViewTextViewCell.m
//  F53FeedbackKit
//
//  Created by Brent Lord on 9/22/15.
//  Copyright © 2015 Figure 53, LLC. All rights reserved.
//

#import "FRiOSFeedbackTableViewTextViewCell.h"

@implementation FRiOSFeedbackTableViewTextViewCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    self.textView.text = nil;
    self.textViewPlaceholder.text = nil;
    
    self.textView.delegate = self;
    
    self.textView.layer.borderColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
    self.textView.layer.borderWidth = 0.5f;
    self.textView.layer.cornerRadius = 5.0f;
}

- (void) prepareForReuse
{
    [super prepareForReuse];
    
    self.textView.text = nil;
    self.textViewPlaceholder.text = nil;
    
    self.textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

#pragma mark UITextViewDelegate

- (void) textViewDidChange:(UITextView *)textView
{
    if ( textView == self.textView ) {
        self.textViewPlaceholder.hidden = ( [textView.text length] > 0 );
    }
}

- (void) textViewDidEndEditing:(UITextView *)textView
{
    if ( textView == self.textView ) {
        [[NSNotificationCenter defaultCenter] postNotificationName:FRiOSFeedbackTableViewTextViewCellDidEndEditingNotification
                                                            object:textView];
    }
}
@end
