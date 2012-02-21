//
//  UIImage+FromView.m
//  TikTok
//
//  Created by Moiz Merchant on 02/20/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes 
//-----------------------------------------------------------------------------

#include <QuartzCore/QuartzCore.h>
#import "UIImage+FromView.h"

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation UIImage (FromView)

//-----------------------------------------------------------------------------

+ (void) beginImageContextWithSize:(CGSize)size
{
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        if ([[UIScreen mainScreen] scale] == 2.0) {
            UIGraphicsBeginImageContextWithOptions(size, YES, 2.0);
        } else {
            UIGraphicsBeginImageContext(size);
        }
    } else {
        UIGraphicsBeginImageContext(size);
    }
}

//-----------------------------------------------------------------------------

+ (void) endImageContext
{
    UIGraphicsEndImageContext();
}

//-----------------------------------------------------------------------------

+ (UIImage*) imageFromView:(UIView*)view
{
    // create a new graphics context
    [self beginImageContextWithSize:[view bounds].size];

    // save hidden status and make sure view is visible
    BOOL hidden = [view isHidden];
    view.hidden = NO;

    // render the view
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    // cleanup the graphics context
    [self endImageContext];

    // reset hidden field
    [view setHidden:hidden];

    return image;
}

//-----------------------------------------------------------------------------

+ (UIImage*)imageFromView:(UIView*)view scaledToSize:(CGSize)newSize
{
    UIImage *image = [self imageFromView:view];
    CGRect bounds  = view.bounds;
    if (bounds.size.width != newSize.width ||
        bounds.size.height != newSize.height) {
        image = [self imageWithImage:image scaledToSize:newSize];
    }
    return image;
}

//-----------------------------------------------------------------------------

+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize
{
    [self beginImageContextWithSize:newSize];
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    [self endImageContext];
    return newImage;
}

//-----------------------------------------------------------------------------

@end
