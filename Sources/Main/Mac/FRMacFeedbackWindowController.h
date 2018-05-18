//
//  FRMacFeedbackWindowController.m
//  F53FeedbackKit
//
//  Created by Brent Lord on 9/20/15.
//  Copyright © 2015-2018 Figure 53, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "FRDocumentList.h"
#import "FRConstants.h"

@class FRFeedbackController;


NS_ASSUME_NONNULL_BEGIN

@interface FRMacFeedbackWindowController : NSWindowController <NSWindowDelegate>

@property (nonatomic, weak)                 FRFeedbackController *feedbackController;
@property (nonatomic, weak)                 NSString *type;

@property (nonatomic, weak)                 IBOutlet NSTextField *headingField;
@property (nonatomic, weak)                 IBOutlet NSTextField *subheadingField;
    
@property (nonatomic, weak)                 IBOutlet NSTextField *messageLabel;
@property (nonatomic, unsafe_unretained)    IBOutlet NSTextView *messageView;
    
@property (nonatomic, weak)                 IBOutlet NSTextField *emailLabel;
@property (nonatomic, weak)                 IBOutlet NSComboBox *emailBox;
    
@property (nonatomic, weak)                 IBOutlet NSButton *detailsButton;
@property (nonatomic, weak)                 IBOutlet NSTextField *detailsLabel;
@property (nonatomic)                       BOOL detailsShown;
    
@property (nonatomic, weak)                 IBOutlet NSButton *sendDetailsCheckbox;
@property (nonatomic, weak)                 IBOutlet NSButton *includeConsoleCheckbox;
    
@property (nonatomic, weak)                 IBOutlet NSTabView *tabView;
@property (nonatomic, strong)               IBOutlet NSTabViewItem *tabSystem;
@property (nonatomic, strong)               IBOutlet NSTabViewItem *tabConsole;
@property (nonatomic, strong)               IBOutlet NSTabViewItem *tabCrash;
@property (nonatomic, strong)               IBOutlet NSTabViewItem *tabScript;
@property (nonatomic, strong)               IBOutlet NSTabViewItem *tabPreferences;
@property (nonatomic, strong)               IBOutlet NSTabViewItem *tabException;
@property (nonatomic, strong)               IBOutlet NSTabViewItem *tabDocuments;
    
@property (nonatomic, weak)                 IBOutlet NSTableView *systemView;
@property (nonatomic, unsafe_unretained)    IBOutlet NSTextView *consoleView;
@property (nonatomic, unsafe_unretained)    IBOutlet NSTextView *crashesView;
@property (nonatomic, unsafe_unretained)    IBOutlet NSTextView *scriptView;
@property (nonatomic, unsafe_unretained)    IBOutlet NSTextView *preferencesView;
@property (nonatomic, unsafe_unretained)    IBOutlet NSTextView *exceptionView;
@property (nonatomic, weak)                 IBOutlet NSTableView *documentsView;
    
@property (nonatomic, weak)                 IBOutlet NSButton *otherDocumentButton;
    
@property (nonatomic, weak)                 IBOutlet NSProgressIndicator *indicator;
    
@property (nonatomic, weak)                 IBOutlet NSButton *cancelButton;
@property (nonatomic, weak)                 IBOutlet NSButton *sendButton;
    
@property (nonatomic, strong, nullable)     FRDocumentList *documentList;

@property (nonatomic, getter=isUploading)   BOOL uploading;

- (void) show;
- (void) resetWithEmailRequired:(BOOL)emailRequired;

@end

NS_ASSUME_NONNULL_END
