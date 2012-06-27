//
//  JsonPickerViewController.h
//  TikTok
//
//  Created by Moiz Merchant on 06/12/12.
//  Copyright (c) 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

//------------------------------------------------------------------------------
// typedefs
//------------------------------------------------------------------------------

typedef void (^JsonPickerCompletionHandler)(NSDictionary*);

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface JsonPickerViewController : UIViewController <UITableViewDelegate,
                                                        UITableViewDataSource>
{

    UITableView                 *mTableView;
    NSString                    *mTitleKey;
    NSString                    *mImageKey;
    NSArray                     *mJsonData;
    NSArray                     *mHeaders;
    NSMutableDictionary         *mImages;
    JsonPickerCompletionHandler  mSelectionHandler;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) IBOutlet UITableView                 *tableView;
@property (nonatomic, retain)          NSString                    *titleKey;
@property (nonatomic, retain)          NSString                    *imageKey;
@property (nonatomic, retain)          NSArray                     *jsonData;
@property (nonatomic, copy)            JsonPickerCompletionHandler  selectionHandler;

//------------------------------------------------------------------------------

- (IBAction) close;

//------------------------------------------------------------------------------

@end
