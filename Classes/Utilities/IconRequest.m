//
//  IconRequest.m
//  TikTok
//
//  Created by Moiz Merchant on 01/03/12.
//  Copyright 2011 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes 
//-----------------------------------------------------------------------------

#import "IconRequest.h"
#import "ASIHTTPRequest.h"

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation IconRequest

//-----------------------------------------------------------------------------

@synthesize request  = mRequest;
@synthesize handlers = mHandlers;

//-----------------------------------------------------------------------------

- (id) init
{
    self = [super init];
    if (self) {
        self.handlers = [[[NSMutableArray alloc] init] autorelease];
    }
    return self;
}

//-----------------------------------------------------------------------------

- (void) dealloc
{
    [mRequest release];
    [mHandlers release];
    [super dealloc];
}

//-----------------------------------------------------------------------------

@end

