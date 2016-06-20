//
//  GFBackgroundBlockOperation.m
//  Geofancy
//
//  Created by Marcus Kida on 25.12.13.
//  Copyright (c) 2013 Marcus Kida. All rights reserved.
//

#import "GFBackgroundBlockOperation.h"

@interface GFBackgroundBlockOperation ()

@property (assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@end

@implementation GFBackgroundBlockOperation

- (id)init {
    if (self = [super init]) {
        self.automaticallyEndsBackgroundTask = YES;
    }
    return self;
}

- (void)startBackgroundTask {
    self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundTask];
    }];
}

- (void)endBackgroundTask {
    if (self.backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
        self.backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
}

- (void)addExecutionBlock:(void (^)(void))block {
    __weak typeof(self) weakSelf = self;
    [super addExecutionBlock:^{
        [weakSelf startBackgroundTask];
        block();
        if (weakSelf.automaticallyEndsBackgroundTask)
            [weakSelf endBackgroundTask];
    }];
}

@end
