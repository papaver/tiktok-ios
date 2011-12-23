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
// interface implementation 
//------------------------------------------------------------------------------

@interface IconManager : NSObject
{
    NSMutableDictionary *mImages;
    NSMutableDictionary *mImageRequests;
}

//------------------------------------------------------------------------------

//@property (nonatomic, retain) SBJsonStreamParser        *parser;

//------------------------------------------------------------------------------

+ (IconManager*) getInstance;

//------------------------------------------------------------------------------

/**
 * Returns image if availble in the memory cache.
 */
- (UIImage*) getImage:(NSURL*)imageUrl;

/**
 * Checks file system for cached image, if not availble downloads image from the 
 * internet.
 */
- (void) requestImage:(NSURL*)imageUrl 
withCompletionHandler:(void (^)(UIImage* image, NSError *error))handler;

/**
 * Stop existing image request.
 */
- (void) cancelImageRequest:(NSURL*)imageUrl;

/**
 * Delete image from filesystem.
 */
- (void) deleteImage:(NSURL*)imageUrl;

/**
 * Delete image directory from filesystem.
 */
- (void) deleteAllImages;

//------------------------------------------------------------------------------

@end
