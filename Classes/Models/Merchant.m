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

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation Merchant

//------------------------------------------------------------------------------

@dynamic merchantId;
@dynamic name;
@dynamic imagePath;
@dynamic coupons;

@synthesize image = mImage;

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
        NSLog(@"failed to query context for merchant: %@", error);
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
    merchant = (Merchant*)[NSEntityDescription 
        insertNewObjectForEntityForName:@"Merchant" 
                 inManagedObjectContext:context];
    [merchant initWithJsonDictionary:data];

    // -- debug --
    NSLog(@"new merchant created: %@", merchant.name);

    // save the object to store
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"merchant save failed: %@", error);
    }

    return merchant;
}

//------------------------------------------------------------------------------
#pragma mark -
#pragma mark methods
//------------------------------------------------------------------------------

- (Merchant*) initWithJsonDictionary:(NSDictionary*)data
{
    self.name      = [data objectForKey:@"name"];
    self.imagePath = [data objectForKey:@"image_url"];

    return self;
}

//------------------------------------------------------------------------------

- (UIImage*) image
{
    if (mImage == nil) {
        id url         = [NSURL URLWithString:self.imagePath];
        NSData *bitmap = [NSData dataWithContentsOfURL:url];

        CGSize size = CGSizeMake(20, 20); 
        UIGraphicsBeginImageContext(size);
        UIImage *image = [UIImage imageWithData:bitmap];
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        mImage = UIGraphicsGetImageFromCurrentImageContext();    
        [mImage retain];
        UIGraphicsEndImageContext();
    }

    return mImage;
}

//------------------------------------------------------------------------------

@end
