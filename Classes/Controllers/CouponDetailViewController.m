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

#import "CouponDetailViewController.h"
#import "Coupon.h"
#import "GradientView.h"
#import "IconManager.h"
#import "Merchant.h"
#import "MerchantViewController.h"

//------------------------------------------------------------------------------
// enums
//------------------------------------------------------------------------------

enum CouponDetailTag
{
    kTagBarcodeView  = 1,
    kTagContentView  = 2,
    kTagTitle        = 3,
    kTagDetails      = 4,
    kTagIcon         = 5,
    kTagIconActivity = 6,
    kTagColorTimer   = 7,
    kTagTextTimer    = 8,
    kTagTextTime     = 9
};

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface CouponDetailViewController ()
    - (void) setupToolbar;
    - (void) setupCouponDetails;
    - (void) setupIcon;
    - (void) setIcon:(UIImage*)image;
    - (void) arrangeSubviewsForRedeemedCouponWithAnimation:(bool)animated;
    - (void) resetSubviews;
    - (void) startTimer;
    - (void) updateTimers;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation CouponDetailViewController

//------------------------------------------------------------------------------

@synthesize coupon       = mCoupon;
@synthesize timer        = mTimer;
@synthesize barcodeView  = mBarcodeView;
@synthesize redeemButton = mRedeemButton;

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

    // add barcode view to the view and hide, do this so it shows up seperately
    // in interface designer and is easier to manage
    [self.view addSubview:self.barcodeView];
    self.barcodeView.hidden = YES;

    // correct font on timer
    UILabel *timer = (UILabel*)[self.view viewWithTag:kTagTextTimer];
    timer.font     = [UIFont fontWithName:@"NeutraDisp-BoldAlt" size:20];
}

//------------------------------------------------------------------------------

- (void) viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
    [self setupCouponDetails];

    // don't add redeem button if coupon is expired or already activated
    if (self.coupon.wasRedeemed) {
        [self arrangeSubviewsForRedeemedCouponWithAnimation:false];
    } else if (![self.coupon isExpired]) {
        [self setupToolbar];
    } else {
        [self resetSubviews];
    }

    // setup an update loop to for the color/text timers
    if (!self.coupon.isExpired) {
        [self startTimer];
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
}

//------------------------------------------------------------------------------
#pragma - Setup
//------------------------------------------------------------------------------

- (void) setupToolbar
{
    // show navigation toolbar
    [self.navigationController setToolbarHidden:NO animated:YES];

    // create a flexible spacer
    UIBarButtonItem *flexibleSpaceButton = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
                             target:nil 
                             action:nil];

    // set the items in the toolbar
    self.toolbarItems = $array(
        flexibleSpaceButton, 
        self.redeemButton, 
        flexibleSpaceButton,
        nil);

    // cleanup 
    [flexibleSpaceButton release];
}

//------------------------------------------------------------------------------

- (void) setupCouponDetails
{
    // title
    UITextView *title = (UITextView*)[self.view viewWithTag:kTagTitle];
    title.text        = self.coupon.title;

    // details
    UITextView *details = (UITextView*)[self.view viewWithTag:kTagDetails];
    details.text        = self.coupon.details;

    // icon
    [self setupIcon];

    // color timer
    GradientView *color = (GradientView*)[self.view viewWithTag:kTagColorTimer];
    color.color         = [self.coupon getColor];

    // text timer
    UILabel *label = (UILabel*)[self.view viewWithTag:kTagTextTimer];
    label.text     = [self.coupon getExpirationTimer];

    // text expire timer
    UILabel *expire = (UILabel*)[self.view viewWithTag:kTagTextTime];
    expire.text     = $string(@"Offer expires at %@.", [self.coupon getExpirationTime]);
}

//------------------------------------------------------------------------------

