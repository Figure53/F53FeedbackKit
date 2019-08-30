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


#import <XCTest/XCTest.h>
#import "FRCommand.h"

@interface CommandTestCase : XCTestCase

@end

@implementation CommandTestCase

- (void) testSimple
{

    NSLog(@"HELLO");
    FRCommand *cmd = [[FRCommand alloc] initWithPath:@"/bin/ls"];
    
    NSMutableString *err = [[NSMutableString alloc] init];
    NSMutableString *out = [[NSMutableString alloc] init];
    
    [cmd setOutput:out];
    [cmd setError:err];
    
    int result = [cmd execute];

    XCTAssertTrue(result == 0, @"Return code was %d", result);    
    XCTAssertTrue([out length] > 0, @"Found no output on stdout");
    XCTAssertTrue([err length] == 0, @"Found output on stderr");

    err = nil;
    out = nil;
    
    cmd = nil;
}

@end
