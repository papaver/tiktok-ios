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
// statics
//------------------------------------------------------------------------------

NSString *sCouponCacheName = @"coupon_map";

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface CouponMapViewController ()
    - (void) setupToolbarButtons;
    - (void) setupExpirationTimer:(NSArray*)coupons;
    - (void) addCouponAnnotation:(Coupon*)coupon;
    - (void) removeCouponAnnotation:(Coupon*)coupon;
    - (void) addCouponAnnotations:(NSArray*)coupons;
    - (void) getCouponDetails;
    - (void) centerMapAroundCoupons:(NSArray*)coupons;
    - (void) centerMapUserLocation;
    - (MKPinAnnotationView*) getCouponPinViewForAnnotation:(id<MKAnnotation>)annotation;
    - (MKPinAnnotationView*) setupNewPinViewForAnnotation:(id<MKAnnotation>)annotation;
    - (void) expireCoupon:(NSTimer*)timer;
    - (void) refetchCoupons;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation CouponMapViewController

//------------------------------------------------------------------------------

@synthesize mapView                  = mMapView;
@synthesize fetchedCouponsController = mFetchedCouponsController;
@synthesize timer                    = mTimer;

//------------------------------------------------------------------------------
#pragma mark - View lifecycle
//------------------------------------------------------------------------------

- (void) viewDidLoad 
{
    [super viewDidLoad];

    self.title = @"Map";
                
    [Analytics passCheckpoint:@"Deal Map"];

    // initialize variables
    NSMutableArray *adds    = [[NSMutableArray alloc] init];
    NSMutableArray *deletes = [[NSMutableArray alloc] init];
    mUpdates = [$dict($array(@"adds", @"deletes"),
                      $array(adds, deletes)) retain];
    [adds release];
    [deletes release];

    // show user location
    self.mapView.showsUserLocation = YES;

    // setup toolbar
    [self setupToolbarButtons];

    // add coupon location to map and center map
    NSArray *coupons = self.fetchedCouponsController.fetchedObjects;
    [self addCouponAnnotations:coupons];

    // create a timer for the first expired coupon
    [self setupExpirationTimer:coupons];
}

//------------------------------------------------------------------------------

- (void) viewDidUnload 
{
    [super viewDidUnload];
}

//------------------------------------------------------------------------------

- (void) viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];

    // update adds
    NSMutableArray *adds = [mUpdates objectForKey:@"adds"];
    for (Coupon *coupon in adds) {
        [self addCouponAnnotation:coupon];
    }
    [adds removeAllObjects];

    // update deletes
    NSMutableArray *deletes = [mUpdates objectForKey:@"deletes"];
    for (Coupon *coupon in deletes) {
        [self removeCouponAnnotation:coupon];
    }
    [deletes removeAllObjects];
}

//------------------------------------------------------------------------------

- (void) setupToolbarButtons
{
    // add current location button
    UIBarButtonItem *currentLocationButton = 
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"193-location-arrow-bar.png"]
                                         style:UIBarButtonItemStyleBordered 
                                        target:self 
                                        action:@selector(centerMapUserLocation)];

    // [iOS4] tintColor not available
    if ($has_selector(currentLocationButton, setTintColor:)) {
        currentLocationButton.tintColor = [UIColor blueColor];
    }

    // add to navbar
    self.navigationItem.rightBarButtonItem = currentLocationButton;

    // cleanup
    [currentLocationButton release];
}

//------------------------------------------------------------------------------

