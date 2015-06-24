//
//  LoginViewController.h
//  awscognitoid
//
//  Created by jilcreationMacPro1 on 22/6/15.
//  Copyright (c) 2015 jilcreationMacPro1. All rights reserved.
//

#import "ViewController.h"

@interface LoginViewController : ViewController

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *logoutWipeButton;
- (IBAction)loginClicked:(id)sender;
- (IBAction)logoutClicked:(id)sender;



@end
