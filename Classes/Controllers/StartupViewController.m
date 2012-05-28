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
#import "Database.h"
#import "IconManager.h"
#import "LocationTracker.h"
#import "NetworkConnectivity.h"
#import "Settings.h"
#import "TikTokApi.h"
#import "Utilities.h"

//------------------------------------------------------------------------------
// enums
//------------------------------------------------------------------------------

enum StartupTag
{
    kTagProgressBar = 3,
    kTagShakeIcon   = 4,
    kTagShakeText   = 5,
};

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface StartupViewController ()
    - (void) runStartupProcess;
    - (void) purgeData;
    - (void) setupLocationTracking;
    - (void) registerDevice;
    - (void) validateRegistration;
    - (void) registerNotifications;
    - (void) syncCoupons;
    - (void) progressBar:(NSTimer*)timer;
    - (void) waitForInternetConnection;
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
    [super viewDidLoad];
    NSLog(@"StartupController: viewDidLoad, setting up services...");

    [Analytics passCheckpoint:@"Startup"];

    // [OS4] fix for missing font bradley hand bold
    UILabel *shakeText = (UILabel*)[self.view viewWithTag:kTagShakeText];
    if (shakeText.font == nil) {
        shakeText.font  = [UIFont fontWithName:@"BradleyHandITCTTBold" size:18];
    }

    // initialize variables
    mPause               = false;
    mComplete            = false;
    mNotifications       = false;
    mLocations           = false;
    mRegistrationTimeout = [ASIHTTPRequest defaultTimeOutSeconds];

    // setup gesture recognizer
    UIView *shakeIcon = [self.view viewWithTag:kTagShakeIcon];
    UITapGestureRecognizer* gestureRecognizer =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pauseStartup)];
    [shakeIcon setUserInteractionEnabled:YES];
    [shakeIcon addGestureRecognizer:gestureRecognizer];
    [gestureRecognizer release];

    // register device with server if no customer id found
    NSString *customerId  = [Utilities getConsumerId];
    if (!customerId) {
        [self purgeData];
        [self registerDevice];
    } else {
        [self validateRegistration];
    }

    // start fake progress bar timer
    mTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                              target:self
                                            selector:@selector(progressBar:)
                                            userInfo:nil
                                             repeats:YES];
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

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // [iOS4] viewWillAppear doesn't get triggered on physics controller
    [self.physicsController viewWillAppear:animated];
}

//------------------------------------------------------------------------------

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    // stop processing physics
    [self.physicsController stopWorld];

    // [iOS4] viewWillDisappear doesn't get triggered on physics controller
    [self.physicsController viewWillDisappear:animated];
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

- (void) purgeData
{
    NSLog(@"StartupViewController: Purgin data...");

    // purge the database
    [Database purgeDatabase];

    // purge the icon directory
    [[IconManager getInstance] deleteAllImages];

    // purge settings
    [Settings clearAllSettings];
}

//------------------------------------------------------------------------------

- (void) runStartupProcess
{
    // set user id for analytics session
    [Analytics setUserId:[Utilities getDeviceId]];

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

    NSLog(@"StartupController: Registering device id...");

    // generate a new device id
    NSString *newDeviceId = [Utilities getDeviceId];
    if (newDeviceId == nil) {
        newDeviceId = [[UIDevice currentDevice] generateGUID];
    }

    // setup an instance of the tiktok api to register the device
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    api.timeOut = mRegistrationTimeout;

    // setup a completion handler to save id after server registration
    api.completionHandler = ^(NSDictionary *response) {

        // verify registeration succeeded
        NSString *status = [response objectForKey:kTikTokApiKeyStatus];
        if ([status isEqualToString:kTikTokApiStatusOkay]) {

            // grab customer id from api
            NSDictionary *results = [response objectForKey:kTikTokApiKeyResults];
            NSString *consumerId  = $string(@"%@", [results objectForKey:@"id"]);

            // cache the customer/device id
            [Utilities cacheDeviceId:newDeviceId];
            [Utilities cacheConsumerId:consumerId];

            // allow the startup process to continue
            [self runStartupProcess];

        // something went horribly wrong...
        } else {
            NSString *error = [response objectForKey:kTikTokApiKeyError];
            NSLog(@"StartupController: registration failed: %@", error);
            NSString *title   = @"Registration Error";
            NSString *message = @"Failed to register with the server.  Please "
                                @"try again later.";
            [Utilities displaySimpleAlertWithTitle:title
                                        andMessage:message];
        }
    };

    // most probably we lost network connection, so put up a HUD and wait till
    // we get connectivity back, one we do restart the startup process
    api.errorHandler = ^(ASIHTTPRequest* request) {
        mRegistrationTimeout *= 2.0f;
        [self waitForInternetConnection];
    };

    // register the device with the server
    [api registerDevice:newDeviceId];
}

//------------------------------------------------------------------------------

