//
//  Debug.h
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

#define ANALYTICS_MODE_DEBUG    0

#define ANALYTICS_TESTFLIGHT    0
#define ANALYTICS_FLURRY        1
#define ANALYTICS_FLURRY_DEBUG  ANALYTICS_MODE_DEBUG

//------------------------------------------------------------------------------
// TikTokApi
//------------------------------------------------------------------------------

#define TIKTOKAPI_STAGING 0

//------------------------------------------------------------------------------
// Logging
//------------------------------------------------------------------------------

#define LOGGING_VIEWER           0
#define LOGGING_APP_DELEGATE     0
#define LOGGING_LOCATION_TRACKER 0

//------------------------------------------------------------------------------
// TestFlight Remote Logging
//------------------------------------------------------------------------------

#define RLog(__FORMAT__, ...) TFLog((@"%s [Line %d] " __FORMAT__), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
