//
//  StringPickerViewController.h
//  TikTok
//
//  Created by Moiz Merchant on 1/12/12.
//  Copyright (c) 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

//------------------------------------------------------------------------------
// typedefs
//------------------------------------------------------------------------------

typedef void (^StringPickerSelectionHandler)(NSString*);

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface StringPickerViewController : UIViewController <UITableViewDelegate, 
                                                          UITableViewDataSource>
{
    UITableView                  *mTableView;
    NSArray                      *mData;
    NSString                     *mCurrentSelection;
    StringPickerSelectionHandler  mSelectionHandler;
}

//------------------------------------------------------------------------------
                                                    
@property (nonatomic, retain) IBOutlet UITableView                  *tableView;
@property (nonatomic, retain)          NSArray                      *data;
@property (nonatomic, retain)          NSString                     *currentSelection;
@property (nonatomic, copy)            StringPickerSelectionHandler  selectionHandler;

//------------------------------------------------------------------------------

@end
