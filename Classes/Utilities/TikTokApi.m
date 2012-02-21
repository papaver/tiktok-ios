//
//  TikTokApi.m
//  TikTok
//
//  Created by Moiz Merchant on 4/30/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports 
//------------------------------------------------------------------------------

#import <assert.h>
#import "TikTokApi.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "Coupon.h"
#import "Debug.h"
#import "Database.h"
#import "JSONKit.h"
#import "Merchant.h"
#import "Utilities.h"

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface TikTokApi ()
    + (NSString*) apiUrlPath;
    - (void) parseCouponData:(NSDictionary*)data
                 withContext:(NSManagedObjectContext*)context;
    - (void) parseCoupon:(NSDictionary*)couponData
             withContext:(NSManagedObjectContext*)context;
    - (void) syncManagedObjects:(NSNotification*)notification;
    - (void) killCoupons:(NSArray*)killed fromContext:(NSManagedObjectContext*)context;
    - (void) sellOutCoupons:(NSArray*)soldOut fromContext:(NSManagedObjectContext*)context;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation TikTokApi

//------------------------------------------------------------------------------

@synthesize timeOut           = mTimeOut;
@synthesize completionHandler = mCompletionHandler;
@synthesize errorHandler      = mErrorHandler;

//------------------------------------------------------------------------------
#pragma mark - Statics
//------------------------------------------------------------------------------

+ (NSString*) apiUrlPath
{
    if (TIKTOKAPI_STAGING) {
        return @"https://furious-window-5155.herokuapp.com";
    } else {
        return @"https://www.tiktok.com";
    }
}

//------------------------------------------------------------------------------
#pragma mark - Object
//------------------------------------------------------------------------------

- (id) init
{
    self = [super init];
    if (self) {

        // setup the job queue
        mQueue = dispatch_queue_create("com.tiktok.tiktok.api", NULL);

        // set the default timeout
        self.timeOut = [ASIHTTPRequest defaultTimeOutSeconds];
    }

    return self;
}

//------------------------------------------------------------------------------

- (void) dealloc
{
    dispatch_release(mQueue);
    [mManagedObjectContext release];
    [super dealloc];
}

//------------------------------------------------------------------------------

/**
 * Returns the managed object context for the application.  If the context
 * doesn't exist, it is created and bound to the persistant store coordinator.
 */
- (NSManagedObjectContext*) context
{
    // lazy allocation
    if (mManagedObjectContext != nil)  return mManagedObjectContext;

    // allocate the object context and attach it to the persistant storage
    Database *database = [Database getInstance];
    if (database.context != nil) {

        // [iOS4] concurrency type only exists in 5.0+
        NSManagedObjectContext *context = [NSManagedObjectContext alloc];
        if ($has_selector(context, initWithConcurrencyType:)) {
            context = [context initWithConcurrencyType:NSConfinementConcurrencyType];
        } else {
            context = [context init];
        }

        // set the presistance store and save cache the context
        [context setPersistentStoreCoordinator:database.coordinator];
        mManagedObjectContext = [context retain];
    }

    return mManagedObjectContext;
}

//------------------------------------------------------------------------------

- (void) registerDevice:(NSString*)deviceId
{
    // construct the checkin url path 
    NSURL *url = [[[NSURL alloc] initWithString:
        $string(@"%@/register?uuid=%@", [TikTokApi apiUrlPath], deviceId)] 
        autorelease];

    // setup the async request
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setTimeOutSeconds:self.timeOut];
    [request setCompletionBlock:^{
        NSDictionary *response = [[request responseData] objectFromJSONData];
        if (self.completionHandler) self.completionHandler(response);
    }];

    // set error handler
    [request setFailedBlock:^{
        NSLog(@"TikTokApi: Failed to register deviceId: %@", [request error]);
        if (self.errorHandler) self.errorHandler(request);
    }];

    // initiate the request
    [request startAsynchronous];
}

//------------------------------------------------------------------------------

