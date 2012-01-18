//
//  CouponAnnotation.m
//  TikTok
//
//  Created by Moiz Merchant on 01/18/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "CouponAnnotation.h"
#import "Coupon.h"
#import "Merchant.h"

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation CouponAnnotation

//------------------------------------------------------------------------------

@synthesize coupon = mCoupon;

//------------------------------------------------------------------------------
#pragma mark - Initilization
//------------------------------------------------------------------------------

- (id) initWithCoupon:(Coupon*)coupon
{
    self = [super init];
    if (self) {
        self.coupon = coupon;
    }
    return self;
}

//------------------------------------------------------------------------------
#pragma mark - MKAnnotation
//------------------------------------------------------------------------------

- (NSString*) title
{
    return self.coupon.merchant.name;
}

//------------------------------------------------------------------------------

- (NSString*) subtitle
{
    return self.coupon.title;
}

//------------------------------------------------------------------------------

- (CLLocationCoordinate2D) coordinate
{
    CLLocationDegrees latitude  = self.coupon.merchant.latitude.doubleValue;
    CLLocationDegrees longitude = self.coupon.merchant.longitude.doubleValue;
    return CLLocationCoordinate2DMake(latitude, longitude);
}

//------------------------------------------------------------------------------
#pragma mark - Memory Management
//------------------------------------------------------------------------------

- (void) dealloc
{
    [mCoupon release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
