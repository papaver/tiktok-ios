//
//  LocationTracker.m
//  TikTok
//
//  Created by Moiz Merchant on 5/25/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "LocationTracker.h"
#import "TikTokApi.h"
#import "Utilities.h"

//------------------------------------------------------------------------------
// statics
//------------------------------------------------------------------------------

static LocationTracker *sLocationTracker;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface LocationTracker ()
    - (void) restartTracking:(NSTimer*)timer;
    - (void) doSpeedCheckFromOldLocation:(CLLocation*)oldLocation 
                           toNewLocation:(CLLocation*)newLocation;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation LocationTracker

//------------------------------------------------------------------------------

@synthesize locationManager = mLocationManager;

//------------------------------------------------------------------------------
#pragma mark - class members
//------------------------------------------------------------------------------

+ (void) startLocationTracking
{
    // allocate a new location tacker if required
    if (!sLocationTracker) {
        sLocationTracker = [[[LocationTracker alloc] init] retain];
    }
    [sLocationTracker.locationManager startUpdatingLocation];
}

//------------------------------------------------------------------------------

+ (void) stopLocationTracking
{
    // release the existing location tracker if one was allocated
    if (sLocationTracker) {
        [sLocationTracker.locationManager stopUpdatingLocation];
        [sLocationTracker release];
        sLocationTracker = nil;
    }
}

//------------------------------------------------------------------------------
#pragma mark - Initilization
//------------------------------------------------------------------------------

- (id) init 
{
    self = [super init];
    if (self != nil) {
        self.locationManager = [[[CLLocationManager alloc] init] autorelease];
        self.locationManager.delegate        = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.distanceFilter  = 500.0;
        self.locationManager.purpose         = NSLocalizedString(@"LOCATION_REQUEST", nil);

        // print out info about location manager
        [self printLocationManagerStatus:self.locationManager];
    }
    return self;
}

//------------------------------------------------------------------------------

- (void) dealloc
{
    [self.locationManager release];
    [super dealloc];
}

//------------------------------------------------------------------------------
#pragma mark - Timer
//------------------------------------------------------------------------------

- (void) restartTracking:(NSTimer*)timer
{
    // make sure tracker is available
    if (!sLocationTracker) return;

    // restart location tracking
    [sLocationTracker.locationManager startUpdatingLocation];
}

//------------------------------------------------------------------------------
#pragma mark - Helper Functions
//------------------------------------------------------------------------------

- (void) doSpeedCheckFromOldLocation:(CLLocation*)oldLocation 
                       toNewLocation:(CLLocation*)newLocation
{
    // try to figure out the speed that the device is traveling
    NSTimeInterval time = [newLocation.timestamp timeIntervalSinceDate:oldLocation.timestamp];
    CLLocationDistance distance = [newLocation distanceFromLocation:oldLocation];

    // if the last check was from an hour ago skip the speed check
    if (time > (60.0 * 60.0)) {
        return;
    }

    // if the distance is over 10 km skip the speed check
    if (distance > (10.0 * 1000.0)) {
        return;
    }

    // use the fastest of the two speeds
    CGFloat speed = MAX(distance / time, newLocation.speed);

    // don't check again for 30 minutes if we are going to fast
    if (speed > 20.0) {
        [sLocationTracker.locationManager stopUpdatingLocation];
        [NSTimer scheduledTimerWithTimeInterval:30.0 * 60.0
                                         target:self 
                                       selector:@selector(restartTracking:) 
                                       userInfo:nil 
                                        repeats:NO];
    }
}

//------------------------------------------------------------------------------
#pragma mark - CLLocationManagerDelegate
//------------------------------------------------------------------------------

- (void) locationManager:(CLLocationManager*)manager
     didUpdateToLocation:(CLLocation*)newLocation
            fromLocation:(CLLocation*)oldLocation
{
    // make sure tracker is available
    if (!sLocationTracker) return;

    // only do speed checks if old location available
    if (oldLocation) {
        [self doSpeedCheckFromOldLocation:oldLocation 
                            toNewLocation:newLocation];
    }
    
    // push the current location to the server
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    [api updateCurrentLocation:newLocation.coordinate];
}

//------------------------------------------------------------------------------

- (void) locationManager:(CLLocationManager*)manager
        didFailWithError:(NSError*)error
{
    NSLog(@"LocationTracker: error updating location: %@", error);
}

//------------------------------------------------------------------------------

- (void) locationManager:(CLLocationManager*)manager 
didStartMonitoringForRegion:(CLRegion*)region
{
    NSLog(@"LocationTracker: started monitoring region: %@", region);
}

//------------------------------------------------------------------------------

- (void) locationManager:(CLLocationManager*)manager 
monitoringDidFailForRegion:(CLRegion*)region 
                 withError:(NSError*)error
{
    NSLog(@"LocationTracker: error monitoring region %@: %@", region, error);
}

//------------------------------------------------------------------------------

- (void) locationManager:(CLLocationManager*)manager 
          didEnterRegion:(CLRegion*)region
{
    NSLog(@"LocationTracker: entering region: %@", region);
    /*
    [Utilities postLocalNotificationInBackgroundWithBody:@"Entering Region"
                                                  action:@"Read Message"
                                         iconBadgeNumber:0];
    */
}

//------------------------------------------------------------------------------

- (void) locationManager:(CLLocationManager*)manager 
           didExitRegion:(CLRegion*)region
{
    NSLog(@"LocationTracker: exiting region: %@", region);
    /*
    [Utilities postLocalNotificationInBackgroundWithBody:@"Exiting Region"
                                                  action:@"Read Message"
                                         iconBadgeNumber:0];
    */
}

//------------------------------------------------------------------------------
#pragma mark - Helper Functions
//------------------------------------------------------------------------------

- (void) printLocationManagerStatus:(CLLocationManager*)manager
{
    NSLog(@"LocationTracker: authorization status: %d", 
        [CLLocationManager authorizationStatus]);
    NSLog(@"LocationTracker: location services enabled: %d", 
        [CLLocationManager locationServicesEnabled]);
    NSLog(@"LocationTracker: region monitoring available: %d", 
        [CLLocationManager regionMonitoringAvailable]);
    NSLog(@"LocationTracker: region monitoring enabled: %d", 
        [CLLocationManager regionMonitoringEnabled]);
    NSLog(@"LocationTracker: significant location change available: %d", 
        [CLLocationManager significantLocationChangeMonitoringAvailable]);
    NSLog(@"LocationTracker: monitored regions: %@", 
        manager.monitoredRegions);
}

//------------------------------------------------------------------------------

@end
