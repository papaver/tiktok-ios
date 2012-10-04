//
//  CategoryViewController.m
//  TikTok
//
//  Created by Moiz Merchant on 10/03/12.
//  Copyright (c) 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "CategoryViewController.h"

//------------------------------------------------------------------------------
// enums
//------------------------------------------------------------------------------

enum ViewTag
{
    kTagTitle  = 1,
    kTagSwitch = 2,
};

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation CategoryViewController

//------------------------------------------------------------------------------

@synthesize tableView        = mTableView;
@synthesize cellView         = mCellView;
@synthesize doneButton       = mDoneButton;
@synthesize data             = mData;
@synthesize currentSelection = mCurrentSelections;
@synthesize selectionHandler = mSelectionHandler;

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
    [super viewDidLoad];

    // add done button
    self.navigationItem.rightBarButtonItem = self.doneButton;
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
    return mData.count;
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
    // update the category and state
    UITableViewCell *cell = [self getReusableCell];
    UILabel *title        = (UILabel*)[cell viewWithTag:kTagTitle];
    UISwitch *swich       = (UISwitch*)[cell viewWithTag:kTagSwitch];

    // update the text
    title.text = [mData objectAtIndex:indexPath.row];
    swich.on   = [mCurrentSelections indexOfObject:title.text] != NSNotFound;

    return cell;
}

//------------------------------------------------------------------------------

- (UITableViewCell*) getReusableCell
{
    static NSString *sCellId = @"category";

    // check if reuasable cell exists
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:sCellId];
    if (!cell) {
        NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:self.cellView];
        cell = [NSKeyedUnarchiver unarchiveObjectWithData:archivedData];

        // connect delegate
        UISwitch *swich = (UISwitch*)[cell viewWithTag:kTagSwitch];
        [swich addTarget:self action:@selector(selectSwitch:)
            forControlEvents:UIControlEventValueChanged];
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

/*
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
}
*/

//------------------------------------------------------------------------------

/**
 * Customize the appearance of the table header.
 * /
- (UIView*) tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
}
*/

//------------------------------------------------------------------------------
#pragma mark - Events
//------------------------------------------------------------------------------

- (IBAction) selectSwitch:(id)sender
{
    UISwitch *swich       = (UISwitch*)sender;
    UITableViewCell *cell = (UITableViewCell*)swich.superview;
    UILabel *category     = (UILabel*)[cell viewWithTag:kTagTitle];

    // add entry from selection if on else remove entry
    if (swich.on) {
        [mCurrentSelections addObject:category.text];
    } else {
        [mCurrentSelections removeObject:category.text];
    }
}

//------------------------------------------------------------------------------

- (IBAction) done:(id)sender
{
    // run the selection handler
    if (self.selectionHandler) self.selectionHandler(self.currentSelection);

    // pop off the controller
    [self.navigationController popViewControllerAnimated:YES];
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
    [mSelectionHandler release];
    [mCurrentSelections release];
    [mData release];
    [mDoneButton release];
    [mCellView release];
    [mTableView release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
