//
//  UIAlertView+Handlers.m
//  TikTok
//
//  Created by Moiz Merchant on 01/16/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes 
//-----------------------------------------------------------------------------

#import <objc/runtime.h>
#import "UIAlertView+Handlers.h"

//-----------------------------------------------------------------------------
// statics
//-----------------------------------------------------------------------------

static char const* const HandlerKey = "SelectionHandler";

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation UIAlertView (Handlers)

//-----------------------------------------------------------------------------

- (id) initWithTitle:(NSString*)title 
             message:(NSString*)message 
         withHandler:(UIAlertViewSelectionHandler)handler
   cancelButtonTitle:(NSString*)cancelButtonTitle 
   otherButtonTitles:(NSString*)otherButtonTitles, ... 
{
    // initialize the view using self as the delegate handler
    self = [self initWithTitle:title 
                       message:message 
                      delegate:self 
             cancelButtonTitle:cancelButtonTitle 
             otherButtonTitles:nil];

    // add rest of the buttons and save the handler for later use
    if (self) {
        
        // add the other buttons
        va_list args;
        va_start(args, otherButtonTitles);
        for (NSString *arg = otherButtonTitles; arg; arg = va_arg(args, NSString*)) {
            [self addButtonWithTitle:arg];
        }
        va_end(args);

        // save the handler
        objc_setAssociatedObject(self, HandlerKey, handler, OBJC_ASSOCIATION_COPY);
    }

    return self;
}

//-----------------------------------------------------------------------------

- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // grab the handler 
    UIAlertViewSelectionHandler handler = objc_getAssociatedObject(self, HandlerKey);

    // run the handler
    if (handler) handler(buttonIndex);
}

//-----------------------------------------------------------------------------

@end
