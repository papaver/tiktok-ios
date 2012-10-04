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
#import "GoogleMapsApi.h"
#import "TikTokApi.h"

//-----------------------------------------------------------------------------
// defines
//-----------------------------------------------------------------------------

#define KEY_NAME           @"TTS_name"
#define KEY_EMAIL          @"TTS_email"
#define KEY_TWITTER        @"TTS_twitter"
#define KEY_PHONE          @"TTS_phone"
#define KEY_GENDER         @"TTS_gender"
#define KEY_BIRTHDAY       @"TTS_birthday"
#define KEY_HOME           @"TTS_home"
#define KEY_HOMELOC        @"TTS_homeLocality"
#define KEY_WORK           @"TTS_work"
#define KEY_WORKLOC        @"TTS_workLocality"
#define KEY_CATEGORIES     @"TTS_categories"
#define KEY_LASTUPDATE     @"TTS_lastUpdate"
#define KEY_TUTORIAL       @"TTS_tutorial"
#define KEY_SYNCEDSETTINGS @"TTS_syncedSettings"

#define API_KEY_NAME       @"name"
#define API_KEY_EMAIL      @"email"
#define API_KEY_TWITTER    @"twh"
#define API_KEY_PHONE      @"phone"
#define API_KEY_GENDER     @"sex"
#define API_KEY_BIRTHDAY   @"birthday"
#define API_KEY_HOME       @"home"
#define API_KEY_WORK       @"work"
#define API_KEY_CATEGORIES @"categories"

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface Settings ()
    - (id) loadValueForKey:(NSString*)key;
    - (void) saveValue:(id)value forKey:(NSString*)key;
    - (void) clearValueForKey:(NSString*)key;
    - (CLLocation*) loadLocationForKey:(NSString*)key;
    - (void) saveLocation:(CLLocation*)location forKey:(NSString*)key;
    - (bool) hasSetting:(NSString*)key;
    - (bool) hasLocationSetting:(NSString*)key;
    - (void) syncSimpleSettings:(NSDictionary*)settings;
    - (void) syncGenderSettings:(NSDictionary*)settings;
    - (void) syncBirthdaySettings:(NSDictionary*)settings;
    - (void) syncLocationSettings:(NSDictionary*)settings;
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

- (bool) hasSetting:(NSString*)key
{
    NSString *setting = [self loadValueForKey:key];
    bool isEmpty      = (setting == nil) || [setting isEqualToString:@""];
    return !isEmpty;
}

//-----------------------------------------------------------------------------

- (bool) hasLocationSetting:(NSString*)key
{
    CLLocation *location = [self loadLocationForKey:key];
    bool isEmpty =
        (location == nil) ||
        ((location.coordinate.latitude == 0.0) &&
         (location.coordinate.longitude == 0.0));
    return !isEmpty;
}

//-----------------------------------------------------------------------------
#pragma - Public Api
//-----------------------------------------------------------------------------

+ (void) syncSettings:(NSDictionary*)data;
{
    Settings *settings = [Settings getInstance];

    [settings syncSimpleSettings:data];
    [settings syncGenderSettings:data];
    [settings syncBirthdaySettings:data];
    [settings syncLocationSettings:data];
}

//-----------------------------------------------------------------------------

+ (void) clearAllSettings
{
    Settings *settings = [Settings getInstance];

    [settings clearValueForKey:KEY_NAME];
    [settings clearValueForKey:KEY_EMAIL];
    [settings clearValueForKey:KEY_TWITTER];
    [settings clearValueForKey:KEY_PHONE];
    [settings clearValueForKey:KEY_GENDER];
    [settings clearValueForKey:KEY_BIRTHDAY];
    [settings clearValueForKey:KEY_HOME];
    [settings clearValueForKey:KEY_HOMELOC];
    [settings clearValueForKey:KEY_WORK];
    [settings clearValueForKey:KEY_WORKLOC];
    [settings clearValueForKey:KEY_CATEGORIES];
    [settings clearValueForKey:KEY_LASTUPDATE];
    [settings clearValueForKey:KEY_TUTORIAL];
    [settings clearValueForKey:KEY_SYNCEDSETTINGS];
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
    [api updateSettings:$dict($array(API_KEY_NAME), $array(name))];
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
    [api updateSettings:$dict($array(API_KEY_EMAIL), $array(email))];
}

//-----------------------------------------------------------------------------

- (NSString*) twitter
{
    return [self loadValueForKey:KEY_TWITTER];
}

//-----------------------------------------------------------------------------

- (void) setTwitter:(NSString*)twitter
{
    [self saveValue:twitter forKey:KEY_TWITTER];
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    [api updateSettings:$dict($array(API_KEY_TWITTER), $array(twitter))];
}

//-----------------------------------------------------------------------------

- (NSString*) phone
{
    return [self loadValueForKey:KEY_PHONE];
}

//-----------------------------------------------------------------------------

