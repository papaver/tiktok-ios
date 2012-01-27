//
//  InputTableViewCell.m
//  TikTok
//
//  Created by Moiz Merchant on 01/25/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "InputTableViewCell.h"
#import "Coupon.h"

//------------------------------------------------------------------------------
// interface implementation 
//------------------------------------------------------------------------------

@implementation InputTableViewCell 

//------------------------------------------------------------------------------

@synthesize inputView;
@synthesize inputAccessoryView;

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
#pragma - Memory Management
//------------------------------------------------------------------------------

- (void) dealloc
{
    [self.inputView release];
    [self.inputAccessoryView release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end

