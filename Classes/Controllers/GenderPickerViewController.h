//
//  GenderPickerViewController.h
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
// interface definition
//------------------------------------------------------------------------------

@interface GenderPickerViewController : UIViewController <UITableViewDelegate, 
                                                          UITableViewDataSource>
{
    UITableView *mTableView;
    NSArray     *mGenderData;
}

//------------------------------------------------------------------------------
                                                    
@property (nonatomic, retain) IBOutlet UITableView *tableView;

//------------------------------------------------------------------------------

- (IBAction) done:(id)sender;

//------------------------------------------------------------------------------

@end
