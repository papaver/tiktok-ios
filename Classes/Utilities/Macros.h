//
//  Macros.h
//  TikTok
//
//  Created by Moiz Merchant on 12/07/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// defines
//------------------------------------------------------------------------------

/**
 * Familiars
 */
#define $string(...) [NSString stringWithFormat:__VA_ARGS__]
#define $array(...)  [NSArray arrayWithObjects:__VA_ARGS__, nil]
#define $dict(k, v)  [NSDictionary dictionaryWithObjects:v forKeys:k]

/**
 * NSNumber
 */
#define $numb(b) [NSNumber numberWithBool:b]
#define $numi(i) [NSNumber numberWithInt:i]
#define $numd(d) [NSNumber numberWithDouble:d]

/**
 * Selectors
 */
#define $has_selector(c, m) [c respondsToSelector:@selector(m)]
