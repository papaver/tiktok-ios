//
//  Settings.m
//  TikTok
//
//  Created by Moiz Merchant on 01/12/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes 
//-----------------------------------------------------------------------------

#import "Settings.h"

//-----------------------------------------------------------------------------
// defines
//-----------------------------------------------------------------------------

#define KEY_NAME   @"TTS_name"
#define KEY_EMAIL  @"TTS_email"
#define KEY_GENDER @"TTS_gender"

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface Settings ()
    - (NSString*) loadValueForKey:(NSString*)key;
    - (void) saveValue:(NSString*)value forKey:(NSString*)key;
    - (void) clearValueForKey:(NSString*)key;
@end

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation Settings

//-----------------------------------------------------------------------------

@synthesize name   = mName;
@synthesize email  = mEmail;
@synthesize gender = mGender;

//-----------------------------------------------------------------------------

+ (Settings*) getInstance
{
    static Settings *sSettings = nil;
    if (!sSettings) {
        sSettings = [[[Settings alloc] init] retain];
    }
    return sSettings;
}

//-----------------------------------------------------------------------------
#pragma - Initialization
//-----------------------------------------------------------------------------

- (id) init
{
    self = [super init];
    if (self) {
    }
    return self;
}

//-----------------------------------------------------------------------------
#pragma - Methods
//-----------------------------------------------------------------------------

- (NSString*) loadValueForKey:(NSString*)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *value          = [defaults objectForKey:key];
    return value;
}

//-----------------------------------------------------------------------------

- (void) saveValue:(NSString*)value forKey:(NSString*)key;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:key];
    [defaults synchronize];
}

//-----------------------------------------------------------------------------

- (void) clearValueForKey:(NSString*)key;
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:key]) {
        [defaults removeObjectForKey:key];
        [defaults synchronize];
    }
}

//-----------------------------------------------------------------------------
#pragma - Public Api
//-----------------------------------------------------------------------------

- (void) clearAllSettings
{
    [self clearValueForKey:KEY_NAME];
    [self clearValueForKey:KEY_EMAIL];
    [self clearValueForKey:KEY_GENDER];
}

//-----------------------------------------------------------------------------
#pragma - Properties
//-----------------------------------------------------------------------------

- (NSString*) name 
{
    return [self loadValueForKey:KEY_NAME];
}

//-----------------------------------------------------------------------------

- (void) setName:(NSString*)name 
{
    return [self saveValue:name forKey:KEY_NAME];
}

//-----------------------------------------------------------------------------

- (NSString*) email 
{
    return [self loadValueForKey:KEY_EMAIL];
}

//-----------------------------------------------------------------------------

- (void) setEmail:(NSString*)email 
{
    return [self saveValue:email forKey:KEY_EMAIL];
}

//-----------------------------------------------------------------------------

- (NSString*) gender 
{
    return [self loadValueForKey:KEY_GENDER];
}

//-----------------------------------------------------------------------------

- (void) setGender:(NSString*)gender 
{
    return [self saveValue:gender forKey:KEY_GENDER];
}

//-----------------------------------------------------------------------------
#pragma - Memory Management
//-----------------------------------------------------------------------------

- (void) dealloc
{
    [super dealloc];
}

//-----------------------------------------------------------------------------

@end
