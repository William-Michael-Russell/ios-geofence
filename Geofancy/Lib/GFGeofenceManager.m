//
//  GFGeofenceManager.m
//  Geofancy
//
//  Created by Marcus Kida on 03.10.13.
//  Copyright (c) 2013 Marcus Kida. All rights reserved.
//

#import "GFGeofenceManager.h"

#import <INTULocationManager/INTULocationManager.h>
#import <ObjectiveSugar/ObjectiveSugar.h>
#import <ObjectiveRecord/ObjectiveRecord.h>

#import "GFAppDelegate.h"
#import "GFBackgroundBlockOperation.h"
#import "GFRequest.h"

#define WHICH_METHOD(number) ([number intValue] == 0)?@"POST":@"GET"

@interface GFGeofenceManager () <CLLocationManagerDelegate>

@property (nonatomic, weak) GFAppDelegate *appDelegate;
@property (nonatomic, copy) void (^locationBlock)(CLLocation *currentLocation);
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *currentLocation;

@property (nonatomic, weak) NSOperationQueue *mainQueue;
@property (nonatomic, strong) NSOperationQueue *dispatchQueue;

@end

@implementation GFGeofenceManager

+ (id) sharedManager
{
    static GFGeofenceManager *geofenceManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        geofenceManager = [[GFGeofenceManager alloc] init];
        [geofenceManager setup];
    });
    return geofenceManager;
}

- (void) setup
{
    self.appDelegate = (GFAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager setDelegate:self];
    
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways) {
        return [self.locationManager requestAlwaysAuthorization];
    }
    
    [self.locationManager startUpdatingLocation];
    [self.locationManager startMonitoringSignificantLocationChanges];
}

- (void) cleanup
{
    [[self geofences] each:^(CLRegion *fence) {
        __block BOOL found = NO;
        [[GFGeofence all] each:^(GFGeofence *event) {
            if([event.uuid isEqualToString:fence.identifier]) {
                found = YES;
            }
            
        }];
        if(!found) {
            [self stopMonitoringForRegion:fence];
        }
    }];
    
    [[GFGeofence all] each:^(GFGeofence *event) {
        [self startMonitoringEvent:event];
    }];
}

#pragma mark - Accessors
- (NSOperationQueue *)dispatchQueue {
    if (!_dispatchQueue) {
        _dispatchQueue = [[NSOperationQueue alloc] init];
    }
    return _dispatchQueue;
}

- (NSOperationQueue *)mainQueue {
    if (!_mainQueue) {
        _mainQueue = [NSOperationQueue mainQueue];
    }
    return _mainQueue;
}

