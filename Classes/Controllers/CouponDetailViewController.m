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
#import "MerchantViewController.h"
#import "Merchant.h"
#import "Coupon.h"

//------------------------------------------------------------------------------
// enums
//------------------------------------------------------------------------------

enum CouponDetailTag
{
    kTagBarcodeView  = 1,
    kTagContentView  = 2,
    kTagRedeemButton = 3
};

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface CouponDetailViewController ()
    - (void) setupToolbar;
    - (void) setupCouponDetails;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation CouponDetailViewController

//------------------------------------------------------------------------------

@synthesize coupon       = mCoupon;
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
 * Implement loadView to create a view hierarchy programmatically, without 
 * using a nib.
 * /
- (void) loadView 
{
}
*/

//------------------------------------------------------------------------------

/**
 * Implement viewDidLoad to do additional setup after loading the view, 
 * typically from a nib.
 */
- (void) viewDidLoad 
{
    [super viewDidLoad];
    [self setupToolbar];
    [self setupCouponDetails];

    // add barcode view to the view and hide, do this so it shows up seperately
    // in interface designer and is easier to manage
    [self.view addSubview:self.barcodeView];
    self.barcodeView.hidden = YES;
}

//------------------------------------------------------------------------------

- (void) viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:YES];
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

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0, 0, 280, 100);
    [button setImage:[UIImage imageNamed:@"RedeemBarItemButton.png"] forState:UIControlStateNormal];
    UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    // set the items in the toolbar
    self.toolbarItems = $array(
        flexibleSpaceButton, 
        self.redeemButton, 
        //barButtonItem,
        flexibleSpaceButton,
        nil);

    // cleanup 
    [flexibleSpaceButton release];
}

//------------------------------------------------------------------------------

- (void) setupCouponDetails
{
    // [moiz] setup will differ depending on if the coupon has been redeemed 
    //   or not may also want to do the setup during the setting of the coupon
    //   maybe? doing it on view load seems a little hacky?
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
    // grab subviews
    __block UIView *barcodeView  = [self.view viewWithTag:kTagBarcodeView];
    __block UIView *contentView  = [self.view viewWithTag:kTagContentView];
    
    // make sure barcode view is visible
    self.barcodeView.hidden = NO;

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
    [UIView animateWithDuration:0.4 animations:^{
        contentView.frame      = contentFrameNew;
        self.barcodeView.frame = barcodeFrameNew;
    }];

    // hide the toolbar
    [self.navigationController setToolbarHidden:YES animated:YES];
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
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
