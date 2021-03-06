//
//  FRiOSFeedbackTableViewController.m
//  F53FeedbackKit
//
//  Created by Brent Lord on 9/22/15.
//  Copyright © 2015-2019 Figure 53, LLC. All rights reserved.
//

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "FRiOSFeedbackTableViewController.h"

#import "FRFeedbackController.h"

#import "FRCrashLogFinder.h"

#import "FRiOSFeedbackTableViewHeaderView.h"
#import "FRiOSFeedbackTableViewFooterView.h"
#import "FRiOSFeedbackTableViewCheckmarkCell.h"
#import "FRiOSFeedbackTableViewEmailCell.h"
#import "FRiOSFeedbackTableViewTabPickerCell.h"
#import "FRiOSFeedbackTableViewTextViewCell.h"


NS_ASSUME_NONNULL_BEGIN

@interface FRiOSFeedbackTableViewController ()

@property (nonatomic, strong, nullable) UIColor *delegateTintColor;
@property (nonatomic, strong, nullable) UIColor *emailBoxTextColor;
@property (nonatomic, strong)           NSString *detailsLabelText;

@property (nonatomic)                   BOOL sendDetailsIsOptional;
@property (nonatomic)                   BOOL detailsShown;
@property (nonatomic)                   BOOL includeConsoleSpinnerOn;

@property (nonatomic, strong)           NSMutableArray<NSMutableDictionary *> *detailsTabItems;
@property (nonatomic, strong)           NSMutableDictionary<NSString *, NSString *> *selectedDetailTabItem;
@property (nonatomic, strong)           NSMutableDictionary<NSString *, NSString *> *detailTabSystem;
@property (nonatomic, strong)           NSMutableDictionary<NSString *, NSString *> *detailTabConsole;
@property (nonatomic, strong)           NSMutableDictionary<NSString *, NSString *> *detailTabCrash;
@property (nonatomic, strong)           NSMutableDictionary<NSString *, NSString *> *detailTabScript;
@property (nonatomic, strong)           NSMutableDictionary<NSString *, NSString *> *detailTabPreferences;
@property (nonatomic, strong)           NSMutableDictionary<NSString *, NSString *> *detailTabException;
@property (nonatomic, strong)           NSMutableDictionary<NSString *, NSString *> *detailTabDocuments;

//@property (nonatomic, strong)           IBOutlet NSButton *otherDocumentButton;

@property (nonatomic, strong)           UIBarButtonItem *cancelButton;
@property (nonatomic, strong)           UIBarButtonItem *sendButton;
@property (nonatomic, strong)           UIBarButtonItem *sendingSpinner;

@property (nonatomic, strong)           NSString *preferences;

- (NSArray<NSDictionary *> *) systemProfile;

- (void) populate;
- (void) loadConsole;
- (void) populateConsole;
- (void) stopSpinner;

- (NSString *) crashLog;
//- (NSString *) scriptLog;

#pragma mark - UI

- (void) showDetails:(BOOL)show animate:(BOOL)animate;
- (void) sendDetailsChecked:(FRiOSFeedbackTableViewCheckmarkCell *)sender;
- (void) includeConsoleChecked:(FRiOSFeedbackTableViewCheckmarkCell *)sender;
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

#define TEXTVIEW_MESSAGE_TAG    (SECTION_MESSAGE * 10000) + (SECTION_MESSAGE_ROW_MESSAGE * 100) + 1
#define TEXTVIEW_DETAILS_TAG    (SECTION_DETAILS * 10000) + (SECTION_DETAILS_ROW_TAB_TEXT * 100) + 1

#define MESSAGE_DEFAULT_HEIGHT              150.0
#define EMAIL_DEFAULT_HEIGHT                60.0
#define TABS_DEFAULT_HEIGHT                 44.0


