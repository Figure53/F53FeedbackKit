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

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "FRFeedbackController.h"
#import "FRFeedbackReporter.h"
#import "FRUploader.h"
#import "FRApplication.h"
#import "FRSystemProfile.h"
#import "FRConstants.h"
#import "FRConsoleLog.h"

#if TARGET_OS_IPHONE
#import "FRiOSFeedbackTableViewController.h"
#else
#import "FRMacFeedbackWindowController.h"
#import "FRCommand.h"
#endif

#import "NSMutableDictionary+FRAdditions.h"

#import <SystemConfiguration/SystemConfiguration.h>


NS_ASSUME_NONNULL_BEGIN

@interface FRFeedbackController ()

@property (nonatomic, strong, nullable) FRUploader *uploader;
@property (nonatomic, strong)           NSArray<NSString *> *emailRequiredTypes;
@property (nonatomic, strong)           NSArray<NSString *> *emailStronglySuggestedTypes;

- (NSMutableDictionary<NSString *, NSObject<NSCopying> *> *) parametersForFeedbackReport;
- (BOOL) shouldSend:(id)sender;
- (BOOL) shouldAttemptSendForUnreachableHost:(NSString *)host;

@end


#if TARGET_OS_IPHONE
@interface FRiOSFeedbackController : FRFeedbackController <FRUploaderDelegate>

@property (nonatomic, strong, null_resettable)  FRiOSFeedbackTableViewController *controller;

@property (nonatomic)                           BOOL allowSendWithoutEmailAddress;
@property (nonatomic)                           BOOL allowAttemptSendForUnreachableHost;

@end
#else
@interface FRMacFeedbackController : FRFeedbackController <FRUploaderDelegate>

@property (nonatomic, strong, null_resettable) FRMacFeedbackWindowController *windowController;

@end
#endif


@implementation FRFeedbackController

+ (instancetype) alloc
{
    if ( [self class] == [FRFeedbackController class] ) {
#if TARGET_OS_IPHONE
        return [FRiOSFeedbackController alloc];
#else
        return [FRMacFeedbackController alloc];
#endif
    }
    else {
        return [super alloc];
    }
}

- (instancetype) init
{
    self = [super init];
    if ( self ) {
        self.emailRequiredTypes = [NSArray arrayWithObject:FR_SUPPORT];
        self.emailStronglySuggestedTypes = [NSArray arrayWithObjects:FR_FEEDBACK, FR_CRASH, nil];
    }
    return self;
}


#pragma mark Accessors

- (void) setTitle:(NSString *)title
{
}

- (void) setHeading:(NSString *)message
{
}

- (void) setSubheading:(NSString *)informativeText
{
}

- (void) setMessage:(NSString *)message
{
}

- (void) setCrash:(NSString *)crash
{
}

- (void) setException:(NSString *)exception
{
}


#pragma mark information gathering

- (NSString *) consoleLog
{
    NSInteger hours = 24;
    NSInteger maxSize = 0;  // default to no maximum
    
    // valueForKey: could return NSNumber or NSString here
    // - both classes respond to integerValue
    id logHoursValue = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_LOGHOURS];
    if ( logHoursValue != nil && [logHoursValue respondsToSelector:@selector( integerValue )] ) {
        hours = [logHoursValue integerValue];
    }
    
    NSDate *since = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitHour value:-hours toDate:[NSDate date] options:0];
    
    // valueForKey: could return NSNumber or NSString here
    // - both classes respond to integerValue
    id maxConsoleLogSizeValue = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_MAXCONSOLELOGSIZE];
    if ( maxConsoleLogSizeValue != nil && [maxConsoleLogSizeValue respondsToSelector:@selector( integerValue )] ) {
        maxSize = [maxConsoleLogSizeValue integerValue];
    }
    
    NSString *consoleLog = [FRConsoleLog logSince:since maxSize:maxSize];
    if ( [self.delegate respondsToSelector:@selector(customizeConsoleLogForFeedbackReport:since:maxSize:)] ) {
        
        consoleLog = [self.delegate customizeConsoleLogForFeedbackReport:consoleLog since:since maxSize:maxSize];
        
        if ( maxSize > 0 && consoleLog.length > maxSize ) {
            NSUInteger index = consoleLog.length - maxSize;
            consoleLog = [consoleLog substringFromIndex:index];
        }
        
    }
    
    return consoleLog;
}


