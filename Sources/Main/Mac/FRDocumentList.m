//
//  FRDocumentList.m
//  F53FeedbackKit
//
//  Created by Chad Sellers on 11/1/12.
//
//

#import "FRDocumentList.h"
#import "NSString+FRBase64.h"
#import "FRProgressWindow.h"
#import "FRConstants.h"


NS_ASSUME_NONNULL_BEGIN

@interface FRDocumentList ()

- (nullable NSString *)cacheDir;

@end


@implementation FRDocumentList

- (instancetype)init
{
    self = [super init];
    if (self) {
        _docs = [NSMutableArray array];
        _selectionState = [NSMutableDictionary dictionary];
        NSArray<NSURL *> *docs = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
        if (docs && [docs count] > 0) {
            [_docs addObjectsFromArray:docs];
            NSMutableDictionary<NSURL *, NSNumber *> *docDict = [NSMutableDictionary dictionaryWithCapacity:[docs count]];
            for ( NSURL *aDoc in docs ) {
                [docDict setObject:@NO forKey:aDoc];
            }
            [self.selectionState addEntriesFromDictionary:docDict];
        }
    }
    return self;
}


// Auto-select the most recent document. Was used whenever the report type was support, but then we changed our mind. Not used now.
- (void)selectMostRecentDocument
{
    if ([self docs] && [[self docs] count] > 0) {
        NSURL *firstDoc = [[self docs] objectAtIndex:0];
        [[self selectionState] setObject:[NSNumber numberWithBool:YES] forKey:firstDoc];
    }
}

- (void)setupOtherButton:(NSButton *)otherButton
{
    [otherButton setTarget:self];
    [otherButton setAction:@selector(otherButtonPressed:)];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[self docs] count];
}

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (row < (NSInteger)[[self docs] count]) {
        NSURL *url = [[self docs] objectAtIndex:row];
        NSString *fname = [[url path] lastPathComponent];
        NSButton *checkbox = [[NSButton alloc] init];
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

- (IBAction)otherButtonPressed:(id)sender
{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:YES];
    [oPanel setCanCreateDirectories:NO];
    [oPanel setCanChooseDirectories:YES];
    [oPanel setCanChooseFiles:YES];
    [oPanel setTitle:@"Add document to upload"];
    [oPanel setMessage:@"Select another document to send"];
    [oPanel setNameFieldLabel:@"Document:"];
    [oPanel setPrompt:@"Choose"];
    NSInteger result = [oPanel runModal];
    if (result == NSFileHandlingPanelOKButton) {
        NSArray *newDocs = [oPanel URLs];
        for (NSURL *newDoc in newDocs) {
            [self addDocumentToList:newDoc];
        }
    }
}

- (void)addDocumentToList:(NSURL *)newDoc
{
    if (![[self docs] containsObject:newDoc])
        [[self docs] addObject:newDoc];
    [[self selectionState] setObject:[NSNumber numberWithBool:YES] forKey:newDoc];
    [[self tableView] reloadData];
}

- (void)emptyFile:(NSString *)path
{
    NSError *err;
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSDictionary *attrs = [fm attributesOfItemAtPath:path error:&err];
    if (attrs) {
        long long fileSize = -1;
        NSNumber *sizeNum = [attrs objectForKey:NSFileSize];
        if (sizeNum)
            fileSize = [sizeNum longLongValue];
        NSString *contents = [NSString stringWithFormat:@"File emptied for submission. Original file was %lld bytes.\n", fileSize];
        if (![contents writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err])
            NSLog(@"Failed to empty file %@: %@", path, err);
    }
    else {
        NSLog(@"Failed to get file attributes for %@ while emptying: %@", path, err);
    }
}

