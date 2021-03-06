//
//  CouponViewController.m
//  TikTok
//
//  Created by Moiz Merchant on 4/19/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <Twitter/Twitter.h>
#import "Coupon.h"
#import "CouponViewController.h"
#import "CouponTableViewCell.h"
#import "CouponDetailViewController.h"
#import "Database.h"
#import "FacebookManager.h"
#import "GradientView.h"
#import "IconManager.h"
#import "LogViewController.h"
#import "Merchant.h"
#import "PromoController.h"
#import "Settings.h"
#import "TikTokApi.h"
#import "UIDefaults.h"
#import "Utilities.h"

//------------------------------------------------------------------------------
// defines
//------------------------------------------------------------------------------

#define SECONDS_PER_DAY 86400

//------------------------------------------------------------------------------
// enums
//------------------------------------------------------------------------------

enum CouponTag {
    kTagIcon            =  1,
    kTagTitle           =  2,
    kTagTextTime        =  3,
    kTagTextTimer       =  4,
    kTagColorTimer      =  5,
    kTagIconActivity    =  6,
    kTagSash            =  7,
    kTagCompanyName     =  8,
    kTagBackground      =  9,
    kTagActiveFilter    = 10,
    kTagRedeemedFilter  = 11,
    kTagNoDeals         = 12,
    kTagWhiteBackground = 13,
};

enum ActionButton
{
    kActionButtonFacebook = 0,
    kActionButtonTwitter  = 1,
    kActionButtonSMS      = 2,
    kActionButtonEmail    = 3,
};

//------------------------------------------------------------------------------
// statics
//------------------------------------------------------------------------------

static NSString *sCouponCacheName = @"coupon_table";

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface CouponViewController ()
    - (void) setupRefreshHeader;
    - (void) setupFilterButtons;
    - (void) setupNavButtons;
    - (void) openLog;
    - (void) setupFilterPopoverController;
    - (WEPopoverContainerViewProperties*) popoverViewProperties;
    - (void) updateExpiration:(NSTimer*)timer;
    - (void) configureCell:(UIView*)cell atIndexPath:(NSIndexPath*)indexPath;
    - (void) configureExpiredCell:(UITableViewCell*)cell coupon:(Coupon*)coupon;
    - (void) configureActiveCell:(UITableViewCell*)cell withCoupon:(Coupon*)coupon;
    - (void) updateActiveCell:(UITableViewCell*)cell withCoupon:(Coupon*)coupon;
    - (void) configureNoDealsImage;
    - (void) setIcon:(UIImage*)image forCell:(UIView*)cell;
    - (void) setupIconForCell:(UIView*)cell atIndexPath:(NSIndexPath*)indexPath withCoupon:(Coupon*)coupon;
    - (void) requestImageForCoupon:(Coupon*)coupon atIndexPath:(NSIndexPath*)indexPath;
    - (void) loadImagesForOnscreenRows;
    - (void) reloadTableViewDataSource;
    - (void) doneLoadingTableViewData;
    - (void) reloadFetchedResults;
    - (void) updateFilterByReedmeedOnly:(bool)redeemedOnly activeOnly:(bool)activeOnly;
    - (void) filterDealsRedeemed:(id)sender;
    - (void) filterDealsActive:(id)sender;
    - (void) filterPopup;
    - (void) redeemPromoCode:(id)sender;
    - (void) shareApp:(id)sender;
    - (void) shareTwitter;
    - (void) shareFacebook;
    - (void) setupFacebook;
    - (void) postDealToFacebook;
    - (void) setupTwitter;
    - (void) tweetDealOnTwitter;
    - (void) shareSMS;
    - (void) shareEmail;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation CouponViewController

//------------------------------------------------------------------------------

@synthesize cellView                 = mCellView;
@synthesize tableView                = mTableView;
@synthesize fetchedCouponsController = mFetchedCouponsController;
@synthesize popoverControllerFilter  = mPopoverControllerFilter;

//------------------------------------------------------------------------------
#pragma mark - View lifecycle
//------------------------------------------------------------------------------

/**
 * Only runs after view is loaded.
 */
- (void) viewDidLoad
{
    [super viewDidLoad];

    // set title
    self.title = @"Deals";

    // patch font in cell
    UILabel *timer = (UILabel*)[self.cellView viewWithTag:kTagTextTimer];
    timer.font     = [UIFont fontWithName:@"NeutraDisp-BoldAlt" size:19];

    // tag testflight checkpoint
    [Analytics passCheckpoint:@"Deals"];

    // add navitems
    [self setupNavButtons];

    // setup the refresh header
    [self setupRefreshHeader];

    // add app backgrounded notification
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(reloadFetchedResults)
               name:UIApplicationDidEnterBackgroundNotification
             object:nil];

    // initialize fields
    mReloading = false;
}

//------------------------------------------------------------------------------

