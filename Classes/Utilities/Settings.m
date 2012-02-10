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
#import "TikTokApi.h"

//-----------------------------------------------------------------------------
// defines
//-----------------------------------------------------------------------------

#define KEY_NAME       @"TTS_name"
#define KEY_EMAIL      @"TTS_email"
#define KEY_GENDER     @"TTS_gender"
#define KEY_BIRTHDAY   @"TTS_birthday"
#define KEY_HOME       @"TTS_home"
#define KEY_HOMELOC    @"TTS_homeLocality"
#define KEY_WORK       @"TTS_work"
#define KEY_WORKLOC    @"TTS_workLocality"
#define KEY_LASTUPDATE @"TTS_lastUpdate"
#define KEY_TUTORIAL   @"TTS_tutorial"

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
    NSNumber *latitude  = $numd(location.coordinate.latitude);
    NSNumber *longitude = $numd(location.coordinate.longitude);
    NSDictionary *dict  = $dict($array(@"lat", @"long"), 
                                $array(latitude, longitude));
    [self saveValue:dict forKey:key];
}

//-----------------------------------------------------------------------------
#pragma - Public Api
//-----------------------------------------------------------------------------

+ (void) clearAllSettings
{
    Settings *settings = [Settings getInstance];

    [settings clearValueForKey:KEY_NAME];
    [settings clearValueForKey:KEY_EMAIL];
    [settings clearValueForKey:KEY_GENDER];
    [settings clearValueForKey:KEY_BIRTHDAY];
    [settings clearValueForKey:KEY_HOME];
    [settings clearValueForKey:KEY_HOMELOC];
    [settings clearValueForKey:KEY_WORK];
    [settings clearValueForKey:KEY_WORKLOC];
    [settings clearValueForKey:KEY_LASTUPDATE];
    [settings clearValueForKey:KEY_TUTORIAL];
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
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    [api updateSettings:$dict($array(@"name"), $array(name))];
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
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    [api updateSettings:$dict($array(@"email"), $array(email))];
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
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    [api updateSettings:$dict($array(@"sex"), 
                              $array([gender substringToIndex:1]))];
    
    // save analytics data
    [FlurryAnalytics setGender:[[gender substringToIndex:1] lowercaseString]];
}

//-----------------------------------------------------------------------------

- (NSDate*) birthday 
{
    return [self loadValueForKey:KEY_BIRTHDAY];
}

//-----------------------------------------------------------------------------

- (NSString*) birthdayStr
{
    // setup the date formatter
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSLocale *locale           = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];

    [formatter setTimeStyle:NSDateFormatterNoStyle];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setLocale:locale];

    // format the date
    NSString *birthdayStr = [formatter stringFromDate:self.birthday];

    // cleanup
    [locale release];
    [formatter release];

    return birthdayStr;
}

//-----------------------------------------------------------------------------

- (void) setBirthday:(NSDate*)birthday 
{
    [self saveValue:birthday forKey:KEY_BIRTHDAY];
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    [api updateSettings:$dict($array(@"birthday"), $array(self.birthdayStr))];

    // save analytics data
    NSDateComponents* ageComponents = 
        [[NSCalendar currentCalendar] components:NSYearCalendarUnit 
                                        fromDate:birthday
                                          toDate:[NSDate date]
                                         options:0];
    [FlurryAnalytics setAge:ageComponents.year];
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
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    [api updateSettingsHomeLocation:home];
}

//-----------------------------------------------------------------------------

- (NSString*) homeLocality 
{
    return [self loadValueForKey:KEY_HOMELOC];
}

//-----------------------------------------------------------------------------

- (void) setHomeLocality:(NSString*)homeLocality 
{
    [self saveValue:homeLocality forKey:KEY_HOMELOC];
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
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    [api updateSettingsWorkLocation:work];
}
       
//-----------------------------------------------------------------------------

- (NSString*) workLocality 
{
    return [self loadValueForKey:KEY_WORKLOC];
}

//-----------------------------------------------------------------------------

- (void) setWorkLocality:(NSString*)workLocality 
{
    [self saveValue:workLocality forKey:KEY_WORKLOC];
}

//-----------------------------------------------------------------------------

- (NSDate*) lastUpdate 
{
    return [self loadValueForKey:KEY_LASTUPDATE];
}

//-----------------------------------------------------------------------------

- (void) setLastUpdate:(NSDate*)lastUpdate 
{
    [self saveValue:lastUpdate forKey:KEY_LASTUPDATE];
}
       
//-----------------------------------------------------------------------------

- (NSNumber*) tutorialIndex 
{
    return [self loadValueForKey:KEY_TUTORIAL];
}

//-----------------------------------------------------------------------------

- (void) setTutorialIndex:(NSNumber*)tutorialIndex 
{
    [self saveValue:tutorialIndex forKey:KEY_TUTORIAL];
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
