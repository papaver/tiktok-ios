//
//  JsonPickerViewController.m
//  TikTok
//
//  Created by Moiz Merchant on 06/12/12.
//  Copyright (c) 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import "JsonPickerViewController.h"
#import "ASIHTTPRequest.h"

//------------------------------------------------------------------------------
// defines
//------------------------------------------------------------------------------

#define kImageKey        @"_image"
#define kImageRequestKey @"_request"

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

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface JsonPickerViewController ()
    - (void) setupHeaderData;
    - (UITableViewCell*) getReusableCell;
    - (NSString*) getRequestKeyForTitle:(NSString*)title;
    - (NSString*) getImageKeyForTitle:(NSString*)title;
    - (NSArray*) getEntriesStartingWithLetter:(NSString*)letter;
    - (NSDictionary*) getEntryAtIndexPath:(NSIndexPath*)indexPath;
    - (void) setupIconForCell:(UITableViewCell*)cell
                  atIndexPath:(NSIndexPath*)indexPath
                    withEntry:(NSDictionary*)entry;
    - (void) setIcon:(UIImage*)image forCell:(UITableViewCell*)cell;
    - (void) requestImageForEntry:(NSDictionary*)entry atIndexPath:(NSIndexPath*)indexPath;
    - (void) loadImagesForOnscreenRows;
    - (UIImage*) createThumbnailFromImage:(UIImage*)image;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation JsonPickerViewController

//------------------------------------------------------------------------------

@synthesize tableView        = mTableView;
@synthesize jsonData         = mJsonData;
@synthesize titleKey         = mTitleKey;
@synthesize imageKey         = mImageKey;
@synthesize selectionHandler = mSelectionHandler;

//------------------------------------------------------------------------------
#pragma mark - Initialization
//------------------------------------------------------------------------------

- (id) initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.titleKey = @"title";
        self.imageKey = @"image";
        mImages       = [[[NSMutableDictionary alloc] init] retain];
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
    [self setupHeaderData];
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

- (void) setupHeaderData
{
    NSMutableSet *alphabet = [NSMutableSet set];

    // gather all of first letters in all the entries names present
    for (NSDictionary *entry in self.jsonData) {
        NSString *title  = [entry objectForKey:self.titleKey];
        NSString *letter = [[title substringToIndex:1] uppercaseString];
        [alphabet addObject:letter];
    }

    // save set of letters
    mHeaders = [[[alphabet allObjects]
        sortedArrayUsingSelector:@selector(compare:)] retain];
}

//------------------------------------------------------------------------------
#pragma mark - Table view data source
//------------------------------------------------------------------------------

/**
 * Customize the number of sections in the table view.
 */
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
    return mHeaders.count;
}

//------------------------------------------------------------------------------

/**
 * Customize the number of rows in the table view.
 */
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *letter = [mHeaders objectAtIndex:section];
    NSArray *entries = [self getEntriesStartingWithLetter:letter];
    return entries.count;
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

    // update cell with entry info
    NSDictionary *entry = [self getEntryAtIndexPath:indexPath];
    cell.textLabel.text = [entry objectForKey:@"name"];

    // setup icon
    [self setupIconForCell:cell atIndexPath:indexPath withEntry:entry];

    return cell;
}

//------------------------------------------------------------------------------

- (UITableViewCell*) getReusableCell
{
    static NSString *sCellId = @"fbAppFriends";

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
 */
- (BOOL) tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath
{
    // table rows are not editable
    return NO;
}

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
    if (self.selectionHandler) {
        NSDictionary* entry = [self getEntryAtIndexPath:indexPath];
        [self close];
        self.selectionHandler(entry);
    }
}

//------------------------------------------------------------------------------

/**
 * Customize the title of the table header.
 */
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *letter = [mHeaders objectAtIndex:section];
    return letter;
}

//------------------------------------------------------------------------------
#pragma mark - Events
//------------------------------------------------------------------------------

- (IBAction) close
{
    // [iOS4] fix for newer function
    if ($has_selector(self, presentingViewController)) {
        [self.presentingViewController dismissViewControllerAnimated:YES
                                                          completion:nil];
    } else {
        [self.parentViewController dismissModalViewControllerAnimated:YES];
    }
}

//-----------------------------------------------------------------------------
#pragma mark - ScrollView Delegates
//-----------------------------------------------------------------------------

- (void) scrollViewDidEndDragging:(UIScrollView*)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) [self loadImagesForOnscreenRows];
}

//-----------------------------------------------------------------------------

- (void) scrollViewDidEndDecelerating:(UIScrollView*)scrollView
{
    [self loadImagesForOnscreenRows];
}

//------------------------------------------------------------------------------
#pragma mark - Helper Functions
//------------------------------------------------------------------------------

- (NSString*) getRequestKeyForTitle:(NSString*)title
{
    return $string(@"%@%@", title, kImageRequestKey);
}

//------------------------------------------------------------------------------

- (NSString*) getImageKeyForTitle:(NSString*)title
{
    return $string(@"%@%@", title, kImageKey);
}

//------------------------------------------------------------------------------

- (NSArray*) getEntriesStartingWithLetter:(NSString*)letter
{
    NSMutableArray *entries = [[[NSMutableArray alloc] init] autorelease];
    for (NSDictionary *entry in self.jsonData) {
        NSString *title = [entry objectForKey:self.titleKey];
        if ([title hasPrefix:letter]) {
            [entries addObject:entry];
        }
    }
    return entries;
}

