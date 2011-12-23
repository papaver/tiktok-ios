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
#import "Merchant.h"
#import "Coupon.h"
#import "Location.h"

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation TikTokApi

//------------------------------------------------------------------------------

@synthesize adapter        = mAdapter;
@synthesize parser         = mParser;
@synthesize jsonData       = mJsonData;
@synthesize managedContext = mManagedContext;

//------------------------------------------------------------------------------

static NSData *sDeviceToken;

//------------------------------------------------------------------------------
#pragma mark - Statics
//------------------------------------------------------------------------------

+ (NSData*) deviceToken
{
    return sDeviceToken;
}

//------------------------------------------------------------------------------

+ (void) setDeviceToken:(NSData*)deviceToken
{
    // release current token if it exists
    if (sDeviceToken != nil) [sDeviceToken release];

    // set new device token
    sDeviceToken = deviceToken;
    [sDeviceToken retain];

    NSLog(@"TikTokApi: Setting device token: %@", [sDeviceToken description]);
}

//------------------------------------------------------------------------------

+ (NSString*) apiUrlPath
{
    return @"http://electric-dusk-7349.herokuapp.com/";
}

//------------------------------------------------------------------------------

+ (NSData*) httpQueryWithUrlPath:(NSString*)urlPath andPostData:(NSString*)postData
{
    NSLog(@"post data -> %@", postData);

    // create a url object from the path
    NSURL *url = [[[NSURL alloc] initWithString:urlPath] autorelease];

    // setup the post data for the url
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];

    // retrive data
    NSURLResponse *response;
    NSError *error;
    NSData *data = [NSURLConnection sendSynchronousRequest:request 
                                         returningResponse:&response 
                                                     error:&error];

    return data;
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
    }

    return self;
}

//------------------------------------------------------------------------------

- (void) dealloc
{
    [self.adapter  release];
    [self.parser   release];
    [self.jsonData release];

    [super dealloc];
}

//------------------------------------------------------------------------------

- (Location*) checkInWithCurrentLocation:(CLLocation*)location
{
    CLLocationDegrees latitude  = location.coordinate.latitude;
    CLLocationDegrees longitude = location.coordinate.longitude;

    // construct the checkin url path 
    NSString *urlPath = [NSString stringWithFormat:@"%@/register", 
        [TikTokApi apiUrlPath]];

    // convert token data into a string
    NSString *deviceTokenStr = 
        [[[TikTokApi deviceToken] description] stringByTrimmingCharactersInSet:
            [NSCharacterSet characterSetWithCharactersInString:@"<>"]];

    // setup the post data for the url
    NSString *postData = [NSString stringWithFormat:@"token=%@&lat=%lf&long=%lf", 
        deviceTokenStr, latitude, longitude];

    // attempt to checkin with the server
    NSData* data = [TikTokApi httpQueryWithUrlPath:urlPath 
                                       andPostData:postData];
    NSLog(@"api data -> %s", (char*)[data bytes]);

    // clear out the cache
    [self.jsonData removeAllObjects];

    // set the parser for the incoming json data
    mParserMethod = NSSelectorFromString(@"parseLocationData:");

    [self parseData:data];

    // return location if found
    if (self.jsonData.count != 0) {
        return [self.jsonData objectAtIndex:0];
    } else {
        return nil;
    }
}

//------------------------------------------------------------------------------

- (bool) checkOut
{
    // construct the checkin url path 
    NSString *urlPath = [NSString stringWithFormat:@"%@/checkout", 
        [TikTokApi apiUrlPath]];

    // convert token data into a string
    NSString *deviceTokenStr = 
        [[[TikTokApi deviceToken] description] stringByTrimmingCharactersInSet:
            [NSCharacterSet characterSetWithCharactersInString:@"<>"]];

    // setup the post data for the url
    NSString *postData = [NSString stringWithFormat:@"token=%@", deviceTokenStr];

    // attempt to checkin with the server
    [TikTokApi httpQueryWithUrlPath:urlPath andPostData:postData];

    return YES;
}

//------------------------------------------------------------------------------

- (NSMutableArray*) getActiveCoupons
{
    // need the token as a string
    NSString *deviceTokenStr = [[[[TikTokApi deviceToken] description]
        stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]]
        stringByReplacingOccurrencesOfString:@" " 
        withString:@"%20"];

    NSURL *url = [[[NSURL alloc] initWithString:
        [NSString stringWithFormat:@"%@/coupons?token=%@", 
            [TikTokApi apiUrlPath], deviceTokenStr]] autorelease];

    // query data from the server
    NSData *data = [[[NSData alloc] initWithContentsOfURL:url] autorelease];
    //NSLog(@"active coupons -> %s", (char*)[data bytes]);

    // clear out the cache
    [self.jsonData removeAllObjects];

    // set the parser for the incoming json data
    mParserMethod = NSSelectorFromString(@"parseCouponData:");

    [self parseData:data];

    return self.jsonData;
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

- (void) parseLocationData:(NSDictionary*)data
{
    // parse the location data
    NSDictionary *locationData = [data objectForKey:@"checkin_point"];
    Location *location = 
        [Location getOrCreateLocationWithJsonData:locationData 
                                      fromContext:self.managedContext];

    // skip out if we can't retrive a location from the checkin
    if (location == nil) {
        NSLog(@"failed to parse location on checkin.");
        return;
    }

    // -- debug --
    NSLog(@"parsed location: %@", location ? location.name : @"nil");

    // parse the coupon data
    for (NSDictionary *couponData in [data objectForKey:@"coupons"]) {
        [self parseCouponData:couponData];
    }
}

//------------------------------------------------------------------------------

- (void) parseCouponData:(NSDictionary*)data
{
    // create merchant from json 
    NSDictionary *merchantData = [data objectForKey:@"merchant"];
    Merchant *merchant = 
        [Merchant getOrCreateMerchantWithJsonData:merchantData 
                                      fromContext:self.managedContext];

    // skip out if we can't retrive a merchant from the checkin
    if (merchant == nil) {
        NSLog(@"failed to parse merchant.");
        return;
    }

    // -- debug --
    NSLog(@"parsed merchant: %@", merchant ? merchant.name : @"nil");

    // create coupon from json
    Coupon *coupon = 
        [Coupon getOrCreateCouponWithJsonData:data 
                                  fromContext:self.managedContext];
    
    // add coupon to merchant
    //[merchant addCouponObject:coupon];

    //NSLog(@"merchant: %@", merchant.name);
    //NSLog(@"coupon: %@", coupon.description);

    // save merchant in cache
    [self.jsonData addObject:merchant];
}

//------------------------------------------------------------------------------
#pragma mark - SBJsonStreamParserAdapterDelegate
//------------------------------------------------------------------------------

/**
 * Called when a JSON array is found.
 */
- (void) parser:(SBJsonStreamParser*)parser foundArray:(NSArray*)array
{
    NSLog(@"json: array found.");

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
    NSLog(@"json: dictionary found.");

    [self performSelector:mParserMethod withObject:dict];
}

//------------------------------------------------------------------------------

@end
