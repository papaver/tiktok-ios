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
// interface definition
//------------------------------------------------------------------------------

@interface StartupViewController : UIViewController
{
    TikTokPhysicsViewController *mPhysicsController;
    NSOperationQueue*            mOperationQueue;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) IBOutlet TikTokPhysicsViewController *physicsController;
@property (nonatomic, retain)          NSOperationQueue            *operationQueue;

//------------------------------------------------------------------------------

- (void) onDeviceTokenReceived:(NSData*)deviceToken;

//------------------------------------------------------------------------------

@end
