//
//  NetworkConnectivity.m
//  TikTok
//
//  Created by Moiz Merchant on 01/23/12.
//  Copyright 2012 TikTok. All rights reserved.
//

// [moiz] so... once this class is allocated it just hangs around, the 
//  notifications are also always on.  not sure if that is a good or a bad 
//  thing really.  would be nice to figure out a way to automatically have
//  the hud pop up when the internet connection goes down...

//-----------------------------------------------------------------------------
// includes 
//-----------------------------------------------------------------------------

#import "NetworkConnectivity.h"
#import "Reachability.h"
#import "SVProgressHUD.h"

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface NetworkConnectivity ()
    + (NetworkConnectivity*) getInstance;
    - (void) checkNetworkStatus:(NSNotification*)notice;
    - (void) runConnectionHandler;
    - (void) setupNotifications;
@end

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation NetworkConnectivity

//-----------------------------------------------------------------------------

@synthesize handler              = mHandler;
@synthesize internetReachability = mInternetReachability;

//-----------------------------------------------------------------------------

+ (NetworkConnectivity*) getInstance
{
    static NetworkConnectivity *sNetworkConnectivity = nil;
    if (!sNetworkConnectivity) {
        sNetworkConnectivity = [[[NetworkConnectivity alloc] init] retain];
    }
    return sNetworkConnectivity;
}

//-----------------------------------------------------------------------------

+ (void) waitForNetworkWithConnectionHandler:(NetworkConnectionHandler)handler
{
    // save handler
    NetworkConnectivity *networkConnectivity = [NetworkConnectivity getInstance];

    // skip if internet connectivity exists
    NetworkStatus status = 
        [networkConnectivity.internetReachability currentReachabilityStatus];
    if (status != NotReachable) {
        handler();
        return;
    }

    // save handler
    networkConnectivity.handler = [handler copy];

    // put up the hud
    [SVProgressHUD showWithStatus:@"Waiting for Internet" 
                         maskType:SVProgressHUDMaskTypeBlack 
                 networkIndicator:YES];
}

//-----------------------------------------------------------------------------
#pragma - Initialization
//-----------------------------------------------------------------------------

- (id) init
{
    self = [super init];
    if (self) {
        [self setupNotifications];
    }
    return self;
}

//-----------------------------------------------------------------------------

- (void) setupNotifications
{
    // add notification to deal with network status change
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self 
                      selector:@selector(checkNetworkStatus:) 
                          name:kReachabilityChangedNotification 
                        object:nil];

    self.internetReachability = [Reachability reachabilityForInternetConnection]; 
    [self.internetReachability startNotifier];
}

//-----------------------------------------------------------------------------

- (void) runConnectionHandler
{
    // run connection handler
    if (mHandler) mHandler();

    // release handler
    [mHandler release];
    mHandler = nil;
    
    // dismiss the hud
    [SVProgressHUD dismiss];
}

//-----------------------------------------------------------------------------
#pragma - Notifications
//-----------------------------------------------------------------------------

- (void) checkNetworkStatus:(NSNotification*)notice
{
     NetworkStatus internetStatus = [self.internetReachability currentReachabilityStatus];
     switch (internetStatus) {
        case NotReachable:
            break;

        case ReachableViaWiFi: 
        case ReachableViaWWAN: 
            [self runConnectionHandler];
            break;
    }
}

//-----------------------------------------------------------------------------
#pragma - Memory Management
//-----------------------------------------------------------------------------

- (void) dealloc
{
    [mInternetReachability stopNotifier];

    // remove notification 
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver:self];

    [mInternetReachability release];
    [super dealloc];
}

//-----------------------------------------------------------------------------

@end
