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
#import "CouponDetailViewController.h"
#import "TikTokApi.h"
#import "Merchant.h"
#import "Coupon.h"

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

    // add the background view
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
    [self.navigationController setNavigationBarHidden:NO animated:YES];
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
 * Constructs the index path for the merchant. This will always correspond
 * to the index into section 0, since there is only one section.
 */
- (NSIndexPath*) getMerchantIndexPath:(NSUInteger)section
{
    NSUInteger indexes[2] = { section, 0 };
    NSIndexPath *indexPath = [[[NSIndexPath alloc] 
        initWithIndexes:indexes length:2] 
        autorelease];

    return indexPath;
}

//------------------------------------------------------------------------------

/**
 * Customize the number of sections in the table view.
 */
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView 
{
    // [moiz] we only have one section now... we also want to turn the header 
    //  off, already forgot how to do that, sigh... working with multiple 
    //  frameworks at the same time is mind numbing
    
    return 1;

    /*
    NSInteger sections = [[self.fetchedCouponsController sections] count];
    return sections;
    */
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
    return self.cellView.contentView.frame.size.height;
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:s_cell_id];
    if (cell == nil) {
        NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:self.cellView];
        cell = [NSKeyedUnarchiver unarchiveObjectWithData:archivedData];
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

/**
  * Initializes cell with coupon information.
  */
- (void) configureCell:(UIView*)cell atIndexPath:(NSIndexPath*)indexPath
{
    // grab coupon at the given index path
    Coupon* coupon = [self.fetchedCouponsController 
        objectAtIndexPath:indexPath];

    // update the coupon image
    UIImageView *imageView = (UIImageView*)[cell viewWithTag:1];
    //[imageView setImage:coupon.image];
        
    // update the coupon text
    UITextView *textView = (UITextView*)[cell viewWithTag:2];
    [textView setText:coupon.text];
}

//------------------------------------------------------------------------------

/**
  * Initializes header with coupon information.
  */
- (void) configureHeader:(UIView*)header atSection:(NSUInteger)section
{
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
        initWithKey:@"startTime" ascending:NO]
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

