//
//  UIDefaults.m
//  TikTok
//
//  Created by Moiz Merchant on 12/20/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes 
//-----------------------------------------------------------------------------

#import "UIDefaults.h"

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation UIDefaults

//-----------------------------------------------------------------------------

+ (UIColor*) getTikColor
{
    static UIColor *tikColor = nil;
    if (tikColor == nil) {
        CGFloat red   = 130.0 / 255.0;
        CGFloat green = 179.0 / 255.0;
        CGFloat blue  =  79.0 / 255.0;
        tikColor      = [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
        [tikColor retain];
    }
    return tikColor;
}

//-----------------------------------------------------------------------------

+ (UIColor*) getTokColor
{
    static UIColor *tokColor = nil;
    if (tokColor == nil) {
        CGFloat red   = 211.0 / 255.0;
        CGFloat green =  61.0 / 255.0;
        CGFloat blue  =  61.0 / 255.0;
        tokColor      = [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
        [tokColor retain];
    }
    return tokColor;
}

//-----------------------------------------------------------------------------

@end