- (void) validateRegistration
{
    // construct the checkin url path 
    NSURL *url = [[[NSURL alloc] initWithString:
        $string(@"%@/consumers/%@/registered?uuid=%@", [TikTokApi apiUrlPath], 
            [Utilities getConsumerId], [Utilities getDeviceId])] 
        autorelease];

    // setup the async request
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setTimeOutSeconds:self.timeOut];
    [request setCompletionBlock:^{
        NSDictionary *response = [[request responseData] objectFromJSONData];
        if (self.completionHandler) self.completionHandler(response);
    }];

    // set error handler
    [request setFailedBlock:^{
        NSLog(@"TikTokApi: Failed validate device registration: %@", [request error]);
        if (self.errorHandler) self.errorHandler(request);
    }];

    // initiate the request
    [request startAsynchronous];
}

//------------------------------------------------------------------------------

- (void) registerNotificationToken:(NSString*)token
{
    // construct the consumer settings url path 
    NSURL *url = [[[NSURL alloc] initWithString:
        $string(@"%@/consumers/%@", [TikTokApi apiUrlPath], [Utilities getConsumerId])] 
        autorelease];

    // need the token as a string
    NSString *tokenTrimmed = [token stringByTrimmingCharactersInSet:
        [NSCharacterSet characterSetWithCharactersInString:@"<>"]];

    // setup the async request
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setTimeOutSeconds:self.timeOut];
    [request setRequestMethod:@"PUT"];
    [request setPostValue:tokenTrimmed forKey:@"token"];
    [request setCompletionBlock:^{
        NSDictionary *response = [[request responseData] objectFromJSONData];
        if (self.completionHandler) self.completionHandler(response);
    }];

    // set error handler
    [request setFailedBlock:^{
        NSLog(@"TikTokApi: Failed to register notification token: %@", [request error]);
        if (self.errorHandler) self.errorHandler(request);
    }];

    // initiate the request
    [request startAsynchronous];
}

//------------------------------------------------------------------------------

- (void) syncActiveCoupons:(NSDate*)date
{
    NSString *syncPath = $string(@"%@/consumers/%@/coupons", 
        [TikTokApi apiUrlPath], [Utilities getConsumerId]);

    // add last update time 
    if (date) {
        syncPath = $string(@"%@/?min_time=%f", syncPath, [date timeIntervalSince1970]);
    }

    // construct url
    NSURL *url = [[[NSURL alloc] initWithString:syncPath] autorelease];

    // setup the async request
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setTimeOutSeconds:self.timeOut];
    [request setCompletionBlock:^{

        // [moiz] this doesn't seem like the best idea, to get notifications from
        //   any context, but if the attach block is run inside another thead
        //   notification seem to break, ex, redeemed sash doesn't show up in the
        //   deal view when deal is redeemed...

        // [iOS4] I can't get this shit working using multiple threads on on iOS4.
        //   Keep gettings tons of merge conflict bullshit.  tried all sorts of
        //   variations of using main thread and queue, nothing seems to help, so
        //   only thread on iOS5+

        NSDictionary *response = [[request responseData] objectFromJSONData];
        Database *database     = [Database getInstance];
        BOOL runASync          = $has_selector(database.context, initWithConcurrencyType:);

        // convert the json data into managed objects
        dispatch_block_t parseData = ^{
            NSManagedObjectContext *context = runASync ? self.context : database.context;
            [self parseCouponData:response withContext:context];
        };

        // run completion handler and cleanup notification registration
        dispatch_block_t cleanup = ^{
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            if (self.completionHandler) self.completionHandler(response);
        };

        // setup notifiation for object updates
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(syncManagedObjects:)
                                   name:NSManagedObjectContextDidSaveNotification
                                 object:nil];

        // parse the data on another thread
        if (runASync) {
            dispatch_async(mQueue, ^(void) {
                parseData();
                dispatch_async(dispatch_get_main_queue(), cleanup);
            });

        // [iOS4] run on main thread
        } else {
            parseData();
            cleanup();
        }
    }];

    // set error handler
    [request setFailedBlock:^{
        NSLog(@"TikTokApi: Failed to sync coupons: %@", [request error]);
        if (self.errorHandler) self.errorHandler(request);
    }];
 
    // initiate the request
    [request startAsynchronous];
}

//------------------------------------------------------------------------------

