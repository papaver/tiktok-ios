//
//  LocationPickerViewController.m
//  TikTok
//
//  Created by Moiz Merchant on 1/19/12.
//  Copyright (c) 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <QuartzCore/QuartzCore.h>
#import "LocationPickerViewController.h"
#import "GoogleMapsApi.h"

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

@class ASIHTTPRequest;

//------------------------------------------------------------------------------
// enum
//------------------------------------------------------------------------------

enum ViewTags
{
    kTagSearch          = 1,
    kTagMap             = 2,
    kTagSearchContainer = 3,
};

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface LocationPickerViewController ()
    - (void) centerMapToGeocoding:(NSDictionary*)geoData;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation LocationPickerViewController

//------------------------------------------------------------------------------

@synthesize location    = mLocation;
@synthesize doneButton  = mDoneButton;
@synthesize saveHandler = mSaveHandler;

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
 * Do any additional setup after loading the view from its nib.
 */
- (void) viewDidLoad
{
    [super viewDidLoad];

    // set title
    self.title = @"Set Location";

    // add done button
    self.navigationItem.rightBarButtonItem = self.doneButton;

    // give focus to the search field
    UIView *search = [self.view viewWithTag:kTagSearch];
    [search becomeFirstResponder];

    // add shadow to search container
    UIView *container             = [self.view viewWithTag:kTagSearchContainer];
    container.layer.shadowColor   = [[UIColor blackColor] CGColor];
    container.layer.shadowOffset  = CGSizeMake(2.0f, 2.0f);
    container.layer.shadowOpacity = 0.3f;

    // center on location if set
    if (self.location) {
        MKMapView *map = (MKMapView*)[self.view viewWithTag:kTagMap];
        MKCoordinateRegion viewRegion =
            MKCoordinateRegionMakeWithDistance(self.location.coordinate, 1000, 1000);
        MKCoordinateRegion adjustedRegion = [map regionThatFits:viewRegion];                
        [map setRegion:adjustedRegion animated:NO]; 
    }
}

//------------------------------------------------------------------------------

/**
 * Release any retained subviews of the main view.
 */
- (void) viewDidUnload
{
    [super viewDidUnload];
}

//------------------------------------------------------------------------------

/**
 * Return YES for supported orientations
 */
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

//------------------------------------------------------------------------------
#pragma mark - Events
//------------------------------------------------------------------------------

- (IBAction) centerMap:(id)sender
{
    MKMapView *map = (MKMapView*)[self.view viewWithTag:kTagMap];
    MKCoordinateRegion region = map.region;
    region.center = map.userLocation.location.coordinate;
    [map setRegion:[map regionThatFits:region] animated:YES];
}

//------------------------------------------------------------------------------

- (IBAction) done:(id)sender
{
    MKMapView *map = (MKMapView*)[self.view viewWithTag:kTagMap];
    if (self.saveHandler) {
        CLLocation *location = 
            [[CLLocation alloc] initWithLatitude:map.region.center.latitude
                                       longitude:map.region.center.longitude];
        self.saveHandler(location);
        [location release];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

//------------------------------------------------------------------------------
#pragma mark - MapViewDelegate
//------------------------------------------------------------------------------

- (MKAnnotationView*) mapView:(MKMapView*)mapView 
            viewForAnnotation:(id<MKAnnotation>)annotation
{
    // center to user location if location property is not set
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        if (!self.location) {
            self.location = mapView.userLocation.location;
            MKCoordinateRegion viewRegion =
                MKCoordinateRegionMakeWithDistance(self.location.coordinate, 1000, 1000);
            MKCoordinateRegion adjustedRegion = [mapView regionThatFits:viewRegion];                
            [mapView setRegion:adjustedRegion animated:YES]; 
        }
    } 

    return nil;
}

//------------------------------------------------------------------------------
#pragma mark - UITableView protocol
//------------------------------------------------------------------------------

- (BOOL) textFieldShouldReturn:(UITextField*)textField 
{
    // query the geocoding location for the givin address
    if (![textField.text isEqualToString:@""]) {
        GoogleMapsApi *api = [[GoogleMapsApi alloc] init];

        // add completion handler
        api.completionHandler = ^(ASIHTTPRequest *request, id geoData) {
            if (geoData) [self centerMapToGeocoding:geoData];
        };

        // add error handler
        api.errorHandler = ^(NSError *error) {
            // alert user search failed
        };

        // query for geocode data
        [api getGeocodingForAddress:textField.text];
        [api release];
    }
    return YES;
}

//------------------------------------------------------------------------------
#pragma mark - Helper functions
//------------------------------------------------------------------------------

- (void) centerMapToGeocoding:(NSDictionary*)geoData
{
    NSDictionary *results   = [[geoData objectForKey:@"results"] objectAtIndex:0];
    NSDictionary *location  = [results objectForComplexKey:@"geometry.location"];
    NSDictionary *northEast = [results objectForComplexKey:@"geometry.bounds.northeast"];
    NSDictionary *southWest = [results objectForComplexKey:@"geometry.bounds.southwest"];
    CGFloat latitude        = [[location objectForKey:@"lat"] doubleValue]; 
    CGFloat longitude       = [[location objectForKey:@"lng"] doubleValue]; 
    CGFloat neLatitude      = [[northEast objectForKey:@"lat"] doubleValue]; 
    CGFloat neLongitude     = [[northEast objectForKey:@"lng"] doubleValue]; 
    CGFloat swLatitude      = [[southWest objectForKey:@"lat"] doubleValue]; 
    CGFloat swLongitude     = [[southWest objectForKey:@"lng"] doubleValue]; 

    // setup a region 
    MKCoordinateRegion region;
    region.center.latitude     = latitude;
    region.center.longitude    = longitude;
    region.span.latitudeDelta  = fabs(neLatitude - swLatitude);
    region.span.longitudeDelta = fabs(neLongitude - swLongitude);

    // zoom with map
    MKMapView *map = (MKMapView*)[self.view viewWithTag:kTagMap];
    [map setRegion:region animated:YES];
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

- (void) dealloc
{
    [mDoneButton release];
    [mLocation release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
