//
//  NSString+URLEncode.m
//  Geofancy
//
//  Created by Marcus Kida on 09.10.13.
//  Copyright (c) 2013 Marcus Kida. All rights reserved.
//

#import "NSString+URLEncode.h"

@implementation NSString (URLEncode)

- (NSString *) urlEncodeUsingEncoding:(NSStringEncoding)encoding
{
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (CFStringRef)self,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                 CFStringConvertNSStringEncodingToEncoding(encoding)));
}

@end
