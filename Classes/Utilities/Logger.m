//
//  Logger.m
//  TikTok
//
//  Created by Moiz Merchant on 05/02/12.
//  Copyright 2012 TikTok. All rights reserved.
//

//-----------------------------------------------------------------------------
// includes
//-----------------------------------------------------------------------------

#import "Logger.h"

//-----------------------------------------------------------------------------
// interface definition
//-----------------------------------------------------------------------------

@interface Logger ()
    + (NSURL*) applicationDocumentsDirectory;
    + (NSString*) getLogPath;
@end

//-----------------------------------------------------------------------------
// interface implementation
//-----------------------------------------------------------------------------

@implementation Logger

//-----------------------------------------------------------------------------

+ (void) logInfo:(NSString*)message
{
    // setup date formater
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeStyle:NSDateFormatterMediumStyle];

    // format message
    NSString *logTime    = [formatter stringFromDate:[NSDate date]];
    NSString *logMessage = $string(@"%@ %@", logTime, message);

    // append to file
    NSString* logPath = [Logger getLogPath];
    FILE* file = fopen([logPath UTF8String], "at");
    fprintf(file, "%s\n", [logMessage UTF8String]);
    fclose(file);

    // cleanup
    [formatter release];
}

//-----------------------------------------------------------------------------

+ (void) clearLog
{
    NSString *empty = @"";
    NSString *logPath = [Logger getLogPath];
    [empty writeToFile:logPath
            atomically:NO
              encoding:NSStringEncodingConversionAllowLossy
                 error:nil];
}

//-----------------------------------------------------------------------------

+ (NSString*) getLog
{
    NSString *logPath = [Logger getLogPath];
    NSString *log     = [NSString stringWithContentsOfFile:logPath
                                              usedEncoding:nil
                                                     error:nil];
    return log;
}

//------------------------------------------------------------------------------
#pragma mark - Filesystem
//------------------------------------------------------------------------------

+ (NSURL*) applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager]
        URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask]
        lastObject];
}

//------------------------------------------------------------------------------

+ (NSString*) getLogPath
{
    // construct path to storage on disk
    NSString *logPath = [[[Logger applicationDocumentsDirectory]
        URLByAppendingPathComponent:@"log.txt"] path];
    return logPath;
}

//-----------------------------------------------------------------------------

@end

