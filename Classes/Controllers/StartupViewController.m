//
//  StartupViewController.m
//  TikTok
//
//  Created by Moiz Merchant on 12/19/11.
//  Copyright (c) 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "StartupViewController.h"
#import "TikTokApi.h"

// [moiz] temp till i figure out a better way to share the managed context,
//   may be a bad idea over all to even tie the context together with the api
#import "TikTokAppDelegate.h"

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface StartupViewController ()
    - (void) setupLocationTracking;
    - (void) registerDevice;
    - (void) syncCoupons;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation StartupViewController

//------------------------------------------------------------------------------
#pragma mark - View lifecycle
//------------------------------------------------------------------------------

/**
 * Do any additional setup after loading the view from its nib.
 */
- (void) viewDidLoad
{
    [super viewDidLoad];

    NSLog(@"StartupController: viewDidLoad, setting up services...");

    // start location tracking
    [self setupLocationTracking];

    // register device for notifications
    [self registerDevice];
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
#pragma mark - Memory Management
//------------------------------------------------------------------------------

/**
 *  Releases the view if it doesn't have a superview.
 *  Release any cached data, images, etc that aren't in use.
 */
- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

//------------------------------------------------------------------------------
#pragma mark - Helper Functions
//------------------------------------------------------------------------------

- (void) setupLocationTracking
{
    NSLog(@"StartupController: Setting up location tracking...");
}

//------------------------------------------------------------------------------

- (void) registerDevice
{
    NSLog(@"StartupController: registering device id if required...");

    // [moiz] should cache the device id for later reference

    UIApplication *application = [UIApplication sharedApplication];
    [application registerForRemoteNotificationTypes:
        (UIRemoteNotificationTypeBadge | 
         UIRemoteNotificationTypeSound |
         UIRemoteNotificationTypeAlert)];
}

//------------------------------------------------------------------------------

- (void) syncCoupons
{
    NSLog(@"StartupController: syncing coupons...");
    
    TikTokAppDelegate *appDelegate = (TikTokAppDelegate*)[[UIApplication sharedApplication] delegate];

    // sync the coupons from the server
    TikTokApi *api = [[TikTokApi new] autorelease];
    api.managedContext = [appDelegate managedObjectContext];
    [api getActiveCoupons];

    // [moiz] this should really happen on another thread so the ui can run 
    //   while all the startup is happening in the background need to figure
    //   out the best way to run stuff in side threads... can run all the startup
    //   stuff at the same time then and just wait for all the thread to finish
    //   before continuing

    [self.view removeFromSuperview];
    [appDelegate.window addSubview:appDelegate.navigationController.view];
}

//------------------------------------------------------------------------------

- (void) onDeviceTokenReceived:(NSData*)deviceToken;
{
    // update the api with the device token
    [TikTokApi setDeviceToken:deviceToken];

    // sync the coupons from the server
    [self syncCoupons];
}

//------------------------------------------------------------------------------

@end
