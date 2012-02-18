//
//  CouponDetailViewController.m
//  TikTok
//
//  Created by Moiz Merchant on 4/22/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <Twitter/Twitter.h>
#import <QuartzCore/QuartzCore.h>
#import "CouponDetailViewController.h"
#import "Coupon.h"
#import "FacebookManager.h"
#import "GradientView.h"
#import "IconManager.h"
#import "LocationMapViewController.h"
#import "Merchant.h"
#import "MerchantViewController.h"
#import "TikTokApi.h"
#import "Utilities.h"

//------------------------------------------------------------------------------
// enums
//------------------------------------------------------------------------------

enum CouponDetailTag
{
    kTagBackground       = 16,
    kTagScrollView       = 14,
    kTagTitleBar         = 11,
    kTagTitle            =  3,
    kTagContentView      =  2,
    kTagIcon             =  5,
    kTagIconActivity     =  6,
    kTagColorTimer       =  7,
    kTagTextTimer        =  8,
    kTagTextTime         =  9,
    kTagMap              = 10,
    kTagCompanyName      = 12,
    kTagCompanyAddress   = 13,
    kTagDetails          =  4,
    kTagBarcodeView      =  1,
    kTagBarcodeCodeView  = 15,
    kTagBarcodeSlideView = 17,
};

enum ActionButton
{
    kActionButtonSMS   = 0,
    kActionButtonEmail = 1,
};

enum CouponState
{
    kStateDefault = 0,
    kStateActive  = 1,
    kStateExpired = 2,
};

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface CouponDetailViewController ()
    - (void) addShadows;
    - (void) setupToolbar;
    - (void) setupCouponDetails;
    - (void) setupIcon;
    - (void) setIcon:(UIImage*)image;
    - (void) setupMap;
    - (void) expireCoupon;
    - (void) startTimer;
    - (void) updateTimers;
    - (void) shareSMS;
    - (void) shareEmail;
    - (void) setupTwitter;
    - (void) tweetDealOnTwitter;
    - (void) setupFacebook;
    - (void) postDealToFacebook;
    - (void) openMap;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation CouponDetailViewController

//------------------------------------------------------------------------------

@synthesize coupon       = mCoupon;
@synthesize timer        = mTimer;
@synthesize barcodeView  = mBarcodeView;

//------------------------------------------------------------------------------
#pragma - View Lifecycle
//------------------------------------------------------------------------------

/**
 * The designated initializer.  Override if you create the controller 
 * programmatically and want to perform customization that is not appropriate 
 * for viewDidLoad.
 */
- (id) initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil 
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

//------------------------------------------------------------------------------

/**
 * Implement viewDidLoad to do additional setup after loading the view, 
 * typically from a nib.
 */
- (void) viewDidLoad 
{
    [super viewDidLoad];

    // set title 
    self.title = @"Deal";

    // tag testflight checkpoint
    [Analytics passCheckpoint:@"Deal"];

    // setup toolbar
    [self setupToolbar];

    // add nice little shadow details
    [self addShadows];

    // [iOS4] fix for missing font bradley hand bold
    UILabel *address = (UILabel*)[self.view viewWithTag:kTagCompanyAddress];
    UITextView *text = (UITextView*)[self.view viewWithTag:kTagDetails];
    if (address.font == nil) {
        address.font = [UIFont fontWithName:@"HelveticaNeueMedium" size:13];
        text.font    = [UIFont fontWithName:@"HelveticaNeueLight" size:14];
    }

    // correct font on timer
    UILabel *timer = (UILabel*)[self.view viewWithTag:kTagTextTimer];
    timer.font     = [UIFont fontWithName:@"NeutraDisp-BoldAlt" size:20];

    // correct font on barcode
    UIButton *barcode       = (UIButton*)[self.barcodeView viewWithTag:kTagBarcodeCodeView];
    barcode.titleLabel.font = [UIFont fontWithName:@"UnitedSansReg-Bold" size:17];
    barcode.titleLabel.adjustsFontSizeToFitWidth = YES;

    // setup gesture recogizer on map
    MKMapView *map = (MKMapView*)[self.view viewWithTag:kTagMap];
    UITapGestureRecognizer* mapTap = 
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openMap)];
    [map setUserInteractionEnabled:YES];
    [map addGestureRecognizer:mapTap];
    [mapTap release];
}

