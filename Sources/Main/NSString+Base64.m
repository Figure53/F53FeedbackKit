//
//  NSString+Base64.m
//  Helpifier
//
//  Created by Sean Dougall on 5/24/10.
//
//	Copyright (c) 2010-2018 Figure 53 LLC, http://figure53.com
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.
//

#import "NSString+Base64.h"


NS_ASSUME_NONNULL_BEGIN

@implementation NSData (Base64)

- (NSString *) encodeBase64
{
	char *base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	NSMutableString *result = [NSMutableString new];
	NSUInteger i;
	NSUInteger len = [self length];
	int paddingBytes = 0;
    const unsigned char *bytes = [self bytes];
	
	for ( i = 0; i < len; i += 3 )
	{
		UInt32 threeBytes = bytes[i] * 0x10000;
        
		if (i < len - 1) threeBytes += bytes[i + 1] * 0x100;
		else paddingBytes++;
		
		if (i < len - 2) threeBytes += bytes[i + 2];
		else paddingBytes++;
		
		[result appendFormat:@"%c%c%c%c",
		 base64Chars[(threeBytes >> 18) & 0x3f],
		 base64Chars[(threeBytes >> 12) & 0x3f],
		 paddingBytes > 1 ? '=' : base64Chars[(threeBytes >> 6) & 0x3f],
		 paddingBytes > 0 ? '=' : base64Chars[ threeBytes       & 0x3f]];
	}
	
	return result;
}

@end



@implementation NSString (Base64)

- (NSString *) encodeBase64
{
	char *base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	NSMutableString *result = [NSMutableString new];
	NSUInteger i;
	NSUInteger len = [self length];
	int paddingBytes = 0;
	
	for ( i = 0; i < len; i += 3 )
	{
		UInt32 threeBytes = [self characterAtIndex:i] * 0x10000;

		if ( i < len - 1 )
            threeBytes += [self characterAtIndex:i+1] * 0x100;
		else
            paddingBytes++;
		
		if ( i < len - 2 )
            threeBytes += [self characterAtIndex:i+2];
		else
            paddingBytes++;
		
		[result appendFormat:@"%c%c%c%c",
		 base64Chars[(threeBytes >> 18) & 0x3f],
		 base64Chars[(threeBytes >> 12) & 0x3f],
		 paddingBytes > 1 ? '=' : base64Chars[(threeBytes >> 6) & 0x3f],
		 paddingBytes > 0 ? '=' : base64Chars[ threeBytes       & 0x3f]];
	}
	
	return result;
}


@end

NS_ASSUME_NONNULL_END
