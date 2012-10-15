//
//  SoftNagManager.h
//  TikTok
//
//  Created by Moiz Merchant on 10/04/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

//------------------------------------------------------------------------------
// class interface
//------------------------------------------------------------------------------

@interface SoftNagManager : NSObject <UIAlertViewDelegate>
{
    UIAlertView *mNagAlert;
    NSString    *mCategory;
}

//------------------------------------------------------------------------------

@property(nonatomic, retain) UIAlertView *nagAlert;
@property(nonatomic, retain) NSString    *category;

//------------------------------------------------------------------------------

+ (void) appLaunched;
+ (void) appEnteredForeground;

//------------------------------------------------------------------------------

@end
