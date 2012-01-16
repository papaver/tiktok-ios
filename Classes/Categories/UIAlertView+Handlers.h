//
//  UIAlertView+Handlers.h
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

typedef void (^UIAlertViewSelectionHandler)(NSInteger);

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface UIAlertView (Handlers)

/**
 * Initialize an alert view using a button selection handler.
 */
- (id) initWithTitle:(NSString*)title 
             message:(NSString*)message 
         withHandler:(UIAlertViewSelectionHandler)handler
   cancelButtonTitle:(NSString*)cancelButtonTitle 
   otherButtonTitles:(NSString*)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

//-----------------------------------------------------------------------------

@end
