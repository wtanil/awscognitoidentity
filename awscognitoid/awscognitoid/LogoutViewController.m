//
//  LogoutViewController.m
//  awscognitoid
//
//  Created by jilcreationMacPro1 on 24/6/15.
//  Copyright (c) 2015 jilcreationMacPro1. All rights reserved.
//

#import "LogoutViewController.h"
#import "AmazonClientManager.h"
#import <AWSCore/AWSTask.h>
#import <AWSCore/AWSCore.h>
#import <AWSCognito/AWSCognito.h>

@interface LogoutViewController () {
    NSMutableArray *_datasets;
}

@end

@implementation LogoutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.logoutButton.enabled = [[AmazonClientManager sharedInstance] isLoggedIn];
    
    _datasets = [NSMutableArray arrayWithArray:[[AWSCognito defaultCognito] listDatasets]];
    
    [self refreshDatasets];
    
}

- (void) refreshDatasets {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    NSMutableArray *tasks = [NSMutableArray arrayWithCapacity:_datasets.count];
    
    for (AWSCognitoDatasetMetadata *metadata in _datasets) {
        AWSCognitoDataset *dataset = [[AWSCognito defaultCognito] openOrCreateDataset:metadata.name];
        [tasks addObject:[dataset synchronize]];
    }
    
    [[[AWSTask taskForCompletionOfAllTasks:tasks] continueWithBlock:^id(AWSTask *task) {
        return [[AWSCognito defaultCognito] refreshDatasetMetadata];
    }] continueWithBlock:^id(AWSTask *task) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            if (task.error) {
                [[[UIAlertView alloc] initWithTitle:@"Error" message:task.error.description delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
            }
            else {
                _datasets = [NSMutableArray arrayWithArray:[[AWSCognito defaultCognito] listDatasets]];
                NSLog(@"######################### %lu", (unsigned long)_datasets.count);
            }
        });
        return nil;
    }];
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

- (IBAction)logoutClicked:(id)sender {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    [[AmazonClientManager sharedInstance] logoutWithCompletionHandler:^id(AWSTask *task) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Loggout");
            self.logoutButton.enabled = false;
            [self performSegueWithIdentifier:@"logoutSegue" sender:self];
        });
        return nil;
    }];
}



@end
