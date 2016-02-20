//
//  FRiOSFeedbackTableViewTabPickerCell.m
//  F53FeedbackKit
//
//  Created by Brent Lord on 9/22/15.
//  Copyright © 2015 Figure 53, LLC. All rights reserved.
//

#import "FRiOSFeedbackTableViewTabPickerCell.h"

@interface FRiOSFeedbackTableViewTabPickerCell ()

@property (nonatomic, strong)   NSArray *tabItems;

- (IBAction)handleSegmentedControlDidChange:(UISegmentedControl *)sender;

@end


@implementation FRiOSFeedbackTableViewTabPickerCell

//- (void) awakeFromNib
//{
//    [super awakeFromNib];
//}

- (void) configureControlWithItems:(NSArray *)tabItems selectedItem:(id)selectedItem
{
    self.tabItems = [tabItems copy];
    
    [self.tabControl removeAllSegments];
    for ( NSDictionary *aTabItem in tabItems ) {
        NSString *label = [aTabItem objectForKey:@"label"];
        [self.tabControl insertSegmentWithTitle:label atIndex:self.tabControl.numberOfSegments animated:NO];
    }
    
    NSInteger selectedIndex = UISegmentedControlNoSegment;
    if ( [self.tabItems containsObject:selectedItem] ) {
        selectedIndex = [self.tabItems indexOfObject:selectedItem];
    }
    else if ( self.tabItems.count ) {
        selectedIndex = 0;
    }
    self.tabControl.selectedSegmentIndex = selectedIndex;
    [self handleSegmentedControlDidChange:self.tabControl];
}

- (IBAction) handleSegmentedControlDidChange:(UISegmentedControl *)sender
{
    if ( sender == self.tabControl ) {
        
        id tabItem = nil;
        
        NSInteger selectedIndex = sender.selectedSegmentIndex;
        if ( selectedIndex >= 0 && selectedIndex < [self.tabItems count] ) {
            tabItem = [self.tabItems objectAtIndex:selectedIndex];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:FRiOSFeedbackTableViewTabPickerCellTabItemDidChangeNotification
                                                            object:tabItem];
        
    }
    
}

@end
