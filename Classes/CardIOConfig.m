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
    _allowedInterfaceOrientationMask = 0;
    _automaticTorchModeEnabled = YES;
    _automaticVibrationModeEnabled = YES;
    _animatedShutter = YES;
  }
  return self;
}


-(void)addOutput:(CardIOOutput *)output {
  self.outputs = [self.outputs arrayByAddingObject:output];
  CardIOLogVerbose(@"CardIOOutput %@ of type %@ has been added.", output ,ClassStringFromObject(output));
}

-(BOOL)removeOutput:(CardIOOutput *)output {
  if ([self.outputs containsObject:output]) {
    NSMutableArray* outputs = [self.outputs mutableCopy];
    [outputs removeObject:output];
    self.outputs = outputs;
    CardIOLogVerbose(@"CardIOOutput %@ of type %@ has been removed.", output ,ClassStringFromObject(output));
    return YES;
  } else {
    //TODO: Error
    CardIOLogWithLevel(CardIOLogLevelWarning, @"Couldn't remove output <%@>, since it wasn't set before",NSStringFromClass([output class]));
    return NO;
  }
}

@end
