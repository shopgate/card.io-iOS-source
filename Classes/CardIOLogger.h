//
//  CardIOLogger.h
//  icc
//
//  Created by Shopgate on 15.01.16.
//
//

#import <Foundation/Foundation.h>

typedef void (^ LoggingBlock)(NSString*);

@interface CardIOLogger : NSObject
+(void)logMessage:(NSString*) format, ... NS_FORMAT_FUNCTION(1,2);
+(void)setLoggingBlock:(LoggingBlock)loggingBlock;
@end

