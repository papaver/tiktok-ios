//
//  UITableViewHeader.h
//  TikTok
//
//  Created by Moiz Merchant on 07/26/12.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports
//------------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

@protocol UITableViewHeaderDelegate;

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface UITableViewHeader : UIView
{
    NSInteger                     mSection;
    id<UITableViewHeaderDelegate> mDelegate;
}

//------------------------------------------------------------------------------

@property (nonatomic, assign)          NSInteger                     section;
@property (nonatomic, weak)   IBOutlet id<UITableViewHeaderDelegate> delegate;

//------------------------------------------------------------------------------

- (void) toggle;

//------------------------------------------------------------------------------

@end

//------------------------------------------------------------------------------
// protocol definition
//------------------------------------------------------------------------------

@protocol UITableViewHeaderDelegate <NSObject>

@optional

- (void) headerView:(UITableViewHeader*)headerView sectionTapped:(NSInteger)section;

@end


