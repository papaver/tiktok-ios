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
#import "GoogleMapsApi.h"
#import "InputTableViewCell.h"
#import "LocationPickerViewController.h"
#import "Settings.h"
#import "StringPickerViewController.h"
#import "TikTokApi.h"

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
    kRowTwitter  = 2,
    kRowHome     = 0,
    kRowWork     = 1,
    kRowGender   = 0,
    kRowBirthday = 1,
};

enum ViewTags
{
    kTagNameField         = 1,
    kTagEmailField        = 1,
    kTagTwitterField      = 1,
    kTagFacebook          = 2,
    kTagTutorialArrow     = 4,
    kTagTutorialText      = 5,
    kTagTutorialTapMe     = 6,
    kTagTutorialCharacter = 7,
};

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface SettingsViewController ()
    - (void) setupTutorialForStage:(TutorialStage)stage;
    - (void) setupTutorialStageStart;
    - (void) setupTutorialStage:(TutorialStage)stage
                characterOrigin:(CGPoint)characterOrigin
                    arrowOrigin:(CGPoint)arrowOrigin
                      textFrame:(CGRect)textFrame
                   tutorialText:(NSString*)tutorialText;
    - (void) setupTutorialStageFacebook;
    - (void) setupTutorialStageUserInfo;
    - (void) setupTutorialStageMisc;
    - (void) setupTutorialStageLocation;
    - (void) setupTutorialStageTwitter;
    - (void) setupTutorialStageComplete;
    - (UIImage*) tutorialCharacterImageForStage:(TutorialStage)stage;
    - (UIImage*) tutorialArrowImageForStage:(TutorialStage)stage;
    - (void) repositionTapMe:(UIButton*)character;
    - (void) addTutorialBarButton;
    - (void) restartTutorial;
    - (void) setupFacebookConnect;
    - (void) updateFacebookConnect;
    - (void) facebookConnect;
    - (void) facebookLogout;
    - (UITableViewCell*) getReusableCell;
    - (InputTableViewCell*) getReusableBirthdayCell;
    - (void) updateGenderAtIndexPath:(NSIndexPath*)indexPath;
    - (void) updateBirthdayAtIndexPath:(NSIndexPath*)indexPath;
    - (void) updateWorkLocationAtIndexPath:(NSIndexPath*)indexPath;
    - (void) updateHomeLocationAtIndexPath:(NSIndexPath*)indexPath;
    - (NSString*) parseLocality:(NSDictionary*)geoData;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation SettingsViewController

//------------------------------------------------------------------------------

@synthesize tableView              = mTableView;
@synthesize nameCell               = mNameCell;
@synthesize emailCell              = mEmailCell;
@synthesize twitterCell            = mTwitterCell;
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
    [Analytics passCheckpoint:@"Settings"];

    // setup navigation info
    self.title = @"Settings";

    // [iOS4] fix for black corners
    self.tableView.backgroundColor = [UIColor clearColor];

    // [iOS4] fix for missing font bradley hand bold
    UILabel *text  = (UILabel*)[self.view viewWithTag:kTagTutorialText];
    UILabel *tapme = (UILabel*)[self.view viewWithTag:kTagTutorialTapMe];
    if (text.font == nil) {
        text.font  = [UIFont fontWithName:@"BradleyHandITCTTBold" size:18];
        tapme.font = [UIFont fontWithName:@"BradleyHandITCTTBold" size:18];
    }

    // load available data
    Settings *settings        = [Settings getInstance];
    UITextField *nameField    = (UITextField*)[self.nameCell viewWithTag:kTagNameField];
    UITextField *emailField   = (UITextField*)[self.emailCell viewWithTag:kTagEmailField];
    UITextField *twitterField = (UITextField*)[self.twitterCell viewWithTag:kTagTwitterField];
    nameField.text            = settings.name;
    emailField.text           = settings.email;
    twitterField.text         = settings.twitter;

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

    // completed version will look a little different
    NSArray *sectionBasicFinal = $array(@"Name", @"Email", @"Twitter Handle");
    mTableDataFinal = [$dict(
        $array($numi(kSectionBasic), $numi(kSectionDetails), $numi(kSectionLocation)),
        $array(sectionBasicFinal, sectionDetails, sectionLocation))
        retain];

    // add facebook connect to navbar
    [self setupFacebookConnect];

    // setup tutorial
    NSNumber *stage = settings.tutorialIndex;
    mTutorialStage = stage == nil ? kTutorialStageStart : stage.intValue;
    [self setupTutorialForStage:mTutorialStage];
}

