//
//  GFConfig.h
//  Geofancy
//
//  Created by Marcus Kida on 14.02.14.
//  Copyright (c) 2014 Marcus Kida. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GFConfig : NSObject

@property (nonatomic, assign) BOOL backgroundFetchMessageShown;
@property (nonatomic, strong) NSDate *lastMessageFetch;
@property (nonatomic, strong, readonly) NSString *readableVersionString;

@end
