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
#import "Database.h"
#import "FacebookManager.h"
#import "GradientView.h"
#import "IconManager.h"
#import "JsonPickerViewController.h"
#import "Location.h"
#import "LocationMapViewController.h"
#import "LocationTracker.h"
#import "Merchant.h"
#import "MerchantPinViewController.h"
#import "MerchantViewController.h"
#import "Settings.h"
#import "SVProgressHUD.h"
#import "TikTokApi.h"
#import "UIDefaults.h"
#import "Utilities.h"
#import "WebViewController.h"

//------------------------------------------------------------------------------
// enums
//------------------------------------------------------------------------------

enum CouponDetailTag
{
    kTagBackground         = 16,
    kTagScrollView         = 14,
    kTagTitleBar           = 11,
    kTagTitle              =  3,
    kTagContentView        =  2,
    kTagIcon               =  5,
    kTagIconActivity       =  6,
    kTagColorTimer         =  7,
    kTagTextTimer          =  8,
    kTagTextTime           =  9,
    kTagMap                = 10,
    kTagCompanyName        = 12,
    kTagCompanyAddress     = 13,
    kTagDetails            =  4,
    kTagBarcodeView        =  1,
    kTagBarcodeCodeView    = 15,
    kTagBarcodeSlideView   = 17,
    kTagBarcodeRedeem      = 18,
    kTagBarcodeRedeemEmpty = 19,
    kTagBarcodeActivity    = 20,
    kTagBarcodeRedeemed    = 21,
    kTagWhiteBackground    = 22,
};

enum ActionButtonShare
{
    kActionButtonSMS   = 0,
    kActionButtonEmail = 1,
};

enum ActionButtonShareDeal
{
    kActionButtonFacebook    = 0,
    kActionButtonAddressBook = 1,
};

typedef enum _CouponState
{
    kStateDefault = 0,
    kStateActive  = 1,
    kStateExpired = 2,
    kStateSoldOut = 3,
    kStateInfo    = 4,
} CouponState;

//------------------------------------------------------------------------------
// statics
//------------------------------------------------------------------------------