- (void) setupIcon
{
    IconManager *iconManager = [IconManager getInstance];
    NSURL *imageUrl          = [NSURL URLWithString:self.coupon.iconUrl];
    __block UIImage *image   = [iconManager getImage:imageUrl];

    // set merchant icon
    [self setIcon:image];

    // load image from server if not available
    if (!image) {
        [iconManager requestImage:imageUrl 
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
    if ([self.coupon isExpired]) [self.timer invalidate];
}

//------------------------------------------------------------------------------
#pragma - Events
//------------------------------------------------------------------------------

- (IBAction) merchantDetails:(id)sender
{
    MerchantViewController *merchantViewController = [[MerchantViewController alloc] 
        initWithNibName:@"MerchantViewController" bundle:nil];

    // set merchant to view
    merchantViewController.merchant = self.coupon.merchant;

    // pass the selected object to the new view controller.
    [self.navigationController pushViewController:merchantViewController animated:YES];
    [merchantViewController release];
}

//------------------------------------------------------------------------------

- (IBAction) redeemCoupon:(id)sender
{
    [self arrangeSubviewsForRedeemedCouponWithAnimation:true];
    self.coupon.wasRedeemed = YES;
}

//------------------------------------------------------------------------------

- (void) resetSubviews
{
    // grab subviews
    __block UIView *barcodeView  = [self.view viewWithTag:kTagBarcodeView];
    __block UIView *contentView  = [self.view viewWithTag:kTagContentView];

    // already in default state if barcode is hidden
    if (barcodeView.hidden) return;

    // hide barcode
    barcodeView.hidden = YES;

    // position contentview back to original position
    CGRect barcodeFrame          = barcodeView.frame;
    CGRect contentViewFrameNew   = contentView.frame;
    contentViewFrameNew.origin.x = barcodeFrame.origin.x;
    contentViewFrameNew.origin.y = barcodeFrame.origin.y;
    contentView.frame            = contentViewFrameNew;
}

//------------------------------------------------------------------------------

- (void) arrangeSubviewsForRedeemedCouponWithAnimation:(bool)animated
{
    // grab subviews
    __block UIView *barcodeView  = [self.view viewWithTag:kTagBarcodeView];
    __block UIView *contentView  = [self.view viewWithTag:kTagContentView];

    // already configured correctly if barcode is visible
    if (!barcodeView.hidden) return;
    
    // make sure barcode view is visible
    barcodeView.hidden = NO;

    // grab the current values of the views
    CGRect contentFrame = contentView.frame;
    CGRect barcodeFrame = self.barcodeView.frame;
    CGSize barcodeSize  = self.barcodeView.frame.size;

    // position the barcode view at content view origin and null out height
    barcodeFrame.origin.x    = contentFrame.origin.x;
    barcodeFrame.origin.y    = contentFrame.origin.y;
    barcodeFrame.size.height = 0.1;
    barcodeView.frame        = barcodeFrame;

    // calculate the new position for the content view
    __block CGRect contentFrameNew = contentFrame;
    contentFrameNew.origin.y      += barcodeSize.height;

    // calcuate the new size for the 
    __block CGRect barcodeFrameNew = barcodeFrame;
    barcodeFrameNew.size.height    = barcodeSize.height;

    // calculate the new scroll view height
    UIScrollView *scrollView = (UIScrollView*)self.view;
    CGSize scrollSizeNew     = scrollView.frame.size;
    scrollSizeNew.height    += barcodeSize.height;
    scrollView.contentSize   = scrollSizeNew;

    // animate new views into place
    void (^animationBlock)(void) = ^{
        contentView.frame      = contentFrameNew;
        self.barcodeView.frame = barcodeFrameNew;
    };
    
    // update the subviews
    if (animated) {
        [UIView animateWithDuration:0.4 animations:animationBlock];
        [self.navigationController setToolbarHidden:YES animated:YES];
    } else {
        animationBlock();
        [self.navigationController setToolbarHidden:YES animated:NO];
    }
}

//------------------------------------------------------------------------------

- (IBAction) shareMail:(id)sender
{
    NSLog(@"share mail");
}

//------------------------------------------------------------------------------

- (IBAction) shareTwitter:(id)sender
{
    NSLog(@"share twitter");
}

//------------------------------------------------------------------------------

- (IBAction) shareFacebook:(id)sender
{
    NSLog(@"share facebook");
}

//------------------------------------------------------------------------------

- (IBAction) shareGooglePlus:(id)sender
{
    NSLog(@"share googleplus");
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
    [mTimer release];
    [mRedeemButton release];
    [mBarcodeView release];
    [mCoupon release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
