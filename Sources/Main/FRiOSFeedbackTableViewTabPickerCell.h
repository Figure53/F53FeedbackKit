//
//  FRiOSFeedbackTableViewTabPickerCell.h
//  F53FeedbackKit
//
//  Created by Brent Lord on 9/22/15.
//  Copyright © 2015 Figure 53, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * FRiOSFeedbackTableViewTabPickerCellIdentifier = @"FRiOSFeedbackTableViewTabPickerCellIdentifier";
static NSString * FRiOSFeedbackTableViewTabPickerCellTabItemDidChangeNotification = @"FRiOSFeedbackTableViewTabPickerCellTabItemDidChangeNotification";


@interface FRiOSFeedbackTableViewTabPickerCell : UITableViewCell

- (void) configureControlWithItems:(NSArray *)tabItems selectedItem:(id)selectedItem;

@end
