//
//  FacebookManager.h
//  TikTok
//
//  Created by Moiz Merchant on 01/03/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes
//-----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "FBConnect.h"

//-----------------------------------------------------------------------------
// forward declarations
//-----------------------------------------------------------------------------

@class Facebook;

//-----------------------------------------------------------------------------
// typedefs
//-----------------------------------------------------------------------------

typedef void (^FacebookConnectSuccessHandler)(void);

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface FacebookManager : NSObject <FBSessionDelegate>
{
    Facebook                      *mFacebook;
    FacebookConnectSuccessHandler  mSuccessHandler;
}

//-----------------------------------------------------------------------------

@property(nonatomic, retain) Facebook *facebook;

//-----------------------------------------------------------------------------

/**
 * Gets the global instance of the facebook manager.
 */
+ (FacebookManager*) getInstance;

/**
 * Authorize app to connect with facebook.
 */
- (void) authorizeWithSucessHandler:(FacebookConnectSuccessHandler)handler;

//-----------------------------------------------------------------------------

@end
