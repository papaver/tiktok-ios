//
//  GoogleMapsApi.m
//  TikTok
//
//  Created by Moiz Merchant on 4/30/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports 
//------------------------------------------------------------------------------

#import "GoogleMapsApi.h"
#import "ASIHTTPRequest.h"
#import "JSONKit.h"

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface GoogleMapsApi ()
    + (NSString*) apiUrlPath;
    + (NSURL*) urlForDataFromSource:(NSString*)source
                      toDestination:(NSString*)destination;
    + (NSURL*) urlForForwardGeocodingForAddress:(NSString*)address;
    + (NSURL*) urlForReverseGeocodingForAddress:(CLLocationCoordinate2D)coordinate;
    + (NSString*) formatString:(NSString*)string;
    - (NSDictionary*) parseRouteData:(NSData*)data;
    - (NSDictionary*) parseRawRouteData:(NSData*)data;
    - (NSArray*) decodePolyline:(NSString*)polyline;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation GoogleMapsApi

//------------------------------------------------------------------------------

@synthesize completionHandler = mCompletionHandler;
@synthesize errorHandler      = mErrorHandler;

//------------------------------------------------------------------------------
#pragma mark - Statics
//------------------------------------------------------------------------------

+ (NSString*) apiUrlPath
{
    return @"http://maps.google.com/maps";
}

//------------------------------------------------------------------------------

+ (NSURL*) urlForDirectionsFromSource:(NSString*)source toDestination:(NSString*)destination
{
    // properly encode/format the source and destination strings
    source      = [self formatString:source];
    destination = [self formatString:destination];

    // grab the local identifier
    NSString *locale = [[NSLocale currentLocale] localeIdentifier];

    // construct the url path
    NSURL *url = [[[NSURL alloc] initWithString:
        $string(@"%@?saddr=%@&daddr=%@&hl=%@", 
            [GoogleMapsApi apiUrlPath], source, destination, locale)] 
        autorelease];
    return url;
}

//------------------------------------------------------------------------------

+ (NSURL*) urlForDataFromSource:(NSString*)source toDestination:(NSString*)destination
{
    // properly encode/format the source and destination strings
    source      = [self formatString:source];
    destination = [self formatString:destination];

    // grab the local identifier
    NSString *locale = [[NSLocale currentLocale] localeIdentifier];

    // construct the url path
    NSURL *url = [[[NSURL alloc] initWithString:
        $string(@"%@?output=dragdir&saddr=%@&daddr=%@&hl=%@", 
            [GoogleMapsApi apiUrlPath], source, destination, locale)] 
        autorelease];
    return url;
}

//------------------------------------------------------------------------------

+ (NSURL*) urlForForwardGeocodingForAddress:(NSString*)address
{
    // properly encode/format the source and destination strings
    address = [self formatString:address];

    // construct the url path
    NSURL *url = [[[NSURL alloc] initWithString:
        $string(@"%@/api/geocode/json?sensor=false&address=%@",  
            [GoogleMapsApi apiUrlPath], address)]
        autorelease];
    return url;
}

//------------------------------------------------------------------------------

+ (NSURL*) urlForReverseGeocodingForAddress:(CLLocationCoordinate2D)coordinate
{
    // construct the url path
    NSURL *url = [[[NSURL alloc] initWithString:
        $string(@"%@/api/geocode/json?sensor=false&latlng=%f,%f",  
            [GoogleMapsApi apiUrlPath], coordinate.latitude, coordinate.longitude)]
        autorelease];
    return url;
}

//------------------------------------------------------------------------------

+ (NSString*) formatString:(NSString*)string
{
    return [string stringByReplacingOccurrencesOfString:@" " withString:@"+"];
}

//------------------------------------------------------------------------------

