//
//  LocationTracker.h
//  TikTok
//
//  Created by Moiz Merchant on 5/25/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports 
//------------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface LocationTracker : NSObject <CLLocationManagerDelegate>
{
    CLLocationManager *mLocationManager;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) CLLocationManager *locationManager;

//------------------------------------------------------------------------------

+ (void) startLocationTracking;
+ (void) stopLocationTracking;

- (void) printLocationManagerStatus:(CLLocationManager*)manager;

//------------------------------------------------------------------------------

@end