- (void) validateRegistration
{
    NSLog(@"StartupController: Validating registration with server...");

    // setup an instance of the tiktok api to check registration
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    api.timeOut = mRegistrationTimeout;

    // setup a completion handler
    api.completionHandler = ^(NSDictionary *response) {
        bool isRegistered = false;

        // parse out registration status
        NSString *status = [response objectForKey:kTikTokApiKeyStatus];
        if ([status isEqualToString:kTikTokApiStatusOkay]) {
            NSDictionary *results = [response objectForKey:kTikTokApiKeyResults];
            isRegistered          = [[results objectForKey:@"registered"] boolValue];
        }

        // allow the startup process to continue
        if (isRegistered) {
            [self runStartupProcess];

        // rerun registration process if server no longer registered
        } else {

            // clean up existing keychain and cached data and
            // re-register with the server
            [Utilities clearConsumerId];
            [Utilities clearNotificationToken];
            [self purgeData];
            [self registerDevice];
        }
    };

    // most probably we lost network connection, so put up a HUD and wait till
    // we get connectivity back, one we do restart the startup process
    api.errorHandler = ^(ASIHTTPRequest* request) {
        mRegistrationTimeout *= 2.0f;
        [self waitForInternetConnection];
    };

    // validate registration with server
    [api validateRegistration];
}

//------------------------------------------------------------------------------

- (void) registerNotifications
{
    // don't re-register
    if (mNotifications) return;

    NSLog(@"StartupController: Registering with notification server...");

    // register with apn server
    UIApplication *application = [UIApplication sharedApplication];
    [application registerForRemoteNotificationTypes:
        (UIRemoteNotificationTypeBadge |
         UIRemoteNotificationTypeSound |
         UIRemoteNotificationTypeAlert)];

    // set flag
    mNotifications = true;
}

//------------------------------------------------------------------------------

- (void) setupLocationTracking
{
    // dont restart tracking
    if (mLocations) return;

    NSLog(@"StartupController: Setting up location tracking...");

    // start up tracking
    [LocationTracker startLocationTracking];

    // set flag
    mLocations = true;
}

//------------------------------------------------------------------------------

- (void) syncCoupons
{
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    api.timeOut = mRegistrationTimeout;

    // trigger completion handler
    NSDate *lastUpdate    = [NSDate date];
    api.completionHandler = ^(NSDictionary *response) {
        mComplete = true;

        // run completion handler
        if (!mPause && self.completionHandler) self.completionHandler();

        // update last update time
        [[Settings getInstance] setLastUpdate:lastUpdate];
    };

    // lost connection? fuck... restart startup process for now...
    api.errorHandler = ^(ASIHTTPRequest* request) {
        [self waitForInternetConnection];
    };

    // sync coupons
    Settings *settings = [Settings getInstance];
    [api syncActiveCoupons:settings.lastUpdate];
}

//------------------------------------------------------------------------------

- (void) progressBar:(NSTimer*)timer
{
    UIProgressView *progressBar = (UIProgressView*)[self.view viewWithTag:kTagProgressBar];
    progressBar.progress       += 0.01;

    // kill timer
    if (progressBar.progress >= 1.0) {
        [mTimer invalidate];
        mTimer = nil;
    }
}

//------------------------------------------------------------------------------

- (void) waitForInternetConnection
{
    // wait for internet connection
    [NetworkConnectivity waitForNetworkWithConnectionHandler:^() {

        // register device with server if no customer id found
        NSString *customerId  = [Utilities getConsumerId];
        if (!customerId) {
            [self purgeData];
            [self registerDevice];
        } else {
            [self validateRegistration];
        }

        // reset progress bar
        UIProgressView *progressBar = (UIProgressView*)[self.view viewWithTag:kTagProgressBar];
        progressBar.progress        = 0.01;

        // kill timer if it is still running
        if (mTimer) {
            [mTimer invalidate];
        }

        // start fake progress bar timer
        mTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                target:self
                                                selector:@selector(progressBar:)
                                                userInfo:nil
                                                repeats:YES];
    }];
}

//------------------------------------------------------------------------------
#pragma mark - Events
//------------------------------------------------------------------------------

- (IBAction) pauseStartup
{
    // startup paused and complete, run completion handler
    if (mPause && mComplete) {
        if (self.completionHandler) self.completionHandler();

    // startup not paused and not complete, pause startup
    } else if (!mPause && !mComplete) {
        mPause = true;

        // tag testflight checkpoint
        [Analytics passCheckpoint:@"EasterEgg"];

        // alert user of easter egg
        NSString *message = @"Congrats! You found the easter egg. You can now toss \
                            Tik and Tok, around as long as you like. Click on the \
                            Shake icon again to continue using the app!";
        [Utilities displaySimpleAlertWithTitle:@"Easter Egg"
                                    andMessage:message];

    // startup paused and not complete, unpause startup
    } else if (mPause && !mComplete) {
        mPause = false;
    }
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
    [mTimer invalidate];
    [mPhysicsController release];
    [mCompletionHandler release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
