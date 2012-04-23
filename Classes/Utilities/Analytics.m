//
//  Analytics.m
//  TikTok
//
//  Created by Moiz Merchant on 02/10/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes 
//-----------------------------------------------------------------------------

#import "Analytics.h"
#import "Constants.h"
#import "FlurryAnalytics.h"
#import "TestFlight.h"
#import "TestFlight+Extensions.h"

//-----------------------------------------------------------------------------
// exception handler
//-----------------------------------------------------------------------------

void 
uncaughtExceptionHandler(NSException *exception) 
{
    if (ANALYTICS_FLURRY) {
        [FlurryAnalytics logError:@"Uncaught" message:@"Crash!" exception:exception];
    }
}

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation Analytics

//-----------------------------------------------------------------------------

+ (void) startSession
{
    // start up flurry
    if (ANALYTICS_FLURRY) {

        // setup flurry crash handler if testflight is disabled
        if (!ANALYTICS_TESTFLIGHT) {
            NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
        }

        // use proper api key
        NSString *apiKey = ANALYTICS_FLURRY_DEBUG ? FLURRY_DEV_API_KEY : FLURRY_API_KEY;
        [FlurryAnalytics setSecureTransportEnabled:YES];
        [FlurryAnalytics startSession:apiKey];
    }

    // start up test flight
    if (ANALYTICS_TESTFLIGHT) {
        [TestFlight takeOff:TESTFLIGHT_API_KEY];
    }
}

//-----------------------------------------------------------------------------

+ (void) setUserId:(NSString*)userId
{
    if (ANALYTICS_FLURRY) {
        [FlurryAnalytics setUserID:userId];
    }
}

//-----------------------------------------------------------------------------

+ (void) setUserGender:(NSString*)gender
{
    if (ANALYTICS_FLURRY) {
        [FlurryAnalytics setGender:[[gender substringToIndex:1] lowercaseString]];
    }
}

//-----------------------------------------------------------------------------

+ (void) setUserAgeWithBirthday:(NSDate*)birthday
{
    if (ANALYTICS_FLURRY) {

        // calculate the age of the user from the birthday
        NSDateComponents* ageComponents = 
            [[NSCalendar currentCalendar] components:NSYearCalendarUnit 
                                            fromDate:birthday
                                            toDate:[NSDate date]
                                            options:0];
    
        [FlurryAnalytics setAge:ageComponents.year];
    }
}

//-----------------------------------------------------------------------------

+ (void) passCheckpoint:(NSString*)checkpoint
{
    if (ANALYTICS_TESTFLIGHT) {
        [TestFlight passCheckpointOnce:checkpoint];
    }

    if (ANALYTICS_FLURRY) {
        [FlurryAnalytics logEvent:checkpoint];
    }
}

//-----------------------------------------------------------------------------

@end