+ (NSString*) parseLocality:(NSDictionary*)geoData
{
    static NSArray *keys = nil;
    if (keys == nil) {
        keys = [$array(@"subpremise", @"premise", @"neighborhood",
            @"sublocality", @"locality", @"colloquial_area",
            @"administrative_area_level_3") retain];
    }

    // make sure search results exist
    NSString *status = [geoData objectForKey:@"status"];
    if (!status || [status isEqualToString:@"ZERO_RESULTS"]) {
        return @"Unknown";
    }

    // grab the results from the json data
    NSArray *results = [geoData objectForKey:@"results"];

    // loop through all of the results and get as many fits as possbile
    NSMutableDictionary *localities = [[NSMutableDictionary alloc] init];
    for (NSDictionary *address in results) {
        NSArray *components = [address objectForKey:@"address_components"];
        for (NSDictionary *component in components) {
            for (NSString *key in keys) {

                // skip if the key was already found
                if ([localities objectForKey:key]) continue;

                // add key if it matches the type
                NSArray *types = [component objectForKey:@"types"];
                if ([types containsObject:key]) {
                    NSString *name = [component objectForKey:@"short_name"];
                    [localities setObject:name forKey:key];
                }
            }
        }
    }

    // go through the list and find the smallest locality
    NSString *locality = nil;
    for (NSString *key in keys) {
        NSString *value = [localities objectForKey:key];
        if (value) {
            locality = value;
            break;
        }
    }

    // cleanup
    [localities release];

    return locality ? locality : @"Unknown";
}

//------------------------------------------------------------------------------
#pragma mark - Object
//------------------------------------------------------------------------------

- (id) init
{
    self = [super init];
    if (self) {
        mQueue = dispatch_queue_create("com.tiktok.tiktok.api.googlemaps", NULL);
    }

    return self;
}

//------------------------------------------------------------------------------

- (void) dealloc
{
    dispatch_release(mQueue);
    [super dealloc];
}

//------------------------------------------------------------------------------

- (void) getRouteBetweenSource:(NSString*)source andDestination:(NSString*)destination
{
    NSURL* url = [GoogleMapsApi urlForDataFromSource:source toDestination:destination];

    // setup the async request
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setCompletionBlock:^{

        // parse data
        dispatch_async(mQueue, ^(void) {
            
            // parse the route data 
            NSDictionary *routeData = [self parseRouteData:[request responseData]];
            NSLog(@"data: %@", routeData);

            // run completion handler
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                if (self.completionHandler) self.completionHandler(request, routeData);
            });
        });  
    }];

    // set error handler
    [request setFailedBlock:^{
        NSLog(@"GoogleMapsApi: Failed to query directions: %@", [request error]);
        if (self.errorHandler) self.errorHandler([request error]);
    }];
 
    // initiate the request
    [request startAsynchronous];
}

//------------------------------------------------------------------------------

- (void) getGeocodingForAddress:(NSString*)address
{
    NSURL* url = [GoogleMapsApi urlForForwardGeocodingForAddress:address];

    // setup the async request
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setCompletionBlock:^{

        // parse data
        dispatch_async(mQueue, ^(void) {
            
            // parse the route data 
            NSDictionary *geoData = [[request responseData] objectFromJSONData];

            // run completion handler
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                if (self.completionHandler) self.completionHandler(request, geoData);
            });
        });  
    }];

    // set error handler
    [request setFailedBlock:^{
        NSLog(@"GoogleMapsApi: Failed to query coordinate: %@", [request error]);
        if (self.errorHandler) self.errorHandler([request error]);
    }];
 
    // initiate the request
    [request startAsynchronous];
}

//------------------------------------------------------------------------------

- (void) getReverseGeocodingForAddress:(CLLocationCoordinate2D)coordinate
{
    NSURL* url = [GoogleMapsApi urlForReverseGeocodingForAddress:coordinate];

    // setup the async request
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setCompletionBlock:^{

        // parse data
        dispatch_async(mQueue, ^(void) {
            
            // parse the route data 
            NSDictionary *geoData = [[request responseData] objectFromJSONData];

            // run completion handler
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                if (self.completionHandler) self.completionHandler(request, geoData);
            });
        });  
    }];

    // set error handler
    [request setFailedBlock:^{
        NSLog(@"GoogleMapsApi: Failed to query address: %@", [request error]);
        if (self.errorHandler) self.errorHandler([request error]);
    }];
 
    // initiate the request
    [request startAsynchronous];
}

//------------------------------------------------------------------------------

/** 
 * Parse the route data using the JsonKit parser. 
 */ 
