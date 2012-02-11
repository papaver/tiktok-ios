//
//  Coupon.m
//  TikTok
//
//  Created by Moiz Merchant on 4/29/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "Coupon.h"
#import "IconData.h"
#import "Merchant.h"
#import "UIDefaults.h"

//------------------------------------------------------------------------------
// defines
//------------------------------------------------------------------------------

#define $60_MINS (60.0 * 60.0)
#define $30_MINS (30.0 * 60.0)
#define  $5_MINS ( 5.0 * 60.0)

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation Coupon

//------------------------------------------------------------------------------

@dynamic couponId;
@dynamic title;
@dynamic details;
@dynamic iconId;
@dynamic iconUrl;
@dynamic startTime;
@dynamic endTime;
@dynamic wasRedeemed;
@dynamic barcode;
@dynamic merchant;

//------------------------------------------------------------------------------
#pragma mark - Static methods
//------------------------------------------------------------------------------

+ (Coupon*) getCouponById:(NSNumber*)couponId
                fromContext:(NSManagedObjectContext*)context
{
    // grab the coupon description
    NSEntityDescription *description = [NSEntityDescription
        entityForName:@"Coupon" inManagedObjectContext:context];

    // create a coupon fetch request
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:description];

    // setup the request to lookup the specific coupon by name
    NSPredicate *predicate = 
        [NSPredicate predicateWithFormat:@"couponId == %@", couponId];
    [request setPredicate:predicate];

    // return the coupon if it already exists in the context
    NSError *error = nil;
    NSArray *array = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"failed to query context for coupon: %@", error);
        return nil;
    }

    // return found merchant, otherwise nil
    Coupon* coupon = [array count] ? (Coupon*)[array objectAtIndex:0] : nil;
    return coupon;
}

//------------------------------------------------------------------------------

+ (Coupon*) getOrCreateCouponWithJsonData:(NSDictionary*)data 
                              fromContext:(NSManagedObjectContext*)context
{
    // check if coupon already exists in the store
    NSNumber *couponId = [data objectForKey:@"id"];
    Coupon *coupon = [Coupon getCouponById:couponId fromContext:context];
    if (coupon != nil) {
        return coupon;
    }

    // create merchant from json 
    NSDictionary *merchantData = [data objectForKey:@"merchant"];
    Merchant *merchant = 
        [Merchant getOrCreateMerchantWithJsonData:merchantData 
                                      fromContext:context];

    // skip out if we can't retrive a merchant from the context
    if (merchant == nil) {
        NSLog(@"failed to parse merchant.");
        return nil;
    }

    // create a new coupon object
    coupon = [[NSEntityDescription 
        insertNewObjectForEntityForName:@"Coupon" 
                 inManagedObjectContext:context]
                initWithJsonDictionary:data];
    coupon.merchant = merchant;

    // save the object to store
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"coupon save failed: %@", error);
    }

    return coupon;
}

//------------------------------------------------------------------------------
#pragma mark - properties
//------------------------------------------------------------------------------

- (IconData*) iconData
{
    return [IconData withId:self.iconId andUrl:self.iconUrl];
}

//------------------------------------------------------------------------------
#pragma mark - methods
//------------------------------------------------------------------------------

- (Coupon*) initWithJsonDictionary:(NSDictionary*)data
{ 
    NSNumber *enableTime = [data objectForKey:@"enable_time_in_tvsec"];
    NSNumber *expireTime = [data objectForKey:@"expiry_time_in_tvsec"];

    self.couponId    = [data objectForKey:@"id"];
    self.details     = [data objectForKey:@"description"];
    self.title       = [data objectForKey:@"headline"];
    self.startTime   = [NSDate dateWithTimeIntervalSince1970:enableTime.intValue];
    self.endTime     = [NSDate dateWithTimeIntervalSince1970:expireTime.intValue];
    self.iconId      = [data objectForKey:@"icon_uid"];
    self.iconUrl     = [data objectForKey:@"icon_url"];
    self.barcode     = [data objectForKey:@"barcode_number"];
    self.wasRedeemed = [[data objectForComplexKey:@"assignment.redeemed"] boolValue];

    return self;
}

//------------------------------------------------------------------------------

- (BOOL) isExpired 
{
    NSTimeInterval seconds = [self.endTime timeIntervalSinceNow];
    return seconds <= 0.0;
}

//------------------------------------------------------------------------------

- (UIColor*) getColor
{
    // return the default color if expired
    if ([self isExpired]) return [UIDefaults getTokColor];

    // calculate interp value
    NSTimeInterval secondsLeft  = [self.endTime timeIntervalSinceNow];
    NSTimeInterval totalSeconds = [self.endTime timeIntervalSinceDate:self.startTime];
    CGFloat t                   = 1.0 - (secondsLeft / totalSeconds);

    // green  should be solid until 60 minutes
    // yellow should be solid at 30 minutes
    // orange should be solid at  5 minutes
    if (secondsLeft > $60_MINS) {
        t = 0.0f;
    } else if (secondsLeft > $30_MINS) {
        t = (secondsLeft - $30_MINS) / $30_MINS;
        t = 0.00 + (1.0 - t) * 0.33;
    } else if (secondsLeft > $5_MINS) {
        t = (secondsLeft - $5_MINS) / ($30_MINS - $5_MINS);
        t = 0.33 + (1.0 - t) * 0.33;
    } else {
        t = (secondsLeft / $5_MINS);
        t = 0.66 + (1.0 - t) * 0.33;
    }

    // colors to transition between
    UIColor *tik    = [UIDefaults getTikColor];
    UIColor *yellow = [UIColor yellowColor];
    UIColor *orange = [UIColor orangeColor];
    UIColor *tok    = [UIDefaults getTokColor];

    // struct to make computations cleaner
    struct ColorTable {
        CGFloat t, offset;
        UIColor *start, *end;
    } sColorTable[3] = {
        { 0.33, 0.00, tik,    yellow },
        { 0.66, 0.33, yellow, orange },
        { 1.00, 0.66, orange, tok    },
    };

    // return the interpolated color
    NSUInteger index = 0;
    for (; index < 3; ++index) {
        if (t > sColorTable[index].t) continue;

        UIColor *start = sColorTable[index].start;
        UIColor *end   = sColorTable[index].end;
        CGFloat newT   = (t - sColorTable[index].offset) / 0.33;
        return [start colorByInterpolatingToColor:end
                                       byFraction:newT];
    }

    // in case something went wrong...
    return [UIColor blackColor];
}

//------------------------------------------------------------------------------

- (NSString*) getExpirationTime
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *expirationTime = [formatter stringForObjectValue:self.endTime];
    [formatter release];

    return expirationTime;
}

//------------------------------------------------------------------------------

- (NSString*) getExpirationTimer
{
    // return the default color if expired
    if ([self isExpired]) return @"00:00:00";
    
    // calculate inter value
    NSTimeInterval secondsLeft  = [self.endTime timeIntervalSinceNow];
    CGFloat minutesLeft         = secondsLeft / 60.0;

    // update the coupon expire timer
    NSString *timer = $string(@"%.2d:%.2d:%.2d", 
        (int)minutesLeft / 60, (int)minutesLeft % 60, (int)secondsLeft % 60);
    return timer;
}

//------------------------------------------------------------------------------

@end
