//
//  FRDocumentList.m
//  F53FeedbackKit
//
//  Created by Chad Sellers on 11/1/12.
//
//

#import "FRDocumentList.h"

@implementation FRDocumentList

@synthesize recentDocs = _recentDocs;

- (id)init
{
    self = [super init];
    if (self) {
        _recentDocs = nil;
        NSArray *docs = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
        if (docs)
            [self setRecentDocs:docs];
    }
    return self;
}

- (void)dealloc
{
    [_recentDocs release];
    [super dealloc];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[self recentDocs] count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (row < (NSInteger)[[self recentDocs] count]) {
        NSURL *url = [[self recentDocs] objectAtIndex:row];
        NSString *fname = [[url path] lastPathComponent];
        NSButton *checkbox = [[[NSButton alloc] init] autorelease];
        [checkbox setButtonType:NSSwitchButton];
        [checkbox setTitle:fname];
        if (row < 1)
            [checkbox setState:NSOnState];
        else
            [checkbox setState:NSOffState];
        return checkbox;
    }
    return nil;
}

@end
