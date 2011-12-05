//
//  TikTokAppDelegate.m
//  FifteenMinutes
//
//  Created by Moiz Merchant on 4/19/11.
//  Copyright 2011 Bunnies on Acid. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "TikTokAppDelegate.h"
#import "TikTokApi.h"

//------------------------------------------------------------------------------
// interface implemenation
//------------------------------------------------------------------------------

@implementation TikTokAppDelegate

//------------------------------------------------------------------------------

@synthesize window               = m_window;
@synthesize tabBarController     = m_tab_bar_controller;
@synthesize navigationController = m_navigation_controller;

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Application lifecycle
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
    
    // add the navigation controller's view to the window and display.
    [self.window addSubview:self.tabBarController.view];
    [self.window makeKeyAndVisible];

    // configure navigation bar
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.translucent = YES;

    // configure local/remote notifications
    [application registerForRemoteNotificationTypes:
        (UIRemoteNotificationTypeBadge | 
         UIRemoteNotificationTypeSound |
         UIRemoteNotificationTypeAlert)];

    return YES;
}

//------------------------------------------------------------------------------

- (void) applicationWillResignActive:(UIApplication*)application 
{
    /*
     Sent when the application is about to move from active to inactive state. 
     This can occur for certain types of temporary interruptions (such as an 
     incoming phone call or SMS message) or when the user quits the application 
     and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down 
     OpenGL ES frame rates. Games should use this method to pause the game.
    */
}

//------------------------------------------------------------------------------

- (void) applicationDidEnterBackground:(UIApplication*)application 
{
    /*
     Use this method to release shared resources, save user data, invalidate 
     timers, and store enough application state information to restore your 
     application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of 
     applicationWillTerminate: when the user quits.
    */

    //NSInteger UIInvalidBackgroundTask = 0;

    //NSLog(@"Application entered background state.");
    //NSAssert(self.bgTask == UIInvalidBackgroundTask, nil);
 
    /* local notification example 
    bgTask = [application beginBackgroundTaskWithExpirationHandler: ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [application endBackgroundTask:self.bgTask];
            self.bgTask = UIInvalidBackgroundTask;
        });
    }];
 
    dispatch_async(dispatch_get_main_queue(), ^{
        while ([application backgroundTimeRemaining] > 1.0) {
            UILocalNotification *localNotif = [[UILocalNotification alloc] init];
            if (localNotif) {
                localNotif.alertBody   = @"a message for you.";
                localNotif.alertAction = @"Read Message";
                localNotif.soundName   = UILocalNotificationDefaultSoundName; 
                localNotif.applicationIconBadgeNumber = 1;
                [application presentLocalNotificationNow:localNotif];
                [localNotif release];
                break;
            }
        }

        [application endBackgroundTask:self.bgTask];
        self.bgTask = UIInvalidBackgroundTask;
    });
    */
}

//------------------------------------------------------------------------------

- (void) applicationWillEnterForeground:(UIApplication*)application 
{
    /*
     Called as part of transition from the background to the inactive state: 
     here you can undo many of the changes made on entering the background.
    */
}

//------------------------------------------------------------------------------

- (void) applicationDidBecomeActive:(UIApplication*)application 
{
    /*
     Restart any tasks that were paused (or not yet started) while the 
     application was inactive. If the application was previously in the 
     background, optionally refresh the user interface.
    */

    NSLog(@"Application entered foreground state.");
}

//------------------------------------------------------------------------------

- (void) applicationWillTerminate:(UIApplication*)application 
{
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
    */
}

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Notifications
//------------------------------------------------------------------------------

- (void) application:(UIApplication*)application 
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken 
{
    NSLog(@"Notifications: Registering device, token: %@.", deviceToken);

    [TikTokApi setDeviceToken:deviceToken];
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
#pragma mark -
#pragma mark Core Data Stack
//------------------------------------------------------------------------------

/**
 * Returns the managed object context for the application.  If the context
 * doesn't exist, it is created and bound to the persistant store coordinator.
 */
- (NSManagedObjectContext*) managedObjectContext
{
    if (m_managed_object_context != nil) {
        return m_managed_object_context;
    }

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
    if (m_managed_object_model != nil) {
        return m_managed_object_model;
    }

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
    if (m_persistent_store_coordinator != nil) {
        return m_persistent_store_coordinator;
    }

    // construct path to storage on disk
    NSURL *storage_url = [[self applicationDocumentsDirectory] 
        URLByAppendingPathComponent:@"15Minutes.sqlite"];
    NSLog(@"sqlite -> %@", storage_url);

    // [-moiz] move this back into the if statement below
    [[NSFileManager defaultManager] removeItemAtURL:storage_url error:nil];

    // allocate a persistant store coordinator, attached to the storage db
    NSError *error = nil;
    m_persistent_store_coordinator = [[NSPersistentStoreCoordinator alloc] 
        initWithManagedObjectModel:self.managedObjectModel];
    bool result = [m_persistent_store_coordinator addPersistentStoreWithType:NSSQLiteStoreType 
                                                               configuration:nil 
                                                                         URL:storage_url 
                                                                     options:nil 
                                                                       error:&error];

    // make sure the persistant store was setup properly
    if (!result) {
        /*
         * Typical reasons for an error here include:
         *  - The persistant store is not accessible.
         *  - The schema forthe persistant store is incompatible with the 
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
#pragma mark -
#pragma mark Application's Documents directory
//------------------------------------------------------------------------------

- (NSURL*) applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] 
        URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] 
        lastObject];
}

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Memory management
//------------------------------------------------------------------------------

- (void) applicationDidReceiveMemoryWarning:(UIApplication*)application 
{
    /*
     Free up as much memory as possible by purging cached data objects that can 
     be recreated (or reloaded from disk) later.
    */
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

