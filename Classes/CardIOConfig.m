//
//  CardIOConfig.m
//  See the file "LICENSE.md" for the full license governing this code.
//

#import "CardIOConfig+Internal.h"



@implementation CardIOConfig

- (instancetype)init {
  if ((self = [super init])) {
    _allowFreelyRotatingCardGuide = YES;
    _scanReport = [[CardIOAnalytics alloc] initWithContext:nil];
    _scanExpiry = YES;
  }
  return self;
}

@end
