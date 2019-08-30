//
//  FRiOSFeedbackTableViewTextViewCell.h
//  F53FeedbackKit
//
//  Created by Brent Lord on 9/22/15.
//  Copyright © 2015-2019 Figure 53, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

static NSString *FRiOSFeedbackTableViewTextViewCellIdentifier = @"FRiOSFeedbackTableViewTextViewCellIdentifier";
static NSString *FRiOSFeedbackTableViewTextViewCellDidEndEditingNotification = @"FRiOSFeedbackTableViewTextViewCellDidEndEditingNotification";


@interface FRiOSFeedbackTableViewTextViewCell : UITableViewCell <UITextViewDelegate>

@property (nonatomic, weak)     IBOutlet UITextView *textView;
@property (nonatomic, weak)     IBOutlet UITextView *textViewPlaceholder;

@end

NS_ASSUME_NONNULL_END