//------------------------------------------------------------------------------

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateFacebookConnect];
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
#pragma mark - Tutorial
//------------------------------------------------------------------------------

- (void) setupTutorialForStage:(TutorialStage)stage
{
    // save the new stage, once complete don't allow change
    Settings *settings = [Settings getInstance];
    if (settings.tutorialIndex.intValue != kTutorialStageComplete) {
        [[Settings getInstance] setTutorialIndex:$numi(stage)];
    }

    // update the views
    switch (stage) {
        case kTutorialStageStart:
            [self setupTutorialStageStart];
            break;
        case kTutorialStageFacebook:
            [self setupTutorialStageFacebook];
            break;
        case kTutorialStageUserInfo:
            [self setupTutorialStageUserInfo];
            break;
        case kTutorialStageMisc:
            [self setupTutorialStageMisc];
            break;
        case kTutorialStageLocation:
            [self setupTutorialStageLocation];
            break;
        case kTutorialStageTwitter:
            [self setupTutorialStageTwitter];
            break;
        case kTutorialStageComplete:
            [self setupTutorialStageComplete];
            break;
    };
}

//------------------------------------------------------------------------------

- (void) setupTutorialStageStart
{
    // grab all the tutorial elements
    UIImageView *arrow  = (UIImageView*)[self.view viewWithTag:kTagTutorialArrow];
    UIButton *character = (UIButton*)[self.view viewWithTag:kTagTutorialCharacter];
    UILabel *text       = (UILabel*)[self.view viewWithTag:kTagTutorialText];

    // hide the unused elements
    character.hidden = NO;
    arrow.hidden     = YES;
    text.hidden      = YES;

    // load the image
    UIImage *characterImage = [self tutorialCharacterImageForStage:kTutorialStageStart];
    [character setImage:characterImage forState:UIControlStateNormal];

    // position tik in the middle of the screen
    CGRect frame      = self.view.frame;
    frame.origin.x    = (frame.size.width / 2.0) - (characterImage.size.width / 2.0);
    frame.origin.y    = (367.0 / 2.0) - (characterImage.size.height / 2.0);
    frame.size.width  = characterImage.size.width;
    frame.size.height = characterImage.size.height;
    character.frame   = frame;

    // reposition tapme under the character
    [self repositionTapMe:character];
}

//------------------------------------------------------------------------------

- (void) setupTutorialStage:(TutorialStage)stage
            characterOrigin:(CGPoint)characterOrigin
                arrowOrigin:(CGPoint)arrowOrigin
                  textFrame:(CGRect)textFrame
               tutorialText:(NSString*)tutorialText
{
    CGRect frame;

    // grab all the tutorial elements
    UIImageView *arrow  = (UIImageView*)[self.view viewWithTag:kTagTutorialArrow];
    UIButton *character = (UIButton*)[self.view viewWithTag:kTagTutorialCharacter];
    UILabel *text       = (UILabel*)[self.view viewWithTag:kTagTutorialText];

    // load the character image
    UIImage *characterImage = [self tutorialCharacterImageForStage:stage];
    [character setImage:characterImage forState:UIControlStateNormal];

    // load the arrow image
    UIImage *arrowImage = [self tutorialArrowImageForStage:stage];
    arrow.image         = arrowImage;
    arrow.hidden        = NO;

    // add the text
    text.text          = tutorialText;
    text.hidden        = NO;
    text.numberOfLines = 4;

    // position tik
    frame.origin.x    = characterOrigin.x;
    frame.origin.y    = characterOrigin.y;
    frame.size.width  = characterImage.size.width;
    frame.size.height = characterImage.size.height;
    character.frame   = frame;

    // position arrow
    frame.origin.x    = arrowOrigin.x;
    frame.origin.y    = arrowOrigin.y;
    frame.size.width  = arrowImage.size.width;
    frame.size.height = arrowImage.size.height;
    arrow.frame       = frame;

    // position text
    text.frame = textFrame;

    // reposition tapme under the character
    [self repositionTapMe:character];
}

