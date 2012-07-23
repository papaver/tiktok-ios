//
//  MerchantViewController.h
//  TikTok
//
//  Created by Moiz Merchant on 4/22/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>
#import "UILabelExt.h"
#import "UITableViewHeader.h"

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

@class Coupon;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface MerchantViewController : UIViewController <UITableViewDelegate,
                                                      UITableViewDataSource,
                                                      UITableViewHeaderDelegate,
                                                      UILabelExtDelegate>
{
    Coupon          *mCoupon;
    NSArray         *mLocations;
    UITableView     *mTableView;
    UITableViewCell *mCellView;
    UIView          *mHeaderView;
    bool             mTableExpanded;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain)          Coupon          *coupon;
@property (nonatomic, retain)          NSArray         *locations;
@property (nonatomic, retain) IBOutlet UITableView     *tableView;
@property (nonatomic, retain) IBOutlet UITableViewCell *cellView;
@property (nonatomic, retain) IBOutlet UIView          *headerView;

//------------------------------------------------------------------------------

@end