- (void) syncManagedObjects:(NSNotification*)notification
{
    // make sure the update happens on the main thread!
    Database *database = [Database getInstance];
    SEL selector = @selector(mergeChangesFromContextDidSaveNotification:);
    [database.context performSelectorOnMainThread:selector 
                                       withObject:notification 
                                    waitUntilDone:YES];
}

//------------------------------------------------------------------------------

- (void) updateCurrentLocation:(CLLocationCoordinate2D)coordinate
{
    // construct the consumer settings url path 
    NSURL *url = [[[NSURL alloc] initWithString:
        $string(@"%@/consumers/%@", [TikTokApi apiUrlPath], [Utilities getConsumerId])] 
        autorelease];

    // convert to objects
    NSNumber *latitude  = $numd(coordinate.latitude);
    NSNumber *longitude = $numd(coordinate.longitude);

    // setup the async request
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setTimeOutSeconds:self.timeOut];
    [request setRequestMethod:@"PUT"];
    [request setPostValue:latitude forKey:@"latitude"];
    [request setPostValue:longitude forKey:@"longitude"];
    [request setCompletionBlock:^{
        NSDictionary *response = [[request responseData] objectFromJSONData];
        if (self.completionHandler) self.completionHandler(response);
    }];

    // set error handler
    [request setFailedBlock:^{
        NSLog(@"TikTokApi: Failed to push current location: %@", [request error]);
        if (self.errorHandler) self.errorHandler(request);
    }];

    // initiate the request
    [request startAsynchronous];
}

//------------------------------------------------------------------------------

- (void) updateSettings:(NSDictionary*)settings
{
    // construct the consumer settings url path 
    NSURL *url = [[[NSURL alloc] initWithString:
        $string(@"%@/consumers/%@", [TikTokApi apiUrlPath], [Utilities getConsumerId])] 
        autorelease];

    // setup the async request
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setTimeOutSeconds:self.timeOut];
    [request setRequestMethod:@"PUT"];

    // add settings in dictionary
    for (NSString* key in [settings allKeys]) {
        NSString* value = [settings objectForKey:key];
        [request setPostValue:key forKey:value];
    }

    // set completion handler
    [request setCompletionBlock:^{
        NSDictionary *response = [[request responseData] objectFromJSONData];
        if (self.completionHandler) self.completionHandler(response);
    }];

    // set error handler
    [request setFailedBlock:^{
        NSLog(@"TikTokApi: Failed to push current location: %@", [request error]);
        if (self.errorHandler) self.errorHandler(request);
    }];

    // initiate the request
    [request startAsynchronous];
}

//------------------------------------------------------------------------------

- (void) updateSettingsHomeLocation:(CLLocation*)home
{
    // convert to objects
    NSString *latitude  = $string(@"%f", home.coordinate.latitude);
    NSString *longitude = $string(@"%f", home.coordinate.longitude);

    // create dictionary with data to be updated
    NSDictionary *settings = $dict(
        $array(@"home_latitude", @"home_longitude"),
        $array(latitude, longitude));

    // push the settings to the server
    [self updateSettings:settings];
}

//------------------------------------------------------------------------------

- (void) updateSettingsWorkLocation:(CLLocation*)work
{
    // convert to objects
    NSString *latitude  = $string(@"%f", work.coordinate.latitude);
    NSString *longitude = $string(@"%f", work.coordinate.longitude);

    // create dictionary with data to be updated
    NSDictionary *settings = $dict(
        $array(@"work_latitude", @"work_longitude"),
        $array(latitude, longitude));

    // push the settings to the server
    [self updateSettings:settings];
}

//------------------------------------------------------------------------------

