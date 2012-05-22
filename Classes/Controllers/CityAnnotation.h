//
//  CityAnnotation.h
//  TikTok
//
//  Created by Moiz Merchant on 05/22/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

//------------------------------------------------------------------------------
// enums
//------------------------------------------------------------------------------

enum CityType
{
    kCityTypeLive,
    kCityTypeBeta,
    kCityTypeSoon
};

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface CityAnnotation : NSObject <MKAnnotation>
{
    NSDictionary *mCity;
    NSUInteger    mType;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) NSDictionary *city;
@property (nonatomic, assign) NSUInteger    type;

//------------------------------------------------------------------------------

- (id) initWithCity:(NSDictionary*)city ofType:(NSUInteger)type;

/**
 * MKAnnotation Accessors
 */
- (NSString*) title;
- (NSString*) subtitle;
- (CLLocationCoordinate2D) coordinate;

//------------------------------------------------------------------------------

@end

