//
//  IconManager.m
//  TikTok
//
//  Created by Moiz Merchant on 12/22/11.
//  Copyright 2011 TikTok. All rights reserved.
//

//------------------------------------------------------------------------------
// imports 
//------------------------------------------------------------------------------

#import "IconManager.h"
#import "ASIHTTPRequest.h"
#import "IconData.h"
#import "IconRequest.h"

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface IconManager ()
    - (NSURL*) applicationDocumentsDirectory;
    - (NSURL*) getIconDirectory;
    - (bool) createDirectory:(NSURL*)directory;
    - (NSURL*) getOrCreateIconDirectory;
    - (NSString*) getImageName:(IconData*)iconData;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation IconManager

//------------------------------------------------------------------------------
#pragma - Statics
//------------------------------------------------------------------------------

+ (IconManager*) getInstance
{
    static IconManager *sIconManager = nil;
    if (sIconManager == nil) {
        sIconManager = [[[IconManager alloc] init] retain]; 
    }
    return sIconManager;
}

//------------------------------------------------------------------------------
#pragma - Public Api
//------------------------------------------------------------------------------

- (UIImage*) getImage:(IconData*)iconData
{
    NSString *imageName = [self getImageName:iconData];

    // check if image already exists in memory cache
    UIImage* image = [mImages valueForKey:imageName];
    if (image) return image;

    // [moiz] we may want to do this is another thread? 
    
    // construct path to image on the file system
    NSURL *fileUrl = [[self getOrCreateIconDirectory] 
        URLByAppendingPathComponent:imageName];

    // grab image of file system, cache if it exists
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:fileUrl.path]) {
        image = [UIImage imageWithData:[NSData dataWithContentsOfURL:fileUrl]];
        [mImages setValue:image forKey:imageName];
    }

    return image;
}

//------------------------------------------------------------------------------

- (void) requestImage:(IconData*)iconData 
withCompletionHandler:(void (^)(UIImage* image, NSError *error))handler
{
    NSLog(@"Requesting image: %@", iconData.iconUrl);

    __block NSString *imageName = [self getImageName:iconData];

    // check if request for image already exists
    if ([mImageRequests valueForKey:imageName]) {
        IconRequest *iconRequest = [mImageRequests objectForKey:imageName];
        [iconRequest.handlers addObject:[handler copy]];
        return;
    }

    // submit a web request to grab the data
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:iconData.iconUrl];
    [request setCompletionBlock:^{
        UIImage *image = [UIImage imageWithData:[request responseData]];
        image = [UIImage imageWithCGImage:[image CGImage] scale:2.0 orientation:UIImageOrientationUp];
        [mImages setValue:image forKey:imageName];

        // save image to the filesystem
        NSURL *fileUrl = [[self getOrCreateIconDirectory] 
            URLByAppendingPathComponent:imageName];
        [UIImagePNGRepresentation(image) writeToFile:fileUrl.path atomically:YES];

        // run handlers
        IconRequest *iconRequest = [mImageRequests objectForKey:imageName];
        for (void (^imageHandler)(UIImage*, NSError*) in iconRequest.handlers) {
            imageHandler(image, nil);
        }

        // cleanup
        [mImageRequests removeObjectForKey:imageName];
    }];

    // setup fail block
    [request setFailedBlock:^{
        IconRequest *iconRequest = [mImageRequests objectForKey:imageName];
        for (void (^imageHandler)(UIImage*, NSError*) in iconRequest.handlers) {
            imageHandler(nil, [request error]);
        }

        // cleanup
        [mImageRequests removeObjectForKey:imageName];
    }];

    // start up request
    [request startAsynchronous];

    // cache request 
    IconRequest *iconRequest = [[IconRequest alloc] init];
    iconRequest.request = request;
    [iconRequest.handlers addObject:[handler copy]];
    [mImageRequests setValue:iconRequest forKey:imageName];
    [iconRequest release];
}

//------------------------------------------------------------------------------

- (void) cancelImageRequest:(IconData*)iconData
{
    __block NSString *imageName = [self getImageName:iconData];

    // check if request for image already exists
    IconRequest *iconRequest = [mImageRequests valueForKey:imageName];
    if (iconRequest) {
        [iconRequest.request clearDelegatesAndCancel];
        [mImageRequests removeObjectForKey:imageName];
    }
}

//------------------------------------------------------------------------------

- (void) deleteImage:(IconData*)iconData
{
    NSString *imageName = [self getImageName:iconData];
    NSURL *fileUrl = 
        [[self getOrCreateIconDirectory] URLByAppendingPathComponent:imageName];

    // make sure path exists 
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:fileUrl.path isDirectory:(BOOL[]){YES}]) {
        return;
    }

    // attempt to delete image
    NSError *error = nil;
    [fileManager removeItemAtPath:fileUrl.path error:&error];
    if (error) {
        NSLog(@"IconManager: failed to delete image '%@': %@", fileUrl, error);
    }
}

//------------------------------------------------------------------------------

- (void) deleteAllImages
{
    NSLog(@"IconManager: purging all images.");

    // make sure path exists 
    NSURL *iconDirectory       = [self getIconDirectory];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:iconDirectory.path isDirectory:(BOOL[]){YES}]) {
        return;
    }

    // attempt to delete images
    NSError *error       = nil;
    [fileManager removeItemAtPath:iconDirectory.path error:&error];
    if (error) {
        NSLog(@"IconManager: failed to delete icon directory '%@': %@", 
            iconDirectory, error);
    }
}

//------------------------------------------------------------------------------
#pragma - Lifecycle
//------------------------------------------------------------------------------

- (id) init
{
    self = [super init];
    if (self) {
        mImages        = [[[NSMutableDictionary alloc] init] retain];
        mImageRequests = [[[NSMutableDictionary alloc] init] retain];
    }
    return self;
}

//------------------------------------------------------------------------------

- (void) dealloc
{
    [mImages release];
    [mImageRequests release];
    [super dealloc];
}

//------------------------------------------------------------------------------
#pragma - Filesystem
//------------------------------------------------------------------------------

- (NSURL*) applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] 
        URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] 
        lastObject];
}

//------------------------------------------------------------------------------

/**
 * Create directory if it doesn't already exist
 */
- (bool) createDirectory:(NSURL*)directory
{
    BOOL isDir;
    bool result = true;
    NSFileManager *fileManager = [NSFileManager defaultManager]; 
    if (![fileManager fileExistsAtPath:directory.path isDirectory:&isDir]) {
        NSLog(@"IconManager: creating dir: %@", directory.path);
        result = [fileManager createDirectoryAtPath:directory.path 
                         withIntermediateDirectories:YES 
                                          attributes:nil 
                                               error:NULL];

        if (!result) {
            NSLog(@"IconManager: Failed to create dir: %@", directory.path);
        }
    }

    return result;
}

//------------------------------------------------------------------------------

- (NSURL*) getIconDirectory
{
    NSURL *directory = [[self applicationDocumentsDirectory] 
        URLByAppendingPathComponent:@"icons"];
    return directory;
}

//------------------------------------------------------------------------------

- (NSURL*) getOrCreateIconDirectory
{
    NSURL *directory = [self getIconDirectory];
    [self createDirectory:directory];
    return directory;
}

//------------------------------------------------------------------------------
    
- (NSString*) getImageName:(IconData*)iconData
{
    return $string(@"%@", iconData.iconId);
}

//------------------------------------------------------------------------------

@end
