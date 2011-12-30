//
//  GradientView.m
//  TikTok
//
//  Created by Moiz Merchant on 12/29/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <QuartzCore/QuartzCore.h>
#import "GradientView.h"

//------------------------------------------------------------------------------
// interface definition 
//------------------------------------------------------------------------------

@interface GradientView ()
    - (void) drawGradient:(CGRect)rect;
    - (void) drawBorder:(CGRect)rect;
@end

//------------------------------------------------------------------------------
// interface implementation 
//------------------------------------------------------------------------------

@implementation GradientView 

//------------------------------------------------------------------------------

@synthesize color  = mColor;
@synthesize border = mBorder;

//------------------------------------------------------------------------------

- (void) initialize
{
    self.color               = [UIColor orangeColor];
    self.border              = 10.0;
    self.layer.shadowColor   = [[UIColor blackColor] CGColor];
    self.layer.shadowOffset  = CGSizeMake(3.0f, 3.0f);
    self.layer.shadowOpacity = 0.4f;
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
    [mColor release];
    [super dealloc];
}

//------------------------------------------------------------------------------

- (void) drawRect:(CGRect)rect
{
    [self drawGradient:rect];
    [self drawBorder:rect];
}

//------------------------------------------------------------------------------

- (void) drawGradient:(CGRect)rect
{
    // break the color down to hsv
    CGFloat hue, saturation, brightness;
    [UIColor red:self.color.red green:self.color.green blue:self.color.blue 
        toHue:&hue saturation:&saturation brightness:&brightness];

    // create the gradient colors by moving up and down the sat and brightness
    UIColor *startColor   = [UIColor colorWithHue:hue 
                                       saturation:saturation - 0.1
                                       brightness:brightness 
                                            alpha:1.0];
    UIColor *endColor = [UIColor colorWithHue:hue 
                                   saturation:saturation + 0.2 
                                   brightness:brightness + 0.2 
                                        alpha:1.0];

    // setup gradient data
    size_t locationCount   = 2;
    CGFloat locationList[] = { 0.0, 1.0 };
    CGFloat colorList[]    = {
        startColor.red, startColor.green, startColor.blue, 1.0,
        endColor.red,   endColor.green,   endColor.blue,   1.0
    };

    // create simple linear gradient 
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient     = CGGradientCreateWithColorComponents(
        colorSpace, colorList, locationList, locationCount);

    // fill view with gradient, allow border
    CGSize size    = rect.size;
    CGPoint start  = rect.origin;
    CGPoint end    = CGPointMake(start.x, start.y + size.height);

    // draw the gradient
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextDrawLinearGradient(context, gradient, start, end, 0);
}

//------------------------------------------------------------------------------

- (void) drawBorder:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, self.border);
    CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextStrokeRect(context, rect);
}

//------------------------------------------------------------------------------

@end