static NSUInteger sObservationContext;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface CouponDetailViewController ()
    - (void) addShadows;
    - (void) setupNavButtons;
    - (void) setupToolbar;
    - (void) setupCouponDetails;
    - (void) setupIcon;
    - (void) setIcon:(UIImage*)image;
    - (void) setupMap:(Location*)location;
    - (void) setupGestureRecognizers;
    - (void) expireCoupon;
    - (void) sellOutCoupon;
    - (void) startTimer;
    - (void) updateTimers;
    - (void) shareDeal:(id)sender;
    - (void) shareDealFacebook;
    - (void) shareDealAddressBook;
    - (void) shareSMS;
    - (void) shareEmail;
    - (void) setupTwitter;
    - (void) tweetDealOnTwitter;
    - (void) setupFacebook;
    - (void) postDealToFacebook;
    - (UIImage*) imageForIcon:(UIImage*)icon;
    - (void) openMap;
    - (void) onCouponDeleted:(NSNotification*)notification;
    - (CouponState) getCouponState:(Coupon*)coupon;
    - (void) addSoldOutObserver;
    - (void) removeSoldOutObserver;
    - (void) startRedeemedActivity;
    - (void) endRedeemedActivity:(bool)redeemed;
    - (void) selectFacebookFriend:(NSArray*)friends;
    - (void) confirmShareDealWithFriend:(NSDictionary*)friend;
    - (void) shareDealWithFriend:(NSDictionary*)friend;
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

    // [moiz] contains share deal workflow
    /* setup nar bar
    [self setupNavButtons];
    */

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

    // correct font and selectablility on barcode
    UIButton *barcode       = (UIButton*)[self.barcodeView viewWithTag:kTagBarcodeCodeView];
    barcode.titleLabel.font = [UIFont fontWithName:@"UnitedSansReg-Bold" size:28];
    barcode.titleLabel.adjustsFontSizeToFitWidth = YES;
    barcode.userInteractionEnabled = self.coupon.merchant.usesPin.boolValue;

    // setup gesture recogizer on map
    [self setupGestureRecognizers];

    // watch for deletions
    Database *database = [Database getInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onCouponDeleted:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:database.context];
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
    } sYTable[5] = {
        { kStateDefault , -120.0 },
        { kStateActive  ,  -60.0 },
        { kStateExpired ,    0.0 },
        { kStateSoldOut ,   60.0 },
        { kStateInfo    ,  120.0 },
    };

    // get the coupon state
    // position the view accordingly
    CouponState state = [self getCouponState:self.coupon];
    UIView *view      = [self.barcodeView viewWithTag:kTagBarcodeSlideView];
    CGRect frame      = view.frame;
    frame.origin.y    = sYTable[state].h;
    view.frame        = frame;

    // show the toolbar
    [self.navigationController setToolbarHidden:NO animated:YES];

    // setup an update loop to for the color/text timers
    if (!self.coupon.isExpired) {
        [self startTimer];
        [self addSoldOutObserver];
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

    // cleanup notifications
    [self removeSoldOutObserver];
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

- (void) observeValueForKeyPath:(NSString*)keyPath
                       ofObject:(id)object
                         change:(NSDictionary*)change
                        context:(void*)context
{
    if (&sObservationContext != context) return;

    // only listen to sold out
    if (![keyPath isEqualToString:@"isSoldOut"]) return;

    // get new value and animate view if required
    NSNumber *isSoldOut = [change objectForKey:NSKeyValueChangeNewKey];
    Coupon *coupon      = (Coupon*)object;
    CouponState state   = [self getCouponState:coupon];
    if ((self.coupon == coupon) && (state == kStateSoldOut) && isSoldOut.boolValue) {
        [UIView animateWithDuration:0.25 animations:^{
            [self sellOutCoupon];
            [self removeSoldOutObserver];
        }];
    }
}

//------------------------------------------------------------------------------
#pragma - Properties
//------------------------------------------------------------------------------

- (void) setupGestureRecognizers
{
    // setup touch for map
    UIView *map = [self.view viewWithTag:kTagMap];
    UITapGestureRecognizer* mapTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openMap)];
    [map setUserInteractionEnabled:YES];
    [map addGestureRecognizer:mapTap];
    [mapTap release];

    // setup touch for merchant pin
    if (self.coupon.merchant.usesPin.boolValue) {
        UIView *banner = [self.barcodeView viewWithTag:kTagBarcodeRedeemed];
        UITapGestureRecognizer* bannerTap =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(validateMerchantPin:)];
        [banner setUserInteractionEnabled:YES];
        [banner addGestureRecognizer:bannerTap];
        [bannerTap release];
    }
}

//------------------------------------------------------------------------------

- (void) setCoupon:(Coupon*)coupon
{
    if (mCoupon) [mCoupon release];
    mCoupon = [coupon retain];
    [self setupCouponDetails];

    // fix up scroll view to account for text view content
    UIScrollView *scrollView   = (UIScrollView*)[self.view viewWithTag:kTagScrollView];
    UITextView *textView       = (UITextView*)[self.view viewWithTag:kTagDetails];
    UIView *contentView        = [self.view viewWithTag:kTagContentView];
    CGRect contentFrame        = contentView.frame;
    CGRect textFrame           = textView.frame;
    CGSize contentSize         = scrollView.contentSize;
    contentSize.height         = contentFrame.origin.y   +
                                 textView.frame.origin.y +
                                 textView.contentSize.height;
    scrollView.contentSize     = contentSize;

    // update the height of the textview to match the content
    textFrame.size.height = contentSize.height;
    textView.frame        = textFrame;

    // update the height of the content view
    contentFrame.size.height = contentSize.height;
    contentView.frame        = contentFrame;
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

- (void) setupNavButtons
{
    // share app button
    UIBarButtonItem *shareButton =
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"24-gift-bar.png"]
                                         style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(shareDeal:)];

    // add to navbar
    self.navigationItem.rightBarButtonItem = shareButton;

    // cleanup
    [shareButton release];
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
}

//------------------------------------------------------------------------------

