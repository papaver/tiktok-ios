//
//  TikTokPhysicsView.m
//  TikTok
//
//  Created by Moiz Merchant on 12/21/11.
//  Copyright (c) 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports 
//------------------------------------------------------------------------------

#import "TikTokPhysicsView.h"
#import "TikTokPhysicsViewController.h"

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation TikTokPhysicsView

//------------------------------------------------------------------------------

@synthesize physicsController = mPhysicsController;

//------------------------------------------------------------------------------

- (BOOL) canBecomeFirstResponder
{ 
    return YES;
}

//------------------------------------------------------------------------------

- (void) motionBegan:(UIEventSubtype)motion withEvent:(UIEvent*)event 
{
    if (event.type == UIEventSubtypeMotionShake) {
        [self.physicsController shakeTikTok];
    }
}

//------------------------------------------------------------------------------

@end
