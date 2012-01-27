//
//  WebViewController.h
//  TikTok
//
//  Created by Moiz Merchant on 1/27/12.
//  Copyright (c) 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface WebViewController : UIViewController <UIWebViewDelegate>
{
    UIWebView               *mWebView;
    UIActivityIndicatorView *mActivityIndicator;
    NSString                *mUrl;
}

//------------------------------------------------------------------------------

@property(nonatomic, retain) IBOutlet UIWebView               *webView;
@property(nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;
@property(nonatomic, retain)          NSString                *url;

//------------------------------------------------------------------------------

@end
