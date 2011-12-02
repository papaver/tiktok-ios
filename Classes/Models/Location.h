//
//  Location.h
//  fifteenMinutes
//
//  Created by Moiz Merchant on 5/18/11.
//  Copyright 2011 Bunnies on Acid. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

@class Merchant;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface Location : NSManagedObject <MKAnnotation>
{
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSNumber *latitude;
@property (nonatomic, retain) NSNumber *longitude;
@property (nonatomic, retain) NSNumber *radius;
@property (nonatomic, retain) NSSet    *merchants;

//------------------------------------------------------------------------------

/**
 * Query the context for a location by name.  
 */
+ (Location*) getLocationByName:(NSString*)name 
                    fromContext:(NSManagedObjectContext*)context;

/**
 * Query the context for a location by json data.  If the location does not 
 * exist, it will be added to the context and saved into the store.
 */
+ (Location*) getOrCreateLocationWithJsonData:(NSDictionary*)data 
                                  fromContext:(NSManagedObjectContext*)context;

/**
 * Initialize the location object with the given json data.
 */
- (Location*) initWithJsonDictionary:(NSDictionary*)data;

/**
 * MKAnnotation Accessors
 */
- (NSString*) title;
- (CLLocationCoordinate2D) coordinate;

//------------------------------------------------------------------------------

@end

//------------------------------------------------------------------------------
// CoreData Accessors
//------------------------------------------------------------------------------

@interface Location (CoreDataGeneratedAccessors)
- (void) addMerchantsObject:(Merchant*)merchant;
- (void) removeMerchantsObject:(Merchant*)merchant;
- (void) addMerchants:(NSSet*)merchants;
- (void) removeMerchants:(NSSet*)merchants;
@end

