//
//  MFMessageComposeViewController+Handlers.m
//  TikTok
//
//  Created by Moiz Merchant on 01/17/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes 
//-----------------------------------------------------------------------------

#import <objc/runtime.h>
#import "MFMessageComposeViewController+Handlers.h"

//-----------------------------------------------------------------------------
// statics
//-----------------------------------------------------------------------------

static char const* const HandlerKey = "MessageComposeViewControllerCompletionHandler";

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation MFMessageComposeViewController (Handlers)

//-----------------------------------------------------------------------------

@dynamic completionHandler;

//-----------------------------------------------------------------------------

- (MFMessageComposeViewControllerCompletionHandler) completionHandler 
{
    return objc_getAssociatedObject(self, HandlerKey);
}

//-----------------------------------------------------------------------------

- (void) setCompletionHandler:(MFMessageComposeViewControllerCompletionHandler)handler 
{
    objc_setAssociatedObject(self, HandlerKey, handler, OBJC_ASSOCIATION_COPY);
    self.messageComposeDelegate = handler ? self : nil;
}

//-----------------------------------------------------------------------------

- (void) messageComposeViewController:(MFMessageComposeViewController*)controller 
                  didFinishWithResult:(MessageComposeResult)result
{
    // run the handler
    if (self.completionHandler) self.completionHandler(controller, result);
}

//-----------------------------------------------------------------------------

@end
