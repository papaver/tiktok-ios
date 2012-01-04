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
#import "FacebookManager.h"
#import "TikTokApi.h"
#import "StartupViewController.h"
#import "Utilities.h"

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

    // handle local notifications
    UILocalNotification *localNotification =
        [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotification) {
        application.applicationIconBadgeNumber = 
            localNotification.applicationIconBadgeNumber - 1;
    }

    // handle remote notifications
    NSDictionary *userInfo =
        [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        application.applicationIconBadgeNumber = 0;
    }
    
    // hide navigation toolbar
    [self.navigationController setToolbarHidden:YES animated:NO];

    // start up test flight
    [TestFlight takeOff:TESTFLIGHT_API_KEY];

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

    // [moiz] this will probably change once we change the way devices are
    //   tracked, using the notification device token doesn't seem to be the 
    //   best idea
    [mStartupController onDeviceTokenReceived:deviceToken];
}

//------------------------------------------------------------------------------
 
- (void) application:(UIApplication*)application
    didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    NSLog(@"Notifications: Error in registration: %@", error);
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

    // get list of available coupons
    TikTokApi *api = [[TikTokApi new] autorelease];
    api.managedContext = self.managedObjectContext;
    [api getActiveCoupons];
}

//------------------------------------------------------------------------------
#pragma mark - Core Data Stack
//------------------------------------------------------------------------------

/**
 * Returns the managed object context for the application.  If the context
 * doesn't exist, it is created and bound to the persistant store coordinator.
 */
- (NSManagedObjectContext*) managedObjectContext
{
    // lazy allocation
    if (mManagedObjectContext != nil)  return mManagedObjectContext;

    // allocate the object context and attach it to the persistant storage
    NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
    if (coordinator != nil) {
        mManagedObjectContext = [[NSManagedObjectContext alloc] init]; 
        [mManagedObjectContext setPersistentStoreCoordinator:coordinator];
    }

    return mManagedObjectContext;
}

//------------------------------------------------------------------------------

/**
 * Returns the managed object model for the application.  If the model doesn't 
 * exist, it is created from the model.
 */
- (NSManagedObjectModel*) managedObjectModel
{
    // lazy allocation
    if (mManagedObjectModel != nil)  return mManagedObjectModel;

    // allocate a new model from the data model on disk
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"DataModel" ofType:@"mom"];
    NSURL *modelUrl     = [NSURL fileURLWithPath:modelPath];
    mManagedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelUrl];

    return mManagedObjectModel;
}

//------------------------------------------------------------------------------

/**
 * Returns the persistant store coordinator for the application.  If the 
 * coordinator doesn't already exist, it is created and the application's store
 * is added to it.
 */
- (NSPersistentStoreCoordinator*) persistentStoreCoordinator
{
    // lazy allocation
    if (mPersistantStoreCoordinator != nil) return mPersistantStoreCoordinator; 

    // construct path to storage on disk
    NSURL *storageUrl = [[self applicationDocumentsDirectory] 
        URLByAppendingPathComponent:@"TikTok.sqlite"];
    NSLog(@"sqlite -> %@", storageUrl);

    // [moiz][TEMP] move this back into the if statement below
    [[NSFileManager defaultManager] removeItemAtURL:storageUrl error:nil];

    // allocate a persistant store coordinator, attached to the storage db
    NSError *error = nil;
    mPersistantStoreCoordinator = [[NSPersistentStoreCoordinator alloc] 
        initWithManagedObjectModel:self.managedObjectModel];
    bool result = [mPersistantStoreCoordinator 
        addPersistentStoreWithType:NSSQLiteStoreType 
                     configuration:nil 
                               URL:storageUrl 
                           options:nil 
                             error:&error];

    // make sure the persistant store was setup properly
    if (!result) {

        /*
         * Typical reasons for an error here include:
         *  - The persistant store is not accessible.
         *  - The schema for the persistant store is incompatible with the 
         *    current managed object model.
         *
         * If the persistant store is no accessible, there is typically 
         * something wrong with the file path.  Often the file URL is pointing 
         * into the applications resource directory instead of the writable 
         * directoy.
         *
         * If you encounter schema incompatibility errors during development, 
         * you can reduce thier frequency by:
         *
         *   - Simply deleting the existing store:
         *       [[NSFileManager defaultManager] removeItemAtURL:storeURL 
         *                                                 error:nil];
         *
         *   - Performing automatic lightweight migration by passing the 
         *     following directory as the options parameter:
         *       [NSDictionary dictionaryWithObjectsAndKeys:
         *           [NSNumber numberWithBool:YES], NSMigratePersistantStoresAutomaticallyOption,
         *           [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
         *           nil];
         *
         * Lightweight migration will only work for a limited set of schema 
         * changes.
         */

        NSLog(@"PersistentStoreCoordinator error: %@, %@", error, [error userInfo]);
        abort();
    }

    return mPersistantStoreCoordinator;
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
#pragma mark - Application's Documents directory
//------------------------------------------------------------------------------

- (NSURL*) applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] 
        URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] 
        lastObject];
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

    [mManagedObjectContext release];
    [mManagedObjectModel release];
    [mPersistantStoreCoordinator release];

    [super dealloc];
}

//------------------------------------------------------------------------------

@end