- (void) setPhone:(NSString*)phone
{
    [self saveValue:phone forKey:KEY_PHONE];
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    [api updateSettings:$dict($array(API_KEY_PHONE), $array(phone))];
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
    [api updateSettings:$dict($array(API_KEY_GENDER),
                              $array([gender substringToIndex:1]))];

    // save analytics data
    [Analytics setUserGender:gender];
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
    [api updateSettings:$dict($array(API_KEY_BIRTHDAY), $array(self.birthdayStr))];

    // update analytics
    [Analytics setUserAgeWithBirthday:birthday];
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

- (NSString*) categories
{
    return [self loadValueForKey:KEY_CATEGORIES];
}

//-----------------------------------------------------------------------------

- (void) setCategories:(NSString*)categories
{
    [self saveValue:categories forKey:KEY_CATEGORIES];
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    [api updateSettings:$dict($array(API_KEY_CATEGORIES), $array(categories))];
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

- (NSNumber*) syncedSettings
{
    return [self loadValueForKey:KEY_SYNCEDSETTINGS];
}

//-----------------------------------------------------------------------------

- (void) setSyncedSettings:(NSNumber*)synced
{
    [self saveValue:synced forKey:KEY_SYNCEDSETTINGS];
}

//-----------------------------------------------------------------------------
#pragma - Sync
//-----------------------------------------------------------------------------

- (void) syncSimpleSettings:(NSDictionary*)settings
{
    // helper struct to loop over the simple settings
    struct SettingsMapping {
        NSString *settingsKey, *apiKey;
    } sKeyMappings[5] = {
        { KEY_NAME,       API_KEY_NAME       },
        { KEY_EMAIL,      API_KEY_EMAIL      },
        { KEY_TWITTER,    API_KEY_TWITTER    },
        { KEY_PHONE,      API_KEY_PHONE      },
        { KEY_CATEGORIES, API_KEY_CATEGORIES }
    };

    // update any empty settings
    for (NSUInteger index = 0; index < 4; ++index) {
        NSString *key   = sKeyMappings[index].settingsKey;
        NSString *value = [settings objectForKey:sKeyMappings[index].apiKey];
        if (![self hasSetting:key] && ![value isEqualToString:@""]) {
            [self saveValue:value forKey:key];
        }
    }
}

//-----------------------------------------------------------------------------

- (void) syncGenderSettings:(NSDictionary*)settings
{
    NSString *value = [[settings objectForKey:API_KEY_GENDER] lowercaseString];
    if (![self hasSetting:KEY_GENDER] && ![value isEqualToString:@""]) {
        if ([value isEqualToString:@"f"]) {
            [self saveValue:kSettingsGenderFemale forKey:KEY_GENDER];
        } else if ([value isEqualToString:@"m"]) {
            [self saveValue:kSettingsGenderMale forKey:KEY_GENDER];
        }
    }
}

//-----------------------------------------------------------------------------

- (void) syncBirthdaySettings:(NSDictionary*)settings
{
    NSString *value = [settings objectForKey:API_KEY_BIRTHDAY];
    if (![self loadValueForKey:KEY_BIRTHDAY] && ![value isEqualToString:@""]) {

        // setup date formatter
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd"];

        // attempt to convert string into date and update settings
        NSDate *birthday = [formatter dateFromString:value];
        if (birthday != nil) {
            [self saveValue:birthday forKey:KEY_BIRTHDAY];
        }

        // cleanup
        [formatter release];
    }
}

//-----------------------------------------------------------------------------

- (void) syncLocationSettings:(NSDictionary*)settings
{
    // helper struct to loop over the location settings
    struct SettingsMapping {
        NSString *settingsKey, *localityKey, *apiKey;
    } sKeyMappings[2] = {
        { KEY_HOME, KEY_HOMELOC, API_KEY_HOME },
        { KEY_WORK, KEY_WORKLOC, API_KEY_WORK },
    };

    // update location settings
    for (NSUInteger index = 0; index < 2; ++index) {

        // update location if setting is invalid
        NSString *key = sKeyMappings[index].settingsKey;
        if (![self hasLocationSetting:key]) {

            // check if synced data is valid
            NSString *apiKey          = sKeyMappings[index].apiKey;
            NSString *apiKeyLatitude  = $string(@"%@_latitude", apiKey);
            NSString *apiKeyLongitude = $string(@"%@_longitude", apiKey);
            NSNumber *latitude        = [settings objectForKey:apiKeyLatitude];
            NSNumber *longitude       = [settings objectForKey:apiKeyLongitude];
            if ((latitude.doubleValue != 0.0) && (longitude.doubleValue != 0.0)) {

                // save location to settings
                CLLocation *location =
                    [[[CLLocation alloc]
                        initWithLatitude:[latitude doubleValue]
                               longitude:[longitude doubleValue]] autorelease];
                [self saveLocation:location forKey:key];

                // query and save the locality
                NSString *localityKey = sKeyMappings[index].localityKey;
                GoogleMapsApi *api    = [[GoogleMapsApi alloc] init];
                api.completionHandler = ^(ASIHTTPRequest *request, id geoData) {
                    if (geoData) {
                        NSString *place = [GoogleMapsApi parseLocality:geoData];
                        [self saveValue:place forKey:localityKey];
                    }
                };
                [api getReverseGeocodingForAddress:location.coordinate];
                [api release];
            }
        }
    }
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
