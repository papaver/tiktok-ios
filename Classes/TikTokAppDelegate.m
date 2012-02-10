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
#import "ASIHTTPRequest.h"
#import "Constants.h"
#import "Database.h"
#import "FacebookManager.h"
#import "TikTokApi.h"
#import "StartupViewController.h"
#import "Settings.h"
#import "Utilities.h"

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface TikTokAppDelegate ()
    - (void) handleNotificationsForApplication:(UIApplication*)application
                                   withOptions:(NSDictionary*)launchOptions;
    - (void) setupNavigationController;
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
    NSLog(@"Application did finish launching with options.");

    // start up test flight and flurry
    [TestFlight takeOff:TESTFLIGHT_API_KEY];
    [FlurryAnalytics setSecureTransportEnabled:YES];
    [FlurryAnalytics startSession:FLURRY_DEV_API_KEY];

    // handle any notification sent to the app on startup
    [self handleNotificationsForApplication:application withOptions:launchOptions];

    // have to manually add the tabbar controller to the navigation controller
    [self setupNavigationController];

    // set startup completion handler to show navigation controller 
    self.startupController.completionHandler = ^{
        self.window.rootViewController = self.navigationController;
    };

    // we need this to allow events to propagate through properly
    [self.window makeKeyAndVisible];

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
    NSLog(@"Application entered background state.");

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
}

//------------------------------------------------------------------------------

/**
 * Restart any tasks that were paused (or not yet started) while the 
 * application was inactive. If the application was previously in the 
 * background, optionally refresh the user interface.
 */
- (void) applicationDidBecomeActive:(UIApplication*)application 
{
    NSLog(@"Application entered foreground state.");
}

//------------------------------------------------------------------------------

/**
 * Called when the application is about to terminate.
 * See also applicationDidEnterBackground:.
 */
- (void) applicationWillTerminate:(UIApplication*)application 
{
    NSLog(@"Application will terminate.");
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
        api.completionHandler = ^(ASIHTTPRequest *request){
            if (request.responseStatusCode == 200) {
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
    NSLog(@"Application did recieve local notification.");

    // update badge number
    application.applicationIconBadgeNumber = 
        notification.applicationIconBadgeNumber - 1;
}

//------------------------------------------------------------------------------

/**
 * Handling a remote notification when an application is already running.
 */
- (void) application:(UIApplication*)application 
    didReceiveRemoteNotification:(NSDictionary*)userInfo
{
    NSLog(@"Application did recieve remote notification.");

    // update badge number
    application.applicationIconBadgeNumber = 0;

    // [moiz] fix up how notifications work...

    // sync any newly available coupons
    //TikTokApi *api = [[[TikTokApi alloc] init] autorelease];

    //Settings *settings = [Settings getInstance];
    //[api syncActiveCoupons:settings.lastUpdate];
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

- (void) handleNotificationsForApplication:(UIApplication*)application
                               withOptions:(NSDictionary*)launchOptions
{
    // handle local notifications
    UILocalNotification *localNotification =
        [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotification) {
        application.applicationIconBadgeNumber = 0;
            //localNotification.applicationIconBadgeNumber - 1;
    }

    // handle remote notifications
    NSDictionary *userInfo =
        [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        application.applicationIconBadgeNumber = 0;
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
    if ([sourceApplication isEqualToString:@"com.facebook.Facebook"]) {
        FacebookManager* facebookManager = [FacebookManager getInstance];
        return [facebookManager.facebook handleOpenURL:url];
    }
    return YES;
}

//------------------------------------------------------------------------------

- (BOOL) application:(UIApplication*)application handleOpenURL:(NSURL*)url 
{
    // facebook
    if ([[url absoluteString] hasPrefix:$string(@"fb%@",FACEBOOK_API_KEY)]) {
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

