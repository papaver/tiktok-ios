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

#define $string(...) [NSString stringWithFormat:__VA_ARGS__]
#define $array(...)  [NSArray arrayWithObjects:__VA_ARGS__]
#define $dict(k, v)  [NSDictionary dictionaryWithObjects:v forKeys:k]

