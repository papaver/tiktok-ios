//
//  MFMailComposeViewController+Handlers.h
//  TikTok
//
//  Created by Moiz Merchant on 01/17/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes
//-----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

//-----------------------------------------------------------------------------
// typedef 
//-----------------------------------------------------------------------------

typedef void (^MFMailComposeViewControllerCompletionHandler)(
                MFMailComposeViewController* controller,
                MFMailComposeResult result,
                NSError* error);

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface MFMailComposeViewController (Handlers) <MFMailComposeViewControllerDelegate> 

//-----------------------------------------------------------------------------

/**
 * Called when mail controller has completed.
 */
@property (nonatomic, copy) MFMailComposeViewControllerCompletionHandler completionHandler;
      
//-----------------------------------------------------------------------------

@end
