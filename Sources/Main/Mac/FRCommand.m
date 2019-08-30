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

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "FRCommand.h"


NS_ASSUME_NONNULL_BEGIN

@implementation FRCommand

- (instancetype) initWithPath:(NSString *)path
{
    self = [super init];
    if (self != nil) {
        _task = [[NSTask alloc] init];
        _args = [NSArray array];
        _path = path;
        _error = nil;
        _output = nil;
        _terminated = NO;
    }
    
    return self;
}




- (void) setArgs:(NSArray *)args
{
    _args = args;
}

- (void) setError:(nullable NSMutableString *)error
{
    _error = error;
}

- (void) setOutput:(nullable NSMutableString *)output
{
    _output = output;
}


- (void) appendDataFrom:(NSFileHandle *)fileHandle to:(NSMutableString *)string
{
    NSData *data = [fileHandle availableData];

    if ([data length]) {

        // Initially try to read the file in using UTF8
        NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

        // If that fails, attempt plain ASCII
        if (!s) {
            s = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        }

        if (s) {
            [string appendString:s];
            //NSLog(@"| %@", s);

        }
    }

    [fileHandle waitForDataInBackgroundAndNotify];
}

- (void) outData:(NSNotification *)notification
{
    NSFileHandle *fileHandle = (NSFileHandle *)[notification object];

    [self appendDataFrom:fileHandle to:_output];

    [fileHandle waitForDataInBackgroundAndNotify];
}

- (void) errData:(NSNotification *)notification
{
    NSFileHandle *fileHandle = (NSFileHandle *)[notification object];

    [self appendDataFrom:fileHandle to:_output];

    [fileHandle waitForDataInBackgroundAndNotify];
}


- (void) terminated:(NSNotification *)notification
{
    // NSLog(@"Task terminated");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    _terminated = YES;
}

- (int) execute
{
    if (![[NSFileManager defaultManager] isExecutableFileAtPath:_path]) {
        // executable not found
        return -1;
    }

    [_task setLaunchPath:_path];
    [_task setArguments:_args];

    NSPipe *outPipe = [NSPipe pipe];
    NSPipe *errPipe = [NSPipe pipe];

    [_task setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
    [_task setStandardOutput:outPipe];
    [_task setStandardError:errPipe];

    NSFileHandle *outFile = [outPipe fileHandleForReading];
    NSFileHandle *errFile = [errPipe fileHandleForReading]; 

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(outData:)
                                                 name:NSFileHandleDataAvailableNotification
                                               object:outFile];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(errData:)
                                                 name:NSFileHandleDataAvailableNotification
                                               object:errFile];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(terminated:)
                                                 name:NSTaskDidTerminateNotification
                                               object:_task];

    [outFile waitForDataInBackgroundAndNotify];
    [errFile waitForDataInBackgroundAndNotify];

    [_task launch];

    while(!_terminated) {
        @autoreleasepool {
            if (![[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:100000]]) {
                break;
            }
        }
    }

    [self appendDataFrom:outFile to:_output];
    [self appendDataFrom:errFile to:_error];

    int result = [_task terminationStatus];

    return result;
}

@end

NS_ASSUME_NONNULL_END
