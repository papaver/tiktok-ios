//
//  Utilities.m
//  TikTok
//
//  Created by Moiz Merchant on 12/07/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes 
//-----------------------------------------------------------------------------

#import <assert.h>

#import "Utilities.h"

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation Utilities

//-----------------------------------------------------------------------------

+ (void) postLocalNotificationInBackgroundWithBody:(NSString*)body 
                                            action:(NSString*)action
                                   iconBadgeNumber:(NSUInteger)iconBadgeNumber
{
    __block UIBackgroundTaskIdentifier backgroundTask;

    UIApplication *application = [UIApplication sharedApplication]; 
    backgroundTask = [application beginBackgroundTaskWithExpirationHandler: ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [application endBackgroundTask:backgroundTask];
            backgroundTask = UIBackgroundTaskInvalid;
        });
    }];

    dispatch_async(dispatch_get_main_queue(), ^{
        while ([application backgroundTimeRemaining] > 1.0) {
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            if (localNotification) {
                localNotification.alertBody   = body;
                localNotification.alertAction = action;
                localNotification.soundName   = UILocalNotificationDefaultSoundName; 
                localNotification.applicationIconBadgeNumber = iconBadgeNumber;
                [application presentLocalNotificationNow:localNotification];
                [localNotification release];
                break;
            }
        }

        [application endBackgroundTask:backgroundTask];
        backgroundTask = UIBackgroundTaskInvalid;
    });
}

//-----------------------------------------------------------------------------

@end
