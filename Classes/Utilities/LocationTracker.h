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
// enums
//------------------------------------------------------------------------------

typedef enum _TrackingMode
{
    kTrackingModeNone,
    kTrackingModeForeground,
    kTrackingModeBackground,
} TrackingMode;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface LocationTracker : NSObject <CLLocationManagerDelegate>
{
    CLLocationManager *mLocationManager;
    CLLocation        *mLocation;
    NSDate            *mStartTime;
    NSTimer           *mTimer;
    TrackingMode       mMode;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) CLLocationManager *locationManager;
@property (nonatomic, retain) CLLocation        *location;
@property (nonatomic, retain) NSDate            *startTime;
@property (nonatomic, assign) NSTimer           *timer;
@property (nonatomic, assign) TrackingMode       mode;

//------------------------------------------------------------------------------

+ (bool) isInitialized;
+ (CLLocation*) currentLocation;
+ (void) startLocationTracking;
+ (void) stopLocationTracking;
+ (void) foregroundLocationTracking;
+ (void) backgroundLocationTracking;

+ (void) printLocationManagerStatus:(CLLocationManager*)manager;

//------------------------------------------------------------------------------

@end
