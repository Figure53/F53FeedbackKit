//
//  FRiOSFeedbackTableViewHeaderView.h
//  F53FeedbackKit
//
//  Created by Brent Lord on 8/29/19.
//  Copyright 2019 Figure 53, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const FRiOSFeedbackTableViewHeaderViewIdentifier;


NS_CLASS_AVAILABLE_IOS(10_0) @interface FRiOSFeedbackTableViewHeaderView : UITableViewHeaderFooterView

+ (UIFont *) defaultFont;

@end

NS_ASSUME_NONNULL_END
