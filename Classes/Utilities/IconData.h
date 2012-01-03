//
//  IconData.h
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
// interface definition
//-----------------------------------------------------------------------------

@interface IconData : NSObject
{
    NSNumber *mIconId;
    NSURL    *mIconUrl;
}

//-----------------------------------------------------------------------------

@property (nonatomic, retain) NSNumber *iconId;
@property (nonatomic, retain) NSURL    *iconUrl;

//-----------------------------------------------------------------------------

/**
 * Creates a new icon given the id and url.
 */
+ (IconData*) withId:(NSNumber*)iconId andUrl:(NSString*)iconUrl;

/**
 * Initializes a new icon given the id and url.
 */
- (id) initWithId:(NSNumber*)iconId andUrl:(NSString*)iconUrl;

//-----------------------------------------------------------------------------

@end
