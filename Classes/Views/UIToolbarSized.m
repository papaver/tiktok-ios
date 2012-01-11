//
//  UIToolbarSized.m
//  TikTok
//
//  Created by Moiz Merchant on 01/10/12.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "UIToolbarSized.h"

//------------------------------------------------------------------------------
// interface implementation 
//------------------------------------------------------------------------------

@implementation UIToolbarSized 

//------------------------------------------------------------------------------

- (CGSize) sizeThatFits:(CGSize)size 
{
    CGSize result = [super sizeThatFits:size];
    result.height = 60;
    return result;
}; 

//------------------------------------------------------------------------------

@end

