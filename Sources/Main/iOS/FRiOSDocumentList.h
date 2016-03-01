//
//  FRiOSDocumentList.h
//  F53FeedbackKit
//
//  Created by Chad Sellers on 11/1/12.
//
//

@interface FRiOSDocumentList : NSObject <UITableViewDelegate, UITableViewDataSource>

- (void)selectMostRecentDocument;
//- (void)setupOtherButton:(UIButton *)otherButton;
- (NSDictionary *)documentsToUpload; // key = filename, value = NSString of base64 encoded file data

@property (strong, nonatomic) NSMutableArray *docs;
@property (strong, nonatomic) NSMutableDictionary *selectionState;
@property (strong, nonatomic) UITableView *tableView;

@end
