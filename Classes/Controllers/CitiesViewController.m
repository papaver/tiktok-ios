//
//  CitiesViewController.m
//  TikTok
//
//  Created by Moiz Merchant on 05/21/12.
//  Copyright (c) 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "CitiesViewController.h"
#import "ASIHTTPRequest.h"
#import "CityAnnotation.h"
#import "TikTokApi.h"
#import "Utilities.h"
#import "WebViewController.h"

//------------------------------------------------------------------------------
// statics
//------------------------------------------------------------------------------

static NSString *sCityPinId = @"cityPinId";

//------------------------------------------------------------------------------
// enums
//------------------------------------------------------------------------------

enum TableSection
{
    kSectionLive = kCityTypeLive,
    kSectionBeta = kCityTypeBeta,
    kSectionSoon = kCityTypeSoon,
};

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface CitiesViewController ()
    - (void) syncCities;
    - (void) setupMapButton;
    - (void) setupListButton;
    - (void) openMap;
    - (void) openList;
    - (UITableViewCell*) getReusableCell;
    - (NSString*) keyForSection:(NSUInteger)section;
    - (void) addCityAnnotation:(NSDictionary*)city ofType:(NSUInteger)type;
    - (MKPinAnnotationView*) getCityPinViewForAnnotation:(id<MKAnnotation>)annotation;
    - (MKPinAnnotationView*) setupNewPinViewForAnnotation:(id<MKAnnotation>)annotation;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation CitiesViewController

//------------------------------------------------------------------------------

@synthesize tableView = mTableView;
@synthesize mapView   = mMapView;

//------------------------------------------------------------------------------
#pragma mark - Initialization
//------------------------------------------------------------------------------

- (id) initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

//------------------------------------------------------------------------------
#pragma mark - View lifecycle
//------------------------------------------------------------------------------

/**
 * Only runs after view is loaded.
 */
- (void) viewDidLoad
{
    [Analytics passCheckpoint:@"Cities"];

    // setup navigation info
    self.title = @"Cities";

    // [iOS4] fix for black corners
    self.tableView.backgroundColor = [UIColor clearColor];

    // setup an empty structure
    mTableData = [$dict(
        $array(@"live", @"beta", @"soon"),
        $array([[[NSArray alloc] init] autorelease],
               [[[NSArray alloc] init] autorelease],
               [[[NSArray alloc] init] autorelease])) retain];

    // show user location
    self.mapView.showsUserLocation = YES;

    // setup toolbar
    [self setupMapButton];

    // sync the city data from the server
    [self syncCities];
}

//------------------------------------------------------------------------------

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

//------------------------------------------------------------------------------
#pragma mark - Helper Functions
//------------------------------------------------------------------------------

- (void) setupMapButton
{
    UIBarButtonItem *mapButton =
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"07-map-marker-bar.png"]
                                         style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(openMap)];

    // add to navbar
    self.navigationItem.rightBarButtonItem                  = mapButton;
    self.tabBarController.navigationItem.rightBarButtonItem = mapButton;

    // cleanup
    [mapButton release];
}

//------------------------------------------------------------------------------

- (void) setupListButton
{
    UIBarButtonItem *listButton =
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"259-list.png"]
                                         style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(openList)];

    // add to navbar
    self.navigationItem.rightBarButtonItem                  = listButton;
    self.tabBarController.navigationItem.rightBarButtonItem = listButton;

    // cleanup
    [listButton release];
}

//------------------------------------------------------------------------------

- (void) syncCities
{
    // setup an instance of the tiktok api to sync city data
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];

    // setup a completion handler to save points
    api.completionHandler = ^(NSDictionary *response) {

        // verify sync succeeded
        NSString *status = [response objectForKey:kTikTokApiKeyStatus];
        NSLog(@"status: %@", status);
        if ([status isEqualToString:kTikTokApiStatusOkay]) {

            // save cities
            [mTableData release];
            mTableData = [[response objectForKey:kTikTokApiKeyResults] retain];

            // refresh table
            [self.tableView reloadData];

            // add cities to map
            [self addCityAnnotations:mTableData];

        // something bad happened...
        } else {
            NSString *title   = NSLocalizedString(@"CITIES", nil);
            NSString *message = NSLocalizedString(@"CITIES_SYNC_FAIL", nil);
            [Utilities displaySimpleAlertWithTitle:title andMessage:message];
        }
    };

    // alert user if sync failed
    api.errorHandler = ^(ASIHTTPRequest* request) {
        NSString *title   = NSLocalizedString(@"CITIES", nil);
        NSString *message = NSLocalizedString(@"CITIES_SYNC_FAIL", nil);
        [Utilities displaySimpleAlertWithTitle:title andMessage:message];
    };

    // sync city data from server
    [api cities];
}

