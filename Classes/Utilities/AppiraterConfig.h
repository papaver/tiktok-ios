//
//  AppiraterConfig.h
//  TikTok
//
//  Created by Moiz Merchant on 05/18/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "Appirater.h"

//------------------------------------------------------------------------------
// Appirater undefine config
//------------------------------------------------------------------------------

/**
 * This file should be placed into the precompiled headers file. An easy and
 * quick hack to redefine the configuration parameters without messing with the
 * appirater module. The message defines are left out since the defaults are
 * fine and can be updated using the localizations file.
 */

#undef APPIRATER_APP_ID
#undef APPIRATER_APP_NAME
#undef APPIRATER_DAYS_UNTIL_PROMPT
#undef APPIRATER_USES_UNTIL_PROMPT
#undef APPIRATER_SIG_EVENTS_UNTIL_PROMPT
#undef APPIRATER_TIME_BEFORE_REMINDING
#undef APPIRATER_DEBUG

//------------------------------------------------------------------------------
// Appirater configuration
//------------------------------------------------------------------------------

/**
 * Place your Apple generated software id here.
 */
#define APPIRATER_APP_ID 499341754

/**
 * Your app's name.
 */
#define APPIRATER_APP_NAME [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey]

/**
 * Users will need to have the same version of your app installed for this many
 * days before they will be prompted to rate it. (double)
 */
#define APPIRATER_DAYS_UNTIL_PROMPT 15.0

/**
 * An example of a 'use' would be if the user launched the app. Bringing the app
 * into the foreground (on devices that support it) would also be considered
 * a 'use'. You tell Appirater about these events using the two methods:
 * [Appirater appLaunched:]
 * [Appirater appEnteredForeground:]
 *
 * Users need to 'use' the same version of the app this many times before
 * before they will be prompted to rate it. (integer)
 */
#define APPIRATER_USES_UNTIL_PROMPT 20

/**
 * A significant event can be anything you want to be in your app. In a
 * telephone app, a significant event might be placing or receiving a call.
 * In a game, it might be beating a level or a boss. This is just another
 * layer of filtering that can be used to make sure that only the most
 * loyal of your users are being prompted to rate you on the app store.
 * If you leave this at a value of -1, then this won't be a criteria
 * used for rating. To tell Appirater that the user has performed
 * a significant event, call the method:
 * [Appirater userDidSignificantEvent:]; (integer)
 */
#define APPIRATER_SIG_EVENTS_UNTIL_PROMPT -1

/**
 * Once the rating alert is presented to the user, they might select
 * 'Remind me later'. This value specifies how long (in days) Appirater
 * will wait before reminding them. (double)
 */
#define APPIRATER_TIME_BEFORE_REMINDING 1.0

/**
 * 'YES' will show the Appirater alert everytime. Useful for testing how your message
 * looks and making sure the link to your app's review page works.
 */
#define APPIRATER_DEBUG NO
