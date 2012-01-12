//
//  Settings.h
//  TikTok
//
//  Created by Moiz Merchant on 01/12/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes
//-----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface Settings : NSObject
{
}

//-----------------------------------------------------------------------------

@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *email;
@property(nonatomic, retain) NSString *gender;

//-----------------------------------------------------------------------------

/**
 * Gets the global instance of the settings object.
 */
+ (Settings*) getInstance;

//-----------------------------------------------------------------------------

- (void) clearAllSettings;

//-----------------------------------------------------------------------------

@end
