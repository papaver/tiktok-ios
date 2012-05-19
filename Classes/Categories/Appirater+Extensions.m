//
//  Appirater+Extensions.m
//  TikTok
//
//  Created by Moiz Merchant on 05/18/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes
//-----------------------------------------------------------------------------

#import "Appirater+Extensions.h"

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation Appirater (Extensions)

//-----------------------------------------------------------------------------

+ (void) reset
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kAppiraterCurrentVersion];
    [defaults removeObjectForKey:kAppiraterFirstUseDate];
    [defaults removeObjectForKey:kAppiraterUseCount];
    [defaults removeObjectForKey:kAppiraterSignificantEventCount];
    [defaults removeObjectForKey:kAppiraterRatedCurrentVersion];
    [defaults removeObjectForKey:kAppiraterDeclinedToRate];
    [defaults removeObjectForKey:kAppiraterReminderRequestDate];
    [defaults synchronize];
}

//-----------------------------------------------------------------------------

@end
