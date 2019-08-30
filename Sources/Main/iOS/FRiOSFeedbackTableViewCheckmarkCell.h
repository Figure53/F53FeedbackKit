//
//  FRiOSFeedbackTableViewCheckmarkCell.h
//  F53FeedbackKit
//
//  Created by Brent Lord on 9/22/15.
//  Copyright © 2015-2019 Figure 53, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

static NSString *FRiOSFeedbackTableViewCheckmarkCellIdentifier = @"FRiOSFeedbackTableViewCheckmarkCellIdentifier";

@interface FRiOSFeedbackTableViewCheckmarkCell : UITableViewCell

@property (nonatomic)       BOOL checkmarkOn;

- (void) startSpinner;
- (void) stopSpinner;

@end

NS_ASSUME_NONNULL_END
