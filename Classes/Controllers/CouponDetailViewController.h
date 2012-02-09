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
#import "FBConnect.h"

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

@class Coupon;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface CouponDetailViewController : UIViewController <FBRequestDelegate,
                                                          FBDialogDelegate>
{
    Coupon   *mCoupon;
    NSTimer  *mTimer;
    UIView   *mBarcodeView;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain)          Coupon   *coupon;
@property (nonatomic, retain)          NSTimer  *timer;
@property (nonatomic, retain) IBOutlet UIView   *barcodeView;

//------------------------------------------------------------------------------

- (IBAction) merchantDetails:(id)sender;
- (IBAction) redeemCoupon:(id)sender;

- (IBAction) shareTwitter:(id)sender;
- (IBAction) shareFacebook:(id)sender;
- (IBAction) shareMore:(id)sender;

//------------------------------------------------------------------------------

@end