//------------------------------------------------------------------------------

- (void) setupTutorialStageFacebook
{
    [self setupTutorialStage:kTutorialStageFacebook
             characterOrigin:CGPointMake(51.0, 23.0)
                 arrowOrigin:CGPointMake(120.0, 20.0)
                   textFrame:CGRectMake(41.0, 145.0, 179.0 * 2, 94.0)
                tutorialText:@"Connect to Facebook,\n"
                             @"allow us to customize\n"
                             @"your deals and cater to\n"
                             @"YOU!"];
}

//------------------------------------------------------------------------------

- (void) setupTutorialStageUserInfo
{
    [self setupTutorialStage:kTutorialStageUserInfo
             characterOrigin:CGPointMake(220.0, 145.0)
                 arrowOrigin:CGPointMake(77.0, 145.0)
                   textFrame:CGRectMake(90.0, 241.0, 188.0 * 2, 80.0)
                tutorialText:@"Fill out your name and\n"
                             @"email if you feel like it,\n"
                             @"or just stay anonymous."];
}

//------------------------------------------------------------------------------

- (void) setupTutorialStageMisc
{
    [self setupTutorialStage:kTutorialStageMisc
             characterOrigin:CGPointMake(198.0, 67.0)
                 arrowOrigin:CGPointMake(53.0, 69.0)
                   textFrame:CGRectMake(70.0, 8.0, 196.0 * 2, 60.0)
                tutorialText:@"Let us send you special\n"
                             @"deals on your birthday!"];
}

//------------------------------------------------------------------------------

- (void) setupTutorialStageLocation
{
    [self setupTutorialStage:kTutorialStageLocation
             characterOrigin:CGPointMake(203.0, 174.0)
                 arrowOrigin:CGPointMake(60.0, 182.0)
                   textFrame:CGRectMake(110.0, 120.0, 166.0 * 2, 60.0)
                tutorialText:@"We want to send you\n"
                             @"convenient deals!"];
}

//------------------------------------------------------------------------------

- (void) setupTutorialStageTwitter
{
    [self setupTutorialStage:kTutorialStageTwitter
             characterOrigin:CGPointMake(220.0, 100.0)
                 arrowOrigin:CGPointMake(77.0, 100.0)
                   textFrame:CGRectMake(90.0, 206.0, 188.0 * 2, 80.0)
                tutorialText:@"Fill out your twitter\n"
                             @"handle so we can follow\n"
                             @"you on Twitter!"];
}

//------------------------------------------------------------------------------

- (void) setupTutorialStageComplete
{
    [Analytics passCheckpoint:@"Settings Tutorial Complete"];

    // grab all the tutorial elements
    UIImageView *arrow  = (UIImageView*)[self.view viewWithTag:kTagTutorialArrow];
    UILabel *tapme      = (UILabel*)[self.view viewWithTag:kTagTutorialTapMe];
    UIButton *character = (UIButton*)[self.view viewWithTag:kTagTutorialCharacter];
    UILabel *text       = (UILabel*)[self.view viewWithTag:kTagTutorialText];

    arrow.hidden     = YES;
    tapme.hidden     = YES;
    character.hidden = YES;
    text.hidden      = YES;

    // add tutorial button to nav bar
    [self addTutorialBarButton];
}

//------------------------------------------------------------------------------