//------------------------------------------------------------------------------

- (void) openMap
{
   [UIView transitionFromView:self.tableView
                       toView:self.mapView
                     duration:1.0
                      options:(UIViewAnimationOptionCurveEaseInOut |
                               UIViewAnimationOptionTransitionFlipFromRight)
                   completion:NULL];

    // update button
    [self setupListButton];
}

//------------------------------------------------------------------------------

- (void) openList
{
   [UIView transitionFromView:self.mapView
                       toView:self.tableView
                     duration:1.0
                      options:(UIViewAnimationOptionCurveEaseInOut |
                               UIViewAnimationOptionTransitionFlipFromRight)
                   completion:NULL];

    // update button
    [self setupMapButton];
}

//------------------------------------------------------------------------------

- (NSString*) keyForSection:(NSUInteger)section
{
    switch (section) {
        case kSectionLive:
            return @"live";
        case kSectionBeta:
            return @"beta";
        case kSectionSoon:
            return @"soon";
        default:
            return nil;
    }
}

//------------------------------------------------------------------------------

- (void) addCityAnnotations:(NSDictionary*)cityData
{
    // setup a new array for the annotations
    [mAnnotations release];
    mAnnotations = [[[NSMutableArray alloc] init] retain];

    // add live cities
    for (NSDictionary *city in [cityData objectForKey:@"live"]) {
        [self addCityAnnotation:city ofType:kCityTypeLive];
    }

    // add beta cities
    for (NSDictionary *city in [cityData objectForKey:@"beta"]) {
        [self addCityAnnotation:city ofType:kCityTypeBeta];
    }

    // add soon cities
    for (NSDictionary *city in [cityData objectForKey:@"soon"]) {
        [self addCityAnnotation:city ofType:kCityTypeSoon];
    }
}

//------------------------------------------------------------------------------

- (void) addCityAnnotation:(NSDictionary*)city ofType:(NSUInteger)type
{
    // setup annotation
    CityAnnotation *annotation = [[CityAnnotation alloc] initWithCity:city ofType:type];

    // add to map
    [self.mapView addAnnotation:annotation];
    [mAnnotations addObject:annotation];

    // cleanup
    [annotation release];
}

//------------------------------------------------------------------------------

- (MKPinAnnotationView*) getCityPinViewForAnnotation:(id<MKAnnotation>)annotation
{
    [Analytics passCheckpoint:@"City Map Callout"];

    // check for any available annotation views
    MKPinAnnotationView *pinView = (MKPinAnnotationView*)[self.mapView
        dequeueReusableAnnotationViewWithIdentifier:sCityPinId];
    if (pinView == nil) {
        pinView = [self setupNewPinViewForAnnotation:annotation];
    }

    // select color according to type
    CityAnnotation *cityAnnotation = (CityAnnotation*)annotation;
    switch (cityAnnotation.type) {
        case kCityTypeLive:
            pinView.pinColor = MKPinAnnotationColorGreen;
            break;
        case kCityTypeBeta:
            pinView.pinColor = MKPinAnnotationColorPurple;
            break;
        case kCityTypeSoon:
            pinView.pinColor = MKPinAnnotationColorRed;
            break;
    }

    return pinView;
}

//------------------------------------------------------------------------------

- (MKPinAnnotationView*) setupNewPinViewForAnnotation:(id<MKAnnotation>)annotation
{
    // create a new pin view
    MKPinAnnotationView *pinView =
        [[[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                         reuseIdentifier:sCityPinId] autorelease];

    // setup configuration
    pinView.canShowCallout = YES;
    pinView.animatesDrop   = YES;

    return pinView;
}

//------------------------------------------------------------------------------
#pragma mark - Table view data source
//------------------------------------------------------------------------------

/**
 * Customize the number of sections in the table view.
 */
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return mTableData.count;
}

