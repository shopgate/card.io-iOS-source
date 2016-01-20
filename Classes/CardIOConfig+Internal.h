//
//  CardIOConfig+Internal.h
//  icc
//
//  Created by Shopgate on 19.01.16.
//
//

#import "CardIOConfig.h"
#import "CardIOOutput.h"

@interface CardIOConfig ()

-(void)addOutput:(CardIOOutput *)output;
-(BOOL)removeOutput:(CardIOOutput *)output;

@property(nonatomic, assign, readwrite)  BOOL isAutoInterupted;
@end