- (NSArray<NSDictionary *> *) systemProfile
{
    static NSArray<NSDictionary *> *systemProfile = nil;
    
    if (systemProfile == nil) {
        systemProfile = [FRSystemProfile discover];
    }
    
    return systemProfile;
}

- (NSString *) systemProfileAsString
{
    NSMutableString *string = [NSMutableString string];
    NSArray<NSDictionary *> *dicts = [self systemProfile];
    NSUInteger i = [dicts count];
    while(i--) {
        NSDictionary *dict = [dicts objectAtIndex:i];
        [string appendFormat:@"%@ = %@\n", [dict objectForKey:@"key"], [dict objectForKey:@"value"]];
    }
    return string;
}

- (NSString *) preferences
{
    NSMutableDictionary<NSString *, id> *preferences = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:[FRApplication applicationIdentifier]] mutableCopy];
    
    if (preferences == nil) {
        return @"";
    }
    
    [preferences removeObjectForKey:DEFAULTS_KEY_SENDEREMAIL];
    
    if ([self.delegate respondsToSelector:@selector(anonymizePreferencesForFeedbackReport:)]) {
        preferences = [self.delegate anonymizePreferencesForFeedbackReport:preferences];
    }
    
    return [NSString stringWithFormat:@"%@", preferences];
}


#pragma mark UI Actions

- (BOOL) shouldSend:(id)sender
{
    return YES;
}

- (BOOL) shouldAttemptSendForUnreachableHost:(NSString *)host
{
    return NO;
}

- (NSMutableDictionary<NSString *, NSObject<NSCopying> *> *) parametersForFeedbackReport
{
    NSMutableDictionary<NSString *, NSObject<NSCopying> *> *dict = [NSMutableDictionary dictionary];
    
    [dict FR_setValidString:self.type
                     forKey:POST_KEY_TYPE];
    
    [dict FR_setValidString:[FRApplication applicationLongVersion]
                     forKey:POST_KEY_VERSION_LONG];
    
    [dict FR_setValidString:[FRApplication applicationShortVersion]
                     forKey:POST_KEY_VERSION_SHORT];
    
    [dict FR_setValidString:[FRApplication applicationBundleVersion]
                     forKey:POST_KEY_VERSION_BUNDLE];
    
    [dict FR_setValidString:[FRApplication applicationVersion]
                     forKey:POST_KEY_VERSION];
    
    return dict;
}


#pragma mark FRUploaderDelegate

- (void) uploaderStarted:(FRUploader *)uploader
{
    // NSLog(@"Upload started");
}

- (void) uploaderFailed:(FRUploader *)uploader withError:(NSError *)error
{
    NSLog(@"Upload failed: %@", error);
}

- (void) uploaderFinished:(FRUploader *)uploader
{
    // NSLog(@"Upload finished");
}


#pragma mark other

- (void) cancelUpload
{
    [self.uploader cancel];
    self.uploader = nil;
}

