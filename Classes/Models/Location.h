//
//  Location.h
//  TikTok
//
//  Created by Moiz Merchant on 5/18/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

@class Coupon;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface Location : NSManagedObject //<MKAnnotation>
{
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) NSNumber *locationId;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *address;
@property (nonatomic, retain) NSNumber *latitude;
@property (nonatomic, retain) NSNumber *longitude;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSDate   *lastUpdated;
@property (nonatomic, retain) NSSet    *coupons;

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

//------------------------------------------------------------------------------

/**
 * Query the context for a location by id.
 */
+ (Location*) getLocationById:(NSNumber*)locationId
                  fromContext:(NSManagedObjectContext*)context;

/**
 * Query the context for a location by json data.  If the location does not
 * exist, it will be added to the context and saved into the store.
 */
+ (Location*) getOrCreateLocationWithJsonData:(NSDictionary*)data
                                  fromContext:(NSManagedObjectContext*)context;

/**
 * Initialize the location object with the given json data.
 */
- (Location*) initWithJsonDictionary:(NSDictionary*)data;

/**
 * Get city location resides in.
 */
- (NSString*) getCity;

/**
 * MKAnnotation Accessors
- (NSString*) title;
- (CLLocationCoordinate2D) coordinate;
 */

//------------------------------------------------------------------------------

@end

//------------------------------------------------------------------------------
// CoreData Accessors
//------------------------------------------------------------------------------

@interface Location (CoreDataGeneratedAccessors)
- (void) addCouponObject:(Coupon*)coupon;
- (void) removeCouponObject:(Coupon*)coupon;
- (void) addCoupons:(NSSet*)coupons;
- (void) removeCoupons:(NSSet*)coupons;
@end

