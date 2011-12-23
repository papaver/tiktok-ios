//
//  LocationController.h
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
// protocol definition 
//------------------------------------------------------------------------------

@protocol LocationControllerDelegate 

@required

- (void) locationUpdate:(CLLocation*)location;
- (void) locationError:(NSError*)error;

@end

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface LocationController : NSObject <CLLocationManagerDelegate>
{
    CLLocationManager *mLocationManager;
    id                 mDelegate;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) id                delegate;

//------------------------------------------------------------------------------

- (void) printLocationManagerStatus:(CLLocationManager*)manager;

//------------------------------------------------------------------------------

@end
