//
//  KeychainUtilities.h
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

@interface KeychainUtilities : NSObject
{
}

//-----------------------------------------------------------------------------

/**
 * Retrieve the value for an existing keychain identifier.
 */
+ (NSData*) searchKeychainForIdentifier:(NSString*)identifier;

/**
 * Create a new keychain with the given identifier.
 */
+ (BOOL) createKeychainValue:(NSString*)value forIdentifier:(NSString*)identifier;

/**
 * Update the value for the given identifier.
 */
+ (BOOL) updateKeychainValue:(NSString*)value forIdentifier:(NSString*)identifier;

/**
 * Delete the identifier from the keychain.
 */
+ (void) deleteKeychainValueForIdentifier:(NSString*)identifier;

//-----------------------------------------------------------------------------

@end