- (void) setupCouponDetails
{
    // get closest location
    CLLocation* currentLocation = [LocationTracker currentLocation];
    Location* location =
        [self.coupon getClosestLocationToCoordinate:currentLocation.coordinate];

    // title
    UITextView *title = (UITextView*)[self.view viewWithTag:kTagTitle];
    title.text        = [self.coupon getTitleWithFormatting];

    // details
    UITextView *details = (UITextView*)[self.view viewWithTag:kTagDetails];
    details.text        = [self.coupon getDetailsWithTerms];

    // icon
    [self setupIcon];

    // map
    [self setupMap:location];

    // merchant name
    UILabel *name = (UILabel*)[self.view viewWithTag:kTagCompanyName];
    name.text     = [self.coupon.merchant.name uppercaseString];

    // merchant address
    UILabel *address = (UILabel*)[self.view viewWithTag:kTagCompanyAddress];
    address.text     = self.coupon.locations.count == 1 ?
        location.address :
        $string(@"Available at %d Locations.", self.coupon.locations.count);

    // color timer
    GradientView *color = (GradientView*)[self.view viewWithTag:kTagColorTimer];
    color.color         = [self.coupon getColor];

    // text timer
    UILabel *label = (UILabel*)[self.view viewWithTag:kTagTextTimer];
    label.text     = [self.coupon getExpirationTimer];

    // barcode code
    UIButton *code = (UIButton*)[self.barcodeView viewWithTag:kTagBarcodeCodeView];
    [code setTitle:self.coupon.barcode forState:UIControlStateNormal];
    [code setTitle:self.coupon.barcode forState:UIControlStateSelected];
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
                    NSLog(@"CouponDetailViewController: Failed to load image, %@", error);
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

- (void) setupMap:(Location*)location
{
    // center map
    CLLocationCoordinate2D coordinate;
    coordinate.latitude  = [location.latitude doubleValue];
    coordinate.longitude = [location.longitude doubleValue];
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
    controller.coupon    = self.coupon;
    controller.locations = [self.coupon.locations allObjects];

    // pass the selected object to the new view controller.
    [self.navigationController pushViewController:controller animated:YES];
    [controller release];
}

//------------------------------------------------------------------------------

- (IBAction) redeemCoupon:(id)sender
{
    // show redeeming activity
    [UIView animateWithDuration:0.3 animations:^{
        [self startRedeemedActivity];
    }
    completion:^(BOOL complete) {

        // let server know of redemption
        TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
        api.completionHandler = ^(NSDictionary *response) {

            // parse out registration status
            NSString *status = [response objectForComplexKey:kTikTokApiKeyStatus@".redeem"];
            if ([status isEqualToString:kTikTokApiStatusOkay]) {
                [self endRedeemedActivity:true];
                self.coupon.wasRedeemed = $numb(YES);

            // alert the user of a problem
            } else if ([status isEqualToString:kTikTokApiStatusForbidden]) {
                [self endRedeemedActivity:false];
                NSString *title   = NSLocalizedString(@"REDEEM", nil);
                NSString *message = [response objectForComplexKey:kTikTokApiKeyError@".redeem"];
                [Utilities displaySimpleAlertWithTitle:title andMessage:message];

                // sync up coupons
                Settings *settings = [Settings getInstance];
                [[[[TikTokApi alloc] init] autorelease] syncActiveCoupons:settings.lastUpdate];
            }
        };

        // alert the user of error
        api.errorHandler = ^(ASIHTTPRequest* request) {
            [self endRedeemedActivity:false];
            NSString *title   = NSLocalizedString(@"REDEEM", nil);
            NSString *message = NSLocalizedString(@"REDEEM_NETWORK_ERROR", nil);
            [Utilities displaySimpleAlertWithTitle:title andMessage:message];
        };

        // run api
        [api updateCoupon:self.coupon.couponId attribute:kTikTokApiCouponAttributeRedeem];
    }];
}

//------------------------------------------------------------------------------

- (UIImage*) imageForIcon:(UIImage*)icon
{
    // create a gradient view for the background
    CGRect gradientFrame       = CGRectMake(0.0, 0.0, 128.0, 128.0);
    GradientView *gradientView = [[GradientView alloc] initWithFrame:gradientFrame];
    gradientView.color         = [UIDefaults getTikColor];

    // add the icon to the center
    CGRect iconFrame      = CGRectMake(8.0, 8.0, 112.0, 112.0);
    UIImageView *iconView = [[UIImageView alloc] initWithFrame:iconFrame];
    iconView.contentMode  = UIViewContentModeScaleAspectFit;
    iconView.image        = icon;
    [gradientView addSubview:iconView];

    // render the image
    UIImage *image = [UIImage imageFromView:gradientView];

    // cleanup
    [iconView release];
    [gradientView release];

    return image;
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
    label.text     = @"TIME'S UP!";

    // update the opacity for all the coupons
    [[self.view viewWithTag:kTagTitle] setAlpha:0.6];
    UIView *contentView = [self.view viewWithTag:kTagContentView];
    for (UIView *view in contentView.subviews) {
        if (view.tag != kTagWhiteBackground) {
            view.alpha = 0.6;
        }
    }

    // animate banner
    if (!self.coupon.wasRedeemed.boolValue && self.coupon.isRedeemable.boolValue) {
        UIView *view   = [self.barcodeView viewWithTag:kTagBarcodeSlideView];
        CGRect frame   = view.frame;
        frame.origin.y = 0.0;
        view.frame     = frame;
    }
}

//------------------------------------------------------------------------------

- (void) sellOutCoupon
{
    if (self.coupon.isSoldOut.boolValue) {
        UIView *view   = [self.barcodeView viewWithTag:kTagBarcodeSlideView];
        CGRect frame   = view.frame;
        frame.origin.y = 60.0;
        view.frame     = frame;
    }
}

//------------------------------------------------------------------------------

- (void) onCouponDeleted:(NSNotification*)notification
{
    // pop to the root controller
    NSArray *killedCoupons = [notification.userInfo objectForKey:NSDeletedObjectsKey];
    for (Coupon *killedCoupon in killedCoupons) {
        if (self.coupon == killedCoupon) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }
}

//------------------------------------------------------------------------------

- (CouponState) getCouponState:(Coupon*)coupon
{
    NSUInteger state = kStateDefault;
    state            = coupon.isSoldOut.boolValue ? kStateSoldOut : state;
    state            = coupon.isExpired ? kStateExpired : state;
    state            = coupon.wasRedeemed.boolValue ? kStateActive : state;
    state            = !coupon.isRedeemable.boolValue ? kStateInfo : state;
    return state;
}

//------------------------------------------------------------------------------

- (void) addSoldOutObserver
{
    mHasObserver      = false;
    CouponState state = [self getCouponState:self.coupon];

    // only add observer if coupon can be sold out
    if (state == kStateDefault) {
        mHasObserver = true;
        [self.coupon addObserver:self
                      forKeyPath:@"isSoldOut"
                         options:NSKeyValueObservingOptionNew
                         context:&sObservationContext];
    }
}

//------------------------------------------------------------------------------

- (void) removeSoldOutObserver
{
    // only remove observer if we are still listening
    if (mHasObserver) {
        mHasObserver = false;

        // [iOS4] fix for newer function
        if ($has_selector(self.coupon, removeObserver:forKeyPath:context:)) {
            [self.coupon removeObserver:self
                             forKeyPath:@"isSoldOut"
                                context:&sObservationContext];
        } else {
            [self.coupon removeObserver:self
                             forKeyPath:@"isSoldOut"];
        }
    }
}

//------------------------------------------------------------------------------

- (void) startRedeemedActivity
{
    UIImageView *empty               = (UIImageView*)[self.barcodeView viewWithTag:kTagBarcodeRedeemEmpty];
    UIImageView *redeem              = (UIImageView*)[self.barcodeView viewWithTag:kTagBarcodeRedeem];
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)[self.barcodeView viewWithTag:kTagBarcodeActivity];
    empty.hidden                     = NO;
    empty.alpha                      = 1.0;
    redeem.alpha                     = 0.0;
    [spinner startAnimating];
}

