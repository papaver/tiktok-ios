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

@interface CouponMapViewController : UIViewController <MKMapViewDelegate,
                                                       NSFetchedResultsControllerDelegate>
{
    MKMapView                  *mMapView;
    NSMutableArray             *mAnnotations;
    NSFetchedResultsController *mFetchedCouponsController;
    NSTimer                    *mTimer;
    NSDictionary               *mUpdates;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) IBOutlet MKMapView                  *mapView;
@property (nonatomic, retain)          NSFetchedResultsController *fetchedCouponsController;
@property (nonatomic, retain)          NSTimer                    *timer;

//------------------------------------------------------------------------------

@end
