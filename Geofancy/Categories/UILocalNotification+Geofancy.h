//
//  UILocalNotification+Geofancy.h
//  Geofancy
//
//  Created by Marcus Kida on 5/05/2015.
//  Copyright (c) 2015 Marcus Kida. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UILocalNotification (Geofancy)

+ (void)presentLocalNotificationWithAlertBody:(NSString *)alertBody;
+ (void)presentLocalDebugNotificationWithAlertBody:(NSString *)alertBody;

+ (void)presentLocalNotificationWithSoundName:(NSString *)soundName alertBody:(NSString *)alertBody;
+ (void)presentLocalNotificationWithSoundName:(NSString *)soundName alertBody:(NSString *)alertBody userInfo:(NSDictionary *)userInfo;

@end
