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

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation Location

//------------------------------------------------------------------------------

@dynamic locationId;
@dynamic name;
@dynamic address;
@dynamic latitude;
@dynamic longitude;
@dynamic phone;
@dynamic lastUpdated;
@dynamic coupons;

//------------------------------------------------------------------------------
#pragma mark - properties
//------------------------------------------------------------------------------

- (CLLocationCoordinate2D) coordinate
{
    return CLLocationCoordinate2DMake(
        [self.latitude doubleValue], [self.longitude doubleValue]);
}

//------------------------------------------------------------------------------
#pragma mark - Static methods
//------------------------------------------------------------------------------

+ (Location*) getLocationById:(NSNumber*)locationId
                  fromContext:(NSManagedObjectContext*)context
{
    // grab the location description
    NSEntityDescription *description = [NSEntityDescription
        entityForName:@"Location" inManagedObjectContext:context];

    // create a location fetch request
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:description];

    // setup the request to lookup the specific location by name
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"locationId == %@", locationId];
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
    NSNumber *locationId = [data objectForKey:@"id"];
    Location *location   = [Location getLocationById:locationId fromContext:context];
    if (location != nil) {

        // update location data if required
        NSNumber *lastUpdatedSeconds = [data objectForKey:@"last_update"];
        NSDate *lastUpdated = [NSDate dateWithTimeIntervalSince1970:lastUpdatedSeconds.intValue];
        if ([location.lastUpdated compare:lastUpdated] == NSOrderedAscending) {
            [location initWithJsonDictionary:data];
        }

        return location;
    }

    // create a new location object
    location = (Location*)[NSEntityDescription
        insertNewObjectForEntityForName:@"Location"
                 inManagedObjectContext:context];
    [location initWithJsonDictionary:data];

    // -- debug --
    NSLog(@"new location created: %@ -> %@", location.name, location.address);

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
    NSNumber *lastUpdated = [data objectForKey:@"last_update"];

    self.locationId  = [data objectForKey:@"id"];
    self.name        = [data objectForKey:@"name"];
    self.address     = [data objectForKey:@"full_address"];
    self.latitude    = [data objectForKey:@"latitude"];
    self.longitude   = [data objectForKey:@"longitude"];
    self.phone       = [data objectForKey:@"phone_number"];
    self.lastUpdated = [NSDate dateWithTimeIntervalSince1970:lastUpdated.intValue];

    return self;
}

//------------------------------------------------------------------------------

- (NSString*) getCity
{
    NSString *city = [[[self.address
        componentsSeparatedByString:@", "]
        objectAtIndex:1]
        stringByReplacingOccurrencesOfString:@" " withString:@""];
    return city;
}

/*
//------------------------------------------------------------------------------
#pragma mark - MKAnnotation
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
*/

@end
