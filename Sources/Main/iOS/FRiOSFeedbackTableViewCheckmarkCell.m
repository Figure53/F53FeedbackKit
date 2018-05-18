//
//  FRiOSFeedbackTableViewCheckmarkCell.m
//  F53FeedbackKit
//
//  Created by Brent Lord on 9/22/15.
//  Copyright © 2015-2018 Figure 53, LLC. All rights reserved.
//

#import "FRiOSFeedbackTableViewCheckmarkCell.h"


NS_ASSUME_NONNULL_BEGIN

@implementation FRiOSFeedbackTableViewCheckmarkCell

- (void) prepareForReuse
{
    [super prepareForReuse];
    
    self.indentationLevel = 0;
}

- (void) setSelected:(BOOL)selected
{
    // disable cell selection
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    // disable cell selection
}

- (void) setCheckmarkOn:(BOOL)checkmarkOn
{
    if ( _checkmarkOn != checkmarkOn ) {
        
        _checkmarkOn = checkmarkOn;
        self.accessoryType = ( _checkmarkOn ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone );
        
    }
}

- (void) startSpinner
{
    UIActivityIndicatorViewStyle indicatorStyle = UIActivityIndicatorViewStyleGray;
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:indicatorStyle];
    activityView.color = self.tintColor;
    [activityView startAnimating];
    activityView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    
    self.accessoryView = activityView;
}

- (void) stopSpinner
{
    self.accessoryView = nil;
}

@end

NS_ASSUME_NONNULL_END