- (UIImage*) tutorialCharacterImageForStage:(TutorialStage)stage
{
    NSString *imageName = $string(@"SettingsTutorialChar%02d.png", (NSUInteger)stage);
    UIImage *image      = [UIImage imageNamed:imageName];
    return image;
}

//------------------------------------------------------------------------------

- (UIImage*) tutorialArrowImageForStage:(TutorialStage)stage
{
    NSString *imageName = $string(@"SettingsTutorialArrow%02d.png", (NSUInteger)stage);
    UIImage *image      = [UIImage imageNamed:imageName];
    return image;
}

//------------------------------------------------------------------------------

- (void) repositionTapMe:(UIButton*)character
{
    UILabel *tapme = (UILabel*)[self.view viewWithTag:kTagTutorialTapMe];
    CGRect frame     = tapme.frame;
    frame.origin.x   = character.frame.origin.x + 5;
    frame.origin.y   = character.frame.origin.y + character.frame.size.height - 5;
    frame.size.width = character.frame.size.width;
    tapme.frame      = frame;
    tapme.hidden     = NO;
}

//------------------------------------------------------------------------------

- (void) addTutorialBarButton
{
    UIImage *image = [UIImage imageNamed:@"Tik.png"];

    // resize the image
    CGSize size = CGSizeMake(48.0, 48.0);
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    image = [UIImage imageWithCGImage:[image CGImage] scale:2.0 orientation:UIImageOrientationUp];
    UIGraphicsEndImageContext();

    // create the button
    UIBarButtonItem *infoButton =
        [[UIBarButtonItem alloc] initWithImage:image
                                         style:UIBarButtonItemStyleBordered
                                        target:self
                                        action:@selector(restartTutorial)];

    // add to nav bar
    self.navigationItem.leftBarButtonItem = infoButton;
    self.tabBarController.navigationItem.leftBarButtonItem = infoButton;

    // cleanup
    [infoButton release];
}

//------------------------------------------------------------------------------

- (void) restartTutorial
{
    mTutorialStage = 0;
    [self tutorialNext:nil];
}

//------------------------------------------------------------------------------
#pragma mark - Facebook Connect
//------------------------------------------------------------------------------

