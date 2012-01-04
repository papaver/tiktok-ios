//
//  TikTokPhysicsViewController.m
//  TikTok
//
//  Created by Moiz Merchant on 12/20/11.
//  Copyright (c) 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports 
//------------------------------------------------------------------------------

#import "TikTokPhysicsViewController.h"
#import <Box2D/Box2D.h>

//------------------------------------------------------------------------------
// defines
//------------------------------------------------------------------------------

/**
 * Points to Meters Ratio
 */
#define PTM_RATIO 16

//------------------------------------------------------------------------------
// enums
//------------------------------------------------------------------------------

enum kViewTag
{
    kTagTik = 1,
    kTagTok = 2,
};

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface TikTokPhysicsViewController ()
    - (void) createPhysicsWorld;
    - (void) addPhysicalBodyForView:(UIView*)physicalView;
    - (void) updateWorld:(NSTimer*)timer;
    - (void) setHappyTikTok;
    - (void) setShakenTikTok;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation TikTokPhysicsViewController

//------------------------------------------------------------------------------

@synthesize timer = mTimer;

//------------------------------------------------------------------------------
#pragma mark - View lifecycle
//------------------------------------------------------------------------------

- (void) viewDidLoad
{
    [super viewDidLoad];
}

//------------------------------------------------------------------------------

/**
 * Release any retained subviews of the main view.
 */
- (void) viewDidUnload
{
    [super viewDidUnload];
}

//------------------------------------------------------------------------------

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.view becomeFirstResponder];
}

//------------------------------------------------------------------------------

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view resignFirstResponder];
}

//------------------------------------------------------------------------------

/**
 * Return YES for supported orientations
 */
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
 
//------------------------------------------------------------------------------
#pragma - Public Api
//------------------------------------------------------------------------------

- (void) startWorld
{
    // make sure simulation hasn't already started
    if (mWorld) return;

    // setup the box2d physics world 
    [self createPhysicsWorld];

    // add tik and tok to the world
    UIView *tik = [self.view viewWithTag:kTagTik];
    UIView *tok = [self.view viewWithTag:kTagTok];
    [self addPhysicalBodyForView:tik];
    [self addPhysicalBodyForView:tok];

    // setup a timer to run the main update loop
    CGFloat interval = 1.0 / 60.0;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:interval 
                                                  target:self 
                                                selector:@selector(updateWorld:) 
                                                userInfo:nil 
                                                 repeats:YES];
}

//------------------------------------------------------------------------------

- (void) stopWorld
{
    if (!mWorld) delete mWorld;
    mWorld = NULL;
    [self.timer invalidate];
    [self.timer release];
}

//------------------------------------------------------------------------------
#pragma - Helper Functions
//------------------------------------------------------------------------------

- (void) setHappyTikTok
{
    UIImageView *tik = (UIImageView*)[self.view viewWithTag:kTagTik];
    UIImageView *tok = (UIImageView*)[self.view viewWithTag:kTagTok];
    tik.image        = [UIImage imageNamed:@"Tik.png"]; 
    tok.image        = [UIImage imageNamed:@"Tok.png"]; 
}

//------------------------------------------------------------------------------

- (void) setShakenTikTok
{
    UIImageView *tik = (UIImageView*)[self.view viewWithTag:kTagTik];
    UIImageView *tok = (UIImageView*)[self.view viewWithTag:kTagTok];
    tik.image        = [UIImage imageNamed:@"TikShaken.png"]; 
    tok.image        = [UIImage imageNamed:@"TokShaken.png"]; 
}

//------------------------------------------------------------------------------
#pragma - Box2D
//------------------------------------------------------------------------------

- (void) createPhysicsWorld
{
    CGSize screenSize = self.view.bounds.size;

    // Define the gravity vector.
    b2Vec2 gravity;
    gravity.Set(0.0f, -9.81f);

    // do we want to let bodies sleep? this will speed up the physics sim
    //bool doSleep = true;

    // construct a world object, which will hold and simulate the rigid bodies
    mWorld = new b2World(gravity);
    mWorld->SetContinuousPhysics(true);

    // define the ground body, bottom-left corner
    b2BodyDef groundBodyDef;
    groundBodyDef.position.Set(0, 0);

    // call the body factory which allocates memory for the ground body
    // from a pool and creates the ground box shape (also from a pool).
    // the body is also added to the world.
    b2Body* groundBody = mWorld->CreateBody(&groundBodyDef);

    // define the ground box shape.
    b2EdgeShape groundBox;

    // bottom
    groundBox.Set(b2Vec2(0, 0), 
                  b2Vec2(screenSize.width / PTM_RATIO, 0));
    groundBody->CreateFixture(&groundBox, 0);

    // top
    groundBox.Set(b2Vec2(0, screenSize.height / PTM_RATIO), 
                  b2Vec2(screenSize.width / PTM_RATIO, screenSize.height / PTM_RATIO));
    groundBody->CreateFixture(&groundBox, 0);

    // left
    groundBox.Set(b2Vec2(0, screenSize.height / PTM_RATIO), 
                  b2Vec2(0, 0));
    groundBody->CreateFixture(&groundBox, 0);

    // right
    groundBox.Set(b2Vec2(screenSize.width / PTM_RATIO, screenSize.height / PTM_RATIO), 
                  b2Vec2(screenSize.width / PTM_RATIO, 0));
    groundBody->CreateFixture(&groundBox, 0);
}

