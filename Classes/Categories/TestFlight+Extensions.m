//
//  TestFlight+Extensions.m
//  TikTok
//
//  Created by Moiz Merchant on 01/05/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes 
//-----------------------------------------------------------------------------

#import "TestFlight+Extensions.h"

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation TestFlight (Extensions)

//-----------------------------------------------------------------------------

+ (void) passCheckpointOnce:(NSString*)checkpointName;
{
    // make sure a checkpoint dict exists
    static NSMutableDictionary *sCheckpoints = nil;
    if (sCheckpoints == nil) {
        sCheckpoints = [[[NSMutableDictionary alloc] init] retain];
    }

    // check if the object exists in the dict
    if ([sCheckpoints objectForKey:checkpointName]) {
        return;
    }

    // run the checkpoint
    [TestFlight passCheckpoint:checkpointName];

    // add to dict
    [sCheckpoints setObject:$numb(YES) forKey:checkpointName];
}

//-----------------------------------------------------------------------------

@end
