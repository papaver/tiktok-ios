//
//  UILabelExt.m
//  TikTok
//
//  Created by Moiz Merchant on 12/29/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <QuartzCore/QuartzCore.h>
#import "UILabelExt.h"

//------------------------------------------------------------------------------
// interface definition 
//------------------------------------------------------------------------------

@interface UILabelExt ()
    - (void) highlightEnable:(bool)enable;
@end

//------------------------------------------------------------------------------
// interface implementation 
//------------------------------------------------------------------------------

@implementation UILabelExt 

//------------------------------------------------------------------------------

@synthesize highlightColor  = mHighlightColor;

//------------------------------------------------------------------------------
#pragma - Helper Functions
//------------------------------------------------------------------------------

- (void) initialize
{
    self.highlightColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.3];
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
    [mHighlightColor release];
    [super dealloc];
}

//------------------------------------------------------------------------------
#pragma - Helper Functions
//------------------------------------------------------------------------------

- (void) highlightEnable:(bool)enable
{
    CGFloat cornerRadius     = enable ? 2.0 : 0.0;
    UIColor *backgroundColor = enable ? self.highlightColor : [UIColor clearColor];

    // set layer attributes
    self.layer.cornerRadius    = cornerRadius;
    self.layer.backgroundColor = [backgroundColor CGColor];

    // redraw
    [self setNeedsDisplay];
}

//------------------------------------------------------------------------------
#pragma - Responder Chain
//------------------------------------------------------------------------------

- (BOOL) canBecomeFirstResponder
{
    return YES;
}

//------------------------------------------------------------------------------

- (BOOL) canResignFirstResponder
{
    return YES;
}

//------------------------------------------------------------------------------
#pragma - Events
//------------------------------------------------------------------------------

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self highlightEnable:true];
}

//------------------------------------------------------------------------------

- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self highlightEnable:false];
}

//------------------------------------------------------------------------------

- (void) touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self highlightEnable:false];
}

//------------------------------------------------------------------------------

@end

