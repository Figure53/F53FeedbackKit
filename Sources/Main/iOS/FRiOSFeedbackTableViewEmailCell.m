//
//  FRiOSFeedbackTableViewEmailCell.m
//  F53FeedbackKit
//
//  Created by Brent Lord on 9/22/15.
//  Copyright © 2015 Figure 53, LLC. All rights reserved.
//

#import "FRiOSFeedbackTableViewEmailCell.h"

@implementation FRiOSFeedbackTableViewEmailCell

#pragma mark UITextFieldDelegate

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    self.emailBox.delegate = self;
}


#pragma mark UITextFieldDelegate

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    if ( textField == self.emailBox ) {
        [[NSNotificationCenter defaultCenter] postNotificationName:FRiOSFeedbackTableViewEmailCellDidEndEditingNotification
                                                            object:textField];
    }
}


@end
