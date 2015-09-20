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

@protocol FRUploaderDelegate;

@interface FRUploader : NSObject <NSURLConnectionDataDelegate> {

@private
    NSString *_target;
    id<FRUploaderDelegate> _delegate;

    NSURLConnection *_connection;
    NSMutableData *_responseData;
}

- (id) initWithTarget:(NSString *)target delegate:(id<FRUploaderDelegate>)delegate;
- (void) postAndNotify:(NSDictionary *)dict;
- (void) cancel;
- (NSString *) response;

@end


@protocol FRUploaderDelegate <NSObject>

@optional
- (void) uploaderStarted:(FRUploader *)uploader;
- (void) uploaderFailed:(FRUploader *)uploader withError:(NSError *)error;
- (void) uploaderFinished:(FRUploader *)uploader;

@end
