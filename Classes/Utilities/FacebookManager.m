//
//  FacebookManager.m
//  TikTok
//
//  Created by Moiz Merchant on 01/03/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes 
//-----------------------------------------------------------------------------

#import "FacebookManager.h"
#import "Constants.h"
#import "TikTokApi.h"

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface FacebookManager ()
    - (void) loadFacebookData;
    - (void) saveFacebookData;
    - (void) clearFacebookData;
@end

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation FacebookManager

//-----------------------------------------------------------------------------

@synthesize facebook = mFacebook;

//-----------------------------------------------------------------------------

+ (FacebookManager*) getInstance
{
    static FacebookManager *sFacebookManager = nil;
    if (!sFacebookManager) {
        sFacebookManager = [[[FacebookManager alloc] init] retain];
    }
    return sFacebookManager;
}

//-----------------------------------------------------------------------------
#pragma - Initialization
//-----------------------------------------------------------------------------

- (id) init
{
    self = [super init];
    if (self) {
         self.facebook = [[[Facebook alloc] 
             initWithAppId:FACEBOOK_API_KEY andDelegate:self] autorelease];
         [self loadFacebookData];
    }
    return self;
}

//-----------------------------------------------------------------------------
#pragma - Public Api
//-----------------------------------------------------------------------------

- (void) authorizeWithSucessHandler:(FacebookConnectSuccessHandler)handler
{
    if (![self.facebook isSessionValid]) {
        mSuccessHandler = [handler copy];

        // permission to request from user
        NSArray *permissions = [[NSArray alloc] initWithObjects:
            @"user_likes", 
            @"user_birthday",
            @"user_checkins",
            @"user_interests",
            @"user_location",
            @"user_relationships",
            @"user_relationship_details",
            @"offline_access",
            @"publish_stream",
            nil];
        [self.facebook authorize:permissions];
        [permissions release];
    }
}

//-----------------------------------------------------------------------------
#pragma - Methods
//-----------------------------------------------------------------------------

- (void) loadFacebookData
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *accessToken    = [defaults objectForKey:@"FBAccessTokenKey"];
    NSDate *expirationDate   = [defaults objectForKey:@"FBExpirationDateKey"];
    if (accessToken && expirationDate) {
        self.facebook.accessToken    = accessToken;
        self.facebook.expirationDate = expirationDate;
    }
}

//-----------------------------------------------------------------------------

- (void) saveFacebookData
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self.facebook accessToken]    forKey:@"FBAccessTokenKey"];
    [defaults setObject:[self.facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];

    // push facebook token to server
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    [api updateSettings:$dict($array(@"fb"), $array(self.facebook.accessToken))];
}

//-----------------------------------------------------------------------------

- (void) clearFacebookData
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"FBAccessTokenKey"]) {
        [defaults removeObjectForKey:@"FBAccessTokenKey"];
        [defaults removeObjectForKey:@"FBExpirationDateKey"];
        [defaults synchronize];
    }
}

//-----------------------------------------------------------------------------
#pragma - FacebookDelegate
//-----------------------------------------------------------------------------

- (void) fbDidLogin 
{
    [self saveFacebookData];

    // run handler if setup
    if (mSuccessHandler != nil) {
        mSuccessHandler();

        // release handler
        [mSuccessHandler release];
        mSuccessHandler = nil;
    }
}

//-----------------------------------------------------------------------------

- (void) fbDidLogout 
{
    [self clearFacebookData];
}

//-----------------------------------------------------------------------------
#pragma - Memory Management
//-----------------------------------------------------------------------------

- (void) dealloc
{
    [mSuccessHandler release];
    [mFacebook release];
    [super dealloc];
}

//-----------------------------------------------------------------------------

@end