- (void) setupFacebookConnect
{
    UIImage *image = [UIImage imageNamed:@"fbConnect.png"];

    // setup facebook connect button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame  = CGRectMake(0.0, 0.0, image.size.width, image.size.height);

    // add to nav bar
    UIBarButtonItem *facebookItem =
        [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.rightBarButtonItem = facebookItem;

    // cleanup
    [facebookItem release];
}

//------------------------------------------------------------------------------

- (void) updateFacebookConnect
{
    // set correct state on facebook connect button
    FacebookManager *manager = [FacebookManager getInstance];
    UIBarButtonItem *item    = self.navigationItem.rightBarButtonItem;
    UIButton *facebookButton = (UIButton*)item.customView;

    // update according to session validity
    UIImage *image = nil;
    SEL selector   = nil;
    if (![manager.facebook isSessionValid]) {
        selector = @selector(facebookConnect);
        image    = [UIImage imageNamed:@"fbConnect.png"];
    } else {
        selector = @selector(facebookLogout);
        image    = [UIImage imageNamed:@"fbLogout.png"];
    }

    // update the button
    [facebookButton setImage:image forState:UIControlStateNormal];
    [facebookButton addTarget:self
                       action:selector
             forControlEvents:UIControlEventTouchUpInside];
}

//------------------------------------------------------------------------------

- (void) facebookConnect
{
    [Analytics passCheckpoint:@"Settings Facebook Connect"];

    FacebookManager *manager = [FacebookManager getInstance];
    if (![manager.facebook isSessionValid]) {
        [manager authorizeWithSucessHandler:^{
            [self updateFacebookConnect];
        }];
    }
}

//------------------------------------------------------------------------------

- (void) facebookLogout
{
    [Analytics passCheckpoint:@"Settings Facebook Logout"];

    FacebookManager *manager = [FacebookManager getInstance];
    if ([manager.facebook isSessionValid]) {
        [manager.facebook logout];
        [self updateFacebookConnect];
    }
}

//------------------------------------------------------------------------------
#pragma mark - Events
//------------------------------------------------------------------------------

- (void) setTutorialAlpha:(CGFloat)alpha
{
    UIImageView *arrow  = (UIImageView*)[self.view viewWithTag:kTagTutorialArrow];
    UILabel *tapme      = (UILabel*)[self.view viewWithTag:kTagTutorialTapMe];
    UIButton *character = (UIButton*)[self.view viewWithTag:kTagTutorialCharacter];
    UILabel *text       = (UILabel*)[self.view viewWithTag:kTagTutorialText];

    arrow.alpha     = alpha;
    tapme.alpha     = alpha;
    character.alpha = alpha;
    text.alpha      = alpha;
}

//------------------------------------------------------------------------------

- (IBAction) saveName:(id)sender
{
    [Analytics passCheckpoint:@"Settings Name"];

    UITextField *nameField = (UITextField*)[self.nameCell viewWithTag:kTagNameField];
    Settings *settings     = [Settings getInstance];
    settings.name          = nameField.text;
}

//------------------------------------------------------------------------------

- (IBAction) saveEmail:(id)sender
{
    [Analytics passCheckpoint:@"Settings Email"];

    UITextField *emailField = (UITextField*)[self.emailCell viewWithTag:kTagEmailField];
    Settings *settings      = [Settings getInstance];
    settings.email          = emailField.text;
}

//------------------------------------------------------------------------------

- (IBAction) saveTwitter:(id)sender
{
    [Analytics passCheckpoint:@"Settings Twitter"];

    UITextField *twitterField = (UITextField*)[self.twitterCell viewWithTag:kTagTwitterField];
    Settings *settings        = [Settings getInstance];
    settings.twitter          = twitterField.text;
}

//------------------------------------------------------------------------------

- (IBAction) tutorialNext:(id)sender
{
    // shouldn't really get here if the tutorial is complete...
    if (mTutorialStage == kTutorialStageComplete) {
        return;
    }

    // update the view to present the next tutorial
    CGFloat animationDuration = 0.2;
    [UIView animateWithDuration:animationDuration

        // hide the views
        animations:^{
            [self setTutorialAlpha:0.0];
            self.tableView.alpha = 0.0;
        }

        // update the views and show
        completion:^(BOOL finished) {

            // update the tutorial
            [self setupTutorialForStage:++mTutorialStage];

            // update the table view
            [self.tableView reloadData];

            // show the views again
            [UIView animateWithDuration:animationDuration animations:^{
                [self setTutorialAlpha:1.0];
                self.tableView.alpha = 1.0;
            }];
        }];
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
    if (mTutorialStage == kTutorialStageTwitter) {
        return 1;
    } else if (mTutorialStage == kTutorialStageComplete) {
        return [mTableDataFinal count];
    } else {
        return [mTableData count];
    }
}

//------------------------------------------------------------------------------

/**
 * Customize the number of rows in the table view.
 */
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if (mTutorialStage == kTutorialStageTwitter) {
        return 1;
    } else if (mTutorialStage == kTutorialStageComplete) {
        return [[mTableDataFinal objectForKey:$numi(section)] count];
    } else {
        return [[mTableData objectForKey:$numi(section)] count];
    }
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

    // deal with extra twitter tutorial
    if ((mTutorialStage == kTutorialStageTwitter) && (indexPath.section == kSectionBasic)) {
        return [self tableViewForTwitter:tableView cellForRowAtIndexPath:indexPath];
    }

    // grab the title from the table data
    NSString *title = (mTutorialStage == kTutorialStageComplete) ?
        [[mTableDataFinal objectForKey:$numi(indexPath.section)] objectAtIndex:indexPath.row] :
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
                case kRowTwitter:
                    cell = self.twitterCell;
                    break;
                default:
                    break;
            }

            // show correctly for tutorial
            cell.hidden = (mTutorialStage != kTutorialStageUserInfo) &&
                          (mTutorialStage != kTutorialStageComplete);
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

            // show correctly for tutorial
            cell.hidden = (mTutorialStage != kTutorialStageMisc) &&
                          (mTutorialStage != kTutorialStageComplete);
            break;
        }

        case kSectionLocation: {
            cell                = [self getReusableCell];
            cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = title;

            if (indexPath.row == kRowHome) {
                cell.detailTextLabel.text = settings.homeLocality;
            } else {
                cell.detailTextLabel.text = settings.workLocality;
            }

            // show correctly for tutorial
            cell.hidden = (mTutorialStage != kTutorialStageLocation) &&
                          (mTutorialStage != kTutorialStageComplete);
            break;
        }

        default:
            break;
    }

    return cell;
}

