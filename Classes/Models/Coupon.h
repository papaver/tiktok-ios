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

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface Coupon : NSManagedObject 
{
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSString *imagePath;
@property (nonatomic, retain) NSDate   *startTime;
@property (nonatomic, retain) NSDate   *endTime;
@property (nonatomic, retain) Merchant *merchant;

//------------------------------------------------------------------------------

/**
 * Query the context for a coupon by name.  
 */
+ (Coupon*) getCouponByName:(NSString*)name 
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

//------------------------------------------------------------------------------

@end
