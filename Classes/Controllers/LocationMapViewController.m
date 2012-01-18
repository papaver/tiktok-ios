//
//  LocationMapViewController.m
//  TikTok
//
//  Created by Moiz Merchant on 5/30/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports 
//------------------------------------------------------------------------------

#import "LocationMapViewController.h"
#import "ASIHTTPRequest.h"
#import "Coupon.h"
#import "CouponAnnotation.h"
#import "GoogleMapsApi.h"

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface LocationMapViewController ()
    - (void) addCouponAnnotations;
    - (void) addRouteOverlay:(NSDictionary*)routeData;
    - (MKPolyline*) polylineFromPoints:(NSArray*)points;
    - (MKCoordinateRegion) regionFromPoints:(NSArray*)points;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation LocationMapViewController

//------------------------------------------------------------------------------

@synthesize mapView = mMapView;
@synthesize coupon  = mCoupon;

//------------------------------------------------------------------------------
#pragma mark - View lifecycle
//------------------------------------------------------------------------------

- (void) viewDidLoad 
{
    [super viewDidLoad];

    // show user location
    self.mapView.showsUserLocation = YES;

    // add coupon location to map and center map
    if (self.coupon) [self addCouponAnnotations];

    /*
    NSString *source = @"875 Carleton Way, Burnaby";
    NSString *dest   = @"595 Burrard St, Vancouver";
    GoogleMapsApi *api = [[GoogleMapsApi alloc] init];
    api.completionHandler = ^(ASIHTTPRequest *request, id data) {
        NSArray *routes = [data objectForKey:@"routes"];
        if (routes && routes.count) {
            [self addRouteOverlay:data];
        }
    };
    [api getRouteBetweenSource:source andDestination:dest];
    [api release];
    */
}

//------------------------------------------------------------------------------

- (void) viewDidUnload 
{
    [super viewDidUnload];
}

//------------------------------------------------------------------------------
#pragma mark - MapViewDelegate
//------------------------------------------------------------------------------

- (MKAnnotationView*) mapView:(MKMapView*)mapView 
            viewForAnnotation:(id<MKAnnotation>)annotation
{
    static NSString *pinViewId = @"pinViewId";

    // user location (let sdk handle drawing)
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }

    // skip if displaying current location
    if ([annotation isKindOfClass:[CouponAnnotation class]]) {

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
    
        return pinView;
    }

    return nil;
}

//------------------------------------------------------------------------------

- (MKOverlayView*) mapView:(MKMapView*)mapView 
            viewForOverlay:(id<MKOverlay>)overlay
{
    MKOverlayView *view = nil;

    // polylines
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineView* polylineView = [[[MKPolylineView alloc] initWithPolyline:overlay] autorelease];
        polylineView.fillColor   = [UIColor colorWithRed:0.1f green:0.1f blue:0.9f alpha:0.4f];
        polylineView.strokeColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.9f alpha:0.6f];
        polylineView.lineWidth   = 6;
        view = polylineView;
    }

    return view;
}

//------------------------------------------------------------------------------
#pragma mark - Helper Functions
//------------------------------------------------------------------------------

- (void) addCouponAnnotations
{
    // add coupon annotations
    CouponAnnotation *annotation = [[CouponAnnotation alloc] initWithCoupon:self.coupon];
    [self.mapView addAnnotation:annotation];

    // center map to annotation
    self.mapView.centerCoordinate = annotation.coordinate;

    // zoom map appropriatly
    MKCoordinateRegion viewRegion =
        MKCoordinateRegionMakeWithDistance(annotation.coordinate, 900, 900);
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];                
    [self.mapView setRegion:adjustedRegion animated:NO]; 
    
    // cleanup
    [annotation release];
}

//------------------------------------------------------------------------------

- (void) addRouteOverlay:(NSDictionary*)data
{
    // get the first route from the data and add it as an overlay
    NSArray *routes = [data objectForKey:@"routes"];
    if (routes && routes.count) {

        // add route
        NSArray *route       = [routes objectAtIndex:0];
        MKPolyline *polyline = [self polylineFromPoints:route];
        [self.mapView addOverlay:polyline];

        // zoom map to show entire route
        MKCoordinateRegion region = MKCoordinateRegionForMapRect(polyline.boundingMapRect);
        region.span.latitudeDelta  *= 1.1;
        region.span.longitudeDelta *= 1.1;
        [self.mapView setRegion:region animated:YES];

    // alert user that route data could not be obtained?
    } else {
    }
}

//------------------------------------------------------------------------------

- (MKPolyline*) polylineFromPoints:(NSArray*)points
{
    // convert points to a c array
    MKMapPoint *pointsArray = malloc(sizeof(MKMapPoint) * points.count);
    NSUInteger index = 0;
    for (CLLocation *location in points) {
        pointsArray[index++] = MKMapPointForCoordinate(location.coordinate);
    }

    // create the polyline
    MKPolyline *polyline = [MKPolyline polylineWithPoints:pointsArray 
                                                    count:points.count];
    
    // cleanup
    free(pointsArray);
    
    return polyline;
}

//------------------------------------------------------------------------------

- (MKCoordinateRegion) regionFromPoints:(NSArray*)points
{
    CLLocationCoordinate2D max, min;
    min.latitude  =   90.0;
    max.latitude  =  -90.0;
    min.longitude =  180.0;
    max.longitude = -180.0; 

    // find the min/max coordinates 
    for (CLLocation *location in points) {
        min.latitude  = MIN(min.latitude,  location.coordinate.latitude);
        max.latitude  = MAX(max.latitude,  location.coordinate.latitude);
        min.longitude = MIN(min.longitude, location.coordinate.longitude);
        max.longitude = MAX(max.longitude, location.coordinate.longitude);
    }

    // create a region from the min/max coordinates
    MKCoordinateRegion region;
    region.center.latitude     = (min.latitude + max.latitude)   / 2.0;
    region.center.longitude    = (min.longitude + max.longitude) / 2.0;
    region.span.latitudeDelta  = max.latitude - min.latitude;
    region.span.longitudeDelta = max.longitude - min.longitude;

    return region;
}

//------------------------------------------------------------------------------
#pragma mark - Memory management
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
