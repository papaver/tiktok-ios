//
//  LogViewController.h
//  TikTok
//
//  Created by Moiz Merchant on 05/02/12.
//  Copyright (c) 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface LogViewController : UIViewController <UITableViewDelegate,
                                                 UITableViewDataSource>
{
    UITableView *mTableView;
    NSArray     *mTableData;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) IBOutlet UITableView *tableView;

//------------------------------------------------------------------------------

- (IBAction) clear:(id)sender;
- (IBAction) close:(id)sender;

//------------------------------------------------------------------------------

@end
