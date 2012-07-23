//
//  Merchant.h
//  TikTok
//
//  Created by Moiz Merchant on 4/29/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

@class Coupon;
@class IconData;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface Merchant : NSManagedObject 
{
}

//------------------------------------------------------------------------------

@property (nonatomic, retain)   NSNumber *merchantId;
@property (nonatomic, retain)   NSString *name;
@property (nonatomic, retain)   NSString *category;
@property (nonatomic, retain)   NSString *details;
@property (nonatomic, retain)   NSNumber *iconId;
@property (nonatomic, retain)   NSString *iconUrl;
@property (nonatomic, readonly) IconData *iconData;
@property (nonatomic, retain)   NSString *twitterUrl;
@property (nonatomic, retain)   NSString *facebookUrl;
@property (nonatomic, retain)   NSString *websiteUrl;
@property (nonatomic, retain)   NSDate   *lastUpdated;
@property (nonatomic, retain)   NSSet    *coupons;

//------------------------------------------------------------------------------

/**
 * Query the context for a merchant by name.  
 */
+ (Merchant*) getMerchantById:(NSNumber*)merchantId
                  fromContext:(NSManagedObjectContext*)context;

/**
 * Query the context for a merchant by json data.  If the merchant does not 
 * exist, it will be added to the context and saved into the store.
 */
+ (Merchant*) getOrCreateMerchantWithJsonData:(NSDictionary*)data 
                                  fromContext:(NSManagedObjectContext*)context;

/**
 * Initialize the merchant object with the given json data.
 */
- (Merchant*) initWithJsonDictionary:(NSDictionary*)data;

//------------------------------------------------------------------------------

@end 

//------------------------------------------------------------------------------
// CoreData Accessors
//------------------------------------------------------------------------------

@interface Merchant (CoreDataGeneratedAccessors)
- (void) addCouponObject:(Coupon*)coupon;
- (void) removeCouponObject:(Coupon*)coupon;
- (void) addCoupons:(NSSet*)coupons;
- (void) removeCoupons:(NSSet*)coupons;
@end
