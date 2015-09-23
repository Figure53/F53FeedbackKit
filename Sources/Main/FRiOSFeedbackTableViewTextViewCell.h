//
//  FRiOSFeedbackTableViewTextViewCell.h
//  F53FeedbackKit
//
//  Created by Brent Lord on 9/22/15.
//  Copyright © 2015 Figure 53, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * FRiOSFeedbackTableViewTextViewCellIdentifier = @"FRiOSFeedbackTableViewTextViewCellIdentifier";
static NSString * FRiOSFeedbackTableViewTextViewCellDidEndEditingNotification = @"FRiOSFeedbackTableViewTextViewCellDidEndEditingNotification";

@interface FRiOSFeedbackTableViewTextViewCell : UITableViewCell <UITextViewDelegate>

@property (nonatomic, weak)     IBOutlet UITextView *textView;
@property (nonatomic, weak)     IBOutlet UITextView *textViewPlaceholder;

@end
