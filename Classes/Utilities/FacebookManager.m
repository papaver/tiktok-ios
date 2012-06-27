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
#import "FacebookResult.h"
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
        mConnectHandler = [handler copy];

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

- (void) getFacebookId:(FacebookQuerySuccessHandler)successHandler
           handleError:(FacebookQueryErrorHandler)errorHandler
{
    FacebookResult *result =
        [[[FacebookResult alloc] initWithFacebook:self.facebook] retain];

    // success handler
    result.didLoadHandler = ^(FBRequest* request, id data) {
        if (successHandler != nil) {
            NSDictionary *dict = (NSDictionary*)data;
            NSNumber *userId   = (NSNumber*)[dict objectForKey:@"id"];
            successHandler(userId);
        }
        [result release];
    };

    // error handler
    result.didFailWithErrorHandler = ^(FBRequest* request, NSError* error) {
        if (errorHandler != nil) errorHandler(error);
        [result release];
    };

    // run query
    [self.facebook requestWithGraphPath:@"me" andDelegate:result];
}

//-----------------------------------------------------------------------------

- (void) getAppFriends:(FacebookQuerySuccessHandler)successHandler
           handleError:(FacebookQueryErrorHandler)errorHandler
{
    FacebookResult *result =
        [[[FacebookResult alloc] initWithFacebook:self.facebook] retain];

    // success handler
    result.didLoadHandler = ^(FBRequest* request, id data) {
        if (successHandler != nil) successHandler(data);
        [result release];
    };

    // error handler
    result.didFailWithErrorHandler = ^(FBRequest* request, NSError* error) {
        if (errorHandler != nil) errorHandler(error);
        [result release];
    };

    // setup query
    NSString *fql = $string(
        @"select name, uid, pic_small "
        @"from user "
        @"where is_app_user = 1 and uid in ("
            @"select uid2 "
            @"from friend "
            @"where uid1 = me()) "
        @"order by concat(first_name,last_name) asc");

    // run query
    NSMutableDictionary* params =
        [NSMutableDictionary dictionaryWithObjectsAndKeys:fql, @"query", nil];
    [self.facebook requestWithMethodName:@"fql.query"
                               andParams:params
                           andHttpMethod:@"POST"
                             andDelegate:result];
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

- (NSNumber*) getFacebookUserId
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *userId         = [defaults objectForKey:@"FBUserIdKey"];
    return userId;
}

//-----------------------------------------------------------------------------

- (void) saveFacebookUserId:(NSNumber*)userId
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:userId forKey:@"FBUserIdKey"];
    [defaults synchronize];

    // push facebook token to server
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    [api updateSettings:$dict($array(@"fb_id"), $array(userId))];
}

//-----------------------------------------------------------------------------
#pragma - FacebookDelegate
//-----------------------------------------------------------------------------

- (void) fbDidLogin
{
    [self saveFacebookData];

    // run handler if setup
    if (mConnectHandler != nil) {
        mConnectHandler();

        // release handler
        [mConnectHandler release];
        mConnectHandler = nil;
    }
}

//-----------------------------------------------------------------------------

- (void) fbDidNotLogin:(BOOL)cancelled
{
}

//-----------------------------------------------------------------------------

- (void) fbDidExtendToken:(NSString*)accessToken
                expiresAt:(NSDate*)expiresAt;
{
    self.facebook.accessToken    = accessToken;
    self.facebook.expirationDate = expiresAt;
    [self saveFacebookData];
}

//-----------------------------------------------------------------------------

- (void) fbDidLogout
{
    [self clearFacebookData];
}

//-----------------------------------------------------------------------------

- (void) fbSessionInvalidated
{
    [self clearFacebookData];
}

//-----------------------------------------------------------------------------
#pragma - Memory Management
//-----------------------------------------------------------------------------

- (void) dealloc
{
    [mConnectHandler release];
    [mFacebook release];
    [super dealloc];
}

//-----------------------------------------------------------------------------

@end
