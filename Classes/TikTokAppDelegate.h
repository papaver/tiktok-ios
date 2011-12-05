//
//  TikTokAppDelegate.h
//  TikTok
//
//  Created by Moiz Merchant on 4/19/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface TikTokAppDelegate : NSObject <UIApplicationDelegate> 
{
    UIWindow               *m_window;
    UITabBarController     *m_tab_bar_controller;
    UINavigationController *m_navigation_controller;

@private

    NSManagedObjectContext       *m_managed_object_context;
    NSManagedObjectModel         *m_managed_object_model;
    NSPersistentStoreCoordinator *m_persistent_store_coordinator;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) IBOutlet UIWindow               *window;
@property (nonatomic, retain) IBOutlet UITabBarController     *tabBarController;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@property (nonatomic, retain, readonly) NSManagedObjectContext       *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel         *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

//------------------------------------------------------------------------------
          
- (NSURL*) applicationDocumentsDirectory;

//------------------------------------------------------------------------------

@end

