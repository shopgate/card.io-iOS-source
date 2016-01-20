//
//  CardIOConfig.m
//  See the file "LICENSE.md" for the full license governing this code.
//

#import "CardIOConfig+Internal.h"
#import "CardIOMacros.h"



@implementation CardIOConfig

- (instancetype)init {
  if ((self = [super init])) {
    _allowFreelyRotatingCardGuide = YES;
    _scanReport = [[CardIOAnalytics alloc] initWithContext:nil];
    _scanExpiry = YES;
  }
  return self;
}


-(void)addOutput:(CardIOOutput *)output {
  self.outputs = [self.outputs arrayByAddingObject:output];
}

-(BOOL)removeOutput:(CardIOOutput *)output {
  if ([self.outputs containsObject:output]) {
    NSMutableArray* outputs = [self.outputs mutableCopy];
    [outputs removeObject:output];
    self.outputs = outputs;
    return YES;
  } else {
    //TODO: Error
    CardIOLogWithLevel(CardIOLevelWarning, @"Couldn't remove output <%@>, since it wasn't set before",NSStringFromClass([output class]));
    return NO;
  }
}

@end
