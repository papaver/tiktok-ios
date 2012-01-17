//
//  UIActionSheet+Handlers.h
//  TikTok
//
//  Created by Moiz Merchant on 01/16/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes
//-----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

//-----------------------------------------------------------------------------
// typedef 
//-----------------------------------------------------------------------------

typedef void (^UIActionSheetSelectionHandler)(NSInteger);

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface UIActionSheet (Handlers) <UIActionSheetDelegate> 

/**
 * Initialize an action sheet using a button selection handler.
 */
- (id) initWithTitle:(NSString*)title 
           withHandler:(UIActionSheetSelectionHandler)handler
     cancelButtonTitle:(NSString*)cancelButtonTitle 
destructiveButtonTitle:(NSString*)destructiveButtonTitle 
     otherButtonTitles:(NSString*)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;
       
//-----------------------------------------------------------------------------

@end
