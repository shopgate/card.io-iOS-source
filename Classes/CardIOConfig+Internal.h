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

/// Adds an output to the outputs array
-(void)addOutput:(CardIOOutput *)output;

/// Removes an output from the output array
/// Returns YES when the output was in the array before and could be removed.
-(BOOL)removeOutput:(CardIOOutput *)output;

@property(nonatomic, assign, readwrite)  BOOL isAutoInterupted;
@end