//------------------------------------------------------------------------------

- (void) viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];

    // update the ui with the coupon details
    [self setupCouponDetails];

    // table enumeration view positions for various states
    static struct YTable {
        NSUInteger cs;
        CGFloat    h;
    } sYTable[3] = {
        { kStateDefault , -120.0 },
        { kStateActive  ,  -60.0 },
        { kStateExpired ,    0.0 },
    };

    // get the coupon state
    NSUInteger state = kStateDefault;
    state            = self.coupon.wasRedeemed.boolValue ? kStateActive : state;

    // position the view accordingly
    UIView *view   = [self.barcodeView viewWithTag:kTagBarcodeSlideView];
    CGRect frame   = view.frame;
    frame.origin.y = sYTable[state].h;
    view.frame     = frame;

    // show the toolbar
    [self.navigationController setToolbarHidden:NO animated:YES];

    // setup an update loop to for the color/text timers
    if (!self.coupon.isExpired) {
        [self startTimer];
    } else {
        [self expireCoupon];
    }
}

//------------------------------------------------------------------------------

/*
- (void) viewDidAppear:(BOOL)animated 
{
    [super viewDidAppear:animated];
}
*/

//------------------------------------------------------------------------------

- (void) viewWillDisappear:(BOOL)animated 
{
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:YES];

    // stop timer 
    [self.timer invalidate];
}

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
#pragma - Properties
//------------------------------------------------------------------------------

- (void) setCoupon:(Coupon*)coupon
{
    if (mCoupon) [mCoupon release];
    mCoupon = [coupon retain];
    [self setupCouponDetails];

    // fix up scroll view to account for text view content
    UIScrollView *scrollView = (UIScrollView*)[self.view viewWithTag:kTagScrollView];
    UITextView *textView     = (UITextView*)[self.view viewWithTag:kTagDetails];
    CGSize contentSize       = scrollView.contentSize;
    contentSize.height       = textView.frame.origin.y + textView.contentSize.height + 60;
    scrollView.contentSize   = contentSize;
}

//------------------------------------------------------------------------------
#pragma - Setup
//------------------------------------------------------------------------------

- (void) addShadows
{
    // map view
    UIView *titleView             = [self.view viewWithTag:15];
    titleView.layer.shadowColor   = [[UIColor blackColor] CGColor];
    titleView.layer.shadowOffset  = CGSizeMake(2.0f, 2.0f);
    titleView.layer.shadowOpacity = 0.2f;

    // map view
    UIView *mapView             = [[self.view viewWithTag:kTagMap] superview];
    mapView.layer.shadowColor   = [[UIColor blackColor] CGColor];
    mapView.layer.shadowOffset  = CGSizeMake(2.0f, 2.0f);
    mapView.layer.shadowOpacity = 0.2f;
}

//------------------------------------------------------------------------------

- (void) setupToolbar
{
    // create a flexible spacer
    UIBarButtonItem *flexibleSpaceButton = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                             target:nil 
                             action:nil];

    // create a bar button
    UIBarButtonItem *barButtonItem = 
        [[UIBarButtonItem alloc] initWithCustomView:self.barcodeView];
     
    // set the items in the toolbar
    self.toolbarItems = $array(
        flexibleSpaceButton, 
        barButtonItem,
        flexibleSpaceButton);

    // cleanup 
    [flexibleSpaceButton release];
    [barButtonItem release];

    // show the toolbar
}

//------------------------------------------------------------------------------

