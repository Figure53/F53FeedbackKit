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

@interface FRUploader ()

@property (nonatomic, strong)           NSString *target;
@property (nonatomic, weak)             id<FRUploaderDelegate> delegate;

@property (nonatomic, strong, nullable) NSURLSession *session;
@property (nonatomic, strong, nullable) NSURLSessionUploadTask *uploadTask;
@property (nonatomic, strong)           NSMutableData *responseData;

@end



@implementation FRUploader

- (instancetype) initWithTarget:(NSString *)target delegate:(id<FRUploaderDelegate>)delegate
{
    self = [super init];
    if ( self )
    {
        self.target = target;
        self.delegate = delegate;
        self.responseData = [[NSMutableData alloc] init];
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

    NSLog(@"Posting %lu bytes to %@", (unsigned long)[formData length], self.target);

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.target]];
    
#if defined(FR_UPLOAD_FORM_DATA) || defined(FR_JSON_SENT_AS_PARAM)
    NSString *boundaryString = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", formBoundary];
    [request addValue:boundaryString forHTTPHeaderField:@"Content-Type"];
#endif
    
    [request setHTTPMethod:@"POST"];
    
    self.session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration] delegate:self delegateQueue:nil];
    self.uploadTask = [self.session uploadTaskWithRequest:request fromData:formData];
    [self.uploadTask resume];
}

- (void) cancel
{
    [self.uploadTask cancel];
    self.uploadTask = nil;
    
    [self.session invalidateAndCancel];
    self.session = nil;
}

- (NSString *) response
{
    return [[NSString alloc] initWithData:self.responseData
                                 encoding:NSUTF8StringEncoding];
}

//- (void) dealloc
//{
//    NSLog( @"dealloc" );
//}



#pragma mark NSURLSessionDelegate methods

- (void) URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    if ( session != self.session )
        return;
    if ( dataTask != self.uploadTask )
        return;
    
    if ( self.responseData.length == 0 &&
        [response respondsToSelector:@selector(statusCode)] &&
        ((NSHTTPURLResponse *)response).statusCode == 200 )
    {
        __weak typeof(self) weakSelf = self;
        dispatch_async( dispatch_get_main_queue(), ^{
            
            if ( [weakSelf.delegate respondsToSelector:@selector(uploaderStarted:)] )
                [weakSelf.delegate uploaderStarted:weakSelf];
            
        });
    }
    
    completionHandler( NSURLSessionResponseAllow );
}

- (void) URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    if ( session != self.session )
        return;
    if ( dataTask != self.uploadTask )
        return;
    
    NSLog( @"Connection received data" );
    
    __weak typeof(self) weakSelf = self;
    dispatch_async( dispatch_get_main_queue(), ^{
        
        [weakSelf.responseData appendData:data];
        
    });
}

- (void) URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error
{
    if ( session != self.session )
        return;
    if ( task != self.uploadTask )
        return;
    
    if ( error )
    {
        NSLog(@"Connection failed");
        
        __weak typeof(self) weakSelf = self;
        dispatch_async( dispatch_get_main_queue(), ^{
            
            if ( [weakSelf.delegate respondsToSelector:@selector(uploaderFailed:withError:)] )
                [weakSelf.delegate uploaderFailed:weakSelf withError:error];
            
            [weakSelf cancel];
            
        });
    }
    else
    {
        NSLog(@"Connection finished");
        
        __weak typeof(self) weakSelf = self;
        dispatch_async( dispatch_get_main_queue(), ^{
            
            if ( [self.delegate respondsToSelector:@selector(uploaderFinished:)] )
                [weakSelf.delegate uploaderFinished:weakSelf];
            
            [weakSelf cancel];
            
        });
    }
}

@end

NS_ASSUME_NONNULL_END
