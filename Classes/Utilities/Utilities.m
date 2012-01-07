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
#import "Constants.h"
#import "KeychainUtilities.h"

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface Utilities ()
    + (NSString*) getSecureValueForKey:(NSString*)key;
    + (void) cacheSecureValue:(NSString*)value forKey:(NSString*)key;
    + (void) clearSecureValueForKey:(NSString*)key;
@end

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation Utilities

//-----------------------------------------------------------------------------

+ (NSString*) getSecureValueForKey:(NSString*)key
{
    // grab the device id from the use defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *deviceId       = [defaults objectForKey:key];
    if (deviceId) {
        return deviceId;
    }

    // the app may have been deleted, grab the key from the keychain
    // device doesn't need re-registering if key found
    NSData *data = [KeychainUtilities searchKeychainForIdentifier:key];
    if (data) {
        deviceId = [[[NSString alloc] 
            initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        [defaults setObject:deviceId forKey:key];
        [defaults synchronize];
        return deviceId;
    }

    return nil;
}

//-----------------------------------------------------------------------------

+ (void) cacheSecureValue:(NSString*)value forKey:(NSString*)key
{
    // save the device id in the keychain
    [KeychainUtilities createKeychainValue:value 
                             forIdentifier:key];

    // save the device id in the user defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
}

//-----------------------------------------------------------------------------

+ (void) clearSecureValueForKey:(NSString*)key
{
    // clear from the keystore
    [KeychainUtilities deleteKeychainValueForIdentifier:key];

    // clear from the user defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:key]) {
        [defaults removeObjectForKey:key];
        [defaults synchronize];
    }
}

//-----------------------------------------------------------------------------
#pragma mark - Device Id
//-----------------------------------------------------------------------------

+ (NSString*) getDeviceId
{
    return [self getSecureValueForKey:TIKTOK_DEVICEID_KEY];
}

//-----------------------------------------------------------------------------

+ (void) cacheDeviceId:(NSString*)deviceId
{
    [self cacheSecureValue:deviceId forKey:TIKTOK_DEVICEID_KEY];
}

//-----------------------------------------------------------------------------

+ (void) clearDeviceId
{
    [self clearSecureValueForKey:TIKTOK_DEVICEID_KEY];
}

//-----------------------------------------------------------------------------
#pragma mark - Customer Id
//-----------------------------------------------------------------------------

+ (NSString*) getConsumerId
{
    return [self getSecureValueForKey:TIKTOK_CUSTOMERID_KEY];
}

//-----------------------------------------------------------------------------

+ (void) cacheConsumerId:(NSString*)customerId
{
    [self cacheSecureValue:customerId forKey:TIKTOK_CUSTOMERID_KEY];
}

//-----------------------------------------------------------------------------

+ (void) clearConsumerId
{
    [self clearSecureValueForKey:TIKTOK_CUSTOMERID_KEY];
}

//-----------------------------------------------------------------------------
#pragma mark - Notification Token
//-----------------------------------------------------------------------------

+ (NSString*) getNotificationToken
{
    // grab the token from the use defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *token          = [defaults objectForKey:TIKTOK_NOTIFICATION_KEY];
    return token;
}

//-----------------------------------------------------------------------------

+ (void) cacheNotificationToken:(NSString*)token
{
    // save the token in the user defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:token forKey:TIKTOK_NOTIFICATION_KEY];
    [defaults synchronize];
}

//-----------------------------------------------------------------------------

+ (void) clearNotificationToken
{
    // clear from the user defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:TIKTOK_NOTIFICATION_KEY]) {
        [defaults removeObjectForKey:TIKTOK_NOTIFICATION_KEY];
        [defaults synchronize];
    }
}

//-----------------------------------------------------------------------------
#pragma mark - Misc
//-----------------------------------------------------------------------------

+ (void) displaySimpleAlertWithTitle:(NSString*)title andMessage:(NSString*)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil 
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}
  
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

+ (void) printHierarchyForView:(UIView*)view withHeader:(NSString*)header
{
    // print out the current view information

    NSLog(@"%@%@ - %@ - %d", header, view, 
        [NSValue valueWithCGRect:view.frame], [view isFirstResponder]);

    // extend the header
    NSString *childHeader = [NSString stringWithFormat:@" %@", header];

    // print out the children
    NSArray *subviews = view.subviews;
    NSUInteger count  = subviews.count;
    for (NSUInteger index = 0; index < count; ++index) {
        UIView *childView = [subviews objectAtIndex:index];
        [Utilities printHierarchyForView:childView withHeader:childHeader];
    }
}

//-----------------------------------------------------------------------------

+ (void) printHierarchyForView:(UIView*)view
{
    [Utilities printHierarchyForView:view withHeader:@""];
}

//-----------------------------------------------------------------------------

@end
