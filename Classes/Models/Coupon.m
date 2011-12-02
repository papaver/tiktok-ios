//
//  Coupon.m
//  fifteenMinutes
//
//  Created by Moiz Merchant on 4/29/11.
//  Copyright 2011 Bunnies on Acid. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "Coupon.h"
#import "Merchant.h"

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation Coupon

//------------------------------------------------------------------------------

@dynamic title;
@dynamic text;
@dynamic imagePath;
@dynamic startTime;
@dynamic endTime;
@dynamic merchant;

@synthesize image = m_image;

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Static methods
//------------------------------------------------------------------------------

+ (Coupon*) getCouponByName:(NSString*)name 
                fromContext:(NSManagedObjectContext*)context
{
    // grab the coupon description
    NSEntityDescription *description = [NSEntityDescription
        entityForName:@"Coupon" inManagedObjectContext:context];

    // create a coupon fetch request
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:description];

    // setup the request to lookup the specific coupon by name
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"text == %@", name];
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
    NSString *name = [data objectForKey:@"description"];
    Coupon *coupon = [Coupon getCouponByName:name fromContext:context];
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
    coupon = (Coupon*)[NSEntityDescription 
        insertNewObjectForEntityForName:@"Coupon" 
                 inManagedObjectContext:context];
    [coupon initWithJsonDictionary:data];
    coupon.merchant = merchant;

    // -- debug --
    NSLog(@"new coupon created: %@", coupon.text);

    // save the object to store
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"coupon save failed: %@", error);
    }

    return coupon;
}

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark methods
//------------------------------------------------------------------------------

- (Coupon*) initWithJsonDictionary:(NSDictionary*)data
{ 
    NSNumber *enable_time = [data objectForKey:@"enable_time_in_tvsec"];
    NSNumber *expire_time = [data objectForKey:@"expiry_time_in_tvsec"];

    self.imagePath = [data objectForKey:@"image_url"];
    self.text      = [data objectForKey:@"description"];
    self.startTime = [NSDate dateWithTimeIntervalSince1970:enable_time.intValue];
    self.endTime   = [NSDate dateWithTimeIntervalSince1970:expire_time.intValue];

    return self;
}

//------------------------------------------------------------------------------

- (UIImage*) image
{
    if (m_image == nil) {
        id url         = [NSURL URLWithString:self.imagePath];
        NSData *bitmap = [NSData dataWithContentsOfURL:url];

        CGSize size = CGSizeMake(280, 280); 
        UIGraphicsBeginImageContext(size);
        UIImage *image = [UIImage imageWithData:bitmap];
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        m_image = UIGraphicsGetImageFromCurrentImageContext();    
        [m_image retain];
        UIGraphicsEndImageContext();
    }

    return m_image;
}

//------------------------------------------------------------------------------

@end
