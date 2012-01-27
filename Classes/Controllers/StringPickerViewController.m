//
//  StringPickerViewController.m
//  TikTok
//
//  Created by Moiz Merchant on 1/12/12.
//  Copyright (c) 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "StringPickerViewController.h"

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation StringPickerViewController

//------------------------------------------------------------------------------

@synthesize tableView        = mTableView;
@synthesize data             = mData;
@synthesize currentSelection = mCurrentSelection;
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
    static NSString *sCellId = @"stringCellId";

    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:sCellId];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
            reuseIdentifier:sCellId] autorelease];
    }

    // update the text
    cell.textLabel.text = [mData objectAtIndex:indexPath.row];

    // check the cell if current option
    if ([cell.textLabel.text caseInsensitiveCompare:self.currentSelection] == NSOrderedSame) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
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
    // grab cell at indexpath
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];

    // only update if selection has changed 
    if (cell.textLabel.text != self.currentSelection) {

        // update the current selection
        self.currentSelection = cell.textLabel.text;
    
        // run the selection handler
        if (self.selectionHandler) self.selectionHandler(self.currentSelection);

        // reload data to make sure appropriate selection is checked
        cell.accessoryType = UITableViewCellAccessoryCheckmark;

        // loop through all the visible cells and remove checkmark
        for (UITableViewCell *visibleCell in [self.tableView visibleCells]) {
            if (visibleCell != cell) {
                visibleCell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
    }

    // deselect row
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//------------------------------------------------------------------------------

/**
 * Customize the appearance of the table header.
 * /
- (UIView*) tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
}
*/

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
    [mCurrentSelection release];
    [mData release];
    [mTableView release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
