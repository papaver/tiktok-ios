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
#import "ASIHTTPRequest.h"
#import "TikTokApi.h"
#import "Utilities.h"

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface StartupViewController ()
    - (void) runStartupProcess;
    - (void) setupLocationTracking;
    - (void) registerDevice;
    - (void) registerNotifications;
    - (void) syncCoupons;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation StartupViewController

//------------------------------------------------------------------------------

@synthesize physicsController = mPhysicsController;
@synthesize completionHandler = mCompletionHandler;

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

    // register device with server if no customer id found
    NSString *customerId  = [Utilities getConsumerId];
    if (!customerId) { 
        [self registerDevice];
    } else {
        [self runStartupProcess];
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
#pragma mark - Helper Functions
//------------------------------------------------------------------------------

- (void) runStartupProcess
{
    // kick of registration for notifications
    [self registerNotifications];

    // add location tracking operation
    [self setupLocationTracking];

    // sync coupons
    [self syncCoupons];
}

//------------------------------------------------------------------------------

- (void) registerDevice
{
    // [moiz::memleak] is the self referencing of the block going to cause a 
    //  memory leak in the api.json call?
    
    NSLog(@"StartupController: registering device id...");

    // generate a new device id
    NSString *newDeviceId = [[UIDevice currentDevice] generateGUID];

    // setup an instance of the tiktok api to register the device
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];

    // setup a completion handler to save id after server registration
    api.completionHandler = ^(ASIHTTPRequest* request) { 

        // verify registeration succeeded
        if (request.responseStatusCode == 200) {

            // grab customer id from api
            NSString *consumerId = [api.jsonData objectAtIndex:0];

            // cache the customer/device id 
            [Utilities cacheDeviceId:newDeviceId];
            [Utilities cacheConsumerId:consumerId];

            // allow the startup process to continue
            [self runStartupProcess];
            
        // prompt user of registration failure
        } else {
            NSString *title   = NSLocalizedString(@"TITLE_NETWORK_ERROR", nil);
            NSString *message = NSLocalizedString(@"MESSAGE_DEVICEID_REG_FAILURE", nil);
            [Utilities displaySimpleAlertWithTitle:title andMessage:message]; 
        }
    };

    // alert user of registration failure
    api.errorHandler = ^(ASIHTTPRequest* request) { 
        NSString *title   = NSLocalizedString(@"TITLE_NETWORK_ERROR", nil);
        NSString *message = NSLocalizedString(@"MESSAGE_DEVICEID_REG_FAILURE", nil);
        [Utilities displaySimpleAlertWithTitle:title andMessage:message]; 
    };

    // register the device with the server
    [api registerDevice:newDeviceId];
}

//------------------------------------------------------------------------------

- (void) registerNotifications
{
    NSLog(@"StartupController: registering with notification server...");

    UIApplication *application = [UIApplication sharedApplication];
    [application registerForRemoteNotificationTypes:
        (UIRemoteNotificationTypeBadge | 
         UIRemoteNotificationTypeSound |
         UIRemoteNotificationTypeAlert)];
}

//------------------------------------------------------------------------------

- (void) setupLocationTracking
{
    NSLog(@"StartupController: Setting up location tracking...");
}

//------------------------------------------------------------------------------

- (void) syncCoupons
{
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];

    // trigger completion handler
    api.completionHandler = ^(ASIHTTPRequest* request) { 

        // stop processing physics
        [self.physicsController stopWorld];

        // run the completion handler if one exists
        if (self.completionHandler) self.completionHandler();
    };

    // sync coupons
    [api syncActiveCoupons];
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
    [mCompletionHandler release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