- (void) send:(id)sender
{
    if (self.uploader != nil) {
        NSLog(@"Still uploading");
        return;
    }
    
    if ( [self shouldSend:sender] == NO )
        return;
    
    
    // -[NSString stringByAddingPercentEscapesUsingEncoding] is deprecated as of macOS 10.11 and iOS 9.0
    // - because each component of a URL has different encoding rules and no one function can properly encode an entire string.
    // - As a replacement, we are using URLFragmentAllowedCharacterSet which is the most conservative set: "#%<>[\]^`{|}  (see https://stackoverflow.com/a/44643893 for more)
    // - This is mostly for convenience and light backward-compatibility.
    // - The client app really should just be providing an already properly encoded string in the Info.plist or targetUrlForFeedbackReport delgate callback
    NSString *target = [[FRApplication feedbackURL] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    
    if ([[[FRFeedbackReporter sharedReporter] delegate] respondsToSelector:@selector(targetUrlForFeedbackReport)]) {
        target = [[[FRFeedbackReporter sharedReporter] delegate] targetUrlForFeedbackReport];
    }
    
    if (target == nil) {
        NSLog(@"You are missing the %@ key in your Info.plist!", PLIST_KEY_TARGETURL);
        return;
    }
    
    NSURL *url = [NSURL URLWithString:target];
    if ( !url ) {
        NSLog(@"Your target URL string is not a valid URL: %@", target);
        return;
    }
    
    NSString *host = [url host];
    const char *hostname = [host UTF8String];
    
    SCNetworkConnectionFlags reachabilityFlags = 0;
    Boolean reachabilityResult = FALSE;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, hostname);
    if (reachability) {
        reachabilityResult = SCNetworkReachabilityGetFlags(reachability, &reachabilityFlags);
        CFRelease(reachability);
    }
    
    // Prevent premature release (UTF8String returns an inner pointer).
    [host self];
    
    BOOL reachable = reachabilityResult
        &&  (reachabilityFlags & kSCNetworkFlagsReachable)
        && !(reachabilityFlags & kSCNetworkFlagsConnectionRequired)
        && !(reachabilityFlags & kSCNetworkFlagsConnectionAutomatic)
        && !(reachabilityFlags & kSCNetworkFlagsInterventionRequired);
    
    if (!reachable) {
        if ( [self shouldAttemptSendForUnreachableHost:host] == NO ) {
            return;
        }
    }
    
    self.uploader = [[FRUploader alloc] initWithTarget:target delegate:self];
    
    NSMutableDictionary *dict = [self parametersForFeedbackReport];
    
    NSLog(@"Sending feedback to %@", target);
    
    [self.uploader postAndNotify:dict];
}

- (void) show
{
    [[NSNotificationCenter defaultCenter] postNotificationName:FRFeedbackReporterWillAppearNotification
                                                        object:nil];
}

- (void) close
{
    [[NSNotificationCenter defaultCenter] postNotificationName:FRFeedbackReporterWillDisappearNotification
                                                        object:nil];
}

- (void) reset
{
}

- (BOOL) isShown
{
    return NO;
}

@end


#if !TARGET_OS_IPHONE
@implementation FRMacFeedbackController

#pragma mark Accessors

- (FRMacFeedbackWindowController *) windowController
{
    if ( !_windowController ) {
        _windowController = [[FRMacFeedbackWindowController alloc] initWithWindowNibName:@"FRMacFeedbackWindowController"];
        _windowController.feedbackController = self;
    }
    return _windowController;
}

- (void) setTitle:(NSString *)title
{
    [super setTitle:title];
    [[self.windowController window] setTitle:title];
}

- (void) setHeading:(NSString *)message
{
    [super setHeading:message];
    [self.windowController.headingField setStringValue:message];
}

- (void) setSubheading:(NSString *)informativeText
{
    [super setSubheading:informativeText];
    [self.windowController.subheadingField setStringValue:informativeText];
}

- (void) setMessage:(NSString *)message
{
    [super setMessage:message];
    [self.windowController.messageView setString:message];
}

- (void) setCrash:(NSString *)crash
{
    [super setCrash:crash];
    [self.windowController.crashesView setString:crash];
}

- (void) setException:(NSString *)exception
{
    [super setException:exception];
    [self.windowController.exceptionView setString:exception];
}

- (void) setType:(NSString *)type
{
    [super setType:type];
    self.windowController.type = type;
}


#pragma mark UI Actions

