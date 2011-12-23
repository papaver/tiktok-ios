//
//  LocationController.m
//  TikTok
//
//  Created by Moiz Merchant on 5/25/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "LocationController.h"
#import "Utilities.h"

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation LocationController

//------------------------------------------------------------------------------

@synthesize locationManager = mLocationManager;
@synthesize delegate        = mDelegate;

//------------------------------------------------------------------------------

- (id) init 
{
    self = [super init];
    if (self != nil) {
        self.locationManager = [[[CLLocationManager alloc] init] autorelease];
        self.locationManager.delegate       = self;
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.locationManager.purpose        = @"Todo: fill this out and load from a localized strings file...";

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
#pragma mark -
#pragma mark CLLocationManagerDelegate
//------------------------------------------------------------------------------

- (void) locationManager:(CLLocationManager*)manager
     didUpdateToLocation:(CLLocation*)newLocation
            fromLocation:(CLLocation*)oldLocation
{
    NSLog(@"LocationController: new location: %@", newLocation);
    [self.delegate locationUpdate:newLocation];
}

//------------------------------------------------------------------------------

- (void) locationManager:(CLLocationManager*)manager
        didFailWithError:(NSError*)error
{
    NSLog(@"LocationController: error updating location: %@", error);
    [self.delegate locationError:error];
}

//------------------------------------------------------------------------------

- (void) locationManager:(CLLocationManager*)manager 
didStartMonitoringForRegion:(CLRegion*)region
{
    NSLog(@"LocationController: started monitoring region: %@", region);
}

//------------------------------------------------------------------------------

- (void) locationManager:(CLLocationManager*)manager 
monitoringDidFailForRegion:(CLRegion*)region 
                 withError:(NSError*)error
{
    NSLog(@"LocationController: error monitoring region %@: %@", region, error);
}

//------------------------------------------------------------------------------

- (void) locationManager:(CLLocationManager*)manager 
          didEnterRegion:(CLRegion*)region
{
    NSLog(@"LocationController: entering region: %@", region);
    [Utilities postLocalNotificationInBackgroundWithBody:@"Entering Region"
                                                  action:@"Read Message"
                                         iconBadgeNumber:0];
}

//------------------------------------------------------------------------------

- (void) locationManager:(CLLocationManager*)manager 
           didExitRegion:(CLRegion*)region
{
    NSLog(@"LocationController: exiting region: %@", region);
    [Utilities postLocalNotificationInBackgroundWithBody:@"Exiting Region"
                                                  action:@"Read Message"
                                         iconBadgeNumber:0];
}

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Helper Functions
//------------------------------------------------------------------------------

- (void) printLocationManagerStatus:(CLLocationManager*)manager
{
    NSLog(@"LocationController: authorization status: %d", 
        [CLLocationManager authorizationStatus]);
    NSLog(@"LocationController: location services enabled: %d", 
        [CLLocationManager locationServicesEnabled]);
    NSLog(@"LocationController: region monitoring available: %d", 
        [CLLocationManager regionMonitoringAvailable]);
    NSLog(@"LocationController: region monitoring enabled: %d", 
        [CLLocationManager regionMonitoringEnabled]);
    NSLog(@"LocationController: significant location change available: %d", 
        [CLLocationManager significantLocationChangeMonitoringAvailable]);
    NSLog(@"LocationController: monitored regions: %@", 
        manager.monitoredRegions);
}

//------------------------------------------------------------------------------

@end
