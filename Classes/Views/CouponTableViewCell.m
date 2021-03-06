//
//  CouponTableViewCell.m
//  TikTok
//
//  Created by Moiz Merchant on 4/19/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "CouponTableViewCell.h"
#import "Coupon.h"

//------------------------------------------------------------------------------
// interface implementation 
//------------------------------------------------------------------------------

@implementation CouponTableViewCell 

//------------------------------------------------------------------------------

@synthesize coupon = mCoupon;
@synthesize timer  = mTimer;

//------------------------------------------------------------------------------

- (void) dealloc
{
    [mTimer invalidate];
    [mTimer release];
    [mCoupon release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end

