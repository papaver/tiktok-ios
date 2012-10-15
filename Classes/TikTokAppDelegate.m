//
//  TikTokAppDelegate.m
//  TikTok
//
//  Created by Moiz Merchant on 4/19/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "TikTokAppDelegate.h"
#import "Constants.h"
#import "Database.h"
#import "FacebookManager.h"
#import "LocationTracker.h"
#import "Logger.h"
#import "TikTokApi.h"
#import "StartupViewController.h"
#import "Settings.h"
#import "SoftNagManager.h"
#import "Utilities.h"

//------------------------------------------------------------------------------
// defines
//------------------------------------------------------------------------------

#define appState(app) [self getStringForActiveState:app.applicationState]

#if LOGGING_APP_DELEGATE
    #define NSLog(...) [Logger logInfo:$string(__VA_ARGS__)]
#endif

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface TikTokAppDelegate ()
    - (void) handleNotificationsForApplication:(UIApplication*)application
                                   withOptions:(NSDictionary*)launchOptions;
    - (void) setupNavigationController;
    - (NSString*) getStringForActiveState:(UIApplicationState)state;
@end

//------------------------------------------------------------------------------
// interface implemenation
//------------------------------------------------------------------------------

@implementation TikTokAppDelegate

//------------------------------------------------------------------------------

@synthesize window               = mWindow;
@synthesize tabBarController     = mTabBarController;
@synthesize navigationController = mNavigationController;
@synthesize startupController    = mStartupController;

//------------------------------------------------------------------------------
#pragma mark - Application lifecycle
//------------------------------------------------------------------------------

- (BOOL) application:(UIApplication*)application
    didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    // override point for customization after application launch.
    NSLog(@"Application: Did Finish Launching With Options: %@", appState(application));
    NSLog(@"Application: Launch Options: %@", launchOptions);

    // start up analytics session
    [Analytics startSession];

    // have to manually add the tabbar controller to the navigation controller
    [self setupNavigationController];

    // set startup completion handler to show navigation controller
    self.startupController.completionHandler = ^{

        // display main navigation controller
        self.window.rootViewController = self.navigationController;

        // alert soft nag manager of app launch
        [SoftNagManager appLaunched];
    };

    // handle any notification sent to the app on startup
    [self handleNotificationsForApplication:application withOptions:launchOptions];

    // check if we were woken up because of background location services
    id locationValue = [launchOptions objectForKey:UIApplicationLaunchOptionsLocationKey];
    if (locationValue) {
        NSLog(@"Application woken up by background location services.");
        [LocationTracker startLocationTracking];
    }

    return YES;
}

//------------------------------------------------------------------------------

/**
 * Sent when the application is about to move from active to inactive state.
 * This can occur for certain types of temporary interruptions (such as an
 * incoming phone call or SMS message) or when the user quits the application
 * and it begins the transition to the background state.
 * Use this method to pause ongoing tasks, disable timers, and throttle down
 * OpenGL ES frame rates. Games should use this method to pause the game.
 */
- (void) applicationWillResignActive:(UIApplication*)application
{
    NSLog(@"Application: Will Resign Active: %@", appState(application));

    // save the database
    NSError *error = nil;
    [[[Database getInstance] context] save:&error];
    if (error != nil) {
        NSLog(@"AppDelegate: Failed to save managed context!");
    }
}

//------------------------------------------------------------------------------

/**
 * Use this method to release shared resources, save user data, invalidate
 * timers, and store enough application state information to restore your
 * application to its current state in case it is terminated later.
 * If your application supports background execution, called instead of
 * applicationWillTerminate: when the user quits.
 */
- (void) applicationDidEnterBackground:(UIApplication*)application
{
    NSLog(@"Application: Did Enter Background: %@", appState(application));
    [LocationTracker backgroundLocationTracking];

    /* local notification example
    [Utilities postLocalNotificationInBackgroundWithBody:@"App entered background"
                                                  action:@"Read Message"
                                         iconBadgeNumber:0];
    */
}

//------------------------------------------------------------------------------

