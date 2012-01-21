//
//  NSDictionary+Extensions.h
//  TikTok
//
//  Created by Moiz Merchant on 01/05/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes
//-----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface NSDictionary (Extensions)

//-----------------------------------------------------------------------------

/**
 * Accepts a list of keys, allowing access into nested dictionaries.
 */
- (id) objectForNestedKeys:(NSString*)key, ... NS_REQUIRES_NIL_TERMINATION;

/**
 * Accepts keys of the fashion: one.two.three, allowing easy access into 
 * nested dictionaries.
 */
- (id) objectForComplexKey:(NSString*)key;

//-----------------------------------------------------------------------------

@end