- (NSString *)emptyDocument:(NSString *)documentPath tmpPath:(NSString *)tmpPath
{
    NSArray *emptyDocumentExpressions = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_EMPTYDOCUMENTFILES];
    if (emptyDocumentExpressions && [emptyDocumentExpressions count] > 0) {
        NSError *err;
        NSFileManager *fm = [[NSFileManager alloc] init];
        NSString *tmpDocPath = [tmpPath stringByAppendingPathComponent:[documentPath lastPathComponent]];
        if (![fm copyItemAtPath:documentPath toPath:tmpDocPath error:&err]) {
            NSLog(@"Failed to copy document %@ to %@ for emptying", documentPath, tmpDocPath);
            return documentPath;
        }
        NSArray *subPaths = [fm subpathsOfDirectoryAtPath:tmpDocPath error:&err];
        if (!subPaths) {
            NSLog(@"Failed to look inside document for emptying files: %@", err);
            return documentPath;
        }
        for (NSString *subPath in subPaths) {
            NSString *fullSubPath = [tmpDocPath stringByAppendingPathComponent:subPath];
            // Make sure this is a regular file
            NSDictionary *attrs = [fm attributesOfItemAtPath:fullSubPath error:&err];
            if (attrs) {
                NSString *fileType = [attrs objectForKey:NSFileType];
                if (!fileType || ![fileType isEqualToString:NSFileTypeRegular])
                    continue;
            }
            for (NSString *emptyRegEx in emptyDocumentExpressions) {
                if (emptyRegEx) {
                    NSRange rng = [subPath rangeOfString:emptyRegEx options:NSRegularExpressionSearch];
                    if (rng.location != NSNotFound) {
                        [self emptyFile:fullSubPath];
                        break;
                    }
                }
            }
        }
        return tmpDocPath;
    }
    return documentPath;
}

- (nullable NSDictionary<NSString *, NSString *> *)documentsToUpload
{
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    __block BOOL success = YES;
    __block BOOL done = NO;
    dispatch_queue_t aQ = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(aQ, ^{
        NSError *err;
        NSFileManager *fm = [[NSFileManager alloc] init];
        for (NSURL *url in [self docs]) {
            if ([[[self selectionState] objectForKey:url] boolValue]) {
                NSString *path = [url path];
                
                // Create temporary folder
                NSString *tmpFolder = [NSString stringWithFormat:@"%@-%u", @"f53feedbackkit", arc4random() % 1000000];
                NSString *tmpPath = [[self cacheDir] stringByAppendingPathComponent:tmpFolder];
                if (![fm createDirectoryAtPath:tmpPath withIntermediateDirectories:YES attributes:nil error:&err]) {
                    NSLog(@"Failed to create temporary directory at %@: %@", tmpPath, err);
                    success = NO;
                    break;
                }
                
                path = [self emptyDocument:path tmpPath:tmpPath];
                
                // Zip up file
                NSString *zipName = [[path lastPathComponent] stringByAppendingPathExtension:@"zip"];
                NSString *zipPath = [tmpPath stringByAppendingPathComponent:zipName];
                NSTask *compressor = [[NSTask alloc] init];
                [compressor setLaunchPath:@"/usr/bin/zip"];
                [compressor setArguments:[NSArray arrayWithObjects:@"-r9", zipPath, [path lastPathComponent], nil]];
                [compressor setStandardError:[NSFileHandle fileHandleWithNullDevice]];
                [compressor setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
                [compressor setStandardOutput:[NSFileHandle fileHandleWithNullDevice]];
                [compressor setCurrentDirectoryPath:[path stringByDeletingLastPathComponent]];
                @try {
                    [compressor launch];
                }
                @catch (NSException *e) {
                    NSLog(@"Failed to zip document: %@", e);
                    success = NO;
                    break;
                }
                [compressor waitUntilExit];
                int status = [compressor terminationStatus];
                if (status != 0) {
                    NSLog(@"Failed to zip document with exit status: %d", status);
                    success = NO;
                    break;
                }
                
                // Get file data
                NSData *fileData = [NSData dataWithContentsOfFile:zipPath options:0 error:&err];
                if (!fileData) {
                    NSLog(@"Failed to get contents of document %@: %@", url, err);
                    success = NO;
                    break;
                }
                NSString *encodedData = [fileData FR_encodeBase64];
                
                NSString *fname = zipName;
                unsigned int i = 1;
                while ([ret objectForKey:fname]) {
                    fname = [zipName stringByAppendingFormat:@"-%u", i];
                    i++;
                }
                [ret setObject:encodedData forKey:fname];
                if (![fm removeItemAtPath:tmpPath error:&err])
                    NSLog(@"Failed to remove temporary items, continuing anyway. Error: %@", err);
            }
        }
        done = YES;
    });
    FRProgressWindow *progWindow = [[FRProgressWindow alloc] initWithText:@"Preparing document files"];
    [progWindow show];
    while (!done) {
        [[NSApplication sharedApplication] runModalSession:[progWindow modalSession]];
        [NSThread sleepForTimeInterval:0.01];
    }
    [progWindow hide];
    if (!success)
        return nil;
    return ret;
}

- (nullable NSString *)cacheDir
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

NS_ASSUME_NONNULL_END
