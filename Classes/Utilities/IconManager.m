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

//------------------------------------------------------------------------------
// interface definition
//------------------------------------------------------------------------------

@interface IconManager ()
    - (NSURL*) applicationDocumentsDirectory;
    - (NSURL*) getIconDirectory;
    - (bool) createDirectory:(NSURL*)directory;
    - (NSURL*) getOrCreateIconDirectory;
    - (NSString*) getImageName:(NSURL*)imageUrl;
@end

//------------------------------------------------------------------------------
// interface implementation
//------------------------------------------------------------------------------

@implementation IconManager

//------------------------------------------------------------------------------

//@synthesize adapter = m_adapter;

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

- (UIImage*) getImage:(NSURL*)imageUrl
{
    NSString *imageName = [self getImageName:imageUrl];

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

- (void) requestImage:(NSURL*)imageUrl 
withCompletionHandler:(void (^)(UIImage* image, NSError *error))handler
{
    NSLog(@"Requesting image: %@", imageUrl);

    // [moiz] would be nice to figure out a way to allow managing multiple 
    //  requests somehow, not sure how useful this really is though

    __block NSString *imageName = [self getImageName:imageUrl];

    // check if request for image already exists
    if ([mImageRequests valueForKey:imageName]) {
        return;
    }

    // submit a web request to grab the data
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:imageUrl];
    [request setCompletionBlock:^{
        UIImage *image = [UIImage imageWithData:[request responseData]];
        [mImages setValue:image forKey:imageName];

        // run handler
        handler(image, nil);

        // cleanup
        [mImageRequests removeObjectForKey:imageName];
    }];

    // setup fail block
    [request setFailedBlock:^{
        handler(nil, [request error]);
        [mImageRequests removeObjectForKey:imageName];
    }];

    // start up request
    [request startAsynchronous];

    // cache request 
    [mImageRequests setValue:request forKey:imageName];
}

//------------------------------------------------------------------------------

- (void) cancelImageRequest:(NSURL*)imageUrl
{
    __block NSString *imageName = [self getImageName:imageUrl];

    // check if request for image already exists
    ASIHTTPRequest *request = [mImageRequests valueForKey:imageName];
    if (request) {
        [request clearDelegatesAndCancel];
        [mImageRequests removeObjectForKey:imageName];
    }
}

//------------------------------------------------------------------------------

- (void) deleteImage:(NSURL*)imageUrl
{
    NSString *imageName = [self getImageName:imageUrl];
    NSURL *fileUrl = 
        [[self getOrCreateIconDirectory] URLByAppendingPathComponent:imageName];

    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:fileUrl.path error:&error];
    if (error) {
        NSLog(@"IconManager: failed to delete image '%@': %@", fileUrl, error);
    }
}

//------------------------------------------------------------------------------

- (void) deleteAllImages
{
    NSLog(@"IconManager: purging all images.");

    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *iconDirectory       = [self getIconDirectory];
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
    BOOL is_dir;
    bool result = true;
    NSFileManager *file_manager = [NSFileManager defaultManager]; 
    if (![file_manager fileExistsAtPath:directory.path isDirectory:&is_dir]) {
        NSLog(@"IconManager: creating dir: %@", directory.path);
        result = [file_manager createDirectoryAtPath:directory.path 
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
    
- (NSString*) getImageName:(NSURL*)imageUrl
{
    // [moiz] temp till dinos fixes the path name 
    NSArray *pathComponents = [imageUrl pathComponents];
    NSString *imageName     =  [pathComponents objectAtIndex:pathComponents.count - 2];
    return imageName;

    //return [imageUrl lastPathComponent];
}

//------------------------------------------------------------------------------

@end
