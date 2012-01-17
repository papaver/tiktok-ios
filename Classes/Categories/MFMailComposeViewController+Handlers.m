//
//  MFMailComposeViewController+Handlers.m
//  TikTok
//
//  Created by Moiz Merchant on 01/17/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes 
//-----------------------------------------------------------------------------

#import <objc/runtime.h>
#import "MFMailComposeViewController+Handlers.h"

//-----------------------------------------------------------------------------
// statics
//-----------------------------------------------------------------------------

static char const* const HandlerKey = "MailComposeViewControllerCompletionHandler";

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation MFMailComposeViewController (Handlers)

//-----------------------------------------------------------------------------

@dynamic completionHandler;

//-----------------------------------------------------------------------------

- (MFMailComposeViewControllerCompletionHandler) completionHandler 
{
    return objc_getAssociatedObject(self, HandlerKey);
}

//-----------------------------------------------------------------------------

- (void) setCompletionHandler:(MFMailComposeViewControllerCompletionHandler)handler 
{
    objc_setAssociatedObject(self, HandlerKey, handler, OBJC_ASSOCIATION_COPY);
    self.mailComposeDelegate = handler ? self : nil;
}

//-----------------------------------------------------------------------------

- (void) mailComposeController:(MFMailComposeViewController*)controller 
           didFinishWithResult:(MFMailComposeResult)result 
                         error:(NSError*)error 
{
    // run the handler
    if (self.completionHandler) self.completionHandler(controller, result, error);
}

//-----------------------------------------------------------------------------

@end
