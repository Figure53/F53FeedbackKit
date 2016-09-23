//
//  FRMacFeedbackWindowController.m
//  F53FeedbackKit
//
//  Created by Brent Lord on 9/20/15.
//  Copyright © 2015 Figure 53, LLC. All rights reserved.
//

#import "FRMacFeedbackWindowController.h"

#import "FRFeedbackController.h"

#import "FRCommand.h"
#import "FRCrashLogFinder.h"

#import <AddressBook/AddressBook.h>
#import <SystemConfiguration/SystemConfiguration.h>


@interface FRMacFeedbackWindowController ()

@property (nonatomic, strong)   NSString *preferences;

- (NSArray *) systemProfile;

- (void) populate;
- (void) loadConsole;
- (void) populateConsole;
- (void) stopSpinner;

- (NSString *) crashLog;
- (NSString *) scriptLog;

#pragma mark UI

- (void) showDetails:(BOOL)show animate:(BOOL)animate;

- (IBAction) showDetails:(id)sender;
- (IBAction) sendDetailsChecked:(id)sender;
- (IBAction) includeConsoleChecked:(id)sender;
- (IBAction) cancel:(id)sender;
- (IBAction) send:(id)sender;

@end


@implementation FRMacFeedbackWindowController

- (void) windowDidLoad
{
    [super windowDidLoad];
    
    self.detailsShown = YES;
    self.documentList = nil;
    
    [self.window setDelegate:self];
    
    [self.window setTitle:FRLocalizedString(@"Feedback", nil)];
    [self.emailLabel setStringValue:FRLocalizedString(@"Email address:", nil)];
    [self.detailsLabel setStringValue:FRLocalizedString(@"Details", nil)];
    [self.tabSystem setLabel:FRLocalizedString(@"System", nil)];
    [self.tabConsole setLabel:FRLocalizedString(@"Console", nil)];
    [self.tabCrash setLabel:FRLocalizedString(@"CrashLog", nil)];
    [self.tabScript setLabel:FRLocalizedString(@"Script", nil)];
    [self.tabPreferences setLabel:FRLocalizedString(@"Preferences", nil)];
    [self.tabException setLabel:FRLocalizedString(@"Exception", nil)];
    
    [self.sendButton setTitle:FRLocalizedString(@"Send", nil)];
    [self.cancelButton setTitle:FRLocalizedString(@"Cancel", nil)];
    
    [[self.consoleView textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
    [[self.consoleView textContainer] setWidthTracksTextView:NO];
    [self.consoleView setString:@""];
    [[self.crashesView textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
    [[self.crashesView textContainer] setWidthTracksTextView:NO];
    [self.crashesView setString:@""];
    [[self.scriptView textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
    [[self.scriptView textContainer] setWidthTracksTextView:NO];
    [self.scriptView setString:@""];
    [[self.preferencesView textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
    [[self.preferencesView textContainer] setWidthTracksTextView:NO];
    [self.preferencesView setString:@""];
    [[self.exceptionView textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
    [[self.exceptionView textContainer] setWidthTracksTextView:NO];
    [self.exceptionView setString:@""];
}

//- (void) dealloc
//{
//    NSLog( @"dealloc" );
//}


#pragma mark information gathering

- (NSArray *) systemProfile
{
    return [self.feedbackController systemProfile];
}

- (void) populate
{
    @autoreleasepool {
        
        if ([self.includeConsoleCheckbox state] == NSOnState)
            [self populateConsole];
        
        NSString *crashLog = self.crashesView.string;
        if ( !crashLog || [crashLog length] < 1 )
            crashLog = [self crashLog];
        if ([crashLog length] > 0) {
            [self performSelectorOnMainThread:@selector(addTabViewItem:) withObject:self.tabCrash waitUntilDone:YES];
            [self.crashesView performSelectorOnMainThread:@selector(setString:) withObject:crashLog waitUntilDone:YES];
        }
        
        NSString *scriptLog = [self scriptLog];
        if ([scriptLog length] > 0) {
            [self performSelectorOnMainThread:@selector(addTabViewItem:) withObject:self.tabScript waitUntilDone:YES];
            [self.scriptView performSelectorOnMainThread:@selector(setString:) withObject:scriptLog waitUntilDone:YES];
        }
        
        if ([self.preferences length] > 0) {
            [self performSelectorOnMainThread:@selector(addTabViewItem:) withObject:self.tabPreferences waitUntilDone:YES];
            [self.preferencesView performSelectorOnMainThread:@selector(setString:) withObject:self.preferences waitUntilDone:YES];
        }
        
        [self performSelectorOnMainThread:@selector(stopSpinner) withObject:nil waitUntilDone:YES];
        
    }
}

- (void) loadConsole
{
    @autoreleasepool {
        [self populateConsole];
        [self performSelectorOnMainThread:@selector(stopSpinner) withObject:nil waitUntilDone:YES];
    }
}

- (void) populateConsole
{
    NSString *consoleLog = [self.feedbackController consoleLog];
    if ([consoleLog length] > 0) {
        [self performSelectorOnMainThread:@selector(addTabViewItem:) withObject:self.tabConsole waitUntilDone:YES];
        [self.consoleView performSelectorOnMainThread:@selector(setString:) withObject:consoleLog waitUntilDone:YES];
    }
}

- (NSString *) crashLog
{
    NSDate *lastSubmissionDate = [[NSUserDefaults standardUserDefaults] valueForKey:DEFAULTS_KEY_LASTSUBMISSIONDATE];
    
    NSArray *crashFiles = [FRCrashLogFinder findCrashLogsSince:lastSubmissionDate];
    
    NSUInteger i = [crashFiles count];
    
    if (i == 1) {
        if (lastSubmissionDate == nil) {
            NSLog(@"Found a crash file");
        } else {
            NSLog(@"Found a crash file earlier than latest submission on %@", lastSubmissionDate);
        }
        NSError *error = nil;
        NSString *result = [NSString stringWithContentsOfFile:[crashFiles lastObject] encoding:NSUTF8StringEncoding error:&error];
        if (result == nil) {
            NSLog(@"Failed to read crash file: %@", error);
            return @"";
        }
        return result;
    }
    
    if (lastSubmissionDate == nil) {
        NSLog(@"Found %lu crash files", (unsigned long)i);
    } else {
        NSLog(@"Found %lu crash files earlier than latest submission on %@", (unsigned long)i, lastSubmissionDate);
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSDate *newest = nil;
    NSInteger newestIndex = -1;
    
    while(i--) {
        
        NSString *crashFile = [crashFiles objectAtIndex:i];
        NSError *error = nil;
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:crashFile error:&error];
        if (!fileAttributes) {
            NSLog(@"Error while fetching file attributes: %@", [error localizedDescription]);
        }
        NSDate *fileModDate = [fileAttributes objectForKey:NSFileModificationDate];
        
        NSLog(@"CrashLog: %@", crashFile);
        
        if ([fileModDate laterDate:newest] == fileModDate) {
            newest = fileModDate;
            newestIndex = i;
        }
        
    }
    
    if (newestIndex != -1) {
        NSString *newestCrashFile = [crashFiles objectAtIndex:newestIndex];
        
        NSLog(@"Picking CrashLog: %@", newestCrashFile);
        
        NSError *error = nil;
        NSString *result = [NSString stringWithContentsOfFile:newestCrashFile encoding:NSUTF8StringEncoding error:&error];
        if (result == nil) {
            NSLog(@"Failed to read crash file: %@", error);
            return @"";
        }
        return result;
    }
    
    return @"";
}

- (NSString *) scriptLog
{
    NSMutableString *scriptLog = [NSMutableString string];
    
    NSString *scriptPath = [[NSBundle mainBundle] pathForResource:FILE_SHELLSCRIPT ofType:@"sh"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:scriptPath]) {
        
        FRCommand *cmd = [[FRCommand alloc] initWithPath:scriptPath];
        [cmd setOutput:scriptLog];
        [cmd setError:scriptLog];
        int ret = [cmd execute];
        
        NSLog(@"Script exit code = %d", ret);
        
    } /* else {
       NSLog(@"No custom script to execute");
       }
       */
    
    return scriptLog;
}


#pragma mark custom setters/getters

- (void) setUploading:(BOOL)uploading
{
    if ( _uploading != uploading ) {
        
        _uploading = uploading;
        
        [self.indicator setHidden:!_uploading];
        if ( _uploading ) {
            [self.indicator startAnimation:self];
        }
        else {
            [self.indicator stopAnimation:self];
        }
        
        [self.messageView setEditable:!_uploading];
        [self.sendButton setEnabled:!_uploading];
        
    }
}


#pragma mark UI Actions

- (void) showDetails:(BOOL)show animate:(BOOL)animate
{
    if (self.detailsShown == show) {
        return;
    }
    
    NSSize fullSize = NSMakeSize(455, 302);
    
    NSRect windowFrame = [self.window frame];
    
    if (show) {
        
        windowFrame.origin.y -= fullSize.height;
        windowFrame.size.height += fullSize.height;
        [self.window setFrame:windowFrame
                      display:YES
                      animate:animate];
        
    } else {
        windowFrame.origin.y += fullSize.height;
        windowFrame.size.height -= fullSize.height;
        [self.window setFrame:windowFrame
                      display:YES
                      animate:animate];
        
    }
    
    self.detailsShown = show;
}

- (IBAction) showDetails:(id)sender
{
    BOOL show = [[sender objectValue] boolValue];
    [self showDetails:show animate:YES];
}

- (IBAction) sendDetailsChecked:(id)sender
{
    if ([self.sendDetailsCheckbox state] == NSOnState)
        [self.includeConsoleCheckbox setEnabled:YES];
    else
        [self.includeConsoleCheckbox setEnabled:NO];
}

- (IBAction) includeConsoleChecked:(id)sender
{
    if ([self.includeConsoleCheckbox state] == NSOnState) {
        [self.indicator setHidden:NO];
        [self.indicator startAnimation:self];
        [self.sendButton setEnabled:NO];
        [NSThread detachNewThreadSelector:@selector(loadConsole) toTarget:self withObject:nil];
    }
    else {
        [self.tabView removeTabViewItem:self.tabConsole];
    }
}

- (IBAction) cancel:(id)sender
{
    [self.feedbackController cancelUpload];
    [self.feedbackController close];
}

- (IBAction) send:(id)sender
{
    [self.feedbackController send:sender];
}

- (void) addTabViewItem:(NSTabViewItem *)tabViewItem
{
    [self.tabView insertTabViewItem:tabViewItem atIndex:1];
}

- (void) stopSpinner
{
    [self.indicator stopAnimation:self];
    [self.indicator setHidden:YES];
    [self.sendButton setEnabled:YES];
}

- (void) show
{
    self.documentList = [[FRDocumentList alloc] init];
    [self.documentList setupOtherButton:self.otherDocumentButton];
    [self.documentList setTableView:self.documentsView];
    [self.documentsView setDelegate:self.documentList];
    [self.documentsView setDataSource:self.documentList];
    [self.documentsView reloadData];
    
    if ([self.type isEqualToString:FR_FEEDBACK]) {
        [self.messageLabel setStringValue:FRLocalizedString(@"Feedback comment label", nil)];
    } else if ([self.type isEqualToString:FR_SUPPORT]) {
        [self.messageLabel setStringValue:FRLocalizedString(@"Describe the problem:", nil)];
    } else {
        [self.messageLabel setStringValue:FRLocalizedString(@"Comments:", nil)];
    }
    
    if ([[self.exceptionView string] length] != 0) {
        [self.tabView insertTabViewItem:self.tabException atIndex:1];
        [self.tabView selectTabViewItemWithIdentifier:@"Exception"];
    } else {
        [self.tabView selectTabViewItemWithIdentifier:@"System"];
    }
    
    if ([self.type isEqual:FR_SUPPORT]) {
        [self showDetails:YES animate:NO];
        [self.detailsButton setState:NSOnState];
        if ([[self.documentList docs] count] > 0)
            [self.tabView selectTabViewItemWithIdentifier:@"Documents"];
    }
    
    self.preferences = [self.feedbackController preferences];
    [NSThread detachNewThreadSelector:@selector(populate) toTarget:self withObject:nil];
    
    [self showWindow:self];
    [[self window] center];
}

- (void) resetWithEmailRequired:(BOOL)emailRequired
{
    [self.tabView removeTabViewItem:self.tabConsole];
    [self.tabView removeTabViewItem:self.tabCrash];
    [self.tabView removeTabViewItem:self.tabScript];
    [self.tabView removeTabViewItem:self.tabPreferences];
    [self.tabView removeTabViewItem:self.tabException];
    
    ABPerson *me = [[ABAddressBook sharedAddressBook] me];
    ABMutableMultiValue *emailAddresses = [me valueForProperty:kABEmailProperty];
    
    NSUInteger count = [emailAddresses count];
    [self.emailBox removeAllItems];
    
    [self.emailBox addItemWithObjectValue:FRLocalizedString(@"anonymous", nil)];
    
    for(NSUInteger i=0; i<count; i++) {
        NSString *emailAddress = [emailAddresses valueAtIndex:i];
        [self.emailBox addItemWithObjectValue:emailAddress];
    }
    
    NSString *email = [[NSUserDefaults standardUserDefaults] stringForKey:DEFAULTS_KEY_SENDEREMAIL];
    
    NSInteger found = [self.emailBox indexOfItemWithObjectValue:email];
    if (found != NSNotFound) {
        [self.emailBox selectItemAtIndex:found];
    } else if ([self.emailBox numberOfItems] >= 2) {
        NSString *defaultSender = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_DEFAULTSENDER];
        NSUInteger idx = (defaultSender && [defaultSender isEqualToString:@"firstEmail"]) ? 1 : 0;
        [self.emailBox selectItemAtIndex:idx];
    }
    
    if (emailRequired &&
        ([self.emailBox stringValue] == nil || [[self.emailBox stringValue] isEqualToString:@""] || [[self.emailBox stringValue] isEqualToString:FRLocalizedString(@"anonymous", nil)])) {
        [self.emailLabel setTextColor:[NSColor redColor]];
    }
    else {
        [self.emailLabel setTextColor:[NSColor blackColor]];
    }
    
    
    [self.headingField setStringValue:@""];
    [self.messageView setString:@""];
    [self.exceptionView setString:@""];
    
    [self showDetails:NO animate:NO];
    [self.detailsButton setIntValue:NO];
    
    [self.indicator setHidden:NO];
    [self.indicator startAnimation:self];
    [self.sendButton setEnabled:NO];
    
    //  setup 'send details' checkbox...
    [self.sendDetailsCheckbox setTitle:FRLocalizedString(@"Send details", nil)];
    [self.sendDetailsCheckbox setState:NSOnState];
    id sendDetailsIsOptionalValue = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_SENDDETAILSISOPTIONAL];
    if ([sendDetailsIsOptionalValue respondsToSelector:@selector( boolValue )] && [sendDetailsIsOptionalValue boolValue]) {
        [self.detailsLabel setHidden:YES];
        [self.sendDetailsCheckbox setHidden:NO];
        
        [self.sendDetailsCheckbox sizeToFit];
        [self.includeConsoleCheckbox sizeToFit];
        NSRect sendFrame = [self.sendDetailsCheckbox frame];
        NSRect consoleFrame = [self.includeConsoleCheckbox frame];
        CGFloat buffer = 20.0;
        consoleFrame.origin.x = sendFrame.origin.x + sendFrame.size.width + buffer;
        [self.includeConsoleCheckbox setFrame:consoleFrame];
        
        id defaultIncludeConsoleValue = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_DEFAULTINCLUDECONSOLE];
        NSCellStateValue includeConsoleState = NSOffState;
        if ([defaultIncludeConsoleValue respondsToSelector:@selector( boolValue )] && [defaultIncludeConsoleValue boolValue]) {
            includeConsoleState = NSOnState;
        }
        [self.includeConsoleCheckbox setState:includeConsoleState];
    } else {
        [self.detailsLabel setHidden:NO];
        [self.sendDetailsCheckbox setHidden:YES];
        [self.includeConsoleCheckbox setHidden:YES];
    }
}


#pragma mark NSWindowDelegate

- (void) windowWillClose:(NSNotification *)notification
{
    [self.feedbackController cancelUpload];
    
    if ([self.type isEqualToString:FR_EXCEPTION]) {
        NSString *exitAfterExceptionValue = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_EXITAFTEREXCEPTION];
        if ([exitAfterExceptionValue respondsToSelector:@selector( boolValue )] && [exitAfterExceptionValue boolValue]) {
            // We want a pure exit() here I think.
            // As an exception has already been raised there is no
            // guarantee that the code path to [NSAapp terminate] is functional.
            // Calling abort() will crash the app here but is that more desirable?
            exit(EXIT_FAILURE);
        }
    }
}

@end