- (void) setupRefreshHeader
{
    // make sure reload header is not already loaded
    if (!mRefreshHeaderView) {
        CGRect frame;
        frame.origin.x    = 0.0;
        frame.origin.y    = -self.tableView.bounds.size.height;
        frame.size.width  = self.view.frame.size.width;
        frame.size.height = self.tableView.bounds.size.height;

        // setup a new header view
        EGORefreshTableHeaderView *headerView =
            [[EGORefreshTableHeaderView alloc] initWithFrame:frame
                                              arrowImageName:@"Tik.png"
                                                   textColor:[UIColor blackColor]];
        headerView.delegate = self;

        // add a background image
        CGRect backgroundFrame  = CGRectMake(0.0f, 0.0f,
                                             frame.size.width, frame.size.height);
        UIImageView *background = [[UIImageView alloc] initWithFrame:backgroundFrame];
        background.image        = [UIImage imageNamed:@"CouponDetailBackgroundTexture.png"];
        [headerView insertSubview:background atIndex:0];

        // add to table
        [self.tableView addSubview:headerView];

        // save pointer
        mRefreshHeaderView = [headerView retain];

        // cleanup
        [headerView release];
        [background release];
    }

    //  update the last update date
    [mRefreshHeaderView refreshLastUpdatedDate];
}

//------------------------------------------------------------------------------

- (void) setupFilterButtons
{
    // create a bar button item for filters
    UIBarButtonItem *filterButton =
        [[UIBarButtonItem alloc] initWithTitle:@"Filter"
                                         style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(filterPopup)];

    // add to navbar
    self.navigationItem.leftBarButtonItem = filterButton;

    // cleanup
    [filterButton release];
}

//------------------------------------------------------------------------------

- (void) setupNavButtons
{
    // share app button
    UIBarButtonItem *shareButton =
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"112-group-bar.png"]
                                         style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(shareApp:)];

    // redeem promo button
    UIBarButtonItem *redeemButton =
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"24-gift-bar.png"]
                                         style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(redeemPromoCode:)];

    // add to navbar
    self.navigationItem.leftBarButtonItem  = redeemButton;
    self.navigationItem.rightBarButtonItem = shareButton;

    // cleanup
    [shareButton release];
    [redeemButton release];

    // add debug gesture recognizer to logo
    if (LOGGING_VIEWER) {
        UIView *logo = self.navigationItem.titleView;
        UITapGestureRecognizer* gestureRecognizer =
            [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openLog)];
        [logo setUserInteractionEnabled:YES];
        [logo addGestureRecognizer:gestureRecognizer];
        [gestureRecognizer release];
    }
}

//------------------------------------------------------------------------------

- (void) openLog
{
    LogViewController *controller = [[LogViewController alloc] init];
    [self presentModalViewController:controller animated:YES];
    [controller release];
}

//------------------------------------------------------------------------------

- (void) setupFilterPopoverController
{
    // create popup and content view controllers
    UIViewController *contentViewController =
        [[UIViewController alloc] init];

    // create active button
    UISegmentedControl *activeButton   =
        [[UISegmentedControl alloc] initWithItems:$array(@"Active Only")];
    activeButton.tag                   = kTagActiveFilter;
    activeButton.tintColor             = [UIColor darkGrayColor];
    activeButton.segmentedControlStyle = UISegmentedControlStyleBar;
    [activeButton addTarget:self
                     action:@selector(filterDealsActive:)
           forControlEvents:UIControlEventValueChanged];

    // create redeemed button
    UISegmentedControl *redeemedButton   =
        [[UISegmentedControl alloc] initWithItems:$array(@"Redeemed Only")];
    redeemedButton.tag                   = kTagRedeemedFilter;
    redeemedButton.tintColor             = [UIColor darkGrayColor];
    redeemedButton.segmentedControlStyle = UISegmentedControlStyleBar;
    [redeemedButton addTarget:self
                       action:@selector(filterDealsRedeemed:)
             forControlEvents:UIControlEventValueChanged];

    // layout the buttons properly
    CGFloat buffer          = 5.0;
    CGRect activeFrame      = activeButton.frame;
    CGRect redeemedFrame    = redeemedButton.frame;
    activeFrame.origin.x   += buffer;
    activeFrame.origin.y   += buffer;
    redeemedFrame.origin.x += buffer;
    redeemedFrame.origin.y  = activeFrame.origin.y + activeFrame.size.height + buffer;

    // resize the buttons to have equal width
    CGFloat maxWidth         = MAX(activeFrame.size.width, redeemedFrame.size.width);
    activeFrame.size.width   = maxWidth;
    redeemedFrame.size.width = maxWidth;

    // update the frames
    activeButton.frame   = activeFrame;
    redeemedButton.frame = redeemedFrame;

    // create a view to hold the buttons
    CGRect frame;
    frame.origin.x    = 0.0;
    frame.origin.y    = 0.0;
    frame.size.width  = maxWidth + buffer * 2.0;
    frame.size.height = redeemedFrame.origin.y + redeemedFrame.size.height + buffer;
    UIView *view = [[UIView alloc] initWithFrame:frame];
    [view addSubview:activeButton];
    [view addSubview:redeemedButton];

    // set view on controller
    contentViewController.view                        = view;
    contentViewController.contentSizeForViewInPopover = frame.size;

    // create the popup controller
    WEPopoverController *popoverController = [[WEPopoverController alloc]
        initWithContentViewController:contentViewController];

    // setup popover
    popoverController.delegate                = self;
    popoverController.passthroughViews        = $array(self.navigationController.navigationBar);
    popoverController.containerViewProperties = [self popoverViewProperties];

    // save controller
    self.popoverControllerFilter = popoverController;

    // cleanup
    [view release];
    [activeButton release];
    [redeemedButton release];
    [contentViewController release];
    [popoverController release];
}

