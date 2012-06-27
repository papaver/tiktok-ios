//
//  FacebookResult.h
//  TikTok
//
//  Created by Moiz Merchant on 06/11/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes
//-----------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "FBConnect.h"

//-----------------------------------------------------------------------------
// typedefs
//-----------------------------------------------------------------------------

typedef void (^FacebookResultRequestLoading)(FBRequest*);
typedef void (^FacebookResultDidReceiveResponse)(FBRequest*, NSURLResponse*);
typedef void (^FacebookResultDidFailWithError)(FBRequest*, NSError*);
typedef void (^FacebookResultDidLoad)(FBRequest*, id);
typedef void (^FacebookResultDidLoadRawResponse)(FBRequest*, NSData*);

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface FacebookResult : NSObject <FBRequestDelegate>

{
    Facebook                         *mFacebook;
    FacebookResultRequestLoading      mRequestLoadingHandler;
    FacebookResultDidReceiveResponse  mDidReceiveResponseHandler;
    FacebookResultDidFailWithError    mDidFailWithErrorHandler;
    FacebookResultDidLoad             mDidLoadHandler;
    FacebookResultDidLoadRawResponse  mDidLoadRawResponseHandler;
}

//-----------------------------------------------------------------------------

@property(nonatomic, retain) Facebook                        *facebook;
@property(nonatomic, copy)   FacebookResultRequestLoading     requestLoadingHandler;
@property(nonatomic, copy)   FacebookResultDidReceiveResponse didReceiveResponseHandler;
@property(nonatomic, copy)   FacebookResultDidFailWithError   didFailWithErrorHandler;
@property(nonatomic, copy)   FacebookResultDidLoad            didLoadHandler;
@property(nonatomic, copy)   FacebookResultDidLoadRawResponse didLoadRawResponseHandler;

//-----------------------------------------------------------------------------

- (id) initWithFacebook:(Facebook*)facebook;

//-----------------------------------------------------------------------------

@end
