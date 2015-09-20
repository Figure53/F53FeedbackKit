/*
 * Copyright 2008-2011, Torsten Curdt
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Cocoa/Cocoa.h>
#import "FRUploader.h"
#import "FRDocumentList.h"

#define FR_FEEDBACK  @"feedback"
#define FR_EXCEPTION @"exception"
#define FR_CRASH     @"crash"
#define FR_SUPPORT   @"support"

{
@private
    IBOutlet NSTextField *headingField;
    IBOutlet NSTextField *subheadingField;

    IBOutlet NSTextField *messageLabel;
    IBOutlet NSTextView *messageView;
@interface FRFeedbackController : NSWindowController <FRUploaderDelegate, NSWindowDelegate>

    IBOutlet NSTextField *emailLabel;
    IBOutlet NSComboBox *emailBox;

    IBOutlet NSButton *detailsButton;
    IBOutlet NSTextField *detailsLabel;
    BOOL detailsShown;

	IBOutlet NSButton *sendDetailsCheckbox;
    IBOutlet NSButton *includeConsoleCheckbox;

    IBOutlet NSTabView *tabView;
    IBOutlet NSTabViewItem *tabSystem;
    IBOutlet NSTabViewItem *tabConsole;
    IBOutlet NSTabViewItem *tabCrash;
    IBOutlet NSTabViewItem *tabScript;
    IBOutlet NSTabViewItem *tabPreferences;
    IBOutlet NSTabViewItem *tabException;
    IBOutlet NSTabViewItem *tabDocuments;

    IBOutlet NSTableView *systemView;
    IBOutlet NSTextView *consoleView;
    IBOutlet NSTextView *crashesView;
    IBOutlet NSTextView *scriptView;
    IBOutlet NSTextView *preferencesView;
    IBOutlet NSTextView *exceptionView;
    IBOutlet NSTableView *documentsView;
    
    IBOutlet NSButton *otherDocumentButton;

    IBOutlet NSProgressIndicator *indicator;

    IBOutlet NSButton *cancelButton;
    IBOutlet NSButton *sendButton;
		
    
    
    FRDocumentList *documentList;
    
}
@property (nonatomic, weak)     id<FRFeedbackReporterDelegate> delegate;
@property (nonatomic, strong)   NSString *type;

#pragma mark Accessors


- (void) setHeading:(NSString *)message;
- (void) setSubheading:(NSString *)informativeText;
- (void) setMessage:(NSString *)message;
- (void) setException:(NSString *)exception;

#pragma mark UI

- (IBAction) showDetails:(id)sender;
- (IBAction) sendDetailsChecked:(id)sender;
- (IBAction) includeConsoleChecked:(id)sender;
- (IBAction) cancel:(id)sender;
- (IBAction) send:(id)sender;

#pragma mark Other

- (void) reset;
- (BOOL) isShown;

@end
