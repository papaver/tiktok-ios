//
//  CouponTableViewCell.h
//  TikTok
//
//  Created by Moiz Merchant on 4/19/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

@class Coupon;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface CouponTableViewCell : UITableViewCell
{
    Coupon  *mCoupon;
    NSTimer *mTimer;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) Coupon  *coupon;
@property (nonatomic, retain) NSTimer *timer;

//------------------------------------------------------------------------------

@end