//------------------------------------------------------------------------------

- (void) endRedeemedActivity:(bool)redeemed
{
    UIImageView *empty               = (UIImageView*)[self.barcodeView viewWithTag:kTagBarcodeRedeemEmpty];
    UIImageView *redeem              = (UIImageView*)[self.barcodeView viewWithTag:kTagBarcodeRedeem];
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)[self.barcodeView viewWithTag:kTagBarcodeActivity];
    empty.hidden                     = YES;
    empty.alpha                      = 0.0;
    redeem.alpha                     = 1.0;
    [spinner stopAnimating];

    // animate to redeemed status
    if (redeemed) {
        [UIView animateWithDuration:0.3 animations:^{
            UIView *view    = [self.barcodeView viewWithTag:kTagBarcodeSlideView];
            CGRect frame    = view.frame;
            frame.origin.y += 60.0;
            view.frame      = frame;
        }];
    }
}

//------------------------------------------------------------------------------

- (void) selectFacebookFriend:(NSArray*)friends
{
    // make sure user has friends :P
    if (friends.count == 0) {
        NSString *title   = NSLocalizedString(@"SHARE_DEAL", nil);
        NSString *message = NSLocalizedString(@"SHARE_DEAL_FB_FRIENDLESS", nil);
        [Utilities displaySimpleAlertWithTitle:title andMessage:message];
        return;
    }

    // present facebook friends picker
    JsonPickerViewController *controller = [[JsonPickerViewController alloc] init];
    controller.titleKey         = @"name";
    controller.imageKey         = @"pic_small";
    controller.jsonData         = friends;
    controller.selectionHandler = ^(NSDictionary* friend) {
        [self confirmShareDealWithFriend:friend];
    };

    // [iOS4] fix for newer function
    if ($has_selector(self, presentViewController:animated:completion:)) {
        [self presentViewController:controller
                           animated:YES
                         completion:nil];
    } else {
        [self presentModalViewController:controller animated:YES];
    }

    // cleanup
    [controller release];
}

