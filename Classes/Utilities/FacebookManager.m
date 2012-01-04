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
#pragma - methods
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
    [mFacebook release];
    [super dealloc];
}

//-----------------------------------------------------------------------------

@end
