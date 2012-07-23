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
#import "Coupon.h"
#import "CouponAnnotation.h"
#import "IconManager.h"
#import "Location.h"
#import "LocationTracker.h"
#import "Merchant.h"
#import "GoogleMapsApi.h"
#import "GradientView.h"

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

@class ASIHTTPRequest;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface LocationMapViewController ()
    - (void) addCouponAnnotations;
    - (void) addRouteToCoupon:(Location*)location;
    - (void) addRouteOverlay:(NSDictionary*)routeData;
    - (void) getDirections:(id)sender;
    - (MKPinAnnotationView*) getCouponPinViewForAnnotation:(id<MKAnnotation>)annotation;
    - (MKPolyline*) polylineFromPoints:(NSArray*)points;
    - (MKCoordinateRegion) regionFromPoints:(NSArray*)points;
    - (void) openMapApp:(Location*)location;
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
}

//------------------------------------------------------------------------------

- (void) viewDidUnload
{
    [super viewDidUnload];
}

//------------------------------------------------------------------------------
#pragma mark - MapViewDelegate
//------------------------------------------------------------------------------

- (void) mapView:(MKMapView*)mapView didAddAnnotationViews:(NSArray*)views
{
    // [moiz] should open the deal location

    // open a single callout
    id myAnnotation = [mapView.annotations objectAtIndex:0];
    [mapView selectAnnotation:myAnnotation animated:YES];
}

//------------------------------------------------------------------------------

- (MKAnnotationView*) mapView:(MKMapView*)mapView
            viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView *view = nil;

    // user location (let sdk handle drawing)
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        // [moiz] this is a good place to create a route to a destination from
        // the user location
        view = nil;

    // coupon annotations
    } else if ([annotation isKindOfClass:[CouponAnnotation class]]) {
        view = [self getCouponPinViewForAnnotation:annotation];
    }

    return view;
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
    // get closest location
    CLLocation* currentLocation = [LocationTracker currentLocation];
    Location* closestLocation =
        [self.coupon getClosestLocationToCoordinate:currentLocation.coordinate];

    // add closest location first
    CouponAnnotation *closestAnnotation = [[CouponAnnotation alloc]
        initWithCoupon:self.coupon andLocation:closestLocation];
    [self.mapView addAnnotation:closestAnnotation];

    // add the rest of the locations
    for (Location *location in self.coupon.locations) {
        if (location == closestLocation) continue;
        CouponAnnotation *annotation = [[CouponAnnotation alloc]
            initWithCoupon:self.coupon andLocation:location];
        [self.mapView addAnnotation:annotation];
    }

    // center map to closest annotation
    self.mapView.centerCoordinate = closestAnnotation.coordinate;

    // zoom map appropriatly
    MKCoordinateRegion viewRegion =
        MKCoordinateRegionMakeWithDistance(closestAnnotation.coordinate, 900, 900);
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
    [self.mapView setRegion:adjustedRegion animated:NO];

    // [moiz] hmmm... looks like we need to keep a reference to the annotaion
    //  around this might be true for overlays as well i imagine
    // cleanup
    //[closestAnnotation release];
}

//------------------------------------------------------------------------------

- (void) addRouteToCoupon:(Location*)location
{
    // source : user location
    CLLocationCoordinate2D currentLocation = self.mapView.userLocation.coordinate;
    NSString *source = $string(@"%f,%f", currentLocation.latitude,
                                         currentLocation.longitude);

    // desintation : coupon location
    NSString *destination = $string(@"%f,%f", location.latitude.doubleValue,
                                              location.longitude.doubleValue);

    // query the location using google maps
    GoogleMapsApi *api = [[GoogleMapsApi alloc] init];
    api.completionHandler = ^(ASIHTTPRequest *request, id data) {
        NSArray *routes = [data objectForKey:@"routes"];
        if (routes && routes.count) {
            [self addRouteOverlay:data];
        }
    };
    [api getRouteBetweenSource:source andDestination:destination];
    [api release];
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

- (MKPinAnnotationView*) getCouponPinViewForAnnotation:(id<MKAnnotation>)annotation
{
    static NSString *sCouponPinId = @"couponPinId";

    enum CouponPinViewTag {
        kTagGradient = 0,
        kTagIcon     = 1,
    };

    // check for any available annotation views
    MKPinAnnotationView *pinView = (MKPinAnnotationView*)[self.mapView
        dequeueReusableAnnotationViewWithIdentifier:sCouponPinId];
    if (pinView == nil) {
        pinView =
            [[[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                             reuseIdentifier:sCouponPinId] autorelease];

        // setup configuration
        pinView.pinColor       = MKPinAnnotationColorPurple;
        pinView.canShowCallout = YES;
        pinView.animatesDrop   = YES;

        // setup icon view
        IconManager *iconManager = [IconManager getInstance];
        CGRect gradientFrame     = CGRectMake(0.0, 0.0, 32.0, 32.0);
        GradientView *gradient   = [[GradientView alloc] initWithFrame:gradientFrame];
        gradient.tag             = kTagGradient;
        gradient.color           = [self.coupon getColor];
        gradient.border          = 2;
        CGRect iconFrame         = CGRectMake(4.0, 4.0, 24.0, 24.0);
        UIImageView *icon        = [[UIImageView alloc] initWithFrame:iconFrame];
        icon.image               = [iconManager getImage:self.coupon.iconData];
        icon.tag                 = kTagIcon;
        [gradient addSubview:icon];

        // setup button
        UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [button addTarget:self
                   action:@selector(getDirections:)
         forControlEvents:UIControlEventTouchUpInside];

        // add accessory view
        pinView.leftCalloutAccessoryView  = gradient;
        pinView.rightCalloutAccessoryView = button;

        // cleanup
        [icon release];
        [gradient release];
    }

    return pinView;
}

//------------------------------------------------------------------------------

- (void) getDirections:(id)sender
{
    // get pin annotation
    MKPinAnnotationView *pinView = (MKPinAnnotationView*)[[sender superview] superview];
    if (pinView == nil) return;

    // get location from annotation
    if (![pinView.annotation isKindOfClass:[CouponAnnotation class]]) return;
    CouponAnnotation *annotation = pinView.annotation;
    Location *location           = annotation.location;

    NSString *title   = self.coupon.merchant.name;
    NSString *message = location.address;

    // open up settings to configure twitter account
    UIAlertViewSelectionHandler handler = ^(NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            [self openMapApp:location];
        }
    };

    // display alert
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                withHandler:handler
                                          cancelButtonTitle:@"Okay"
                                          otherButtonTitles:@"Directions", nil];
    [alert show];
    [alert release];
}

//------------------------------------------------------------------------------

- (void) openMapApp:(Location*)location
{
    // use current location
    NSString *source = @"Current Location";

    // grab merchant location
    NSString *destination = $string(@"%f,%f", location.latitude.doubleValue,
                                              location.longitude.doubleValue);

    // generate url
    NSURL *url = [GoogleMapsApi urlForDirectionsFromSource:source
                                             toDestination:destination];

    // open map app
    UIApplication *application = [UIApplication sharedApplication];
    [application openURL:url];
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
    // its possible not niling out the delegate is causing crashes
    // ref: http://stackoverflow.com/questions/8022609/ios-5-mapkit-crashes-with-overlays-when-zoom-pan
    mMapView.delegate = nil;

    [mMapView release];
    [mCoupon release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
