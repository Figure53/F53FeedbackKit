//
//  AppDelegate.m
//  iOSApp
//
//  Created by Brent Lord on 9/21/15.
//  Copyright © 2015-2020 Figure 53, LLC. All rights reserved.
//

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "AppDelegate.h"


NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate ()
@end


@implementation AppDelegate

void uncaughtExceptionHandler(NSException *x)
{
    @try {
        if ( [NSThread isMainThread] == NO ) {
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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions
{
#if TARGET_OS_SIMULATOR
    NSLog(@"Build root: file://%@", NSHomeDirectory());
#endif
    
    NSSetUncaughtExceptionHandler( &uncaughtExceptionHandler );

    return YES;
}

@end

NS_ASSUME_NONNULL_END
