//
//  KarmaViewController.m
//  TikTok
//
//  Created by Moiz Merchant on 02/14/12.
//  Copyright (c) 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "KarmaViewController.h"
#import "ASIHTTPRequest.h"
#import "TikTokApi.h"
#import "Utilities.h"
#import "WebViewController.h"

//------------------------------------------------------------------------------
// enums
//------------------------------------------------------------------------------

enum ViewTag
{
    kTagIcon      = 1,
    kTagTitle     = 2,
    kTagSubtitle  = 3,
    kTagKarmaCopy = 4,
};

enum TableRow
{
    kRowTwitter  = 0,
    kRowFacebook = 1,
    kRowEmail    = 2,
    kRowSMS      = 3,
    kRowReferral = 4,
};

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface KarmaViewController ()
    - (void) setupToolbar;
    - (void) syncKarmaPoints;
    - (UITableViewCell*) getReusableCell;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation KarmaViewController

//------------------------------------------------------------------------------

@synthesize tableView  = mTableView;
@synthesize cellView   = mCellView;

//------------------------------------------------------------------------------
#pragma mark - Initialization
//------------------------------------------------------------------------------

- (id) initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

//------------------------------------------------------------------------------
#pragma mark - View lifecycle
//------------------------------------------------------------------------------

/**
 * Only runs after view is loaded.
 */
- (void) viewDidLoad
{
    [Analytics passCheckpoint:@"Karma"];

    // setup navigation info
    self.title = @"Karma";

    // [iOS4] fix for black corners 
    self.tableView.backgroundColor = [UIColor clearColor];

    // [iOS4] fix for missing font bradley hand bold
    UILabel *copy = (UILabel*)[self.view viewWithTag:kTagKarmaCopy];
    if (copy.font == nil) {
        copy.font  = [UIFont fontWithName:@"BradleyHandITCTTBold" size:18];
    }

    // setup a dictionary for each naming of the rows
    mTableData   = [$array(@"Twitter", @"Facebook", @"SMS", @"Email", @"Referrals") retain];
    mIconData    = [$array(@"210-twitterbird", @"208-facebook", @"286-speechbubble", @"18-envelope", @"108-badge") retain];
    mKarmaPoints = [$array(@"-", @"-", @"-", @"-", @"-") retain];

    // setup toolbar
    [self setupToolbar];

    // sync the points from the server
    [self syncKarmaPoints];
}

//------------------------------------------------------------------------------

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

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
#pragma mark - Helper Functions
//------------------------------------------------------------------------------

- (void) setupToolbar
{
    UIBarButtonItem *reloadButton =
        [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"01-refresh-bar.png"]
                                         style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(syncKarmaPoints)];

    // add to navbar
    self.navigationItem.rightBarButtonItem = reloadButton;

    // cleanup
    [reloadButton release];
}

//------------------------------------------------------------------------------

- (void) syncKarmaPoints
{
    // setup an instance of the tiktok api to register the device
    TikTokApi *api = [[[TikTokApi alloc] init] autorelease];

    // setup a completion handler to save points
    api.completionHandler = ^(NSDictionary *response) {

        // verify sync succeeded
        NSString *status = [response objectForKey:kTikTokApiKeyStatus];
        NSLog(@"status: %@", status);
        if ([status isEqualToString:kTikTokApiStatusOkay]) {

            // grab points
            NSDictionary *results = [response objectForKey:kTikTokApiKeyResults];
            NSString *twitter     = $string(@"%@", [results objectForKey:@"tw"]);
            NSString *facebook    = $string(@"%@", [results objectForKey:@"fb"]);
            NSString *sms         = $string(@"%@", [results objectForKey:@"sms"]);
            NSString *email       = $string(@"%@", [results objectForKey:@"email"]);
            NSString *referral    = $string(@"%@", [results objectForKey:@"referral"]);

            // cache for easy access
            [mKarmaPoints release];
            mKarmaPoints = [$array(twitter, facebook, sms, email, referral) retain];

            // refresh table
            [self.tableView reloadData];

        // something bad happened...
        } else {
            NSString *title   = NSLocalizedString(@"KARMA_POINTS", nil);
            NSString *message = NSLocalizedString(@"KARMA_SYNC_FAIL", nil);
            [Utilities displaySimpleAlertWithTitle:title andMessage:message];
        }
    };

    // alert user if sync failed
    api.errorHandler = ^(ASIHTTPRequest* request) {
        NSString *title   = NSLocalizedString(@"KARMA_POINTS", nil);
        NSString *message = NSLocalizedString(@"KARMA_SYNC_FAIL", nil);
        [Utilities displaySimpleAlertWithTitle:title andMessage:message];
    };

    // sync karma points from server
    [api syncKarmaPoints];
}

//------------------------------------------------------------------------------

- (IBAction) karmaDetails:(id)sender
{
    // setup a webview controller
    WebViewController *controller = [[WebViewController alloc] init];
    controller.title              = @"Karma Points";
    controller.url                = @"http://www.tiktok.com/karma_details";

    // present the webview
    [self.navigationController pushViewController:controller animated:YES];

    // cleanup
    [controller release];
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
    return mTableData.count;
}

//------------------------------------------------------------------------------

/**
 * Customize the height of the cell at the given index.
 * /
- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
}
*/

//------------------------------------------------------------------------------

/**
 * Customize the appearance of table view cells.
 */
- (UITableViewCell*) tableView:(UITableView*)tableView
         cellForRowAtIndexPath:(NSIndexPath*)indexPath
{

    // grab the title from the table data
    UITableViewCell *cell = [self getReusableCell];
    UIImageView *icon     = (UIImageView*)[cell viewWithTag:kTagIcon];
    UILabel *title        = (UILabel*)[cell viewWithTag:kTagTitle];
    UILabel *subtitle     = (UILabel*)[cell viewWithTag:kTagSubtitle];

    icon.image    = [UIImage imageNamed:[mIconData objectAtIndex:indexPath.row]];
    title.text    = [mTableData objectAtIndex:indexPath.row];
    subtitle.text = [mKarmaPoints objectAtIndex:indexPath.row];

    return cell;
}

//------------------------------------------------------------------------------

- (UITableViewCell*) getReusableCell
{
    static NSString *sCellId = @"karma";

    // check if reuasable cell exists
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:sCellId];
    if (!cell) {
        NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:self.cellView];
        cell = [NSKeyedUnarchiver unarchiveObjectWithData:archivedData];
    }
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
#pragma mark - TableView Delegate
//------------------------------------------------------------------------------

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
}

//------------------------------------------------------------------------------

- (CGFloat) tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0f;
}

//------------------------------------------------------------------------------

/**
 * Customize the appearance of the table header.
 */
- (UIView*) tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
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
}

//------------------------------------------------------------------------------

- (void) dealloc
{
    [mKarmaPoints release];
    [mTableView release];
    [mCellView release];
    [mIconData release];
    [mTableData release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
