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
#import "StringPickerViewController.h"
#import "InputTableViewCell.h"
#import "LocationPickerViewController.h"
#import "Settings.h"

//------------------------------------------------------------------------------
// enums
//------------------------------------------------------------------------------
 
enum TableSections
{
    kSectionBasic    = 0,
    kSectionDetails  = 1,
    kSectionLocation = 2,
};

enum TableRows
{
    kRowName     = 0,
    kRowEmail    = 1,
    kRowHome     = 0,
    kRowWork     = 1,
    kRowGender   = 0,
    kRowBirthday = 1,
};

enum ViewTags
{
    kTagNameField  = 1,
    kTagEmailField = 1,
    kTagFacebook   = 2,
};


//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface SettingsViewController ()
    - (UITableViewCell*) getReusableCell;
    - (InputTableViewCell*) getReusableBirthdayCell;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation SettingsViewController

//------------------------------------------------------------------------------

@synthesize tableView              = mTableView;
@synthesize nameCell               = mNameCell;
@synthesize emailCell              = mEmailCell;
@synthesize birthdayCell           = mBirthdayCell;
@synthesize dateInputView          = mInputView;
@synthesize dateInputAccessoryView = mInputAccessoryView;
@synthesize basicHeader            = mBasicHeader;

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

    // save birthday cell
    self.birthdayCell = [self getReusableBirthdayCell];

    // setup a dictionary for each naming of the rows
    NSArray *sectionBasic    = $array(@"Name", @"Email");
    NSArray *sectionDetails  = $array(@"Gender", @"Birthday");
    NSArray *sectionLocation = $array(@"Home Location", @"Work Location");
    mTableData = [$dict(
        $array($numi(kSectionBasic), $numi(kSectionDetails), $numi(kSectionLocation)), 
        $array(sectionBasic, sectionDetails, sectionLocation)) 
        retain];
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
    return [mTableData count];
}

//------------------------------------------------------------------------------

/**
 * Customize the number of rows in the table view.
 */ 
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section 
{
    return [[mTableData objectForKey:$numi(section)] count];
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

    // grab the title from the table data
    NSString *title = 
        [[mTableData objectForKey:$numi(indexPath.section)] objectAtIndex:indexPath.row];

    // grab the settings object
    Settings *settings = [Settings getInstance];

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

        case kSectionDetails: {
            if (indexPath.row == kRowGender) {
                cell                      = [self getReusableCell];
                cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
                cell.textLabel.text       = title;
                cell.detailTextLabel.text = settings.gender;
            } else {
                cell                      = self.birthdayCell;
                cell.textLabel.text       = title;
                cell.detailTextLabel.text = settings.birthdayStr;
            }
            break;
        }

        case kSectionLocation: {
            cell                      = [self getReusableCell];
            cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text       = title;
            break;
        }

        default:
            break;
    }

    return cell;
}

//------------------------------------------------------------------------------

- (UITableViewCell*) getReusableCell
{
    static NSString *sCellId = @"generic";

    // check if reuasable cell exists
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:sCellId];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 
            reuseIdentifier:sCellId] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

//------------------------------------------------------------------------------

- (InputTableViewCell*) getReusableBirthdayCell
{
    static NSString *sCellId = @"date";

    // check if reuasable cell exists
    InputTableViewCell *cell = 
        (InputTableViewCell*)[self.tableView dequeueReusableCellWithIdentifier:sCellId];
    if (!cell) {
        cell = [[[InputTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 
            reuseIdentifier:sCellId] autorelease];
        cell.accessoryType      = UITableViewCellAccessoryNone;
        cell.inputView          = self.dateInputView;
        cell.inputAccessoryView = self.dateInputAccessoryView;
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
    if (indexPath.section == kSectionDetails) {
        switch (indexPath.row) {
            case kRowGender: {
                StringPickerViewController *controller = [[StringPickerViewController alloc] 
                    initWithNibName:@"StringPickerViewController" bundle:nil];
                controller.title            = @"Gender";
                controller.data             = $array(@"Female", @"Male");
                controller.currentSelection = [[Settings getInstance] gender];
                controller.selectionHandler = ^(NSString* selection) {
                    Settings *settings        = [Settings getInstance];
                    settings.gender           = selection;
                    UITableViewCell *cell     = [self.tableView cellForRowAtIndexPath:indexPath];
                    cell.detailTextLabel.text = selection;
                    [cell setNeedsLayout];
                };
                [self.navigationController pushViewController:controller animated:YES];
                [controller release];
                break;
            }

            case kRowBirthday: {
                NSDate *birthday        = [[Settings getInstance] birthday];
                if (!birthday) birthday = [NSDate dateWithTimeIntervalSince1970:60.0*60.0*24.0];
                self.dateInputView.date = birthday;
                [self.birthdayCell becomeFirstResponder];
                break;
            }

            default:
                break;
        }


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
#pragma mark - Helper Functions
//------------------------------------------------------------------------------

- (IBAction) toolbarDatePickerCancel:(id)sender
{
    [self.birthdayCell resignFirstResponder];
}

//------------------------------------------------------------------------------

- (IBAction) toolbarDatePickerSave:(id)sender
{
    // save date
    Settings *settings                     = [Settings getInstance];
    settings.birthday                      = self.dateInputView.date;
    self.birthdayCell.detailTextLabel.text = settings.birthdayStr;
    [self.birthdayCell setNeedsLayout];

    // hide date picker
    [self.birthdayCell resignFirstResponder];
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
    [mBirthdayCell release];
    [mTableView release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
