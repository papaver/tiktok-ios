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
// forward declarations
//------------------------------------------------------------------------------

@protocol UILabelExtDelegate;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface UILabelExt : UILabel
{
    UIColor                *mHighlightColor;
    id<UILabelExtDelegate>  mDelegate;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain)          UIColor                *highlightColor;
@property (nonatomic, weak)   IBOutlet id<UILabelExtDelegate>  delegate;

//------------------------------------------------------------------------------

@end

//------------------------------------------------------------------------------
// protocol definition
//------------------------------------------------------------------------------

@protocol UILabelExtDelegate <NSObject>

@optional

- (void) tappedLabelView:(UILabelExt*)labelView;

@end
