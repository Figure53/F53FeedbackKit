//
//  FRDocumentList.h
//  F53FeedbackKit
//
//  Created by Chad Sellers on 11/1/12.
//
//

#import <Cocoa/Cocoa.h>

@interface FRDocumentList : NSObject <NSTableViewDelegate, NSTableViewDataSource>
{
    NSMutableArray          *_docs;
    NSMutableDictionary     *_selectionState;
    NSTableView             *_tableView;
}
- (void)selectMostRecentDocument;
- (void)setupOtherButton:(NSButton *)otherButton;
- (NSDictionary *)documentsToUpload; // key = filename, value = NSString of base64 encoded file data
@property(readwrite, retain, nonatomic) NSMutableArray *docs;
@property(readwrite, retain, nonatomic) NSMutableDictionary *selectionState;
@property(readwrite, assign, nonatomic) NSTableView *tableView;
@end
