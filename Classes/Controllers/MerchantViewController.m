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
#import "Coupon.h"
#import "GradientView.h"
#import "IconManager.h"
#import "Location.h"
#import "LocationTracker.h"
#import "Merchant.h"
#import "WebViewController.h"
#import "UIDefaults.h"

//------------------------------------------------------------------------------
// enums
//------------------------------------------------------------------------------

enum MerchantTags
{
    kTagCategory     =  5,
    kTagName         =  1,
    kTagIcon         =  3,
    kTagIconActivity =  4,
    kTagDetails      =  6,
    kTagAddress      =  7,
    kTagPhone        =  8,
    kTagWebsite      =  9,
    kTagGradient     = 10,
    kTagScrollView   = 11,
    kTagHeaderLabel  = 1,
    kTagHeaderArrow  = 2,
};

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface MerchantViewController ()
    - (void) setupMerchantDetails;
    - (void) setupIcon;
    - (void) setIcon:(UIImage*)image;
    - (void) setupLocationsTable;
    - (void) configureHeaderView:(bool)expanded;
    - (void) configureTableView:(bool)expanded;
    - (void) configureScrollView;
    - (void) configureDetails;
    - (NSString*) getFormattedAddressForLocation:(Location*)location;
    - (void) presentWebsite:(NSString*)url;
    - (void) clickAddress:(NSString*)address;
    - (void) clickPhone:(NSString*)number;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation MerchantViewController

//------------------------------------------------------------------------------

@synthesize coupon     = mCoupon;
@synthesize locations  = mLocations;
@synthesize tableView  = mTableView;
@synthesize cellView   = mCellView;
@synthesize headerView = mHeaderView;

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

    [Analytics passCheckpoint:@"Merchant"];

    // setup title
    self.title = @"Merchant";

    // [iOS4] fix for missing helvetics neuve fonts
    UILabel *address = (UILabel*)[self.view viewWithTag:kTagAddress];
    UILabel *website = (UILabel*)[self.view viewWithTag:kTagWebsite];
    UITextView *details = (UITextView*)[self.view viewWithTag:kTagDetails];
    if (address.font == nil) {
        address.font = [UIFont fontWithName:@"HelveticaNeueLight" size:15];
        website.font = [UIFont fontWithName:@"HelveticaNeueMeduim" size:15];
        details.font = [UIFont fontWithName:@"HelveticaNeueLight" size:14];
    }

    // set default variables
    mTableExpanded = false;
}

//------------------------------------------------------------------------------

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupLocationsTable];
    [self setupMerchantDetails];
    [self configureScrollView];
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

- (void) setupMerchantDetails
{
    Merchant *merchant     = self.coupon.merchant;
    bool multipleLocations = self.locations.count > 1;
    Location *location     = [self.locations objectAtIndex:0];

    // category
    UILabel *category = (UILabel*)[self.view viewWithTag:kTagCategory];
    category.text     = merchant.category;

    // name
    UILabel *name = (UILabel*)[self.view viewWithTag:kTagName];
    name.text     = [merchant.name uppercaseString];

    // address
    UILabelExt *address = (UILabelExt*)[self.view viewWithTag:kTagAddress];
    if (multipleLocations) {
        address.text           = @"Multiple locations,\nsee below.";
        address.highlightColor = [UIColor clearColor];
        address.delegate       = nil;
    } else {
        address.text = [self getFormattedAddressForLocation:location];
    }

    // phone number
    UILabelExt *phone = (UILabelExt*)[self.view viewWithTag:kTagPhone];
    if (multipleLocations) {
        phone.text           = @"";
        phone.highlightColor = [UIColor clearColor];
        phone.delegate       = nil;
    } else {
        phone.text = location.phone;
    }

    // website
    UILabelExt *website = (UILabelExt*)[self.view viewWithTag:kTagWebsite];
    if ([merchant.websiteUrl isEqualToString:@""]) {
        website.text           = @"";
        website.highlightColor = [UIColor clearColor];
        website.delegate       = nil;
    } else {
        website.text = [merchant.websiteUrl
            stringByReplacingOccurrencesOfString:@"http://"
                                    withString:@""];
    }

    // details
    UITextView *details      = (UITextView*)[self.view viewWithTag:kTagDetails];
    details.text             = merchant.details;
    CGRect detailsFrame      = details.frame;
    detailsFrame.size.height = details.contentSize.height;
    details.frame            = detailsFrame;

    // gradient
    GradientView *color = (GradientView*)[self.view viewWithTag:kTagGradient];
    color.color         = [UIDefaults getTikColor];

    // icon
    [self setupIcon];
}

//------------------------------------------------------------------------------

