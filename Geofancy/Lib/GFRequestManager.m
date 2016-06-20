//
//  GFRequestManager.m
//  Geofancy
//
//  Created by Marcus Kida on 11.01.14.
//  Copyright (c) 2014 Marcus Kida. All rights reserved.
//

#import <ObjectiveRecord/ObjectiveRecord.h>

#import "GFRequestManager.h"
#import "UILocalNotification+Geofancy.h"
#import "GFAppDelegate.h"

#define IS_POST_METHOD(method) ([method isEqualToString:@"POST"])

@interface GFRequestManager ()

@property (nonatomic, strong) GFAppDelegate *appDelegate;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, assign) BOOL currentlyFlushing;
@property (nonatomic, strong) NSMutableArray *lastRequestIds;

@end

@implementation GFRequestManager

+ (GFRequestManager *) sharedManager
{
    static GFRequestManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[GFRequestManager alloc] init];
        [manager setAppDelegate:(GFAppDelegate *)[[UIApplication sharedApplication] delegate]];
        [manager setQueue:[NSOperationQueue new]];
    });
    return manager;
}

- (void) flushWithCompletion:(void(^)())cb
{
    if (self.currentlyFlushing) {
        return;
    }
    self.currentlyFlushing = YES;
    // flush last request ids if > 100
    if (self.lastRequestIds.count > 100) {
        [self.lastRequestIds removeAllObjects];
    }
    
    NSArray *allRequests = [GFRequest all];
    NSOperation *operation = nil;
    NSOperation *previousOperation = nil;
    for (GFRequest *httpRequest in allRequests) {
        BOOL faulty = NO;
        if ([httpRequest.failCount intValue] >= 3) {
            faulty = YES;
        }
        if ([self.lastRequestIds containsObject:httpRequest.uuid]) {
            faulty = YES;
        }
        if (faulty) { // Delete request in case failCount reaches 3
            [httpRequest delete];
        } else {
            if (httpRequest.uuid.length > 0) {
                [self.lastRequestIds addObject:httpRequest.uuid];
            }
            if (self.appDelegate.reachabilityManager.isReachable) { // Only try to send request if device is reachable via WWAN or WiFi
                operation = [NSBlockOperation blockOperationWithBlock:^{
                    [self dispatchRequest:httpRequest completion:^(BOOL success) {
                        if (success) {
                            [httpRequest delete];
                        } else { // Increase failcount on error
                            NSInteger oldFailCount = httpRequest.failCount.integerValue;
                            oldFailCount++;
                            NSError *error;
                            // perform check for fault and returns nil if object doesn't exist anymore
                            // e.g. if request has already been fulfilled/removed
                            // fixes https://fabric.io/locative/ios/apps/com.marcuskida.geofancy/issues/573d92aaffcdc04250123a23
                            if([httpRequest.managedObjectContext existingObjectWithID:httpRequest.objectID error:&error]) {
                                httpRequest.failCount = @(oldFailCount);
                            }
                        }
                    }];
                }];
                if (previousOperation) {
                    [operation addDependency:previousOperation];
                }
                previousOperation = operation;
                [self.queue addOperation:operation];
            }
        }
    }

    operation = [NSBlockOperation blockOperationWithBlock:^{
        self.currentlyFlushing = NO;
        if(cb) {
            cb();
        }
    }];
    if (previousOperation) {
        [operation addDependency:previousOperation];
    }
    [self.queue addOperation:operation];
}

