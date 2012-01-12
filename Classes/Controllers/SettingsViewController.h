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
// interface definition
//------------------------------------------------------------------------------

@interface SettingsViewController : UIViewController <UITableViewDelegate, 
                                                      UITableViewDataSource,
                                                      UITextFieldDelegate>
{
    UITableView     *mTableView;
    UITableViewCell *mNameCell;
    UITableViewCell *mEmailCell;
    UIView          *mBasicHeader;
}

//------------------------------------------------------------------------------
                                                    
@property (nonatomic, retain) IBOutlet UITableView     *tableView;
@property (nonatomic, retain) IBOutlet UITableViewCell *nameCell;
@property (nonatomic, retain) IBOutlet UITableViewCell *emailCell;
@property (nonatomic, retain) IBOutlet UIView          *basicHeader;

//------------------------------------------------------------------------------

- (IBAction) saveName:(id)sender;
- (IBAction) saveEmail:(id)sender;

- (IBAction) facebookConnect:(id)sender;

//------------------------------------------------------------------------------

@end
