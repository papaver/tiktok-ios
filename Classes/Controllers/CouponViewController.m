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
#import "CouponViewController.h"
#import "CouponTableViewCell.h"
#import "CouponDetailViewController.h"
#import "TikTokApi.h"
#import "Merchant.h"
#import "Coupon.h"
#import "UIDefaults.h"

//------------------------------------------------------------------------------
// enums
//------------------------------------------------------------------------------

enum CouponTag {
    kCouponTagIcon        = 1,
    kCouponTagTitle       = 2,
    kCouponTagExpireText  = 3,
    kCouponTagExpireTimer = 4,
    kCouponTagExpireColor = 5,
};

//------------------------------------------------------------------------------
// interface definition 
//------------------------------------------------------------------------------

@interface CouponViewController ()
    - (void) updateExpiration:(NSTimer*)timer;
    - (void) configureExpiredCell:(UIView*)cell;
    - (void) configureActiveCell:(UIView*)cell withCoupon:(Coupon*)coupon;
    - (UIColor*) getInterpolatedColor:(CGFloat)t;
@end 

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation CouponViewController

//------------------------------------------------------------------------------

@synthesize cellView                 = m_cell_view;
@synthesize headerView               = m_header_view;
@synthesize fetchedCouponsController = m_fetched_coupons_controller;

@synthesize backgroundView           = m_background_view;

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
}

//------------------------------------------------------------------------------

- (void) viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];

    // [moiz] don't hide the navigation bar on top anymore..
    //[self.navigationController setNavigationBarHidden:YES animated:YES];
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

    // [moiz] don't hide the navigation bar on top anymore..
    //[self.navigationController setNavigationBarHidden:NO animated:YES];
}

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

- (void) updateExpiration:(NSTimer*)timer
{
    CouponTableViewCell* cell = (CouponTableViewCell*)timer.userInfo;

    // grab coupon at the given index path
    Coupon *coupon = cell.coupon;
    if (coupon == nil) return;

    // only update the view if its visibile
    UIView *view = [cell viewWithTag:kCouponTagExpireText];
    CGRect rect  = [view convertRect:view.frame toView:self.view.superview];
    bool visible = CGRectIntersectsRect(self.view.superview.frame, rect);
    if (!visible) return;

    // check if the coupon has already expired
    NSTimeInterval seconds = [coupon.endTime timeIntervalSinceNow];
    bool isExpired         = seconds <= 0.0;

    // [moiz] need to make sure that we know when its been
    //  expired
    
    // update the cell to reflect the state of the coupon
    if (isExpired) {
        //[self configureExpiredCell:cell];
    } else {
        [self configureActiveCell:cell withCoupon:coupon];
    }
}

//------------------------------------------------------------------------------

/**
 * Customize the appearance of table view cells.
 */
- (UITableViewCell*) tableView:(UITableView*)tableView 
         cellForRowAtIndexPath:(NSIndexPath*)indexPath 
{
    static NSString *s_cell_id = @"coupon_cell";
    
    // only create as many coupons as are in view at the same time
    CouponTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:s_cell_id];
    if (cell == nil) {
        NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:self.cellView];
        cell = [NSKeyedUnarchiver unarchiveObjectWithData:archivedData];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;

        [NSTimer scheduledTimerWithTimeInterval:1.0
                                         target:self
                                       selector:@selector(updateExpiration:)
                                       userInfo:cell
                                        repeats:YES];
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

- (UIColor*) getInterpolatedColor:(CGFloat)t
{
    UIColor *tik    = [UIDefaults getTikColor];
    UIColor *yellow = [UIColor yellowColor];
    UIColor *orange = [UIColor orangeColor];
    UIColor *tok    = [UIDefaults getTokColor];

    struct ColorTable {
        CGFloat t, offset;
        UIColor *start, *end;
    } s_color_table[3] = {
        { 0.33, 0.00, tik,    yellow },
        { 0.66, 0.33, yellow, orange },
        { 1.00, 0.66, orange, tok    },
    };

    NSUInteger index = 0;
    for (; index < 3; ++index) {
        if (t > s_color_table[index].t) continue;

        UIColor *start = s_color_table[index].start;
        UIColor *end   = s_color_table[index].end;
        CGFloat new_t  = (t - s_color_table[index].offset) / 0.33;
        return [start colorByInterpolatingToColor:end
                                       byFraction:new_t];
    }

    return [UIColor blackColor];
}

//------------------------------------------------------------------------------

- (void) configureExpiredCell:(UIView*)cell
{
    const static CGFloat expired_alpha = 0.2;
    static NSString *offerText   = @"Offer has expired";
    static NSString *timerText   = @"00:00:00";

    // update expire text
    UITextView *expire_text = (UITextView*)[cell viewWithTag:kCouponTagExpireText];
    [expire_text setText:offerText];

    // update expire timer
    UILabel *expire_timer = (UILabel*)[cell viewWithTag:kCouponTagExpireTimer];
    [expire_timer setText:timerText];

    // update the coupon expire color
    UIView *expire_color         = [cell viewWithTag:kCouponTagExpireColor];
    expire_color.backgroundColor = [UIDefaults getTokColor];

    // update the cell opacity
    for (UIView *view in cell.subviews) {
        view.alpha = expired_alpha;
    }
}

//------------------------------------------------------------------------------