//------------------------------------------------------------------------------

- (NSDictionary*) getEntryAtIndexPath:(NSIndexPath*)indexPath
{
    NSString *letter    = [mHeaders objectAtIndex:indexPath.section];
    NSArray *entries    = [self getEntriesStartingWithLetter:letter];
    NSDictionary *entry = [entries objectAtIndex:indexPath.row];
    return entry;
}

//------------------------------------------------------------------------------

- (void) setupIconForCell:(UITableViewCell*)cell
              atIndexPath:(NSIndexPath*)indexPath
                withEntry:(NSDictionary*)entry
{
    NSString *title    = [entry objectForKey:self.titleKey];
    NSString *imageKey = [self getImageKeyForTitle:title];
    UIImage *image     = [mImages objectForKey:imageKey];

    // set merchant icon
    [self setIcon:image forCell:cell];

    // load image from server if table is not moving
    if (!image && !self.tableView.dragging && !self.tableView.decelerating) {
        [self requestImageForEntry:entry atIndexPath:indexPath];
    }
}

//------------------------------------------------------------------------------

- (void) setIcon:(UIImage*)image forCell:(UITableViewCell*)cell
{
    // load default thumb
    static UIImage *defaultThumbnail = nil;
    if (defaultThumbnail == nil) {
        defaultThumbnail = [[UIImage imageNamed:@"FacebookDefault.png"] retain];
    }

    // update image
    cell.imageView.image = (image != nil) ? image : defaultThumbnail;
    [cell setNeedsLayout];
}

//------------------------------------------------------------------------------

- (void) requestImageForEntry:(NSDictionary*)entry atIndexPath:(NSIndexPath*)indexPath
{
    NSString *title      = [entry objectForKey:self.titleKey];
    NSString *requestKey = [self getRequestKeyForTitle:title];
    NSString *imageKey   = [self getImageKeyForTitle:title];

    // don't re-run requests
    if (([mImages objectForKey:requestKey] != nil) ||
         [mImages objectForKey:imageKey] != nil) return;

    // grab url path
    NSURL *imageUrl = [NSURL URLWithString:[entry objectForKey:self.imageKey]];

    // submit a web request to grab the data
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:imageUrl];
    [request setCompletionBlock:^{
        UIImage *image = [UIImage imageWithData:[request responseData]];
        image          = [self createThumbnailFromImage:image];

        // cache image
        [mImages setObject:image forKey:imageKey];

        // cleanup
        [mImages removeObjectForKey:requestKey];

        // update cell if visible
        NSArray *visibleIndices  = [self.tableView indexPathsForVisibleRows];
        if ([visibleIndices containsObject:indexPath]) {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            [UIView animateWithDuration:0.2 animations:^{
                [self setIcon:image forCell:cell];
            }];
        }
    }];

    // setup fail block
    [request setFailedBlock:^{
        [mImages removeObjectForKey:requestKey];
    }];

    // cache request
    [mImages setObject:request forKey:requestKey];

    // run request
    [request startAsynchronous];
}

//------------------------------------------------------------------------------

- (void) loadImagesForOnscreenRows
{
    NSArray *visibleIndices = [self.tableView indexPathsForVisibleRows];
    [visibleIndices enumerateObjectsUsingBlock:
        ^(NSIndexPath *indexPath, NSUInteger index, BOOL *stop) {
            NSDictionary *entry = [self getEntryAtIndexPath:indexPath];
            NSString *title     = [entry objectForKey:self.titleKey];
            NSString *titleKey  = [self getImageKeyForTitle:title];
            UIImage *image      = [mImages objectForKey:titleKey];
            if (image == nil) {
                [self requestImageForEntry:entry atIndexPath:indexPath];
            }
        }];
}

//------------------------------------------------------------------------------

- (UIImage*) createThumbnailFromImage:(UIImage*)image
{
    // target thumbnail size
    CGSize target = CGSizeMake(80.0, 80.0);

    // figure out correct scaling
    CGFloat scaleFactor  = 0.0;
    CGFloat widthFactor  = target.width  / image.size.width;
    CGFloat heightFactor = target.height / image.size.height;
    if (widthFactor > heightFactor) {
         scaleFactor = widthFactor;
    } else {
         scaleFactor = heightFactor;
    }

    // calculate scaled image size
    CGSize scaled = CGSizeMake(image.size.width * scaleFactor,
                               image.size.height * scaleFactor);

    // center the image
    CGPoint origin = CGPointZero;
    if (widthFactor > heightFactor) {
        origin.y = (target.height - scaled.height) * 0.5;
    } else if (widthFactor < heightFactor) {
        origin.x = (target.width - scaled.width) * 0.5;
    }

    // creating the context should crop
    UIGraphicsBeginImageContext(target);

    // draw new image
    CGRect rect = CGRectZero;
    rect.origin = origin;
    rect.size   = scaled;
    [image drawInRect:rect];

    // grab the new image
    UIImage *thumbnail = UIGraphicsGetImageFromCurrentImageContext();

    // pop the context to get back to the default
    UIGraphicsEndImageContext();

    // scale for retina display?
    return [UIImage imageWithCGImage:[thumbnail CGImage]
                               scale:2.0
                         orientation:UIImageOrientationUp];
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
    [mImages release];
    [mHeaders release];
    [mJsonData release];
    [mTitleKey release];
    [mImageKey release];
    [mTableView release];
    [super dealloc];
}

//------------------------------------------------------------------------------

@end
