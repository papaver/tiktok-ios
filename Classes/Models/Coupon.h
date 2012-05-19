//
//  Coupon.h
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

@class Merchant;
@class IconData;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface Coupon : NSManagedObject 
{
}

//------------------------------------------------------------------------------

@property (nonatomic, retain)   NSNumber *couponId;
@property (nonatomic, retain)   NSString *title;
@property (nonatomic, retain)   NSString *details;
@property (nonatomic, retain)   NSNumber *iconId;
@property (nonatomic, retain)   NSString *iconUrl;
@property (nonatomic, readonly) IconData *iconData;
@property (nonatomic, retain)   NSDate   *startTime;
@property (nonatomic, retain)   NSDate   *endTime;
@property (nonatomic, retain)   NSString *barcode;
@property (nonatomic, retain)   Merchant *merchant;
@property (nonatomic, assign)   NSNumber *wasRedeemed;
@property (nonatomic, assign)   NSNumber *isSoldOut;

//------------------------------------------------------------------------------

/**
 * Query the context for a coupon by name.  
 */
+ (Coupon*) getCouponById:(NSNumber*)couponId 
                fromContext:(NSManagedObjectContext*)context;

/**
 * Query the context for a coupon by json data.  If the coupon does not 
 * exist, it will be added to the context and saved into the store.
 */
+ (Coupon*) getOrCreateCouponWithJsonData:(NSDictionary*)data 
                              fromContext:(NSManagedObjectContext*)context;

/**
 * Initialize the coupon object with the given json data.
 */
- (Coupon*) initWithJsonDictionary:(NSDictionary*)data;

/**
 * Returns true if coupon no longer has time left.
 */
- (BOOL) isExpired;

/**
 * Returns the color representing the time left on the coupon.
 */
- (UIColor*) getColor;

/**
 * Returns the a formated string of the expiration time in am/pm.
 */
- (NSString*) getExpirationTime;

/**
 * Returns the a formated string of the expiration time as a timer.
 */
- (NSString*) getExpirationTimer;

/**
 * Returns the headline with extra formatting.
 */
- (NSString*) getTitleWithFormatting;

/**
 * Returns the details with terms and conditions attached to the bottom.
 */
- (NSString*) getDetailsWithTerms;

//------------------------------------------------------------------------------

@end
