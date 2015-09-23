//
//  FRiOSFeedbackTableViewController.m
//  F53FeedbackKit
//
//  Created by Brent Lord on 9/22/15.
//  Copyright © 2015 Figure 53, LLC. All rights reserved.
//

#import "FRiOSFeedbackTableViewController.h"

#import "FRFeedbackController.h"

#import "FRCrashLogFinder.h"

#import "FRiOSFeedbackTableViewCheckmarkCell.h"
#import "FRiOSFeedbackTableViewEmailCell.h"
#import "FRiOSFeedbackTableViewTabPickerCell.h"
#import "FRiOSFeedbackTableViewTextViewCell.h"

@interface FRiOSFeedbackTableViewController ()

@property (nonatomic, strong)   UIColor *delegateTintColor;
@property (nonatomic, strong)   UIColor *emailBoxTextColor;
@property (nonatomic, strong)   NSString *detailsLabelText;
@property (nonatomic, strong)   NSArray *systemProfile;

@property (nonatomic)           BOOL sendDetailsIsOptional;
@property (nonatomic)           BOOL includeConsoleSpinnerOn;

@property (nonatomic, strong)   NSMutableArray *detailsTabItems;
@property (nonatomic, strong)   NSMutableDictionary *selectedDetailTabItem;
@property (nonatomic, strong)   NSMutableDictionary *detailTabSystem;
@property (nonatomic, strong)   NSMutableDictionary *detailTabConsole;
@property (nonatomic, strong)   NSMutableDictionary *detailTabCrash;
@property (nonatomic, strong)   NSMutableDictionary *detailTabScript;
@property (nonatomic, strong)   NSMutableDictionary *detailTabPreferences;
@property (nonatomic, strong)   NSMutableDictionary *detailTabException;
@property (nonatomic, strong)   NSMutableDictionary *detailTabDocuments;

//@property (nonatomic, strong)   IBOutlet NSButton *otherDocumentButton;

@property (nonatomic, strong)   UIBarButtonItem *cancelButton;
@property (nonatomic, strong)   UIBarButtonItem *sendButton;

@property (nonatomic, strong)   NSString *preferences;

- (NSArray *) systemProfile;

- (void) populate;
- (void) loadConsole;
- (void) populateConsole;
- (void) stopSpinner;

- (NSString *) crashLog;
//- (NSString *) scriptLog;

#pragma mark UI

- (void) showDetails:(BOOL)show animate:(BOOL)animate;
- (void) includeConsoleChecked:(BOOL)checked;
- (void) cancel:(id)sender;
- (void) send:(id)sender;

@end

@implementation FRiOSFeedbackTableViewController

#define NUM_SECTIONS                        2

#define SECTION_MESSAGE                     0
#define SECTION_DETAILS                     1

#define SECTION_MESSAGE_NUM_ROWS            2
#define SECTION_DETAILS_NUM_ROWS            4

#define SECTION_MESSAGE_ROW_MESSAGE         0
#define SECTION_MESSAGE_ROW_EMAIL           1
#define SECTION_DETAILS_ROW_SEND_DETAILS    0
#define SECTION_DETAILS_ROW_INCL_CONSOLE    1
#define SECTION_DETAILS_ROW_TABS            2
#define SECTION_DETAILS_ROW_TAB_TEXT        3

#define TEXTVIEW_MESSAGE_TAG    (SECTION_MESSAGE * 10000) + (SECTION_MESSAGE_ROW_MESSAGE * 100)
#define TEXTVIEW_DETAILS_TAG    (SECTION_DETAILS * 10000) + (SECTION_DETAILS_ROW_TAB_TEXT * 100)


- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if ( self ) {
        
        self.detailTabSystem        = [@{ @"label" : FRLocalizedString(@"System", nil) } mutableCopy];
        self.detailTabConsole       = [@{ @"label" : FRLocalizedString(@"Console", nil) } mutableCopy];
        self.detailTabCrash         = [@{ @"label" : FRLocalizedString(@"CrashLog", nil) } mutableCopy];
        self.detailTabScript        = [@{ @"label" : FRLocalizedString(@"Script", nil) } mutableCopy];
        self.detailTabPreferences   = [@{ @"label" : FRLocalizedString(@"Preferences", nil) } mutableCopy];
        self.detailTabException     = [@{ @"label" : FRLocalizedString(@"Exception", nil) } mutableCopy];
//        self.detailTabDocuments     = [@{ @"label" : FRLocalizedString(@"Documents", nil) } mutableCopy];
        
        self.detailsTabItems = [NSMutableArray arrayWithObjects:self.detailTabSystem, self.detailTabConsole, self.detailTabCrash, self.detailTabScript, self.detailTabPreferences, self.detailTabException, self.detailTabDocuments, nil];
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeRight;
    
    self.sendDetails = YES;
//    self.documentList = nil;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"reuseIdentifier"];
    [self.tableView registerNib:[UINib nibWithNibName:@"FRiOSFeedbackTableViewCheckmarkCell" bundle:[NSBundle bundleForClass:[self class]]] forCellReuseIdentifier:FRiOSFeedbackTableViewCheckmarkCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"FRiOSFeedbackTableViewEmailCell" bundle:[NSBundle bundleForClass:[self class]]] forCellReuseIdentifier:FRiOSFeedbackTableViewEmailCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"FRiOSFeedbackTableViewTabPickerCell" bundle:[NSBundle bundleForClass:[self class]]] forCellReuseIdentifier:FRiOSFeedbackTableViewTabPickerCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"FRiOSFeedbackTableViewTextViewCell" bundle:[NSBundle bundleForClass:[self class]]] forCellReuseIdentifier:FRiOSFeedbackTableViewTextViewCellIdentifier];
    
    self.title = FRLocalizedString(@"Feedback", nil);
    self.detailsLabelText = FRLocalizedString(@"Details", nil);
    
    self.sendButton = [[UIBarButtonItem alloc] initWithTitle:FRLocalizedString(@"Send", nil) style:UIBarButtonItemStyleDone target:self action:@selector( send: )];
    self.navigationItem.rightBarButtonItem = self.sendButton;
    
    self.cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector( cancel: )];
    self.navigationItem.leftBarButtonItem = self.cancelButton;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ( [self.feedbackController.delegate respondsToSelector:@selector( feedbackControllerTintColor )] ) {
        self.delegateTintColor = [self.feedbackController.delegate feedbackControllerTintColor];
        self.navigationController.navigationBar.tintColor = self.delegateTintColor;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( handleTextViewDidEndEditing: ) name:FRiOSFeedbackTableViewTextViewCellDidEndEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( handleEmailTextDidEndEditing: ) name:FRiOSFeedbackTableViewEmailCellDidEndEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( handleSelectedDetailTabItemDidChange: ) name:FRiOSFeedbackTableViewTabPickerCellTabItemDidChangeNotification object:nil];
    
    if ( self.titleText )
        self.title = self.titleText;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:SECTION_MESSAGE_ROW_MESSAGE inSection:SECTION_MESSAGE];
    FRiOSFeedbackTableViewTextViewCell *messageViewCell = (FRiOSFeedbackTableViewTextViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [messageViewCell.textView becomeFirstResponder];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.feedbackController cancelUpload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FRiOSFeedbackTableViewTextViewCellDidEndEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FRiOSFeedbackTableViewEmailCellDidEndEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FRiOSFeedbackTableViewTabPickerCellTabItemDidChangeNotification object:nil];
    
    if ([self.type isEqualToString:FR_EXCEPTION]) {
        NSString *exitAfterException = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_EXITAFTEREXCEPTION];
        if (exitAfterException && [exitAfterException isEqualToString:@"YES"]) {
            // We want a pure exit() here I think.
            // As an exception has already been raised there is no
            // guarantee that the code path to [NSAapp terminate] is functional.
            // Calling abort() will crash the app here but is that more desirable?
            exit(EXIT_FAILURE);
        }
    }
    
}

//- (void) dealloc
//{
//    NSLog( @"dealloc" );
//}


