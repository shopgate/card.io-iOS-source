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
+(void)logMessage:(NSString*) format, ... NS_FORMAT_FUNCTION(1,2);
+(void)logWithLevel:(CardIOLevel)logLevel message:(NSString*) format, ... NS_FORMAT_FUNCTION(2,3);
+(void)setLoggingBlock:(LoggingBlock)loggingBlock;
@end

