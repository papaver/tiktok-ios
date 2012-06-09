//
//  MerchantPinViewController.m
//  TikTok
//
//  Created by Moiz Merchant on 06/08/12.
//  Copyright (c) 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "MerchantPinViewController.h"
#import "ASIHTTPRequest.h"
#import "TikTokApi.h"
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

@interface MerchantPinViewController ()
    - (void) setupToolbar;
    - (void) validate;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation MerchantPinViewController

//------------------------------------------------------------------------------

@synthesize couponId = mCouponId;

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
    [Analytics passCheckpoint:@"Merchant Pin"];

    // [iOS4] fix for missing font bradley hand bold
    UILabel *copy = (UILabel*)[self.view viewWithTag:kTagCopy];
    if (copy.font == nil) {
        copy.font  = [UIFont fontWithName:@"BradleyHandITCTTBold" size:18];
    }

    // add keyboard show notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];

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

- (void) keyboardDidShow:(NSNotification*)notification
{
    [self addButtonToKeyboard];
}

//------------------------------------------------------------------------------
#pragma mark - Helper Functions
//------------------------------------------------------------------------------

- (void) setupToolbar
{
    // grab current button in toolbar
    UIToolbar *toolbar = (UIToolbar*)[self.view viewWithTag:kTagToolbar];

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

- (void) addButtonToKeyboard
{
    // setup custom button
    UIImage *upButton    = [UIImage imageNamed:@"DoneUp.png"];
    UIImage *downButton  = [UIImage imageNamed:@"DoneDown.png"];
    UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    doneButton.frame = CGRectMake(0, 163, 106, 53);
    doneButton.adjustsImageWhenHighlighted = NO;
    [doneButton setImage:upButton forState:UIControlStateNormal];
    [doneButton setImage:downButton forState:UIControlStateHighlighted];
    [doneButton addTarget:self
                   action:@selector(validate)
         forControlEvents:UIControlEventTouchUpInside];

    // locate keyboard view
    UIWindow* window = [[[UIApplication sharedApplication] windows] objectAtIndex:1];
    for (UIView *keyboard in window.subviews) {
       if ([[keyboard description] hasPrefix:@"<UIPeripheralHost"] == YES) {
            [keyboard addSubview:doneButton];
            break;
       }
    }
}

//------------------------------------------------------------------------------
#pragma mark - Events
//------------------------------------------------------------------------------

- (void) validate
{
    UITextField *textField = (UITextField*)[self.view viewWithTag:kTagInput];
    [self textFieldShouldReturn:textField];
    [textField resignFirstResponder];
}

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
        NSString *title = NSLocalizedString(@"MERCHANT_PIN", nil);
        NSString *message;

        // verify pin validation succeeded
        NSString *status = [response objectForComplexKey:kTikTokApiKeyStatus@".merchant_redeem"];
        if ([status isEqualToString:kTikTokApiStatusOkay]) {
            message = NSLocalizedString(@"MERCHANT_PIN_SUCCESS", nil);
            [self close];
        } else {
            message = [response objectForComplexKey:kTikTokApiKeyError@".merchant_redeem"];
        }

        // display redemption status
        [Utilities displaySimpleAlertWithTitle:title andMessage:message];

        // unlock textfield
        textField.enabled = YES;
        [spinner stopAnimating];
    };

    // alert user of error
    api.errorHandler = ^(ASIHTTPRequest *request) {
        NSString *title   = NSLocalizedString(@"MERCHANT_PIN", nil);
        NSString *message = NSLocalizedString(@"MERCHANT_PIN_FAIL", nil);
        [Utilities displaySimpleAlertWithTitle:title andMessage:message];
        textField.enabled = YES;
        [spinner stopAnimating];
    };

    // attempt to validate merchant pin
    [api validateMerchantPin:textField.text forCoupon:self.couponId];

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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//------------------------------------------------------------------------------

- (void) dealloc
{
    [mCouponId release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
