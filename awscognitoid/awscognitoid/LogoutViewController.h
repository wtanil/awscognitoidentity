//
//  LogoutViewController.h
//  awscognitoid
//
//  Created by jilcreationMacPro1 on 24/6/15.
//  Copyright (c) 2015 jilcreationMacPro1. All rights reserved.
//

#import "ViewController.h"

@class AWSCognitoDataset;

@interface LogoutViewController : ViewController
- (IBAction)logoutClicked:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;

@property (strong, nonatomic) AWSCognitoDataset *dataset;
@property (strong, nonatomic) NSString* identityId;


@end
