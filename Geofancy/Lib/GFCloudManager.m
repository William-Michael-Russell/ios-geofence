//
//  GFCloudManager.m
//  Geofancy
//
//  Created by Marcus Kida on 07.12.13.
//  Copyright (c) 2013 Marcus Kida. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>

#import "Locative-Swift.h"
#import "GFCloudManager.h"
#import "GFGeofence.h"
#import "GFCloudFencelog.h"
#import "NSString+Hashes.h"
#import "GFGeofenceManager.h"

#define StringOrEmpty(arg) (arg ? arg : @"")
#define NumberOrZeroFloat(arg) (arg ? arg : [NSNumber numberWithFloat:0.0f])
#define kMyGeofancyBackend      [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"BackendProtocol"] stringByAppendingFormat:@"://%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"BackendHost"]]
#define kOriginFallbackString   @"iOS App"

@interface GFCloudManager ()

@property (nonatomic, strong) Settings *settings;

@end

@implementation GFCloudManager

- (instancetype)initWithSettings:(Settings *)settings {
    self = [super init];
    if (self) {
        NSLog(@"My Locative Backend: %@", kMyGeofancyBackend);
        _settings = settings;
    }
    return self;
}

- (AFSecurityPolicy *) commonPolicy
{
    AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
    [policy setAllowInvalidCertificates:YES];
    [policy setValidatesDomainName:NO];
    return policy;
}

- (void) signupAccountWithUsername:(NSString *)username andEmail:(NSString *)email andPassword:(NSString *)password onFinish:(void (^)(NSError *, GFCloudManagerSignupError))finish
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager setSecurityPolicy:[self commonPolicy]];
    NSDictionary *params = @{@"username": username,
                             @"email": email,
                             @"password": password,
                             @"token": [[NSString stringWithFormat:@"%@:%@%%%@", username, password, email] sha1]
                             };
    [manager POST:[kMyGeofancyBackend stringByAppendingString:@"/api/signup"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Request succeeded
        if (finish) {
            finish(nil, GFCloudManagerSignupErrorNoError);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Request failed
        if ([operation.response statusCode] == 409) {
            if (finish) {
                finish(error, GFCloudManagerSignupErrorUserExisting);
            }
        } else {
            if (finish) {
                finish(error, GFCloudManagerSignupErrorGeneric);
            }
        }
    }];
}

- (void) loginToAccountWithUsername:(NSString *)username andPassword:(NSString *)password onFinish:(void (^)(NSError *, NSString *))finish
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager setSecurityPolicy:[self commonPolicy]];
    NSDictionary *params = @{@"username": username,
                             @"password": password,
                             @"origin": [self originString]};
    [manager GET:[kMyGeofancyBackend stringByAppendingString:@"/api/session"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Request succeeded
        if (finish) {
            finish(nil, [responseObject objectForKey:@"success"]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Request failed
        if (finish) {
            finish(error, nil);
        }
    }];
}

- (void) checkSessionWithSessionId:(NSString *)sessionId onFinish:(void (^)(NSError *))finish
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager setSecurityPolicy:[self commonPolicy]];
    NSDictionary *params = @{@"origin": [self originString]};
    [manager GET:[NSString stringWithFormat:@"%@/api/session/%@", kMyGeofancyBackend, sessionId] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (finish) {
            finish(nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (finish) {
            finish(error);
        }
    }];
}

- (void) dispatchCloudFencelog:(GFCloudFencelog *)fencelog onFinish:(void (^)(NSError *))finish
{
    NSLog(@"dispatchCloudFencelog");
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager setSecurityPolicy:[self commonPolicy]];
    NSDictionary *params = @{@"longitude": NumberOrZeroFloat(fencelog.longitude),
                             @"latitude": NumberOrZeroFloat(fencelog.latitude),
                             @"locationId": StringOrEmpty(fencelog.locationId),
                             @"httpUrl": StringOrEmpty(fencelog.httpUrl),
                             @"httpMethod": StringOrEmpty(fencelog.httpMethod),
                             @"httpResponseCode": StringOrEmpty(fencelog.httpResponseCode),
                             @"httpResponse": StringOrEmpty(fencelog.httpResponse),
                             @"eventType": StringOrEmpty(fencelog.eventType),
                             @"fenceType": StringOrEmpty(fencelog.fenceType),
                             @"origin": [self originString]
                             };
    [manager POST:[NSString stringWithFormat:@"%@/api/fencelogs/%@", kMyGeofancyBackend, [self.settings apiToken]] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // Request succeeded
        if (finish) {
            finish(nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Request failed
        NSLog(@"dispatchCloudFencelog Failed: %@", error);
        if (finish) {
            finish(error);
        }
    }];
}

