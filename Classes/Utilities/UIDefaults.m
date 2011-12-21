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
    static UIColor *tik_color = nil;
    if (tik_color == nil) {
        CGFloat red   = 130.0 / 255.0;
        CGFloat green = 179.0 / 255.0;
        CGFloat blue  =  79.0 / 255.0;
        tik_color     = [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
        [tik_color retain];
    }
    return tik_color;
}

//-----------------------------------------------------------------------------

+ (UIColor*) getTokColor
{
    static UIColor *tok_color = nil;
    if (tok_color == nil) {
        CGFloat red   = 211.0 / 255.0;
        CGFloat green =  61.0 / 255.0;
        CGFloat blue  =  61.0 / 255.0;
        tok_color     = [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
        [tok_color retain];
    }
    return tok_color;
}

//-----------------------------------------------------------------------------

@end
