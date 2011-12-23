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
// forward declarations
//------------------------------------------------------------------------------

@class StartupViewController;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface TikTokAppDelegate : NSObject <UIApplicationDelegate> 
{
    UIWindow               *mWindow;
    UITabBarController     *mTabBarController;
    UINavigationController *mNavigationController;
    StartupViewController  *mStartupController;

@private

    NSManagedObjectContext       *mManagedObjectContext;
    NSManagedObjectModel         *mManagedObjectModel;
    NSPersistentStoreCoordinator *mPersistantStoreCoordinator;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) IBOutlet UIWindow               *window;
@property (nonatomic, retain) IBOutlet UITabBarController     *tabBarController;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet StartupViewController  *startupController;

@property (nonatomic, retain, readonly) NSManagedObjectContext       *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel         *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

//------------------------------------------------------------------------------
          
- (NSURL*) applicationDocumentsDirectory;

//------------------------------------------------------------------------------

@end

