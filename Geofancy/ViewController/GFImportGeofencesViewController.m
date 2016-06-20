//
//  GFImportGeofencesViewController.m
//  Geofancy
//
//  Created by Marcus Kida on 3/09/2014.
//  Copyright (c) 2014 Marcus Kida. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import <ObjectiveRecord/ObjectiveRecord.h>

#import "GFImportGeofencesViewController.h"
#import "GFAppDelegate.h"

@interface GFImportGeofencesViewController ()

@property (nonatomic, strong) GFAppDelegate *appDelegate;
@property (nonatomic, strong) CLGeocoder *geocoder;
@property (nonatomic, strong) GFGeofence *event;

@property (nonatomic, strong) NSArray *geofences;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, strong) id selectedGeofence;

@end

@implementation GFImportGeofencesViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.appDelegate = (GFAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.geocoder = [[CLGeocoder alloc] init];
    self.tableView.tableFooterView = [UIView new];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadGeofences];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Data loading
- (void)loadGeofences
{
    self.loading = YES;
    [self.appDelegate.cloudManager loadGeofences:^(NSError *error, NSArray *geofences) {
        if (error) {
            return;
        }
        self.geofences = [NSArray arrayWithArray:geofences];
        self.loading = NO;
        [self.tableView reloadData];
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([GFGeofence maximumReachedShowingAlert:YES viewController:self]) {
        return;
    }
    
    // Add Geofences
    self.selectedGeofence = self.geofences[indexPath.row];
    [self importSelectedGeofence];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.geofences.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    id geofence = self.geofences[indexPath.row];
    cell.textLabel.text = geofence[@"locationId"];
    cell.imageView.image = [UIImage imageNamed:@"icon-geofence"];
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"UUID: %@", geofence[@"uuid"]]];
    [string addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:cell.detailTextLabel.font.pointSize] range:NSMakeRange(0, 3)];
    [cell.detailTextLabel setAttributedText:string];
    
    return cell;
}

#pragma mark - DZNEmptyDataSetSource
- (UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView{
    
    if (self.loading) {
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [activityView startAnimating];
        return activityView;
    }
    
    return nil;
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"No Geofences", nil)];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView{
    
    return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Add some Geofences at https://my.locative.io to get going.", nil)];
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIColor whiteColor];
}

#pragma mark - Save Imported
- (void)importSelectedGeofence
{
    if (!self.selectedGeofence) {
        return;
    }
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    
    NSString *uuid = [[NSUUID UUID] UUIDString];
    [self reverseGeocodeForNearestPlacemark:^(CLPlacemark *placemark) {
        NSString *eventName = [NSString stringWithFormat:@"Event (%@)", uuid];
        if (placemark) {
            eventName = [self addressFromPlacemark:placemark];
            NSLog(@"Event Name: %@", eventName);
        }
        [self saveEventWithEventName:eventName andUuid:uuid];
    }];

}

- (void)reverseGeocodeForNearestPlacemark:(void(^)(CLPlacemark *placemark))cb
{
    [_geocoder cancelGeocode];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:[self.selectedGeofence[@"location"][@"lat"] doubleValue] longitude:[self.selectedGeofence[@"location"][@"lon"] doubleValue]];
    [_geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        cb([placemarks firstObject]);
    }];
}

- (NSString *)addressFromPlacemark:(CLPlacemark *)placemark
{
    if (!placemark) {
        return NSLocalizedString(@"Unknown Location", @"Unknown Location");
    }
    NSString *eventName = @"";
    for (int i = 0; i < [[[placemark addressDictionary] objectForKey:@"FormattedAddressLines"] count]; i++) {
        NSString *part = [[[placemark addressDictionary] objectForKey:@"FormattedAddressLines"] objectAtIndex:i];
        eventName = [eventName stringByAppendingFormat:@"%@", part];
        
        if(i < ([[[placemark addressDictionary] objectForKey:@"FormattedAddressLines"] count] - 1)) {
            eventName = [eventName stringByAppendingString:@", "];
        }
    }
    return eventName;
}

- (void) saveEventWithEventName:(NSString *)eventName andUuid:(NSString *)uuid
{
    NSNumber *triggers = [NSNumber numberWithInt:(GFTriggerOnEnter | GFTriggerOnExit)];
    BOOL enterSwitchOn = [self.selectedGeofence[@"triggerOnArrival"][@"enabled"] boolValue];
    BOOL exitSwitchOn = [self.selectedGeofence[@"triggerOnLeave"][@"enabled"] boolValue];
    
    if(!enterSwitchOn && exitSwitchOn)
    {
        triggers = [NSNumber numberWithInt:(GFTriggerOnExit)];
    }
    else if(enterSwitchOn && !exitSwitchOn)
    {
        triggers = [NSNumber numberWithInt:(GFTriggerOnEnter)];
    }
    else if(!exitSwitchOn && !exitSwitchOn)
    {
        triggers = [NSNumber numberWithInt:0];
    }
    
    self.event = [GFGeofence create];
    self.event.uuid = self.selectedGeofence[@"uuid"];
    
    self.event.name = eventName;
    self.event.triggers = triggers;
    self.event.type = @(GFGeofenceTypeGeofence);
    
    // Geofence
    self.event.latitude = @([self.selectedGeofence[@"location"][@"lat"] doubleValue]);
    self.event.longitude = @([self.selectedGeofence[@"location"][@"lon"] doubleValue]);
    self.event.radius = @([self.selectedGeofence[@"location"][@"radius"] intValue]);
    self.event.customId = self.selectedGeofence[@"locationId"];
    
    // Normalize URLs (if necessary)
    NSString *enterUrl = self.selectedGeofence[@"triggerOnArrival"][@"url"];
    if([enterUrl length] > 0) {
        if([[enterUrl lowercaseString] hasPrefix:@"http://"] || [[enterUrl lowercaseString] hasPrefix:@"https://"]) {
            self.event.enterUrl = enterUrl;
        } else {
            self.event.enterUrl = [@"http://" stringByAppendingString:enterUrl];
        }
    } else {
        self.event.enterUrl = nil;
    }
    
    NSString *exitUrl = self.selectedGeofence[@"triggerOnLeave"][@"url"];
    if([exitUrl length] > 0) {
        if([[exitUrl lowercaseString] hasPrefix:@"http://"] || [[exitUrl lowercaseString] hasPrefix:@"https://"]) {
            self.event.exitUrl = exitUrl;
        } else if ([exitUrl length] > 0) {
            self.event.exitUrl = [@"http://" stringByAppendingString:exitUrl];
        }
    } else {
        self.event.exitUrl = nil;
    }
    
    self.event.enterMethod = @([self.selectedGeofence[@"triggerOnArrival"][@"method"] intValue]);
    self.event.exitMethod = @([self.selectedGeofence[@"triggerOnLeave"][@"method"] intValue]);
    
    self.event.httpAuth = @([self.selectedGeofence[@"basicAuth"][@"enabled"] boolValue]);
    self.event.httpUser = self.selectedGeofence[@"basicAuth"][@"username"];
    self.event.httpPasswordSecure = self.selectedGeofence[@"basicAuth"][@"password"];
    
    [[_appDelegate geofenceManager] startMonitoringEvent:self.event];
    [self.event save];
    
    [SVProgressHUD dismiss];
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
