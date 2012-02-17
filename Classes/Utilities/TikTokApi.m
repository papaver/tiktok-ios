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
#import "Database.h"
#import "JSONKit.h"
#import "Merchant.h"
#import "Utilities.h"

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface TikTokApi ()
    + (NSString*) apiUrlPath;
    - (void) parseCouponData:(NSDictionary*)data;
    - (void) parseCoupon:(NSDictionary*)couponData;
    - (void) syncManagedObjects:(NSNotification*)notification;
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
    return @"http://electric-dusk-7349.herokuapp.com/";
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

        // add notifications to allow updating of main context
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                            selector:@selector(syncManagedObjects:)
                                name:NSManagedObjectContextDidSaveNotification
                                object:self.context];

        // parse the data on another thread
        dispatch_async(mQueue, ^(void) {

            // convert the json data into managed objects
            NSDictionary *response = [[request responseData] objectFromJSONData];
            [self parseCouponData:response];

            // run completion handler and cleanup notification registration
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [notificationCenter removeObserver:self];
                if (self.completionHandler) self.completionHandler(response);
            });
        });  
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
        { kTikTokApiCouponAttributeTwitter    , @"twit"   },
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
#pragma mark - Json Parserers
//------------------------------------------------------------------------------

- (void) parseCouponData:(NSDictionary*)response
{
    NSString *status = [response objectForKey:kTikTokApiKeyStatus];
    if ([status isEqualToString:kTikTokApiStatusOkay]) {
        NSArray *results = [response objectForKey:kTikTokApiKeyResults];
        for (NSDictionary *couponData in results) {
            [self parseCoupon:couponData];
        }
    }
}

//------------------------------------------------------------------------------

- (void) parseCoupon:(NSDictionary*)couponData
{
    // create merchant from json 
    NSDictionary *merchantData = [couponData objectForKey:@"merchant"];
    Merchant *merchant = 
        [Merchant getOrCreateMerchantWithJsonData:merchantData 
                                      fromContext:self.context];

    // skip out if we can't retrive a merchant from the coupon
    if (merchant == nil) {
        NSLog(@"failed to parse merchant.");
        return;
    }

    // create coupon from json
    [Coupon getOrCreateCouponWithJsonData:couponData 
                              fromContext:self.context];
}

//------------------------------------------------------------------------------

@end
