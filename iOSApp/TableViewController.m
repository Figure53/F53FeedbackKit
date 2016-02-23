//
//  TableViewController.m
//  iOSApp
//
//  Created by Brent Lord on 9/21/15.
//  Copyright © 2015 Figure 53, LLC. All rights reserved.
//

#import "TableViewController.h"

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

- (NSDictionary *) customParametersForFeedbackReport
{
    NSLog(@"adding custom parameters");
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
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

//- (NSString *) consoleLogForFeedbackReportSince:(NSDate *)since maxSize:(NSInteger)maxSize
//{
//    NSString *maxSizeString = @"none";
//    if ( maxSize > 0 )
//        maxSizeString = [NSString stringWithFormat:@"%ld", (long)maxSize];
//    
//    return [NSString stringWithFormat:@"my custom console log here since %@, max size: %@", since.description, maxSizeString];
//}

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
