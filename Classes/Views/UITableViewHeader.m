//
//  UITableViewHeader.m
//  TikTok
//
//  Created by Moiz Merchant on 07/26/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <QuartzCore/QuartzCore.h>
#import "UITableViewHeader.h"

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation UITableViewHeader

//------------------------------------------------------------------------------

@synthesize section  = mSection;
@synthesize delegate = mDelegate;

//------------------------------------------------------------------------------
#pragma - Helper Functions
//------------------------------------------------------------------------------

- (void) initialize
{
    // setup tap gesture recognizer
    UITapGestureRecognizer *tapGesture =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggle)];
    [self addGestureRecognizer:tapGesture];

    // allow interaction
    self.userInteractionEnabled = YES;
}

//------------------------------------------------------------------------------

- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) [self initialize];
    return self;
}

//------------------------------------------------------------------------------

- (id) initWithCoder:(NSCoder*)encoder
{
    self = [super initWithCoder:encoder];
    if (self) [self initialize];
    return self;
}

//------------------------------------------------------------------------------

- (void) dealloc
{
    [super dealloc];
}

//------------------------------------------------------------------------------
#pragma - Events
//------------------------------------------------------------------------------

- (void) toggle
{
    if ($has_selector(self.delegate, headerView:sectionTapped:)) {
        [self.delegate headerView:self sectionTapped:self.section];
    }
}

//------------------------------------------------------------------------------

@end

