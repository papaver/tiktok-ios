//
//  CitiesViewController.h
//  TikTok
//
//  Created by Moiz Merchant on 05/21/12.
//  Copyright (c) 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface CitiesViewController : UIViewController <UITableViewDelegate,
                                                    UITableViewDataSource,
                                                    MKMapViewDelegate>
{
    UITableView    *mTableView;
    MKMapView      *mMapView;
    NSDictionary   *mTableData;
    NSMutableArray *mAnnotations;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet MKMapView   *mapView;

//------------------------------------------------------------------------------

@end
