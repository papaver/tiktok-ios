//
//  CheckinViewController.h
//  fifteenMinutes
//
//  Created by Moiz Merchant on 5/28/11.
//  Copyright 2011 Bunnies on Acid. All rights reserved.
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
    UIButton           *m_checkin_button;
    UIButton           *m_checkout_button;
    LocationController *m_location_controller;
    Location           *m_checkin_location;
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
