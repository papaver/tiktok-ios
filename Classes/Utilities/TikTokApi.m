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

#import "TikTokApi.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "Coupon.h"
#import "Database.h"
#import "Merchant.h"
#import "Utilities.h"

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface TikTokApi ()
    + (NSString*) apiUrlPath;
    - (void) parseData:(NSData*)data;
    - (void) parseRegistrationId:(NSDictionary*)data;
    - (void) parseCouponData:(NSDictionary*)data;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation TikTokApi

//------------------------------------------------------------------------------

@synthesize adapter           = mAdapter;
@synthesize parser            = mParser;
@synthesize jsonData          = mJsonData;
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

        // setup the json parser adapter
        self.adapter          = [SBJsonStreamParserAdapter new];
        self.adapter.delegate = self;

        // setup the json parser
        self.parser          = [SBJsonStreamParser new];
        self.parser.delegate = self.adapter;

        // initialize merchant array
        self.jsonData = [[NSMutableArray alloc] init];

        // setup the job queue
        mQueue = dispatch_queue_create("com.tiktok.tiktok.api", NULL);
    }

    return self;
}

//------------------------------------------------------------------------------

- (void) dealloc
{
    dispatch_release(mQueue);
     
    mAdapter.delegate = nil;
    mParser.delegate  = nil;

    [mAdapter  release];
    [mParser   release];
    [mJsonData release];

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
    Database *database    = [Database getInstance];
    if (database.context != nil) {
        mManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType]; 
        [mManagedObjectContext setPersistentStoreCoordinator:database.coordinator];
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
    [request setCompletionBlock:^{

        // parse data
        mParserMethod = NSSelectorFromString(@"parseRegistrationId:");
        [self parseData:[request responseData]];

        // run handler
        if (self.completionHandler) self.completionHandler(request);
    }];

    // set error handler
    [request setFailedBlock:^{
        NSLog(@"TikTokApi: Failed to register deviceId: %@", [request error]);
        if (self.errorHandler) self.errorHandler(request);
    }];

    // clear out the cache
    [self.jsonData removeAllObjects];
 
    // initiate the request
    [request startAsynchronous];
}

//------------------------------------------------------------------------------

- (void) validateRegistration
{
    // construct the checkin url path 
    NSURL *url = [[[NSURL alloc] initWithString:
        $string(@"%@/consumers/%@/registered", [TikTokApi apiUrlPath], 
            [Utilities getConsumerId])] 
        autorelease];

    // setup the async request
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setCompletionBlock:^{
        if (self.completionHandler) self.completionHandler(request);
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
    // construct the checkin url path 
    NSURL *url = [[[NSURL alloc] initWithString:
        $string(@"%@/consumers/%@", [TikTokApi apiUrlPath], [Utilities getConsumerId])] 
        autorelease];

    // need the token as a string
    NSString *tokenTrimmed = [token stringByTrimmingCharactersInSet:
        [NSCharacterSet characterSetWithCharactersInString:@"<>"]];

    // setup the async request
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setRequestMethod:@"PUT"];
    [request setPostValue:tokenTrimmed forKey:@"token"];
    [request setCompletionBlock:^{
        if (self.completionHandler) self.completionHandler(request);
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

- (void) syncActiveCoupons
{
    NSURL *url = [[[NSURL alloc] initWithString:
        $string(@"%@/consumers/%@/coupons", [TikTokApi apiUrlPath], [Utilities getConsumerId])] 
        autorelease];

    // setup the async request
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setCompletionBlock:^{

        // parse data
        dispatch_async(mQueue, ^(void) {
            mParserMethod = NSSelectorFromString(@"parseCouponData:");
            [self parseData:[request responseData]];

            // save data in the context
            NSError *error = nil;
            [self.context save:&error];
            if (error) NSLog(@"TikTokApi: failed to save context: %@", error);
                
            // run handler
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                if (self.completionHandler) self.completionHandler(request);
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

/** 
 * Parse the given data using the SBJson parser. 
 */ 
- (void) parseData:(NSData*)data
{
    // parse the json results
    SBJsonStreamParserStatus status = [self.parser parse:data];
    if (status == SBJsonStreamParserError) {
        NSLog(@"json parser error: %@", self.parser.error);
    } else if (status == SBJsonStreamParserWaitingForData) {
        NSLog(@"json parser: waiting for more data.");
    }
}

//------------------------------------------------------------------------------
#pragma mark - Custom JSON Parserers
//------------------------------------------------------------------------------

- (void) parseRegistrationId:(NSDictionary*)data
{
    NSNumber *customerId = [data objectForKey:@"id"];
    NSLog(@"TikTokApi: parsed customer id -> %@", customerId);
    [self.jsonData addObject:$string(@"%@", customerId)];
}

//------------------------------------------------------------------------------

- (void) parseCouponData:(NSDictionary*)data
{
    // create merchant from json 
    NSDictionary *merchantData = [data objectForKey:@"merchant"];
    Merchant *merchant = 
        [Merchant getOrCreateMerchantWithJsonData:merchantData 
                                      fromContext:self.context];

    // skip out if we can't retrive a merchant from the checkin
    if (merchant == nil) {
        NSLog(@"failed to parse merchant.");
        return;
    }

    // create coupon from json
    Coupon *coupon = [Coupon getOrCreateCouponWithJsonData:data 
                                               fromContext:self.context];
    
    // save coupon in cache
    [self.jsonData addObject:coupon];
}

//------------------------------------------------------------------------------
#pragma mark - SBJsonStreamParserAdapterDelegate
//------------------------------------------------------------------------------

/**
 * Called when a JSON array is found.
 */
- (void) parser:(SBJsonStreamParser*)parser foundArray:(NSArray*)array
{
    //NSLog(@"json: array found.");
    for (NSDictionary *data in array) {
        [self performSelector:mParserMethod withObject:data];
    }
}

//------------------------------------------------------------------------------

/**
 * Called when a JSON object is found.
 */
- (void) parser:(SBJsonStreamParser*)parser foundObject:(NSDictionary*)dict
{
    //NSLog(@"json: dictionary found.");
    [self performSelector:mParserMethod withObject:dict];
}

//------------------------------------------------------------------------------

@end