- (BOOL) shouldSend:(id)sender
{
    // Check that email is present
    if ([self.windowController.emailBox stringValue] == nil || [[self.windowController.emailBox stringValue] isEqualToString:@""] || [[self.windowController.emailBox stringValue] isEqualToString:FRLocalizedString(@"anonymous", nil)]) {
        for (NSString *aType in self.emailRequiredTypes) {
            if ([aType isEqualToString:self.type]) {
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setAlertStyle:NSWarningAlertStyle];
                [alert setMessageText:@"Email required"];
                [alert setInformativeText:@"You must enter an email address so that we can respond to you."];
                [alert addButtonWithTitle:FRLocalizedString( @"OK", @"" )];
                [alert runModal];
                return NO;
            }
        }
        for (NSString *aType in self.emailStronglySuggestedTypes) {
            if ([aType isEqualToString:self.type]) {
                NSAlert *alert = [[NSAlert alloc] init];
                [alert setAlertStyle:NSWarningAlertStyle];
                [alert setMessageText:@"Email missing"];
                [alert setInformativeText:@"Email is missing. Without an email address, we cannot respond to you. Go back and enter one?"];
                [alert addButtonWithTitle:FRLocalizedString( @"OK", @"" )];
                [alert addButtonWithTitle:FRLocalizedString( @"Continue anyway", @"" )];
                NSModalResponse buttonPressed = [alert runModal];
                if (buttonPressed == NSAlertFirstButtonReturn)
                    return NO;
                break;
            }
        }
    }
    return YES;
}

- (BOOL) shouldAttemptSendForUnreachableHost:(NSString *)host
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert setMessageText:FRLocalizedString( @"Feedback Host Not Reachable", nil )];
    [alert setInformativeText:[NSString stringWithFormat:FRLocalizedString( @"You may not be able to send feedback because %@ isn't reachable.", nil ), host]];
    [alert addButtonWithTitle:FRLocalizedString( @"Proceed Anyway", nil )];
    [alert addButtonWithTitle:FRLocalizedString( @"Cancel", nil )];
    NSModalResponse alertResult = [alert runModal];
    if (alertResult != NSAlertFirstButtonReturn) {
        return NO;
    }
    
    return YES;
}

- (NSMutableDictionary<NSString *, NSObject<NSCopying> *> *) parametersForFeedbackReport
{
    NSMutableDictionary<NSString *, NSObject<NSCopying> *> *dict = [super parametersForFeedbackReport];
    
    [dict FR_setValidString:[self.windowController.emailBox stringValue]
                     forKey:POST_KEY_EMAIL];
    
    [dict FR_setValidString:[self.windowController.messageView string]
                     forKey:POST_KEY_MESSAGE];
    
    if ([self.windowController.sendDetailsCheckbox state] == NSOnState) {
        if ([self.delegate respondsToSelector:@selector(customParametersForFeedbackReport)]) {
            [dict addEntriesFromDictionary:[self.delegate customParametersForFeedbackReport]];
        }
        
        [dict FR_setValidString:[self systemProfileAsString]
                         forKey:POST_KEY_SYSTEM];
        
        if ([self.windowController.includeConsoleCheckbox state] == NSOnState)
            [dict FR_setValidString:[self.windowController.consoleView string]
                             forKey:POST_KEY_CONSOLE];
        
        [dict FR_setValidString:[self.windowController.crashesView string]
                         forKey:POST_KEY_CRASHES];
        
        [dict FR_setValidString:[self.windowController.scriptView string]
                         forKey:POST_KEY_SHELL];
        
        [dict FR_setValidString:[self.windowController.preferencesView string]
                         forKey:POST_KEY_PREFERENCES];
        
        [dict FR_setValidString:[self.windowController.exceptionView string]
                         forKey:POST_KEY_EXCEPTION];
        
        if (self.windowController.documentList) {
            NSDictionary *documents = [self.windowController.documentList documentsToUpload];
            if (documents && [documents count] > 0)
                [dict setObject:documents forKey:POST_KEY_DOCUMENTS];
        }
    }
    
    return dict;
}

