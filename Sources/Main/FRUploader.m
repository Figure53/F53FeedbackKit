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

#import "FRUploader.h"

// Uncomment the below line if you want to send form data instead of JSON
//#define FR_UPLOAD_FORM_DATA

@implementation FRUploader

- (id) initWithTarget:(NSString*)pTarget delegate:(id<FRUploaderDelegate>)pDelegate
{
    self = [super init];
    if (self != nil) {
        target = pTarget;
        delegate = pDelegate;
        responseData = [[NSMutableData alloc] init];
    }
    
    return self;
}

- (void) dealloc
{
    [responseData release];
    
    [super dealloc];
}

- (NSData *) generateFormData: (NSDictionary *)dict forBoundary:(NSString*)formBoundary
{
    NSString *boundary = formBoundary;
    NSArray *keys = [dict allKeys];
    NSMutableData *result = [[NSMutableData alloc] initWithCapacity:100];
    
    for (NSUInteger i = 0; i < [keys count]; i++) {
        id value = [dict valueForKey: [keys objectAtIndex: i]];
        
        [result appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

        if ([value class] != [NSURL class]) {
            [result appendData:[[NSString stringWithFormat: @"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", [keys objectAtIndex:i]] dataUsingEncoding:NSUTF8StringEncoding]];
            [result appendData:[[NSString stringWithFormat:@"%@",value] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        else if ([value class] == [NSURL class] && [value isFileURL]) {
            NSString *disposition = [NSString stringWithFormat: @"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", [keys objectAtIndex:i], [[value path] lastPathComponent]];
            [result appendData: [disposition dataUsingEncoding:NSUTF8StringEncoding]];
            
            [result appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [result appendData:[NSData dataWithContentsOfFile:[value path]]];
        }

        [result appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }

    [result appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return [result autorelease];
}

- (NSData *)generateJSONData:(NSDictionary *)dict
{
    NSError *err;
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionaryWithCapacity:[dict count]];
    NSArray *keys = [dict allKeys];
    
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
    if (!jsonData)
        NSLog(@"Error creating JSON data: %@", err);
    return jsonData;
}

- (void) postAndNotify:(NSDictionary*)dict
{
    NSData *formData;

#ifdef FR_UPLOAD_FORM_DATA
    NSString *formBoundary = [[NSProcessInfo processInfo] globallyUniqueString];
    formData = [self generateFormData:dict forBoundary:formBoundary];
#else
    formData = [self generateJSONData:dict];
#endif

    NSLog(@"Posting %lu bytes to %@", (unsigned long)[formData length], target);

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:target]];
    
#ifdef FR_UPLOAD_FORM_DATA
    NSString *boundaryString = [NSString stringWithFormat: @"multipart/form-data; boundary=%@", formBoundary];
    [request addValue: boundaryString forHTTPHeaderField: @"Content-Type"];
#endif
    
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody:formData];

    connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];

    if (connection != nil) {
        if ([delegate respondsToSelector:@selector(uploaderStarted:)]) {
            [delegate performSelector:@selector(uploaderStarted:) withObject:self];
        }
        
    } else {
        if ([delegate respondsToSelector:@selector(uploaderFailed:withError:)]) {

            [delegate performSelector:@selector(uploaderFailed:withError:) withObject:self
                withObject:[NSError errorWithDomain:@"Failed to establish connection" code:0 userInfo:nil]];

        }
    }
}



- (void) connection: (NSURLConnection *)pConnection didReceiveData: (NSData *)data
{
    NSLog(@"Connection received data");

    [responseData appendData:data];
}

- (void) connection:(NSURLConnection *)pConnection didFailWithError:(NSError *)error
{
    NSLog(@"Connection failed");
    
    if ([delegate respondsToSelector:@selector(uploaderFailed:withError:)]) {

        [delegate performSelector:@selector(uploaderFailed:withError:) withObject:self withObject:error];
    }
        
    [connection autorelease];
}

- (void) connectionDidFinishLoading: (NSURLConnection *)pConnection
{
    // NSLog(@"Connection finished");

    if ([delegate respondsToSelector: @selector(uploaderFinished:)]) {
        [delegate performSelector:@selector(uploaderFinished:) withObject:self];
    }
    
    [connection autorelease];
}


- (void) cancel
{
    [connection cancel];
    [connection autorelease], connection = nil;
}

- (NSString*) response
{
    return [[[NSString alloc] initWithData:responseData
                                  encoding:NSUTF8StringEncoding] autorelease];
}

@end