- (void) setupCouponDetails
{
    // title
    UITextView *title = (UITextView*)[self.view viewWithTag:kTagTitle];
    title.text        = [self.coupon.title capitalizedString];

    // details
    UITextView *details = (UITextView*)[self.view viewWithTag:kTagDetails];
    details.text        = self.coupon.details;

    // icon
    [self setupIcon];

    // map
    [self setupMap];
    
    // merchant name
    UILabel *name = (UILabel*)[self.view viewWithTag:kTagCompanyName];
    name.text     = [self.coupon.merchant.name uppercaseString];

    // merchant address
    UILabel *address = (UILabel*)[self.view viewWithTag:kTagCompanyAddress];
    address.text     = self.coupon.merchant.address;
    
    // color timer
    GradientView *color = (GradientView*)[self.view viewWithTag:kTagColorTimer];
    color.color         = [self.coupon getColor];

    // text timer
    UILabel *label = (UILabel*)[self.view viewWithTag:kTagTextTimer];
    label.text     = [self.coupon getExpirationTimer];

    // barcode code
    UIButton *code       = (UIButton*)[self.barcodeView viewWithTag:kTagBarcodeCodeView];
    code.titleLabel.text = self.coupon.barcode;
}

//------------------------------------------------------------------------------

- (void) setupIcon
{
    IconManager *iconManager = [IconManager getInstance];
    __block UIImage *image   = [iconManager getImage:self.coupon.iconData];

    // set merchant icon
    [self setIcon:image];

    // load image from server if not available
    if (!image) {
        [iconManager requestImage:self.coupon.iconData 
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

- (void) setupMap
{
    // center map 
    CLLocationCoordinate2D coordinate;
    coordinate.latitude  = [self.coupon.merchant.latitude doubleValue];
    coordinate.longitude = [self.coupon.merchant.longitude doubleValue];
    MKMapView *map       = (MKMapView*)[self.view viewWithTag:kTagMap];
    map.centerCoordinate = coordinate;

    // set zoom
    MKCoordinateRegion viewRegion =
        MKCoordinateRegionMakeWithDistance(coordinate, 100, 100);
    MKCoordinateRegion adjustedRegion = [map regionThatFits:viewRegion];                
    [map setRegion:adjustedRegion animated:NO]; 

    // add pin 
    MKPointAnnotation *pin = [[MKPointAnnotation alloc] init];
    pin.coordinate         = coordinate;
    [map addAnnotation:pin];
    [pin release];
}

//------------------------------------------------------------------------------

- (void) startTimer
{
    // setup timer
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(updateTimers)
                                                userInfo:nil
                                                 repeats:YES];
}

//------------------------------------------------------------------------------

- (void) updateTimers
{
    // color timer
    GradientView *color = (GradientView*)[self.view viewWithTag:kTagColorTimer];
    color.color         = [self.coupon getColor];

    // text timer
    UILabel *label = (UILabel*)[self.view viewWithTag:kTagTextTimer];
    label.text     = [self.coupon getExpirationTimer];

    // kill timer if coupon is expired
    if ([self.coupon isExpired]) {
        [self.timer invalidate];
        [UIView animateWithDuration:0.25 animations:^{
            [self expireCoupon];
        }];
    }
}

//------------------------------------------------------------------------------
#pragma - Events
//------------------------------------------------------------------------------

- (IBAction) merchantDetails:(id)sender
{
    MerchantViewController *controller = [[MerchantViewController alloc] 
        initWithNibName:@"MerchantViewController" bundle:nil];

    // set merchant to view
    controller.merchant = self.coupon.merchant;

    // pass the selected object to the new view controller.
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

//------------------------------------------------------------------------------

- (IBAction) redeemCoupon:(id)sender
{
    self.coupon.wasRedeemed = $numb(YES);

    // animate barcode
    [UIView animateWithDuration:0.3 animations:^{
        UIView *view    = [self.barcodeView viewWithTag:kTagBarcodeSlideView];
        CGRect frame    = view.frame;
        frame.origin.y += 60.0;
        view.frame      = frame;
    }];

    // let server know of redemption
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    [api updateCoupon:self.coupon.couponId attribute:kTikTokApiCouponAttributeRedeem];
}

//------------------------------------------------------------------------------

- (void) openMap
{
    [Analytics passCheckpoint:@"Deal Map Opened"];

    LocationMapViewController *controller = [[LocationMapViewController alloc] 
        initWithNibName:@"LocationMapViewController" bundle:nil];

    // set merchant to view
    controller.coupon = self.coupon;

    // pass the selected object to the new view controller.
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

//------------------------------------------------------------------------------

- (void) expireCoupon
{
    [Analytics passCheckpoint:@"Deal Expired"];

    // update the timer label
    UILabel *label = (UILabel*)[self.view viewWithTag:kTagTextTimer];
    label.text     = @"TIMES UP!";

    // update the opacity for all the coupons
    for (UIView *view in self.view.subviews) {
        if (view.tag != kTagBackground) {
            view.alpha = 0.6;
        } 
    }

    // animate barcode
    if (!self.coupon.wasRedeemed.boolValue) {
        UIView *view   = [self.barcodeView viewWithTag:kTagBarcodeSlideView];
        CGRect frame   = view.frame;
        frame.origin.y = 0.0;
        view.frame     = frame;
    }
}

//------------------------------------------------------------------------------
#pragma mark - Events
//------------------------------------------------------------------------------

- (void) shareTwitter
{
    // tweet deal if twitter setup, else request account setup
    if ([TWTweetComposeViewController canSendTweet]) {
        [self tweetDealOnTwitter];
    } else {
        [self setupTwitter];
    }
}

//------------------------------------------------------------------------------

- (IBAction) shareTwitter:(id)sender
{
    // open up settings to configure twitter account
    UIAlertViewSelectionHandler handler = ^(NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            [self performSelector:@selector(shareTwitter) withObject:nil afterDelay:0.05];
        }
    };

    // display alert
    NSString *title    = @"Hey You!";
    NSString *message  = @"Please only tweet for testing! If you tweet please delete it or make it private. Thanks!";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                withHandler:handler
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Tweet", nil];
    [alert show];
    [alert release];
}

//------------------------------------------------------------------------------

- (void) shareFacebook
{
    // post deal if logged on, else request connect first 
    FacebookManager *manager = [FacebookManager getInstance];
    if ([manager.facebook isSessionValid]) {
        [self postDealToFacebook];
    } else {
        [self setupFacebook];
    }
}

//------------------------------------------------------------------------------

- (IBAction) shareFacebook:(id)sender
{
    // open up settings to configure twitter account
    UIAlertViewSelectionHandler handler = ^(NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            [self performSelector:@selector(shareFacebook) withObject:nil afterDelay:0.5];
        }
    };

    // display alert
    NSString *title    = @"Hey You!";
    NSString *message  = @"Please only post to facebook for testing! If you post please delete it or make it private. Thanks!";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                withHandler:handler
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Post", nil];
    [alert show];
    [alert release];
}

//------------------------------------------------------------------------------

- (IBAction) shareMore:(id)sender
{
    // setup action sheet handler
    UIActionSheetSelectionHandler handler = ^(NSInteger buttonIndex) {
        switch (buttonIndex) {
            case kActionButtonSMS:
                [self shareSMS];
                break;
            case kActionButtonEmail:
                [self shareEmail];
                break;
            default:
                break;
        }
    };

    // setup action sheet
    UIActionSheet *actionSheet = 
        [[UIActionSheet alloc] initWithTitle:@"Share Deal"
                                 withHandler:handler 
                           cancelButtonTitle:@"Cancel" 
                      destructiveButtonTitle:nil
                           otherButtonTitles:@"SMS", @"Email", nil];

    // show from toolbar only if coupon not yet redeemed
    if (self.coupon.wasRedeemed.boolValue || self.coupon.isExpired) {
        [actionSheet showFromToolbar:self.navigationController.toolbar];
    } 

    // cleanup
    [actionSheet release];
}

//------------------------------------------------------------------------------

- (void) shareEmail
{
    // only send email if supported by the device
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *controller = 
            [[MFMailComposeViewController alloc] init];

        // present the email controller
        NSString *deal = $string(@"%@ at %@", self.coupon.title, self.coupon.merchant.name);
        [controller setSubject:@"Checkout this amazing deal on TikTok!"];
        [controller setMessageBody:$string(@"%@", deal) isHTML:NO];

        // setup completion handler
        controller.completionHandler = ^(MFMailComposeViewController* controller,
                                         MFMailComposeResult result,
                                         NSError* error) {
            switch (result) {
                case MFMailComposeResultSaved:
                    break;
                case MFMailComposeResultSent: {
                    [Analytics passCheckpoint:@"Deal Emailed"];
                    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
                    [api updateCoupon:self.coupon.couponId attribute:kTikTokApiCouponAttributeEmail];
                    break;
                }
                case MFMailComposeResultFailed:
                    NSLog(@"CouonDetailViewController: email failed: %@", error);
                    break;
                default:
                    break;
            }

            // dismiss controller
            [self dismissModalViewControllerAnimated:YES];
        };

        // present controller
        [self presentModalViewController:controller animated:YES];

        // cleanup
        [controller release];

    // let user know email is not possible on this device
    } else {
        NSString *title   = NSLocalizedString(@"DEVICE_SUPPORT", nil);
        NSString *message = NSLocalizedString(@"EMAIL_NO_SUPPORTED", nil);
        [Utilities displaySimpleAlertWithTitle:title andMessage:message];
    }
}

//------------------------------------------------------------------------------

- (void) shareSMS
{
    // only send text if supported by the device
    if ([MFMessageComposeViewController canSendText]) {
        MFMessageComposeViewController *controller = 
            [[MFMessageComposeViewController alloc] init];

        // present sms controller
        NSString *deal  = $string(@"%@ at %@", self.coupon.title, self.coupon.merchant.name);
        controller.body = $string(@"Checkout this amazing deal on TikTok: %@!", deal);
        controller.completionHandler = ^(MFMessageComposeViewController* controller,
                                         MessageComposeResult result) {
            switch (result) {
                case MessageComposeResultSent: {
                    [Analytics passCheckpoint:@"Deal SMSed"];
                    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
                    [api updateCoupon:self.coupon.couponId attribute:kTikTokApiCouponAttributeSMS];
                    break;
                }
                case MessageComposeResultFailed:
                    NSLog(@"CouonDetailViewController: sms failed.");
                    break;
                default:
                    break;
            }

            // dismiss controller
            [self dismissModalViewControllerAnimated:YES];
        };

        [self presentModalViewController:controller animated:YES];

        // cleanup
        [controller release];

    // let user know sms is not possible on this device...   
    } else {
        NSString *title   = NSLocalizedString(@"DEVICE_SUPPORT", nil);
        NSString *message = NSLocalizedString(@"SMS_NO_SUPPORTED", nil);
        [Utilities displaySimpleAlertWithTitle:title
                                    andMessage:message];
    }
}

//------------------------------------------------------------------------------
#pragma - Sharing
//------------------------------------------------------------------------------

- (void) setupTwitter
{
    NSString *title   = NSLocalizedString(@"TWITTER_SUPPORT", nil);
    NSString *message = NSLocalizedString(@"TWITTER_NOT_SETUP", nil);

    // open up settings to configure twitter account
    UIAlertViewSelectionHandler handler = ^(NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            UIApplication *application = [UIApplication sharedApplication];
            [application openURL:[NSURL URLWithString:@"prefs:root=TWITTER"]];
        }
    };

    // display alert
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                withHandler:handler
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Settings", nil];
    [alert show];
    [alert release];
}