- (void) configureActiveCell:(UIView*)cell withCoupon:(Coupon*)coupon 
{
    NSTimeInterval seconds_left  = [coupon.endTime timeIntervalSinceNow];
    NSTimeInterval total_seconds = [coupon.endTime timeIntervalSinceDate:coupon.startTime];
    CGFloat minutes_left         = seconds_left / 60.0;
    CGFloat t                    = 1.0 - (seconds_left / total_seconds);

    // update the coupon expire timer
    UILabel *expire_timer = (UILabel*)[cell viewWithTag:kCouponTagExpireTimer];
    [expire_timer setText:$string(@"%.2d:%.2d:%.2d", 
        (int)minutes_left / 60, (int)minutes_left % 60, (int)seconds_left % 60)];

    // update the coupon expire color
    UIView *expire_color         = [cell viewWithTag:kCouponTagExpireColor];
    expire_color.backgroundColor = [self getInterpolatedColor:t];

    // update the cell opacity
    for (UIView *view in cell.subviews) {
        view.alpha = 1.0 - MIN(t, 0.6);
    }
}

//------------------------------------------------------------------------------

/**
  * Initializes cell with coupon information.
  */
- (void) configureCell:(CouponTableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    // [moiz] use a random icon for now...
    UIImage *image = nil;
    switch (indexPath.row % 3) {
        case 0:
            image = [UIImage imageNamed:@"Icon01.png"];
            break;
        case 1:
            image = [UIImage imageNamed:@"Icon02.png"];
            break;
        case 2:
            image = [UIImage imageNamed:@"Icon03.png"];
            break;
    }

    // grab coupon at the given index path
    Coupon* coupon = [self.fetchedCouponsController 
        objectAtIndexPath:indexPath];

    // set coupon on cell
    cell.coupon = coupon;

    // update the coupon image
    UIImageView *icon = (UIImageView*)[cell viewWithTag:kCouponTagIcon];
    [icon setImage:image];
        
    // update the coupon title
    UITextView *title = (UITextView*)[cell viewWithTag:kCouponTagTitle];
    [title setText:coupon.text];

    // [moiz] what to do about people changing the time on thier phones?

    // check if the coupon has already expired
    NSTimeInterval seconds = [coupon.endTime timeIntervalSinceNow];
    bool isExpired         = seconds <= 0.0;
    
    // update the cell to reflect the state of the coupon
    if (isExpired) {
        [self configureExpiredCell:cell];
    } else {
        [self configureActiveCell:cell withCoupon:coupon];

        // setup date formatter
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        NSString *end_time = [formatter stringForObjectValue:coupon.endTime];

        // update the coupon expire time
        UITextView *expire_text = (UITextView*)[cell viewWithTag:kCouponTagExpireText];
        [expire_text setText:$string(@"Offer expires at %@", end_time)];
    }
}

//------------------------------------------------------------------------------

/**
  * Initializes header with coupon information.
  */
- (void) configureHeader:(UIView*)header atSection:(NSUInteger)section
{
    /*
    // get merchant at index
    Coupon* coupon = [self.fetchedCouponsController 
        objectAtIndexPath:[self getMerchantIndexPath:section]];
    Merchant *merchant = coupon.merchant;

    // update the merchant icon
    UIImageView *imageView = (UIImageView*)[header viewWithTag:1];
    [imageView setImage:merchant.image];

    // update the merchant name
    UILabel *label = (UILabel*)[header viewWithTag:2];
    [label setText:merchant.name];
    */
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
 */
- (UIView*) tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    // we have to do this because the unarchiving breaks when a new section
    //  is automatically added by the fetcher :|
    NSData *archivedData       = [NSKeyedArchiver archivedDataWithRootObject:self.headerView];
    UIView *headerTemplate     = [NSKeyedUnarchiver unarchiveObjectWithData:archivedData];
    UIImageView *imageTemplate = (UIImageView*)[headerTemplate viewWithTag:1];
    UILabel *labelTemplate     = (UILabel*)[headerTemplate viewWithTag:2];

    // allocate a new header
    UIView *header = 
        [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30)] autorelease];
    header.backgroundColor = headerTemplate.backgroundColor;

    // setup merchant image
    UIImageView *image = [[[UIImageView alloc] initWithFrame:imageTemplate.frame] autorelease];
    image.tag          = imageTemplate.tag;
    [header addSubview:image];

    // setup merchant label
    UILabel *label        = [[[UILabel alloc] initWithFrame:labelTemplate.frame] autorelease];
    label.font            = labelTemplate.font;
    label.tag             = labelTemplate.tag;
    label.backgroundColor = headerTemplate.backgroundColor;
    label.textColor       = labelTemplate.textColor;
    [header addSubview:label];

    // configure the header
    [self configureHeader:header atSection:section];

    return header;
}

//------------------------------------------------------------------------------

/**
 * Customize the height of the header.
 */
- (CGFloat) tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    // [moiz] we are no longer using the header...
    //return self.headerView.frame.size.height;
    return 0;
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
    if (m_fetched_coupons_controller) {
        return m_fetched_coupons_controller;
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
    if (![m_fetched_coupons_controller performFetch:&error]) {
        NSLog(@"Fetching of coupons failed: %@, %@", error, [error userInfo]);
        abort();
    }

    return m_fetched_coupons_controller;
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
    [super dealloc];
}

//------------------------------------------------------------------------------

@end

