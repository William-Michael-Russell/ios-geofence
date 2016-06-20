//
//  GFTodayViewController.m
//  Geofancy
//
//  Created by Marcus Kida on 26/10/2015.
//  Copyright © 2015 Marcus Kida. All rights reserved.
//

#import "GFTodayViewController.h"
#import <AFNetworking/AFNetworking.h>

static NSString *const TODAY_URL = @"https://my.locative.io/api/today";

@interface GFTodayViewController () <NCWidgetProviding>

@property (nonatomic, strong) IBOutlet UILabel *label;
@property (nonatomic, strong) NSUserDefaults *defaults;

@end

@implementation GFTodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.marcuskida.Geofancy"];
}

- (NSString *)getSessionId {
    return [self.defaults stringForKey:@"sessionId"];
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    
    if (!([self getSessionId].length > 0)) {
        [self updateLabelUsingString:nil];
        return completionHandler(NCUpdateResultFailed);
    }
    
    AFHTTPRequestOperationManager *requestManager = [AFHTTPRequestOperationManager manager];
    requestManager.responseSerializer = [AFJSONResponseSerializer serializer];
    requestManager.requestSerializer = [AFHTTPRequestSerializer serializer];
    [requestManager setSecurityPolicy:[self commonPolicy]];
    [requestManager GET:TODAY_URL parameters:@{@"sessionId": [self getSessionId]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *locationId = responseObject[@"fencelog"][@"locationId"];
        if (locationId.length > 0) {
            [self updateLabelUsingString:[NSLocalizedString(@"You last visited", nil) stringByAppendingFormat:@" %@", locationId]];
            return completionHandler(NCUpdateResultNewData);
        }
        [self updateLabelUsingString:NSLocalizedString(@"Error updating last visited location.", nil)];
        completionHandler(NCUpdateResultNoData);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (operation.response.statusCode == 404) {
            [self updateLabelUsingString:NSLocalizedString(@"You have not visited any locations.", nil)];
            return completionHandler(NCUpdateResultNewData);
        }
        [self updateLabelUsingString:nil];
        completionHandler(NCUpdateResultFailed);
    }];
}

- (void)updateLabelUsingString:(NSString *)string {
    self.label.text = string.length > 0 ? string : NSLocalizedString(@"Please login using the Locative App by tapping here.", nil);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([self getSessionId].length > 0) {
        return [self.extensionContext openURL:[NSURL URLWithString:@"locative://open?ref=todaywidget"] completionHandler:nil];
    }
    [self.extensionContext openURL:[NSURL URLWithString:@"locative://open?ref=todaywidget&openSettings=true"] completionHandler:nil];
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
