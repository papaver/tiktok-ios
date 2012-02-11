//
//  Analytics.h
//  TikTok
//
//  Created by Moiz Merchant on 02/10/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes
//-----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

//-----------------------------------------------------------------------------
// function prototypes
//-----------------------------------------------------------------------------

void uncaughtExceptionHandler(NSException *exception);

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface Analytics : NSObject
{
}

//-----------------------------------------------------------------------------

/**
 * Starts up analytics session.
 */
+ (void) startSession;

/**
 * Sets the id of the user.
 */
+ (void) setUserId:(NSString*)userId;

/**
 * Sets the gender of the user.
 */
+ (void) setUserGender:(NSString*)gender;

/**
 * Sets the age of the user.
 */
+ (void) setUserAgeWithBirthday:(NSDate*)birthday;

/**
 * Sets the age of the user.
 */
+ (void) passCheckpoint:(NSString*)checkpoint;

//-----------------------------------------------------------------------------

@end
