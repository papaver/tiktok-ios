//
//  CouponMapViewController.h
//  TikTok
//
//  Created by Moiz Merchant on 01/31/12.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports 
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

@class Coupon;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface CouponMapViewController : UIViewController <MKMapViewDelegate>
{
    MKMapView      *mMapView;
    NSArray        *mCoupons;
    NSMutableArray *mAnnotations;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) IBOutlet MKMapView *mapView;
@property (nonatomic, retain)          NSArray   *coupons;

//------------------------------------------------------------------------------

@end
