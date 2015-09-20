//
//  FRDocumentList.h
//  F53FeedbackKit
//
//  Created by Chad Sellers on 11/1/12.
//
//

#import <Cocoa/Cocoa.h>

@interface FRDocumentList : NSObject <NSTableViewDelegate, NSTableViewDataSource>

- (void)selectMostRecentDocument;
- (void)setupOtherButton:(NSButton *)otherButton;
- (NSDictionary *)documentsToUpload; // key = filename, value = NSString of base64 encoded file data

@property (strong, nonatomic) NSMutableArray *docs;
@property (strong, nonatomic) NSMutableDictionary *selectionState;
@property (strong, nonatomic) NSTableView *tableView;

@end
