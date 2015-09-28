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
@property (unsafe_unretained)   NSString *type;

@property (unsafe_unretained)   IBOutlet NSTextField *headingField;
@property (unsafe_unretained)   IBOutlet NSTextField *subheadingField;
    
@property (unsafe_unretained)   IBOutlet NSTextField *messageLabel;
@property (unsafe_unretained)   IBOutlet NSTextView *messageView;
    
@property (unsafe_unretained)   IBOutlet NSTextField *emailLabel;
@property (unsafe_unretained)   IBOutlet NSComboBox *emailBox;
    
@property (unsafe_unretained)   IBOutlet NSButton *detailsButton;
@property (unsafe_unretained)   IBOutlet NSTextField *detailsLabel;
@property (nonatomic)           BOOL detailsShown;
    
@property (unsafe_unretained)   IBOutlet NSButton *sendDetailsCheckbox;
@property (unsafe_unretained)   IBOutlet NSButton *includeConsoleCheckbox;
    
@property (unsafe_unretained)   IBOutlet NSTabView *tabView;
@property (unsafe_unretained)   IBOutlet NSTabViewItem *tabSystem;
@property (unsafe_unretained)   IBOutlet NSTabViewItem *tabConsole;
@property (unsafe_unretained)   IBOutlet NSTabViewItem *tabCrash;
@property (unsafe_unretained)   IBOutlet NSTabViewItem *tabScript;
@property (unsafe_unretained)   IBOutlet NSTabViewItem *tabPreferences;
@property (unsafe_unretained)   IBOutlet NSTabViewItem *tabException;
@property (unsafe_unretained)   IBOutlet NSTabViewItem *tabDocuments;
    
@property (nonatomic, strong)   IBOutlet NSTableView *systemView;
@property (nonatomic, strong)   IBOutlet NSTextView *consoleView;
@property (nonatomic, strong)   IBOutlet NSTextView *crashesView;
@property (nonatomic, strong)   IBOutlet NSTextView *scriptView;
@property (nonatomic, strong)   IBOutlet NSTextView *preferencesView;
@property (nonatomic, strong)   IBOutlet NSTextView *exceptionView;
@property (nonatomic, strong)   IBOutlet NSTableView *documentsView;
    
@property (unsafe_unretained)   IBOutlet NSButton *otherDocumentButton;
    
@property (unsafe_unretained)   IBOutlet NSProgressIndicator *indicator;
    
@property (unsafe_unretained)   IBOutlet NSButton *cancelButton;
@property (unsafe_unretained)   IBOutlet NSButton *sendButton;
    
@property (nonatomic, strong)   FRDocumentList *documentList;

@property (nonatomic, getter=isUploading)   BOOL uploading;

- (void) show;
- (void) resetWithEmailRequired:(BOOL)emailRequired;

@end
