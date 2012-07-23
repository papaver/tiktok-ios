//
//  MerchantViewController.h
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
@class Location;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface MerchantViewController : UIViewController <UIAlertViewDelegate>
{
    Coupon   *mCoupon;
    Location *mLocation;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) Coupon   *coupon;
@property (nonatomic, retain) Location *location;

//------------------------------------------------------------------------------

- (IBAction) clickAddress:(id)sender;
- (IBAction) clickPhone:(id)sender;
- (IBAction) clickWebsite:(id)sender;

//------------------------------------------------------------------------------

@end
