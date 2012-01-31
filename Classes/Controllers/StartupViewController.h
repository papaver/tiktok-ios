//
//  StartupViewController.h
//  TikTok
//
//  Created by Moiz Merchant on 12/19/11.
//  Copyright (c) 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports 
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>
#import "TikTokPhysicsViewController.h"

//------------------------------------------------------------------------------
// typedefs
//------------------------------------------------------------------------------

typedef void (^StartupCompletionHandler)(void);

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface StartupViewController : UIViewController
{
    TikTokPhysicsViewController *mPhysicsController;
    StartupCompletionHandler     mCompletionHandler;
    NSTimer                     *mTimer;
    CGFloat                      mRegistrationTimeout;
    bool                         mPause;
    bool                         mComplete;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) IBOutlet TikTokPhysicsViewController *physicsController;
@property (nonatomic, copy)            StartupCompletionHandler     completionHandler;

//------------------------------------------------------------------------------

- (IBAction) pauseStartup;

//------------------------------------------------------------------------------

@end
