//
//  MerchantPinViewController.h
//  TikTok
//
//  Created by Moiz Merchant on 06/08/12.
//  Copyright (c) 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface MerchantPinViewController : UIViewController// <UITextFieldDelegate>
{
    NSNumber *mCouponId;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) NSNumber *couponId;

//------------------------------------------------------------------------------

- (IBAction) close;

//------------------------------------------------------------------------------

@end
