//
//  CategoryViewController.h
//  TikTok
//
//  Created by Moiz Merchant on 10/03/12.
//  Copyright (c) 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

//------------------------------------------------------------------------------
// typedefs
//------------------------------------------------------------------------------

typedef void (^CategorySelectionHandler)(NSArray*);

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface CategoryViewController : UIViewController <UITableViewDelegate,
                                                      UITableViewDataSource>
{
    UITableView              *mTableView;
    UITableViewCell          *mCellView;
    UIBarButtonItem          *mDoneButton;
    NSArray                  *mData;
    NSMutableArray           *mCurrentSelections;
    CategorySelectionHandler  mSelectionHandler;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) IBOutlet UITableView              *tableView;
@property (nonatomic, retain) IBOutlet UITableViewCell          *cellView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem          *doneButton;
@property (nonatomic, retain)          NSArray                  *data;
@property (nonatomic, retain)          NSMutableArray           *currentSelection;
@property (nonatomic, copy)            CategorySelectionHandler  selectionHandler;

//------------------------------------------------------------------------------

- (IBAction) selectSwitch:(id)sender;
- (IBAction) done:(id)sender;

//------------------------------------------------------------------------------

@end