//------------------------------------------------------------------------------

- (WEPopoverContainerViewProperties*) popoverViewProperties
{
    WEPopoverContainerViewProperties *props =
        [[WEPopoverContainerViewProperties alloc] autorelease];

    NSString *backgroundImageName = nil;
    CGFloat backgroundMargin      = 0.0;
    CGFloat backgroundCapSize     = 0.0;
    CGFloat contentMargin         = 4.0;

    backgroundImageName = @"popoverBg.png";

    // these constants are determined by the popoverBg.png image file and are
    // image dependent, margin width of 13 pixels on all sides popoverBg.png
    // margin = (62 pixels wide - 36 pixel background) / 2 == 26 / 2 == 13
    // size   = imageSize/2  == 62 / 2 == 31 pixels
    backgroundMargin  = 13;
    backgroundCapSize = 31;

    props.leftBgMargin        = backgroundMargin;
    props.rightBgMargin       = backgroundMargin;
    props.topBgMargin         = backgroundMargin;
    props.bottomBgMargin      = backgroundMargin;
    props.leftBgCapSize       = backgroundCapSize;
    props.topBgCapSize        = backgroundCapSize;
    props.bgImageName         = backgroundImageName;
    props.leftContentMargin   = contentMargin;
    props.rightContentMargin  = contentMargin - 1;
    props.topContentMargin    = contentMargin;
    props.bottomContentMargin = contentMargin;

    props.arrowMargin = 4.0;

    props.upArrowImageName    = @"popoverArrowUp.png";
    props.downArrowImageName  = @"popoverArrowDown.png";
    props.leftArrowImageName  = @"popoverArrowLeft.png";
    props.rightArrowImageName = @"popoverArrowRight.png";

    return props;
}

//------------------------------------------------------------------------------

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // deselect selected rows
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
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

/*
- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}
*/

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
#pragma mark - Table view data source
//------------------------------------------------------------------------------

/**
 * Customize the number of sections in the table view.
 */
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    // currently all the coupons are grouped together in one section
    return 1;
}

//------------------------------------------------------------------------------

/**
 * Customize the number of rows in the table view.
 */
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo =
        [[self.fetchedCouponsController sections] objectAtIndex:section];
    NSInteger objectCount = [sectionInfo numberOfObjects];
    return objectCount;
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
    static NSString *sCellId = @"coupon_cell";

    // only create as many coupons as are in view at the same time
    CouponTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:sCellId];
    if (cell == nil) {
        NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:self.cellView];
        cell = [NSKeyedUnarchiver unarchiveObjectWithData:archivedData];
        cell.selectionStyle  = UITableViewCellSelectionStyleGray;

        // [iOS4] UIImage can't be archived/unarchived, set images manually
        UIImageView *background = (UIImageView*)[cell backgroundView];
        background.image        = [UIImage imageNamed:@"CellBackground.png"];
    }

    // configure the cell
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
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
 * Override to support editing the table view.
 * /
- (void) tableView:(UITableView*)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath*)indexPath
{

    // delete the row from the data source.
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                         withRowAnimation:UITableViewRowAnimationFade];

    // create a new instance of the appropriate class, insert it into the array,
    //  and add a new row to the table view.
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
    }
}
*/

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
#pragma mark - Cell Configuration
//------------------------------------------------------------------------------

/**
 * Initializes cell with coupon information.
 */
