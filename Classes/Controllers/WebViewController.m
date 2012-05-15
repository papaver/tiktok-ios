//
//  WebViewController.m
//  TikTok
//
//  Created by Moiz Merchant on 1/27/12.
//  Copyright (c) 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "WebViewController.h"
#import "Utilities.h"

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface WebViewController ()
    - (void) waitForLoad;
    - (void) showWebPage;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation WebViewController

//------------------------------------------------------------------------------

@synthesize webView           = mWebView;
@synthesize activityIndicator = mActivityIndicator;
@synthesize url               = mUrl;

//------------------------------------------------------------------------------

- (id) initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

//------------------------------------------------------------------------------
#pragma mark - View lifecycle
//------------------------------------------------------------------------------

/**
 * Do any additional setup after loading the view from its nib.
 */
- (void) viewDidLoad
{
    [super viewDidLoad];

    [self waitForLoad];

    // make sure url is properly formatted
    NSString *url = [self formattedUrl];

    // load requset
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [self.webView loadRequest:request]; 
}

//------------------------------------------------------------------------------

/**
 * Release any retained subviews of the main view.
 */
- (void) viewDidUnload
{
    [super viewDidUnload];
}

//------------------------------------------------------------------------------

/**
 * Return YES for supported orientations.
 */
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

//------------------------------------------------------------------------------
#pragma mark - Helper Functions
//------------------------------------------------------------------------------

- (NSString*) formattedUrl
{
    NSString *url = self.url;
    if (![self.url hasPrefix:@"http"]) {
        url = $string(@"http://%@", self.url);
    }
    return url;
}

//------------------------------------------------------------------------------

- (void) waitForLoad
{
    // make sure webview is hidden
    self.webView.hidden = YES;

    // make sure activity indicator is running
    [self.activityIndicator startAnimating];
}

//------------------------------------------------------------------------------

- (void) showWebPage
{
    // show the webpage
    self.webView.hidden = NO;

    // hide the activity indicator
    [self.activityIndicator stopAnimating];
}

//------------------------------------------------------------------------------
#pragma mark - UIWebView Delegate
//------------------------------------------------------------------------------

- (void) webViewDidFinishLoad:(UIWebView*)webView
{
    NSString *state = [webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];  
    if ([state isEqualToString:@"complete"] || [state isEqualToString:@"interactive"]) {
        [self showWebPage];
    }
}
    
//------------------------------------------------------------------------------

- (void) webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error
{
    NSLog(@"WebViewController: failed to load webpage: %@", error);
    NSString *title   = NSLocalizedString(@"WEBVIEW_SUPPORT", nil);
    NSString *message = NSLocalizedString(@"WEBVIEW_LOAD_FAILED", nil);
    [Utilities displaySimpleAlertWithTitle:title andMessage:message];
}

//------------------------------------------------------------------------------
#pragma mark - Memory Management
//------------------------------------------------------------------------------

/**
 * Releases the view if it doesn't have a superview.
 */
- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

//------------------------------------------------------------------------------

- (void) dealloc
{
    mWebView.delegate = nil;
    [super dealloc];
}

@end
