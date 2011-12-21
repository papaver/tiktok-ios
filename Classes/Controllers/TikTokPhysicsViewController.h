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
    UIImageView    *m_tik;
    UIImageView    *m_tok;
    NSTimer        *m_timer;

    struct b2World *m_world;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) IBOutlet UIImageView *tik;
@property (nonatomic, retain) IBOutlet UIImageView *tok;
@property (nonatomic, retain)          NSTimer     *timer;

//------------------------------------------------------------------------------

- (void) shakeTikTok;

//------------------------------------------------------------------------------

@end
