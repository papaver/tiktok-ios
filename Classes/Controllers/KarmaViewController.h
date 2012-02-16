//
//  KarmaViewController.h
//  TikTok
//
//  Created by Moiz Merchant on 02/14/12.
//  Copyright (c) 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface KarmaViewController : UIViewController <UITableViewDelegate,
                                                   UITableViewDataSource>
{
    UITableView     *mTableView;
    UITableViewCell *mCellView;
    NSArray         *mTableData;
    NSArray         *mIconData;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) IBOutlet UITableView     *tableView;
@property (nonatomic, retain) IBOutlet UITableViewCell *cellView;

//------------------------------------------------------------------------------

@end
