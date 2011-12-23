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
#import "Merchant.h"
#import "Coupon.h"

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation CouponDetailViewController

//------------------------------------------------------------------------------

@synthesize coupon = mCoupon;

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

    // update the merchant name
    UILabel *label = (UILabel*)[self.view viewWithTag:1];
    [label setText:self.coupon.merchant.name];

    // update the coupon image
    //UIImageView *imageView = (UIImageView*)[self.view viewWithTag:2];
    //[imageView setImage:self.coupon.image];
        
    // update the coupon text
    UITextView *textView = (UITextView*)[self.view viewWithTag:3];
    [textView setText:self.coupon.text];
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

- (void)didReceiveMemoryWarning 
{
    // releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // release any cached data, images, etc. that aren't in use.
}

//------------------------------------------------------------------------------

- (void)viewDidUnload 
{
    [super viewDidUnload];
    // release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

//------------------------------------------------------------------------------

- (void) dealloc 
{
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
