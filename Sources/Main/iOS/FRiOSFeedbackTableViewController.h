//
//  FRiOSFeedbackTableViewController.h
//  F53FeedbackKit
//
//  Created by Brent Lord on 9/22/15.
//  Copyright © 2015-2018 Figure 53, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

//#import "FRDocumentList.h"
#import "FRConstants.h"


@class FRFeedbackController;


NS_ASSUME_NONNULL_BEGIN

@interface FRiOSFeedbackTableViewController : UITableViewController

@property (nonatomic, weak)                     FRFeedbackController *feedbackController;
@property (nonatomic, strong)                   NSString *type;

@property (nonatomic, strong)                   NSString *titleText;

@property (nonatomic, strong)                   NSString *headingText;
@property (nonatomic, strong)                   NSString *subheadingText;

@property (nonatomic, strong)                   NSString *messageLabelText;
@property (nonatomic, strong)                   NSString *messageViewText;

@property (nonatomic, strong)                   NSString *emailBoxText;

@property (nonatomic, strong, null_resettable)  NSString *crashesViewText;

@property (nonatomic, strong, null_resettable)  NSString *exceptionViewText;

@property (nonatomic)                           BOOL sendDetails;
@property (nonatomic)                           BOOL includeConsole;

//@property (nonatomic, strong)                   IBOutlet NSButton *otherDocumentButton;

//@property (nonatomic, strong)                   FRDocumentList *documentList;

@property (nonatomic, getter=isUploading)       BOOL uploading;

- (NSString *) consoleViewText;
- (NSString *) scriptViewText;
- (NSString *) preferencesViewText;
- (NSString *) documentsViewText;

- (void) show;
- (void) resetWithEmailRequired:(BOOL)emailRequired;

@end

NS_ASSUME_NONNULL_END
