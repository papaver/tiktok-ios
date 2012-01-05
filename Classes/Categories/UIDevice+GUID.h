//
//  UIDevice+GUID.h
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

@interface UIDevice (GUID)

/**
 * Generates a Global Unique Identifier for the device.
 */
- (NSString*) generateGUID;

//-----------------------------------------------------------------------------

@end
