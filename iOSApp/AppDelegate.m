//
//  AppDelegate.m
//  iOSApp
//
//  Created by Brent Lord on 9/21/15.
//  Copyright © 2015 Figure 53, LLC. All rights reserved.
//

#import "AppDelegate.h"
#import "FRConstants.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)
launchOptions
{
    
#if TARGET_OS_SIMULATOR
    NSLog(@"Build root: file://%@", NSHomeDirectory());
#endif
    
    return YES;
}

@end
