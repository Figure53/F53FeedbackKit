//
//  FRDocumentList.h
//  F53FeedbackKit
//
//  Created by Chad Sellers on 11/1/12.
//
//


NS_ASSUME_NONNULL_BEGIN

@interface FRDocumentList : NSObject <NSTableViewDelegate, NSTableViewDataSource>

- (void)selectMostRecentDocument;
- (void)setupOtherButton:(NSButton *)otherButton;
- (nullable NSDictionary<NSString *, NSString *> *)documentsToUpload; // key = filename, value = NSString of base64 encoded file data

@property (strong, nonatomic) NSMutableArray<NSURL *> *docs;
@property (strong, nonatomic) NSMutableDictionary<NSURL *, NSNumber *> *selectionState;
@property (strong, nonatomic) NSTableView *tableView;

@end

NS_ASSUME_NONNULL_END