- (instancetype) initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if ( self )
    {
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
    
    NSBundle *nibBundle = self.nibBundle;
    if ( !nibBundle )
    {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        
        // when built with CocoaPods, the url will be non-nil and we use that to fetch the correct bundle before loading the nib
        // - (NOTE: the bundle name is specified by the key of the podspec `resource_bundles` hash)
        // when building the F53FeedbackKit_iOS.framework (which does not bundle), the url will be nil and we use the bundle fetched above.
        NSURL *url = [bundle URLForResource:@"F53FeedbackKit" withExtension:@"bundle"];
        if ( url )
            bundle = [NSBundle bundleWithURL:url];
        nibBundle = bundle;
    }
    
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    if ( @available(iOS 10.0, *) )
    {
        // NOTE: Custom header/footer classes are only needed if the delegate implements `feedbackControllerTextScale`.
        // - The classes need to be registered here (before the feedbackController.delegate is set).
        // - If the feedback controller delegate does not implement `feedbackControllerTextScale`, `viewForHeaderInSection:` and `viewForFooterInSection:` below return nil so the table uses a default header/footer view.
        [self.tableView registerClass:[FRiOSFeedbackTableViewHeaderView class] forHeaderFooterViewReuseIdentifier:FRiOSFeedbackTableViewHeaderViewIdentifier];
        [self.tableView registerClass:[FRiOSFeedbackTableViewFooterView class] forHeaderFooterViewReuseIdentifier:FRiOSFeedbackTableViewFooterViewIdentifier];
        self.tableView.estimatedSectionHeaderHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedSectionFooterHeight = UITableViewAutomaticDimension;
    }
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"reuseIdentifier"];
    [self.tableView registerClass:[FRiOSFeedbackTableViewCheckmarkCell class] forCellReuseIdentifier:FRiOSFeedbackTableViewCheckmarkCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"FRiOSFeedbackTableViewEmailCell" bundle:nibBundle] forCellReuseIdentifier:FRiOSFeedbackTableViewEmailCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"FRiOSFeedbackTableViewTabPickerCell" bundle:nibBundle] forCellReuseIdentifier:FRiOSFeedbackTableViewTabPickerCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:@"FRiOSFeedbackTableViewTextViewCell" bundle:nibBundle] forCellReuseIdentifier:FRiOSFeedbackTableViewTextViewCellIdentifier];
    
    self.title = FRLocalizedString(@"Feedback", nil);
    self.detailsLabelText = FRLocalizedString(@"Details", nil);
    
    self.sendButton = [[UIBarButtonItem alloc] initWithTitle:FRLocalizedString(@"Send", nil) style:UIBarButtonItemStyleDone target:self action:@selector(send:)];
    self.sendButton.accessibilityLabel = self.sendButton.title;
    self.navigationItem.rightBarButtonItem = self.sendButton;
    
    self.cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = self.cancelButton;
    
    UIActivityIndicatorViewStyle indicatorStyle = UIActivityIndicatorViewStyleGray;
    UIActivityIndicatorView *sendingSpinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:indicatorStyle];
    sendingSpinnerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    self.sendingSpinner = [[UIBarButtonItem alloc] initWithCustomView:sendingSpinnerView];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ( [self.feedbackController.delegate respondsToSelector:@selector(feedbackControllerTintColor)] )
    {
        self.delegateTintColor = [self.feedbackController.delegate feedbackControllerTintColor];
        self.navigationController.navigationBar.tintColor = self.delegateTintColor;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTextViewDidEndEditing:) name:FRiOSFeedbackTableViewTextViewCellDidEndEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEmailTextDidEndEditing:) name:FRiOSFeedbackTableViewEmailCellDidEndEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSelectedDetailTabItemDidChange:) name:FRiOSFeedbackTableViewTabPickerCellTabItemDidChangeNotification object:nil];
    
    if ( self.titleText )
        self.title = self.titleText;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:SECTION_MESSAGE_ROW_MESSAGE inSection:SECTION_MESSAGE];
    NSUInteger tag = [self getTagFromIndexPath:indexPath];
    UIView *messageTextView = [self.tableView viewWithTag:tag + 1];
    [messageTextView becomeFirstResponder];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.feedbackController cancelUpload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FRiOSFeedbackTableViewTextViewCellDidEndEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FRiOSFeedbackTableViewEmailCellDidEndEditingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:FRiOSFeedbackTableViewTabPickerCellTabItemDidChangeNotification object:nil];
    
    if ( [self.type isEqualToString:FR_EXCEPTION] )
    {
        id exitAfterExceptionValue = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_EXITAFTEREXCEPTION];
        if ( [exitAfterExceptionValue respondsToSelector:@selector(boolValue)] && [exitAfterExceptionValue boolValue] )
        {
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
            if ( self.detailsShown )
                return SECTION_DETAILS_NUM_ROWS;
            else
                return 1;
            
        default:
            break;
            
    }
    
    return 0;
}