#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUM_SECTIONS;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch ( section ) {
        case SECTION_MESSAGE:
            return SECTION_MESSAGE_NUM_ROWS;
            break;
            
        case SECTION_DETAILS:
            
            if ( self.sendDetails )
                return SECTION_DETAILS_NUM_ROWS;
            else
                return 1;
            
        default:
            break;
    }
    
    return 0;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = nil;
    
    switch ( section ) {
        case SECTION_MESSAGE:
            title = self.headingText;
            break;
            
        case SECTION_DETAILS:
            title = self.detailsLabelText;
            
        default:
            break;
    }
    
    return title;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *title = nil;
    
    switch ( section ) {
        case SECTION_MESSAGE:
            title = [self.subheadingText stringByAppendingString:@"\n"];
            break;
            
        default:
            break;
    }
    
    return title;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch ( indexPath.section ) {
        case SECTION_MESSAGE: {
            
            switch ( indexPath.row ) {
                case SECTION_MESSAGE_ROW_MESSAGE: {
                    
                    FRiOSFeedbackTableViewTextViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FRiOSFeedbackTableViewTextViewCellIdentifier forIndexPath:indexPath];
                    cell.tintColor = self.delegateTintColor;
                    
                    cell.textView.text = self.messageViewText;
                    cell.textView.tag = [self getTagFromIndexPath:indexPath];
                    cell.textViewPlaceholder.text = self.messageLabelText;
                    
                    return cell;
                    
                } break;
                    
                case SECTION_MESSAGE_ROW_EMAIL: {
                    
                    FRiOSFeedbackTableViewEmailCell *cell = [tableView dequeueReusableCellWithIdentifier:FRiOSFeedbackTableViewEmailCellIdentifier forIndexPath:indexPath];
                    cell.tintColor = self.delegateTintColor;
                    
                    cell.emailBox.text = self.emailBoxText;
                    cell.emailBox.textColor = self.emailBoxTextColor;
                    cell.emailBox.placeholder = FRLocalizedString(@"Email address:", nil);
                    
                    return cell;
                    
                }
                    
                default:
                    break;
            }
            
        } break;
            
        case SECTION_DETAILS: {

            switch ( indexPath.row ) {
                case SECTION_DETAILS_ROW_SEND_DETAILS: {
                    
                    FRiOSFeedbackTableViewCheckmarkCell *cell = [tableView dequeueReusableCellWithIdentifier:FRiOSFeedbackTableViewCheckmarkCellIdentifier forIndexPath:indexPath];
                    cell.hidden = !self.sendDetailsIsOptional;
                    cell.tintColor = self.delegateTintColor;
                    
                    cell.textLabel.text = FRLocalizedString(@"Send details", nil);
                    cell.checkmarkOn = self.sendDetails;
                    
                    return cell;
                    
                } break;
                    
                case SECTION_DETAILS_ROW_INCL_CONSOLE: {
                    
                    FRiOSFeedbackTableViewCheckmarkCell *cell = [tableView dequeueReusableCellWithIdentifier:FRiOSFeedbackTableViewCheckmarkCellIdentifier forIndexPath:indexPath];
                    cell.hidden = !self.sendDetailsIsOptional;
                    cell.tintColor = self.delegateTintColor;
                    //cell.indentationLevel = 2;
                    
                    cell.textLabel.text = FRLocalizedString(@"Include console logs", nil);
                    cell.checkmarkOn = self.includeConsole;
                    if ( self.includeConsoleSpinnerOn ) {
                        [cell startSpinner];
                    }
                    else {
                        [cell stopSpinner];
                    }
                    
                    return cell;
                    
                } break;
                    
                case SECTION_DETAILS_ROW_TABS: {
                    
                    FRiOSFeedbackTableViewTabPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:FRiOSFeedbackTableViewTabPickerCellIdentifier forIndexPath:indexPath];
                    cell.tintColor = self.delegateTintColor;
                    cell.tabControl.tintColor = self.delegateTintColor;
                    
                    [cell configureControlWithItems:self.detailsTabItems selectedItem:self.selectedDetailTabItem];
                    
                    return cell;
                    
                }
                    
                case SECTION_DETAILS_ROW_TAB_TEXT: {
                    
                    FRiOSFeedbackTableViewTextViewCell *cell = [tableView dequeueReusableCellWithIdentifier:FRiOSFeedbackTableViewTextViewCellIdentifier forIndexPath:indexPath];
                    cell.tintColor = self.delegateTintColor;
                    
                    cell.textView.text = [self.selectedDetailTabItem objectForKey:@"text"];
                    cell.textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
                    cell.textView.tag = [self getTagFromIndexPath:indexPath];
                    
                    return cell;
                    
                }
                    
                default:
                    break;
            }
            
        } break;
            
        default:
            break;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
    return cell;
}


