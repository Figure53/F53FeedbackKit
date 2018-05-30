/*
 * Copyright 2008-2012, Torsten Curdt
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

#import "AppDelegate.h"

#import "NSException+FRCallstack.h"
#import <pthread.h>

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end


@implementation AppDelegate

#pragma mark - NSApplicationDelegate

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[FRFeedbackReporter sharedReporter] setDelegate:self];
    
    NSLog(@"checking for crash");
    [[FRFeedbackReporter sharedReporter] reportIfCrash];
}


#pragma mark - NSApplication subclass overrides

- (void) reportException:(NSException *)x
{
    [super reportException:x];
    
    @try {
        if (!pthread_main_np()) {
            [[FRFeedbackReporter sharedReporter] performSelectorOnMainThread:@selector(reportException:) withObject:x waitUntilDone:NO];
            [NSThread exit];
        }
        else {
            [[FRFeedbackReporter sharedReporter] reportException:x];
        }
    }
    @catch (NSException *exception) {
        
        if ([exception respondsToSelector:@selector(callStackSymbols)]) {
            NSLog(@"Problem within FeedbackReporter %@: %@  call stack:%@", [exception name], [exception  reason],[(id)exception callStackSymbols]);
        } else {
            NSLog(@"Problem within FeedbackReporter %@: %@  call stack:%@", [exception name], [exception  reason],[exception callStackReturnAddresses]);
        }
        
    }
    @finally {
    }
}


#pragma mark - FRFeedbackReporterDelegate

- (NSDictionary<NSString *, NSObject<NSCopying> *> *) customParametersForFeedbackReport
{
    NSLog(@"adding custom parameters");
    
    NSMutableDictionary<NSString *, NSObject<NSCopying> *> *dict = [NSMutableDictionary dictionary];
    
    [dict setObject:@"tcurdt"
             forKey:@"user"];
    
    [dict setObject:@"1234-1234-1234-1234"
             forKey:@"license"];
    
    return dict;
}

- (NSString *) feedbackDisplayName
{
    return @"Test App";
}

- (NSString *) customizeConsoleLogForFeedbackReport:(NSString *)consoleLog since:(NSDate *)since maxSize:(NSInteger)maxSize
{
    NSString *maxSizeString = @"none";
    if ( maxSize > 0 )
        maxSizeString = [NSString stringWithFormat:@"%ld", (long)maxSize];
    
    return [NSString stringWithFormat:@"%@\n\nadding my custom console log here since %@, max size: %@", consoleLog, since.description, maxSizeString];
}

- (NSString *) customizeFeedbackHeading:(NSString *)heading forType:(NSString *)type
{
//    if ( [type isEqualToString:@"feedback"] )             // FR_FEEDBACK
//        heading = @"Custom heading text for type Feedback";
//    
//    else if ( [type isEqualToString:@"exception"] )       // FR_EXCEPTION
//        heading = @"Custom heading text for type Exception";
//    
//    else if ( [type isEqualToString:@"crash"] )           // FR_CRASH
//        heading = @"Custom heading text for type Crash";
//    
//    else if ( [type isEqualToString:@"support"] )         // FR_SUPPORT
//        heading = @"Custom heading text for type Support";
    
    return heading;
}

- (NSString *) customizeFeedbackSubheading:(NSString *)subheading forType:(NSString *)type
{
//    if ( [type isEqualToString:@"feedback"] )             // FR_FEEDBACK
//        subheading = @"Custom subheading text for type Feedback";
//
//    else if ( [type isEqualToString:@"exception"] )       // FR_EXCEPTION
//        subheading = @"Custom subheading text for type Exception";
//
//    else if ( [type isEqualToString:@"crash"] )           // FR_CRASH
//        subheading = @"Custom subheading text for type Crash";
//
//    else if ( [type isEqualToString:@"support"] )         // FR_SUPPORT
//        subheading = @"Custom subheading text for type Support";
    
    return subheading;
}

/*
- (NSString *)targetUrlForFeedbackReport
{
    NSString *targetUrlFormat = @"http://myserver.com/submit.php?project=%@&version=%@";
    NSString *project = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleExecutable"];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
    return [NSString stringWithFormat:targetUrlFormat, project, version];
}*/


#pragma mark - UI

- (IBAction) buttonFeedback:(id)sender
{
    NSLog(@"button");
    [[FRFeedbackReporter sharedReporter] reportFeedback];
}

- (IBAction) buttonException:(id)sender
{
    NSLog(@"exception");
    [NSException raise:@"TestException" format:@"Something went wrong"];
}

- (IBAction) buttonExceptionInThread:(id)sender
{
    [NSThread detachNewThreadSelector:@selector(threadWithException) toTarget:self withObject:nil];
}

- (IBAction) buttonCrash:(id)sender
{
    NSLog(@"crash");
    char *c = 0;
    *c = 0;
}

- (IBAction) buttonSupport:(id)sender
{
    [[FRFeedbackReporter sharedReporter] reportSupportNeed];
}

- (IBAction) buttonSendCrash:(id)sender
{
    [[FRFeedbackReporter sharedReporter] reportCrash:@"dummy crash report text here"];
}


#pragma mark - helpers

- (void) threadWithException
{
    @autoreleasepool {
        NSLog(@"exception in thread");
        [NSException raise:@"TestExceptionThread" format:@"Something went wrong"];
        [NSThread exit];
    }
}

@end