- (void) updateCoupon:(NSNumber*)couponId 
            attribute:(TikTokApiCouponAttribute)attribute
{
    // attribute table mapping enums to attribute strings
    static struct AttributeMapping {
        TikTokApiCouponAttribute e;
        NSString *attr; 
    } sAttributeTable[6] = {
        { kTikTokApiCouponAttributeRedeem     , @"redeem" },
        { kTikTokApiCouponAttributeFacebook   , @"fb"     },
        { kTikTokApiCouponAttributeTwitter    , @"tw"     },
        { kTikTokApiCouponAttributeGooglePlus , @"gplus"  },
        { kTikTokApiCouponAttributeSMS        , @"sms"    },
        { kTikTokApiCouponAttributeEmail      , @"email"  },
    };

    // construct the coupon attribute url path 
    NSURL *url = [[[NSURL alloc] initWithString:
        $string(@"%@/consumers/%@/coupons/%@", 
            [TikTokApi apiUrlPath], [Utilities getConsumerId], couponId)] 
        autorelease];

    // have to convert to number object to use with request
    NSNumber *one = $numi(1);

    // grab string representing attribute
    struct AttributeMapping mapping = sAttributeTable[attribute];
    assert(mapping.e == attribute);

    // setup the async request
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setTimeOutSeconds:self.timeOut];
    [request setRequestMethod:@"PUT"];
    [request setPostValue:one forKey:mapping.attr];
    [request setCompletionBlock:^{
        NSDictionary *response = [[request responseData] objectFromJSONData];
        if (self.completionHandler) self.completionHandler(response);
    }];

    // set error handler
    [request setFailedBlock:^{
        NSLog(@"TikTokApi: Failed to push coupon attribute '%@': %@", 
            mapping.attr, [request error]);
        if (self.errorHandler) self.errorHandler(request);
    }];

    // initiate the request
    [request startAsynchronous];
}

//------------------------------------------------------------------------------

- (void) syncKarmaPoints
{
    NSString *syncPath = $string(@"%@/consumers/%@/loyalty_points",
        [TikTokApi apiUrlPath], [Utilities getConsumerId]);

    // construct url
    NSURL *url = [[[NSURL alloc] initWithString:syncPath] autorelease];

    // setup the async request
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setTimeOutSeconds:self.timeOut];
    [request setCompletionBlock:^{
        NSDictionary *response = [[request responseData] objectFromJSONData];
        if (self.completionHandler) self.completionHandler(response);
    }];

    // set error handler
    [request setFailedBlock:^{
        NSLog(@"TikTokApi: Failed to sync karma points: %@", [request error]);
        if (self.errorHandler) self.errorHandler(request);
    }];

    // initiate the request
    [request startAsynchronous];
}

//------------------------------------------------------------------------------
#pragma mark - Json Parserers
//------------------------------------------------------------------------------

- (void) parseCouponData:(NSDictionary*)response
             withContext:(NSManagedObjectContext*)context
{
    NSString *status = [response objectForKey:kTikTokApiKeyStatus];
    if ([status isEqualToString:kTikTokApiStatusOkay]) {
        NSDictionary *results = [response objectForKey:kTikTokApiKeyResults];

        // parse the new coupons
        NSDictionary *coupons = [results objectForKey:@"coupons"];
        for (NSDictionary *couponData in coupons) {
            [self parseCoupon:couponData withContext:context];
        }

        // update any killed coupons
        NSArray *killed = [results objectForKey:@"killed"];
        if (killed.count) {
            [self killCoupons:killed fromContext:context];
        }

        // update any sold out coupons
        NSArray *soldOut = [results objectForKey:@"sold_out"];
        if (soldOut.count) {
            [self sellOutCoupons:soldOut fromContext:context];
        }
    }
}

//------------------------------------------------------------------------------

- (void) parseCoupon:(NSDictionary*)couponData
         withContext:(NSManagedObjectContext*)context
{
    [Coupon getOrCreateCouponWithJsonData:couponData fromContext:context];
}

//------------------------------------------------------------------------------

- (void) killCoupons:(NSArray*)killed fromContext:(NSManagedObjectContext*)context
{
    for (NSNumber* couponId in killed) {
        Coupon *coupon = [Coupon getCouponById:couponId fromContext:context];
        if (coupon) [context deleteObject:coupon];
    }

    // save the context
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"killed coupon save failed: %@", error);
    }
}

//------------------------------------------------------------------------------

- (void) sellOutCoupons:(NSArray*)soldOut fromContext:(NSManagedObjectContext*)context
{
    for (NSNumber* couponId in soldOut) {
        Coupon *coupon = [Coupon getCouponById:couponId fromContext:context];
        if (!coupon.isSoldOut.boolValue) coupon.isSoldOut = $numb(YES);
    }

    // save the context
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"sold out coupon save failed: %@", error);
    }
}

//------------------------------------------------------------------------------

@end