- (void) setupIcon
{
    IconManager *iconManager = [IconManager getInstance];
    __block UIImage *image   = [iconManager getImage:self.coupon.merchant.iconData];

    // set merchant icon
    [self setIcon:image];

    // load image from server if not available
    if (!image) {
        [iconManager requestImage:self.coupon.merchant.iconData
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

- (void) setupLocationsTable
{
    // check if the locations table should be used
    if (self.locations.count > 1) {
        [self configureHeaderView:false];

    // clean up the view, no need to display the table
    } else {

        // hide the table view
        self.tableView.hidden = YES;

        // slide up the details view to compensate for table
        [self configureDetails];
    }
}

//------------------------------------------------------------------------------

- (void) configureHeaderView:(bool)expanded
{
    // setup the label
    UILabel *label = (UILabel*)[self.headerView viewWithTag:kTagHeaderLabel];
    label.text     = expanded ? @"Close" : @"Expand to see all locations";

    // check if the arrow is pointing the correct way
    UIImageView *arrow  = (UIImageView*)[self.headerView viewWithTag:kTagHeaderArrow];
    NSString *arrowName = expanded ? @"ArrowCollapse.png" : @"ArrowExpand.png";
    arrow.image         = [UIImage imageNamed:arrowName];
}

//------------------------------------------------------------------------------

- (void) configureTableView:(bool)expanded;
{
    // update table height
    CGRect tableFrame       = self.tableView.frame;
    CGFloat tableHeight     = self.locations.count * self.cellView.frame.size.height;
    tableFrame.size.height += expanded ? tableHeight : -tableHeight;
    self.tableView.frame    = tableFrame;
}

//------------------------------------------------------------------------------

- (void) configureScrollView
{
    UITextView *details    = (UITextView*)[self.view viewWithTag:kTagDetails];
    UITextView *scrollView = (UITextView*)[self.view viewWithTag:kTagScrollView];

    // calculate size of content
    CGFloat height = details.frame.size.height + self.tableView.frame.size.height;

    // update scrollviews content size
    CGSize contentSize     = scrollView.contentSize;
    contentSize.height     = height;
    scrollView.contentSize = contentSize;
}

//------------------------------------------------------------------------------

- (void) configureDetails
{
    UITextView *details = (UITextView*)[self.view viewWithTag:kTagDetails];
    CGRect frame        = details.frame;
    frame.origin.y      = self.tableView.hidden ? 0 : self.tableView.frame.size.height;
    details.frame       = frame;
}

//------------------------------------------------------------------------------
#pragma mark - Helper functions
//------------------------------------------------------------------------------

- (NSString*) getFormattedAddressForLocation:(Location*)location
{
    NSRange firstComma = [location.address rangeOfString:@", "];
    NSString *address  = [location.address
        stringByReplacingOccurrencesOfString:@", "
                                  withString:@",\n"
                                     options:NSCaseInsensitiveSearch
                                       range:NSMakeRange(0, firstComma.location + 2)];
    return address;
}

//------------------------------------------------------------------------------
#pragma mark - UITable view header
//------------------------------------------------------------------------------

- (void) headerView:(UITableViewHeader*)headerView sectionTapped:(NSInteger)section
{
    mTableExpanded = !mTableExpanded;
    [self configureHeaderView:mTableExpanded];
    [self configureTableView:mTableExpanded];
    [self configureScrollView];

    // animate details shift
    [UIView animateWithDuration:0.25 animations:^{
        [self configureDetails];
    }];

    // reload table
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:section];
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
}

//------------------------------------------------------------------------------
#pragma mark - Table view data source
//------------------------------------------------------------------------------

/**
 * Customize the number of sections in the table view.
 */
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}

//------------------------------------------------------------------------------

/**
 * Customize the number of rows in the table view.
 */
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return mTableExpanded ? self.locations.count : 0;
}

//------------------------------------------------------------------------------

/**
 * Customize the height of the cell at the given index.
 */
- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    // use the height from the cell view prototype
    return self.cellView.contentView.frame.size.height;
}

//------------------------------------------------------------------------------

/**
 * Customize the appearance of table view cells.
 */
- (UITableViewCell*) tableView:(UITableView*)tableView
         cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    static NSString *sCellId = @"location_cell";

    // only create as many coupons as are in view at the same time
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:sCellId];
    if (cell == nil) {
        NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:self.cellView];
        cell = [NSKeyedUnarchiver unarchiveObjectWithData:archivedData];

        // [iOS4] UIImage can't be archived/unarchived, set images manually
        UIImageView *background = (UIImageView*)[cell backgroundView];
        background.image        = [UIImage imageNamed:@"MerchantLocationCellBackground.png"];

        // [iOS4] fix for missing helvetics neuve fonts
        UILabelExt *address = (UILabelExt*)[cell viewWithTag:kTagAddress];
        if (address.font == nil) {
            address.font = [UIFont fontWithName:@"HelveticaNeueLight" size:15];
        }

        // setup delegates
        UILabelExt *phone = (UILabelExt*)[cell viewWithTag:kTagPhone];
        phone.delegate    = self;
        address.delegate  = self;
    }

    // configure the cell
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

