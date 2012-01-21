//
//  SettingsViewController.m
//  TikTok
//
//  Created by Moiz Merchant on 1/11/12.
//  Copyright (c) 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "SettingsViewController.h"
#import "FacebookManager.h"
#import "GenderPickerViewController.h"
#import "LocationPickerViewController.h"
#import "Settings.h"

//------------------------------------------------------------------------------
// enums
//------------------------------------------------------------------------------
 
enum TableSections
{
    kSectionBasic    = 0,
    kSectionGender   = 1,
    kSectionLocation = 2,
};

enum TableRows
{
    kRowName  = 0,
    kRowEmail = 1,
    kRowHome  = 0,
    kRowWork  = 1,
};

enum ViewTags
{
    kTagNameField  = 1,
    kTagEmailField = 1,
    kTagFacebook   = 2,
};

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation SettingsViewController

//------------------------------------------------------------------------------

@synthesize tableView   = mTableView;
@synthesize nameCell    = mNameCell;
@synthesize emailCell   = mEmailCell;
@synthesize basicHeader = mBasicHeader;

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
    self.title = @"Settings";
    
    // load available data
    Settings *settings      = [Settings getInstance];
    UITextField *nameField  = (UITextField*)[self.nameCell viewWithTag:kTagNameField];
    UITextField *emailField = (UITextField*)[self.emailCell viewWithTag:kTagEmailField];
    nameField.text          = settings.name;
    emailField.text         = settings.email;
}

//------------------------------------------------------------------------------

- (void) viewWillAppear:(BOOL)animated 
{
    [super viewWillAppear:animated];

    // set correct state on facebook connect button
    FacebookManager *manager = [FacebookManager getInstance];
    UIButton *facebookButton = (UIButton*)[self.view viewWithTag:kTagFacebook];
    facebookButton.enabled   = ![manager.facebook isSessionValid];
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
#pragma mark - Events
//------------------------------------------------------------------------------

- (IBAction) saveName:(id)sender
{
    UITextField *nameField = (UITextField*)[self.nameCell viewWithTag:kTagNameField];
    Settings *settings     = [Settings getInstance];
    settings.name          = nameField.text; 
}

//------------------------------------------------------------------------------

- (IBAction) saveEmail:(id)sender
{
    UITextField *emailField = (UITextField*)[self.emailCell viewWithTag:kTagEmailField];
    Settings *settings      = [Settings getInstance];
    settings.email          = emailField.text; 
}

//------------------------------------------------------------------------------

- (IBAction) facebookConnect:(id)sender
{
    FacebookManager *manager = [FacebookManager getInstance];
    if (![manager.facebook isSessionValid]) {
        [manager authorizeWithSucessHandler:^{
            UIButton *facebookButton = (UIButton*)[self.view viewWithTag:kTagFacebook];
            facebookButton.enabled   = NO;
        }];
    }
}

//------------------------------------------------------------------------------
#pragma mark - UITableView protocol
//------------------------------------------------------------------------------

- (BOOL) textFieldShouldReturn:(UITextField*)textField 
{
    [textField resignFirstResponder];
    return YES;
}

//------------------------------------------------------------------------------
#pragma mark - Table view data source
//------------------------------------------------------------------------------

/**
 * Customize the number of sections in the table view.
 */
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView 
{
    return 3;
}

//------------------------------------------------------------------------------

/**
 * Customize the number of rows in the table view.
 */ 
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section 
{
    switch (section) {
        case kSectionBasic:
            return 2;
        case kSectionGender:
            return 1;
        case kSectionLocation:
            return 2;
        default:
            break;
    }

    return 0;
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
    UITableViewCell *cell = nil;

    switch (indexPath.section) {
        case kSectionBasic:
            switch (indexPath.row) {
                case kRowName:
                    cell = self.nameCell;
                    break;
                case kRowEmail:
                    cell = self.emailCell;
                    break;
                default:
                    break;
            }
            break;
        case kSectionGender:
            cell = [[[UITableViewCell alloc] 
                initWithStyle:UITableViewCellStyleDefault 
              reuseIdentifier:@"gender"] autorelease];
            cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = @"Gender";
            break;
        case kSectionLocation:
            cell = [[[UITableViewCell alloc] 
                initWithStyle:UITableViewCellStyleDefault 
              reuseIdentifier:@"location"] autorelease];
            cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = !indexPath.row ? @"Home" : @"Work";
            break;
        default:
            break;
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
    // pick gender
    if (indexPath.section == kSectionGender) {
        GenderPickerViewController *controller = [[GenderPickerViewController alloc] 
            initWithNibName:@"GenderPickerViewController" bundle:nil];

        // pass the selected object to the new view controller.
        [self.navigationController pushViewController:controller animated:YES];
        [controller release];

    // pick location
    } else if (indexPath.section == kSectionLocation) {
        LocationPickerViewController *controller = [[LocationPickerViewController alloc] 
            initWithNibName:@"LocationPickerViewController" bundle:nil];
        
        // setup the location and save handler depending on which row is selected
        if (indexPath.row == kRowHome) {
            __block Settings *settings = [Settings getInstance];
            controller.location    = settings.home; 
            controller.saveHandler = ^(CLLocation *location) {
                settings.home = location;
            };
        } else {
            __block Settings *settings = [Settings getInstance];
            controller.location    = settings.work; 
            controller.saveHandler = ^(CLLocation *location) {
                settings.work = location;
            };
        }

        // pass the selected object to the new view controller.
        [self.navigationController pushViewController:controller animated:YES];
        [controller release];
    }

    // deselect row
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//------------------------------------------------------------------------------

- (CGFloat) tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section 
{
    if (section == kSectionBasic) {
        return self.basicHeader.frame.size.height;
    }
    return 10.0f;
}

//------------------------------------------------------------------------------

/**
 * Customize the appearance of the table header.
 */
- (UIView*) tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView* header = nil;
    if (section == kSectionBasic) {
        header = self.basicHeader;
    }
    return header;
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
    [mBasicHeader release];
    [mNameCell release];
    [mEmailCell release];
    [mTableView release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
