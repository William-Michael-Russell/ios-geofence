//
//  GFCloudFencelog.h
//  Geofancy
//
//  Created by Marcus Kida on 07.12.13.
//  Copyright (c) 2013 Marcus Kida. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GFCloudFencelog : NSObject

// Double
@property (strong) NSNumber *longitude;
@property (strong) NSNumber *latitude;

// Int
@property (strong) NSNumber *httpResponseCode;

// String
@property (strong) NSString *locationId;
@property (strong) NSString *httpUrl;
@property (strong) NSString *httpMethod;
@property (strong) NSString *httpResponse;
@property (strong) NSString *eventType;
@property (strong) NSString *fenceType;

@end
