//
//  LogViewController.m
//  TikTok
//
//  Created by Moiz Merchant on 05/02/12.
//  Copyright (c) 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "LogViewController.h"
#import "Logger.h"

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface LogViewController ()
    - (void) setLog:(NSString*)log;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation LogViewController

//------------------------------------------------------------------------------

@synthesize tableView = mTableView;

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
    // setup navigation info
    self.title = @"Log";

    // setup a dictionary for each naming of the rows
    [self setLog:[Logger getLog]];
}

//------------------------------------------------------------------------------

/*
- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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

- (void) setLog:(NSString*)log
{
    // clean up old data
    if (mTableData != nil) [mTableData release];

    // chop into array of lines
    mTableData = [[log componentsSeparatedByString:@"\n"] retain];
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
    return [mTableData count];
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
    UITableViewCell *cell = [self getReusableCell];
    cell.textLabel.text = [mTableData objectAtIndex:[mTableData count] - indexPath.row - 1];
    cell.textLabel.font = [UIFont fontWithName:@"Helvetica" size:10];
    return cell;
}

//------------------------------------------------------------------------------

- (UITableViewCell*) getReusableCell
{
    static NSString *sCellId = @"log";

    // check if reuasable cell exists
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:sCellId];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
            reuseIdentifier:sCellId] autorelease];
    }
    return cell;
}

//------------------------------------------------------------------------------

/**
 * Override to support conditional editing of the table view.
- (BOOL) tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
    // table rows are not editable
    return NO;
}
*/

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
- (void) tableView:(UITableView*)tableView
    moveRowAtIndexPath:(NSIndexPath*)fromIndexPath
           toIndexPath:(NSIndexPath*)toIndexPath
{
    // items cannot be moved
}
*/

//------------------------------------------------------------------------------

/**
 * Override to support conditional rearranging of the table view.
- (BOOL) tableView:(UITableView*)tableView canMoveRowAtIndexPath:(NSIndexPath*)indexPath
{
    // items cannot be re-ordered
    return NO;
}
*/

//------------------------------------------------------------------------------
#pragma mark - TableView Delegate
//------------------------------------------------------------------------------

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
}

//------------------------------------------------------------------------------

/*
- (CGFloat) tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section
{
}
*/

//------------------------------------------------------------------------------

/**
 * Customize the appearance of the table header.
- (UIView*) tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
}
*/

//------------------------------------------------------------------------------
#pragma mark - Events
//------------------------------------------------------------------------------

- (IBAction) clear:(id)sender
{
    [Logger clearLog];
    [self setLog:[Logger getLog]];
	[mTableView reloadData];
}

//------------------------------------------------------------------------------

- (IBAction) close:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
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
    [mTableView release];
    [mTableData release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
