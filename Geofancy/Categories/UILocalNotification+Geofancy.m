//
//  UILocalNotification+Geofancy.m
//  Geofancy
//
//  Created by Marcus Kida on 5/05/2015.
//  Copyright (c) 2015 Marcus Kida. All rights reserved.
//

#import "UILocalNotification+Geofancy.h"

@implementation UILocalNotification (Geofancy)

+ (void)presentLocalNotificationWithAlertBody:(NSString *)alertBody {
    [self presentLocalNotificationWithSoundName:nil alertBody:alertBody];
}

+ (void)presentLocalDebugNotificationWithAlertBody:(NSString *)alertBody {
    [self presentLocalNotificationWithAlertBody:[@"DEBUG: " stringByAppendingString:alertBody]];
}

+ (void)presentLocalNotificationWithSoundName:(NSString *)soundName alertBody:(NSString *)alertBody {
    [self presentLocalNotificationWithSoundName:soundName alertBody:alertBody userInfo:nil];
}

+ (void)presentLocalNotificationWithSoundName:(NSString *)soundName alertBody:(NSString *)alertBody userInfo:(NSDictionary *)userInfo {
    NSAssert(alertBody, @"alertBody is mandatory!");
    UILocalNotification *notification = [[self alloc] init];
    notification.soundName = soundName;
    notification.userInfo = userInfo;
    notification.alertBody = alertBody;
    notification.soundName = @"notification.caf";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

@end
