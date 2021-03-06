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

#import <Foundation/Foundation.h>

#import "FRFeedbackReporter.h"
#import "FRUploader.h"


NS_ASSUME_NONNULL_BEGIN

#define FR_FEEDBACK  @"feedback"
#define FR_EXCEPTION @"exception"
#define FR_CRASH     @"crash"
#define FR_SUPPORT   @"support"

static NSString *FRFeedbackReporterWillAppearNotification = @"FRFeedbackReporterWillAppearNotification";
static NSString *FRFeedbackReporterWillDisappearNotification = @"FRFeedbackReporterWillDisappearNotification";


@interface FRFeedbackController : NSObject <FRUploaderDelegate>

@property (nonatomic, weak)     id<FRFeedbackReporterDelegate> delegate;
@property (nonatomic, strong)   NSString *type;

#pragma mark Accessors

- (NSString *) consoleLog;
- (NSArray<NSDictionary *> *) systemProfile;
- (NSString *) systemProfileAsString;
- (NSString *) preferences;

- (void) setTitle:(NSString *)title;
- (void) setHeading:(NSString *)message;
- (void) setSubheading:(NSString *)informativeText;
- (void) setMessage:(NSString *)message;
- (void) setCrash:(NSString *)crash;
- (void) setException:(NSString *)exception;

#pragma mark Other

- (void) cancelUpload;
- (void) send:(id)sender;

- (void) show;
- (void) close;

- (void) reset;
- (BOOL) isShown;

@end

NS_ASSUME_NONNULL_END
