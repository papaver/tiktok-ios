//
//  SoftNagManager.m
//  TikTok
//
//  Created by Moiz Merchant on 10/04/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "SoftNagManager.h"
#import "Settings.h"

//------------------------------------------------------------------------------
// defines
//------------------------------------------------------------------------------

#define kButtonNo  0
#define kButtonYes 1

//------------------------------------------------------------------------------
// class interface
//------------------------------------------------------------------------------

@interface SoftNagManager ()
    + (SoftNagManager*) getInstance;
    - (void) showNagAlert:(NSString*)category;
    - (bool) shouldNagUser;
    - (NSString*) getNagCategory;
    - (void) hideRatingAlert;
@end

//------------------------------------------------------------------------------
// class implementation
//------------------------------------------------------------------------------

@implementation SoftNagManager

//------------------------------------------------------------------------------

@synthesize nagAlert = mNagAlert;
@synthesize category = mCategory;

//------------------------------------------------------------------------------

+ (SoftNagManager*) getInstance
{
    static SoftNagManager *sManager = nil;
    if (sManager == nil) {

        // run manager setup on seperate thread
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{

            // initialize manager
            sManager = [[SoftNagManager alloc] init];

            // setup notifications
            [[NSNotificationCenter defaultCenter]
                addObserver:self
                   selector:@selector(appWillResignActive)
                       name:UIApplicationWillResignActiveNotification
                     object:nil];
        });
    }

    return sManager;
}

//------------------------------------------------------------------------------

+ (void) appLaunched
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_async(queue, ^{
        [[SoftNagManager getInstance] checkAndNag];
    });
}

//------------------------------------------------------------------------------

+ (void) appEnteredForeground
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_async(queue, ^{
        [[SoftNagManager getInstance] checkAndNag];
    });
}

//------------------------------------------------------------------------------

+ (void) appWillResignActive
{
    [[SoftNagManager getInstance] hideRatingAlert];
}

//------------------------------------------------------------------------------

- (void) showNagAlert:(NSString*)category
{
    NSString* title   = @"Deal Preferences";
    NSString* message = NSLocalizedString(category, nil);

    // setup alert view
    UIAlertView *alertView =
        [[UIAlertView alloc] initWithTitle:title
                                   message:message
                                  delegate:self
                         cancelButtonTitle:@"No"
                         otherButtonTitles:@"Yes", nil];

    // save reference
    self.nagAlert = alertView;

    // display alert
    [alertView show];

    // cleanup
    [alertView release];
}

//------------------------------------------------------------------------------

- (bool) shouldNagUser
{
    // if no settings always nag
    Settings *settings = [Settings getInstance];
    if (settings.lastNag == nil) {
        settings.lastNag = [NSDate date];
        return YES;
    }

    // check if more than a couple of days have gone by
    const CGFloat twoDays    = 60 * 60 * 24 * 2;
    NSTimeInterval timeDelta = [[NSDate date] timeIntervalSinceDate:settings.lastNag];
    if (timeDelta > twoDays) {
        settings.lastNag = [NSDate date];
        return YES;
    }

    return NO;
}

//------------------------------------------------------------------------------

- (NSString*) getNagCategory
{
    // grab soft nag settigns
    Settings *settings = [Settings getInstance];
    NSString *softNags = settings.softNags;

    // set to default if not yet initialized
    if (softNags == nil) {
        softNags = [kSettingsCategories componentsJoinedByString:@","];
        settings.softNags = softNags;
    }

    // check if all categories already nagged
    if ([softNags isEqualToString:kStopNagging]) {
        return @"";
    }

    // return a random category
    NSArray *categories = [softNags componentsSeparatedByString:@","];
    NSUInteger count    = categories.count;
    return [categories objectAtIndex:(arc4random() % count)];
}

//------------------------------------------------------------------------------

- (void) checkAndNag
{
    self.category = [self getNagCategory];
    if ([self shouldNagUser] && ![self.category isEqualToString:@""]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showNagAlert:self.category];
        });
    }
}

//------------------------------------------------------------------------------

- (void) hideRatingAlert
{
    if (self.nagAlert.visible) {
        [self.nagAlert dismissWithClickedButtonIndex:-1 animated:NO];
    }
}

//------------------------------------------------------------------------------

- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    Settings *settings  = [Settings getInstance];

    // remove from nag list
    NSMutableArray *softNags = [[NSMutableArray alloc]
        initWithArray:[settings.softNags componentsSeparatedByString:@","]];
    [softNags removeObject:self.category];
    settings.softNags = [softNags componentsJoinedByString:@","];

    // get current set of categories
    NSMutableArray *categories = [[NSMutableArray alloc]
        initWithArray:[settings.categories componentsSeparatedByString:@","]];

    // update settings
    NSUInteger index = [categories indexOfObject:self.category];
    switch (buttonIndex) {

        case kButtonNo:
            if (index != NSNotFound) {
                [categories removeObject:self.category];
                settings.categories = [categories componentsJoinedByString:@","];
            }
            break;

        case kButtonYes:
            if (index == NSNotFound) {
                [categories addObject:self.category];
                settings.categories = [categories componentsJoinedByString:@","];
            }
            break;

        default:
            break;
    }
}

//------------------------------------------------------------------------------

@end