//------------------------------------------------------------------------------

- (void) confirmShareDealWithFriend:(NSDictionary*)friend
{
    NSString *title   = NSLocalizedString(@"SHARE_DEAL", nil);
    NSString *message = $string(
        NSLocalizedString(@"SHARE_DEAL_CONFIRM", nil),
        [friend objectForKey:@"name"]);

    // open up settings to configure twitter account
    UIAlertViewSelectionHandler handler = ^(NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            [self shareDealWithFriend:friend];
        }
    };

    // display alert
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                withHandler:handler
                                          cancelButtonTitle:@"No."
                                          otherButtonTitles:@"Yes Gift!", nil];
    [alert show];
    [alert release];
}

//------------------------------------------------------------------------------

- (void) shareDealWithFriend:(NSDictionary*)friend
{
    [Analytics passCheckpoint:@"Deal Gifted"];

    // delete the coupon from the database?
    Database *database = [Database getInstance];
    [database.context deleteObject:self.coupon];

    // close this view
    [self.navigationController popToRootViewControllerAnimated:YES];

    NSLog(@"Deal shared with friend: %@", friend);
}

//------------------------------------------------------------------------------
#pragma mark - Events
//------------------------------------------------------------------------------

- (IBAction) validateMerchantPin:(id)sender
{
    // nothing to do if merchant doesn't use pin validation
    if (!self.coupon.merchant.usesPin.boolValue) return;

    // present merchant pin controller
    MerchantPinViewController *controller = [[MerchantPinViewController alloc] init];
    controller.couponId = self.coupon.couponId;

    // [iOS4] fix for newer function
    if ($has_selector(self, presentViewController:animated:completion:)) {
        [self presentViewController:controller
                           animated:YES
                         completion:nil];
    } else {
        [self presentModalViewController:controller animated:YES];
    }

    // cleanup
    [controller release];
}

//------------------------------------------------------------------------------

- (void) shareDeal:(id)sender
{
    // setup action sheet handler
    UIActionSheetSelectionHandler handler = ^(NSInteger buttonIndex) {
        switch (buttonIndex) {
            case kActionButtonFacebook:
                [self shareDealFacebook];
                break;
            case kActionButtonAddressBook:
                [self shareDealAddressBook];
                break;
            default:
                break;
        }
    };

    // setup action sheet
    UIActionSheet *actionSheet =
        [[UIActionSheet alloc] initWithTitle:@"Give your TikTok deal to a friend!"
                                 withHandler:handler
                           cancelButtonTitle:@"Cancel"
                      destructiveButtonTitle:nil
                           otherButtonTitles:@"Facebook", @"Address Book", nil];

    // show from toolbar
    [actionSheet showFromToolbar:self.navigationController.toolbar];

    // cleanup
    [actionSheet release];
}

//------------------------------------------------------------------------------

- (void) shareDealFacebook
{
    // put up the hud
    [SVProgressHUD showWithStatus:@"Finding Friends..."
                         maskType:SVProgressHUDMaskTypeBlack
                 networkIndicator:YES];

    // on successful query, display friends picker controller
    FacebookQuerySuccessHandler successHandler = ^(id result) {
        [SVProgressHUD dismiss];
        NSArray *friends = (NSArray*)result;
        [self selectFacebookFriend:friends];
    };

    // on failure, alert user of error
    FacebookQuerySuccessHandler errorHandler = ^(NSError* error) {
        [SVProgressHUD dismiss];
        NSString *title   = NSLocalizedString(@"SHARE_DEAL", nil);
        NSString *message = NSLocalizedString(@"SHARE_DEAL_FB_FAIL", nil);
        [Utilities displaySimpleAlertWithTitle:title andMessage:message];
    };

    // run query
    FacebookManager *manager = [FacebookManager getInstance];
    [manager getAppFriends:successHandler handleError:errorHandler];
}

