//
//  GFAppDelegate.m
//  Geofancy
//
//  Created by Marcus Kida on 03.10.13.
//  Copyright (c) 2013 Marcus Kida. All rights reserved.
//

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <Harpy/Harpy.h>
#import <TSMessages/TSMessage.h>
#import <PSTAlertController/PSTAlertController.h>
#import <ObjectiveRecord/ObjectiveRecord.h>
#import <SVProgressHUD/SVProgressHUD.h>

#import "GFAppDelegate.h"
#import "GFMenuViewController.h"
//#import "GFSettings.h"

#define kMainStoryboard [UIStoryboard storyboardWithName:[[NSBundle mainBundle].infoDictionary objectForKey:@"UIMainStoryboardFile"] bundle:[NSBundle mainBundle]]

@interface GFAppDelegate ()

@property (nonatomic, strong) Harpy *harpy;

@end

@implementation GFAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Fabric
    [Fabric with:@[[Crashlytics class]]];

    // Override point for customization after application launch.
    self.settings = [[[Settings alloc] init] restoredSettings];
    self.geofenceManager = [GFGeofenceManager sharedManager];
    self.cloudManager = [[GFCloudManager alloc] initWithSettings:self.settings];
    self.requestManager = [GFRequestManager sharedManager];
    self.harpy = [Harpy sharedInstance];
    
    // Setup CoreData
    self.coreDataManager = [[GFCoreDataManager alloc] initWithModel:@"Model"];
    
    // Reachability
    [self setupReachabilityStatus];
    
    [self.window setBackgroundColor:[UIColor blackColor]];
        
    // Initial Setup (if required)
    if (![self.settings appHasBeenStarted]) {
        [self.settings setAppHasBeenStarted:[NSNumber numberWithBool:YES]];
        [self.settings persist];
    }

    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];

    self.dynamicsDrawerViewController = [MSDynamicsDrawerViewController new];
    self.dynamicsDrawerViewController.paneViewSlideOffAnimationEnabled = NO;
    self.dynamicsDrawerViewController.paneDragRequiresScreenEdgePan = YES;
//    [self.dynamicsDrawerViewController addStylersFromArray:@[[MSDynamicsDrawerScaleStyler styler], [MSDynamicsDrawerFadeStyler styler]]
//                                              forDirection:MSDynamicsDrawerDirectionLeft];
    [self.dynamicsDrawerViewController setDrawerViewController:[mainStoryboard instantiateViewControllerWithIdentifier:@"Menu"]
                                                  forDirection:MSDynamicsDrawerDirectionLeft];
    [self.dynamicsDrawerViewController setPaneViewController:[mainStoryboard instantiateViewControllerWithIdentifier:@"GeofencesNav"]];
    [self.dynamicsDrawerViewController setGravityMagnitude:4.0f];
    [self.window setRootViewController:self.dynamicsDrawerViewController];
    [self.window makeKeyAndVisible];
    
    // Background fetch
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    // Remove all remaining GFRequests
    [GFRequest deleteAll];
    
    [self.harpy setAppID:@"725198453"];
#ifdef DEBUG
    [self.harpy setDebugEnabled:YES];
#endif
    [self.harpy setPresentingViewController:self.window.rootViewController];
    [self.harpy setAlertType:HarpyAlertTypeSkip];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [self.cloudManager validateSession];
    [self.harpy checkVersionDaily];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if (url) {
        if ([url isFileURL]) {
            if ([[url pathExtension] isEqualToString:@"gpx"]) {
                NSLog(@"Opening GPX File at URL:%@", [url absoluteString]);
                [self askToImportGpxAtUrl:url];
                return YES;
            }
        }
        if ([url.query rangeOfString:@"openSettings=true"].location != NSNotFound) {
            [self.dynamicsDrawerViewController setPaneViewController:[kMainStoryboard instantiateViewControllerWithIdentifier:@"SettingsNav"] animated:YES completion:nil];
            return YES;

        }
    }
    return NO;
}

- (void) application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [self.requestManager flushWithCompletion:^{
        completionHandler(UIBackgroundFetchResultNewData);
    }];
}

