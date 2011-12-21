//
//  TikTokPhysicsViewController.h
//  TikTok
//
//  Created by Moiz Merchant on 12/20/11.
//  Copyright (c) 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

struct b2World;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface TikTokPhysicsViewController : UIViewController
{
    UIView         *m_tik;
    UIView         *m_tok;
    NSTimer        *m_timer;

    struct b2World *m_world;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) IBOutlet UIView  *tik;
@property (nonatomic, retain) IBOutlet UIView  *tok;
@property (nonatomic, retain)          NSTimer *timer;

//------------------------------------------------------------------------------

@end
