//
//  UIActionSheet+Handlers.m
//  TikTok
//
//  Created by Moiz Merchant on 01/16/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes 
//-----------------------------------------------------------------------------

#import <objc/runtime.h>
#import "UIActionSheet+Handlers.h"

//-----------------------------------------------------------------------------
// statics
//-----------------------------------------------------------------------------

static char const* const HandlerKey = "ActionSheetSelectionHandler";

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation UIActionSheet (Handlers)

//-----------------------------------------------------------------------------

- (id) initWithTitle:(NSString*)title 
           withHandler:(UIActionSheetSelectionHandler)handler
     cancelButtonTitle:(NSString*)cancelButtonTitle 
destructiveButtonTitle:(NSString*)destructiveButtonTitle 
     otherButtonTitles:(NSString*)otherButtonTitles, ...
{
    // initialize the view using self as the delegate handler
    self = [self initWithTitle:title 
                      delegate:self
             cancelButtonTitle:nil 
        destructiveButtonTitle:nil 
             otherButtonTitles:nil];

    // add the buttons and save the handler for later use
    if (self) {

        // add destructive button
        if (destructiveButtonTitle) {
            [self addButtonWithTitle:destructiveButtonTitle];
            self.destructiveButtonIndex = 0;
        }
        
        // add the other buttons
        va_list args;
        va_start(args, otherButtonTitles);
        for (NSString *arg = otherButtonTitles; arg; arg = va_arg(args, NSString*)) {
            [self addButtonWithTitle:arg];
        }
        va_end(args);

        // add cancel button
        if (cancelButtonTitle) {
            [self addButtonWithTitle:cancelButtonTitle];
            self.cancelButtonIndex = self.numberOfButtons - 1;
        }

        // save the handler
        objc_setAssociatedObject(self, HandlerKey, handler, OBJC_ASSOCIATION_COPY);
    }

    return self;
}

//-----------------------------------------------------------------------------

- (void) actionSheet:(UIActionSheet*)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // grab the handler 
    UIActionSheetSelectionHandler handler = objc_getAssociatedObject(self, HandlerKey);

    // run the handler
    if (handler) handler(buttonIndex);
}

//-----------------------------------------------------------------------------

@end