//------------------------------------------------------------------------------

- (UITableViewCell*) tableViewForTwitter:(UITableView*)tableView
                   cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell *cell = self.twitterCell;
    cell.hidden           = NO;
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
    // details sections
    if (indexPath.section == kSectionDetails) {

        switch (indexPath.row) {
            case kRowGender:
                [self updateGenderAtIndexPath:indexPath];
                break;
            case kRowBirthday:
                [self updateBirthdayAtIndexPath:indexPath];
                break;
            default:
                break;
        }

    // location section
    } else if (indexPath.section == kSectionLocation) {

        switch (indexPath.row) {
            case kRowHome:
                [self updateHomeLocationAtIndexPath:indexPath];
                break;
            case kRowWork:
                [self updateWorkLocationAtIndexPath:indexPath];
                break;
            default:
                break;
        }
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

    // show correctly for tutorial
    header.hidden = (mTutorialStage != kTutorialStageUserInfo) &&
                    (mTutorialStage != kTutorialStageTwitter) &&
                    (mTutorialStage != kTutorialStageComplete);

    return header;
}

//------------------------------------------------------------------------------
#pragma mark - Updates settings
//------------------------------------------------------------------------------

- (void) updateGenderAtIndexPath:(NSIndexPath*)indexPath
{
    [Analytics passCheckpoint:@"Settings Gender"];

    // create a string picker controller
    StringPickerViewController *controller = [[StringPickerViewController alloc]
        initWithNibName:@"StringPickerViewController" bundle:nil];

    // setup controller to pick gender
    controller.title            = @"Gender";
    controller.data             = $array(@"Female", @"Male");
    controller.currentSelection = [[Settings getInstance] gender];

    // save the data on completion
    controller.selectionHandler = ^(NSString* selection) {
        Settings *settings        = [Settings getInstance];
        settings.gender           = selection;
        UITableViewCell *cell     = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.detailTextLabel.text = selection;
        [cell setNeedsLayout];
    };

    // display gender picker controller
    [self.navigationController pushViewController:controller animated:YES];

    // cleanup
    [controller release];
}

//------------------------------------------------------------------------------

- (void) updateBirthdayAtIndexPath:(NSIndexPath*)indexPath
{
    [Analytics passCheckpoint:@"Settings Birthday"];

    // update the date picker with the current birthday or use default
    NSDate *birthday        = [[Settings getInstance] birthday];
    if (!birthday) birthday = [NSDate dateWithTimeIntervalSince1970:60.0*60.0*24.0];
    self.dateInputView.date = birthday;

    // display the birthday picker
    [self.birthdayCell becomeFirstResponder];
}

//------------------------------------------------------------------------------

