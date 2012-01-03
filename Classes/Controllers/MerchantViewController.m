//
//  MerchantViewController.m
//  TikTok
//
//  Created by Moiz Merchant on 4/22/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "MerchantViewController.h"
#import "IconManager.h"
#import "Merchant.h"

//------------------------------------------------------------------------------
// enums
//------------------------------------------------------------------------------

enum MerchantTags 
{
    kTagName         = 1,
    kTagTagline      = 2,
    kTagIcon         = 3,
    kTagIconActivity = 4,
    kTagCategory     = 5,
    kTagDetails      = 6,
};

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface MerchantViewController ()
    - (void) setupMerchantDetails;
    - (void) setupIcon;
    - (void) setIcon:(UIImage*)image;
    - (void) presentWebsite:(NSString*)url;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation MerchantViewController

//------------------------------------------------------------------------------

@synthesize merchant = mMerchant;

//------------------------------------------------------------------------------
#pragma - View Lifecycle
//------------------------------------------------------------------------------

/**
 * Implement viewDidLoad to do additional setup after loading the view, 
 * typically from a nib.
 * /
- (void) viewDidLoad 
{
    [super viewDidLoad];
}
*/

//------------------------------------------------------------------------------

- (void) viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
    [self setupMerchantDetails];
}

//------------------------------------------------------------------------------

/*
- (void) viewDidAppear:(BOOL)animated 
{
    [super viewDidAppear:animated];
}
*/

//------------------------------------------------------------------------------

/*
- (void) viewWillDisappear:(BOOL)animated 
{
    [super viewWillDisappear:animated];
}
*/

//------------------------------------------------------------------------------

/**
 * Override to allow orientations other than the default portrait orientation.
 * /
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    // return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

//------------------------------------------------------------------------------
#pragma - Setup
//------------------------------------------------------------------------------

- (void) setupMerchantDetails
{
    // name
    UILabel *title = (UILabel*)[self.view viewWithTag:kTagName];
    title.text     = self.merchant.name;

    // tagline
    UILabel *tagline = (UILabel*)[self.view viewWithTag:kTagTagline];
    tagline.text     = self.merchant.tagline;

    // category
    UILabel *category = (UILabel*)[self.view viewWithTag:kTagCategory];
    category.text     = $string(@"Category: %@", self.merchant.category);
    
    // details
    UITextView *details = (UITextView*)[self.view viewWithTag:kTagDetails];
    details.text        = self.merchant.details;

    // icon
    [self setupIcon];
}

//------------------------------------------------------------------------------

- (void) setupIcon
{
    IconManager *iconManager = [IconManager getInstance];
    __block UIImage *image   = [iconManager getImage:self.merchant.iconData];

    // set merchant icon
    [self setIcon:image];

    // load image from server if not available
    if (!image) {
        [iconManager requestImage:self.merchant.iconData 
            withCompletionHandler:^(UIImage* image, NSError *error) {
                if (image != nil) {
                    [self setIcon:image];
                } else if (error) {
                    NSLog(@"MerchantViewController: Failed to load image, %@", error);
                }
            }];
    }
}

//------------------------------------------------------------------------------

- (void) setIcon:(UIImage*)image
{
    UIImageView *icon                  
        = (UIImageView*)[self.view viewWithTag:kTagIcon];
    UIActivityIndicatorView *spinner 
        = (UIActivityIndicatorView*)[self.view viewWithTag:kTagIconActivity];

    // update icon 
    icon.image  = image;
    icon.hidden = image == nil;

    // update spinner
    if (image) {
        [spinner stopAnimating];
    } else {
        [spinner startAnimating];
    }
}

//------------------------------------------------------------------------------
#pragma - Events
//------------------------------------------------------------------------------

- (void) presentWebsite:(NSString*)url
{
    // create a url request for the website
    NSURLRequest *request = 
        [NSURLRequest requestWithURL:[NSURL URLWithString:url]];

    // create a webview to display the url
    UIWebView *webView      = [[UIWebView alloc] init];
    [webView loadRequest:request];

    // setup a generic view controller
    UIViewController *controller      = [[UIViewController alloc] init];
    controller.view                   = webView;
    controller.modalTransitionStyle   = UIModalTransitionStyleCoverVertical;
    controller.modalPresentationStyle = UIModalPresentationFullScreen;

    // present the webview, should this be done modally?
    //[self presentModalViewController:controller animated:YES];
    [self.navigationController pushViewController:controller animated:YES];

    // cleanup
    [webView release];
    [controller release];
}

//------------------------------------------------------------------------------

- (IBAction) clickTwitter:(id)sender
{
    [self presentWebsite:self.merchant.twitterUrl];
}

//------------------------------------------------------------------------------

- (IBAction) clickFacebook:(id)sender
{
    [self presentWebsite:self.merchant.facebookUrl];
}

//------------------------------------------------------------------------------

- (IBAction) clickWebsite:(id)sender
{
    [self presentWebsite:self.merchant.websiteUrl];
}

//------------------------------------------------------------------------------
#pragma - Memory Management
//------------------------------------------------------------------------------

/** 
 * Releases the view if it doesn't have a superview.
 */
- (void) didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning];
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

- (void) dealloc 
{
    [mMerchant release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
