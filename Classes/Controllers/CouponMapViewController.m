//
//  CouponMapViewController.m
//  TikTok
//
//  Created by Moiz Merchant on 5/30/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports 
//------------------------------------------------------------------------------

#import "CouponMapViewController.h"
#import "Coupon.h"
#import "CouponAnnotation.h"
#import "CouponDetailViewController.h"
#import "Database.h"
#import "IconManager.h"
#import "Merchant.h"
#import "GradientView.h"

//------------------------------------------------------------------------------
// statics
//------------------------------------------------------------------------------

static NSString *sCouponPinId = @"couponPinId";

//------------------------------------------------------------------------------
// enums
//------------------------------------------------------------------------------

typedef enum _CouponPinViewTag 
{
    kTagGradient = 1,
    kTagIcon     = 2,
} CouponPinViewTag;

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

@class ASIHTTPRequest;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface CouponMapViewController ()
    - (NSArray*) fetchCoupons;
    - (void) addCouponAnnotations:(NSArray*)coupons;
    - (void) getCouponDetails;
    - (void) centerMapAroundCoupons:(NSArray*)coupons;
    - (MKPinAnnotationView*) getCouponPinViewForAnnotation:(id<MKAnnotation>)annotation;
    - (MKPinAnnotationView*) setupNewPinViewForAnnotation:(id<MKAnnotation>)annotation;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation CouponMapViewController

//------------------------------------------------------------------------------

@synthesize mapView = mMapView;
@synthesize coupons = mCoupons;

//------------------------------------------------------------------------------
#pragma mark - View lifecycle
//------------------------------------------------------------------------------

- (void) viewDidLoad 
{
    [super viewDidLoad];

    self.title = @"Map";
                
    [TestFlight passCheckpointOnce:@"Deal Map"];

    // show user location
    self.mapView.showsUserLocation = YES;

    // fetch all the active coupons availble from the database
    self.coupons = [self fetchCoupons];

    // add coupon location to map and center map
    if (self.coupons) [self addCouponAnnotations:self.coupons];
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
    /*
    // open a single callout
    id myAnnotation = [mapView.annotations objectAtIndex:0]; 
    [mapView selectAnnotation:myAnnotation animated:YES]; 
    */
}

//------------------------------------------------------------------------------

- (MKAnnotationView*) mapView:(MKMapView*)mapView 
            viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView *view = nil;

    // user location (let sdk handle drawing)
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        // nothing to see here

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
   return nil;
}

//------------------------------------------------------------------------------
#pragma mark - Helper Functions
//------------------------------------------------------------------------------

- (NSArray*) fetchCoupons
{
    Database *database = [Database getInstance];
    NSManagedObjectContext *context = database.context;
    
    // grab the coupon description
    NSEntityDescription *description = [NSEntityDescription
        entityForName:@"Coupon" inManagedObjectContext:context];

    // create a coupon fetch request
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:description];

    // setup the request to lookup the specific coupon by name
    NSPredicate *predicate = 
        [NSPredicate predicateWithFormat:@"endTime > %@", [NSDate date]];
    [request setPredicate:predicate];

    // return the coupon if it already exists in the context
    NSError *error = nil;
    NSArray *array = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"failed to query context for coupon: %@", error);
        return nil;
    }

    return array;
}

//------------------------------------------------------------------------------

- (void) addCouponAnnotations:(NSArray*)coupons
{
    // setup a new array for the annotations
    mAnnotations = [[[NSMutableArray alloc] init] retain];

    // create annotations from all of the coupons
    for (Coupon *coupon in coupons) {
        CouponAnnotation *annotation = [[CouponAnnotation alloc] initWithCoupon:coupon];
        [self.mapView addAnnotation:annotation];
        [mAnnotations addObject:coupon];
        [annotation release];
    }

    // center map around coupons
    [self centerMapAroundCoupons:self.coupons];
 }

//------------------------------------------------------------------------------

