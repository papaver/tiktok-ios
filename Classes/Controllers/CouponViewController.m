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

#import "TikTokAppDelegate.h"
#import "Coupon.h"
#import "CouponViewController.h"
#import "CouponTableViewCell.h"
#import "CouponDetailViewController.h"
#import "GradientView.h"
#import "IconManager.h"
#import "Merchant.h"
#import "TikTokApi.h"
#import "UIDefaults.h"

//------------------------------------------------------------------------------
// enums
//------------------------------------------------------------------------------

enum CouponTag {
    kTagIcon         = 1,
    kTagTitle        = 2,
    kTagTextTime     = 3,
    kTagTextTimer    = 4,
    kTagColorTimer   = 5,
    kTagIconActivity = 6
};

//------------------------------------------------------------------------------
// interface definition 
//------------------------------------------------------------------------------

@interface CouponViewController ()
    - (void) updateExpiration:(NSTimer*)timer;
    - (void) configureCell:(UIView*)cell atIndexPath:(NSIndexPath*)indexPath;
    - (void) configureExpiredCell:(UIView*)cell;
    - (void) configureActiveCell:(UIView*)cell withCoupon:(Coupon*)coupon;
    - (void) updateActiveCell:(UIView*)cell withCoupon:(Coupon*)coupon;
    - (void) setIcon:(UIImage*)image forCell:(UIView*)cell;
    - (void) setupIconForCell:(UIView*)cell atIndexPath:(NSIndexPath*)indexPath withCoupon:(Coupon*)coupon;
    - (void) requestImageForCoupon:(Coupon*)coupon atIndexPath:(NSIndexPath*)indexPath;
    - (void) loadImagesForOnscreenRows;
@end 

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation CouponViewController

//------------------------------------------------------------------------------

@synthesize cellView                 = mCellView;
@synthesize fetchedCouponsController = mFetchedCouponsController;

//------------------------------------------------------------------------------
#pragma mark - View lifecycle
//------------------------------------------------------------------------------

/**
 * Only runs after view is loaded.
 */
- (void) viewDidLoad
{
    [super viewDidLoad];

    // [moiz] not sure if this is the best way to add a background to the table
    self.view.backgroundColor = 
        [UIColor colorWithPatternImage:[UIImage imageNamed:@"CouponTableBackground.png"]];

    // patch font in cell
    UILabel *timer = (UILabel*)[self.cellView viewWithTag:kTagTextTimer];
    timer.font     = [UIFont fontWithName:@"NeutraDisp-BoldAlt" size:20];

    // [moiz] purge files 
    IconManager *iconManager = [IconManager getInstance];
    [iconManager deleteAllImages];
}

//------------------------------------------------------------------------------

- (void) viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];

    // hide navigation toolbar
    [self.navigationController setToolbarHidden:YES animated:YES];
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
        cell.selectionStyle  = UITableViewCellSelectionStyleBlue;
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
    // grab coupon at the given index path
    Coupon* coupon = [self.fetchedCouponsController objectAtIndexPath:indexPath];

    // set coupon on cell
    cell.coupon = coupon;

    // invaliate the timer
    [cell.timer invalidate];

    // update the coupon title
    UITextView *title = (UITextView*)[cell viewWithTag:kTagTitle];
    [title setText:coupon.title];

    // setup icon
    [self setupIconForCell:cell atIndexPath:indexPath withCoupon:coupon];

    // update the cell to reflect the state of the coupon
    if ([coupon isExpired]) {
        [self configureExpiredCell:cell];
    } else {
        [self configureActiveCell:cell withCoupon:coupon];

        // create update loop for timers
        cell.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                    selector:@selector(updateExpiration:)
                                                    userInfo:cell
                                                     repeats:YES];
    }
}


//------------------------------------------------------------------------------

- (void) updateExpiration:(NSTimer*)timer
{
    CouponTableViewCell* cell = (CouponTableViewCell*)timer.userInfo;

    // grab coupon at the given index path
    Coupon *coupon = cell.coupon;
    if (coupon == nil) return;

    /* only update the view if its visibile
    UIView *view = [cell viewWithTag:kTagTextTime];
    CGRect rect  = [view convertRect:view.frame toView:self.view.superview];
    bool visible = CGRectIntersectsRect(self.view.superview.frame, rect);
    if (!visible) return;
    */

    // update the cell to reflect the state of the coupon
    if ([coupon isExpired]) {
        [self configureExpiredCell:cell];
        [timer invalidate];
    } else {
        [self configureActiveCell:cell withCoupon:coupon];
    }
}


//------------------------------------------------------------------------------

