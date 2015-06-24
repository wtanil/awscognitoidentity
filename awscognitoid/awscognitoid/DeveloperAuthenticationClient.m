/*
 * Copyright 2010-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import "DeveloperAuthenticationClient.h"
#import <AWSCore/AWSCore.h>
#import <UICKeychainStore/UICKeychainStore.h>

NSString *const ProviderPlaceHolder = @"foobar.com";
NSString *const LoginURI = @"%@login-api.php?email2=%@&pass2=%@";
NSString *const GetTokenURI = @"%@gettoken-api.php?key=%@&login=%@";
NSString *const DeveloperAuthenticationClientDomain = @"com.amazonaws.service.cognitoidentity.DeveloperAuthenticatedIdentityProvider";

NSString *const EncryptionKeyKey = @"authkey";

@interface DeveloperAuthenticationResponse()

@property (nonatomic, strong) NSString *identityId;
@property (nonatomic, strong) NSString *identityPoolId;
@property (nonatomic, strong) NSString *token;

@end

@implementation DeveloperAuthenticationResponse
@end

@interface DeveloperAuthenticationClient()
@property (nonatomic, strong) NSString *identityPoolId;
@property (nonatomic, strong) NSString *identityId;
@property (nonatomic, strong) NSString *token;

// used for internal encryption

@property (nonatomic, strong) NSString *key;

// used to save state of authentication
@property (nonatomic, strong) UICKeyChainStore *keychain;

@end

@implementation DeveloperAuthenticationClient

+ (instancetype)identityProviderWithAppname:(NSString *)appname endpoint:(NSString *)endpoint {
    return [[DeveloperAuthenticationClient alloc] initWithAppname:appname endpoint:endpoint];
}

- (instancetype)initWithAppname:(NSString *)appname endpoint:(NSString *)endpoint {
    if (self = [super init]) {
        self.appname  = appname;
        self.endpoint = endpoint;
        
        self.keychain = _keychain = [UICKeyChainStore keyChainStoreWithService:[NSString stringWithFormat:@"%@.%@.%@", [NSBundle mainBundle].bundleIdentifier, [DeveloperAuthenticationClient class], self.appname]];
        

        self.key = self.keychain[EncryptionKeyKey];
    }
    
    return self;
}

- (BOOL)isAuthenticated {
    return self.key != nil;
}

// login and get a decryption key to be used for subsequent calls
- (AWSTask *)login:(NSString *)username password:(NSString *)password {
    
    // If the key is already set, the login already succeeeded
    if (self.key) {
        return [AWSTask taskWithResult:self.key];
    }
    
    NSLog(@"login");
    
    return [[AWSTask taskWithResult:nil] continueWithBlock:^id(AWSTask *task) {
        NSURL *request = [NSURL URLWithString:[self buildLoginRequestUrl:username password:password]];
        
        NSLog(@"URL %@", request);
        
        NSData *rawResponse = [NSData dataWithContentsOfURL:request];
        if (!rawResponse) {
            NSLog(@"error connecting");
            return [AWSTask taskWithError:[NSError errorWithDomain:DeveloperAuthenticationClientDomain
                                                              code:DeveloperAuthenticationClientLoginError
                                                          userInfo:nil]];
        }
        
        
        NSString *json = [[NSString alloc] initWithData:rawResponse encoding:NSUTF8StringEncoding];
        NSLog(@"json: %@", json);
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:rawResponse options:kNilOptions error:nil];
        
        NSString* errorType = [jsonDict objectForKey:@"errortype"];
        
        if (![errorType isEqualToString:@"0"]) {
            return [AWSTask taskWithError:[NSError errorWithDomain:DeveloperAuthenticationClientDomain
                                                              code:DeveloperAuthenticationClientLoginError
                                                          userInfo:nil]];
        }
        
        self.key = [jsonDict objectForKey:@"randomkey"];
        if (!self.key) {
            return [AWSTask taskWithError:[NSError errorWithDomain:DeveloperAuthenticationClientDomain
                                                              code:DeveloperAuthenticationClientUnknownError
                                                          userInfo:nil]];
        }
        AWSLogDebug(@"key: %@", self.key);
        
        // Save our key/uid to the keychain

        self.keychain[EncryptionKeyKey] = self.key;
        
        return [AWSTask taskWithResult:nil];
    }];
    
}

- (void)logout {
    self.key = nil;
    self.keychain[EncryptionKeyKey] = nil;

}

// call gettoken and set our values from returned result
- (AWSTask *)getToken:(NSString *)identityId logins:(NSDictionary *)logins {
    
    // make sure we've authenticated
    if (![self isAuthenticated]) {
        return [AWSTask taskWithError:[NSError errorWithDomain:DeveloperAuthenticationClientDomain
                                                          code:DeveloperAuthenticationClientLoginError
                                                      userInfo:nil]];
    }
    
    return [[AWSTask taskWithResult:nil] continueWithBlock:^id(AWSTask *task) {
        NSURL *request = [NSURL URLWithString:[self buildGetTokenRequestUrl:identityId logins:logins]];
        NSData *rawResponse = [NSData dataWithContentsOfURL:request];
        if (!rawResponse) {
            return [AWSTask taskWithError:[NSError errorWithDomain:DeveloperAuthenticationClientDomain
                                                              code:DeveloperAuthenticationClientLoginError
                                                          userInfo:nil]];
        }
        
        NSString *json = [[NSString alloc] initWithData:rawResponse encoding:NSUTF8StringEncoding];
        NSLog(@"json: %@", json);
        
        
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:rawResponse options:kNilOptions error:nil];
        
        NSLog(@"jsonDict");
        
        NSString* errorType = [NSString stringWithFormat:@"%@", [jsonDict objectForKey:@"errortype"]];
        
        NSLog(@"%@", errorType);
        
        if (![errorType isEqualToString:@"0"]) {
            NSLog(@"ERROR TYPE ERROR ");
            return [AWSTask taskWithError:[NSError errorWithDomain:DeveloperAuthenticationClientDomain
                                                              code:DeveloperAuthenticationClientLoginError
                                                          userInfo:nil]];
        }
        
        DeveloperAuthenticationResponse *authResponse = [DeveloperAuthenticationResponse new];
        
        authResponse.token = [jsonDict objectForKey:@"token"];
        authResponse.identityId = [jsonDict objectForKey:@"identityId"];
        authResponse.identityPoolId = [jsonDict objectForKey:@"identityPoolId"];
        if (!(authResponse.token || authResponse.identityId || authResponse.identityPoolId)) {
            return [AWSTask taskWithError:[NSError errorWithDomain:DeveloperAuthenticationClientDomain
                                                              code:DeveloperAuthenticationClientUnknownError
                                                          userInfo:nil]];
        }
        
        return [AWSTask taskWithResult:authResponse];
    }];
}

- (NSString *)buildLoginRequestUrl:(NSString *)username password:(NSString *)password {
    

    return [NSString stringWithFormat:LoginURI, self.endpoint, username, password];
}

- (NSString *)buildGetTokenRequestUrl:(NSString *)identityId logins:(NSDictionary *)logins {
    
    NSString* username = [logins objectForKey:@"login.testproject.testPHPCognitoId"];
    
    return [NSString stringWithFormat:GetTokenURI, self.endpoint, self.key, username];
}


@end
