//
//  Merchant.h
//  fifteenMinutes
//
//  Created by Moiz Merchant on 4/29/11.
//  Copyright 2011 Bunnies on Acid. All rights reserved.
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

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface Merchant : NSManagedObject 
{
    UIImage *m_image;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) NSNumber *merchantId;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *imagePath;
@property (nonatomic, retain) NSSet    *coupons;

@property (nonatomic, retain, readonly) UIImage *image;

//------------------------------------------------------------------------------

/**
 * Query the context for a merchant by name.  
 */
+ (Merchant*) getMerchantByName:(NSString*)name 
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

