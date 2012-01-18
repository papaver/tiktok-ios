//
//  CouponAnnotation.h
//  TikTok
//
//  Created by Moiz Merchant on 01/18/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

@class Coupon;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface CouponAnnotation : NSObject <MKAnnotation>
{
    Coupon *mCoupon;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) Coupon *coupon;

//------------------------------------------------------------------------------

- (id) initWithCoupon:(Coupon*)coupon;

/**
 * MKAnnotation Accessors
 */
- (NSString*) title;
- (NSString*) subtitle;
- (CLLocationCoordinate2D) coordinate;

//------------------------------------------------------------------------------

@end

