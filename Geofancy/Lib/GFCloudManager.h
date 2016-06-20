//
//  GFCloudManager.h
//  Geofancy
//
//  Created by Marcus Kida on 07.12.13.
//  Copyright (c) 2013 Marcus Kida. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Locative-Swift.h"
#import "GFCloudFencelog.h"

typedef enum {
    GFCloudManagerSignupErrorNoError = 0,
    GFCloudManagerSignupErrorUserExisting,
    GFCloudManagerSignupErrorGeneric
} GFCloudManagerSignupError;

@class GFGeofence;
@class GFSettings;

@interface GFCloudManager : NSObject

- (instancetype)init __attribute__((unavailable("Please use `initWithSettings:` instead")));
- (instancetype)initWithSettings:(Settings *)settings;

- (void) signupAccountWithUsername:(NSString *)username andEmail:(NSString *)email andPassword:(NSString *)password onFinish:(void(^)(NSError *error, GFCloudManagerSignupError gfcError))finish;
- (void) loginToAccountWithUsername:(NSString *)username andPassword:(NSString *)password onFinish:(void(^)(NSError *error, NSString *sessionId))finish;
- (void) checkSessionWithSessionId:(NSString *)sessionId onFinish:(void(^)(NSError *error))finish;

- (void) dispatchCloudFencelog:(GFCloudFencelog *)fencelog onFinish:(void(^)(NSError *error))finish;
- (void) validateSessionWithCallback:(void(^)(BOOL valid))cb;
- (void) validateSession;
- (void) loadGeofences:(void(^)(NSError *error, NSArray *geofences))completion;
- (void) uploadGeofence:(GFGeofence *)geofence onFinish:(void(^)(NSError *error))finish;

@end