#pragma mark FRUploaderDelegate

- (void) uploaderStarted:(FRUploader *)uploader
{
    [super uploaderStarted:uploader];
    
    self.windowController.uploading = YES;
}

- (void) uploaderFailed:(FRUploader *)uploader withError:(NSError *)error
{
    [super uploaderFailed:uploader withError:error];
    
    self.uploader = nil;
    
    self.windowController.uploading = NO;
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:FRLocalizedString(@"OK", nil)];
    [alert setMessageText:FRLocalizedString(@"Sorry, failed to submit your feedback to the server.", nil)];
    [alert setInformativeText:[NSString stringWithFormat:FRLocalizedString(@"Error: %@", nil), [error localizedDescription]]];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
    
    [self close];
}

- (void) uploaderFinished:(FRUploader *)uploader
{
    [super uploaderFinished:uploader];
    
    NSString *response = [self.uploader response];
    
    self.uploader = nil;
    
    self.windowController.uploading = NO;
    
    NSArray *lines = [response componentsSeparatedByString:@"\n"];
    NSUInteger i = [lines count];
    while(i--) {
        NSString *line = [lines objectAtIndex:i];
        
        if ([line length] == 0) {
            continue;
        }
        
        if (![line hasPrefix:@"OK "]) {
            
            NSLog (@"Failed to submit to server: %@", response);
            
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:FRLocalizedString(@"OK", nil)];
            [alert setMessageText:FRLocalizedString(@"Sorry, failed to submit your feedback to the server.", nil)];
            [alert setInformativeText:[NSString stringWithFormat:FRLocalizedString(@"Error: %@", nil), line]];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert runModal];
            
            return;
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:[NSDate date]
                                             forKey:DEFAULTS_KEY_LASTSUBMISSIONDATE];
    
    [[NSUserDefaults standardUserDefaults] setObject:[self.windowController.emailBox stringValue]
                                              forKey:DEFAULTS_KEY_SENDEREMAIL];
    
    [self close];
}

- (void) show
{
    [super show];
    [self.windowController show];
}

- (void) close
{
    [super close];
    [self.windowController close];
    _windowController = nil;
}

- (void) reset
{
    BOOL emailRequired = ( [self.emailRequiredTypes containsObject:self.type] || [self.emailStronglySuggestedTypes containsObject:self.type] );
    [self.windowController resetWithEmailRequired:emailRequired];
}

- (BOOL) isShown
{
    return [[self.windowController window] isVisible];
}

@end
#endif


#if TARGET_OS_IPHONE
@implementation FRiOSFeedbackController

#pragma mark Accessors

- (FRiOSFeedbackTableViewController *) controller
{
    if ( !_controller ) {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        
        // when built with CocoaPods, the url will be non-nil and we use that to fetch the correct bundle before loading the nib
        // - (NOTE: the bundle name is specified by the key of the podspec `resource_bundles` hash)
        // when building the F53FeedbackKit_iOS.framework (which does not bundle), the url will be nil and we use the bundle fetched above.
        NSURL *url = [bundle URLForResource:@"F53FeedbackKit" withExtension:@"bundle"];
        if ( url ) {
            bundle = [NSBundle bundleWithURL:url];
        }
        
        _controller = [[FRiOSFeedbackTableViewController alloc] initWithNibName:@"FRiOSFeedbackTableViewController" bundle:bundle];
        _controller.feedbackController = self;
    }
    return _controller;
}

- (void) setTitle:(NSString *)title
{
    [super setTitle:title];
    self.controller.titleText = title;
}

- (void) setHeading:(NSString *)message
{
    [super setHeading:message];
    self.controller.headingText = message;
}

- (void) setSubheading:(NSString *)informativeText
{
    [super setSubheading:informativeText];
    self.controller.subheadingText = informativeText;
}