//------------------------------------------------------------------------------

- (void) tweetDealOnTwitter
{
    TWTweetComposeViewController *twitter = [[TWTweetComposeViewController alloc] init];

    // grab icon from view
    UIImageView *icon = (UIImageView*)[self.view viewWithTag:kTagIcon];                

    // setup twitter controller
    NSString *deal = $string(@"%@ at %@!", self.coupon.title, self.coupon.merchant.name);
    [twitter setInitialText:deal];
    [twitter addImage:icon.image];

    // setup completion handler
    twitter.completionHandler = ^(TWTweetComposeViewControllerResult result) {
        switch (result) {
            case TWTweetComposeViewControllerResultCancelled:
                break;
            case TWTweetComposeViewControllerResultDone: {
                [Analytics passCheckpoint:@"Deal Tweeted"];

                // let server know of share
                TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
                [api updateCoupon:self.coupon.couponId attribute:kTikTokApiCouponAttributeTwitter];

                // alert user of successful tweet
                NSString *title   = NSLocalizedString(@"TWITTER", nil);
                NSString *message = NSLocalizedString(@"TWITTER_DEAL_POST", nil);
                [Utilities displaySimpleAlertWithTitle:title
                                            andMessage:message];
                break;
            }
        }

        // dismiss the controller
        [self dismissModalViewControllerAnimated:YES];
    };

    // display controller
    [self presentModalViewController:twitter animated:YES];

    // cleanup
    [twitter release];
}

