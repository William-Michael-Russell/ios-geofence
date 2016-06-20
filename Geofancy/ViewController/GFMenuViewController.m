//
//  GFMenuViewController.m
//  Geofancy
//
//  Created by Marcus Kida on 14.11.13.
//  Copyright (c) 2013 Marcus Kida. All rights reserved.
//

#import <PSTAlertController/PSTAlertController.h>

#import "GFAppDelegate.h"
#import "GFMenuViewController.h"

@implementation GFMenuViewController

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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 50, 0, 0);
    [self hideEmptySeparators];
}

- (void) hideEmptySeparators
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:view];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //FIXME: Workaround since Xcode 6 Beta 5 (iOS 8)
    cell.backgroundColor = [UIColor colorWithRed:51.0/255.0 green:51.0/255.0 blue:51.0/255.0 alpha:1.0f];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        if (indexPath.row == 1) {
            [[(GFAppDelegate *)[[UIApplication sharedApplication] delegate] dynamicsDrawerViewController] setPaneViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"GeofencesNav"] animated:YES completion:nil];
        } else if (indexPath.row == 2) {
            [[(GFAppDelegate *)[[UIApplication sharedApplication] delegate] dynamicsDrawerViewController] setPaneViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"SettingsNav"] animated:YES completion:nil];
        } else if (indexPath.row == 3) {
            [self askToOpenSocialLink:@"GitHub Issues" callback:^{
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/LocativeHQ/ios-app/issues"]];
            }];
        } else if (indexPath.row == 5) {
            [self askToOpenSocialLink:@"Twitter" callback:^{
                if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://user?screen_name=LocativeHQ"]];
                } else {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://twitter.com/LocativeHQ"]];
                }
            }];

            [[(GFAppDelegate *)[[UIApplication sharedApplication] delegate] dynamicsDrawerViewController] setPaneState:MSDynamicsDrawerPaneStateClosed animated:YES allowUserInterruption:YES completion:nil];
        } else if (indexPath.row == 6) {
            [self askToOpenSocialLink:@"Facebook" callback:^{
                if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fb://"]]) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"fb://profile/329978570476013"]];
                } else {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://facebook.com/LocativeHQ"]];
                }
            }];
            [[(GFAppDelegate *)[[UIApplication sharedApplication] delegate] dynamicsDrawerViewController] setPaneState:MSDynamicsDrawerPaneStateClosed animated:YES allowUserInterruption:YES completion:nil];
        }
    }
}

- (void)askToOpenSocialLink:(NSString *)name callback:(void(^)())cb {
    PSTAlertController *controller = [PSTAlertController alertControllerWithTitle:NSLocalizedString(@"Note", nil)
                                                                          message:[NSString stringWithFormat:NSLocalizedString(@"This will open up %@. Ready?", nil), name]
                                                                   preferredStyle:PSTAlertControllerStyleAlert];
    [controller addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"No", nil) style:PSTAlertActionStyleCancel handler:nil]];
    [controller addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil) style:PSTAlertActionStyleDefault handler:^(PSTAlertAction *action) {
        cb();
    }]];
    [controller showWithSender:nil controller:self animated:YES completion:nil];
}

@end