- (void) setMessage:(NSString *)message
{
    [super setMessage:message];
    self.controller.messageViewText = message;
}

- (void) setCrash:(NSString *)crash
{
    [super setCrash:crash];
    self.controller.crashesViewText = crash;
}

- (void) setException:(NSString *)exception
{
    [super setException:exception];
    self.controller.exceptionViewText = exception;
}

- (void) setType:(NSString *)type
{
    [super setType:type];
    self.controller.type = type;
}


#pragma mark UI Actions

- (BOOL) shouldSend:(id)sender
{
    // Check that email is present
    if (self.controller.emailBoxText == nil || [self.controller.emailBoxText isEqualToString:@""] || [self.controller.emailBoxText isEqualToString:FRLocalizedString(@"anonymous", nil)]) {
        for (NSString *aType in self.emailRequiredTypes) {
            if ([aType isEqualToString:self.type]) {
                
                NSString *title = @"Email required";
                NSString *message = @"You must enter an email address so that we can respond to you.";
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:FRLocalizedString( @"OK", @"" ) style:UIAlertActionStyleCancel handler:nil]];
                
                [self.controller.navigationController presentViewController:alert animated:YES completion:nil];
                
                return NO;
            }
        }
        for (NSString *aType in self.emailStronglySuggestedTypes) {
            if ([aType isEqualToString:self.type]) {
                
                // UIAlertController actions below can set this flag and then resubmit send:
                // - only reset sets the flag back to NO to preserve this response, in case we are passing by here because of a shouldAttemptSendForUnreachableHost: alert action calling send: a second time
                if ( self.allowSendWithoutEmailAddress ) {
                    return YES;
                }
                
                NSString *title = @"Email missing";
                NSString *message = @"Email is missing. Without an email address, we cannot respond to you. Go back and enter one?";
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Go back" style:UIAlertActionStyleCancel handler:nil]];
                
                __weak typeof(self) weakSelf = self;
                [alert addAction:[UIAlertAction actionWithTitle:@"Send anyway" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if ( !strongSelf )
                        return;
                    
                    strongSelf.allowSendWithoutEmailAddress = YES;
                    [strongSelf send:strongSelf];
                    
                }]];
                
                [self.controller.navigationController presentViewController:alert animated:YES completion:nil];
                
                return NO;
            }
        }
    }
    return YES;
}

- (BOOL) shouldAttemptSendForUnreachableHost:(NSString *)host
{
    // UIAlertController action below sets this flag and then resubmits send:
    if ( self.allowAttemptSendForUnreachableHost ) {
        return YES;
    }
    
    NSString *title = FRLocalizedString(@"Feedback Host Not Reachable", nil);
    NSString *message = [NSString stringWithFormat:FRLocalizedString(@"You may not be able to send feedback because %@ isn't reachable.", nil), host];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:FRLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:FRLocalizedString(@"Proceed Anyway", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ( !strongSelf )
            return;
        
        strongSelf.allowAttemptSendForUnreachableHost = YES;
        [strongSelf send:strongSelf];
        
    }]];
    
    [self.controller.navigationController presentViewController:alert animated:YES completion:nil];
    
    return NO;
}