- (nullable NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
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

- (nullable NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
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
                    
                case SECTION_MESSAGE_ROW_MESSAGE:
                    return [tableView dequeueReusableCellWithIdentifier:FRiOSFeedbackTableViewTextViewCellIdentifier forIndexPath:indexPath];
                    
                case SECTION_MESSAGE_ROW_EMAIL:
                    return [tableView dequeueReusableCellWithIdentifier:FRiOSFeedbackTableViewEmailCellIdentifier forIndexPath:indexPath];
                    
                default:
                    break;
                    
            }
        } break;
            
        case SECTION_DETAILS: {
            switch ( indexPath.row ) {
                    
                case SECTION_DETAILS_ROW_SEND_DETAILS:
                    return [tableView dequeueReusableCellWithIdentifier:FRiOSFeedbackTableViewCheckmarkCellIdentifier forIndexPath:indexPath];
                    
                case SECTION_DETAILS_ROW_INCL_CONSOLE:
                    return [tableView dequeueReusableCellWithIdentifier:FRiOSFeedbackTableViewCheckmarkCellIdentifier forIndexPath:indexPath];
                    
                case SECTION_DETAILS_ROW_TABS:
                    return [tableView dequeueReusableCellWithIdentifier:FRiOSFeedbackTableViewTabPickerCellIdentifier forIndexPath:indexPath];
                    
                case SECTION_DETAILS_ROW_TAB_TEXT:
                    return [tableView dequeueReusableCellWithIdentifier:FRiOSFeedbackTableViewTextViewCellIdentifier forIndexPath:indexPath];
                    
                default:
                    break;
                    
            }
        } break;
            
        default:
            break;
            
    }
    
    // all else, return generic cell
    return [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
}


#pragma mark - Table view delegate

- (nullable UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = nil;
    
    if ( @available(iOS 10.0, *) )
    {
        if ( [self.feedbackController.delegate respondsToSelector:@selector(feedbackControllerTextScale)] )
        {
            UITableViewHeaderFooterView *sectionHeaderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:FRiOSFeedbackTableViewHeaderViewIdentifier];
            sectionHeaderView.textLabel.numberOfLines = 0;
            
            CGFloat scale = [self.feedbackController.delegate feedbackControllerTextScale];
            UIFont *defaultFont = [FRiOSFeedbackTableViewHeaderView defaultFont];
            UIFont *font = [defaultFont fontWithSize:floor( defaultFont.pointSize * scale )];
            sectionHeaderView.textLabel.adjustsFontForContentSizeCategory = NO;
            sectionHeaderView.textLabel.font = font;
            
            view = sectionHeaderView;
        }
    }
    
    return view;
}

