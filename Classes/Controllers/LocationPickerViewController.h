//
//  LocationPickerViewController.h
//  TikTok
//
//  Created by Moiz Merchant on 1/19/12.
//  Copyright (c) 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <UIKit/UIKit.h>

//------------------------------------------------------------------------------
// typedefs
//------------------------------------------------------------------------------

typedef void (^LocationPickerCompletionHandler)(CLLocation*);

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface LocationPickerViewController : UIViewController <UITextFieldDelegate,
                                                            MKMapViewDelegate>
{
    CLLocation                      *mLocation;
    UIBarButtonItem                 *mDoneButton;
    LocationPickerCompletionHandler  mSaveHandler;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain)          CLLocation                      *location;
@property (nonatomic, retain) IBOutlet UIBarButtonItem                 *doneButton;
@property (nonatomic, copy)            LocationPickerCompletionHandler  saveHandler;

//------------------------------------------------------------------------------

- (IBAction) centerMap:(id)sender;
- (IBAction) done:(id)sender;

//------------------------------------------------------------------------------

@end