- (void) configureExpiredCell:(UIView*)cell
{
    const static CGFloat expiredAlpha = 0.3;
    static NSString *offerText        = @"Offer has expired.";
    static NSString *timerText        = @"00:00:00";

    // expire text
    UILabel *textTime = (UILabel*)[cell viewWithTag:kTagTextTime];
    textTime.text     = offerText;

    // expire timer
    UILabel *textTimer = (UILabel*)[self.view viewWithTag:kTagTextTimer];
    textTimer.text     = timerText;

    // color timer
    GradientView *color = (GradientView*)[cell viewWithTag:kTagColorTimer];
    color.color         = [UIDefaults getTokColor];

    // update the cell opacity
    for (UIView *view in cell.subviews) {
        view.alpha = expiredAlpha;
    }
}

//------------------------------------------------------------------------------

- (void) configureActiveCell:(UIView*)cell withCoupon:(Coupon*)coupon 
{
    // fix the opacity
    for (UIView *view in cell.subviews) {
        view.alpha = 1.0;
    }

    // expire time
    UILabel *expire = (UILabel*)[cell viewWithTag:kTagTextTime];
    expire.text     = $string(@"Offer expires at %@", [coupon getExpirationTime]);

    // configure the timers
    [self updateActiveCell:cell withCoupon:coupon];
}

//------------------------------------------------------------------------------

- (void) updateActiveCell:(UIView*)cell withCoupon:(Coupon*)coupon 
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
    NSURL *imageUrl          = [NSURL URLWithString:coupon.imagePath];
    __block UIImage *image   = [iconManager getImage:imageUrl];

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
    IconManager *iconManager = [IconManager getInstance];
    NSURL *imageUrl          = [NSURL URLWithString:coupon.imagePath];

    // submit the request to retrive the image and update the cell
    [iconManager requestImage:imageUrl 
        withCompletionHandler:^(UIImage* image, NSError *error) {
            if (image) {
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                [self setIcon:image forCell:cell];
            } else if (error) {
                NSLog(@"CouponViewController: Failed to load image: %@", error);
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
            UIImage *image = [iconManager getImage:[NSURL URLWithString:coupon.imagePath]];
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
    // -- temp --
    NSManagedObjectContext *managedObjectContext = 
        [((TikTokAppDelegate*)[[UIApplication sharedApplication] delegate]) 
        managedObjectContext];

    // check if controller already created
    if (mFetchedCouponsController) {
        return mFetchedCouponsController;
    }

    // create an entity description object
    NSEntityDescription *description = [NSEntityDescription 
        entityForName:@"Coupon" inManagedObjectContext:managedObjectContext];
                                                   
    // create a sort descriptor
    NSSortDescriptor *sortByStartDate = [[[NSSortDescriptor alloc] 
        initWithKey:@"endTime" ascending:NO]
        autorelease];
    NSArray *sortDescriptors = [[[NSArray alloc] 
        initWithObjects:sortByStartDate, nil] 
        autorelease];

    // create a fetch request
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    request.entity          = description;
    request.fetchBatchSize  = 10;
    request.sortDescriptors = sortDescriptors;

    // create a results controller from the request
    self.fetchedCouponsController = [[NSFetchedResultsController alloc] 
        initWithFetchRequest:request 
        managedObjectContext:managedObjectContext 
          sectionNameKeyPath:nil
                   cacheName:@"coupon_table"];
    self.fetchedCouponsController.delegate = self;

    // preform the fetch
    NSError *error = nil;
    if (![mFetchedCouponsController performFetch:&error]) {
        NSLog(@"Fetching of coupons failed: %@, %@", error, [error userInfo]);
        abort();
    }

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
}

//------------------------------------------------------------------------------

- (void) controllerDidChangeContent:(NSFetchedResultsController*)controller 
{
    [self.tableView endUpdates];
}

//-----------------------------------------------------------------------------
#pragma mark - ScrollView Delegates
//-----------------------------------------------------------------------------

- (void) scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self loadImagesForOnscreenRows];
    }
}

//-----------------------------------------------------------------------------

- (void) scrollViewDidEndDecelerating:(UIScrollView*)scrollView
{
    [self loadImagesForOnscreenRows];
}

//------------------------------------------------------------------------------
#pragma mark - Memory Management
//------------------------------------------------------------------------------

- (void) didReceiveMemoryWarning 
{
    // releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // relinquish ownership any cached data, images, etc that aren't in use.
}

//------------------------------------------------------------------------------

- (void) viewDidUnload 
{
    // relinquish ownership of anything that can be recreated in viewDidLoad 
    //  or on demand.
    // for example: self.myOutlet = nil;
}

//------------------------------------------------------------------------------

- (void) dealloc 
{
    [mFetchedCouponsController release];
    [mCellView release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end

