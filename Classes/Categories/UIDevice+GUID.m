//
//  UIDevice+GUID.m
//  TikTok
//
//  Created by Moiz Merchant on 01/05/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes 
//-----------------------------------------------------------------------------

#import "UIDevice+GUID.h"

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation UIDevice (GUID)

//-----------------------------------------------------------------------------

- (NSString*) generateGUID
{
    // generate guid
    CFUUIDRef uuid        = CFUUIDCreate(NULL);
    CFStringRef uuidCFStr = CFUUIDCreateString(NULL, uuid);

    // bridge over to objc
    NSString *uuidNSStr = $string((NSString*)uuidCFStr);
    
    // cleanup
    CFRelease(uuid);
    CFRelease(uuidCFStr);

    return uuidNSStr;
}

//-----------------------------------------------------------------------------

@end
