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
#define KEY_HOME   @"TTS_home"
#define KEY_WORK   @"TTS_work"

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface Settings ()
    - (id) loadValueForKey:(NSString*)key;
    - (void) saveValue:(id)value forKey:(NSString*)key;
    - (void) clearValueForKey:(NSString*)key;
    - (CLLocation*) loadLocationForKey:(NSString*)key;
    - (void) saveLocation:(CLLocation*)location forKey:(NSString*)key;
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

- (id) loadValueForKey:(NSString*)key
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id value                 = [defaults objectForKey:key];
    return value;
}

//-----------------------------------------------------------------------------

- (void) saveValue:(id)value forKey:(NSString*)key;
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

- (CLLocation*) loadLocationForKey:(NSString*)key
{
    NSDictionary *dict = [self loadValueForKey:key];
    if (!dict) return nil;

    NSNumber *latitude   = [dict objectForKey:@"lat"];
    NSNumber *longitude  = [dict objectForKey:@"long"];
    CLLocation *location = 
        [[[CLLocation alloc] initWithLatitude:[latitude doubleValue]
                                    longitude:[longitude doubleValue]] autorelease];
    return location;
}

//-----------------------------------------------------------------------------

- (void) saveLocation:(CLLocation*)location forKey:(NSString*)key
{
    NSNumber *latitude  = [NSNumber numberWithDouble:location.coordinate.latitude];
    NSNumber *longitude = [NSNumber numberWithDouble:location.coordinate.longitude];
    NSDictionary *dict  = $dict($array(@"lat", @"long", nil), 
                                $array(latitude, longitude, nil));
    [self saveValue:dict forKey:key];
}

//-----------------------------------------------------------------------------
#pragma - Public Api
//-----------------------------------------------------------------------------

- (void) clearAllSettings
{
    [self clearValueForKey:KEY_NAME];
    [self clearValueForKey:KEY_EMAIL];
    [self clearValueForKey:KEY_GENDER];
    [self clearValueForKey:KEY_HOME];
    [self clearValueForKey:KEY_WORK];
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
    [self saveValue:name forKey:KEY_NAME];
}

//-----------------------------------------------------------------------------

- (NSString*) email 
{
    return [self loadValueForKey:KEY_EMAIL];
}

//-----------------------------------------------------------------------------

- (void) setEmail:(NSString*)email 
{
    [self saveValue:email forKey:KEY_EMAIL];
}

//-----------------------------------------------------------------------------

- (NSString*) gender 
{
    return [self loadValueForKey:KEY_GENDER];
}

//-----------------------------------------------------------------------------

- (void) setGender:(NSString*)gender 
{
    [self saveValue:gender forKey:KEY_GENDER];
}

//-----------------------------------------------------------------------------

- (CLLocation*) home 
{
    return [self loadLocationForKey:KEY_HOME];
}

//-----------------------------------------------------------------------------

- (void) setHome:(CLLocation*)home 
{
    [self saveLocation:home forKey:KEY_HOME];
}

//-----------------------------------------------------------------------------

- (CLLocation*) work 
{
    return [self loadLocationForKey:KEY_WORK];
}

//-----------------------------------------------------------------------------

- (void) setWork:(CLLocation*)work 
{
    [self saveLocation:work forKey:KEY_WORK];
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
