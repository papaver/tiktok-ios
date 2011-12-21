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
// interface definition
//------------------------------------------------------------------------------

@interface TikTokPhysicsViewController ()
    -(void) createPhysicsWorld;
    -(void) addPhysicalBodyForView:(UIView*)physicalView;
    -(void) updateWorld:(NSTimer*)timer;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation TikTokPhysicsViewController

//------------------------------------------------------------------------------

@synthesize tik   = m_tik;
@synthesize tok   = m_tok;
@synthesize timer = m_timer;

//------------------------------------------------------------------------------
#pragma mark - View lifecycle
//------------------------------------------------------------------------------

- (void) viewDidLoad
{
    [super viewDidLoad];

    // setup the box2d physics world 
    [self createPhysicsWorld];

    // add tik and tok to the world
    [self addPhysicalBodyForView:m_tik];
    [self addPhysicalBodyForView:m_tok];

    // setup a timer to run the main update loop
    CGFloat interval = 1.0 / 60.0;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:interval 
                                                  target:self 
                                                selector:@selector(updateWorld:) 
                                                userInfo:nil 
                                                 repeats:YES];
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

/**
 * Return YES for supported orientations
 */
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
    //bool do_sleep = true;

    // construct a world object, which will hold and simulate the rigid bodies
    m_world = new b2World(gravity);
    m_world->SetContinuousPhysics(true);

    // define the ground body, bottom-left corner
    b2BodyDef groundBodyDef;
    groundBodyDef.position.Set(0, 0);

    // call the body factory which allocates memory for the ground body
    // from a pool and creates the ground box shape (also from a pool).
    // the body is also added to the world.
    b2Body* groundBody = m_world->CreateBody(&groundBodyDef);

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

    CGPoint center         = physicalView.center;
    CGPoint box_dimensions = CGPointMake(
        physicalView.bounds.size.width  / PTM_RATIO / 2.0,
        physicalView.bounds.size.height / PTM_RATIO / 2.0);

    bodyDef.position.Set(center.x / PTM_RATIO, (428.0 - center.y) / PTM_RATIO);
    bodyDef.userData = physicalView;

    // tell the physics world to create the body
    b2Body *body = m_world->CreateBody(&bodyDef);

    // define another box shape for our dynamic body.
    b2PolygonShape dynamic_box;
    dynamic_box.SetAsBox(box_dimensions.x, box_dimensions.y);

    // define the dynamic body fixture.
    b2FixtureDef fixtureDef;
    fixtureDef.shape       = &dynamic_box;
    fixtureDef.density     = 3.0f;
    fixtureDef.friction    = 0.3f;
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

    int32 velocity_iterations = 8;
    int32 position_iterations = 1;

    // instruct the world to perform a single step of simulation. It is
    // generally best to keep the time step and iterations fixed.
    m_world->Step(1.0f / 60.0f, velocity_iterations, position_iterations);

    //Iterate over the bodies in the physics world
    for (b2Body* body = m_world->GetBodyList(); body; body = body->GetNext()) {
        if (body->GetUserData() != NULL) {
            UIView *view = (UIView*)body->GetUserData();

            // y position subtracted because of flipped coordinate system
            view.center = CGPointMake(
                body->GetPosition().x * PTM_RATIO,
                self.view.bounds.size.height - body->GetPosition().y * PTM_RATIO);

            // update transform
            view.transform = CGAffineTransformMakeRotation(-body->GetAngle());
        }
    }
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
    [super didReceiveMemoryWarning];
}

//------------------------------------------------------------------------------

- (void) dealloc
{
    delete m_world;
    [self.timer invalidate];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
