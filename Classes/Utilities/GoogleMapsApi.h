//
//  GoogleMapsApi.h
//  TikTok
//
//  Created by Moiz Merchant on 01/17/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports 
//------------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

@class ASIHTTPRequest;

//------------------------------------------------------------------------------
// typedefs
//------------------------------------------------------------------------------

typedef void (^GoogleApiCompletionHandler)(ASIHTTPRequest*, id);
typedef void (^GoogleApiErrorHandler)(NSError*);

//------------------------------------------------------------------------------
// interface implementation 
//------------------------------------------------------------------------------

@interface GoogleMapsApi : NSObject
{
    GoogleApiCompletionHandler mCompletionHandler;
    GoogleApiErrorHandler      mErrorHandler;
    dispatch_queue_t           mQueue;
}

//------------------------------------------------------------------------------

@property (nonatomic, copy) GoogleApiCompletionHandler completionHandler;
@property (nonatomic, copy) GoogleApiErrorHandler      errorHandler;

//------------------------------------------------------------------------------

/**
 * Returns google maps url that gets direction between the given places.
 */
+ (NSURL*) urlForDirectionsFromSource:(NSString*)source 
                        toDestination:(NSString*)destination;

/**
 * Parses the reverse geodata for a best pick for the locality.
 */
+ (NSString*) parseLocality:(NSDictionary*)geoData;

/**
 * Returns a dictionary containing geocoding information about the givin address.
 */
- (void) getGeocodingForAddress:(NSString*)address;

/**
 * Returns a dictionary containing geocoding information about the givin coordinate.
 */
- (void) getReverseGeocodingForAddress:(CLLocationCoordinate2D)coordinate;

/**
 * Returns a dictionary containing distance/time/route from source to destination.
 */
- (void) getRouteBetweenSource:(NSString*)source andDestination:(NSString*)destination;

//------------------------------------------------------------------------------

@end