/**
 * Called as part of transition from the background to the inactive state:
 * here you can undo many of the changes made on entering the background.
 */
- (void) applicationWillEnterForeground:(UIApplication*)application
{
    NSLog(@"Application: Will Enter Foreground: %@", appState(application));
    [LocationTracker foregroundLocationTracking];

    // alert appirater of app foreground
    [Appirater appEnteredForeground:YES];

    // alert soft nag manager of app foreground
    [SoftNagManager appEnteredForeground];

    // sync coupons
    Settings *settings = [Settings getInstance];
    [self syncCoupons:settings.lastUpdate];
}

//------------------------------------------------------------------------------

/**
 * Restart any tasks that were paused (or not yet started) while the
 * application was inactive. If the application was previously in the
 * background, optionally refresh the user interface.
 */
- (void) applicationDidBecomeActive:(UIApplication*)application
{
    NSLog(@"Application: Did Become Active: %@", appState(application));

    // make sure there is a window attached
    if (!self.window.subviews.count) {

        // attach startup view to window
        self.window.rootViewController = self.startupController;

        // we need this to allow events to propagate through properly
        [self.window makeKeyAndVisible];

        // alert appirater of app launch
        [Appirater appLaunched:YES];
    }

    // clear out notifications
    if (application.applicationIconBadgeNumber != 0) {
        application.applicationIconBadgeNumber = 0;
    }
}

//------------------------------------------------------------------------------

/**
 * Called when the application is about to terminate.
 * See also applicationDidEnterBackground:.
 */
- (void) applicationWillTerminate:(UIApplication*)application
{
    NSLog(@"Application: Will Terminate: %@", appState(application));
    [LocationTracker backgroundLocationTracking];
}

//------------------------------------------------------------------------------
#pragma mark - Notifications
//------------------------------------------------------------------------------

- (void) application:(UIApplication*)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    NSLog(@"Notifications: Registering device, token: %@.", deviceToken);

    // check if the token is the same as the cached token
    NSString *newToken = [deviceToken description];
    NSString *oldToken = [Utilities getNotificationToken];
    if (![newToken isEqualToString:oldToken]) {

        // cache and register with the server if different
        TikTokApi *api = [[[TikTokApi alloc] init] autorelease];

        // setup completion handler
        api.completionHandler = ^(NSDictionary* response) {
            NSString *status = [response objectForKey:kTikTokApiKeyStatus];
            if ([status isEqualToString:kTikTokApiStatusOkay]) {
                NSLog(@"Notifications: Caching new token %@", newToken);
                [Utilities cacheNotificationToken:newToken];
            }
        };

        // register token with server
        [api registerNotificationToken:newToken];
    }
}

//------------------------------------------------------------------------------

- (void) application:(UIApplication*)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    NSLog(@"Notifications: Error in registration: %@", error);

    // clear the token from the cache
    [Utilities clearNotificationToken];

    // clear the token out from the server
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    [api registerNotificationToken:@""];
}

//------------------------------------------------------------------------------

/**
 * Handling a local notification when an application is already running.
 */
- (void) application:(UIApplication*)application
    didReceiveLocalNotification:(UILocalNotification*)notification
{
    NSLog(@"Application: Did Recieve Local Notification.");
}

//------------------------------------------------------------------------------

/**
 * Handling a remote notification when an application is already running.
 */
- (void) application:(UIApplication*)application
    didReceiveRemoteNotification:(NSDictionary*)userInfo
{
    NSLog(@"Application: Did Recieve Remote Notification.");

    // cleat out badge
    application.applicationIconBadgeNumber = 0;

    // sync coupons
    Settings *settings = [Settings getInstance];
    [self syncCoupons:settings.lastUpdate];
}

//------------------------------------------------------------------------------
#pragma mark - UITabBarController Delegate
//------------------------------------------------------------------------------

/**
 * This is kind of a hack, but this allows us to embed the tabbar under a
 * navigation bar and allow the navbar items to propate up correctly, else since
 * the nav bar doesn't correctly pass up the items.
 */
