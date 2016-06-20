//
//  GFRequestManager.h
//  Geofancy
//
//  Created by Marcus Kida on 11.01.14.
//  Copyright (c) 2014 Marcus Kida. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GFRequest.h"

@class GFCloudFencelog;

@interface GFRequestManager : NSObject

+ (GFRequestManager *) sharedManager;
- (void) flushWithCompletion:(void(^)())cb;

/* Fencelogs */
- (void) dispatchFencelog:(GFCloudFencelog *)fencelog;

@end