//------------------------------------------------------------------------------

/**
 * Customize the number of rows in the table view.
 */
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *key = [self keyForSection:section];
    return [[mTableData objectForKey:key] count];
}

//------------------------------------------------------------------------------

/**
 * Customize the appearance of table view cells.
 */
- (UITableViewCell*) tableView:(UITableView*)tableView
         cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    // grab city
    NSString *key      = [self keyForSection:indexPath.section];
    NSArray *cities    = [mTableData objectForKey:key];
    NSDictionary *city = (NSDictionary*)[cities objectAtIndex:indexPath.row];

    // update cell
    UITableViewCell *cell = [self getReusableCell];
    cell.textLabel.text   = [city objectForKey:@"name"];

    return cell;
}

//------------------------------------------------------------------------------

- (UITableViewCell*) getReusableCell
{
    static NSString *sCellId = @"city";

    // check if reuasable cell exists
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:sCellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                      reuseIdentifier:sCellId];
    }
    return cell;
}

//------------------------------------------------------------------------------

/**
 * Override to support conditional editing of the table view.
 */
- (BOOL) tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
    // table rows are not editable
    return NO;
}

//------------------------------------------------------------------------------

/**
 * Override to support rearranging the table view.
 */
- (void) tableView:(UITableView*)tableView
    moveRowAtIndexPath:(NSIndexPath*)fromIndexPath
           toIndexPath:(NSIndexPath*)toIndexPath
{
    // items cannot be moved
}

//------------------------------------------------------------------------------

/**
 * Override to support conditional rearranging of the table view.
 */
- (BOOL) tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath
{
    // items cannot be re-ordered
    return NO;
}

//------------------------------------------------------------------------------
#pragma mark - TableView Delegate
//------------------------------------------------------------------------------

- (CGFloat) tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    return 44.0;
}

//------------------------------------------------------------------------------

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    // create the parent view that will hold header Label
    CGRect headerFrame = CGRectMake(0.0, 0.0, 320.0, 44.0);
    UIView *header     = [[UIView alloc] initWithFrame:headerFrame];

    // create the background
    UIImage *image          = [UIImage imageNamed:@"TableHeaderBackground.png"];
    UIImageView *background = [[UIImageView alloc] initWithImage:image];

    // create the label
    CGRect labelFrame     = CGRectMake(10.0, 0.0, 300.0, 34.0);
    UILabel *label        = [[UILabel alloc] initWithFrame:labelFrame];
    label.font            = [UIFont boldSystemFontOfSize:20];
    label.textColor       = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];

    // add the appropriate text
    switch (section) {
        case kSectionLive:
            label.text = @"Live";
            break;
        case kSectionBeta:
            label.text = @"Beta";
            break;
        case kSectionSoon:
            label.text = @"Coming Soon";
            break;
        default:
            label.text = @"";
            break;
    }

    // add subviews to header
    [header addSubview:background];
    [header addSubview:label];

    return header;
}

//------------------------------------------------------------------------------
#pragma mark - MapViewDelegate
//------------------------------------------------------------------------------

- (void) mapView:(MKMapView*)mapView didAddAnnotationViews:(NSArray*)views
{
}

//------------------------------------------------------------------------------

- (MKAnnotationView*) mapView:(MKMapView*)mapView
            viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKAnnotationView *view = nil;

    // user location (let sdk handle drawing)
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        // nothing to see here

    // city annotations
    } else if ([annotation isKindOfClass:[CityAnnotation class]]) {
        view = [self getCityPinViewForAnnotation:annotation];
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
#pragma mark - Memory Management
//------------------------------------------------------------------------------

/**
 * Releases the view if it doesn't have a superview.
 */
- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

//------------------------------------------------------------------------------

/**
 * Relinquish ownership of anything that can be recreated in viewDidLoad
 * or on demand.
 */
- (void) viewDidUnload
{
}

//------------------------------------------------------------------------------

- (void) dealloc
{
    // its possible not niling out the delegate is causing crashes
    // ref: http://stackoverflow.com/questions/8022609/ios-5-mapkit-crashes-with-overlays-when-zoom-pan
    mMapView.delegate = nil;

    [mAnnotations release];
    [mTableData release];
    [mMapView release];
    [mTableView release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
