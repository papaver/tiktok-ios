//
//  CheckinViewController.h
//  TikTok
//
//  Created by Moiz Merchant on 5/28/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports 
//------------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "LocationController.h"
#import "Location.h"

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface CheckinViewController : UIViewController <LocationControllerDelegate>
{
    UIButton           *mCheckinButton;
    UIButton           *mCheckoutButton;
    LocationController *mLocationController;
    Location           *mCheckinLocation;
}

//------------------------------------------------------------------------------

@property (nonatomic, retain) IBOutlet UIButton           *checkinButton;
@property (nonatomic, retain) IBOutlet UIButton           *checkoutButton;
@property (nonatomic, retain)          LocationController *locationController;
@property (nonatomic, retain)          Location           *checkinLocation;

//------------------------------------------------------------------------------

- (IBAction) checkIn:(id)sender;
- (IBAction) checkOut:(id)sender;

- (bool) isCheckedIn;

- (void) locationUpdate:(CLLocation*)location;
- (void) locationError:(NSError*)error;

//------------------------------------------------------------------------------

@end
