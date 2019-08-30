//
//  AppDelegate.m
//  iOSApp
//
//  Created by Brent Lord on 9/21/15.
//  Copyright © 2015-2019 Figure 53, LLC. All rights reserved.
//

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


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
