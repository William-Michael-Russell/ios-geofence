//
//  NSString+URLEncode.h
//  Geofancy
//
//  Created by Marcus Kida on 09.10.13.
//  Copyright (c) 2013 Marcus Kida. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (URLEncode)

- (NSString *) urlEncodeUsingEncoding:(NSStringEncoding)encoding;

@end
