//
//  MFMessageComposeViewController+Handlers.h
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

typedef void (^MFMessageComposeViewControllerCompletionHandler)(
                MFMessageComposeViewController* controller,
                MessageComposeResult result);

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface MFMessageComposeViewController (Handlers) <MFMessageComposeViewControllerDelegate> 

//-----------------------------------------------------------------------------

/**
 * Called when mail controller has completed.
 */
@property (nonatomic, copy) MFMessageComposeViewControllerCompletionHandler completionHandler;
      
//-----------------------------------------------------------------------------

@end
