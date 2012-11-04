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
    NSArray         *_recentDocs;
}
@property(readwrite, copy, nonatomic) NSArray *recentDocs;
@end
