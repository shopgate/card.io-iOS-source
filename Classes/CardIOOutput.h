//
//  CardIOOutput.h
//  icc
//
//  Created by Shopgate on 11.01.16.
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "CardIOView.h"
/**
 *  Abstract class
 */
@interface CardIOOutput : NSObject
@end






@interface CardIOOutputCardScanner : CardIOOutput
+(instancetype)outputCardScannerDoOnCardDetection:(void(^)(CardIOView *cardIOView, CardIOCreditCardInfo *detectedCardInfo))onDetectedCard;
@end


@interface CardIOOutputMetadataScanner : CardIOOutput
+(instancetype)outputMetadataScannerWithTypes:(NSArray*)metadataTypes doOnMetadataDetection:(void(^)(AVCaptureOutput *captureOutput, NSArray *outputMetadataObjects, AVCaptureConnection *fromConnection))onDetectedMetadata;
@end

@interface CardIOOutputImageScanner : CardIOOutput
+(instancetype)outputImageScannerWithOutputSettings:(NSDictionary*)outputSettings
                                  doOnScannedImmage:(void(^)(UIImage* scannedImage, NSDictionary *info))onScannedImage
                                          doOnError:(void(^)(NSError* error, NSDictionary *info))onError;

-(void)scanImageWithMaxWidth:(NSNumber*)maxWidth maxHeight:(NSNumber*)maxHeight info:(NSDictionary *)info;
@end