- (void) setupExpirationTimer:(NSArray*)coupons
{
    if (!coupons.count) return;

    // find the first coupon to expire
    Coupon *firstExpired = [coupons objectAtIndex:0];
    for (Coupon *coupon in coupons) {
        if (coupon.endTime < firstExpired.endTime) {
            firstExpired = coupon;
        }
    }

    // release existing timer 
    if (self.timer) [self.timer invalidate];

    // calculate seconds to expiration
    NSTimeInterval seconds = [firstExpired.endTime timeIntervalSinceNow];
    self.timer = [NSTimer timerWithTimeInterval:seconds 
                                         target:self
                                       selector:@selector(expireCoupon:)
                                       userInfo:firstExpired
                                        repeats:NO];

    // add to run loop
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
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

- (void) mapView:(MKMapView*)mapView didSelectAnnotationView:(MKAnnotationView*)view
{
    if ([view.annotation isKindOfClass:[CouponAnnotation class]]) {
        MKPinAnnotationView *pinView       = (MKPinAnnotationView*)view;
        CouponAnnotation *couponAnnotation = (CouponAnnotation*)view.annotation;

        // update gradient color and icon
        IconManager *iconManager = [IconManager getInstance];
        GradientView *gradient   = (GradientView*)pinView.leftCalloutAccessoryView;
        gradient.color           = [couponAnnotation.coupon getColor];
        UIImageView *icon        = (UIImageView*)[gradient viewWithTag:kTagIcon];
        icon.image               = [iconManager getImage:couponAnnotation.coupon.iconData];
    }
}

//------------------------------------------------------------------------------
#pragma mark - Fetched Results Controller
//------------------------------------------------------------------------------

- (NSFetchedResultsController*) fetchedCouponsController
{
    // check if controller already created
    if (mFetchedCouponsController) {
        return mFetchedCouponsController;
    }

    NSManagedObjectContext *context = [[Database getInstance] context];

     // clear the cache
    [NSFetchedResultsController deleteCacheWithName:sCouponCacheName];

    // create an entity description object
    NSEntityDescription *description = [NSEntityDescription 
        entityForName:@"Coupon" inManagedObjectContext:context];

    // create a predicate
    NSPredicate *predicate = 
         [NSPredicate predicateWithFormat:@"endTime > %@", [NSDate date]];

    // create a sort descriptor
    NSSortDescriptor *sortByEndDate = [[NSSortDescriptor alloc] 
        initWithKey:@"endTime" ascending:NO];

    // create a fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity          = description;
    request.fetchBatchSize  = 10;
    request.predicate       = predicate;
    request.sortDescriptors = $array(sortByEndDate);

    // create a results controller from the request
    NSFetchedResultsController *fetchedCouponsController = 
        [[NSFetchedResultsController alloc] initWithFetchRequest:request 
                                            managedObjectContext:context 
                                              sectionNameKeyPath:nil
                                                       cacheName:sCouponCacheName];

    // save the controller
    self.fetchedCouponsController          = fetchedCouponsController;
    self.fetchedCouponsController.delegate = self;

    // preform the fetch
    NSError *error = nil;
    if (![self.fetchedCouponsController performFetch:&error]) {
        NSLog(@"Fetching of coupons failed: %@, %@", error, [error userInfo]);
        abort();
    }

    // cleanup
    [request release];
    [predicate release];
    [sortByEndDate release];
    [fetchedCouponsController release];

    return mFetchedCouponsController;
}

//------------------------------------------------------------------------------
#pragma mark - Fetched Results Controller Delegates
//------------------------------------------------------------------------------

- (void) controllerWillChangeContent:(NSFetchedResultsController*)controller
{
}

//------------------------------------------------------------------------------

- (void) controller:(NSFetchedResultsController*)controller 
   didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo 
            atIndex:(NSUInteger)sectionIndex 
      forChangeType:(NSFetchedResultsChangeType)type
{
}

//------------------------------------------------------------------------------

- (void) controller:(NSFetchedResultsController*)controller 
    didChangeObject:(id)object 
        atIndexPath:(NSIndexPath*)indexPath 
      forChangeType:(NSFetchedResultsChangeType)type 
       newIndexPath:(NSIndexPath*)newIndexPath 
{
    switch (type) {
        case NSFetchedResultsChangeInsert: 
            if (self.view.window) {
                [self addCouponAnnotation:(Coupon*)object];
            } else {
                [[mUpdates objectForKey:@"adds"] addObject:(Coupon*)object];
            }
            break;
        case NSFetchedResultsChangeDelete:
            [self removeCouponAnnotation:(Coupon*)object];
            break;
        case NSFetchedResultsChangeUpdate:
            break;
        case NSFetchedResultsChangeMove:
            break;
    }
}

//------------------------------------------------------------------------------

- (void) controllerDidChangeContent:(NSFetchedResultsController*)controller 
{
}


//------------------------------------------------------------------------------
#pragma mark - Helper Functions
//------------------------------------------------------------------------------

- (void) addCouponAnnotation:(Coupon*)coupon
{
    CouponAnnotation *annotation = [[CouponAnnotation alloc] initWithCoupon:coupon];
    [self.mapView addAnnotation:annotation];
    [mAnnotations addObject:annotation];
    [annotation release];
}

//------------------------------------------------------------------------------

- (void) removeCouponAnnotation:(Coupon*)coupon
{
    // compile the list of annotations that need to be removed
    NSMutableArray *annotations = [[NSMutableArray alloc] init];  
    for (CouponAnnotation *annotation in mAnnotations) {
        if (annotation.coupon == coupon) {
            [annotations addObject:annotation];
            break;
        }
    }

    // animate the removal of the pins
    [UIView animateWithDuration:1.0 
    animations:^{
        // fade the annotations out
        for (CouponAnnotation *annotation in annotations) {
            [[self.mapView viewForAnnotation:annotation] setAlpha:0.0];
        }
    }
    completion:^(BOOL finished) {
        // remove the annotations from that map
        for (CouponAnnotation *annotation in annotations) {
            [[self.mapView viewForAnnotation:annotation] setAlpha:1.0];
            [self.mapView removeAnnotation:annotation];
            [mAnnotations removeObject:annotation];
        }
    }];

    // cleanup
    [annotations release];
}

//------------------------------------------------------------------------------

- (void) addCouponAnnotations:(NSArray*)coupons
{
    // setup a new array for the annotations
    mAnnotations = [[[NSMutableArray alloc] init] retain];

    // create annotations from all of the coupons
    for (Coupon *coupon in coupons) {
        [self addCouponAnnotation:coupon];
    }

    // center map around coupons
    [self centerMapAroundCoupons:coupons];
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
    region.center.latitude     = (min.latitude + max.latitude)   * 0.5;
    region.center.longitude    = (min.longitude + max.longitude) * 0.5;
    region.span.latitudeDelta  = max.latitude - min.latitude;
    region.span.longitudeDelta = max.longitude - min.longitude;

    // add 5% buffer
    region.span.latitudeDelta  *= 1.05;
    region.span.longitudeDelta *= 1.05;
    region = [self.mapView regionThatFits:region];

    // center map 
    self.mapView.centerCoordinate = region.center;

    // zoom map appropriatly
    [self.mapView setRegion:region animated:YES];
}

//------------------------------------------------------------------------------

- (void) centerMapUserLocation
{
    MKCoordinateRegion region = self.mapView.region;
    region.center = self.mapView.userLocation.location.coordinate;
    [self.mapView setRegion:region animated:YES];
}

//------------------------------------------------------------------------------

- (MKPinAnnotationView*) getCouponPinViewForAnnotation:(id<MKAnnotation>)annotation
{
    [Analytics passCheckpoint:@"Deal Map Callout"];

    // check for any available annotation views 
    MKPinAnnotationView *pinView = (MKPinAnnotationView*)[self.mapView 
        dequeueReusableAnnotationViewWithIdentifier:sCouponPinId];
    if (pinView == nil) {
        pinView = [self setupNewPinViewForAnnotation:annotation];
    }
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
    [Analytics passCheckpoint:@"Deal Map Details"];

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

- (void) expireCoupon:(NSTimer*)timer
{
    // remove annotation and reset the results controller
    Coupon *coupon = (Coupon*)timer.userInfo;
    if (coupon) {

        // if map view showing remove coupon immediately, queue for removal
        if (self.view.window) {
            [self removeCouponAnnotation:coupon];
        } else {
            [[mUpdates objectForKey:@"deletes"] addObject:coupon];
        }

        // reset the results controller
        [self refetchCoupons];
    }

    // create a new timer
    [self setupExpirationTimer:self.fetchedCouponsController.fetchedObjects];
}

//------------------------------------------------------------------------------

- (void) refetchCoupons
{
    // create a predicate
    NSPredicate *predicate = 
         [NSPredicate predicateWithFormat:@"endTime > %@", [NSDate date]];

     // clear the cache
    [NSFetchedResultsController deleteCacheWithName:sCouponCacheName];

    // update the fetch request
    NSFetchRequest *request = self.fetchedCouponsController.fetchRequest; 
    request.predicate       = predicate;

    // update the request in the fetch controller
    NSError *error = nil;
    if (![self.fetchedCouponsController performFetch:&error]) {
        NSLog(@"CouponViewController: Fetching of coupons failed: %@, %@", 
            error, [error userInfo]);
    }
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

    [mTimer release];
    [mUpdates release];
    [mFetchedCouponsController release];
    [mAnnotations release];
    [mMapView release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