- (nullable UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *view = nil;
    
    if ( @available(iOS 10.0, *) )
    {
        if ( [self.feedbackController.delegate respondsToSelector:@selector(feedbackControllerTextScale)] )
        {
            UITableViewHeaderFooterView *sectionFooterView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:FRiOSFeedbackTableViewFooterViewIdentifier];
            sectionFooterView.textLabel.numberOfLines = 0;
            
            CGFloat scale = [self.feedbackController.delegate feedbackControllerTextScale];
            UIFont *defaultFont = [FRiOSFeedbackTableViewFooterView defaultFont];
            UIFont *font = [defaultFont fontWithSize:floor( defaultFont.pointSize * scale )];
            sectionFooterView.textLabel.adjustsFontForContentSizeCategory = NO;
            sectionFooterView.textLabel.font = font;
            
            view = sectionFooterView;
        }
    }
    
    return view;
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
    return 1.0; // if this delegate method is implemented, it must return a positive value to work correctly
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForFooterInSection:(NSInteger)section
{
    return 1.0; // if this delegate method is implemented, it must return a positive value to work correctly
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // global config
    cell.tintColor = self.delegateTintColor;
    cell.tag = [self getTagFromIndexPath:indexPath];
    
    switch ( indexPath.section ) {
            
        case SECTION_MESSAGE: {
            switch ( indexPath.row ) {
                    
                case SECTION_MESSAGE_ROW_MESSAGE: {
                    if ( [cell isKindOfClass:[FRiOSFeedbackTableViewTextViewCell class]] )
                    {
                        FRiOSFeedbackTableViewTextViewCell *textViewCell = (FRiOSFeedbackTableViewTextViewCell *)cell;
                        textViewCell.textView.tag = cell.tag + 1;
                        textViewCell.textView.text = self.messageViewText;
                        textViewCell.textViewPlaceholder.text = self.messageLabelText;
                        textViewCell.textViewPlaceholder.hidden = ( self.messageViewText.length > 0 );
                        
                        if ( @available(iOS 10.0, *) )
                        {
                            if ( [self.feedbackController.delegate respondsToSelector:@selector(feedbackControllerTextScale)] )
                            {
                                CGFloat scale = [self.feedbackController.delegate feedbackControllerTextScale];
                                CGFloat fontSize = floor( [UIFont labelFontSize] * scale );
                                UIFont *font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightRegular];
                                textViewCell.textView.adjustsFontForContentSizeCategory = NO;
                                textViewCell.textViewPlaceholder.adjustsFontForContentSizeCategory = NO;
                                textViewCell.textView.font = font;
                                textViewCell.textViewPlaceholder.font = font;
                            }
                        }
                    }
                } break;
                    
                case SECTION_MESSAGE_ROW_EMAIL: {
                    if ( [cell isKindOfClass:[FRiOSFeedbackTableViewEmailCell class]] )
                    {
                        FRiOSFeedbackTableViewEmailCell *emailCell = (FRiOSFeedbackTableViewEmailCell *)cell;
                        emailCell.emailBox.tag = cell.tag + 1;
                        emailCell.emailBox.text = self.emailBoxText;
                        emailCell.emailBox.textColor = self.emailBoxTextColor;
                        emailCell.emailBox.placeholder = FRLocalizedString(@"Email address:", nil);
                        
                        if ( @available(iOS 10.0, *) )
                        {
                            if ( [self.feedbackController.delegate respondsToSelector:@selector(feedbackControllerTextScale)] )
                            {
                                CGFloat scale = [self.feedbackController.delegate feedbackControllerTextScale];
                                CGFloat fontSize = floor( [UIFont labelFontSize] * scale );
                                UIFont *font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightRegular];
                                emailCell.emailBox.adjustsFontForContentSizeCategory = NO;
                                emailCell.emailBox.font = font;
                                emailCell.emailBox.attributedPlaceholder = [[NSAttributedString alloc] initWithString:FRLocalizedString(@"Email address:", nil) attributes:@{ NSFontAttributeName : font }];
                            }
                        }
                    }
                } break;
                    
            }
        } break;
            
        case SECTION_DETAILS: {
            switch ( indexPath.row ) {
                    
                case SECTION_DETAILS_ROW_SEND_DETAILS: {
                    cell.hidden = !self.sendDetailsIsOptional;
                    
                    if ( [cell isKindOfClass:[FRiOSFeedbackTableViewCheckmarkCell class]] )
                    {
                        FRiOSFeedbackTableViewCheckmarkCell *checkmarkCell = (FRiOSFeedbackTableViewCheckmarkCell *)cell;
                        checkmarkCell.textLabel.tag = cell.tag + 1;
                        checkmarkCell.textLabel.text = FRLocalizedString(@"Send details", nil);
                        checkmarkCell.checkmarkOn = self.sendDetails;
                        
                        if ( @available(iOS 10.0, *) )
                        {
                            if ( [self.feedbackController.delegate respondsToSelector:@selector(feedbackControllerTextScale)] )
                            {
                                CGFloat scale = [self.feedbackController.delegate feedbackControllerTextScale];
                                CGFloat fontSize = floor( [UIFont labelFontSize] * scale );
                                UIFont *font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightRegular];
                                checkmarkCell.textLabel.adjustsFontForContentSizeCategory = NO;
                                checkmarkCell.textLabel.font = font;
                            }
                        }
                    }
                } break;
                    
                case SECTION_DETAILS_ROW_INCL_CONSOLE: {
                    cell.hidden = ( !self.sendDetailsIsOptional || !self.detailsShown );
                    
                    if ( [cell isKindOfClass:[FRiOSFeedbackTableViewCheckmarkCell class]] )
                    {
                        FRiOSFeedbackTableViewCheckmarkCell *checkmarkCell = (FRiOSFeedbackTableViewCheckmarkCell *)cell;
                        checkmarkCell.textLabel.tag = cell.tag + 1;
                        checkmarkCell.textLabel.text = FRLocalizedString(@"Include console logs", nil);
                        checkmarkCell.checkmarkOn = self.includeConsole;
                        
                        if ( self.includeConsoleSpinnerOn )
                            [checkmarkCell startSpinner];
                        else
                            [checkmarkCell stopSpinner];
                        
                        if ( @available(iOS 10.0, *) )
                        {
                            if ( [self.feedbackController.delegate respondsToSelector:@selector(feedbackControllerTextScale)] )
                            {
                                CGFloat scale = [self.feedbackController.delegate feedbackControllerTextScale];
                                CGFloat fontSize = floor( [UIFont labelFontSize] * scale );
                                UIFont *font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightRegular];
                                checkmarkCell.textLabel.adjustsFontForContentSizeCategory = NO;
                                checkmarkCell.textLabel.font = font;
                            }
                        }
                    }
                } break;
                    
                case SECTION_DETAILS_ROW_TABS: {
                    if ( [cell isKindOfClass:[FRiOSFeedbackTableViewTabPickerCell class]] )
                    {
                        FRiOSFeedbackTableViewTabPickerCell *tabPickerCell = (FRiOSFeedbackTableViewTabPickerCell *)cell;
                        tabPickerCell.tabControl.tag = cell.tag + 1;
                        tabPickerCell.tabControl.tintColor = self.delegateTintColor;
                        
                        if ( @available(iOS 10.0, *) )
                        {
                            CGFloat fontSize = [self maybeScaledValueForValue:[UIFont smallSystemFontSize]];
                            UIFont *font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightMedium];
                            [tabPickerCell.tabControl setTitleTextAttributes:@{ NSFontAttributeName : font } forState:UIControlStateNormal];
                        }
                    }
                    
                    [self updateDetailsTabItems];
                } break;
                    
                case SECTION_DETAILS_ROW_TAB_TEXT: {
                    if ( [cell isKindOfClass:[FRiOSFeedbackTableViewTextViewCell class]] )
                    {
                        FRiOSFeedbackTableViewTextViewCell *textViewCell = (FRiOSFeedbackTableViewTextViewCell *)cell;
                        textViewCell.textView.tag = cell.tag + 1;
                        textViewCell.textView.editable = NO;
                        
                        UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
                        if ( @available(iOS 10.0, *) )
                        {
                            if ( [self.feedbackController.delegate respondsToSelector:@selector(feedbackControllerTextScale)] )
                            {
                                CGFloat scale = [self.feedbackController.delegate feedbackControllerTextScale];
                                CGFloat fontSize = floor( [UIFont labelFontSize] * scale * 0.9 ); // a bit smaller
                                font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightRegular];
                                textViewCell.textView.adjustsFontForContentSizeCategory = NO;
                            }
                        }
                        textViewCell.textView.font = font;
                    }
                    
                    [self updateDetailsTextView];
                } break;
                    
                default:
                    break;
                    
            }
        } break;
            
        default:
            break;
            
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = UITableViewAutomaticDimension;
    
    switch ( indexPath.section ) {
            
        case SECTION_MESSAGE: {
            switch ( indexPath.row ) {
                    
                case SECTION_MESSAGE_ROW_MESSAGE:
                    height = [self maybeScaledValueForValue:MESSAGE_DEFAULT_HEIGHT];
                    height = fmin( height, 300.0 );
                    break;
                    
                case SECTION_MESSAGE_ROW_EMAIL:
                    height = [self maybeScaledValueForValue:EMAIL_DEFAULT_HEIGHT];
                    height = fmin( height, 100.0 );
                    break;
                    
                default:
                    break;
            }
        } break;
            
        case SECTION_DETAILS: {
            switch ( indexPath.row ) {
                    
                case SECTION_DETAILS_ROW_SEND_DETAILS: {
                    // collapse details cell to hide if sending details is required
                    if ( !self.sendDetailsIsOptional )
                        height = 0.0;
                } break;
                    
                case SECTION_DETAILS_ROW_INCL_CONSOLE: {
                    // collapse console cell to hide if sending details is required or if details are not showing
                    if ( !self.sendDetailsIsOptional || !self.detailsShown )
                        height = 0.0;
                } break;
                    
                case SECTION_DETAILS_ROW_TABS:
                    height = [self maybeScaledValueForValue:TABS_DEFAULT_HEIGHT];
                    height = fmax( height, TABS_DEFAULT_HEIGHT );
                    height = fmin( height, 100.0 );
                    break;
                    
                case SECTION_DETAILS_ROW_TAB_TEXT:
                    height = 300.0;
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
            
        case SECTION_DETAILS: {
            switch ( indexPath.row ) {
                    
                case SECTION_DETAILS_ROW_SEND_DETAILS: {
                    FRiOSFeedbackTableViewCheckmarkCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    
                    BOOL wasChecked = cell.checkmarkOn;
                    cell.checkmarkOn = !wasChecked;
                    
                    [self sendDetailsChecked:cell];
                } break;
                    
                case SECTION_DETAILS_ROW_INCL_CONSOLE: {
                    FRiOSFeedbackTableViewCheckmarkCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                    
                    BOOL wasChecked = cell.checkmarkOn;
                    cell.checkmarkOn = !wasChecked;
                    
                    [self includeConsoleChecked:cell];
                } break;
                    
                default:
                    break;
            }
        } break;
            
        default:
            break;
    }
}

#pragma mark -

- (NSInteger) getTagFromIndexPath:(NSIndexPath *)indexPath
{
    NSInteger thisTag = 0;
    
    if ( indexPath )
    {
        thisTag += indexPath.section * 10000;
        thisTag += indexPath.row * 100;
    }
    
    return thisTag;
}

- (CGFloat) maybeScaledValueForValue:(CGFloat)value
{
    // If delegate implements `feedbackControllerTextScale` (and we are on iOS 10+), scale using the delegate value.
    // If not, scale using the current font size category, if available (iOS 11+ only).
    // All else, pass thru original value unscaled.
    
    if ( @available(iOS 10.0, *) )
    {
        if ( [self.feedbackController.delegate respondsToSelector:@selector(feedbackControllerTextScale)] )
            return floor( [self.feedbackController.delegate feedbackControllerTextScale] * value );
    }
    
    if ( @available(iOS 11.0, *) )
    {
        return floor( [[UIFontMetrics defaultMetrics] scaledValueForValue:value] );
    }
    
    // all else - no scaling
    return value;
}


#pragma mark - information gathering

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
        if ( [crashLog length] > 0 )
        {
            dispatch_sync( dispatch_get_main_queue(), ^{
                [self addDetailsTabItem:self.detailTabCrash];
                [self.detailTabCrash setObject:crashLog forKey:@"text"];
            });
        }
        
//        NSString *scriptLog = [self scriptLog];
//        if ( [scriptLog length] > 0 )
//        {
//            dispatch_sync( dispatch_get_main_queue(), ^{
//                [self addDetailsTabItem:self.detailTabScript];
//                [self.detailTabScript setObject:scriptLog forKey:@"text"];
//            });
//        }
        
        if ( [self.preferences length] > 0 )
        {
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
    if ( consoleLog != nil )
    {
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
    
    if ( i == 1 )
    {
        if ( lastSubmissionDate == nil )
            NSLog(@"Found a crash file");
        else
            NSLog(@"Found a crash file earlier than latest submission on %@", lastSubmissionDate);
        
        NSError *error = nil;
        NSString *result = [NSString stringWithContentsOfFile:[crashFiles lastObject] encoding:NSUTF8StringEncoding error:&error];
        if ( result == nil )
        {
            NSLog(@"Failed to read crash file: %@", error);
            return @"";
        }
        return result;
    }
    
    if ( lastSubmissionDate == nil )
        NSLog(@"Found %lu crash files", (unsigned long)i);
    else
        NSLog(@"Found %lu crash files earlier than latest submission on %@", (unsigned long)i, lastSubmissionDate);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSDate *newest = nil;
    NSInteger newestIndex = -1;
    
    while( i-- )
    {
        NSString *crashFile = [crashFiles objectAtIndex:i];
        NSError *error = nil;
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:crashFile error:&error];
        if ( !fileAttributes )
            NSLog(@"Error while fetching file attributes: %@", [error localizedDescription]);
        
        NSDate *fileModDate = [fileAttributes objectForKey:NSFileModificationDate];
        
        NSLog(@"CrashLog: %@", crashFile);
        
        if ( [fileModDate laterDate:newest] == fileModDate )
        {
            newest = fileModDate;
            newestIndex = i;
        }
    }
    
    if ( newestIndex != -1 )
    {
        NSString *newestCrashFile = [crashFiles objectAtIndex:newestIndex];
        
        NSLog(@"Picking CrashLog: %@", newestCrashFile);
        
        NSError *error = nil;
        NSString *result = [NSString stringWithContentsOfFile:newestCrashFile encoding:NSUTF8StringEncoding error:&error];
        if ( result == nil )
        {
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
//    NSString *scriptPath = [[NSBundle mainBundle] pathForResource:FILE_SHELLSCRIPT ofType:@"sh"];
//
//    if ( [[NSFileManager defaultManager] fileExistsAtPath:scriptPath] )
//    {
//        FRCommand *cmd = [[FRCommand alloc] initWithPath:scriptPath];
//        [cmd setOutput:scriptLog];
//        [cmd setError:scriptLog];
//        int ret = [cmd execute];
//
//        NSLog(@"Script exit code = %d", ret);
//    }
////    else
////    {
////        NSLog(@"No custom script to execute");
////    }
//
//    return scriptLog;
//}

#pragma mark - custom setters/getters

- (void) setFeedbackController:(nullable FRFeedbackController *)feedbackController
{
    if ( _feedbackController != feedbackController )
    {
        _feedbackController = feedbackController;
        
        [self.detailTabSystem setValue:[_feedbackController systemProfileAsString] forKey:@"text"];
    }
}

- (void) setUploading:(BOOL)uploading
{
    if ( _uploading != uploading )
    {
        _uploading = uploading;
        
        if ( _uploading )
        {
            [(UIActivityIndicatorView *)self.sendingSpinner.customView startAnimating];
            self.navigationItem.rightBarButtonItem = self.sendingSpinner;
        }
        else
        {
            self.navigationItem.rightBarButtonItem = self.sendButton;
            [(UIActivityIndicatorView *)self.sendingSpinner.customView stopAnimating];
        }
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:SECTION_MESSAGE_ROW_MESSAGE inSection:SECTION_MESSAGE];
        NSUInteger tag = [self getTagFromIndexPath:indexPath];
        UIView *messageTextView = [self.tableView viewWithTag:tag + 1];
        if ( [messageTextView isKindOfClass:[UITextView class]] )
            ((UITextView *)messageTextView).editable = !_uploading;
        
        [self.sendButton setEnabled:!_uploading];
    }
}

- (NSString *) consoleViewText
{
    NSString *text = [self.detailTabConsole objectForKey:@"text"];
    if ( !text )
        text = @"";
    return text;
}

- (NSString *) crashesViewText;
{
    NSString *text = [self.detailTabCrash objectForKey:@"text"];
    if ( !text )
        text = @"";
    return text;
}

- (void) setCrashesViewText:(nullable NSString *)crashesViewText
{
    if ( crashesViewText )
        [self.detailTabCrash setObject:crashesViewText forKey:@"text"];
    else
        [self.detailTabCrash removeObjectForKey:@"text"];
}

- (NSString *) scriptViewText;
{
    NSString *text = [self.detailTabScript objectForKey:@"text"];
    if ( !text )
        text = @"";
    return text;
}

- (NSString *) preferencesViewText;
{
    NSString *text = [self.detailTabPreferences objectForKey:@"text"];
    if ( !text )
        text = @"";
    return text;
}

- (NSString *) exceptionViewText;
{
    NSString *text = [self.detailTabException objectForKey:@"text"];
    if ( !text )
        text = @"";
    return text;
}

- (void) setExceptionViewText:(nullable NSString *)exceptionViewText
{
    if ( exceptionViewText )
        [self.detailTabException setObject:exceptionViewText forKey:@"text"];
    else
        [self.detailTabException removeObjectForKey:@"text"];
}

- (NSString *) documentsViewText;
{
    NSString *text = [self.detailTabDocuments objectForKey:@"text"];
    if ( !text )
        text = @"";
    return text;
}

#pragma mark - UI Actions

- (void) showDetails:(BOOL)show animate:(BOOL)animate
{
    if ( self.detailsShown == show )
        return;
    
    self.detailsShown = show;
    
    UITableViewRowAnimation animation = ( animate ? UITableViewRowAnimationAutomatic : UITableViewRowAnimationNone );
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_DETAILS] withRowAnimation:animation];
}

- (void) sendDetailsChecked:(FRiOSFeedbackTableViewCheckmarkCell *)sender
{
    BOOL checked = sender.checkmarkOn;
    self.sendDetails = checked;
    
    [self showDetails:checked animate:YES];
}

- (void) includeConsoleChecked:(FRiOSFeedbackTableViewCheckmarkCell *)sender
{
    BOOL checked = sender.checkmarkOn;
    self.includeConsole = checked;
    
    if ( self.includeConsole )
    {
        [self startSpinner];
        [self.sendButton setEnabled:NO];
        [NSThread detachNewThreadSelector:@selector(loadConsole) toTarget:self withObject:nil];
    }
    else
    {
        [self.detailsTabItems removeObject:self.detailTabConsole];
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
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:SECTION_DETAILS_ROW_TABS inSection:SECTION_DETAILS];
    NSUInteger tag = [self getTagFromIndexPath:indexPath];
    UIView *tabPickerCell = [self.tableView viewWithTag:tag];
    if ( [tabPickerCell isKindOfClass:[FRiOSFeedbackTableViewTabPickerCell class]] )
        [(FRiOSFeedbackTableViewTabPickerCell *)tabPickerCell configureControlWithItems:self.detailsTabItems selectedItem:self.selectedDetailTabItem];
}

- (void) updateDetailsTextView
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:SECTION_DETAILS_ROW_TAB_TEXT inSection:SECTION_DETAILS];
    NSUInteger tag = [self getTagFromIndexPath:indexPath];
    UIView *detailsTextView = [self.tableView viewWithTag:tag + 1];
    if ( [detailsTextView isKindOfClass:[UITextView class]] )
        ((UITextView *)detailsTextView).text = [self.selectedDetailTabItem objectForKey:@"text"];
}

