//
//  Merchant.m
//  TikTok
//
//  Created by Moiz Merchant on 4/29/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "Merchant.h"
#import "Coupon.h"
#import "IconData.h"

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation Merchant

//------------------------------------------------------------------------------

@dynamic merchantId;
@dynamic name;
@dynamic address;
@dynamic latitude;
@dynamic longitude;
@dynamic phone;
@dynamic category;
@dynamic details;
@dynamic iconId;
@dynamic iconUrl;
@dynamic twitterUrl;
@dynamic facebookUrl;
@dynamic websiteUrl;
@dynamic coupons;

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark Static methods
//------------------------------------------------------------------------------

+ (Merchant*) getMerchantByName:(NSString*)name 
                    fromContext:(NSManagedObjectContext*)context
{
    // grab the merchant description
    NSEntityDescription *description = [NSEntityDescription
        entityForName:@"Merchant" inManagedObjectContext:context];

    // create a merchant fetch request
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:description];

    // setup the request to lookup the specific merchant by name
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name == %@", name];
    [request setPredicate:predicate];

    // return the merchant if it already exists in the context
    NSError *error = nil;
    NSArray *array = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Merchant: failed to query context,  %@", error);
        return nil;
    }

    // return found merchant, otherwise nil
    Merchant* merchant = [array count] ? (Merchant*)[array objectAtIndex:0] : nil;
    return merchant;
}

//------------------------------------------------------------------------------

+ (Merchant*) getOrCreateMerchantWithJsonData:(NSDictionary*)data 
                                  fromContext:(NSManagedObjectContext*)context
{
    // check if merchant already exists in the store
    NSString *name     = [data objectForKey:@"name"];
    Merchant *merchant = [Merchant getMerchantByName:name fromContext:context];
    if (merchant != nil) {
        return merchant;
    }

    // create a new merchant object
    merchant = [[NSEntityDescription 
        insertNewObjectForEntityForName:@"Merchant" 
                 inManagedObjectContext:context]
                initWithJsonDictionary:data];

    // save the object to store
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Merchant: save failed, %@", error);
    }

    return merchant;
}

//------------------------------------------------------------------------------
#pragma mark - properties
//------------------------------------------------------------------------------

- (IconData*) iconData
{
    return [IconData withId:self.iconId andUrl:self.iconUrl];
}

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark methods
//------------------------------------------------------------------------------

- (Merchant*) initWithJsonDictionary:(NSDictionary*)data
{
    self.name        = [data objectForKey:@"name"];
    self.address     = [data objectForKey:@"full_address"];
    self.latitude    = [data objectForKey:@"latitude"];
    self.longitude   = [data objectForKey:@"longitude"];
    self.phone       = [data objectForKey:@"phone_number"];
    self.details     = [data objectForKey:@"description"];
    self.iconId      = [data objectForKey:@"icon_uid"];
    self.iconUrl     = [data objectForKey:@"icon_url"];
    self.websiteUrl  = [data objectForKey:@"web_url"];
    self.category    = [data objectForKey:@"category"];

    return self;
}

//------------------------------------------------------------------------------

@end
