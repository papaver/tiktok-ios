//
//  IconData.m
//  TikTok
//
//  Created by Moiz Merchant on 01/03/12.
//  Copyright 2011 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes 
//-----------------------------------------------------------------------------

#import "IconData.h"

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation IconData

//-----------------------------------------------------------------------------

@synthesize iconId  = mIconId;
@synthesize iconUrl = mIconUrl;

//-----------------------------------------------------------------------------

+ (IconData*) withId:(NSNumber*)iconId andUrl:(NSString*)iconUrl
{
    IconData *iconData = 
        [[[IconData alloc] initWithId:iconId andUrl:iconUrl] autorelease];
    return iconData;
}

//-----------------------------------------------------------------------------

- (id) initWithId:(NSNumber*)iconId andUrl:(NSString*)iconUrl
{
    self = [super init];
    if (self) {
        self.iconId  = iconId;
        self.iconUrl = [NSURL URLWithString:iconUrl];
    }
    return self; 
}

//-----------------------------------------------------------------------------

- (void) dealloc
{
    [mIconId release];
    [mIconUrl release];
    [super dealloc];
}

//-----------------------------------------------------------------------------

@end
