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

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation LocationController

//------------------------------------------------------------------------------

@synthesize locationManager = m_location_manager;
@synthesize delegate        = m_delegate;

//------------------------------------------------------------------------------

- (id) init 
{
    self = [super init];
    if (self != nil) {
        self.locationManager = [[[CLLocationManager alloc] init] autorelease];
        self.locationManager.delegate = self;
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

- (void) locationManager:(CLLocationManager*)manager
     didUpdateToLocation:(CLLocation*)newLocation
            fromLocation:(CLLocation*)oldLocation
{
    [self.delegate locationUpdate:newLocation];
}

//------------------------------------------------------------------------------

- (void) locationManager:(CLLocationManager*)manager
        didFailWithError:(NSError*)error
{
    [self.delegate locationError:error];
}

//------------------------------------------------------------------------------

@end