- (void) configureCell:(CouponTableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    // skip out if no cell available
    if (!cell) return;

    // grab coupon at the given index path
    Coupon* coupon = [self.fetchedCouponsController objectAtIndexPath:indexPath];

    // set coupon on cell
    cell.coupon = coupon;

    // invaliate the timer
    [cell.timer invalidate];

    // update the company name
    UILabel *company = (UILabel*)[cell viewWithTag:kTagCompanyName];
    [company setText:[coupon.merchant.name uppercaseString]];

    // update the coupon headline
    UILabel *headline = (UILabel*)[cell viewWithTag:kTagTitle];
    [headline setText:[coupon getTitleWithFormatting]];

    // setup icon
    [self setupIconForCell:cell atIndexPath:indexPath withCoupon:coupon];

    // configure redeemed sash
    UIImageView* sash = (UIImageView*)[cell viewWithTag:kTagSash];
    sash.hidden       = !coupon.wasRedeemed.boolValue &&
                        !coupon.isSoldOut.boolValue &&
                        coupon.isRedeemable.boolValue;
    sash.image        = !coupon.isRedeemable.boolValue ? [UIImage imageNamed:@"InfoSash.png"] :
                        coupon.wasRedeemed.boolValue ? [UIImage imageNamed:@"RedeemedSash.png"] :
                        coupon.isSoldOut.boolValue ? [UIImage imageNamed:@"SoldOutSash.png"] : nil;

    // update the cell to reflect the state of the coupon
    if ([coupon isExpired]) {
        [self configureExpiredCell:cell coupon:coupon];
    } else {
        [self configureActiveCell:cell withCoupon:coupon];

        // create update loop for timers
        cell.timer = [NSTimer timerWithTimeInterval:1.0
                                             target:self
                                          selector:@selector(updateExpiration:)
                                          userInfo:cell
                                           repeats:YES];

        // add timer to the main loop
        [[NSRunLoop mainRunLoop] addTimer:cell.timer forMode:NSRunLoopCommonModes];
    }
}

//------------------------------------------------------------------------------

- (void) updateExpiration:(NSTimer*)timer
{
    // grab coupon at the given index path
    CouponTableViewCell* cell = (CouponTableViewCell*)timer.userInfo;
    Coupon *coupon            = cell.coupon;
    if (coupon == nil) return;

    /* only update the view if its visibile
    UIView *view = [cell viewWithTag:kTagTextTime];
    CGRect rect  = [view convertRect:view.frame toView:self.view.superview];
    bool visible = CGRectIntersectsRect(self.view.superview.frame, rect);
    if (!visible) return;
    */

    // update the cell to reflect the state of the coupon
    if ([coupon isExpired]) {
        [timer invalidate];
        [UIView animateWithDuration:0.25 animations:^{
            [self configureExpiredCell:cell coupon:coupon];
        }];
    } else {
        [self updateActiveCell:cell withCoupon:coupon];
    }
}

//------------------------------------------------------------------------------

- (void) configureNoDealsImage
{
    bool showNoDeals = self.fetchedCouponsController.fetchedObjects.count == 0;

    // udpate the state of alert if required
    UIView *noDeals = [self.view viewWithTag:kTagNoDeals];
    if (noDeals.hidden != !showNoDeals) {
        [UIView animateWithDuration:0.25 animations:^{
            noDeals.hidden = !showNoDeals;
            noDeals.alpha  = showNoDeals ? 1.0 : 0.0;
        }];
    }
}

//------------------------------------------------------------------------------

- (void) configureExpiredCell:(UITableViewCell*)cell coupon:(Coupon*)coupon
{
    const static CGFloat expiredAlpha = 0.4;
    static NSString *timerText        = @"TIME'S UP!";

    // expire text
    UILabel *textTime  = (UILabel*)[cell viewWithTag:kTagTextTime];
    textTime.text      = $string(@"Offer expired at %@", [coupon getExpirationTime]);

    // expire timer
    UILabel *textTimer  = (UILabel*)[cell viewWithTag:kTagTextTimer];
    textTimer.text      = timerText;

    // color timer
    GradientView *color = (GradientView*)[cell viewWithTag:kTagColorTimer];
    color.color         = [UIDefaults getTokColor];

    // update the cell opacity
    for (UIView *view in cell.contentView.subviews) {
        if (view.tag != kTagWhiteBackground) {
            view.alpha = expiredAlpha;
        }
    }
}

//------------------------------------------------------------------------------

- (void) configureActiveCell:(UITableViewCell*)cell withCoupon:(Coupon*)coupon
{
    // fix the opacity
    for (UIView *view in cell.contentView.subviews) {
        view.alpha = 1.0;
    }

    // expire time
    UILabel *expire  = (UILabel*)[cell viewWithTag:kTagTextTime];
    expire.text      = $string(@"Offer expires at %@", [coupon getExpirationTime]);
    expire.textColor = [(UILabel*)[self.cellView viewWithTag:kTagTextTime] textColor];

    // configure the timers
    [self updateActiveCell:cell withCoupon:coupon];
}

//------------------------------------------------------------------------------

- (void) updateActiveCell:(UITableViewCell*)cell withCoupon:(Coupon*)coupon
{
    // color timer
    GradientView *color = (GradientView*)[cell viewWithTag:kTagColorTimer];
    color.color         = [coupon getColor];

    // text timer
    UILabel *label = (UILabel*)[cell viewWithTag:kTagTextTimer];
    label.text     = [coupon getExpirationTimer];
}

//------------------------------------------------------------------------------

