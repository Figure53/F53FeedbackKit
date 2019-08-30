/*
 * Copyright 2008, Torsten Curdt
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


#import "FRFeedbackReporter.h"
#import "FRFeedbackController.h"
#import "FRCrashLogFinder.h"
#import "FRSystemProfile.h"
#import "NSException+FRCallstack.h"
#import "FRUploader.h"
#import "FRApplication.h"
#import "FRConstants.h"

#import <uuid/uuid.h>


NS_ASSUME_NONNULL_BEGIN

@interface FRFeedbackReporter () {
    FRFeedbackController *_feedbackController;
}

@property (nonatomic, strong, readonly) FRFeedbackController *feedbackController;

- (BOOL) showFeedbackControllerWithType:(NSString *)type
                                  title:(nullable NSString *)title
                                heading:(NSString *)heading
                             subheading:(NSString *)subheading
                                  crash:(nullable NSString *)crash
                              exception:(nullable NSString *)exception;

@end


@implementation FRFeedbackReporter

#pragma mark Construction

__strong static FRFeedbackReporter *_sharedReporter = nil;
static dispatch_once_t once_token = 0;

+ (FRFeedbackReporter *) sharedReporter
{
    // executes a block object once and only once for the lifetime of an application
    dispatch_once( &once_token, ^{
        _sharedReporter = [[[self class] alloc] init];
    });
    
    // returns the same object each time
    return _sharedReporter;
}


#pragma mark Destruction


#pragma mark Variable Accessors

- (FRFeedbackController *) feedbackController
{
    if (_feedbackController == nil) {
        _feedbackController = [[FRFeedbackController alloc] init];
    }
    
    return _feedbackController;
}

#pragma mark Reports

- (BOOL) reportFeedback
{
    return [self showFeedbackControllerWithType:FR_FEEDBACK
                                          title:nil
                                        heading:NSLocalizedString(@"Got a problem with %@?", nil)
                                     subheading:NSLocalizedString(@"Send feedback", nil)
                                          crash:nil
                                      exception:nil];
}

- (BOOL) reportIfCrash
{
    NSDate *lastCrashCheckDate = [[NSUserDefaults standardUserDefaults] valueForKey:DEFAULTS_KEY_LASTCRASHCHECKDATE];
    
    NSArray *crashFiles = [FRCrashLogFinder findCrashLogsSince:lastCrashCheckDate];

    [[NSUserDefaults standardUserDefaults] setValue:[NSDate date]
                                             forKey:DEFAULTS_KEY_LASTCRASHCHECKDATE];
    
    if (lastCrashCheckDate && [crashFiles count] > 0) {
        // NSLog(@"Found new crash files");
        
        return [self showFeedbackControllerWithType:FR_CRASH
                                              title:nil
                                            heading:NSLocalizedString(@"%@ has recently crashed!", nil)
                                         subheading:NSLocalizedString(@"Send crash report", nil)
                                              crash:nil
                                          exception:nil];
        
    }
    
    return NO;
}

- (BOOL) reportCrash:(NSString *)crashLogText
{
    if ( crashLogText && [crashLogText isEqualToString:@""] == NO ) {
        
        return [self showFeedbackControllerWithType:FR_CRASH
                                              title:nil
                                            heading:NSLocalizedString(@"%@ has recently crashed!", nil)
                                         subheading:NSLocalizedString(@"Send crash report", nil)
                                              crash:crashLogText
                                          exception:nil];
        
    }
    
    return NO;
}

- (BOOL) reportException:(NSException *)exception
{
    NSString *callStack = [exception FR_callStack];
    NSString *exceptionText = [NSString stringWithFormat: @"%@\n\n%@\n\n%@",
                              [exception name],
                              [exception reason],
                              callStack ? callStack : @""];
    
    return [self showFeedbackControllerWithType:FR_EXCEPTION
                                          title:nil
                                        heading:NSLocalizedString(@"%@ has encountered an exception!", nil)
                                     subheading:NSLocalizedString(@"Send crash report", nil)
                                          crash:nil
                                      exception:exceptionText];
}

- (BOOL) reportSupportNeed
{
    return [self showFeedbackControllerWithType:FR_SUPPORT
                                          title:NSLocalizedString(@"Contact Support", nil)
                                        heading:NSLocalizedString(@"Need help with %@?", nil)
                                     subheading:NSLocalizedString(@"We're happy to help. Please describe your problem and send it to us along with the helpful details below.", nil)
                                          crash:nil
                                      exception:nil];
}

- (BOOL) showFeedbackControllerWithType:(NSString *)type
                                  title:(nullable NSString *)title
                                heading:(NSString *)heading
                             subheading:(NSString *)subheading
                                  crash:(nullable NSString *)crash
                              exception:(nullable NSString *)exception
{
    FRFeedbackController *controller = [self feedbackController];
    
    @synchronized (controller) {
        
        if ([controller isShown])
            return NO;
        
        NSAssert( [type isEqualToString:FR_CRASH]       ||
                 [type isEqualToString:FR_EXCEPTION]    ||
                 [type isEqualToString:FR_FEEDBACK]     ||
                 [type isEqualToString:FR_SUPPORT], @"type is missing or unsupported" );
        
        [controller setType:type];
        
        [controller reset];
        
        if ( title )
            [controller setTitle:title];
        
        if ([self.delegate respondsToSelector:@selector(customizeFeedbackHeading:forType:)]) {
            heading = [self.delegate customizeFeedbackHeading:heading forType:type];
        }
        if ( heading ) {
            NSString *applicationName = nil;
            if ([self.delegate respondsToSelector:@selector(feedbackDisplayName)]) {
                applicationName = [self.delegate feedbackDisplayName];
            }
            else {
                applicationName = [FRApplication applicationName];
            }
            
            [controller setHeading:[NSString stringWithFormat:heading, applicationName]];
        }
        
        if ([self.delegate respondsToSelector:@selector(customizeFeedbackSubheading:forType:)]) {
            subheading = [self.delegate customizeFeedbackSubheading:subheading forType:type];
        }
        if ( subheading )
            [controller setSubheading:subheading];
        
        if ( crash )
            [controller setCrash:crash];
        
        if ( exception )
            [controller setException:exception];
        
        [controller setDelegate:self.delegate];
        
        [controller show];
        
    }
    
    return YES;
}

@end

NS_ASSUME_NONNULL_END
