//
//  TikTokPhysicsView.h
//  TikTok
//
//  Created by Moiz Merchant on 12/21/11.
//  Copyright (c) 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

@class TikTokPhysicsViewController;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface TikTokPhysicsView : UIView
{
    TikTokPhysicsViewController *mPhysicsController;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) IBOutlet TikTokPhysicsViewController *physicsController;

//------------------------------------------------------------------------------

@end