- (void) dispatchRequest:(GFRequest *)httpRequest completion:(void(^)(BOOL success))cb
{
    AFHTTPRequestOperationManager *requestManager = [AFHTTPRequestOperationManager manager];
    requestManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    requestManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    [requestManager setSecurityPolicy:[self commonPolicy]];
    
    if ([httpRequest.httpAuth boolValue]) {
        [requestManager.requestSerializer setAuthorizationHeaderFieldWithUsername:httpRequest.httpAuthUsername
                                                                         password:httpRequest.httpAuthPassword];
    }
    
    if(IS_POST_METHOD(httpRequest.method)) {
        [requestManager POST:httpRequest.url parameters:httpRequest.parameters
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"POST Completion: %@", responseObject);
            [self dispatchFencelogSuccess:YES
                              httpRequest:httpRequest
                           responseObject:responseObject
                           responseStatus:operation.response.statusCode
                                    error:nil
                                 callback:cb];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"POST Error: %@", error);
            [self dispatchFencelogSuccess:NO
                              httpRequest:httpRequest
                           responseObject:nil
                           responseStatus:operation.response.statusCode
                                    error:error
                                 callback:cb];
        }];
    }
    else {
        [requestManager GET:httpRequest.url parameters:httpRequest.parameters
                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"GET Completion: %@", responseObject);
            [self dispatchFencelogSuccess:YES
                              httpRequest:httpRequest
                           responseObject:responseObject
                           responseStatus:operation.response.statusCode
                                    error:nil
                                 callback:cb];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"GET Error: %@", error);
            [self dispatchFencelogSuccess:NO
                              httpRequest:httpRequest
                           responseObject:nil
                           responseStatus:operation.response.statusCode
                                    error:error
                                 callback:cb];
        }];
    }
}

- (void)dispatchFencelogSuccess:(BOOL)success
                    httpRequest:(GFRequest *)httpRequest
                 responseObject:(id)responseObject
                 responseStatus:(NSInteger)statusCode
                          error:(NSError *)error
                       callback:(void(^)(BOOL success))cb {
    if(success && [self.appDelegate.settings notifyOnSuccess]) {
        [self presentLocalNotification:
         [IS_POST_METHOD(httpRequest.method) ? NSLocalizedString(@"POST Success:", nil) : NSLocalizedString(@"GET Success:", nil)
          stringByAppendingFormat:@" %@", [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding]]
         success:YES];
    } else if(!success && [self.appDelegate.settings notifyOnFailure]) {
        [self presentLocalNotification:[NSLocalizedString(@"GET Failure:", nil) stringByAppendingFormat:@" %@", error.localizedDescription]
         success:NO];
    }
    // My Geofancy Fencelog
    GFCloudFencelog *fencelog = [GFCloudFencelog new];
    fencelog.latitude = [httpRequest.parameters objectForKey:@"latitude"];
    fencelog.longitude = [httpRequest.parameters objectForKey:@"longitude"];
    fencelog.httpResponseCode = [NSNumber numberWithLong:statusCode];
    fencelog.locationId = [httpRequest.parameters objectForKey:@"id"];
    fencelog.httpUrl = httpRequest.url;
    fencelog.httpMethod = IS_POST_METHOD(httpRequest.method) ? @"POST" : @"GET";
    fencelog.httpResponse = responseObject ? [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding] : @"<See error code>";
    fencelog.eventType = [httpRequest.parameters objectForKey:@"trigger"];
    fencelog.fenceType = ([httpRequest.eventType intValue] == 0)?@"geofence":@"ibeacon";
    [self dispatchFencelog:fencelog];
    dispatch_async(dispatch_get_main_queue(), ^{
        cb(success);
    });
}

#pragma mark - Local Notification
- (void)presentLocalNotification:(NSString *)text success:(BOOL)success {
    [UILocalNotification presentLocalNotificationWithSoundName:([self.appDelegate.settings soundOnNotification]) ? @"notification.caf" : nil
                                                     alertBody:text
                                                      userInfo:@{@"success": @(success)}];
}

#pragma mark - Accessors
- (NSMutableArray *)lastRequestIds {
    if (!_lastRequestIds) {
        _lastRequestIds = [[NSMutableArray alloc] init];
    }
    return _lastRequestIds;
}

#pragma mark - Fencelog
- (void) dispatchFencelog:(GFCloudFencelog *)fencelog
{
    if ([[self.appDelegate.settings apiToken] length] > 0) {
        [[self.appDelegate cloudManager] dispatchCloudFencelog:fencelog onFinish:nil];
    }
}

#pragma mark - AFNetworking Security Policy
- (AFSecurityPolicy *) commonPolicy
{
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    [policy setAllowInvalidCertificates:YES];
    [policy setValidatesDomainName:NO];
    return policy;
}

@end
