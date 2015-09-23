//
//  FRiOSFeedbackTableViewCheckmarkCell.h
//  F53FeedbackKit
//
//  Created by Brent Lord on 9/22/15.
//  Copyright © 2015 Figure 53, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * FRiOSFeedbackTableViewCheckmarkCellIdentifier = @"FRiOSFeedbackTableViewCheckmarkCellIdentifier";

@interface FRiOSFeedbackTableViewCheckmarkCell : UITableViewCell

@property (nonatomic)       BOOL checkmarkOn;

- (void) startSpinner;
- (void) stopSpinner;

@end
