//
//  TikTokApi.h
//  TikTok
//
//  Created by Moiz Merchant on 4/30/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports 
//------------------------------------------------------------------------------

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>
#import "SBJson.h"

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

@class ASIHTTPRequest;

//------------------------------------------------------------------------------
// typedefs
//------------------------------------------------------------------------------

typedef void (^TikTokApiCompletionHandler)(ASIHTTPRequest*);

//------------------------------------------------------------------------------
// interface implementation 
//------------------------------------------------------------------------------

@interface TikTokApi : NSObject <SBJsonStreamParserAdapterDelegate>
{
    SBJsonStreamParser         *mParser;
    SBJsonStreamParserAdapter  *mAdapter;
    NSMutableArray             *mJsonData;
    SEL                         mParserMethod;
    TikTokApiCompletionHandler  mCompletionHandler;
    TikTokApiCompletionHandler  mErrorHandler;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) SBJsonStreamParser         *parser;
@property (nonatomic, retain) SBJsonStreamParserAdapter  *adapter;
@property (nonatomic, retain) NSMutableArray             *jsonData;
@property (nonatomic, copy)   TikTokApiCompletionHandler  completionHandler;
@property (nonatomic, copy)   TikTokApiCompletionHandler  errorHandler;

//------------------------------------------------------------------------------

- (void) registerDevice:(NSString*)deviceId;
- (void) validateRegistration;
- (void) registerNotificationToken:(NSString*)token;
- (void) syncActiveCoupons;

//------------------------------------------------------------------------------

@end
