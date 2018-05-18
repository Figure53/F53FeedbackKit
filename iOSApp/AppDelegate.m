//
//  AppDelegate.m
//  iOSApp
//
//  Created by Brent Lord on 9/21/15.
//  Copyright © 2015-2018 Figure 53, LLC. All rights reserved.
//

#import "AppDelegate.h"


NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate ()
@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions
{
#if TARGET_OS_SIMULATOR
    NSLog(@"Build root: file://%@", NSHomeDirectory());
#endif
    
    return YES;
}

@end

NS_ASSUME_NONNULL_END