- (NSDictionary*) parseRouteData:(NSData*)data
{
    // parse the json data into a dictionary
    NSDictionary *rawData = [self parseRawRouteData:data];
    if (!rawData) {
        return nil;
    }

    // parse tooltip string for distance and time
    NSString *toolTip = [rawData objectForKey:@"tooltipHtml"];
    NSRegularExpression *regex =
        [NSRegularExpression regularExpressionWithPattern:@"\\(\\s?(.+?)\\s?\\/\\s?(.+?)\\s?\\)"
                                                  options:NSRegularExpressionCaseInsensitive
                                                    error:nil];
    NSTextCheckingResult *match = 
        [regex firstMatchInString:toolTip options:0 range:NSMakeRange(0, [toolTip length])];
    NSString *distance = [toolTip substringWithRange:[match rangeAtIndex:1]];
    NSString *time     = [toolTip substringWithRange:[match rangeAtIndex:2]];

    // decode the the polylines
    NSMutableArray *routes = [[NSMutableArray alloc] init];
    for (NSMutableDictionary *route in [rawData objectForKey:@"polylines"]) {
        NSString *points = [route objectForKey:@"points"];
        [routes addObject:[self decodePolyline:points]];
    }

    // create a new dictionary for the data
    NSDictionary *routeData = $dict(
        $array(@"routes", @"time", @"distance"),
        $array(routes, time, distance));

    // cleanup
    [routes release];

    return routeData;
}

//------------------------------------------------------------------------------

/** 
 * Parse the route data using the JsonKit parser. 
 */ 
- (NSDictionary*) parseRawRouteData:(NSData*)data
{
    // fucking pos google has to send crap data instead of valid json
    NSString *malformedJsonString =
        [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    // match words in front of all colons (hopefully all the dictionary keys)
    NSRegularExpression *regex =
        [NSRegularExpression regularExpressionWithPattern:@"(\\w+):"
                                                  options:NSRegularExpressionCaseInsensitive
                                                    error:nil];

    // quote all the dictionary keys
    NSString *unescapedJsonString =
        [regex stringByReplacingMatchesInString:malformedJsonString
                                        options:0
                                          range:NSMakeRange(0, malformedJsonString.length)
                                   withTemplate:@"\"$1\":"];

    // remove the fucking Š from the string
    NSString *jsonString =
        [unescapedJsonString stringByReplacingOccurrencesOfString:@"\\x26#160;" 
                                                       withString:@" "];

    // parse the json string
    NSError *error = nil;
    NSMutableDictionary *dictionary = 
        [jsonString objectFromJSONStringWithParseOptions:JKParseOptionLooseUnicode 
                                                   error:&error];

    // log any errors
    if (error) {
        NSLog(@"GoogleMapsApi: Failed to parse route data: %@", error);
    }

    // cleanup 
    [malformedJsonString release];

    return dictionary;
}

//------------------------------------------------------------------------------

/**
 * Documentation on decoding the polyline:
 *  http://code.google.com/apis/maps/documentation/utilities/polylinealgorithm.html
 */
- (NSArray*) decodePolyline:(NSString*)polyline
{
    NSMutableArray *coordinates = [[[NSMutableArray alloc] init] autorelease];
    NSUInteger length           = polyline.length;
    NSUInteger index            = 0;
    NSInteger latitude          = 0; 
    NSInteger longitude         = 0; 

    while (index < length) {

        char byte;
        NSUInteger shift;
        NSUInteger result;

        // latitude
        shift  = 0;
        result = 0;
        do {
            byte    = [polyline characterAtIndex:index++] - 63;
            result |= (byte & 0x1f) << shift;
            shift  += 5;
        } while (byte >= 0x20);
        latitude += (result & 1) ? ~(result >> 1) : (result >> 1);

        // longitude
        shift  = 0;
        result = 0;
        do {
            byte    = [polyline characterAtIndex:index++] - 63;
            result |= (byte & 0x1f) << shift;
            shift  += 5;
        } while (byte >= 0x20);
        longitude += (result & 1) ? ~(result >> 1) : (result >> 1);

        // push new coordinate onto array
        CLLocation *location = 
            [[CLLocation alloc] initWithLatitude:(latitude * 1e-5) 
                                       longitude:(longitude * 1e-5)];
        [coordinates addObject:location];
        [location release];
    }

    return coordinates;
}

//------------------------------------------------------------------------------

@end
