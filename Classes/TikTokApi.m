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

@synthesize adapter        = m_adapter;
@synthesize parser         = m_parser;
@synthesize jsonData       = m_json_data;
@synthesize managedContext = m_managed_context;

//------------------------------------------------------------------------------

static NSData *s_device_token;

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark statics
//------------------------------------------------------------------------------

+ (NSData*) deviceToken
{
    return s_device_token;
}

//------------------------------------------------------------------------------

+ (void) setDeviceToken:(NSData*)deviceToken
{
    // release current token if it exists
    if (s_device_token != nil) {
        [s_device_token release];
    }

    // set new device token
    s_device_token = deviceToken;
    [s_device_token retain];

    NSLog(@"TikTokApi: Setting device token: %@", [s_device_token description]);
}

//------------------------------------------------------------------------------

+ (NSString*) apiUrlPath
{
    return @"http://electric-dusk-7349.herokuapp.com/";
}

//------------------------------------------------------------------------------

+ (NSData*) httpQueryWithUrlPath:(NSString*)url_path andPostData:(NSString*)post_data
{
    NSLog(@"post data -> %@", post_data);

    // create a url object from the path
    NSURL *url = [[[NSURL alloc] initWithString:url_path] autorelease];

    // setup the post data for the url
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[post_data dataUsingEncoding:NSUTF8StringEncoding]];

    // retrive data
    NSURLResponse *response;
    NSError *error;
    NSData *data = [NSURLConnection sendSynchronousRequest:request 
                                         returningResponse:&response 
                                                     error:&error];

    return data;
}

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Object
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
        self.parser.multi    = YES;

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
    NSString *url_path = [NSString stringWithFormat:@"%@/checkins", 
        [TikTokApi apiUrlPath]];

    // convert token data into a string
    NSString *deviceTokenStr = 
        [[[TikTokApi deviceToken] description] stringByTrimmingCharactersInSet:
            [NSCharacterSet characterSetWithCharactersInString:@"<>"]];

    // setup the post data for the url
    NSString *post_data = [NSString stringWithFormat:@"token=%@&lat=%lf&long=%lf", 
        deviceTokenStr, latitude, longitude];

    // attempt to checkin with the server
    NSData* data = [TikTokApi httpQueryWithUrlPath:url_path 
                                                  andPostData:post_data];
    NSLog(@"api data -> %s", (char*)[data bytes]);

    // clear out the cache
    [self.jsonData removeAllObjects];

    // set the parser for the incoming json data
    m_parser_method = NSSelectorFromString(@"parseLocationData:");

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
    NSString *url_path = [NSString stringWithFormat:@"%@/checkout", 
        [TikTokApi apiUrlPath]];

    // convert token data into a string
    NSString *deviceTokenStr = 
        [[[TikTokApi deviceToken] description] stringByTrimmingCharactersInSet:
            [NSCharacterSet characterSetWithCharactersInString:@"<>"]];

    // setup the post data for the url
    NSString *post_data = [NSString stringWithFormat:@"token=%@", deviceTokenStr];

    // attempt to checkin with the server
    [TikTokApi httpQueryWithUrlPath:url_path andPostData:post_data];

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
    NSLog(@"active coupons -> %s", (char*)[data bytes]);

    // clear out the cache
    [self.jsonData removeAllObjects];

    // set the parser for the incoming json data
    m_parser_method = NSSelectorFromString(@"parseCouponData:");

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
#pragma mark -
#pragma mark Custom JSON Parserers
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

    NSLog(@"merchant: %@", merchant.name);
    NSLog(@"coupon: %@", coupon.description);

    // save merchant in cache
    [self.jsonData addObject:merchant];
}

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark SBJsonStreamParserAdapterDelegate
//------------------------------------------------------------------------------

/**
 * Called when a JSON array is found.
 */
- (void) parser:(SBJsonStreamParser*)parser foundArray:(NSArray*)array
{
    NSLog(@"json: array found.");

    for (NSDictionary *data in array) {
        [self performSelector:m_parser_method withObject:data];
    }
}

//------------------------------------------------------------------------------

/**
 * Called when a JSON object is found.
 */
- (void) parser:(SBJsonStreamParser*)parser foundObject:(NSDictionary*)dict
{
    NSLog(@"json: dictionary found.");

    [self performSelector:m_parser_method withObject:dict];
}

//------------------------------------------------------------------------------

@end
