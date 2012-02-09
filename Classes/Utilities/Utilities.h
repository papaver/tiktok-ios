//
//  Utilities.h
//  TikTok
//
//  Created by Moiz Merchant on 12/07/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes
//-----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface Utilities : NSObject
{
}

//-----------------------------------------------------------------------------

/**
 * Returns the device id, nil for new devices.
 */
+ (NSString*) getDeviceId;

/**
 * Caches the device id in both the keychain and use defaults.
 */
+ (void) cacheDeviceId:(NSString*)deviceId;

/**
 * Clears any existings cached device ids. 
 */
+ (void) clearDeviceId;

//-----------------------------------------------------------------------------

/**
 * Returns the consumer id, nil for new devices.
 */
+ (NSString*) getConsumerId;

/**
 * Caches the consumer id in both the keychain and use defaults.
 */
+ (void) cacheConsumerId:(NSString*)customerId;

/**
 * Clears any existings cached consumer ids. 
 */
+ (void) clearConsumerId;

//-----------------------------------------------------------------------------

/**
 * Returns the token if it exists.
 */
+ (NSString*) getNotificationToken;

/**
 * Caches the notification token in the use defaults.
 */
+ (void) cacheNotificationToken:(NSString*)token;

/**
 * Clears cached notification token.
 */
+ (void) clearNotificationToken;

//-----------------------------------------------------------------------------

/**
 * Displays a simple alert to the user with a title/message and ok box.
 */
+ (void) displaySimpleAlertWithTitle:(NSString*)title andMessage:(NSString*)message;

//-----------------------------------------------------------------------------

/**
 * Posts a generic local notification to the app in the background with the 
 * desired body and action messages.
 */
+ (void) postLocalNotificationInBackgroundWithBody:(NSString*)body 
                                            action:(NSString*)action
                                   iconBadgeNumber:(NSUInteger)iconBadgeNumber;

//-----------------------------------------------------------------------------

/**
 * Prints out the view hierarchy for the main application window with the 
 * associated frames for all the views.
 */
+ (void) printHierarchyForView:(UIView*)view;

/**
 * Prints out all the available loaded fonts on the system.
 */
+ (void) printAvailableFonts;

//-----------------------------------------------------------------------------

@end
