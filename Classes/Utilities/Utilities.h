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
 * Posts a generic local notification to the app in the background with the 
 * desired body and action messages.
 */
+ (void) postLocalNotificationInBackgroundWithBody:(NSString*)body 
                                            action:(NSString*)action
                                   iconBadgeNumber:(NSUInteger)iconBadgeNumber;

/**
 * Prints out the view hierarchy for the main application window with the 
 * associated frames for all the views.
 */
+ (void) printHierarchyForView:(UIView*)view;

//-----------------------------------------------------------------------------

@end