#pragma mark - Table view delegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return UITableViewAutomaticDimension;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return UITableViewAutomaticDimension;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 44.0f;
    
    switch ( indexPath.section ) {
        case SECTION_MESSAGE: {
            
            switch ( indexPath.row ) {
                case SECTION_MESSAGE_ROW_MESSAGE:
                    height = 150.0f;
                    break;
                    
                case SECTION_MESSAGE_ROW_EMAIL:
                    height = 40.0f;
                    break;
                    
                default:
                    break;
            }
            
        } break;
            
        case SECTION_DETAILS: {
            
            switch ( indexPath.row ) {
                case SECTION_DETAILS_ROW_SEND_DETAILS:
                case SECTION_DETAILS_ROW_INCL_CONSOLE: {
                    
                    // collapse checkmark cells to hide them if sending details is required
                    if ( !self.sendDetailsIsOptional )
                        height = 0.0f;
                    
                } break;
                    
                case SECTION_DETAILS_ROW_TAB_TEXT:
                    height = 300.0f;
                    break;
                    
                default:
                    break;
            }
            
        } break;
            
        default:
            break;
    }
    
    return height;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch ( indexPath.section ) {
        case SECTION_DETAILS:
            
            switch ( indexPath.row ) {
                case SECTION_DETAILS_ROW_SEND_DETAILS: {
                    
                    FRiOSFeedbackTableViewCheckmarkCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    
                    BOOL wasChecked = cell.checkmarkOn;
                    [self showDetails:!wasChecked animate:YES];
                    
                } break;
                    
                case SECTION_DETAILS_ROW_INCL_CONSOLE: {
                    
                    FRiOSFeedbackTableViewCheckmarkCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    
                    BOOL wasChecked = cell.checkmarkOn;
                    [self includeConsoleChecked:!wasChecked];
                    
                } break;
                    
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
}

- (NSInteger) getTagFromIndexPath:(NSIndexPath *)indexPath
{
    NSInteger thisTag = 0;
    
    if ( indexPath ) {
        thisTag += indexPath.section * 10000;
        thisTag += indexPath.row * 100;
    }
    
    return thisTag;
}


#pragma mark information gathering

- (NSArray *) systemProfile
{
    return [self.feedbackController systemProfile];
}

- (void) populate
{
    @autoreleasepool {

        if ( self.includeConsole )
            [self populateConsole];
        
        NSString *crashLog = self.crashesViewText;
        if ( !crashLog )
            crashLog = [self crashLog];
        if ([crashLog length] > 0) {
            dispatch_sync( dispatch_get_main_queue(), ^{
                [self addDetailsTabItem:self.detailTabCrash];
                [self.detailTabCrash setObject:crashLog forKey:@"text"];
            });
        }
        
//        NSString *scriptLog = [self scriptLog];
//        if ([scriptLog length] > 0) {
//            dispatch_sync( dispatch_get_main_queue(), ^{
//                [self addDetailsTabItem:self.detailTabScript];
//                [self.detailTabScript setObject:scriptLog forKey:@"text"];
//            });
//        }
        
        if ([self.preferences length] > 0) {
            dispatch_sync( dispatch_get_main_queue(), ^{
                [self addDetailsTabItem:self.detailTabPreferences];
                [self.detailTabPreferences setObject:self.preferences forKey:@"text"];
            });
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
        dispatch_sync( dispatch_get_main_queue(), ^{
            [self addDetailsTabItem:self.detailTabConsole];
            [self.detailTabConsole setObject:consoleLog forKey:@"text"];
        });
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

//- (NSString *) scriptLog
//{
//    NSMutableString *scriptLog = [NSMutableString string];
//
//    NSString *scriptPath = [[NSBundle mainBundle] pathForResource:FILE_SHELLSCRIPT ofType:@"sh"];
//
//    if ([[NSFileManager defaultManager] fileExistsAtPath:scriptPath]) {
//
//        FRCommand *cmd = [[FRCommand alloc] initWithPath:scriptPath];
//        [cmd setOutput:scriptLog];
//        [cmd setError:scriptLog];
//        int ret = [cmd execute];
//
//        NSLog(@"Script exit code = %d", ret);
//
//    } /* else {
//       NSLog(@"No custom script to execute");
//       }
//       */
//
//    return scriptLog;
//}

#pragma mark custom setters/getters

- (void) setFeedbackController:(FRFeedbackController *)feedbackController
{
    if ( _feedbackController != feedbackController ) {
        
        _feedbackController = feedbackController;
        
        [self.detailTabSystem setValue:[_feedbackController systemProfileAsString] forKey:@"text"];
    }
}

- (void) setUploading:(BOOL)uploading
{
    if ( _uploading != uploading ) {
        
        _uploading = uploading;
        
//        [self.indicator setHidden:NO];
//        [self.indicator startAnimation:self];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:SECTION_MESSAGE_ROW_MESSAGE inSection:SECTION_MESSAGE];
        FRiOSFeedbackTableViewTextViewCell *cell = (FRiOSFeedbackTableViewTextViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        cell.textView.editable = !_uploading;
        
        [self.sendButton setEnabled:!_uploading];

    }
}

- (NSString *) consoleViewText
{
    NSString *text = [self.detailTabConsole objectForKey:@"text"];
    if ( !text ) {
        text = @"";
    }
    return text;
}

- (NSString *) crashesViewText;
{
    NSString *text = [self.detailTabCrash objectForKey:@"text"];
    if ( !text ) {
        text = @"";
    }
    return text;
}

- (void) setCrashesViewText:(NSString *)crashesViewText
{
    if ( crashesViewText )
        [self.detailTabCrash setObject:crashesViewText forKey:@"text"];
    else
        [self.detailTabCrash removeObjectForKey:@"text"];
}

- (NSString *) scriptViewText;
{
    NSString *text = [self.detailTabScript objectForKey:@"text"];
    if ( !text ) {
        text = @"";
    }
    return text;
}

- (NSString *) preferencesViewText;
{
    NSString *text = [self.detailTabPreferences objectForKey:@"text"];
    if ( !text ) {
        text = @"";
    }
    return text;
}

- (NSString *) exceptionViewText;
{
    NSString *text = [self.detailTabException objectForKey:@"text"];
    if ( !text ) {
        text = @"";
    }
    return text;
}

- (void) setExceptionViewText:(NSString *)exceptionViewText
{
    if ( exceptionViewText )
        [self.detailTabException setObject:exceptionViewText forKey:@"text"];
    else
        [self.detailTabException removeObjectForKey:@"text"];
}

- (NSString *) documentsViewText;
{
    NSString *text = [self.detailTabDocuments objectForKey:@"text"];
    if ( !text ) {
        text = @"";
    }
    return text;
}


#pragma mark UI Actions

- (void) showDetails:(BOOL)show animate:(BOOL)animate
{
    if (self.sendDetails == show) {
        return;
    }
    
    self.sendDetails = show;
    
    UITableViewRowAnimation animation = ( animate ? UITableViewRowAnimationAutomatic : UITableViewRowAnimationNone );
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_DETAILS] withRowAnimation:animation];
}

- (void) includeConsoleChecked:(BOOL)checked
{
    self.includeConsole = checked;
    
    if ( self.includeConsole ) {
        [self startSpinner];
        [self.sendButton setEnabled:NO];
        [NSThread detachNewThreadSelector:@selector(loadConsole) toTarget:self withObject:nil];
    }
    else {
        [self.detailsTabItems removeObject:self.detailTabConsole];
        
        NSIndexPath *includeConsoleIndexPath = [NSIndexPath indexPathForRow:SECTION_DETAILS_ROW_INCL_CONSOLE inSection:SECTION_DETAILS];
        FRiOSFeedbackTableViewCheckmarkCell *cell = (FRiOSFeedbackTableViewCheckmarkCell *)[self.tableView cellForRowAtIndexPath:includeConsoleIndexPath];
        cell.checkmarkOn = NO;
        
        [self updateDetailsTabItems];
    }
}

- (void) cancel:(id)sender
{
    [self.feedbackController cancelUpload];
    [self.feedbackController close];
}

- (void) send:(id)sender
{
    [self.tableView endEditing:YES];
    [self.feedbackController send:sender];
}

- (void) addDetailsTabItem:(id)viewItem
{
    [self.detailsTabItems insertObject:viewItem atIndex:1];
    [self updateDetailsTabItems];
}

- (void) updateDetailsTabItems
{
    NSIndexPath *detailsIndexPath = [NSIndexPath indexPathForRow:SECTION_DETAILS_ROW_TABS inSection:SECTION_DETAILS];
    FRiOSFeedbackTableViewTabPickerCell *cell = (FRiOSFeedbackTableViewTabPickerCell *)[self.tableView cellForRowAtIndexPath:detailsIndexPath];
    [cell configureControlWithItems:self.detailsTabItems selectedItem:self.selectedDetailTabItem];
}

- (void) updateDetailsTextView
{
    NSIndexPath *detailsIndexPath = [NSIndexPath indexPathForRow:SECTION_DETAILS_ROW_TAB_TEXT inSection:SECTION_DETAILS];
    FRiOSFeedbackTableViewTextViewCell *cell = (FRiOSFeedbackTableViewTextViewCell *)[self.tableView cellForRowAtIndexPath:detailsIndexPath];
    cell.textView.text = [self.selectedDetailTabItem objectForKey:@"text"];
}

- (void) startSpinner
{
    if ( self.includeConsoleSpinnerOn )
        return;
    
    self.includeConsoleSpinnerOn = YES;
    
    NSIndexPath *includeConsoleIndexPath = [NSIndexPath indexPathForRow:SECTION_DETAILS_ROW_INCL_CONSOLE inSection:SECTION_DETAILS];
    FRiOSFeedbackTableViewCheckmarkCell *cell = (FRiOSFeedbackTableViewCheckmarkCell *)[self.tableView cellForRowAtIndexPath:includeConsoleIndexPath];
    [cell startSpinner];
}

- (void) stopSpinner
{
    if ( !self.includeConsoleSpinnerOn )
        return;
    
    self.includeConsoleSpinnerOn = NO;
    
    NSIndexPath *includeConsoleIndexPath = [NSIndexPath indexPathForRow:SECTION_DETAILS_ROW_INCL_CONSOLE inSection:SECTION_DETAILS];
    FRiOSFeedbackTableViewCheckmarkCell *cell = (FRiOSFeedbackTableViewCheckmarkCell *)[self.tableView cellForRowAtIndexPath:includeConsoleIndexPath];
    [cell stopSpinner];
    
    if ( [self.tableView.indexPathsForVisibleRows containsObject:includeConsoleIndexPath] ) {
        [self.tableView reloadRowsAtIndexPaths:@[includeConsoleIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    
    [self.sendButton setEnabled:YES];
}

- (void) show
{
//    self.documentList = [[FRDocumentList alloc] init];
//    [self.documentList setupOtherButton:self.otherDocumentButton];
//    [self.documentList setTableView:self.documentsView];
//    [self.documentsView setDelegate:self.documentList];
//    [self.documentsView setDataSource:self.documentList];
//    [self.documentsView reloadData];
    
    if ([self.type isEqualToString:FR_FEEDBACK]) {
        self.messageLabelText = FRLocalizedString(@"Feedback comment label", nil);
    } else if ([self.type isEqualToString:FR_SUPPORT]) {
        self.messageLabelText = FRLocalizedString(@"Describe the problem:", nil);
    } else {
        self.messageLabelText = FRLocalizedString(@"Comments:", nil);
    }
    
    if ([self.exceptionViewText length] != 0) {
        [self addDetailsTabItem:self.detailTabException];
        self.selectedDetailTabItem = self.detailTabException;
    } else {
        self.selectedDetailTabItem = self.detailTabSystem;
    }
    
    if ([self.type isEqual:FR_SUPPORT]) {
        [self showDetails:YES animate:NO];
//        if ([[self.documentList docs] count] > 0)
//            self.selectedDetailTabItem = self.detailTabDocuments;
    }
    
    self.preferences = [self.feedbackController preferences];
    [NSThread detachNewThreadSelector:@selector(populate) toTarget:self withObject:nil];
    
    UIViewController *presentingController = nil;
    if ( [self.feedbackController.delegate isKindOfClass:[UIViewController class]] )
        presentingController = (UIViewController *)self.feedbackController.delegate;
    else
        presentingController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    if ( !presentingController )
        return;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self];
    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [presentingController presentViewController:navController animated:YES completion:nil];
}

- (void) resetWithEmailRequired:(BOOL)emailRequired
{
    [self.detailsTabItems removeObject:self.detailTabConsole];
    [self.detailsTabItems removeObject:self.detailTabCrash];
    [self.detailsTabItems removeObject:self.detailTabScript];
    [self.detailsTabItems removeObject:self.detailTabPreferences];
    [self.detailsTabItems removeObject:self.detailTabException];
    
//    ABPerson *me = [[ABAddressBook sharedAddressBook] me];
//    ABMutableMultiValue *emailAddresses = [me valueForProperty:kABEmailProperty];
//
//    [self.emailBox removeAllItems];
//
//    [self.emailBox addItemWithObjectValue:FRLocalizedString(@"anonymous", nil)];
//
//    for ( NSString *emailAddress in emailAddresses ) {
//        [self.emailBox addItemWithObjectValue:emailAddress];
//    }
    
    NSString *email = [[NSUserDefaults standardUserDefaults] stringForKey:DEFAULTS_KEY_SENDEREMAIL];
    
    if ( [email length] > 0 ) {
        self.emailBoxText = email;
//    } else if ([self.emailBox numberOfItems] >= 2) {
//        NSString *defaultSender = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_DEFAULTSENDER];
//        NSUInteger idx = (defaultSender && [defaultSender isEqualToString:@"firstEmail"]) ? 1 : 0;
//        self.emailBoxText = defaultSender;
    }
    
    if (emailRequired &&
        (self.emailBoxText == nil || [self.emailBoxText isEqualToString:@""] || [self.emailBoxText isEqualToString:FRLocalizedString(@"anonymous", nil)])) {
        self.emailBoxTextColor = [UIColor redColor];
    }
    else {
        self.emailBoxTextColor = [UIColor blackColor];
    }
    
    
    self.messageViewText = @"";
    self.exceptionViewText = @"";
    
    [self showDetails:NO animate:NO];
    
    [self startSpinner];
    [self.sendButton setEnabled:NO];

    //  setup 'send details' section...
    NSString *sendDetailsIsOptional = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_SENDDETAILSISOPTIONAL];
    self.sendDetailsIsOptional = ( sendDetailsIsOptional && [sendDetailsIsOptional isEqualToString:@"YES"] );
    if ( self.sendDetailsIsOptional ) {
        self.includeConsole = NO; // let user choose
    } else {
        self.sendDetails = YES;
        self.includeConsole = YES; // force inclusion
    }
}



#pragma mark Notification handlers

- (void) handleEmailTextDidEndEditing:(NSNotification *)notification
{
    UITextField *emailBox = notification.object;
    self.emailBoxText = emailBox.text;
}

- (void) handleTextViewDidEndEditing:(NSNotification *)notification
{
    UITextView *textView = notification.object;
    if ( textView.tag == TEXTVIEW_MESSAGE_TAG ) {
        self.messageViewText = textView.text;
    }
    else if ( textView.tag == TEXTVIEW_DETAILS_TAG ) {
        [self.selectedDetailTabItem setObject:textView.text forKey:@"text"];
    }
}

- (void) handleSelectedDetailTabItemDidChange:(NSNotification *)notification
{
    // force end editing to preserve current text view value in currently-selected tab before we switch
    NSIndexPath *detailsIndexPath = [NSIndexPath indexPathForRow:SECTION_DETAILS_ROW_TAB_TEXT inSection:SECTION_DETAILS];
    FRiOSFeedbackTableViewTextViewCell *cell = (FRiOSFeedbackTableViewTextViewCell *)[self.tableView cellForRowAtIndexPath:detailsIndexPath];
    [cell.textView endEditing:YES];
    
    id tabItem = notification.object;
    self.selectedDetailTabItem = tabItem;
    
    [self updateDetailsTextView];
}

@end
