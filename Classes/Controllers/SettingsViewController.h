//
//  SettingsViewController.h
//  TikTok
//
//  Created by Moiz Merchant on 1/11/12.
//  Copyright (c) 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

@class InputTableViewCell;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface SettingsViewController : UIViewController <UITableViewDelegate, 
                                                      UITableViewDataSource,
                                                      UITextFieldDelegate>
{
    UITableView        *mTableView;
    UITableViewCell    *mNameCell;
    UITableViewCell    *mEmailCell;
    InputTableViewCell *mBirthdayCell;
    UIView             *mDateInputView;
    UIToolbar          *mDateInputAccessoryView;
    UIView             *mBasicHeader;
    NSDictionary       *mTableData;
}

//------------------------------------------------------------------------------
                                                    
@property (nonatomic, retain) IBOutlet UITableView        *tableView;
@property (nonatomic, retain) IBOutlet UITableViewCell    *nameCell;
@property (nonatomic, retain) IBOutlet UITableViewCell    *emailCell;
@property (nonatomic, retain)          InputTableViewCell *birthdayCell;
@property (nonatomic, retain) IBOutlet UIDatePicker       *dateInputView;
@property (nonatomic, retain) IBOutlet UIToolbar          *dateInputAccessoryView;
@property (nonatomic, retain) IBOutlet UIView             *basicHeader;

//------------------------------------------------------------------------------

- (IBAction) saveName:(id)sender;
- (IBAction) saveEmail:(id)sender;

- (IBAction) facebookConnect:(id)sender;

- (IBAction) toolbarDatePickerCancel:(id)sender;
- (IBAction) toolbarDatePickerSave:(id)sender;

//------------------------------------------------------------------------------

@end