- (void) askToImportGpxAtUrl:(NSURL *)url
{
    PSTAlertController *controller = [PSTAlertController alertControllerWithTitle:NSLocalizedString(@"Note", nil)
                                                                          message:NSLocalizedString(@"Would you like to keep your existing Geofences?", nil)
                                                                   preferredStyle:PSTAlertControllerStyleAlert];
    [controller addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"No", nil) style:PSTAlertActionStyleDefault handler:^(PSTAlertAction *action) {
        [GFGeofence deleteAll];
        [self importGpxAtUrl:url keepExistingGeofences:NO];
    }]];
    [controller addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil) style:PSTAlertActionStyleDefault handler:^(PSTAlertAction *action) {
        [self importGpxAtUrl:url keepExistingGeofences:YES];
    }]];
    [controller showWithSender:nil controller:nil animated:YES completion:nil];
}

- (void) importGpxAtUrl:(NSURL *)url keepExistingGeofences:(BOOL)keepExisting
{
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error = nil;
        NSString *gpxString = [[NSString alloc] initWithContentsOfFile:[url path]
                                                              encoding:NSUTF8StringEncoding
                                                                 error:&error];
        
        NSUInteger maxLimit = (20 - [[GFGeofence all] count]);
        if (!keepExisting) {
            maxLimit = 20;
        }
        
        BOOL maxImportLimitExceeded = NO;
        NSUInteger overallWaypoints = 0;
        if (!error) {
            GPXRoot *root = [GPXParser parseGPXWithString:gpxString error:nil];
            if ([root.waypoints count] > maxLimit) {
                overallWaypoints = [root.waypoints count];
                maxImportLimitExceeded = YES;
            }
            NSLog(@"maxLimit: %lu, maxImportLimitExceeded: %@", (unsigned long)maxLimit, maxImportLimitExceeded?@"YES":@"NO");
            for (int i = 0; i < (maxImportLimitExceeded?maxLimit:[root.waypoints count]); i++) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    GPXWaypoint *waypoint = [root.waypoints objectAtIndex:i];
                    GFGeofence *geofence = [GFGeofence create];
                    geofence.type = GFGeofenceTypeGeofence;
                    geofence.name = waypoint.comment;
                    geofence.uuid = [[NSUUID UUID] UUIDString];
                    geofence.customId = waypoint.name;
                    geofence.latitude = [NSNumber numberWithFloat:waypoint.latitude];
                    geofence.longitude = [NSNumber numberWithFloat:waypoint.longitude];
                    geofence.radius = [NSNumber numberWithInt:50];
                    geofence.triggers = @(GFTriggerOnEnter | GFTriggerOnExit);
                    [geofence save];
                    [self.geofenceManager startMonitoringEvent:geofence];
                    NSLog(@"Importing and starting to monitor Geofences: %@", geofence);
                });
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.geofenceManager cleanup];
            [[NSNotificationCenter defaultCenter] postNotificationName:kReloadGeofences object:nil];
            [SVProgressHUD dismiss];
            
            NSString *message = error?
            NSLocalizedString(@"An error occured when trying to open our GPX file, maybe it's damaged?", nil):
            NSLocalizedString(@"Your GPX file has been sucessfully imported.", nil);
            
            if (!error && maxImportLimitExceeded) {
                message = [NSString stringWithFormat:NSLocalizedString(@"Only %1$d of the %2$d Geofences could be imported due to the 20 Geofences limit.", nil), maxLimit, overallWaypoints];
            }

            PSTAlertController *controller = [PSTAlertController alertControllerWithTitle:error?NSLocalizedString(@"Error", nil):NSLocalizedString(@"Note", nil)
                                                                                  message:message
                                                                           preferredStyle:PSTAlertControllerStyleAlert];
            [controller addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:PSTAlertActionStyleDefault handler:nil]];
            [controller showWithSender:nil controller:nil animated:YES completion:nil];
        });
    });
}

- (void) application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    TSMessageNotificationType type = TSMessageNotificationTypeMessage;
    if (notification.userInfo) {
        type = notification.userInfo[@"success"] ? TSMessageNotificationTypeSuccess : TSMessageNotificationTypeError;
    }
    [TSMessage showNotificationWithTitle:notification.alertBody type:type];
}

#pragma mark - UserVoice Delegate
- (void) userVoiceWasDismissed
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

#pragma mark - Reachability
- (void) setupReachabilityStatus
{    
    self.reachabilityManager = [AFNetworkReachabilityManager managerForDomain:@"my.locative.io"];
    [self.reachabilityManager startMonitoring];
    [self.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        NSLog(@"Reachability: %@", AFStringFromNetworkReachabilityStatus(status));
    }];
}

@end