- (NSMutableDictionary<NSString *, NSObject<NSCopying> *> *) parametersForFeedbackReport
{
    NSMutableDictionary<NSString *, NSObject<NSCopying> *> *dict = [super parametersForFeedbackReport];
    
    [dict FR_setValidString:self.controller.emailBoxText
                     forKey:POST_KEY_EMAIL];
    
    [dict FR_setValidString:self.controller.messageViewText
                     forKey:POST_KEY_MESSAGE];
    
    if ( self.controller.sendDetails ) {
        if ([self.delegate respondsToSelector:@selector(customParametersForFeedbackReport)]) {
            [dict addEntriesFromDictionary:[self.delegate customParametersForFeedbackReport]];
        }
        
        [dict FR_setValidString:[self systemProfileAsString]
                         forKey:POST_KEY_SYSTEM];
        
        if ( self.controller.includeConsole )
            [dict FR_setValidString:self.controller.consoleViewText
                             forKey:POST_KEY_CONSOLE];
        
        [dict FR_setValidString:self.controller.crashesViewText
                         forKey:POST_KEY_CRASHES];
        
        [dict FR_setValidString:self.controller.scriptViewText
                         forKey:POST_KEY_SHELL];
        
        [dict FR_setValidString:self.controller.preferencesViewText
                         forKey:POST_KEY_PREFERENCES];
        
        [dict FR_setValidString:self.controller.exceptionViewText
                         forKey:POST_KEY_EXCEPTION];
        
//        if ( self.controller.documentList ) {
//            NSDictionary *documents = [self.controller.documentList documentsToUpload];
//            if (documents && [documents count] > 0)
//                [dict setObject:documents forKey:POST_KEY_DOCUMENTS];
//        }
    }
    
    return dict;
}

#pragma mark FRUploaderDelegate

- (void) uploaderStarted:(FRUploader *)uploader
{
    [super uploaderStarted:uploader];
    
    self.controller.uploading = YES;
}

- (void) uploaderFailed:(FRUploader *)uploader withError:(NSError *)error
{
    [super uploaderFailed:uploader withError:error];
    
    self.uploader = nil;
    
    self.controller.uploading = NO;
    
    NSString *title = FRLocalizedString(@"Sorry, failed to submit your feedback to the server.", nil);
    NSString *message = [NSString stringWithFormat:FRLocalizedString(@"Error: %@", nil), [error localizedDescription]];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:FRLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]]; // rather than call [self close] and disscard the view controller -- and all of the user's typing, just dismiss and give the user a chance to attempt a recovery. They can press cancel if they want to bail.
    
    [self.controller.navigationController presentViewController:alert animated:YES completion:nil];
    
}

- (void) uploaderFinished:(FRUploader *)uploader
{
    [super uploaderFinished:uploader];
    
    NSString *response = [self.uploader response];
    
    self.uploader = nil;
    
    self.controller.uploading = NO;
    
    NSArray *lines = [response componentsSeparatedByString:@"\n"];
    NSUInteger i = [lines count];
    while(i--) {
        NSString *line = [lines objectAtIndex:i];
        
        if ([line length] == 0) {
            continue;
        }
        
        if (![line hasPrefix:@"OK "]) {
            
            NSLog (@"Failed to submit to server: %@", response);
            
            NSString *title = FRLocalizedString(@"Sorry, failed to submit your feedback to the server.", nil);
            NSString *message = [NSString stringWithFormat:FRLocalizedString(@"Error: %@", nil), line];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:FRLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:nil]];
            
            [self.controller.navigationController presentViewController:alert animated:YES completion:nil];
            
            return;
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:[NSDate date]
                                             forKey:DEFAULTS_KEY_LASTSUBMISSIONDATE];
    
    [[NSUserDefaults standardUserDefaults] setObject:self.controller.emailBoxText
                                              forKey:DEFAULTS_KEY_SENDEREMAIL];
    
    [self close];
}

- (void) show
{
    [super show];
    [self.controller show];
}

- (void) close
{
    [super close];
    
    __weak typeof(self) weakSelf = self;
    [self.controller dismissViewControllerAnimated:YES completion:^{
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if ( !strongSelf )
            return;
        
        strongSelf->_controller = nil;
        
    }];
}

- (void) reset
{
    self.allowSendWithoutEmailAddress = NO;
    self.allowAttemptSendForUnreachableHost = NO;
    
    BOOL emailRequired = ( [self.emailRequiredTypes containsObject:self.type] || [self.emailStronglySuggestedTypes containsObject:self.type] );
    [self.controller resetWithEmailRequired:emailRequired];
}

@end
#endif

NS_ASSUME_NONNULL_END
