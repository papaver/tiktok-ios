//
//  CouponDetailViewController.h
//  TikTok
//
//  Created by Moiz Merchant on 4/22/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

@class Coupon;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface CouponDetailViewController : UIViewController 
{
    Coupon          *mCoupon;
    NSTimer         *mTimer;
    UIView          *mBarcodeView;
    UIBarButtonItem *mRedeemButton;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain)          Coupon          *coupon;
@property (nonatomic, retain)          NSTimer         *timer;
@property (nonatomic, retain) IBOutlet UIView          *barcodeView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *redeemButton;

//------------------------------------------------------------------------------

- (IBAction) merchantDetails:(id)sender;
- (IBAction) redeemCoupon:(id)sender;

- (IBAction) shareMail:(id)sender;
- (IBAction) shareTwitter:(id)sender;
- (IBAction) shareFacebook:(id)sender;
- (IBAction) shareGooglePlus:(id)sender;

//------------------------------------------------------------------------------

@end
