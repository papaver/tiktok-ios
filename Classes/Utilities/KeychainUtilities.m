//
//  KeychainUtilities.m
//  TikTok
//
//  Created by Moiz Merchant on 01/05/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes 
//-----------------------------------------------------------------------------

#import "KeychainUtilities.h"

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface KeychainUtilities ()
    + (NSMutableDictionary*) createSearchDictionary:(NSString*)identifier;
@end 

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation KeychainUtilities
   
//-----------------------------------------------------------------------------

+ (NSMutableDictionary*) createSearchDictionary:(NSString*)identifier 
{
    static NSString *serviceName = @"com.tiktok.TikTok";

    // encode the identifier
    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];

    // setup the dictionary
    NSMutableDictionary *keychainData = [[NSMutableDictionary alloc] init];
    [keychainData setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    [keychainData setObject:encodedIdentifier forKey:(id)kSecAttrGeneric];
    [keychainData setObject:encodedIdentifier forKey:(id)kSecAttrAccount];
    [keychainData setObject:serviceName forKey:(id)kSecAttrService];
    
    return keychainData; 
}

//-----------------------------------------------------------------------------

+ (NSData*) searchKeychainForIdentifier:(NSString*)identifier 
{
    NSMutableDictionary *keychainData = 
        [KeychainUtilities createSearchDictionary:identifier];
    
    // set the match to one and simply return nsdata object
    [keychainData setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
    [keychainData setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    
    // query for the result
    NSData *result  = nil;
    SecItemCopyMatching((CFDictionaryRef)keychainData, (CFTypeRef*)&result);

    // cleanup
    [keychainData release];

    return result;
}

//-----------------------------------------------------------------------------

+ (BOOL) createKeychainValue:(NSString*)value forIdentifier:(NSString*)identifier 
{
    NSMutableDictionary *keychainData = 
        [KeychainUtilities createSearchDictionary:identifier];

    // add the value to the dictionary
    NSData *valueData = [value dataUsingEncoding:NSUTF8StringEncoding];
    [keychainData setObject:valueData forKey:(id)kSecValueData];
    
    // add item to keychain
    OSStatus status = SecItemAdd((CFDictionaryRef)keychainData, NULL);

    // cleanup
    [keychainData release];
    
    return status == errSecSuccess;
}

//-----------------------------------------------------------------------------

+ (BOOL) updateKeychainValue:(NSString*)value forIdentifier:(NSString*)identifier 
{
    NSMutableDictionary *keychainData = 
        [KeychainUtilities createSearchDictionary:identifier];
    NSMutableDictionary *updateData = [[NSMutableDictionary alloc] init];

    // add value to update dictionary
    NSData *valueData = [value dataUsingEncoding:NSUTF8StringEncoding];
    [updateData setObject:valueData forKey:(id)kSecValueData];
    
    // update the data
    OSStatus status = 
        SecItemUpdate((CFDictionaryRef)keychainData, (CFDictionaryRef)updateData);

    // cleanup
    [keychainData release];
    [updateData release];

    return status == errSecSuccess;
}

//-----------------------------------------------------------------------------

+ (void) deleteKeychainValueForIdentifier:(NSString*)identifier 
{
    NSMutableDictionary *keychainData = 
        [KeychainUtilities createSearchDictionary:identifier];
    SecItemDelete((CFDictionaryRef)keychainData);
}

//-----------------------------------------------------------------------------

@end