- (void) centerMapAroundCoupons:(NSArray*)coupons
{
    // keep track of the min max lat/long 
    CLLocationCoordinate2D max, min;
    min.latitude  =   90.0;
    max.latitude  =  -90.0;
    min.longitude =  180.0;
    max.longitude = -180.0; 

    // update lat/long min/max
    for (Coupon *coupon in coupons) {
        min.latitude  = MIN(min.latitude,  coupon.merchant.latitude.doubleValue);
        max.latitude  = MAX(max.latitude,  coupon.merchant.latitude.doubleValue);
        min.longitude = MIN(min.longitude, coupon.merchant.longitude.doubleValue);
        max.longitude = MAX(max.longitude, coupon.merchant.longitude.doubleValue);
    }

    // create a region from the min/max coordinates
    MKCoordinateRegion region;
    region.center.latitude     = (min.latitude + max.latitude)   / 2.0;
    region.center.longitude    = (min.longitude + max.longitude) / 2.0;
    region.span.latitudeDelta  = max.latitude - min.latitude;
    region.span.longitudeDelta = max.longitude - min.longitude;

    // add 10% buffer
    region = [self.mapView regionThatFits:region];
    region.span.latitudeDelta  *= 1.1;
    region.span.longitudeDelta *= 1.1;

    // center map 
    self.mapView.centerCoordinate = region.center;

    // zoom map appropriatly
    [self.mapView setRegion:region animated:YES];
}

//------------------------------------------------------------------------------

- (MKPinAnnotationView*) getCouponPinViewForAnnotation:(id<MKAnnotation>)annotation
{
    [TestFlight passCheckpointOnce:@"Deal Map Callout"];

    // check for any available annotation views 
    MKPinAnnotationView *pinView = (MKPinAnnotationView*)[self.mapView 
        dequeueReusableAnnotationViewWithIdentifier:sCouponPinId];
    if (pinView == nil) {
        pinView = [self setupNewPinViewForAnnotation:annotation];
    }

    // convert to coupon annotation
    CouponAnnotation *couponAnnotation = (CouponAnnotation*)annotation;

    // update gradient color and icon
    IconManager *iconManager = [IconManager getInstance];
    GradientView *gradient   = (GradientView*)pinView.leftCalloutAccessoryView;
    gradient.color           = [couponAnnotation.coupon getColor];
    UIImageView *icon        = (UIImageView*)[gradient viewWithTag:kTagIcon];
    icon.image               = [iconManager getImage:couponAnnotation.coupon.iconData];

    return pinView;
}

//------------------------------------------------------------------------------

- (MKPinAnnotationView*) setupNewPinViewForAnnotation:(id<MKAnnotation>)annotation
{
    // create a new pin view
    MKPinAnnotationView *pinView = 
        [[[MKPinAnnotationView alloc] initWithAnnotation:annotation 
                                         reuseIdentifier:sCouponPinId] autorelease];

    // setup configuration
    pinView.pinColor       = MKPinAnnotationColorPurple;
    pinView.canShowCallout = YES;
    pinView.animatesDrop   = YES;

    // setup gradient
    CGRect gradientFrame   = CGRectMake(0.0, 0.0, 32.0, 32.0);
    GradientView *gradient = [[GradientView alloc] initWithFrame:gradientFrame];
    gradient.tag           = kTagGradient;
    gradient.border        = 2;

    // setup icon
    CGRect iconFrame  = CGRectMake(4.0, 4.0, 24.0, 24.0);
    UIImageView *icon = [[UIImageView alloc] initWithFrame:iconFrame];
    icon.contentMode  = UIViewContentModeScaleAspectFit;
    icon.tag          = kTagIcon;
    [gradient addSubview:icon];

    // setup button 
    UIButton *button = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    [button addTarget:self 
               action:@selector(getCouponDetails) 
     forControlEvents:UIControlEventTouchUpInside];

    // add accessory view
    pinView.leftCalloutAccessoryView  = gradient;
    pinView.rightCalloutAccessoryView = button;

    // cleanup
    [icon release];
    [gradient release];

    return pinView;
}

//------------------------------------------------------------------------------

- (void) getCouponDetails
{
    [TestFlight passCheckpointOnce:@"Deal Map Details"];

    // get the selected annotation
    NSArray *selectedAnnotations = [self.mapView selectedAnnotations];

    // make sure annotations exist
    if (!selectedAnnotations.count) return;

    // make sure its a coupon annotation
    id<MKAnnotation> annotation = (id<MKAnnotation>)[selectedAnnotations objectAtIndex:0];
    if (![annotation isKindOfClass:[CouponAnnotation class]]) return;

    // create a detail view and push onto stack
    CouponAnnotation *couponAnnotation = (CouponAnnotation*)annotation;

    // [moiz] this should be cached in some way, causes animation hitch eveytime
    //  it loads...
    CouponDetailViewController *detailViewController = [[CouponDetailViewController alloc] 
        initWithNibName:@"CouponDetailViewController" bundle:nil];

    // set coupon to view
    [detailViewController setCoupon:couponAnnotation.coupon];

    // pass the selected object to the new view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
    [detailViewController release];
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

    [mAnnotations release];
    [mCoupons release];
    [mMapView release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
