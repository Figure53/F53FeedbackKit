//
//  FRMacFeedbackWindowController.m
//  F53FeedbackKit
//
//  Created by Brent Lord on 9/20/15.
//  Copyright © 2015 Figure 53, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "FRDocumentList.h"
#import "FRConstants.h"


@class FRFeedbackController;

@interface FRMacFeedbackWindowController : NSWindowController <NSWindowDelegate>

@property (nonatomic, weak)     FRFeedbackController *feedbackController;
@property (nonatomic, strong)   NSString *type;

@property (nonatomic, strong)   IBOutlet NSTextField *headingField;
@property (nonatomic, strong)   IBOutlet NSTextField *subheadingField;
    
@property (nonatomic, strong)   IBOutlet NSTextField *messageLabel;
@property (nonatomic, strong)   IBOutlet NSTextView *messageView;
    
@property (nonatomic, strong)   IBOutlet NSTextField *emailLabel;
@property (nonatomic, strong)   IBOutlet NSComboBox *emailBox;
    
@property (nonatomic, strong)   IBOutlet NSButton *detailsButton;
@property (nonatomic, strong)   IBOutlet NSTextField *detailsLabel;
@property (nonatomic)           BOOL detailsShown;
    
@property (nonatomic, strong)   IBOutlet NSButton *sendDetailsCheckbox;
@property (nonatomic, strong)   IBOutlet NSButton *includeConsoleCheckbox;
    
@property (nonatomic, strong)   IBOutlet NSTabView *tabView;
@property (nonatomic, strong)   IBOutlet NSTabViewItem *tabSystem;
@property (nonatomic, strong)   IBOutlet NSTabViewItem *tabConsole;
@property (nonatomic, strong)   IBOutlet NSTabViewItem *tabCrash;
@property (nonatomic, strong)   IBOutlet NSTabViewItem *tabScript;
@property (nonatomic, strong)   IBOutlet NSTabViewItem *tabPreferences;
@property (nonatomic, strong)   IBOutlet NSTabViewItem *tabException;
@property (nonatomic, strong)   IBOutlet NSTabViewItem *tabDocuments;
    
@property (nonatomic, strong)   IBOutlet NSTableView *systemView;
@property (nonatomic, strong)   IBOutlet NSTextView *consoleView;
@property (nonatomic, strong)   IBOutlet NSTextView *crashesView;
@property (nonatomic, strong)   IBOutlet NSTextView *scriptView;
@property (nonatomic, strong)   IBOutlet NSTextView *preferencesView;
@property (nonatomic, strong)   IBOutlet NSTextView *exceptionView;
@property (nonatomic, strong)   IBOutlet NSTableView *documentsView;
    
@property (nonatomic, strong)   IBOutlet NSButton *otherDocumentButton;
    
@property (nonatomic, strong)   IBOutlet NSProgressIndicator *indicator;
    
@property (nonatomic, strong)   IBOutlet NSButton *cancelButton;
@property (nonatomic, strong)   IBOutlet NSButton *sendButton;
    
@property (nonatomic, strong)   FRDocumentList *documentList;

@property (nonatomic, getter=isUploading)   BOOL uploading;

- (void) show;
- (void) resetWithEmailRequired:(BOOL)emailRequired;

@end
