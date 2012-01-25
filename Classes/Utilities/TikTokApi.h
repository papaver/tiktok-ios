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
#import <dispatch/dispatch.h>
#import "SBJson.h"

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

@class ASIHTTPRequest;

//------------------------------------------------------------------------------
// enums
//------------------------------------------------------------------------------

typedef enum _TikTokApiCouponAttribute
{
    kTikTokApiCouponAttributeRedeem     = 0,
    kTikTokApiCouponAttributeFacebook   = 1,
    kTikTokApiCouponAttributeTwitter    = 2,
    kTikTokApiCouponAttributeGooglePlus = 3,
    kTikTokApiCouponAttributeSMS        = 4,
    kTikTokApiCouponAttributeEmail      = 5,
} TikTokApiCouponAttribute;

//------------------------------------------------------------------------------
// typedefs
//------------------------------------------------------------------------------

typedef void (^TikTokApiCompletionHandler)(ASIHTTPRequest*);

//------------------------------------------------------------------------------
// interface implementation 
//------------------------------------------------------------------------------

@interface TikTokApi : NSObject <SBJsonStreamParserAdapterDelegate>
{
    SBJsonStreamParser         *mParser;
    SBJsonStreamParserAdapter  *mAdapter;
    NSMutableArray             *mJsonData;
    SEL                         mParserMethod;
    TikTokApiCompletionHandler  mCompletionHandler;
    TikTokApiCompletionHandler  mErrorHandler;
    dispatch_queue_t            mQueue;
    NSManagedObjectContext     *mManagedObjectContext;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain)           SBJsonStreamParser         *parser;
@property (nonatomic, retain)           SBJsonStreamParserAdapter  *adapter;
@property (nonatomic, retain)           NSMutableArray             *jsonData;
@property (nonatomic, copy)             TikTokApiCompletionHandler  completionHandler;
@property (nonatomic, copy)             TikTokApiCompletionHandler  errorHandler;
@property (nonatomic, retain, readonly) NSManagedObjectContext     *context;

//------------------------------------------------------------------------------

- (void) registerDevice:(NSString*)deviceId;
- (void) validateRegistration;
- (void) registerNotificationToken:(NSString*)token;
- (void) syncActiveCoupons;
- (void) updateCurrentLocation:(CLLocationCoordinate2D)coordinate;
- (void) updateCoupon:(NSNumber*)couponId attribute:(TikTokApiCouponAttribute)attribute;
- (void) updateSettings:(NSDictionary*)settings;
- (void) updateSettingsHomeLocation:(CLLocation*)home;
- (void) updateSettingsWorkLocation:(CLLocation*)work;

//------------------------------------------------------------------------------

@end
