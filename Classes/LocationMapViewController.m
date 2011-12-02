//
//  LocationMapViewController.m
//  FifteenMinutes
//
//  Created by Moiz Merchant on 5/30/11.
//  Copyright 2011 Bunnies on Acid. All rights reserved.
//

//------------------------------------------------------------------------------
// imports 
//------------------------------------------------------------------------------

#import "LocationMapViewController.h"
#import "Location.h"

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation LocationMapViewController

//------------------------------------------------------------------------------

@synthesize mapView = m_map_view;

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark View lifecycle
//------------------------------------------------------------------------------

- (void) viewDidLoad 
{
    [super viewDidLoad];

    /*
    // create a temporary location for testing purposes till api is ready
    Location *location = [[[Location alloc] init] autorelease];
    location.name      = @"15 Minutes HQ";
    location.latitude  = [NSNumber numberWithDouble: 34.16245];
    location.longitude = [NSNumber numberWithDouble: -118.344203];
    location.radius    = [NSNumber numberWithInt: 50];

    // create a region for the map to display
    MKCoordinateRegion region;
    region.center.latitude     = location.latitude.doubleValue; 
    region.center.longitude    = location.longitude.doubleValue;
    region.span.latitudeDelta  = 0.01f;
    region.span.longitudeDelta = 0.01f;
    [self.mapView setRegion:region];
    */

    self.mapView.showsUserLocation = YES;

    // add annotation to the map
    //[self.mapView addAnnotation:location];
}

//------------------------------------------------------------------------------

- (void) viewDidUnload 
{
    [super viewDidUnload];
}

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark MapViewDelegate
//------------------------------------------------------------------------------

- (MKAnnotationView*) mapView:(MKMapView*)mapView 
            viewForAnnotation:(id<MKAnnotation>)annotation
{
    static NSString *pinViewId = @"pinViewId";

    // skip if displaying current location
    if (![annotation isKindOfClass:[Location class]]) {
        return nil;
    }

    // cast annotation to location class
    Location *location = (Location*)annotation;

    // check for any available annotation views 
    MKPinAnnotationView *pinView = (MKPinAnnotationView*)[mapView 
        dequeueReusableAnnotationViewWithIdentifier:pinViewId];

    // if none were found, allocate a new one
    if (pinView == nil) {
        pinView = [[[MKPinAnnotationView alloc] 
            initWithAnnotation:annotation reuseIdentifier:pinViewId] 
            autorelease];
    }

    // setup pin view
    pinView.pinColor       = MKPinAnnotationColorGreen;
    pinView.canShowCallout = YES;
    pinView.animatesDrop   = YES;

    // draw the radius circle for the marker
    MKCircle *circle = [MKCircle circleWithCenterCoordinate:location.coordinate 
                                                     radius:location.radius.doubleValue * 1000.0f];
    [circle setTitle:@"background"];
    [self.mapView addOverlay:circle];

    MKCircle *circleLine = [MKCircle circleWithCenterCoordinate:location.coordinate 
                                                         radius:location.radius.doubleValue * 1000.0f];
    [circleLine setTitle:@"line"];
    [self.mapView addOverlay:circleLine];

    return pinView;
}

//------------------------------------------------------------------------------

#define UIColorFromRGB(rgbValue) [UIColor \
    colorWithRed:((float)((rgbValue && 0xFF0000) >> 16)) / 255.0 \
           green:((float)((rgbValue && 0x00FF00) >> 8))  / 255.0 \
            blue:((float) (rgbValue && 0x0000FF))        / 255.0 \
           alpha:1.0]

- (MKOverlayView*) mapView:(MKMapView*)mapView 
            viewForOverlay:(id<MKOverlay>)overlay
{
    MKCircle *circle         = overlay;
    MKCircleView *circleView = [[[MKCircleView alloc] initWithCircle:circle] autorelease];

    if ([circle.title isEqualToString:@"background"]) {
        circleView.fillColor = UIColorFromRGB(0x008DD3);
        circleView.alpha     = 0.25f;
    } else if ([circle.title isEqualToString:@"line" ]) {
        circleView.strokeColor = UIColorFromRGB(0x008AC7);
        circleView.lineWidth   = 2.0f;
    } else {
        circleView = nil;
    }

    return circleView;
}

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Memory management
//------------------------------------------------------------------------------

- (void) didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning];
}

//------------------------------------------------------------------------------

- (void) dealloc 
{
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
