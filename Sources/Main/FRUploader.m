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


#import "FRUploader.h"

// Uncomment the below line if you want to send form data instead of JSON
//#define FR_UPLOAD_FORM_DATA

// Comment out the below line if you want JSON data to not be a parameter
#define FR_JSON_SENT_AS_PARAM


NS_ASSUME_NONNULL_BEGIN

@implementation FRUploader

- (instancetype) initWithTarget:(NSString *)target delegate:(id<FRUploaderDelegate>)delegate
{
    self = [super init];
    if (self != nil) {
        _target = target;
        _delegate = delegate;
        _responseData = [[NSMutableData alloc] init];
    }
    
    return self;
}


- (NSData *) generateFormData:(NSDictionary *)dict forBoundary:(NSString *)formBoundary
{
    NSString *boundary = formBoundary;
    NSArray *keys = [dict allKeys];
    NSMutableData *result = [[NSMutableData alloc] initWithCapacity:100];
    
    for (NSUInteger i = 0; i < [keys count]; i++) {
        id value = [dict valueForKey:[keys objectAtIndex:i]];
        
        [result appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

        if ([value class] != [NSURL class]) {
            [result appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", [keys objectAtIndex:i]] dataUsingEncoding:NSUTF8StringEncoding]];
            [result appendData:[[NSString stringWithFormat:@"%@",value] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        else if ([value class] == [NSURL class] && [(NSURL *)value isFileURL]) {
            NSString *disposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", [keys objectAtIndex:i], [[(NSURL *)value path] lastPathComponent]];
            [result appendData:[disposition dataUsingEncoding:NSUTF8StringEncoding]];
            
            [result appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [result appendData:[NSData dataWithContentsOfFile:[(NSURL *)value path]]];
        }

        [result appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }

    [result appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return result;
}

- (NSData *) generateJSONData:(NSDictionary *)dict forBoundary:(NSString *)formBoundary
{
    NSError *err;
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithCapacity:[dict count]];
    NSArray *keys = [dict allKeys];
    NSMutableData *result = [[NSMutableData alloc] initWithCapacity:100];
    
    for (NSUInteger i = 0; i < [keys count]; i++) {
        id value = [dict valueForKey:[keys objectAtIndex:i]];
        
        // TODO this does not handle other classes like NSURL, though I cannot find anywhere in the code that puts them in the dict
        if ([value isKindOfClass:[NSString class]]) {
            [jsonDict setObject:value forKey:[keys objectAtIndex:i]];
        }
        else if ([value isKindOfClass:[NSDictionary class]]) {
            // Assume sub-dictionaries are already string pairs
            [jsonDict setObject:value forKey:[keys objectAtIndex:i]];
        }
        else {
            NSLog(@"Error inserting item into JSON as it is not a string: %@", value);
        }
    }
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:&err];
    if (!jsonData) {
        NSLog(@"Error creating JSON data: %@", err);
        result = nil;
    }
    else {
#ifdef FR_JSON_SENT_AS_PARAM
        NSString *param = @"payload";
        [result appendData:[[NSString stringWithFormat:@"--%@\r\n", formBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [result appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", param] dataUsingEncoding:NSUTF8StringEncoding]];
#endif
        [result appendData:jsonData];
#ifdef FR_JSON_SENT_AS_PARAM
        [result appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [result appendData:[[NSString stringWithFormat:@"--%@--\r\n", formBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
#endif
    }
    return result;
}

- (void) postAndNotify:(NSDictionary *)dict
{
    NSData *formData;

    NSString *formBoundary = [[NSProcessInfo processInfo] globallyUniqueString];
#ifdef FR_UPLOAD_FORM_DATA
    formData = [self generateFormData:dict forBoundary:formBoundary];
#else
    formData = [self generateJSONData:dict forBoundary:formBoundary];
#endif

    NSLog(@"Posting %lu bytes to %@", (unsigned long)[formData length], _target);

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_target]];
    
#if defined(FR_UPLOAD_FORM_DATA) || defined(FR_JSON_SENT_AS_PARAM)
    NSString *boundaryString = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", formBoundary];
    [request addValue:boundaryString forHTTPHeaderField:@"Content-Type"];
#endif
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:formData];
    
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];

    if (_connection != nil) {
        if ([_delegate respondsToSelector:@selector(uploaderStarted:)]) {
            [_delegate performSelector:@selector(uploaderStarted:) withObject:self];
        }
        
    } else {
        if ([_delegate respondsToSelector:@selector(uploaderFailed:withError:)]) {

            [_delegate performSelector:@selector(uploaderFailed:withError:) withObject:self
                withObject:[NSError errorWithDomain:@"Failed to establish connection" code:0 userInfo:nil]];

        }
    }
}

- (void) cancel
{
    [_connection cancel];
    _connection = nil;
}

- (NSString *) response
{
    return [[NSString alloc] initWithData:_responseData
                                 encoding:NSUTF8StringEncoding];
}



#pragma mark NSURLConnectionDataDelegate methods

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"Connection received data");

    [_responseData appendData:data];
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Connection failed");
    
    if ([_delegate respondsToSelector:@selector(uploaderFailed:withError:)]) {
        
        [_delegate performSelector:@selector(uploaderFailed:withError:) withObject:self withObject:error];
    }

}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    // NSLog(@"Connection finished");
    
    if ([_delegate respondsToSelector:@selector(uploaderFinished:)]) {
        [_delegate performSelector:@selector(uploaderFinished:) withObject:self];
    }
    
}

@end

NS_ASSUME_NONNULL_END
