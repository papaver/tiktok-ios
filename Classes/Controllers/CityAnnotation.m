//
//  CityAnnotation.m
//  TikTok
//
//  Created by Moiz Merchant on 05/22/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "CityAnnotation.h"

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation CityAnnotation

//------------------------------------------------------------------------------

@synthesize city = mCity;
@synthesize type = mType;

//------------------------------------------------------------------------------
#pragma mark - Initilization
//------------------------------------------------------------------------------

- (id) initWithCity:(NSDictionary*)city ofType:(NSUInteger)type
{
    self = [super init];
    if (self) {
        self.city = city;
        self.type = type;
    }
    return self;
}

//------------------------------------------------------------------------------
#pragma mark - MKAnnotation
//------------------------------------------------------------------------------

- (NSString*) title
{
    return [self.city objectForKey:@"name"];
}

//------------------------------------------------------------------------------

- (NSString*) subtitle
{
    switch (self.type) {
        case kCityTypeLive:
            return @"Live";
        case kCityTypeBeta:
            return @"Beta";
        case kCityTypeSoon:
            return @"Coming Soon";
    }
    return @"";
}

//------------------------------------------------------------------------------

- (CLLocationCoordinate2D) coordinate
{
    CLLocationDegrees latitude  = [[self.city objectForComplexKey:@"location.lat"] doubleValue];
    CLLocationDegrees longitude = [[self.city objectForComplexKey:@"location.lng"] doubleValue];
    return CLLocationCoordinate2DMake(latitude, longitude);
}

//------------------------------------------------------------------------------
#pragma mark - Memory Management
//------------------------------------------------------------------------------

- (void) dealloc
{
    [mCity release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
