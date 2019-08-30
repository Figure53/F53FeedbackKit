/*
 * Copyright 2008-2014, Torsten Curdt
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


#import "FRSystemProfile.h"
#import <sys/sysctl.h>
#import <mach/machine.h>


NS_ASSUME_NONNULL_BEGIN

@implementation FRSystemProfile

+ (NSArray<NSDictionary *> *) discover
{
    NSMutableArray<NSDictionary *> *discoveryArray = [[NSMutableArray alloc] init];
    NSArray *discoveryKeys = [NSArray arrayWithObjects:@"key", @"visibleKey", @"value", @"visibleValue", nil];

#if TARGET_OS_IPHONE
    NSString *vendorIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
        @"UUID", @"Vendor Identifier", vendorIdentifier, vendorIdentifier, nil]
        forKeys:discoveryKeys]];
#endif
    
    NSString *osversion = [NSString stringWithFormat:@"%@", [self osversion]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
        @"OS_VERSION", @"OS Version", osversion, osversion, nil]
        forKeys:discoveryKeys]];

    NSString *machinemodel = [NSString stringWithFormat:@"%@", [self machinemodel]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
        @"MACHINE_MODEL", @"Machine Model", machinemodel, machinemodel, nil]
        forKeys:discoveryKeys]];

    NSString *ramsize = [NSString stringWithFormat:@"%lld", [self ramsize]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
        @"RAM_SIZE", @"Memory in (MB)", ramsize, ramsize, nil]
        forKeys:discoveryKeys]];

    NSString *cputype = [NSString stringWithFormat:@"%@", [self cputype]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
        @"CPU_TYPE", @"CPU Type", cputype, cputype, nil]
        forKeys:discoveryKeys]];

    NSString *cpuspeed = [NSString stringWithFormat:@"%lld", [self cpuspeed]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
        @"CPU_SPEED", @"CPU Speed (MHz)", cpuspeed, cpuspeed, nil]
        forKeys:discoveryKeys]];

    NSString *cpucount = [NSString stringWithFormat:@"%d", [self cpucount]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
        @"CPU_COUNT", @"Number of CPUs", cpucount, cpucount, nil]
        forKeys:discoveryKeys]];

    NSString *is64bit = [NSString stringWithFormat:@"%@", ([self is64bit])?@"YES":@"NO"];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
        @"CPU_64BIT", @"CPU is 64-Bit", is64bit, is64bit, nil]
        forKeys:discoveryKeys]];

    NSString *language = [NSString stringWithFormat:@"%@", [self language]];
    [discoveryArray addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
        @"LANGUAGE", @"Preferred Language", language, language, nil]
        forKeys:discoveryKeys]];

    return discoveryArray;
}

+ (BOOL) is64bit
{
    int error = 0;
    int value = 0;
    size_t length = sizeof(value);

    error = sysctlbyname("hw.cpu64bit_capable", &value, &length, NULL, 0);
    
    if(error != 0) {
        error = sysctlbyname("hw.optional.x86_64", &value, &length, NULL, 0); //x86 specific
    }
    
    if(error != 0) {
        error = sysctlbyname("hw.optional.64bitops", &value, &length, NULL, 0); //PPC specific
    }
    
    BOOL is64bit = NO;
    
    if (error == 0) {
        is64bit = value == 1;
    }
    
    return is64bit;
}

+ (nullable NSString *) cputype
{
    int error = 0;
    
    int cputype = -1;
    size_t length = sizeof(cputype);
    error = sysctlbyname("hw.cputype", &cputype, &length, NULL, 0);
    
    if (error != 0) {
        NSLog(@"Failed to obtain CPU type");
        return nil;
    }
    
    // Intel
    if (cputype == CPU_TYPE_X86) {
        char stringValue[256] = {0};
        size_t stringLength = sizeof(stringValue);
        error = sysctlbyname("machdep.cpu.brand_string", &stringValue, &stringLength, NULL, 0);
        if ((error == 0) && (stringLength > 0)) {
            NSString *brandString = [NSString stringWithUTF8String:stringValue];
            if (brandString)
                return brandString;
        }
    }
    else if (cputype == CPU_TYPE_ARM) {
        
        cpu_subtype_t cpusubtype;
        length = sizeof(cpusubtype);
        sysctlbyname("hw.cpusubtype", &cpusubtype, &length, NULL, 0);
        
        switch( cpusubtype )
        {
            case CPU_SUBTYPE_ARM_V7:
                return @"ARMV7";
                
            case CPU_SUBTYPE_ARM_V7S:
                return @"ARMV7S";
                
            default:
                return @"ARM";
        }
    }
    else if (cputype == CPU_TYPE_ARM64) {
        
        cpu_subtype_t cpusubtype;
        length = sizeof(cpusubtype);
        sysctlbyname("hw.cpusubtype", &cpusubtype, &length, NULL, 0);
        
        switch( cpusubtype )
        {
            case CPU_SUBTYPE_ARM64_V8:
                return @"ARM64_V8";
                
            default:
                return @"ARM64";
        }
    }
    
    
    int cpufamily = -1;
    length = sizeof(cpufamily);
    error = sysctlbyname("hw.cpufamily", &cpufamily, &length, NULL, 0);

    if (error == 0) {
        switch (cpufamily) {
            case CPUFAMILY_POWERPC_G3:
                return @"PowerPC G3";
            case CPUFAMILY_POWERPC_G4:
                return @"PowerPC G4";
            case CPUFAMILY_POWERPC_G5:
                return @"PowerPC G5";
#ifdef CPUFAMILY_INTEL_YONAH
            case CPUFAMILY_INTEL_YONAH:
                return @"Intel Core Duo";
#endif
#ifdef CPUFAMILY_INTEL_MEROM
            case CPUFAMILY_INTEL_MEROM:
                return @"Intel Core 2 Duo";
#endif
            case CPUFAMILY_INTEL_PENRYN:
                return @"Intel Core 2 Duo (Penryn)";
            case CPUFAMILY_INTEL_NEHALEM:
                return @"Intel (Nehalem)";
#ifdef CPUFAMILY_INTEL_WESTMERE
            case CPUFAMILY_INTEL_WESTMERE:
                return @"Intel (Westmere)";
#endif
#ifdef CPUFAMILY_INTEL_SANDYBRIDGE
            case CPUFAMILY_INTEL_SANDYBRIDGE:
                return @"Intel Core i5/i7 (Sandy Bridge)";
#endif
#ifdef CPUFAMILY_INTEL_IVYBRIDGE
            case CPUFAMILY_INTEL_IVYBRIDGE:
                return @"Intel (Ivy Bridge)";
#endif
#ifdef CPUFAMILY_INTEL_HASWELL
            case CPUFAMILY_INTEL_HASWELL:
                return @"Intel Core i5/i7 (Haswell)";
#endif
#ifdef CPUFAMILY_INTEL_BROADWELL
            case CPUFAMILY_INTEL_BROADWELL:
                return @"Intel Core M/i5/i7 (Haswell)";
#endif
#ifdef CPUFAMILY_INTEL_SKYLAKE
            case CPUFAMILY_INTEL_SKYLAKE:
                return @"Intel Core M/i5/i7 (Skylake)";
#endif
                
        }
        return nil;
    }


    int cpusubtype = -1;
    length = sizeof(cpusubtype);
    error = sysctlbyname("hw.cpusubtype", &cpusubtype, &length, NULL, 0);

    if (error != 0) {
        NSLog(@"Failed to obtain CPU subtype");
        return nil;
    }

    switch (cputype) {
        case CPU_TYPE_X86:
            return @"Intel";
        case CPU_TYPE_POWERPC:
            switch (cpusubtype) {
                case CPU_SUBTYPE_POWERPC_750:
                    return @"PowerPC G3";
                case CPU_SUBTYPE_POWERPC_7400:
                case CPU_SUBTYPE_POWERPC_7450:
                    return @"PowerPC G4";
                case CPU_SUBTYPE_POWERPC_970:
                    return @"PowerPC G5";
            }
            break;
    }

    NSLog(@"Unknown CPU type %d, CPU subtype %d", cputype, cpusubtype);

    return nil;
}


+ (NSString *) osversion
{
    NSProcessInfo *info = [NSProcessInfo processInfo];
    NSString *version = [info operatingSystemVersionString];
    
    if ([version hasPrefix:@"Version "]) {
        version = [version substringFromIndex:8];
    }

    return version;
}

+ (nullable NSString *) architecture
{
    int error = 0;
    int value = 0;
    size_t length = sizeof(value);
    error = sysctlbyname("hw.cputype", &value, &length, NULL, 0);
    
    if (error != 0) {
        NSLog(@"Failed to obtain CPU type");
        return nil;
    }
    
    switch (value) {
        case CPU_TYPE_X86:
            return @"Intel";
        case CPU_TYPE_POWERPC:
            return @"PPC";
    }

    NSLog(@"Unknown CPU %d", value);

    return nil;
}

+ (int) cpucount
{
    int error = 0;
    int value = 0;
    size_t length = sizeof(value);
    error = sysctlbyname("hw.ncpu", &value, &length, NULL, 0);
    
    if (error != 0) {
        NSLog(@"Failed to obtain CPU count");
        return 1;
    }
    
    return value;
}

+ (nullable NSString *) machinemodel
{
    const char *name = "hw.model";
#if TARGET_OS_IPHONE
    // .model on iOS returns internal model name (e.g. "N51AP") when we'd prefer to see the model identifier here ("iPhone6,1")
    name = "hw.machine";
#endif
    
    int error = 0;
    size_t length = 0;
    error = sysctlbyname(name, NULL, &length, NULL, 0);
    
    if (error != 0) {
        NSLog(@"Failed to obtain CPU model");
        return nil;
    }

    char *p = malloc(sizeof(char) * length);
    if (p) {
		error = sysctlbyname(name, p, &length, NULL, 0);
    }
	
    if (error != 0) {
        NSLog(@"Failed to obtain machine model");
        free(p);
        return nil;
    }

    NSString *machinemodel = [NSString stringWithFormat:@"%s", p];
    
    free(p);

    return machinemodel;
}

+ (nullable NSString *) language
{
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSArray *languages = [defs objectForKey:@"AppleLanguages"];

    if ([languages count] == 0) {
        NSLog(@"Failed to obtain preferred language");
        return nil;
    }
    
    return [languages objectAtIndex:0];
}

+ (long long) cpuspeed
{
    long long result = 0;

	int error = 0;

    int64_t hertz = 0;
	size_t size = sizeof(hertz);
	int mib[2] = {CTL_HW, HW_CPU_FREQ};
	
	error = sysctl(mib, 2, &hertz, &size, NULL, 0);
	
    if (error) {
        NSLog(@"Failed to obtain CPU speed");
        return -1;
    }
	
	result = (long long)(hertz/1000000); // Convert to MHz
    
    return result;
}

+ (long long) ramsize
{
    long long result = 0;

	int error = 0;
    int64_t value = 0;
    size_t length = sizeof(value);
	
    error = sysctlbyname("hw.memsize", &value, &length, NULL, 0);
	if (error) {
        NSLog(@"Failed to obtain RAM size");
        return -1;
	}
	const int64_t kBytesPerMebibyte = 1024*1024;
	result = (long long)(value/kBytesPerMebibyte);
    
    return result;
}


@end

NS_ASSUME_NONNULL_END
