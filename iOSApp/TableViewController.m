//
//  TableViewController.m
//  iOSApp
//
//  Created by Brent Lord on 9/21/15.
//  Copyright © 2015-2019 Figure 53, LLC. All rights reserved.
//

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "TableViewController.h"


NS_ASSUME_NONNULL_BEGIN

@interface TableViewController ()

@property (nonatomic, strong)   NSString *dummyCrashText;

@end


@implementation TableViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    
    self.dummyCrashText = @"dummy crash text";
    
    
    [[FRFeedbackReporter sharedReporter] setDelegate:self];
    
    NSLog(@"checking for crash");
    [[FRFeedbackReporter sharedReporter] reportIfCrash];
}


#pragma mark UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch ( indexPath.row ) {
        case 0:
            [self doFeedback];
            break;
            
        case 1:
            [self doException];
            break;
            
        case 2:
            [self doExceptionInThread];
            break;
            
        case 3:
            [self doCrash];
            break;
            
        case 4:
            [self doSupport];
            break;
            
        case 5:
            [self doSendCrash:self.dummyCrashText];
            break;
            
        default:
            break;
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

//- (NSString *)targetUrlForFeedbackReport
//{
//    NSString *targetUrlFormat = @"http://myserver.com/submit.php?project=%@&version=%@";
//    NSString *project = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleExecutable"];
//    NSString *version = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
//    return [NSString stringWithFormat:targetUrlFormat, project, version];
//}

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

//- (UIColor *) feedbackControllerTintColor
//{
//    return [UIColor redColor]; // debug
//}

//- (CGFloat) feedbackControllerTextScale
//{
//    return 1.5; // debug
//}

//- (UIFont *) feedbackControllerFont
//{
//    return [UIFont boldSystemFontOfSize:17.0]; // debug
//}

//- (UIFont *) feedbackControllerHeaderFont
//{
//    return [UIFont boldSystemFontOfSize:28.0]; // debug
//}

//- (UIFont *) feedbackControllerFooterFont
//{
//    return [UIFont italicSystemFontOfSize:10.0]; // debug
//}

#pragma - mark

- (void) doFeedback
{
    NSLog(@"button");
    [[FRFeedbackReporter sharedReporter] reportFeedback];
}

- (void) doException
{
    NSLog(@"exception");
    [NSException raise:@"TestException" format:@"Something went wrong"];
}

- (void) doThreadWithException
{
    @autoreleasepool {
        NSLog(@"exception in thread");
        [NSException raise:@"TestExceptionThread" format:@"Something went wrong"];
        [NSThread exit];
    }
}

- (void) doExceptionInThread
{
    [NSThread detachNewThreadSelector:@selector(doThreadWithException) toTarget:self withObject:nil];
}

- (void) doCrash
{
    NSLog(@"crash");
    char *c = 0;
    *c = 0;
}

- (void) doSupport
{
    [[FRFeedbackReporter sharedReporter] reportSupportNeed];
}

- (void) doSendCrash:(NSString *)crashText
{
    [[FRFeedbackReporter sharedReporter] reportCrash:crashText];
}

@end

NS_ASSUME_NONNULL_END