- (void) setupIconForCell:(UIView*)cell
              atIndexPath:(NSIndexPath*)indexPath
               withCoupon:(Coupon*)coupon
{
    IconManager *iconManager = [IconManager getInstance];
    __block UIImage *image   = [iconManager getImage:coupon.iconData];

    // set merchant icon
    [self setIcon:image forCell:cell];

    // load image from server if table is not moving
    if (!image && !self.tableView.dragging && !self.tableView.decelerating) {
        [self requestImageForCoupon:coupon atIndexPath:indexPath];
    }
}

//------------------------------------------------------------------------------

- (void) setIcon:(UIImage*)image forCell:(UIView*)cell
{
    UIImageView *icon
        = (UIImageView*)[cell viewWithTag:kTagIcon];
    UIActivityIndicatorView *spinner
        = (UIActivityIndicatorView*)[cell viewWithTag:kTagIconActivity];

    // update icon
    icon.image  = image;
    icon.hidden = image == nil;
    icon.alpha  = image == nil ? 0.0f : 1.0f;

    // update spinner
    if (image) {
        [spinner stopAnimating];
    } else {
        [spinner startAnimating];
    }
}

//------------------------------------------------------------------------------
#pragma mark - TableView Delegate
//------------------------------------------------------------------------------

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    // [moiz] this should be cached in some way, causes animation hitch eveytime
    //  it loads...
    CouponDetailViewController *detailViewController = [[CouponDetailViewController alloc]
        initWithNibName:@"CouponDetailViewController" bundle:nil];

    // grab coupon at the given index path
    Coupon* coupon = [self.fetchedCouponsController objectAtIndexPath:indexPath];

    // set coupon to view
    [detailViewController setCoupon:coupon];

    // pass the selected object to the new view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
    [detailViewController release];
}

//------------------------------------------------------------------------------

/**
 * Customize the appearance of the table header.
- (UIView*) tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
}
*/

//------------------------------------------------------------------------------

/**
 * Customize the height of the header.
 */
- (CGFloat) tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    // no headers should be visible
    return 0.0;
}

//------------------------------------------------------------------------------

- (void) requestImageForCoupon:(Coupon*)coupon atIndexPath:(NSIndexPath*)indexPath
{
    // submit the request to retrive the image and update the cell
    IconManager *iconManager = [IconManager getInstance];
    [iconManager requestImage:coupon.iconData
        withCompletionHandler:^(UIImage* image, NSError *error) {
            NSArray *visibleIndices = [self.tableView indexPathsForVisibleRows];
            if (image && [visibleIndices containsObject:indexPath]) {
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                [UIView animateWithDuration:0.2 animations:^{
                    [self setIcon:image forCell:cell];
                }];
            } else if (error) {
                NSLog(@"CouponViewController: Failed to load image: %@", error);
                if ([visibleIndices containsObject:indexPath]) {
                    [self requestImageForCoupon:coupon atIndexPath:indexPath];
                }
            }
        }];
}

//------------------------------------------------------------------------------

- (void) loadImagesForOnscreenRows
{
    NSArray *visibleIndices  = [self.tableView indexPathsForVisibleRows];
    IconManager *iconManager = [IconManager getInstance];

    [visibleIndices enumerateObjectsUsingBlock:
        ^(NSIndexPath *indexPath, NSUInteger index, BOOL *stop) {
            Coupon *coupon = [self.fetchedCouponsController objectAtIndexPath:indexPath];
            UIImage *image = [iconManager getImage:coupon.iconData];
            if (image == nil) {
                [self requestImageForCoupon:coupon atIndexPath:indexPath];
            }
        }];
}

//------------------------------------------------------------------------------
#pragma mark - Fetched Results Controller
//------------------------------------------------------------------------------

- (NSFetchedResultsController*) fetchedCouponsController
{
    // check if controller already created
    if (mFetchedCouponsController) {
        return mFetchedCouponsController;
    }

    NSManagedObjectContext *context = [[Database getInstance] context];

    // create an entity description object
    NSEntityDescription *description = [NSEntityDescription
        entityForName:@"Coupon" inManagedObjectContext:context];

    // create a sort descriptor
    NSSortDescriptor *sortByEndDate = [[NSSortDescriptor alloc]
        initWithKey:@"endTime" ascending:NO];

    // create a predicate
    NSDate *oneDayAgo      = [[NSDate date] dateByAddingTimeInterval:(-1 * SECONDS_PER_DAY)];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
            @"endTime > %@", oneDayAgo];

    // create a fetch request
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity          = description;
    request.fetchBatchSize  = 10;
    request.predicate       = predicate;
    request.sortDescriptors = $array(sortByEndDate);

    // clear the cache, can't use cache with predicates...
    [NSFetchedResultsController deleteCacheWithName:sCouponCacheName];

    // create a results controller from the request
    NSFetchedResultsController *fetchedCouponsController =
        [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                            managedObjectContext:context
                                              sectionNameKeyPath:nil
                                                       cacheName:nil];

    // save the controller
    self.fetchedCouponsController          = fetchedCouponsController;
    self.fetchedCouponsController.delegate = self;

    // preform the fetch
    NSError *error = nil;
    if (![self.fetchedCouponsController performFetch:&error]) {
        NSLog(@"Fetching of coupons failed: %@, %@", error, [error userInfo]);
        abort();
    }

    // cleanup
    [request release];
    [sortByEndDate release];
    [fetchedCouponsController release];

    [self configureNoDealsImage];

    return mFetchedCouponsController;
}

