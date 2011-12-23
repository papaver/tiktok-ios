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
    UIView                     *mHeaderView;
    NSFetchedResultsController *mFetchedCouponsController;

    UIView                     *mBackgroundView;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) IBOutlet UITableViewCell             *cellView;
@property (nonatomic, retain) IBOutlet UIView                      *headerView;
@property (nonatomic, retain)          NSFetchedResultsController  *fetchedCouponsController;

@property (nonatomic, retain) IBOutlet UIView                      *backgroundView;

//------------------------------------------------------------------------------

- (void) configureCell:(UIView*)cell atIndexPath:(NSIndexPath*)indexPath;
- (void) configureHeader:(UIView*)header atSection:(NSUInteger)section;

//------------------------------------------------------------------------------

@end
