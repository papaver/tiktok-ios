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
    - (void) startOperationsQueue;
    - (void) setupLocationTracking;
    - (void) registerDevice;
    - (void) syncCoupons;
    - (void) startTimer;
    - (void) displayCouponTableView:(NSTimer*)timer;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation StartupViewController

//------------------------------------------------------------------------------

@synthesize physicsController = mPhysicsController;
@synthesize operationQueue    = mOperationQueue;

//------------------------------------------------------------------------------
#pragma mark - View lifecycle
//------------------------------------------------------------------------------

/**
 * Do any additional setup after loading the view from its nib.
 */
- (void) viewDidLoad
{
    NSLog(@"StartupController: viewDidLoad, setting up services...");

    [super viewDidLoad];
    [self startOperationsQueue];

    // start progress bar animation
    UIView *progressView  = [self.view viewWithTag:1];
    CGRect frame          = progressView.frame;
    progressView.frame    = CGRectMake(frame.origin.x, frame.origin.y, 
                                       0.0, frame.size.height);

    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:10.0];
    [UIView setAnimationDelay:0.0];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    progressView.frame = frame;
    [UIView commitAnimations];
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
#pragma mark - Helper Functions
//------------------------------------------------------------------------------

- (void) startOperationsQueue
{
    // create an operations queue
    self.operationQueue = [[[NSOperationQueue alloc] init] autorelease];

    // add location tracking operation
    [self.operationQueue addOperationWithBlock:^{
        [self setupLocationTracking];
    }];

    // register device for notifications
    [self.operationQueue addOperationWithBlock:^{
        [self registerDevice];
    }];
}

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

    // register device and sync the coupons from the server
    TikTokApi *api = [[TikTokApi new] autorelease];
    api.managedContext = [appDelegate managedObjectContext];

    CLLocation *location = [[[CLLocation alloc] initWithLatitude:0.0 longitude:0.0] autorelease];
    [api checkInWithCurrentLocation:location];
    [api getActiveCoupons];
}

//------------------------------------------------------------------------------

- (void) onDeviceTokenReceived:(NSData*)deviceToken;
{
    // update the api with the device token
    [TikTokApi setDeviceToken:deviceToken];

    // create an operation block to sync the coupons
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        [self syncCoupons];
    }];

    // add completion handler
    __block StartupViewController *controller = self; 
    operation.completionBlock = ^{
        [controller performSelectorOnMainThread:@selector(startTimer) 
                                    withObject:NULL 
                                 waitUntilDone:NO];
    };

    // add the sync operation to the queue
    [self.operationQueue addOperation:operation];
}

//------------------------------------------------------------------------------

- (void) startTimer
{
    // [moiz] temp to show off physics tikntok shake
    [NSTimer scheduledTimerWithTimeInterval:7.0
                                     target:self 
                                   selector:@selector(displayCouponTableView:) 
                                   userInfo:nil 
                                    repeats:YES];
}

//------------------------------------------------------------------------------

- (void) displayCouponTableView:(NSTimer*)timer
{
    // [moiz] see if we can add animation to this 
    //  should turn off the physics stuff in the background at this point as well

    TikTokAppDelegate *appDelegate = (TikTokAppDelegate*)[[UIApplication sharedApplication] delegate];
    [self.view removeFromSuperview];
    [appDelegate.window addSubview:appDelegate.navigationController.view];
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

- (void) dealloc
{
    [mOperationQueue release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
