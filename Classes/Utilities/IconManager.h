//
//  IconManager.h
//  TikTok
//
//  Created by Moiz Merchant on 12/22/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports 
//------------------------------------------------------------------------------

#import <Foundation/Foundation.h>

//------------------------------------------------------------------------------
// forward declarations
//------------------------------------------------------------------------------

@class IconData;

//------------------------------------------------------------------------------
// interface implementation 
//------------------------------------------------------------------------------

@interface IconManager : NSObject
{
    NSMutableDictionary *mImages;
    NSMutableDictionary *mImageRequests;
}

//------------------------------------------------------------------------------

+ (IconManager*) getInstance;

//------------------------------------------------------------------------------

/**
 * Returns image if availble in the memory cache.
 */
- (UIImage*) getImage:(IconData*)iconData;

/**
 * Checks file system for cached image, if not availble downloads image from the 
 * internet.
 */
- (void) requestImage:(IconData*)iconData 
withCompletionHandler:(void (^)(UIImage* image, NSError *error))handler;

/**
 * Stop existing image request.
 */
- (void) cancelImageRequest:(IconData*)iconData;

/**
 * Delete image from filesystem.
 */
- (void) deleteImage:(IconData*)iconData;

/**
 * Delete image directory from filesystem.
 */
- (void) deleteAllImages;

//------------------------------------------------------------------------------

@end
