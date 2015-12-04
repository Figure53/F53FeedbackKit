//
//  FRiOSFeedbackTableViewEmailCell.h
//  F53FeedbackKit
//
//  Created by Brent Lord on 9/22/15.
//  Copyright © 2015 Figure 53, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString *FRiOSFeedbackTableViewEmailCellIdentifier = @"FRiOSFeedbackTableViewEmailCellIdentifier";
static NSString *FRiOSFeedbackTableViewEmailCellDidEndEditingNotification = @"FRiOSFeedbackTableViewEmailCellDidEndEditingNotification";

@interface FRiOSFeedbackTableViewEmailCell : UITableViewCell <UITextFieldDelegate>

@property (nonatomic, weak)     IBOutlet UITextField *emailBox;

@end
