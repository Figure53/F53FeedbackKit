//
//  FRiOSFeedbackTableViewTabPickerCell.h
//  F53FeedbackKit
//
//  Created by Brent Lord on 9/22/15.
//  Copyright © 2015-2018 Figure 53, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

static NSString *FRiOSFeedbackTableViewTabPickerCellIdentifier = @"FRiOSFeedbackTableViewTabPickerCellIdentifier";
static NSString *FRiOSFeedbackTableViewTabPickerCellTabItemDidChangeNotification = @"FRiOSFeedbackTableViewTabPickerCellTabItemDidChangeNotification";


@interface FRiOSFeedbackTableViewTabPickerCell : UITableViewCell

@property (weak, nonatomic)     IBOutlet UISegmentedControl *tabControl;

- (void) configureControlWithItems:(NSArray *)tabItems selectedItem:(id)selectedItem;

@end

NS_ASSUME_NONNULL_END