//------------------------------------------------------------------------------

- (void) configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    // grab location at index
    Location *location = [self.locations objectAtIndex:indexPath.row];

    // grab cell views
    UILabel *name    = (UILabel*)[cell viewWithTag:kTagName];
    UILabel *address = (UILabel*)[cell viewWithTag:kTagAddress];
    UILabel *phone   = (UILabel*)[cell viewWithTag:kTagPhone];

    // use merchant name if location name not given
    NSString *locationName = [location.name isEqualToString:@""] ?
        self.coupon.merchant.name : location.name;

    // update cell info
    name.text    = locationName;
    address.text = [self getFormattedAddressForLocation:location];
    phone.text   = location.phone;
}

//------------------------------------------------------------------------------

/**
 * Override to support conditional editing of the table view.
 */
- (BOOL) tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
    // table rows are not editable
    return NO;
}

//------------------------------------------------------------------------------

/**
 * Override to support rearranging the table view.
 */
- (void) tableView:(UITableView*)tableView
    moveRowAtIndexPath:(NSIndexPath*)fromIndexPath
           toIndexPath:(NSIndexPath*)toIndexPath
{
    // items cannot be moved
}

//------------------------------------------------------------------------------

/**
 * Override to support conditional rearranging of the table view.
 */
- (BOOL) tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath
{
    // items cannot be re-ordered
    return NO;
}

//------------------------------------------------------------------------------
#pragma mark - TableView Delegate
//------------------------------------------------------------------------------

- (CGFloat) tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    return self.headerView.frame.size.height;
}

//------------------------------------------------------------------------------

- (UIView*) tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    return self.headerView;
}

//------------------------------------------------------------------------------
#pragma mark - UILabelExt
//------------------------------------------------------------------------------

- (void) tappedLabelView:(UILabelExt*)labelView
{
    switch (labelView.tag) {
        case kTagAddress:
            [self clickAddress:labelView.text];
            break;
        case kTagPhone:
            [self clickPhone:labelView.text];
            break;
        case kTagWebsite:
            [self presentWebsite:labelView.text];
            break;
    }
}

//------------------------------------------------------------------------------
#pragma - Events
//------------------------------------------------------------------------------

- (void) presentWebsite:(NSString*)url
{
    [Analytics passCheckpoint:@"Merchant Website"];

    // setup a webview controller
    WebViewController *controller = [[WebViewController alloc] init];
    controller.title              = self.coupon.merchant.name;
    controller.url                = url;

    // present the webview
    [self.navigationController pushViewController:controller animated:YES];

    // cleanup
    [controller release];
}

//------------------------------------------------------------------------------

- (void) clickAddress:(NSString*)address
{
    [Analytics passCheckpoint:@"Merchant Address"];

    NSString *formatedAddress = [[address
        stringByReplacingOccurrencesOfString:@"\n" withString:@"%20"]
        stringByReplacingOccurrencesOfString:@" "  withString:@"%20"];

    NSString *mapPath = $string(@"http://maps.google.com/maps?q=%@", formatedAddress);
    NSURL *mapUrl     = [NSURL URLWithString:mapPath];
    [[UIApplication sharedApplication] openURL:mapUrl];
}

//------------------------------------------------------------------------------

- (void) clickPhone:(NSString*)number
{
    [Analytics passCheckpoint:@"Merchant Phone"];

    // construct message for verify phone call
    NSString *title   = $string(@"Calling %@", self.coupon.merchant.name);
    NSString *message = $string(@"Make call to %@?", number);

    UIAlertViewSelectionHandler handler = ^(NSInteger buttonIndex) {
        if (buttonIndex == 1) {
            NSURL *phoneUrl = [NSURL URLWithString:$string(@"tel:%@", number)];
            [[UIApplication sharedApplication] openURL:phoneUrl];
        }
    };

    // display alert window
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                withHandler:handler
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
    [alert show];
    [alert release];
}

//------------------------------------------------------------------------------

- (IBAction) clickWebsite:(id)sender
{
    [self presentWebsite:self.coupon.merchant.websiteUrl];
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
    [mHeaderView release];
    [mCellView release];
    [mTableView release];
    [mCoupon release];
    [mLocations release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
