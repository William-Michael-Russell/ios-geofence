//
//  GFCoreDataManager.m
//  Locative
//
//  Created by Marcus Kida on 1/12/2015.
//  Copyright © 2015 Marcus Kida. All rights reserved.
//

#import <ObjectiveRecord/ObjectiveRecord.h>
#import <ObjectiveSugar/ObjectiveSugar.h>

#import "GFCoreDataManager.h"
#import "Locative-Swift.h"
#import "GFGeofence.h"

@implementation GFCoreDataManager

- (instancetype)initWithModel:(NSString *)model {
    if (self = [super init]) {
        _coreDataManager = [CoreDataManager sharedManager];
        _coreDataManager.modelName = model;
        _coreDataManager.bundle = [NSBundle bundleForClass:self.class];
        [self migrate];
        [self migrateCredentials];
    }
    return self;
}

- (void)migrate {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *documentsDirectory = [self.coreDataManager applicationDocumentsDirectory];
    NSString *geofancyDatabasePath = [documentsDirectory URLByAppendingPathComponent:@"Geofancy.sqlite"].path;
    NSString *locativeDatabasePath = [documentsDirectory URLByAppendingPathComponent:@"Locative.sqlite"].path;
    
    if ([fileManager fileExistsAtPath:geofancyDatabasePath]) {
        NSError *error;
        [fileManager copyItemAtPath:geofancyDatabasePath toPath:locativeDatabasePath error:&error];
        if (!error) {
            NSError *removeError;
            [fileManager removeItemAtPath:geofancyDatabasePath error:&removeError];
        }
    }
}

- (void)migrateCredentials {
    @synchronized (self) {
        [[GFGeofence all] each:^(GFGeofence *object) {
            if (object.httpUser.lct_isNotEmpty == YES) {
                // bail out in case user is nil
                return;
            }
            SecureCredentials *credentials = [[SecureCredentials alloc] initWithService:object.uuid];
            credentials[object.httpUser] = object.httpPassword;
            [object save];
        }];
    }
}

@end