- (void) startSpinner
{
    if ( self.includeConsoleSpinnerOn )
        return;
    
    self.includeConsoleSpinnerOn = YES;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:SECTION_DETAILS_ROW_INCL_CONSOLE inSection:SECTION_DETAILS];
    NSUInteger tag = [self getTagFromIndexPath:indexPath];
    UIView *includeConsoleCell = [self.tableView viewWithTag:tag];
    if ( [includeConsoleCell isKindOfClass:[FRiOSFeedbackTableViewCheckmarkCell class]] )
        [(FRiOSFeedbackTableViewCheckmarkCell *)includeConsoleCell startSpinner];
}

- (void) stopSpinner
{
    if ( !self.includeConsoleSpinnerOn )
        return;
    
    self.includeConsoleSpinnerOn = NO;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:SECTION_DETAILS_ROW_INCL_CONSOLE inSection:SECTION_DETAILS];
    NSUInteger tag = [self getTagFromIndexPath:indexPath];
    UIView *includeConsoleCell = [self.tableView viewWithTag:tag];
    if ( [includeConsoleCell isKindOfClass:[FRiOSFeedbackTableViewCheckmarkCell class]] )
        [(FRiOSFeedbackTableViewCheckmarkCell *)includeConsoleCell stopSpinner];
    
    if ( [self.tableView.indexPathsForVisibleRows containsObject:indexPath] )
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    
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
    
    if ( [self.type isEqualToString:FR_FEEDBACK] )
        self.messageLabelText = FRLocalizedString(@"Feedback comment label", nil);
    else if ( [self.type isEqualToString:FR_SUPPORT] )
        self.messageLabelText = FRLocalizedString(@"Describe the problem:", nil);
    else
        self.messageLabelText = FRLocalizedString(@"Comments:", nil);
    
    if ( [self.exceptionViewText length] != 0 )
    {
        [self addDetailsTabItem:self.detailTabException];
        self.selectedDetailTabItem = self.detailTabException;
    }
    else
    {
        self.selectedDetailTabItem = self.detailTabSystem;
    }
    
    if ( [self.type isEqual:FR_SUPPORT] )
    {
        [self showDetails:YES animate:NO];
//        if ( [[self.documentList docs] count] > 0 )
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
    
    // if root is already presenting a navigation controller, reuse that controller to present
    if ( [presentingController.presentedViewController isKindOfClass:[UINavigationController class]] )
        presentingController = presentingController.presentedViewController;
    
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
//    for ( NSString *emailAddress in emailAddresses )
//    {
//        [self.emailBox addItemWithObjectValue:emailAddress];
//    }
    
    NSString *email = [[NSUserDefaults standardUserDefaults] stringForKey:DEFAULTS_KEY_SENDEREMAIL];
    
    if ( [email length] > 0 )
    {
        self.emailBoxText = email;
    }
//    else if ( [self.emailBox numberOfItems] >= 2 )
//    {
//        NSString *defaultSender = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_DEFAULTSENDER];
//        NSUInteger idx = ( defaultSender && [defaultSender isEqualToString:@"firstEmail"] ) ? 1 : 0;
//        self.emailBoxText = defaultSender;
//    }
    
    if ( emailRequired &&
        ( self.emailBoxText == nil || [self.emailBoxText isEqualToString:@""] || [self.emailBoxText isEqualToString:FRLocalizedString(@"anonymous", nil)] ) )
    {
        self.emailBoxTextColor = [UIColor redColor];
    }
    else
    {
        self.emailBoxTextColor = [UIColor blackColor];
    }
    
    
    self.messageViewText = @"";
    self.exceptionViewText = @"";
    
    [self showDetails:NO animate:NO];
    
    [self startSpinner];
    [self.sendButton setEnabled:NO];
    
    //  setup 'send details' section...
    self.sendDetails = YES;
    
    id sendDetailsIsOptionalValue = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_SENDDETAILSISOPTIONAL];
    self.sendDetailsIsOptional = ( [sendDetailsIsOptionalValue respondsToSelector:@selector(boolValue)] && [sendDetailsIsOptionalValue boolValue] );
    
    if ( self.sendDetailsIsOptional )
    {
        [self showDetails:YES animate:NO];
        
        id defaultIncludeConsoleValue = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_DEFAULTINCLUDECONSOLE];
        self.includeConsole = ( [defaultIncludeConsoleValue respondsToSelector:@selector(boolValue)] && [defaultIncludeConsoleValue boolValue] );
    }
    else
    {
        self.includeConsole = YES; // force inclusion
    }
}

#pragma mark - Notification handlers

- (void) handleEmailTextDidEndEditing:(NSNotification *)notification
{
    UITextField *emailBox = notification.object;
    self.emailBoxText = emailBox.text;
}

- (void) handleTextViewDidEndEditing:(NSNotification *)notification
{
    UITextView *textView = notification.object;
    if ( textView.tag == TEXTVIEW_MESSAGE_TAG )
        self.messageViewText = textView.text;
    else if ( textView.tag == TEXTVIEW_DETAILS_TAG )
        [self.selectedDetailTabItem setObject:textView.text forKey:@"text"];
}

- (void) handleSelectedDetailTabItemDidChange:(NSNotification *)notification
{
    // force end editing to preserve current text view value in currently-selected tab before we switch
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:SECTION_DETAILS_ROW_TAB_TEXT inSection:SECTION_DETAILS];
    NSUInteger tag = [self getTagFromIndexPath:indexPath];
    UIView *detailsTextView = [self.tableView viewWithTag:tag + 1];
    [detailsTextView endEditing:YES];
    
    id tabItem = notification.object;
    self.selectedDetailTabItem = tabItem;
    
    [self updateDetailsTextView];
}

@end

NS_ASSUME_NONNULL_END
