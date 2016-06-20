//
//  GFAppDelegate.h
//  Geofancy
//
//  Created by Marcus Kida on 03.10.13.
//  Copyright (c) 2013 Marcus Kida. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iOS_GPX_Framework/GPX.h>

#import "AFNetworking.h"
#import <MSDynamicsDrawerViewController/MSDynamicsDrawerViewController.h>
#import "GFGeofenceManager.h"
#import "GFCloudManager.h"
#import "GFRequestManager.h"
#import "GFCoreDataManager.h"
#import "Locative-Swift.h"

@interface GFAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) MSDynamicsDrawerViewController *dynamicsDrawerViewController;
@property (nonatomic, strong) GFGeofenceManager *geofenceManager;
@property (nonatomic, strong) GFCloudManager *cloudManager;
@property (nonatomic, strong) GFRequestManager *requestManager;
@property (nonatomic, strong) AFNetworkReachabilityManager *reachabilityManager;
@property (nonatomic, strong) Settings *settings;
@property (nonatomic, strong) GFCoreDataManager *coreDataManager;

@end