//------------------------------------------------------------------------------

- (void) setupFacebook
{
    NSString *title   = NSLocalizedString(@"FACEBOOK_SUPPORT", nil);
    NSString *message = NSLocalizedString(@"FACEBOOK_NOT_SETUP", nil);

    // open up settings to configure twitter account
    UIAlertViewSelectionHandler handler = ^(NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            FacebookManager *manager = [FacebookManager getInstance];
            [manager authorizeWithSucessHandler:^{
                [self postDealToFacebook];
            }];
        }
    };

    // display alert
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                withHandler:handler
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"Facebook", nil];
    [alert show];
    [alert release];
}

//------------------------------------------------------------------------------

- (void) postDealToFacebook
{
    [Analytics passCheckpoint:@"Deal Facebooked"];

    NSString *deal = $string(@"%@ at %@!", self.coupon.title, self.coupon.merchant.name);
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        @"www.tiktok.com",   @"link",
        self.coupon.iconUrl, @"picture",
        @"TikTok",           @"name",
        @"www.tiktok.com",   @"caption",
        deal,                @"description",
        nil];


    // post share on facebook
    FacebookManager *manager = [FacebookManager getInstance];
    [manager.facebook dialog:@"feed" andParams:params andDelegate:self];
}

//------------------------------------------------------------------------------

- (void) request:(FBRequest*)request didLoad:(id)result
{
    // let server know of share
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    [api updateCoupon:self.coupon.couponId attribute:kTikTokApiCouponAttributeFacebook];

    // alert user of successful facebook post
    NSString *title   = NSLocalizedString(@"FACEBOOK", nil);
    NSString *message = NSLocalizedString(@"FACEBOOK_DEAL_POST", nil);
    [Utilities displaySimpleAlertWithTitle:title
                                andMessage:message];

    NSLog(@"CouponDetailViewController: facebook request did load: %@", result);
}

//------------------------------------------------------------------------------

- (void) request:(FBRequest*)request didFailWithError:(NSError*)error
{
    NSLog(@"CouponDetailViewController: Facebook share failed: %@", error);
}

//------------------------------------------------------------------------------
#pragma - Facebook delegate
//------------------------------------------------------------------------------

- (BOOL) dialog:(FBDialog*)dialog shouldOpenURLInExternalBrowser:(NSURL*)url
{
    return NO;
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
    [mTimer invalidate];
    [mBarcodeView release];
    [mCoupon release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
