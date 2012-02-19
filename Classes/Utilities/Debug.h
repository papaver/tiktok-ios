//
//  Constants.h
//  TikTok
//
//  Created by Moiz Merchant on 02/10/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// Analytics 
//------------------------------------------------------------------------------

/**
 * DebugMode:
 *   TestFlight
 *   FlurryAnalytics w/ Dev ApiKey
 *   
 * ProductionMode:
 *   FlurryAnalytics w/ Production ApiKey
 */

#define ANALYTICS_MODE_DEBUG    1 

#define ANALYTICS_TESTFLIGHT    ANALYTICS_MODE_DEBUG
#define ANALYTICS_FLURRY        1
#define ANALYTICS_FLURRY_DEBUG  ANALYTICS_MODE_DEBUG

//------------------------------------------------------------------------------
// TikTokApi 
//------------------------------------------------------------------------------

#define TIKTOKAPI_STAGING 0
