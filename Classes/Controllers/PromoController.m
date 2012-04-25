//
//  PromoController.m
//  TikTok
//
//  Created by Moiz Merchant on 03/27/12.
//  Copyright (c) 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "PromoController.h"
#import "ASIHTTPRequest.h"
#import "TikTokApi.h"
#import "Settings.h"
#import "Utilities.h"

//------------------------------------------------------------------------------
// enums
//------------------------------------------------------------------------------

enum ViewTag
{
    kTagInput       = 1,
    kTagCopy        = 2,
    kTagTok         = 3,
    kTagActivity    = 4,
    kTagToolbar     = 5
};

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface PromoController ()
    - (void) setupToolbar;
    - (void) syncCoupons;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation PromoController

//------------------------------------------------------------------------------
#pragma mark - Initialization
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
 * Only runs after view is loaded.
 */
- (void) viewDidLoad
{
    [Analytics passCheckpoint:@"Promo"];

    // [iOS4] fix for missing font bradley hand bold
    UILabel *copy = (UILabel*)[self.view viewWithTag:kTagCopy];
    if (copy.font == nil) {
        copy.font  = [UIFont fontWithName:@"BradleyHandITCTTBold" size:18];
    }

    // setup icon in toolbar
    [self setupToolbar];
}

//------------------------------------------------------------------------------

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

//------------------------------------------------------------------------------

/**
 * Override to allow orientations other than the default portrait orientation.
 * /
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

//------------------------------------------------------------------------------
#pragma mark - Helper Functions
//------------------------------------------------------------------------------

- (void) setupToolbar
{
    // grab current button in toolbar
    UIToolbar *toolbar      = (UIToolbar*)[self.view viewWithTag:kTagToolbar];

    // create icon bar button
    UIImageView *iconView = [[UIImageView alloc]
        initWithImage:[UIImage imageNamed:@"TopNavBarLogo"]];
    UIBarButtonItem *iconBarItem = [[UIBarButtonItem alloc]
        initWithCustomView:iconView];

    // add to toolbar
    NSMutableArray *items = [[NSMutableArray alloc] initWithArray:toolbar.items];
    [items insertObject:iconBarItem atIndex:1];
    toolbar.items = items;

    // cleanup
    [iconView release];
    [iconBarItem release];
    [items release];
}

//------------------------------------------------------------------------------

- (void) syncCoupons
{
    NSDate *lastUpdate     = [NSDate date];
    __block TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    api.completionHandler  = ^(NSDictionary *response) {
        [[Settings getInstance] setLastUpdate:lastUpdate];
    };

    // sync coupons
    Settings *settings = [Settings getInstance];
    [api syncActiveCoupons:settings.lastUpdate];
}

//------------------------------------------------------------------------------
#pragma mark - Events
//------------------------------------------------------------------------------

- (IBAction) close
{
    // [iOS4] fix for newer function
    if ($has_selector(self, presentingViewController)) {
        [self.presentingViewController dismissViewControllerAnimated:YES
                                                          completion:nil];
    } else {
        [self.parentViewController dismissModalViewControllerAnimated:YES];
    }
}

//------------------------------------------------------------------------------
#pragma mark - UITextView protocol
//------------------------------------------------------------------------------

- (BOOL) textFieldShouldReturn:(UITextField*)textField
{
    // lock textfield
    __block UIActivityIndicatorView *spinner =
        (UIActivityIndicatorView*)[self.view viewWithTag:kTagActivity];
    [spinner startAnimating];
    textField.enabled = NO;

    // setup api object
    __block TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    api.completionHandler  = ^(NSDictionary *response) {
        NSString *title = NSLocalizedString(@"PROMO", nil);
        NSString *message;

        // verify promo code succeeded
        NSString *status = [response objectForKey:kTikTokApiKeyStatus];
        if ([status isEqualToString:kTikTokApiStatusOkay]) {
            message = NSLocalizedString(@"PROMO_SUCCESS", nil);
            [self syncCoupons];
            [self close];
        } else if ([status isEqualToString:kTikTokApiStatusForbidden]) {
            message = NSLocalizedString(@"PROMO_USED", nil);
        } else if ([status isEqualToString:kTikTokApiStatusNotFound]) {
            message = NSLocalizedString(@"PROMO_INVALID", nil);
        }

        // display redemption status
        [Utilities displaySimpleAlertWithTitle:title andMessage:message];

        // unlock textfield
        textField.enabled = YES;
        [spinner stopAnimating];
    };

    // remove notification and close header
    api.errorHandler = ^(ASIHTTPRequest *request) {
        NSString *title   = NSLocalizedString(@"PROMO", nil);
        NSString *message = NSLocalizedString(@"PROMO_FAIL", nil);
        [Utilities displaySimpleAlertWithTitle:title andMessage:message];
        textField.enabled = YES;
        [spinner stopAnimating];
    };

    // attempt to redeem promo code
    [api redeemPromotion:textField.text];

    return YES;
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

/**
 * Relinquish ownership of anything that can be recreated in viewDidLoad
 * or on demand.
 */
- (void) viewDidUnload
{
}

//------------------------------------------------------------------------------

- (void) dealloc
{
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
