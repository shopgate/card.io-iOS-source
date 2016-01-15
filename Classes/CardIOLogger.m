//
//  CardIOLogger.m
//  icc
//
//  Created by Shopgate on 15.01.16.
//
//

#import "CardIOLogger.h"



@interface CardIOLogger ()
@property (nonatomic, copy) void (^log)(NSString* message);
+(CardIOLogger*)sharedInstance;
@end


@implementation CardIOLogger

+(CardIOLogger *)sharedInstance{
  static CardIOLogger *__sharedInstance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    __sharedInstance = [[CardIOLogger alloc] init];
    __sharedInstance.log = ^void(NSString* message) {
      NSLog(@"%@",message);
    };
  });
  return __sharedInstance;
}

+(void)logMessage:(NSString*) format, ... NS_FORMAT_FUNCTION(1,2){
  va_list args;
  va_start(args, format);
  NSString * message = [[NSString alloc]initWithFormat:format arguments:args];
  va_end(args);
  
  return [CardIOLogger sharedInstance].log(message);
}
+(void)setLoggingBlock:(LoggingBlock) loggingBlock{
  [CardIOLogger sharedInstance].log = loggingBlock;
}
@end
