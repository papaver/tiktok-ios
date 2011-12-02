//
//  Device.h
//  FifteenMinutes
//
//  Created by Moiz Merchant on 6/6/11.
//  Copyright 2011 Bunnies on Acid. All rights reserved.
//

//------------------------------------------------------------------------------
// imports 
//------------------------------------------------------------------------------

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>

//------------------------------------------------------------------------------
// interface definition 
//------------------------------------------------------------------------------

@interface Device : NSManagedObject 
{
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) NSString *deviceId;

//------------------------------------------------------------------------------

/**
 * Add the device to the store. If a device already exists, a new one will not
 * be added.
 */
+ (Device*) addDevice:(NSString*)deviceId toContext:(NSManagedObjectContext*)context;

/**
 * Query the context for the device id.  nil is returned if a device id isn't
 * found.
 */
+ (Device*) getDeviceFromContext:(NSManagedObjectContext*)context;

//------------------------------------------------------------------------------

@end
