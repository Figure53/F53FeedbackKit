/*
 * Copyright 2008, Jens Alfke, Torsten Curdt
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

#import "NSException+Callstack.h"
#import "FRConstants.h"
#import <unistd.h>

@implementation NSException (Callstack)

- (NSArray *) my_callStackReturnAddresses
{
    // On 10.5 or later, can get the backtrace:
    if ( [self respondsToSelector:@selector(callStackReturnAddresses)] ) {
        return [self valueForKey:@"callStackReturnAddresses"];
    } else {
        return nil;
    }
}

- (NSArray *) my_callStackReturnAddressesSkipping:(NSUInteger)skip limit:(NSUInteger)limit
{
    NSArray *addresses = [self my_callStackReturnAddresses];
    if ( addresses ) {
        NSUInteger n = [addresses count];
        skip = MIN(skip,n);
        limit = MIN(limit,n-skip);
        addresses = [addresses subarrayWithRange:NSMakeRange(skip,limit)];
    }
    return addresses;
}

- (NSString *) my_callStack
{
	NSArray *symbols = [self callStackSymbols];
    return [NSString stringWithFormat:@"%@\n",symbols];
}

@end
