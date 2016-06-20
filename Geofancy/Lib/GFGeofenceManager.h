//
//  GFGeofenceManager.h
//  Geofancy
//
//  Created by Marcus Kida on 03.10.13.
//  Copyright (c) 2013 Marcus Kida. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "GFGeofence.h"
#import "GFCloudManager.h"

typedef enum : NSUInteger {
    GFTriggerOnEnter = (0x1 << 0), // => 0x00000001
    GFTriggerOnExit   = (0x1 << 1) // => 0x00000010
} GFGeofenceTrigger;

static NSString *const GFEnter = @"enter";
static NSString *const GFExit = @"exit";

@interface GFGeofenceManager : NSObject

#pragma mark - Initialization
+ (id) sharedManager;
- (void) cleanup;

#pragma mark - Accessors
- (NSArray *) geofences;

#pragma mark - Region Monitoring
- (void) startMonitoringForRegion:(CLRegion *)region;
- (void) stopMonitoringForRegion:(CLRegion *)region;

- (void) startMonitoringEvent:(GFGeofence *)event;
- (void) stopMonitoringEvent:(GFGeofence *)event;

#pragma mark - Current Location
- (void) performAfterRetrievingCurrentLocation:(void(^)(CLLocation *currentLocation))block;

@end
