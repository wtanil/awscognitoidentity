//
//  LoginViewController.m
//  awscognitoid
//
//  Created by jilcreationMacPro1 on 22/6/15.
//  Copyright (c) 2015 jilcreationMacPro1. All rights reserved.
//

#import "LoginViewController.h"
#import "AmazonClientManager.h"
#import <AWSCore/AWSTask.h>
#import <AWSCore/AWSCore.h>

@interface LoginViewController ()

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [AWSLogger defaultLogger].logLevel = AWSLogLevelVerbose;
    
    [self disableUI];
    
    if ([[AmazonClientManager sharedInstance] isConfigured]) {
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        
        
        [[AmazonClientManager sharedInstance] resumeSessionWithCompletionHandler:^id(AWSTask *task) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self refreshUI];
            });
            return nil;
        }];
    }
    else {
        [[[UIAlertView alloc] initWithTitle:@"Missing Configuration"
                                    message:@"Please check Constants.m and set appropriate values."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)loginClicked:(id)sender {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self disableUI];
    NSLog(@"LOGIN");
    [[AmazonClientManager sharedInstance] loginFromView:self.view withCompletionHandler:^id(AWSTask *task) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshUI];
            [self performSegueWithIdentifier: @"loginSegue" sender: self];
        });
        return nil;
    }];
}

- (IBAction)logoutClicked:(id)sender {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self disableUI];
    [[AmazonClientManager sharedInstance] logoutWithCompletionHandler:^id(AWSTask *task) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshUI];
            
        });
        return nil;
    }];
}

-(void)disableUI {

    self.loginButton.enabled = NO;
    self.logoutWipeButton.enabled = NO;
}

-(void)refreshUI {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    self.loginButton.enabled = YES;
    if ([[AmazonClientManager sharedInstance] isLoggedIn]) {
        [self.loginButton setTitle:@"Link" forState:UIControlStateNormal];
    }
    else {
        [self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
    }
    self.logoutWipeButton.enabled = [[AmazonClientManager sharedInstance] isLoggedIn];
}

@end
