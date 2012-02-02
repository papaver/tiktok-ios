//
//  Database.h
//  TikTok
//
//  Created by Moiz Merchant on 01/06/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes
//-----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface Database : NSObject
{
@private

    NSManagedObjectContext       *mManagedObjectContext;
    NSManagedObjectModel         *mManagedObjectModel;
    NSPersistentStoreCoordinator *mPersistantStoreCoordinator;
}

//-----------------------------------------------------------------------------

@property (nonatomic, retain, readonly) NSManagedObjectContext       *context;
@property (nonatomic, retain, readonly) NSManagedObjectModel         *model;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *coordinator;

//-----------------------------------------------------------------------------

+ (Database*) getInstance;
+ (void) purgeDatabase;

//-----------------------------------------------------------------------------

@end
