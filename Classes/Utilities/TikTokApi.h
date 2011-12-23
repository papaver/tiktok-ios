//
//  TikTokApi.h
//  TikTok
//
//  Created by Moiz Merchant on 4/30/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports 
//------------------------------------------------------------------------------

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>
#import "SBJson.h"

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

@class Location;

//------------------------------------------------------------------------------
// interface implementation 
//------------------------------------------------------------------------------

@interface TikTokApi : NSObject <SBJsonStreamParserAdapterDelegate>
{
    SBJsonStreamParser        *mParser;
    SBJsonStreamParserAdapter *mAdapter;
    NSMutableArray            *mJsonData;
    SEL                        mParserMethod;
    NSManagedObjectContext    *mManagedContext;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) SBJsonStreamParser        *parser;
@property (nonatomic, retain) SBJsonStreamParserAdapter *adapter;
@property (nonatomic, retain) NSMutableArray            *jsonData;
@property (nonatomic, retain) NSManagedObjectContext    *managedContext;

//------------------------------------------------------------------------------

+ (void) setDeviceToken:(NSData*)deviceToken;

- (Location*) checkInWithCurrentLocation:(CLLocation*)location;
- (bool) checkOut;

- (NSMutableArray*) getActiveCoupons;

- (void) parseData:(NSData*)data;
- (void) parseLocationData:(NSDictionary*)data;
- (void) parseCouponData:(NSDictionary*)data;

//------------------------------------------------------------------------------

@end
