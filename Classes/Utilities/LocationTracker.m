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
#import "Logger.h"
#import "TikTokApi.h"
#import "Utilities.h"

//------------------------------------------------------------------------------
// defines
//------------------------------------------------------------------------------

#if LOGGING_LOCATION_TRACKER
    #define NSLog(...) [Logger logInfo:$string(__VA_ARGS__)]
#endif

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
    - (void) updateCurrentLocation:(CLLocation*)location;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation LocationTracker

//------------------------------------------------------------------------------

@synthesize locationManager = mLocationManager;
@synthesize location        = mLocation;
@synthesize startTime       = mStartTime;
@synthesize timer           = mTimer;
@synthesize mode            = mMode;

//------------------------------------------------------------------------------
#pragma mark - class members
//------------------------------------------------------------------------------

+ (bool) isInitialized
{
    return sLocationTracker != nil;
}

//------------------------------------------------------------------------------

+ (void) startLocationTracking
{
    // allocate a new location tacker if required
    if (!sLocationTracker) {
        sLocationTracker = [[[LocationTracker alloc] init] retain];
    }
    [LocationTracker foregroundLocationTracking];
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

+ (void) foregroundLocationTracking
{
    if (![LocationTracker isInitialized]) return;
    [sLocationTracker.locationManager stopMonitoringSignificantLocationChanges];
    [sLocationTracker.locationManager startUpdatingLocation];
    sLocationTracker.mode      = kTrackingModeForeground;
    sLocationTracker.startTime = nil;
    NSLog(@"LocationTracker: Foreground Mode Enabled");
}

//------------------------------------------------------------------------------

+ (void) backgroundLocationTracking
{
    if (![LocationTracker isInitialized]) return;
    [sLocationTracker.locationManager stopUpdatingLocation];
    [sLocationTracker.locationManager startMonitoringSignificantLocationChanges];
    sLocationTracker.mode      = kTrackingModeBackground;
    sLocationTracker.startTime = nil;
    [sLocationTracker.timer invalidate];
    sLocationTracker.timer = nil;
    NSLog(@"LocationTracker: Background Mode Enabled");
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
        self.locationManager.distanceFilter  = 100.0;
        self.locationManager.purpose         = NSLocalizedString(@"LOCATION_REQUEST", nil);
        self.mode                            = kTrackingModeNone;

        // print out info about location manager
        //[LocationTracker printLocationManagerStatus:self.locationManager];
    }
    return self;
}

//------------------------------------------------------------------------------

- (void) dealloc
{
    [mTimer invalidate];
    [mStartTime release];
    [mLocation release];
    [mLocationManager release];
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

- (bool) isNewLocation:(CLLocation*)newLocation
 betterThanOldLocation:(CLLocation*)oldLocation
{
    const NSUInteger ONE_MINUTE = 60.0;

    if (oldLocation == nil) return true;
    if (newLocation == nil) return false;

    // check weather new location is newer or older
    NSTimeInterval timeDelta = [newLocation.timestamp
        timeIntervalSinceDate:oldLocation.timestamp];
    bool isSignificantlyNewer = timeDelta > ONE_MINUTE;
    bool isSignificantlyOlder = timeDelta < -ONE_MINUTE;
    bool isNewer              = timeDelta > 0;

    // if it has bee more than two minutes since the current location use
    // the new location seind the user has most likely moved, if the new
    // location is older than two minutes it must be worse
    if (isSignificantlyNewer) {
        return true;
    } else if (isSignificantlyOlder) {
        return false;
    }

    // check weather the new location fix is more or less accurate
    CLLocationAccuracy accuracyDelta =
        newLocation.horizontalAccuracy - oldLocation.horizontalAccuracy;
    bool isLessAccurate              = accuracyDelta > 0.0;
    bool isMoreAccurate              = accuracyDelta < 0.0;
    bool isSignificantlyLessAccurate = accuracyDelta > 200.0;

    // determine the location quality using a combination of time/accuracy
    if (isMoreAccurate) {
        return true;
    } else if (isNewer && !isLessAccurate) {
        return true;
    } else if (isNewer && !isSignificantlyLessAccurate) {
        return true;
    }

    return false;
}

//------------------------------------------------------------------------------

- (void) updateCurrentLocation:(CLLocation*)location
{
    // run the task as a background task
    UIApplication *application = [UIApplication sharedApplication];
    if (application.applicationState == UIApplicationStateBackground) {

        __block UIBackgroundTaskIdentifier backgroundTask;

        // clean up any unfinished task business by marking where you
        // stopped or ending the task outright
        backgroundTask = [application beginBackgroundTaskWithExpirationHandler:^{
            NSLog(@"LocationTracker: Background task expired.");
            [application endBackgroundTask:backgroundTask];
            backgroundTask = UIBackgroundTaskInvalid;
        }];

        // start the long-running task and return immediately.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"LocationTracker: Background task started.");

            // do the work associated with the task, preferably in chunks.
            TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
            [api updateCurrentLocation:location.coordinate async:false];

            // clear out the background task
            [application endBackgroundTask:backgroundTask];
            backgroundTask = UIBackgroundTaskInvalid;
        });

    // run the task in another thread
    } else {
        TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
        [api updateCurrentLocation:location.coordinate async:true];
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

    NSLog(@"LocationTracker: Location callback.");

    // push the location to the server if we have better location
    if ([self isNewLocation:newLocation betterThanOldLocation:self.location]) {
        self.location = newLocation;

        // push the current location to the server
        [self updateCurrentLocation:newLocation];

        // record location for analytics
        [Analytics setUserLocation:newLocation];

        // set start time if no set yet
        if (self.startTime == nil) self.startTime = [NSDate date];

        NSLog(@"LocationTracker: New Location: %@", newLocation);
    }

    // if location has been on for 2 minutes switch back to background mode
    if (mMode == kTrackingModeForeground) {
        const NSUInteger TWO_MINUTES = 2.0 * 60.0;
        NSTimeInterval timeDelta = [[NSDate date] timeIntervalSinceDate:self.startTime];
        if (timeDelta > TWO_MINUTES) {
            NSLog(@"LocationTracker: Foreground time expired.");
            [LocationTracker backgroundLocationTracking];

        } else if (self.timer == nil) {
            self.timer =
                [NSTimer scheduledTimerWithTimeInterval:2.1 * 60.0
                                                 target:[LocationTracker class]
                                                   selector:@selector(backgroundLocationTracking)
                                                   userInfo:nil
                                                   repeats:NO];
        }
    }

    // if triggered through significant change enable foreground services again
    if ((mMode == kTrackingModeBackground) && (self.startTime != nil)){
        NSLog(@"LocationTracker: Background triggered.");
        [LocationTracker foregroundLocationTracking];
    }
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
}

//------------------------------------------------------------------------------

- (void) locationManager:(CLLocationManager*)manager
           didExitRegion:(CLRegion*)region
{
    NSLog(@"LocationTracker: exiting region: %@", region);
}

//------------------------------------------------------------------------------
#pragma mark - Helper Functions
//------------------------------------------------------------------------------

+ (void) printLocationManagerStatus:(CLLocationManager*)manager
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