- (void) tabBarController:(UITabBarController*)tabBarController
  didSelectViewController:(UIViewController*)viewController
{
    tabBarController.title                             = viewController.title;
    tabBarController.navigationItem.titleView          = viewController.navigationItem.titleView;
    tabBarController.navigationItem.leftBarButtonItem  = viewController.navigationItem.leftBarButtonItem;
    tabBarController.navigationItem.rightBarButtonItem = viewController.navigationItem.rightBarButtonItem;
}

//------------------------------------------------------------------------------
#pragma - Helper Functions
//------------------------------------------------------------------------------

- (void) syncCoupons:(NSDate*)lastUpdate
{
    // sync any newly available coupons
    NSDate *currentDate    = [NSDate date];
    __block TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    api.completionHandler  = ^(NSDictionary *response) {
        [[Settings getInstance] setLastUpdate:currentDate];
    };

    // sync coupons
    [api syncActiveCoupons:lastUpdate];
}

//------------------------------------------------------------------------------

- (void) handleNotificationsForApplication:(UIApplication*)application
                               withOptions:(NSDictionary*)launchOptions
{
    // clear out badge
    application.applicationIconBadgeNumber = 0;

    // handle local notifications
    UILocalNotification *localNotification =
        [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotification) {
    }

    // handle remote notifications
    NSDictionary *userInfo =
        [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        Settings *settings = [Settings getInstance];
        [self syncCoupons:settings.lastUpdate];
    }
}

//------------------------------------------------------------------------------

- (void) setupNavigationController
{
    // hacky... force the initial view to load so we can get the nav bar icaons
    // to appear correctly through the tab bar delegate
    UIViewController *viewController =
        [self.tabBarController.viewControllers objectAtIndex:0];
    [viewController view];
    [self tabBarController:self.tabBarController didSelectViewController:viewController];

    // manually add the tabbar controller to the navigation controller
    [self.navigationController setViewControllers:$array(self.tabBarController)
                                         animated:NO];
    [self.navigationController setToolbarHidden:YES animated:NO];
}

//------------------------------------------------------------------------------

- (NSString*) getStringForActiveState:(UIApplicationState)state
{
    switch (state) {
        case UIApplicationStateActive:
            return @"UIApplicationStateActive";
        case UIApplicationStateInactive:
            return @"UIApplicationStateInactive";
        case UIApplicationStateBackground:
            return @"UIApplicationStateBackground";
    }
}

//------------------------------------------------------------------------------
#pragma - Handle Url
//------------------------------------------------------------------------------

/**
 * For 4.2+ support
 */
- (BOOL) application:(UIApplication*)application
            openURL:(NSURL*)url
  sourceApplication:(NSString*)sourceApplication
         annotation:(id)annotation
{
    // facebook
    if ([[url absoluteString] hasPrefix:$string(@"fb%@", FACEBOOK_API_KEY)]) {
        FacebookManager* facebookManager = [FacebookManager getInstance];
        return [facebookManager.facebook handleOpenURL:url];
    }
    return YES;
}

//------------------------------------------------------------------------------

- (BOOL) application:(UIApplication*)application handleOpenURL:(NSURL*)url
{
    // facebook
    if ([[url absoluteString] hasPrefix:$string(@"fb%@", FACEBOOK_API_KEY)]) {
        FacebookManager* facebookManager = [FacebookManager getInstance];
        return [facebookManager.facebook handleOpenURL:url];
    }
    return YES;
}

//------------------------------------------------------------------------------
#pragma mark - Memory management
//------------------------------------------------------------------------------

/**
 * Free up as much memory as possible by purging cached data objects that can
 * be recreated (or reloaded from disk) later.
 */
- (void) applicationDidReceiveMemoryWarning:(UIApplication*)application
{
}

//------------------------------------------------------------------------------

- (void) dealloc
{
    [mStartupController release];
    [mNavigationController release];
    [mTabBarController release];
    [mWindow release];

    [super dealloc];
}

//------------------------------------------------------------------------------

@end

