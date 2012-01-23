//
//  NetworkConnectivity.h
//  TikTok
//
//  Created by Moiz Merchant on 01/23/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes
//-----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

//-----------------------------------------------------------------------------
// forward declarations
//-----------------------------------------------------------------------------

@class Reachability;

//-----------------------------------------------------------------------------
// typedefs
//-----------------------------------------------------------------------------

typedef void (^NetworkConnectionHandler)(void);

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface NetworkConnectivity : NSObject
{
    Reachability             *mInternetReachability;
    NetworkConnectionHandler  mHandler;
}

//-----------------------------------------------------------------------------

@property (nonatomic, retain) Reachability             *internetReachability;
@property (nonatomic, copy)   NetworkConnectionHandler  handler;

//-----------------------------------------------------------------------------

+ (void) waitForNetworkWithConnectionHandler:(NetworkConnectionHandler)handler;

//-----------------------------------------------------------------------------

@end
