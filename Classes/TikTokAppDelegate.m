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
#import "TikTokApi.h"
#import "StartupViewController.h"
#import "Utilities.h"

//------------------------------------------------------------------------------
// interface implemenation
//------------------------------------------------------------------------------

@implementation TikTokAppDelegate

//------------------------------------------------------------------------------

@synthesize window               = m_window;
@synthesize tabBarController     = m_tab_bar_controller;
@synthesize navigationController = m_navigation_controller;
@synthesize startupController    = m_startup_controller;

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
    
    // add the startup controller to the main view
    [self.window addSubview:self.startupController.view];
    [self.window makeKeyAndVisible];

    // configure navigation bar
    //self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    //self.navigationController.navigationBar.translucent = YES;

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
    [m_startup_controller onDeviceTokenReceived:deviceToken];
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
    if (m_managed_object_context != nil)  return m_managed_object_context;

    // allocate the object context and attach it to the persistant storage
    NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
    if (coordinator != nil) {
        m_managed_object_context = [[NSManagedObjectContext alloc] init]; 
        [m_managed_object_context setPersistentStoreCoordinator:coordinator];
    }

    return m_managed_object_context;
}

//------------------------------------------------------------------------------

/**
 * Returns the managed object model for the application.  If the model doesn't 
 * exist, it is created from the model.
 */
- (NSManagedObjectModel*) managedObjectModel
{
    // lazy allocation
    if (m_managed_object_model != nil)  return m_managed_object_model;

    // allocate a new model from the data model on disk
    NSString *model_path   = [[NSBundle mainBundle] pathForResource:@"DataModel" ofType:@"mom"];
    NSURL *model_url       = [NSURL fileURLWithPath:model_path];
    m_managed_object_model = [[NSManagedObjectModel alloc] initWithContentsOfURL:model_url];

    return m_managed_object_model;
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
    if (m_persistent_store_coordinator != nil) {
        return m_persistent_store_coordinator;
    }

    // construct path to storage on disk
    NSURL *storage_url = [[self applicationDocumentsDirectory] 
        URLByAppendingPathComponent:@"TikTok.sqlite"];
    NSLog(@"sqlite -> %@", storage_url);

    // [moiz][TEMP] move this back into the if statement below
    [[NSFileManager defaultManager] removeItemAtURL:storage_url error:nil];

    // allocate a persistant store coordinator, attached to the storage db
    NSError *error = nil;
    m_persistent_store_coordinator = [[NSPersistentStoreCoordinator alloc] 
        initWithManagedObjectModel:self.managedObjectModel];
    bool result = [m_persistent_store_coordinator 
        addPersistentStoreWithType:NSSQLiteStoreType 
                     configuration:nil 
                               URL:storage_url 
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

    return m_persistent_store_coordinator;
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
    [m_navigation_controller release];
    [m_tab_bar_controller release];
    [m_window release];

    [m_managed_object_context release];
    [m_managed_object_model release];
    [m_persistent_store_coordinator release];

    [super dealloc];
}

//------------------------------------------------------------------------------

@end

