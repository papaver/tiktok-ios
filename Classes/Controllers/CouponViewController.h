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

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface CouponViewController : UITableViewController <NSFetchedResultsControllerDelegate>
{
    UITableViewCell            *mCellView;
    NSFetchedResultsController *mFetchedCouponsController;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) IBOutlet UITableViewCell             *cellView;
@property (nonatomic, retain)          NSFetchedResultsController  *fetchedCouponsController;

//------------------------------------------------------------------------------

@end