- (void) validateSessionWithCallback:(void(^)(BOOL valid))cb
{
    [self checkSessionWithSessionId:[self.settings apiToken] onFinish:^(NSError *error) {
        if (error) {
            [self.settings removeApiToken];
        }
        if (cb) {
            cb(error?NO:YES);
        }
    }];
}

- (void) validateSession
{
    [self validateSessionWithCallback:nil];
}

- (void) loadGeofences:(void (^)(NSError *, NSArray *))completion
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager setSecurityPolicy:[self commonPolicy]];
    NSString *sessionId = [self.settings apiToken];
    if (sessionId.length == 0) {
        return completion([NSError errorWithDomain:NSStringFromClass(self.class) code:401 userInfo:@{NSLocalizedDescriptionKey: @"Invalid session"}], nil);
    }
    [manager GET:[kMyGeofancyBackend stringByAppendingString:@"/api/geofences"] parameters:@{@"sessionId": sessionId} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *geofences = responseObject[@"geofences"];
        if ([geofences isKindOfClass:NSArray.class]) {
            return completion(nil, geofences);
        }
        completion([NSError errorWithDomain:NSStringFromClass(self.class) code:406 userInfo:@{NSLocalizedDescriptionKey: @"Geofences Array expected"}], nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        completion(error, nil);
    }];
}

- (void)uploadGeofence:(GFGeofence *)geofence onFinish:(void (^)(NSError *))finish
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager setSecurityPolicy:[self commonPolicy]];
    NSString *sessionId = [self.settings apiToken];
    if (sessionId.length == 0) {
        return finish([NSError errorWithDomain:NSStringFromClass(self.class) code:401 userInfo:@{NSLocalizedDescriptionKey: @"Invalid session"}]);
    }
    NSDictionary *params = @{
                             @"origin": [self originString],
                             @"locationId": geofence.customId ? geofence.customId : @"",
                             @"lon": geofence.longitude,
                             @"lat": geofence.latitude,
                             @"radius": geofence.radius,
                             @"triggerOnArrival": (geofence.triggers.integerValue & GFTriggerOnEnter) ? @1 : @0,
                             @"triggerOnArrivalMethod" : geofence.enterMethod,
                             @"triggerOnArrivalUrl" : geofence.enterUrl ? geofence.enterUrl : @"",
                             @"triggerOnLeave": (geofence.triggers.integerValue & GFTriggerOnExit) ? @1 : @0,
                             @"triggerOnLeaveMethod": geofence.exitMethod,
                             @"triggerOnLeaveUrl": geofence.exitUrl ? geofence.exitUrl : @"",
                             @"basicAuth": geofence.httpAuth ? @1 : @0,
                             @"basicAuthUsername": geofence.httpUser ? geofence.httpUser : @"",
                             @"basicAuthPassword": geofence.httpPasswordSecure ? geofence.httpPasswordSecure : @""
                             };
    [manager POST:[kMyGeofancyBackend stringByAppendingFormat:@"/api/geofences/%@", sessionId] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        finish(nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        finish(error);
    }];}

#pragma mark - Helper Methods
- (NSString *)originString
{
    NSString *originString = [[UIDevice currentDevice] name];
    if (![originString isKindOfClass:NSString.class]) {
        return kOriginFallbackString;
    }
    
    if (originString.length == 0) {
        return kOriginFallbackString;
    }
    
    return originString;
}

@end
