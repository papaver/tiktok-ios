//
//  Device.m
//  FifteenMinutes
//
//  Created by Moiz Merchant on 6/6/11.
//  Copyright 2011 Bunnies on Acid. All rights reserved.
//

//------------------------------------------------------------------------------
// imports 
//------------------------------------------------------------------------------

#import "Device.h"

//------------------------------------------------------------------------------
// interface implementation 
//------------------------------------------------------------------------------

@implementation Device

//------------------------------------------------------------------------------

@dynamic deviceId;

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Static methods
//------------------------------------------------------------------------------

+ (Device*) addDevice:(NSString*)deviceId toContext:(NSManagedObjectContext*)context
{
    // make sure there is only one device saved in the context
    NSAssert([Device getDeviceFromContext:context] == nil, 
        @"addDevice: device alredy exists in context.");

    // create a new device object
    Device *device = (Device*)[NSEntityDescription 
        insertNewObjectForEntityForName:@"Device" 
                 inManagedObjectContext:context];
    device.deviceId = deviceId;

    return device;
}

//------------------------------------------------------------------------------

+ (Device*) getDeviceFromContext:(NSManagedObjectContext*)context
{
    // grab the device description
    NSEntityDescription *description = [NSEntityDescription
        entityForName:@"Device" inManagedObjectContext:context];

    // create a device fetch request
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:description];

    // setup the request to lookup all devices
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"deviceId == *"];
    [request setPredicate:predicate];

    // return the device if it already exists in the context
    NSError *error = nil;
    NSArray *array = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"failed to query context for device: %@", error);
        return nil;
    }

    // return found device, otherwise nil
    Device* device = [array count] ? (Device*)[array objectAtIndex:0] : nil;
    return device;
}

//------------------------------------------------------------------------------

@end
