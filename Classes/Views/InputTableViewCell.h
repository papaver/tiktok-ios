//
//  InputTableViewCell.h
//  TikTok
//
//  Created by Moiz Merchant on 01/25/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface InputTableViewCell : UITableViewCell
{
}

//------------------------------------------------------------------------------

@property (readwrite, retain) IBOutlet UIView *inputView;
@property (readwrite, retain) IBOutlet UIView *inputAccessoryView;

//------------------------------------------------------------------------------

@end