//------------------------------------------------------------------------------
#pragma mark - Fetched Results Controller Delegates
//------------------------------------------------------------------------------

- (void) controllerWillChangeContent:(NSFetchedResultsController*)controller
{
    [self.tableView beginUpdates];
}

//------------------------------------------------------------------------------

- (void) controller:(NSFetchedResultsController*)controller
   didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
            atIndex:(NSUInteger)sectionIndex
      forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

//------------------------------------------------------------------------------

- (void) controller:(NSFetchedResultsController*)controller
    didChangeObject:(id)object
        atIndexPath:(NSIndexPath*)indexPath
      forChangeType:(NSFetchedResultsChangeType)type
       newIndexPath:(NSIndexPath*)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath]
                    atIndexPath:indexPath];
            break;
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
    }

    [self configureNoDealsImage];
}

//------------------------------------------------------------------------------

- (void) controllerDidChangeContent:(NSFetchedResultsController*)controller
{
    [self.tableView endUpdates];
}

//-----------------------------------------------------------------------------
#pragma mark - ScrollView Delegates
//-----------------------------------------------------------------------------

- (void) scrollViewDidScroll:(UIScrollView*)scrollView
{
    [mRefreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
}

//-----------------------------------------------------------------------------

- (void) scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) [self loadImagesForOnscreenRows];
    [mRefreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
}

//-----------------------------------------------------------------------------

- (void) scrollViewDidEndDecelerating:(UIScrollView*)scrollView
{
    [self loadImagesForOnscreenRows];
}

//------------------------------------------------------------------------------
#pragma mark - EGORefreshTableHeader Delegate
//------------------------------------------------------------------------------

- (void) egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
    [self reloadTableViewDataSource];
}

//------------------------------------------------------------------------------

- (BOOL) egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
    return mReloading;
}

//------------------------------------------------------------------------------

- (NSDate*) egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view
{
    return [NSDate date];
}

//------------------------------------------------------------------------------
#pragma mark - Data Source Loading / Reloading Methods
//------------------------------------------------------------------------------

- (void) reloadTableViewDataSource
{
    // don't try to reload twice
    if (mReloading) return;

    [Analytics passCheckpoint:@"Deal Header Reload"];

    mReloading = YES;

    // setup api object
    NSDate *lastUpdate     = [NSDate date];
    __block TikTokApi *api = [[[TikTokApi alloc] init] autorelease];
    api.completionHandler  = ^(NSDictionary *response) {
        [self doneLoadingTableViewData];
        [[Settings getInstance] setLastUpdate:lastUpdate];
    };

    // remove notification and close header
    api.errorHandler = ^(ASIHTTPRequest *request) {
        [self doneLoadingTableViewData];
    };

    // sync coupons
    Settings *settings = [Settings getInstance];
    [api syncActiveCoupons:settings.lastUpdate];
}

//------------------------------------------------------------------------------

