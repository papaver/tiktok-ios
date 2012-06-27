//
//  FacebookResult.m
//  TikTok
//
//  Created by Moiz Merchant on 06/11/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes
//-----------------------------------------------------------------------------

#import "FacebookResult.h"
#import "Constants.h"
#import "TikTokApi.h"

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation FacebookResult

//-----------------------------------------------------------------------------

@synthesize facebook                  = mFacebook;
@synthesize requestLoadingHandler     = mRequestLoadingHandler;
@synthesize didReceiveResponseHandler = mDidReceiveResponseHandler;
@synthesize didFailWithErrorHandler   = mDidFailWithErrorHandler;
@synthesize didLoadHandler            = mDidLoadHandler;
@synthesize didLoadRawResponseHandler = mDidLoadRawResponseHandler;

//-----------------------------------------------------------------------------
#pragma - Initialization
//-----------------------------------------------------------------------------

- (id) initWithFacebook:(Facebook*)facebook
{
    self = [super init];
    if (self) {
        self.facebook = facebook;
    }
    return self;
}

//-----------------------------------------------------------------------------
#pragma - FBRequest Delegate
//-----------------------------------------------------------------------------

- (void) requestLoading:(FBRequest*)request
{
    if (mRequestLoadingHandler != NULL) mRequestLoadingHandler(request);
}

//-----------------------------------------------------------------------------

- (void) request:(FBRequest*)request didReceiveResponse:(NSURLResponse*)response
{
    //NSLog(@"fb response: %@", response);
    if (mDidReceiveResponseHandler != NULL) {
        mDidReceiveResponseHandler(request, response);
    }
}

//-----------------------------------------------------------------------------

- (void) request:(FBRequest*)request didFailWithError:(NSError*)error
{
    if (mDidFailWithErrorHandler != NULL) {
        mDidFailWithErrorHandler(request, error);
    }
}

//-----------------------------------------------------------------------------

- (void) request:(FBRequest*)request didLoad:(id)result
{
    //NSLog(@"fb result: %@", result);
    if (mDidLoadHandler != NULL) {
        mDidLoadHandler(request, result);
    }
}

//-----------------------------------------------------------------------------

- (void)request:(FBRequest*)request didLoadRawResponse:(NSData*)data
{
    if (mDidLoadRawResponseHandler != NULL) {
        mDidLoadRawResponseHandler(request, data);
    }
}

//-----------------------------------------------------------------------------
#pragma - Memory Management
//-----------------------------------------------------------------------------

- (void) dealloc
{
    [mRequestLoadingHandler release];
    [mDidReceiveResponseHandler release];
    [mDidFailWithErrorHandler release];
    [mDidLoadHandler release];
    [mDidLoadRawResponseHandler release];
    [mFacebook release];
    [super dealloc];
}

//-----------------------------------------------------------------------------

@end
