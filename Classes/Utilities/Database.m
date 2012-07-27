//
//  Database.m
//  TikTok
//
//  Created by Moiz Merchant on 01/06/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes
//-----------------------------------------------------------------------------

#import "Database.h"
#import "Settings.h"

//-----------------------------------------------------------------------------
// defines
//-----------------------------------------------------------------------------

#define kCurrentDatabaseVersion @"v03"

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface Database ()
    - (void) purgeDatabase:(NSPersistentStoreCoordinator*)coordinator;
    + (NSURL*) applicationDocumentsDirectory;
    + (NSURL*) getStorageUrl;
@end

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation Database

//-----------------------------------------------------------------------------

+ (Database*) getInstance
{
    static Database *sDatabase = nil;
    if (sDatabase == nil) {
        sDatabase = [[[Database alloc] init] retain];
    }
    return sDatabase;
}

//-----------------------------------------------------------------------------

+ (void) purgeDatabase
{
    Database *database = [Database getInstance];
    [database purgeDatabase:database.coordinator];
}

//-----------------------------------------------------------------------------

- (void) purgeDatabase:(NSPersistentStoreCoordinator*)coordinator
{
    NSError *error    = nil;
    NSURL *storageUrl = [Database getStorageUrl];

    // grab the persistant store
    NSPersistentStore *store = [coordinator persistentStoreForURL:storageUrl];
    if (store != nil) {
        [coordinator removePersistentStore:store error:&error];
        if (error != nil) {
            NSLog(@"Database: failed to remove store '%@': %@", storageUrl, error);
            error = nil;
        }
    }

    // remove db from filesystem
    [[NSFileManager defaultManager] removeItemAtURL:storageUrl error:&error];
    if (error != nil) {
        NSLog(@"Database: failed to database file '%@': %@", storageUrl, error);
    }
}

//-----------------------------------------------------------------------------

/**
 * Returns the managed object context for the application.  If the context
 * doesn't exist, it is created and bound to the persistant store coordinator.
 */
- (NSManagedObjectContext*) context
{
    // lazy allocation
    if (mManagedObjectContext != nil)  return mManagedObjectContext;

    // allocate the object context and attach it to the persistant storage
    if (self.coordinator != nil) {
        mManagedObjectContext = [[[NSManagedObjectContext alloc] init] retain];
        [mManagedObjectContext setPersistentStoreCoordinator:self.coordinator];
    }

    return mManagedObjectContext;
}

//------------------------------------------------------------------------------

/**
 * Returns the managed object model for the application.  If the model doesn't
 * exist, it is created from the model.
 */
- (NSManagedObjectModel*) model
{
    // lazy allocation
    if (mManagedObjectModel != nil)  return mManagedObjectModel;

    // allocate a new model from the data model on disk
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"DataModel" ofType:@"momd"];
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
- (NSPersistentStoreCoordinator*) coordinator
{
    // lazy allocation
    if (mPersistantStoreCoordinator != nil) return mPersistantStoreCoordinator;

    NSError *error = nil;

    // construct path to storage on disk
    NSURL *storageUrl = [Database getStorageUrl];

    // allocate a persistant store coordinator, with the model
    mPersistantStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
        initWithManagedObjectModel:self.model];

    // grab the meta data from the current database
    NSDictionary *metaData =
        [NSPersistentStoreCoordinator 
            metadataForPersistentStoreOfType:NSSQLiteStoreType
                                         URL:storageUrl
                                       error:&error];

    // if there is no meta data purge the db
    if (metaData == nil) {
        [self purgeDatabase:mPersistantStoreCoordinator];

    // check the version of the database
    } else {

        // grab the dataabse version
        NSArray *versions = [metaData objectForKey:@"NSStoreModelVersionIdentifiers"];
        NSString *version = [versions objectAtIndex:0];

        // if its not equal to the most current db, purge it
        if (![version isEqualToString:kCurrentDatabaseVersion]) {
            NSLog(@"Database: purging database %@", version);
            [self purgeDatabase:mPersistantStoreCoordinator];
        }
    }

    // options to allow auto migration
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
        [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
        nil];

    // attempt to add a store to the coordinator
    bool result = [mPersistantStoreCoordinator
        addPersistentStoreWithType:NSSQLiteStoreType
                     configuration:nil
                               URL:storageUrl
                           options:options
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

        // log the error and purge the database
        NSLog(@"PersistentStoreCoordinator error: %@, %@", error, [error userInfo]);
        [self purgeDatabase:mPersistantStoreCoordinator];
        mPersistantStoreCoordinator = nil;
        return self.coordinator;
    }

    return mPersistantStoreCoordinator;
}

//------------------------------------------------------------------------------
#pragma mark - Filesystem
//------------------------------------------------------------------------------

+ (NSURL*) applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager]
        URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask]
        lastObject];
}

//------------------------------------------------------------------------------

+ (NSURL*) getStorageUrl
{
    // construct path to storage on disk
    NSURL *storageUrl = [[self applicationDocumentsDirectory]
        URLByAppendingPathComponent:@"TikTok.sqlite"];
    return storageUrl;
}

//------------------------------------------------------------------------------
#pragma mark - Memory Management
//-----------------------------------------------------------------------------

- (void) dealloc
{
    [mManagedObjectContext release];
    [mManagedObjectModel release];
    [mPersistantStoreCoordinator release];
    [super dealloc];
}

//-----------------------------------------------------------------------------

@end
