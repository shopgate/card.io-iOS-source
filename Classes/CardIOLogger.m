//
//  CardIOLogger.m
//  icc
//
//  Created by Shopgate on 15.01.16.
//
//

#import "CardIOLogger.h"
#import "CardIOUtilities.h"


@interface CardIOLogger ()
@property (nonatomic, copy) LoggingBlock log;
+(CardIOLogger*)sharedInstance;
@end


@implementation CardIOLogger

+(CardIOLogger *)sharedInstance{
  static CardIOLogger *__sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    __sharedInstance = [[CardIOLogger alloc] init];
    __sharedInstance.log = ^void(CardIOLogLevel loglevel ,NSString* message) {
      NSLog(@"%@",message);
    };
  });
  return __sharedInstance;
}

+(void)logMessage:(NSString*) format, ... {
  va_list args;
  va_start(args, format);
  NSString * message = [[NSString alloc]initWithFormat:format arguments:args];
  va_end(args);
  
  [CardIOLogger sharedInstance].log(CardIOLogLevelDebug,message);
}

+(void)logWithLevel:(CardIOLogLevel)logLevel message:(NSString *)format, ... {
  va_list args;
  va_start(args, format);
  NSString * message = [[NSString alloc]initWithFormat:format arguments:args];
  va_end(args);
  
  [CardIOLogger sharedInstance].log(logLevel, message);
}

+(void)setLoggingBlock:(LoggingBlock) loggingBlock{
  [CardIOLogger sharedInstance].log = loggingBlock;
}

@end