- (void) doneLoadingTableViewData
{
    mReloading = NO;
    [mRefreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
}

//------------------------------------------------------------------------------

- (void) reloadFetchedResults
{
    // [moiz] should all of the image requests be cancelled?

    // force reload of results
    self.fetchedCouponsController = nil;
    [self.tableView reloadData];
}

//------------------------------------------------------------------------------
#pragma mark - table sorting / filtering
//------------------------------------------------------------------------------

- (void) updateFilterByReedmeedOnly:(bool)redeemedOnly activeOnly:(bool)activeOnly
{
    NSDate *now       = [NSDate date];
    NSDate *oneDayAgo = [now dateByAddingTimeInterval:(-1 * SECONDS_PER_DAY)];

    NSPredicate *predicate = nil;
    if (redeemedOnly && activeOnly) {
        predicate = [NSPredicate predicateWithFormat:
            @"wasRedeemed == %@ && endTime > %@", $numb(YES), now];
    } else if (redeemedOnly) {
        predicate = [NSPredicate predicateWithFormat:
            @"wasRedeemed == %@ && endTime > %@", $numb(YES), oneDayAgo];
    } else if (activeOnly) {
        predicate = [NSPredicate predicateWithFormat:
            @"endTime > %@", now];
    } else {
        predicate = [NSPredicate predicateWithFormat:
            @"endTime > %@", oneDayAgo];
    }

    // clear the cache, can't use cache with predicates...
    [NSFetchedResultsController deleteCacheWithName:sCouponCacheName];

    // update the fetch request
    NSFetchRequest *request = self.fetchedCouponsController.fetchRequest;
    request.predicate       = predicate;

    // update the request in the fetch controller
    NSError *error = nil;
    if (![self.fetchedCouponsController performFetch:&error]) {
        NSLog(@"CouponViewController: Fetching of coupons failed: %@, %@",
            error, [error userInfo]);
    }

    // reload the new data
    [self.tableView reloadData];
}

//------------------------------------------------------------------------------

- (void) filterPopup
{
    // lazy create popover controller
    if (self.popoverControllerFilter == nil) {
        [self setupFilterPopoverController];
    }

    // display popover if visible else dismiss
    if (!self.popoverControllerFilter.popoverVisible) {
        [self.popoverControllerFilter
            presentPopoverFromBarButtonItem:self.navigationItem.leftBarButtonItem
                   permittedArrowDirections:(UIPopoverArrowDirectionUp|UIPopoverArrowDirectionDown)
                                   animated:YES];
    } else {
        [self.popoverControllerFilter dismissPopoverAnimated:YES];
    }
}

//------------------------------------------------------------------------------

- (void) filterDealsRedeemed:(id)sender
{
    [Analytics passCheckpoint:@"Deal Filter Redeemed"];

    // [iOS4] deselecting causes another event to be trigged nullifing the result
    if ([sender selectedSegmentIndex] == UISegmentedControlNoSegment) {
        return;
    }

    // deselect segment
    [sender setSelectedSegmentIndex:UISegmentedControlNoSegment];

    // grab the filter buttons
    UIView *parentView = [sender superview];
    UISegmentedControl *activeButton   =
        (UISegmentedControl*)[parentView viewWithTag:kTagActiveFilter];
    UISegmentedControl *redeemedButton =
        (UISegmentedControl*)[parentView viewWithTag:kTagRedeemedFilter];

    // calculate the new states
    bool redeemedOnly = ![redeemedButton.tintColor isEqual:[UIDefaults getTikColor]];
    bool activeOnly   = [activeButton.tintColor isEqual:[UIDefaults getTikColor]];

    // update the color
    redeemedButton.tintColor = redeemedOnly ?
        [UIDefaults getTikColor] : [UIColor darkGrayColor];;

    [self updateFilterByReedmeedOnly:redeemedOnly activeOnly:activeOnly];
}

//------------------------------------------------------------------------------

- (void) filterDealsActive:(id)sender
{
    [Analytics passCheckpoint:@"Deal Filter Active"];

    // [iOS4] deselecting causes another event to be trigged nullifing the result
    if ([sender selectedSegmentIndex] == UISegmentedControlNoSegment) {
        return;
    }

    // deselect segment
    [sender setSelectedSegmentIndex:UISegmentedControlNoSegment];

    // grab the filter buttons
    UIView *parentView = [sender superview];
    UISegmentedControl *activeButton   =
        (UISegmentedControl*)[parentView viewWithTag:kTagActiveFilter];
    UISegmentedControl *redeemedButton =
        (UISegmentedControl*)[parentView viewWithTag:kTagRedeemedFilter];

    // calculate the new states
    bool redeemedOnly = [redeemedButton.tintColor isEqual:[UIDefaults getTikColor]];
    bool activeOnly   = ![activeButton.tintColor isEqual:[UIDefaults getTikColor]];

    // update the color
    activeButton.tintColor = activeOnly ?
        [UIDefaults getTikColor] : [UIColor darkGrayColor];

    [self updateFilterByReedmeedOnly:redeemedOnly activeOnly:activeOnly];
}

//------------------------------------------------------------------------------
#pragma mark - WEPopoverController Delegate
//------------------------------------------------------------------------------

- (void) popoverControllerDidDismissPopover:(WEPopoverController*)popoverController
{
}

//------------------------------------------------------------------------------

/**
 * The popover is automatically dismissed if you click outside it, unless you,
 * return NO here.
 */
- (BOOL) popoverControllerShouldDismissPopover:(WEPopoverController*)popoverController
{
    return YES;
}

//------------------------------------------------------------------------------
#pragma mark - Events
//------------------------------------------------------------------------------

/**
 * [moiz] something is breaking here, haven't been able to reproduce the error.
 *   May be related to ios version, possibly a corrupt install?
 */
- (void) redeemPromoCode:(id)sender
{
    // present promo controller
    PromoController *controller = [[PromoController alloc] init];

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

- (void) shareApp:(id)sender
{
    // setup action sheet handler
    UIActionSheetSelectionHandler handler = ^(NSInteger buttonIndex) {
        switch (buttonIndex) {
            case kActionButtonFacebook:
                [self shareFacebook];
                break;
            case kActionButtonTwitter:
                [self shareTwitter];
                break;
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
        [[UIActionSheet alloc] initWithTitle:@"Share the TikTok App with your friends!"
                                 withHandler:handler
                           cancelButtonTitle:@"Cancel"
                      destructiveButtonTitle:nil
                           otherButtonTitles:@"Facebook", @"Twitter", @"SMS", @"Email", nil];

    // show from toolbar
    [actionSheet showFromTabBar:self.tabBarController.tabBar];

    // cleanup
    [actionSheet release];
}

//------------------------------------------------------------------------------

- (void) shareTwitter
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

- (void) shareEmail
{
    // only send email if supported by the device
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *controller =
            [[MFMailComposeViewController alloc] init];

        // present the email controller
        [controller setSubject:$string(@"TikTok: Checkout this amazing daily deal app!")];
        NSString *details = $string(@"<h3>TikTok</h3>"
                                    @"<a href='http://www.tiktok.com/download?ref=%@'>"
                                    @"Get your deal on!</a>", [Utilities getConsumerId]);
        [controller setMessageBody:details isHTML:YES];

        // setup completion handler
        controller.completionHandler = ^(MFMailComposeViewController* controller,
                                         MFMailComposeResult result,
                                         NSError* error) {
            switch (result) {
                case MFMailComposeResultSaved:
                    break;
                case MFMailComposeResultSent: {
                    [Analytics passCheckpoint:@"App Emailed"];
                    break;
                }
                case MFMailComposeResultFailed:
                    NSLog(@"CouponViewController: email failed: %@", error);
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
        controller.body     = $string(@"TikTok: Checkout this awesome new daily "
                                      @"deal app: www.tiktok.com/download?ref=%@",
                                      [Utilities getConsumerId]);
        controller.completionHandler = ^(MFMessageComposeViewController* controller,
                                         MessageComposeResult result) {
            switch (result) {
                case MessageComposeResultSent: {
                    [Analytics passCheckpoint:@"App SMSed"];
                    break;
                }
                case MessageComposeResultFailed:
                    NSLog(@"CouponViewController: sms failed.");
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
        [Utilities displaySimpleAlertWithTitle:title andMessage:message];
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

    // setup twitter controller
    NSString *details = $string(@"TikTok: Checkout this new daily deals app!");
    [twitter setInitialText:details];
    [twitter addImage:[UIImage imageNamed:@"TopNavBarLogo"]];
    [twitter addURL:[NSURL URLWithString:$string(@"www.tiktok.com/download?ref=%@",
        [Utilities getConsumerId])]];

    // setup completion handler
    twitter.completionHandler = ^(TWTweetComposeViewControllerResult result) {
        switch (result) {
            case TWTweetComposeViewControllerResultCancelled:
                break;
            case TWTweetComposeViewControllerResultDone: {
                [Analytics passCheckpoint:@"App Tweeted"];

                // alert user of successful tweet
                NSString *title   = NSLocalizedString(@"TWITTER", nil);
                NSString *message = NSLocalizedString(@"TWITTER_APP_POST", nil);
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
    [Analytics passCheckpoint:@"App Facebooked"];

    NSString *icon    = @"https://www.tiktok.com/images/logo.png";
    NSString *link    = $string(@"http://www.tiktok.com/download?ref=%@", [Utilities getConsumerId]);
    NSString *details = $string(@"Checkout this new daily deals app TikTok!");
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
        link,      @"link",
        @"TikTok", @"name",
        icon,      @"picture",
        link,      @"caption",
        details,   @"description",
        nil];

    // post share on facebook
    FacebookManager *manager = [FacebookManager getInstance];
    [manager.facebook dialog:@"feed" andParams:params andDelegate:self];
}

//------------------------------------------------------------------------------
#pragma - Facebook delegate
//------------------------------------------------------------------------------

- (void) dialogCompleteWithUrl:(NSURL*)url
{
    // make sure post actually went through.. fucking pos facebook...
    NSString *query = url.query;
    if (!query || ([query rangeOfString:@"post_id"].location == NSNotFound)) {
        return;
    }

    // alert user of successful facebook post
    NSString *title   = NSLocalizedString(@"FACEBOOK", nil);
    NSString *message = NSLocalizedString(@"FACEBOOK_APP_POST", nil);
    [Utilities displaySimpleAlertWithTitle:title
                                andMessage:message];

    NSLog(@"CouponViewController: facebook request did load");
}

//------------------------------------------------------------------------------

- (void) dialog:(FBDialog*)dialog didFailWithError:(NSError*)error
{
    NSLog(@"CouponViewController: Facebook share failed: %@", error);
}

//------------------------------------------------------------------------------

- (BOOL) dialog:(FBDialog*)dialog shouldOpenURLInExternalBrowser:(NSURL*)url
{
    return NO;
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
    // for example: self.myOutlet = nil;
}

//------------------------------------------------------------------------------

- (void) dealloc
{
    mPopoverControllerFilter.delegate  = nil;
    mFetchedCouponsController.delegate = nil;

    [mPopoverControllerFilter release];
    [mFetchedCouponsController release];
    [mRefreshHeaderView release];
    [mTableView release];
    [mCellView release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end

