//
//  Location.m
//  TikTok
//
//  Created by Moiz Merchant on 5/18/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "Location.h"
#import "Merchant.h"

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation Location

//------------------------------------------------------------------------------

@dynamic name;
@dynamic latitude;
@dynamic longitude;
@dynamic radius;
@dynamic merchants;

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Static methods
//------------------------------------------------------------------------------

+ (Location*) getLocationByName:(NSString*)name 
                    fromContext:(NSManagedObjectContext*)context
{
    // grab the location description
    NSEntityDescription *description = [NSEntityDescription
        entityForName:@"Location" inManagedObjectContext:context];

    // create a location fetch request
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:description];

    // setup the request to lookup the specific location by name
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
    [request setPredicate:predicate];

    // return the location about if it already exists in the context
    NSError *error = nil;
    NSArray *array = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"failed to query context for location: %@", error);
        return nil;
    }

    // return found location, otherwise nil
    Location* location = [array count] ? (Location*)[array objectAtIndex:0] : nil;
    return location;
}

//------------------------------------------------------------------------------

+ (Location*) getOrCreateLocationWithJsonData:(NSDictionary*)data 
                                  fromContext:(NSManagedObjectContext*)context
{
    // check if location already exists in the store
    NSString *name     = [data objectForKey:@"name"];
    Location *location = [Location getLocationByName:name fromContext:context];
    if (location != nil) {
        return location;
    }

    // create a new location object
    location = (Location*)[NSEntityDescription 
        insertNewObjectForEntityForName:@"Location" 
                 inManagedObjectContext:context];
    [location initWithJsonDictionary:data];

    // -- debug --
    NSLog(@"new location created: %@", location.name);

    // save the object to store
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"location save failed: %@", error);
    }

    return location;
}

//------------------------------------------------------------------------------

- (Location*) initWithJsonDictionary:(NSDictionary*)data
{
    self.name      = [data objectForKey:@"name"];
    self.latitude  = [data objectForKey:@"latitude"];
    self.longitude = [data objectForKey:@"longitude"];
    self.radius    = [data objectForKey:@"radius"];

    return self;
}

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark MKAnnotation
//------------------------------------------------------------------------------

- (CLLocationCoordinate2D) coordinate
{
    CLLocationDegrees latitude  = self.latitude.doubleValue;
    CLLocationDegrees longitude = self.longitude.doubleValue;
    return CLLocationCoordinate2DMake(latitude, longitude);
}

//------------------------------------------------------------------------------

- (NSString*) title
{
    return self.name;
}

//------------------------------------------------------------------------------

@end
