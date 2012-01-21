//
//  NSDictionary+Extensions.m
//  TikTok
//
//  Created by Moiz Merchant on 01/05/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes 
//-----------------------------------------------------------------------------

#import "NSDictionary+Extensions.h"

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation NSDictionary (Extensions)

//-----------------------------------------------------------------------------

- (id) objectForNestedKeyArray:(NSArray*)args
{
    id object = self;
    for (NSString* key in args) {
        object = [object objectForKey:key];
    }
    return object;
}

//-----------------------------------------------------------------------------

- (id) objectForNestedKeys:(NSString*)key, ...
{
    NSMutableArray *keys = [[NSMutableArray alloc] init];

    va_list args;
    va_start(args, key);
    for (; key; key = va_arg(args, NSString*)) [keys addObject:key];
    va_end(args);

    // query for the object
    id object = [self objectForNestedKeyArray:keys];

    // cleanup
    [keys release];

    return object;
}

//-----------------------------------------------------------------------------

- (id) objectForComplexKey:(NSString*)key;
{
    // split the keys 
    NSArray *keys = [key componentsSeparatedByString:@"."];
    id object = [self objectForNestedKeyArray:keys];
    return object;
}

//-----------------------------------------------------------------------------

@end
