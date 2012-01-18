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
    kTagCategory     = 5,
    kTagName         = 1,
    kTagIcon         = 3,
    kTagIconActivity = 4,
    kTagDetails      = 6,
    kTagAddress      = 7,
    kTagPhone        = 8,
    kTagWebsite      = 9,
};

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface MerchantViewController ()
    - (void) setupGestureRecognizers;
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
 */
- (void) viewDidLoad 
{
    [super viewDidLoad];
    [self setupGestureRecognizers];

    // setup title
    self.title = @"Merchant";

    // tag testflight checkpoint
    [TestFlight passCheckpoint:@"Merchant"];
}

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

- (void) setupGestureRecognizers
{
    UILabel *address = (UILabel*)[self.view viewWithTag:kTagAddress]; 
    UILabel *phone   = (UILabel*)[self.view viewWithTag:kTagPhone]; 
    UILabel *website = (UILabel*)[self.view viewWithTag:kTagWebsite]; 

    UITapGestureRecognizer* addressTap = 
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickAddress:)];
    UITapGestureRecognizer* phoneTap = 
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickPhone:)];
    UITapGestureRecognizer* websiteTap = 
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickWebsite:)];

    [address setUserInteractionEnabled:YES];
    [address addGestureRecognizer:addressTap];
    [phone setUserInteractionEnabled:YES];
    [phone addGestureRecognizer:phoneTap];
    [website setUserInteractionEnabled:YES];
    [website addGestureRecognizer:websiteTap];

    [addressTap release];
    [phoneTap release];
    [websiteTap release];
}

//------------------------------------------------------------------------------

- (void) setupMerchantDetails
{
    // category
    UILabel *category = (UILabel*)[self.view viewWithTag:kTagCategory];
    category.text     = self.merchant.category;
    
    // name
    UILabel *name = (UILabel*)[self.view viewWithTag:kTagName];
    name.text     = [self.merchant.name uppercaseString];

    // address
    UILabel *address   = (UILabel*)[self.view viewWithTag:kTagAddress]; 
    NSRange firstComma = [self.merchant.address rangeOfString:@", "];
    address.text     = [self.merchant.address 
        stringByReplacingOccurrencesOfString:@", " 
                                  withString:@",\n" 
                                     options:NSCaseInsensitiveSearch 
                                       range:NSMakeRange(0, firstComma.location + 2)];

    // phone number
    UILabel *phone = (UILabel*)[self.view viewWithTag:kTagPhone]; 
    phone.text     = self.merchant.phone;

    // website
    UILabel *website = (UILabel*)[self.view viewWithTag:kTagWebsite]; 
    website.text     = [self.merchant.websiteUrl
        stringByReplacingOccurrencesOfString:@"http://" 
                                  withString:@""];

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
    controller.title                  = self.merchant.name;

    // present the webview, should this be done modally?
    //[self presentModalViewController:controller animated:YES];
    [self.navigationController pushViewController:controller animated:YES];

    // cleanup
    [webView release];
    [controller release];
}

//------------------------------------------------------------------------------

- (IBAction) clickAddress:(id)sender
{
    NSString *address = [self.merchant.address
        stringByReplacingOccurrencesOfString:@" " 
                                  withString:@"%20"];
    NSString *mapPath = $string(@"http://maps.google.com/maps?q=%@", address);
    NSURL *mapUrl = [NSURL URLWithString:mapPath];
    [[UIApplication sharedApplication] openURL:mapUrl];
}

//------------------------------------------------------------------------------

- (IBAction) clickPhone:(id)sender
{
    // construct message for verify phone call
    NSString *title   = $string(@"Calling %@", self.merchant.name);
    NSString *message = $string(@"Make call to %@?", self.merchant.phone);

    // display alert window
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
    [alert show];
    [alert release];
}

//------------------------------------------------------------------------------

- (void) alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        NSURL *phoneUrl = [NSURL URLWithString:$string(@"tel:%@", self.merchant.phone)];
        [[UIApplication sharedApplication] openURL:phoneUrl];
    }
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
