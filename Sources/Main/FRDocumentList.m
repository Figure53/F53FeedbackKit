//
//  FRDocumentList.m
//  F53FeedbackKit
//
//  Created by Chad Sellers on 11/1/12.
//
//

#import "FRDocumentList.h"
#import "NSString+Base64.h"

@implementation FRDocumentList

@synthesize docs = _docs;
@synthesize selectionState = _selectionState;

- (id)init
{
    self = [super init];
    if (self) {
        _docs = nil;
        _selectionState = nil;
        NSArray *docs = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
        if (docs && [docs count] > 0) {
            [self setDocs:[NSMutableArray arrayWithArray:docs]];
            NSMutableDictionary *docDict = [NSMutableDictionary dictionaryWithCapacity:[docs count]];
            for (NSUInteger i = 0; i < [docs count]; i++) {
                if (i == 0)
                    [docDict setObject:[NSNumber numberWithBool:YES] forKey:[docs objectAtIndex:i]];
                else
                    [docDict setObject:[NSNumber numberWithBool:NO] forKey:[docs objectAtIndex:i]];
            }
            [self setSelectionState:docDict];
        }
    }
    return self;
}

- (void)dealloc
{
    [_docs release];
    [_selectionState release];
    [super dealloc];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[self docs] count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (row < (NSInteger)[[self docs] count]) {
        NSURL *url = [[self docs] objectAtIndex:row];
        NSString *fname = [[url path] lastPathComponent];
        NSButton *checkbox = [[[NSButton alloc] init] autorelease];
        [checkbox setButtonType:NSSwitchButton];
        [checkbox setTitle:fname];
        [checkbox setTag:row];
        if ([[[self selectionState] objectForKey:url] boolValue])
            [checkbox setState:NSOnState];
        else
            [checkbox setState:NSOffState];
        [checkbox setTarget:self];
        [checkbox setAction:@selector(checkboxChanged:)];
        return checkbox;
    }
    return nil;
}

- (IBAction)checkboxChanged:(id)sender
{
    if (!sender || ![sender isKindOfClass:[NSButton class]]) {
        NSLog(@"Error in document list, checkboxChanged: called from something that is not a checkbox: %@", sender);
        return;
    }
    NSButton *checkbox = (NSButton *)sender;
    BOOL newState = NO;
    if ([checkbox state] == NSOnState)
        newState = YES;
    NSInteger row = [checkbox tag];
    if (row < (NSInteger)[[self docs] count]) {
        NSURL *url = [[self docs] objectAtIndex:row];
        [[self selectionState] setObject:[NSNumber numberWithBool:newState] forKey:url];
    }
    else {
        NSLog(@"Error, checkbox pressed is beyond list of documents");
        return;
    }
}

- (NSDictionary *)documentsToUpload
{
    NSError *err;
    NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    for (NSURL *url in [self docs]) {
        if ([[[self selectionState] objectForKey:url] boolValue]) {
            NSString *path = [url path];
            
            // Create temporary folder
            NSString *tmpFolder = [NSString stringWithFormat:@"%@-%u", @"f53feedbackkit", arc4random() % 1000000];
            NSString *tmpPath = [[self cacheDir] stringByAppendingPathComponent:tmpFolder];
            if (![fm createDirectoryAtPath:tmpPath withIntermediateDirectories:YES attributes:nil error:&err]) {
                NSLog(@"Failed to create temporary directory at %@: %@", tmpPath, err);
                return nil;
            }
            
            // Zip up file
            NSString *zipName = [[[path lastPathComponent] stringByDeletingPathExtension] stringByAppendingPathExtension:@"zip"];
            NSString *zipPath = [tmpPath stringByAppendingPathComponent:zipName];
            NSTask *compressor = [[NSTask alloc] init];
            [compressor setLaunchPath:@"/usr/bin/zip"];
            [compressor setArguments:[NSArray arrayWithObjects:@"-r9", zipPath, [url path], nil]];
            [compressor setStandardError:[NSFileHandle fileHandleWithNullDevice]];
            [compressor setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
            [compressor setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
            [compressor setCurrentDirectoryPath:tmpPath];
            @try {
                [compressor launch];
            }
            @catch (NSException *e) {
                NSLog(@"Failed to zip document: %@", e);
                [compressor release];
                return nil;
            }
            [compressor waitUntilExit];
            int status = [compressor terminationStatus];
            if (status != 0) {
                NSLog(@"Failed to zip document with exit status: %d", status);
                [compressor release];
                return nil;
            }
            [compressor release];
            
            // Get file data
            NSData *fileData = [NSData dataWithContentsOfFile:zipPath options:0 error:&err];
            if (!fileData) {
                NSLog(@"Failed to get contents of document %@: %@", url, err);
                return nil;
            }
            NSString *encodedData = [fileData encodeBase64];
            NSLog(@"encodedData = %@", encodedData);
            
            NSString *rootfname = [[url path] lastPathComponent];
            NSString *fname = rootfname;
            unsigned int i = 1;
            while ([ret objectForKey:fname]) {
                fname = [rootfname stringByAppendingFormat:@"-%u", i];
                i++;
            }
            [ret setObject:encodedData forKey:fname];
            if (![fm removeItemAtPath:tmpPath error:&err])
                NSLog(@"Failed to remove temporary items, continuing anyway. Error: %@", err);
        }
    }
    return ret;
}

- (NSString *)cacheDir
{
    NSArray *domains = [NSArray arrayWithObjects:[NSNumber numberWithUnsignedInt:NSUserDomainMask], [NSNumber numberWithUnsignedInt:NSLocalDomainMask], [NSNumber numberWithUnsignedInt:NSNetworkDomainMask], nil];
    for (NSNumber *dom in domains) {
        NSArray *supDirs = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, [dom unsignedIntValue], YES);
        if ([supDirs count] > 0) {
            NSBundle *appBundle = [NSBundle mainBundle];
            if (!appBundle)
                return nil;
            NSString *name = [[appBundle infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
            return [[supDirs objectAtIndex:0] stringByAppendingPathComponent:name];
        }
    }
    return nil;
}

@end