//------------------------------------------------------------------------------

- (void) addPhysicalBodyForView:(UIView*)physicalView
{
    // define the dynamic body.
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;

    CGPoint center        = physicalView.center;
    CGPoint boxDimensions = CGPointMake(
        physicalView.bounds.size.width  / PTM_RATIO / 2.0,
        physicalView.bounds.size.height / PTM_RATIO / 2.0);

    bodyDef.position.Set(center.x / PTM_RATIO, (428.0 - center.y) / PTM_RATIO);
    bodyDef.userData = physicalView;

    // tell the physics world to create the body
    b2Body *body = mWorld->CreateBody(&bodyDef);

    // define another box shape for our dynamic body.
    b2PolygonShape dynamicBox;
    dynamicBox.SetAsBox(boxDimensions.x, boxDimensions.y);

    // define the dynamic body fixture.
    b2FixtureDef fixtureDef;
    fixtureDef.shape       = &dynamicBox;
    fixtureDef.density     = 1.0f;
    fixtureDef.friction    = 0.2f;
    fixtureDef.restitution = 0.8f;     // 0 is a lead ball, 1 is a super bouncy ball
    body->CreateFixture(&fixtureDef);

    // a dynamic body reacts to forces right away
    body->SetType(b2_dynamicBody);

    // we abuse the tag property as pointer to the physical body
    physicalView.tag = (int)body;
}

//------------------------------------------------------------------------------

- (void) updateWorld:(NSTimer *)timer
{
    // it is recommended that a fixed time step is used with Box2D for stability
    // of the simulation, however, we are using a variable time step here.
    // you need to make an informed choice, the following URL is useful
    // http://gafferongames.com/game-physics/fix-your-timestep/

    int32 velocityIterations = 8;
    int32 positionIterations = 1;

    // instruct the world to perform a single step of simulation. It is
    // generally best to keep the time step and iterations fixed.
    mWorld->Step(1.0f / 60.0f, velocityIterations, positionIterations);

    // iterate over the bodies in the physics world
    for (b2Body* body = mWorld->GetBodyList(); body; body = body->GetNext()) {
        if (body->GetUserData() != NULL) {
            UIView *view = (UIView*)body->GetUserData();

            // y position subtracted because of flipped coordinate system
            view.center = CGPointMake(
                body->GetPosition().x * PTM_RATIO,
                self.view.bounds.size.height - body->GetPosition().y * PTM_RATIO);

            // update transform
            view.transform = CGAffineTransformMakeRotation(-body->GetAngle());

            // check if they can be happy again
            b2Vec2 linearVelocity = body->GetLinearVelocity();
            if (linearVelocity.LengthSquared() < 1.0f) {
                [self setHappyTikTok];
            }
        }
    }
}

//------------------------------------------------------------------------------

- (void) shakeTikTok
{
    NSLog(@"Shaking Tik n' Tok");

    // setup the world
    [self startWorld];

    // add impulse 
    b2Body* body = mWorld->GetBodyList();
    body->ApplyLinearImpulse(b2Vec2(5000, 5000), body->GetWorldCenter());
    body = body->GetNext();
    body->ApplyLinearImpulse(b2Vec2(-5000, 5000), body->GetWorldCenter());

    // update images
    [self setShakenTikTok];
}

//------------------------------------------------------------------------------
#pragma - Memory Management
//------------------------------------------------------------------------------

/** 
 * Releases the view if it doesn't have a superview.
 * Release any cached data, images, etc that aren't in use.
 */
- (void) didReceiveMemoryWarning
{
    [self stopWorld];
    [super didReceiveMemoryWarning];
}

//------------------------------------------------------------------------------

- (void) dealloc
{
    [self stopWorld];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