- (void) updateWorkLocationAtIndexPath:(NSIndexPath*)indexPath
{
    [Analytics passCheckpoint:@"Settings Work Location"];

    // create a location picker
    LocationPickerViewController *controller = [[LocationPickerViewController alloc]
        initWithNibName:@"LocationPickerViewController" bundle:nil];

    // setup the location to point to current work address if set
    __block Settings *settings = [Settings getInstance];
    controller.location        = settings.work;

    // save the location and reverse geocode the location
    controller.saveHandler = ^(CLLocation *location) {
        settings.work = location;

        // figure out the locality
        GoogleMapsApi *api = [[GoogleMapsApi alloc] init];
        api.completionHandler = ^(ASIHTTPRequest *request, id geoData) {
            if (geoData) {
                NSString *place           = [self parseLocality:geoData];
                UITableViewCell *cell     = [self.tableView cellForRowAtIndexPath:indexPath];
                settings.workLocality     = place;
                cell.detailTextLabel.text = place;
                [cell setNeedsLayout];
            }
        };

        // query for geocode data
        [api getReverseGeocodingForAddress:location.coordinate];
        [api release];
    };

    // display the work location picker
    [self.navigationController pushViewController:controller animated:YES];

    // cleanup
    [controller release];
}

//------------------------------------------------------------------------------

- (void) updateHomeLocationAtIndexPath:(NSIndexPath*)indexPath
{
    [Analytics passCheckpoint:@"Settings Home Location"];

    // create a location picker
    LocationPickerViewController *controller = [[LocationPickerViewController alloc]
        initWithNibName:@"LocationPickerViewController" bundle:nil];

    // setup the location to point to the current home address if set
    __block Settings *settings = [Settings getInstance];
    controller.location        = settings.home;

    // save the location and reverse geocode the location
    controller.saveHandler = ^(CLLocation *location) {
        settings.home = location;

        // figure out the locality
        GoogleMapsApi *api = [[GoogleMapsApi alloc] init];
        api.completionHandler = ^(ASIHTTPRequest *request, id geoData) {
            if (geoData) {
                NSString *place           = [self parseLocality:geoData];
                UITableViewCell *cell     = [self.tableView cellForRowAtIndexPath:indexPath];
                settings.homeLocality     = place;
                cell.detailTextLabel.text = place;
                [cell setNeedsLayout];
            }
        };

        // query for geocode data
        [api getReverseGeocodingForAddress:location.coordinate];
        [api release];
    };

    // display the home location picker
    [self.navigationController pushViewController:controller animated:YES];

    // cleanup
    [controller release];
}

//------------------------------------------------------------------------------

- (NSString*) parseLocality:(NSDictionary*)geoData
{
    static NSArray *keys = nil;
    if (keys == nil) {
        keys = [$array(@"subpremise", @"premise", @"neighborhood",
            @"sublocality", @"locality", @"colloquial_area",
            @"administrative_area_level_3") retain];
    }

    // make sure search results exist
    NSString *status = [geoData objectForKey:@"status"];
    if (!status || [status isEqualToString:@"ZERO_RESULTS"]) {
        return @"Unknown";
    }

    // grab the results from the json data
    NSArray *results = [geoData objectForKey:@"results"];

    // loop through all of the results and get as many fits as possbile
    NSMutableDictionary *localities = [[NSMutableDictionary alloc] init];
    for (NSDictionary *address in results) {
        NSArray *components = [address objectForKey:@"address_components"];
        for (NSDictionary *component in components) {
            for (NSString *key in keys) {

                // skip if the key was already found
                if ([localities objectForKey:key]) continue;

                // add key if it matches the type
                NSArray *types = [component objectForKey:@"types"];
                if ([types containsObject:key]) {
                    NSString *name = [component objectForKey:@"short_name"];
                    [localities setObject:name forKey:key];
                }
            }
        }
    }

    // go through the list and find the smallest locality
    NSString *locality = nil;
    for (NSString *key in keys) {
        NSString *value = [localities objectForKey:key];
        if (value) {
            locality = value;
            break;
        }
    }

    // cleanup
    [localities release];

    return locality ? locality : @"Unknown";
}

//------------------------------------------------------------------------------
#pragma mark - Events
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
    [mTableData release];
    [mTableDataFinal release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
