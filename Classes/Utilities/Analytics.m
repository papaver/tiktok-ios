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

#include <libkern/OSAtomic.h>
#include <execinfo.h>

//-----------------------------------------------------------------------------
// statics
//-----------------------------------------------------------------------------

const NSInteger UncaughtExceptionHandlerSkipAddressCount   = 4;
const NSInteger UncaughtExceptionHandlerReportAddressCount = 5;

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface Analytics ()
    + (NSArray*) backtrace;
    + (NSString*) getDeviceInfo;
@end

//-----------------------------------------------------------------------------
// exception/signal handler
//-----------------------------------------------------------------------------

void
uncaughtExceptionHandler(NSException *exception)
{
    if (ANALYTICS_FLURRY) {
        NSString *name         = [exception name];
        NSString *info         = [Analytics getDeviceInfo];
        NSString *message      = $string(@"DeviceInfo: \n%@", info);
        [FlurryAnalytics logError:name message:message exception:exception];
    }
}

//-----------------------------------------------------------------------------

void
uncaughtSignalHandler(int signal)
{
    // [moiz] technically its not safe to run obj-c code in a signal handler
    if (ANALYTICS_FLURRY) {
        NSString *name     = $string(@"Signal %d", signal);
        NSString *info     = [Analytics getDeviceInfo];
        NSArray *backtrace = [Analytics backtrace];
        NSString *message  = $string(@"Device: %@, Backtrace: %@", info, backtrace);
        [FlurryAnalytics logError:name message:message exception:nil];
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

        // setup flurry exception handler if testflight is disabled
        NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);

        /* [moiz] this is just creating useless spam...
        // setup flurry signal handler if testflight is disabled
        struct sigaction signalAction;
        memset(&signalAction, 0, sizeof(signalAction));
        signalAction.sa_handler = &uncaughtSignalHandler;
        sigaction(SIGABRT, &signalAction, NULL);
        sigaction(SIGILL,  &signalAction, NULL);
        sigaction(SIGSEGV, &signalAction, NULL);
        sigaction(SIGFPE,  &signalAction, NULL);
        sigaction(SIGBUS,  &signalAction, NULL);
        sigaction(SIGPIPE, &signalAction, NULL);
        */

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

+ (void) setUserLocation:(CLLocation*)location
{
    if (ANALYTICS_FLURRY) {
        [FlurryAnalytics setLatitude:location.coordinate.latitude
                           longitude:location.coordinate.longitude
                  horizontalAccuracy:location.horizontalAccuracy
                    verticalAccuracy:location.verticalAccuracy];
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

+ (void) logRemoteError:(NSString*)name withMessage:(NSString*)message
{
    if (ANALYTICS_FLURRY) {
        [FlurryAnalytics logError:name message:message exception:nil];
    }
}

//-----------------------------------------------------------------------------

+ (NSArray*) backtrace
{
    void* callstack[128];
    int frames  = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);

    // convert the strings into a nsstring array
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    int index                 = UncaughtExceptionHandlerSkipAddressCount;
    int count                 = (UncaughtExceptionHandlerSkipAddressCount +
                                 UncaughtExceptionHandlerReportAddressCount);
    for ( ; index < count; ++index) {
        [backtrace addObject:[NSString stringWithUTF8String:strs[index]]];
    }

    // cleanup
    free(strs);

    return backtrace;
}

//-----------------------------------------------------------------------------

+ (NSString*) getDeviceInfo
{
    UIDevice *device = [UIDevice currentDevice];
    NSString *info   = $string(@"%@ %@", device.systemName, device.systemVersion);
    return info;
}

//-----------------------------------------------------------------------------

@end
