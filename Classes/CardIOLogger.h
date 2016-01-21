//
//  CardIOLogger.h
//  icc
//
//  Created by Shopgate on 15.01.16.
//
//

#import <Foundation/Foundation.h>
#import "CardIOUtilities.h"

@interface CardIOLogger : NSObject
/// Standard method to log something with NSLog if no logging Block is set, or calling the external logging block, with an log level of CardIOLogLevelDebug.
+(void)logMessage:(NSString*) format, ... NS_FORMAT_FUNCTION(1,2);

/// Logs a message with NSLog if no logging Block is set, or calling the external logging block, using tge given log level.
+(void)logWithLevel:(CardIOLogLevel)logLevel message:(NSString*) format, ... NS_FORMAT_FUNCTION(2,3);

/// By setting this block, instead of logging with NSLog, cardIO calles this block, in which other log method tham NSLog can be used.
+(void)setLoggingBlock:(LoggingBlock)loggingBlock;
@end

