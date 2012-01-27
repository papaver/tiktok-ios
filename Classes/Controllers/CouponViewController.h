//
//  CouponViewController.h
//  TikTok
//
//  Created by Moiz Merchant on 4/19/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "EGORefreshTableHeaderView.h"

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface CouponViewController : UIViewController <NSFetchedResultsControllerDelegate, 
                                                    UITableViewDelegate, 
                                                    UITableViewDataSource,
                                                    EGORefreshTableHeaderDelegate>
{
    UITableViewCell            *mCellView;
    UITableView                *mTableView;
    NSFetchedResultsController *mFetchedCouponsController;
    EGORefreshTableHeaderView  *mRefreshHeaderView;
    BOOL                        mReloading;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) IBOutlet UITableViewCell             *cellView;
@property (nonatomic, retain) IBOutlet UITableView                 *tableView;
@property (nonatomic, retain)          NSFetchedResultsController  *fetchedCouponsController;

//------------------------------------------------------------------------------

@end
