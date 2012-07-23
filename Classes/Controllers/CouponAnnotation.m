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
#import "Location.h"
#import "Merchant.h"

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation CouponAnnotation

//------------------------------------------------------------------------------

@synthesize coupon   = mCoupon;
@synthesize location = mLocation;

//------------------------------------------------------------------------------
#pragma mark - Initilization
//------------------------------------------------------------------------------

- (id) initWithCoupon:(Coupon*)coupon andLocation:(Location*)location
{
    self = [super init];
    if (self) {
        self.coupon   = coupon;
        self.location = location;
    }
    return self;
}

//------------------------------------------------------------------------------
#pragma mark - MKAnnotation
//------------------------------------------------------------------------------

- (NSString*) title
{
    return $string(@"%@ - %@", self.coupon.merchant.name, self.location.address);
}

//------------------------------------------------------------------------------

- (NSString*) subtitle
{
    return self.coupon.title;
}

//------------------------------------------------------------------------------

- (CLLocationCoordinate2D) coordinate
{
    return self.location.coordinate;
}

//------------------------------------------------------------------------------
#pragma mark - Memory Management
//------------------------------------------------------------------------------

- (void) dealloc
{
    [mLocation release];
    [mCoupon release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
