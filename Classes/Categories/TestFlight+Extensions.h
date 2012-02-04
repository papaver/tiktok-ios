//
//  TestFlight+Extensions.h
//  TikTok
//
//  Created by Moiz Merchant on 01/05/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes
//-----------------------------------------------------------------------------

#import <Foundation/Foundation.h>

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface TestFlight (Extensions)

/**
 * Overloaded to send checkpoints to server once a session.
 */
+ (void) passCheckpointOnce:(NSString*)checkpointName;

//-----------------------------------------------------------------------------

@end
