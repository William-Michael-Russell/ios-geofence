//
//  GFCloudSignupViewController.m
//  Geofancy
//
//  Created by Marcus Kida on 07.12.13.
//  Copyright (c) 2013 Marcus Kida. All rights reserved.
//

#import <PSTAlertController/PSTAlertController.h>
#import <SVProgressHUD/SVProgressHUD.h>

#import "GFAppDelegate.h"
#import "GFCloudSignupViewController.h"

@interface GFCloudSignupViewController ()

@property (nonatomic, weak) IBOutlet UITextField *usernameTextField;
@property (nonatomic, weak) IBOutlet UITextField *emailTextField;
@property (nonatomic, weak) IBOutlet UITextField *passwordTextField;

@property (nonatomic, weak) GFAppDelegate *appDelegate;
@end

@implementation GFCloudSignupViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _appDelegate = (GFAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.usernameTextField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions
- (IBAction) signupAccount:(id)sender {
    if ([[self.usernameTextField text] length] > 4 ||
        [[self.emailTextField text] length] > 4 ||
        [[self.passwordTextField text] length] > 4) {
        
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];

        [[_appDelegate cloudManager] signupAccountWithUsername:[self.usernameTextField text] andEmail:[self.emailTextField text] andPassword:[self.passwordTextField text] onFinish:^(NSError *error, GFCloudManagerSignupError gfcError) {
            
            [SVProgressHUD dismiss];
            
            if (!error) {
                // Account created successfully!
                
                [[_appDelegate cloudManager] loginToAccountWithUsername:[self.usernameTextField text] andPassword:[self.passwordTextField text] onFinish:^(NSError *error, NSString *sessionId) {
                    if (!error) {
                        [self.appDelegate.settings setApiToken:sessionId];
                        [self.appDelegate.settings persist];
                        PSTAlertController *alertController = [PSTAlertController alertControllerWithTitle:NSLocalizedString(@"Note", nil)
                                                                                                   message:NSLocalizedString(@"Your account has been created successfully! You have been logged in automatically.", nil)
                                                                                            preferredStyle:PSTAlertControllerStyleAlert];
                        [alertController addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) handler:^(PSTAlertAction *action) {
                            [[self navigationController] popViewControllerAnimated:YES];
                        }]];
                        [alertController showWithSender:sender controller:self animated:YES completion:nil];
                        
                    } else {
                        PSTAlertController *alertController = [PSTAlertController alertControllerWithTitle:NSLocalizedString(@"Note", nil)
                                                                                                   message:NSLocalizedString(@"Your account has been created successfully! You may now sign in using the prvoided credentials.", nil)
                                                                                            preferredStyle:PSTAlertControllerStyleAlert];
                        [alertController addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) handler:^(PSTAlertAction *action) {
                            [[self navigationController] popViewControllerAnimated:YES];
                        }]];
                        [alertController showWithSender:sender controller:self animated:YES completion:nil];
                    }
                }];
                
                
            } else if (gfcError == GFCloudManagerSignupErrorUserExisting) {
                // User already existing
                PSTAlertController *alertController = [PSTAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                                           message:NSLocalizedString(@"A user with the same Username / E-Mail address ist already existing. Please choose another one..", nil)
                                                                                    preferredStyle:PSTAlertControllerStyleAlert];
                [alertController addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) handler:nil]];
                [alertController showWithSender:sender controller:self animated:YES completion:nil];
            }
        }];
    } else {
        PSTAlertController *alertController = [PSTAlertController alertControllerWithTitle:NSLocalizedString(@"Note", nil)
                                                                                   message:NSLocalizedString(@"Please enter a Username and a Password which have a minimum of 5 chars.", nil)
                                                                            preferredStyle:PSTAlertControllerStyleAlert];
        [alertController addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) handler:nil]];
        [alertController showWithSender:sender controller:self animated:YES completion:nil];
    }
}

- (IBAction) readTos:(id)sender {
    PSTAlertController *alertController = [PSTAlertController alertControllerWithTitle:NSLocalizedString(@"Note", nil)
                                                                               message:NSLocalizedString(@"This will open up Safari and lead to our TOS. Sure?", nil)
                                                                        preferredStyle:PSTAlertControllerStyleAlert];
    [alertController addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"No", nil) style:PSTAlertActionStyleCancel handler:nil]];
    [alertController addAction:[PSTAlertAction actionWithTitle:NSLocalizedString(@"Yes", nil) style:PSTAlertActionStyleDefault handler:^(PSTAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://my.locative.io/tos"]];
    }]];
    [alertController showWithSender:sender controller:self animated:YES completion:nil];
}

@end
