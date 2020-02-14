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

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "NSException+FRCallstack.h"
#import "FRConstants.h"
#import <unistd.h>
#import <mach-o/dyld_images.h>
#if TARGET_OS_OSX
#import <mach/mach_vm.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@implementation NSException (FRCallstack)

- (nullable NSArray<NSNumber *> *) FR_callStackReturnAddresses
{
    // On 10.5 or later, can get the backtrace:
    if ( [self respondsToSelector:@selector(callStackReturnAddresses)] ) {
        return [self valueForKey:@"callStackReturnAddresses"];
    } else {
        return nil;
    }
}

- (nullable NSArray<NSNumber *> *) FR_callStackReturnAddressesSkipping:(NSUInteger)skip limit:(NSUInteger)limit
{
    NSArray<NSNumber *> *addresses = [self FR_callStackReturnAddresses];
    if ( addresses ) {
        NSUInteger n = [addresses count];
        skip = MIN(skip,n);
        limit = MIN(limit,n-skip);
        addresses = [addresses subarrayWithRange:NSMakeRange(skip,limit)];
    }
    return addresses;
}

- (NSString *) FR_callStack
{
	NSArray<NSString *> *symbols = [self callStackSymbols];
    NSString *processBinaryImage = @"";
    
    // filter the list of binary images to include only the line for this app
    NSString *processName = [NSProcessInfo processInfo].processName;
    for ( NSString *aImage in self.binaryImages )
    {
        // case-insensitive "ends with"
        if ( [aImage rangeOfString:processName options:( NSCaseInsensitiveSearch | NSBackwardsSearch | NSAnchoredSearch )].location == NSNotFound )
            continue;
        
        processBinaryImage = [NSString stringWithFormat:@"Binary Image:\n%@", aImage];
        break;
    }
    
    return [NSString stringWithFormat:@"%@\n\n%@\n", symbols, processBinaryImage];
}

#pragma mark -

// adapted from https://stackoverflow.com/a/33898317, licensed under "cc by-sa 4.0"

- (NSArray<NSString *> *) binaryImages
{
    int pid = [NSProcessInfo processInfo].processIdentifier;
    
    task_t task;
    task_for_pid( mach_task_self(), pid, &task);
    
    struct task_dyld_info dyld_info;
    mach_msg_type_number_t count = TASK_DYLD_INFO_COUNT;
    if ( task_info( task, TASK_DYLD_INFO, (task_info_t)&dyld_info, &count ) == KERN_SUCCESS )
    {
        uint8_t *data;
        mach_msg_type_number_t size;
        
        size = sizeof(struct dyld_all_image_infos);
        data = readProcessMemory( pid, dyld_info.all_image_info_addr, size );
        struct dyld_all_image_infos *infos = (struct dyld_all_image_infos *)data;
        
        mach_msg_type_number_t size2 = ( sizeof(struct dyld_image_info) * infos->infoArrayCount );
        uint8_t *info_addr = readProcessMemory( pid, (mach_vm_address_t)infos->infoArray, size2 );
        struct dyld_image_info *info = (struct dyld_image_info *)info_addr;
        
        if ( infos->infoArrayCount )
        {
            NSMutableArray<NSString *> *images = [NSMutableArray arrayWithCapacity:(NSUInteger)infos->infoArrayCount];
            for ( uint32_t i = 0; i < infos->infoArrayCount; i++ )
            {
                mach_msg_type_number_t size3 = PATH_MAX;
                uint8_t *addr = readProcessMemory( pid, (mach_vm_address_t)info[i].imageFilePath, size3 );
                if ( addr )
                {
                    // space-padded address range, path to image, e.g.:
                    //      0x1081e7000 -        0x1081e7400 /Applications/App.app/Contents/MacOS/App
                    NSString *address = [NSString stringWithFormat:@"%s", addr];
                    NSString *imageStr = [NSString stringWithFormat:@"%#18llx - %#18llx %@", (mach_vm_address_t)info[i].imageLoadAddress, (mach_vm_address_t)info[i].imageLoadAddress + size3, address];
                    [images addObject:imageStr];
                }
            }
            
            [images sortUsingSelector:@selector(caseInsensitiveCompare:)];
            return [NSArray arrayWithArray:images];
        }
    }
    
    // else
    return @[];
}

unsigned char * _Nullable readProcessMemory( int pid, mach_vm_address_t addr, mach_msg_type_number_t size )
{
    task_t t;
    task_for_pid( mach_task_self(), pid, &t );
    mach_msg_type_number_t dataCnt = (mach_msg_type_number_t)size;
    vm_offset_t readMem;
    
#if TARGET_OS_IPHONE
    kern_return_t kr = vm_read( t,                  // vm_map_t target_task,
                               (vm_address_t)addr,  // vm_address_t address,
                               size,               // mach_vm_size_t size
                               &readMem,            // vm_offset_t *data,
                               &dataCnt );          // mach_msg_type_number_t *dataCnt
#else
    kern_return_t kr = mach_vm_read( t,             // vm_map_t target_task,
                                    addr,           // mach_vm_address_t address,
                                    size,          // mach_vm_size_t size
                                    &readMem,       // vm_offset_t *data,
                                    &dataCnt );     // mach_msg_type_number_t *dataCnt
#endif
    
    if ( kr )
    {
        fprintf ( stderr, "Unable to read target task's memory @%p - kr 0x%x\n" ,
                 (void *) addr, kr );
        return NULL;
    }
    
    return (unsigned char *)readMem;
}

@end

NS_ASSUME_NONNULL_END
