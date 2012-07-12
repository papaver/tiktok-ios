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

@property(nonatomic, retain) NSString   *name;
@property(nonatomic, retain) NSString   *email;
@property(nonatomic, retain) NSString   *twitter;
@property(nonatomic, retain) NSString   *phone;
@property(nonatomic, retain) NSString   *gender;
@property(nonatomic, retain) NSDate     *birthday;
@property(nonatomic, retain) CLLocation *home;
@property(nonatomic, retain) NSString   *homeLocality;
@property(nonatomic, retain) CLLocation *work;
@property(nonatomic, retain) NSString   *workLocality;
@property(nonatomic, retain) NSDate     *lastUpdate;
@property(nonatomic, retain) NSNumber   *tutorialIndex;

//-----------------------------------------------------------------------------

/**
 * Gets the global instance of the settings object.
 */
+ (Settings*) getInstance;

/**
 * Purges all of the settings saved in the cache.
 */
+ (void) clearAllSettings;

//-----------------------------------------------------------------------------

/**
 * Returns the birtday as a formated string of the us locale.
 */
- (NSString*) birthdayStr;

//-----------------------------------------------------------------------------

@end