#pragma mark - LocationManager Delegate
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusDenied) {
        if (self.locationBlock) {
            return self.locationBlock(nil);
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    NSLog(@"%@", locations);
    
    [self setCurrentLocation:(CLLocation *)[locations first]];
    
    if([self locationBlock])
    {
        self.locationBlock(self.currentLocation);
        self.locationBlock = nil;
    }
    
    [self.locationManager stopUpdatingLocation];
}

- (void) performBackgroundTaskForRegion:(CLRegion *)region withTrigger:(NSString *)trigger
{
    NSLog(@"CLRegion: %@, Trigger: %@", region, trigger);

    [self.dispatchQueue addOperation:[GFBackgroundBlockOperation blockOperationWithBlock:^{
        [self performUrlRequestForRegion:region withTrigger:trigger];
    }]];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    [self performBackgroundTaskForRegion:region withTrigger:GFEnter];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    [self performBackgroundTaskForRegion:region withTrigger:GFExit];
}

- (void) performUrlRequestForRegion:(CLRegion *)region withTrigger:(NSString *)trigger
{
    GFGeofence *event = [GFGeofence where:[NSString stringWithFormat:@"uuid == '%@'", region.identifier]].first;
    NSLog(@"uuid == '%@'", region.identifier);
    
    if(event)
    {
        CLLocation *location = [[CLLocation alloc] initWithLatitude:[event.latitude doubleValue] longitude:[event.longitude doubleValue]];
        NSLog(@"got location update: %@", location);
        if ([trigger isEqualToString:GFEnter] && !([event.triggers integerValue] & GFTriggerOnEnter)) {
            return;
        }
        
        if ([trigger isEqualToString:GFExit] && !([event.triggers integerValue] & GFTriggerOnExit)) {
            return;
        }
        
        NSString *relevantUrl = ([trigger isEqualToString:GFEnter])?[event enterUrl]:[event exitUrl];
        NSString *url = ([relevantUrl length] > 0)?relevantUrl:[[self.appDelegate.settings globalUrl] absoluteString];
        BOOL useGlobalUrl = ([relevantUrl length] == 0);
        NSString *eventId = ([[event customId] length] > 0)?[event customId]:[event uuid];
        NSString *deviceId = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        NSDate *timestamp = [NSDate date];
        
        NSDictionary *parameters = @{@"id":eventId,
                                     @"trigger":trigger,
                                     @"device":deviceId,
                                     @"latitude":[NSNumber numberWithDouble:location.coordinate.latitude],
                                     @"longitude":[NSNumber numberWithDouble:location.coordinate.longitude],
                                     @"timestamp": [NSString stringWithFormat:@"%f", [timestamp timeIntervalSince1970]]};

        if([url length] > 0)
        {
            [self.mainQueue addOperationWithBlock:^{
                GFRequest *httpRequest = [GFRequest create];
                httpRequest.url = url;
                httpRequest.method = WHICH_METHOD([event enterMethod]);
                httpRequest.parameters = parameters;
                httpRequest.eventType = event.type;
                httpRequest.timestamp = timestamp;
                httpRequest.uuid = [[NSUUID UUID] UUIDString];
                
                if (useGlobalUrl) {
                    if ([self.appDelegate.settings httpBasicAuthEnabled]) {
                        httpRequest.httpAuth = [NSNumber numberWithBool:YES];
                        httpRequest.httpAuthUsername = [self.appDelegate.settings httpBasicAuthUsername];
                        httpRequest.httpAuthPassword = [self.appDelegate.settings httpBasicAuthPassword];
                    }
                } else {
                    if ([event.httpAuth boolValue]) {
                        httpRequest.httpAuth = [NSNumber numberWithBool:YES];
                        httpRequest.httpAuthUsername = event.httpUser;
                        httpRequest.httpAuthPassword = event.httpPasswordSecure;
                    }
                }
                
                [httpRequest save];
                [self.appDelegate.requestManager flushWithCompletion:nil];
            }];
        }
    }
}

#pragma mark - Public Methods
- (NSArray *) geofences
{
    return [[self.locationManager monitoredRegions] allObjects];
}

- (void) startMonitoringForRegion:(CLRegion *)region
{
    [[self locationManager] startMonitoringForRegion:region];
}

- (void) stopMonitoringForRegion:(CLRegion *)region
{
    [[self locationManager] stopMonitoringForRegion:region];
}

- (void) stopMonitoringEvent:(GFGeofence *)event
{
    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake([event.latitude doubleValue], [event.longitude doubleValue])
                                                                 radius:[event.radius doubleValue]
                                                             identifier:event.uuid];
    [self stopMonitoringForRegion:region];
}

- (void) startMonitoringEvent:(GFGeofence *)event
{
    if ([event.type intValue] == GFGeofenceTypeGeofence) {
        CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake([event.latitude doubleValue], [event.longitude doubleValue])
                                                                     radius:[event.radius doubleValue]
                                                                 identifier:event.uuid];
        [self startMonitoringForRegion:region];
    } else {
        CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:event.iBeaconUuid]
                                                                         major:[event.iBeaconMajor longLongValue]
                                                                         minor:[event.iBeaconMinor longLongValue]
                                                                    identifier:event.uuid];
        [self startMonitoringForRegion:region];
    }
}

#pragma mark - Current Location
- (void) performAfterRetrievingCurrentLocation:(void (^)(CLLocation *currentLocation))block
{
    self.locationBlock = block;
    __weak typeof (self) weakSelf = self;
    [[INTULocationManager sharedInstance] requestLocationWithDesiredAccuracy:INTULocationAccuracyRoom
                                                                     timeout:10.0
                                                        delayUntilAuthorized:YES
                                                                       block:
     ^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
         // only invoke block if it's not been nulled
         // fixes https://fabric.io/locative/ios/apps/com.marcuskida.geofancy/issues/573d9287ffcdc042501238c9
         __strong typeof (self) strongSelf = weakSelf;
         if (strongSelf.locationBlock) {
             strongSelf.locationBlock(currentLocation);
         }
     }];
}

@end
