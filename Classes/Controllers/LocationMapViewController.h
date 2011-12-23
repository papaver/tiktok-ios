//
//  LocationMapViewController.h
//  TikTok
//
//  Created by Moiz Merchant on 5/30/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports 
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface LocationMapViewController : UIViewController <MKMapViewDelegate>
{
    MKMapView *mMapView;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) IBOutlet MKMapView *mapView;

//------------------------------------------------------------------------------

@end