//------------------------------------------------------------------------------

- (void) shareDealAddressBook
{
}

//------------------------------------------------------------------------------

- (IBAction) shareTwitter:(id)sender
{
    // [iOS4] disable twitter, to much effort to add backwords compatibilty
    Class twitter = NSClassFromString(@"TWTweetComposeViewController");
     if (!twitter) {
        NSString *title   = NSLocalizedString(@"TWITTER", nil);
        NSString *message = NSLocalizedString(@"TWITTER_UPGRADE", nil);
        [Utilities displaySimpleAlertWithTitle:title andMessage:message];
        return;
     }

    // tweet deal if twitter setup, else request account setup
    if ([TWTweetComposeViewController canSendTweet]) {
        [self tweetDealOnTwitter];
    } else {
        [self setupTwitter];
    }
}

//------------------------------------------------------------------------------

- (IBAction) shareFacebook:(id)sender
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

    // show from toolbar
    [actionSheet showFromToolbar:self.navigationController.toolbar];

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
        NSString *merchant  = self.coupon.merchant.name;
        NSString *formatted = [self.coupon.title capitalizedString];
        [controller setSubject:$string(@"TikTok: Checkout this amazing deal for %@!", merchant)];
        NSString *deal      = $string(@"<h3>TikTok</h3>"
                                      @"<b>%@</b> at <b>%@</b>"
                                      @"<br><br>"
                                      @"I just scored this awesome deal with my TikTok app. "
                                      @"Sad you missed it? Don't be a square... download the "
                                      @"app and start getting your own deals right now."
                                      @"<br><br>"
                                      @"<a href='http://www.tiktok.com'>Get your deal on!</a>",
                                      formatted, merchant);
        [controller setMessageBody:deal isHTML:YES];


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
        NSString *formatted = [self.coupon.title capitalizedString];
        NSString *deal      = $string(@"%@ at %@", formatted, self.coupon.merchant.name);
        controller.body     = $string(@"TikTok: %@! www.tiktok.com", deal);
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

    // get closest location to user
    CLLocation* currentLocation = [LocationTracker currentLocation];
    Location* location =
        [self.coupon getClosestLocationToCoordinate:currentLocation.coordinate];

    // setup twitter controller
    Merchant *merchant  = self.coupon.merchant;
    NSString *city      = [[location getCity] lowercaseString];
    NSString *formatted = [self.coupon.title capitalizedString];
    NSString *twHandle  = (merchant.twitterUrl == nil) ||
                          [merchant.twitterUrl isEqualToString:@""] ?
                            merchant.name : merchant.twitterUrl;
    NSString *deal      = $string(@"I just got %@ from %@! @TikTok #FREEisBETTER #%@",
                                  formatted, twHandle, city);
    [twitter setInitialText:deal];
    [twitter addImage:[self imageForIcon:icon.image]];

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

    NSString *formatted = [self.coupon.title capitalizedString];
    NSString *deal      = $string(@"%@ at %@! - "
                                  @"I just scored this awesome deal with my TikTok app. "
                                  @"Sad you missed it? Don't be a square... download the "
                                  @"app and start getting your own deals right now.",
                                  formatted, self.coupon.merchant.name);
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

- (void) dialogCompleteWithUrl:(NSURL*)url
{
    // make sure post actually went through.. fucking pos facebook...
    NSString *query = url.query;
    if (!query || ([query rangeOfString:@"post_id"].location == NSNotFound)) {
        return;
    }

    // let server know of share
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    [api updateCoupon:self.coupon.couponId attribute:kTikTokApiCouponAttributeFacebook];

    // alert user of successful facebook post
    NSString *title   = NSLocalizedString(@"FACEBOOK", nil);
    NSString *message = NSLocalizedString(@"FACEBOOK_DEAL_POST", nil);
    [Utilities displaySimpleAlertWithTitle:title
                                andMessage:message];

    NSLog(@"CouponDetailViewController: facebook request did load");
}

//------------------------------------------------------------------------------

- (void) dialog:(FBDialog*)dialog didFailWithError:(NSError*)error
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

    // clean up notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
