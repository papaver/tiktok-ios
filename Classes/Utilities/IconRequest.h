//
//  IconRequest.h
//  TikTok
//
//  Created by Moiz Merchant on 01/03/12.
//  Copyright 2011 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes
//-----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

//-----------------------------------------------------------------------------
// forward declarations
//-----------------------------------------------------------------------------

@class ASIHTTPRequest;

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface IconRequest : NSObject
{
    ASIHTTPRequest *mRequest;
    NSMutableArray *mHandlers;
}

//-----------------------------------------------------------------------------

@property (nonatomic, retain) ASIHTTPRequest *request;
@property (nonatomic, retain) NSMutableArray *handlers;

//-----------------------------------------------------------------------------

@end
