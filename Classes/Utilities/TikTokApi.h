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

typedef void (^TikTokApiCompletionHandler)(NSDictionary*);
typedef void (^TikTokApiErrorHandler)(ASIHTTPRequest*);

//------------------------------------------------------------------------------
// defines
//------------------------------------------------------------------------------

#define kTikTokApiKeyStatus  @"status"
#define kTikTokApiKeyError   @"error"
#define kTikTokApiKeyResults @"results"

#define kTikTokApiStatusOkay      @"OK"
#define kTikTokApiStatusInvalid   @"INVALID REQUEST"
#define kTikTokApiStatusForbidden @"FORBIDDEN"
#define kTikTokApiStatusNotFound  @"NOT_FOUND"

//------------------------------------------------------------------------------
// interface implementation 
//------------------------------------------------------------------------------

@interface TikTokApi : NSObject
{
    CGFloat                     mTimeOut;
    TikTokApiCompletionHandler  mCompletionHandler;
    TikTokApiErrorHandler       mErrorHandler;
    NSManagedObjectContext     *mManagedObjectContext;
}

//------------------------------------------------------------------------------

@property (nonatomic, copy)             TikTokApiCompletionHandler  completionHandler;
@property (nonatomic, copy)             TikTokApiErrorHandler       errorHandler;
@property (nonatomic, retain, readonly) NSManagedObjectContext     *context;
@property (nonatomic, assign)           CGFloat                     timeOut;

//------------------------------------------------------------------------------

- (void) registerDevice:(NSString*)deviceId;
- (void) validateRegistration;
- (void) registerNotificationToken:(NSString*)token;
- (void) syncActiveCoupons:(NSDate*)date;
- (void) updateCurrentLocation:(CLLocationCoordinate2D)coordinate async:(bool)async;
- (void) updateCoupon:(NSNumber*)couponId attribute:(TikTokApiCouponAttribute)attribute;
- (void) updateSettings:(NSDictionary*)settings;
- (void) updateSettingsHomeLocation:(CLLocation*)home;
- (void) updateSettingsWorkLocation:(CLLocation*)work;
- (void) syncKarmaPoints;
- (void) redeemPromotion:(NSString*)promoCode;
- (void) cities;

//------------------------------------------------------------------------------

@end
