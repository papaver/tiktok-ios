//
//  UILabelExt.h
//  TikTok
//
//  Created by Moiz Merchant on 01/11/12.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface UILabelExt : UILabel
{
    UIColor *mHighlightColor;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) UIColor *highlightColor;

//------------------------------------------------------------------------------

@end
