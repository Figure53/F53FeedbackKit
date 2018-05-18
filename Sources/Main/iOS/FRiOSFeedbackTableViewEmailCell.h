//
//  FRiOSFeedbackTableViewEmailCell.h
//  F53FeedbackKit
//
//  Created by Brent Lord on 9/22/15.
//  Copyright © 2015-2018 Figure 53, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

static NSString *FRiOSFeedbackTableViewEmailCellIdentifier = @"FRiOSFeedbackTableViewEmailCellIdentifier";
static NSString *FRiOSFeedbackTableViewEmailCellDidEndEditingNotification = @"FRiOSFeedbackTableViewEmailCellDidEndEditingNotification";


@interface FRiOSFeedbackTableViewEmailCell : UITableViewCell <UITextFieldDelegate>

@property (nonatomic, weak)     IBOutlet UITextField *emailBox;

@end

NS_ASSUME_NONNULL_END
