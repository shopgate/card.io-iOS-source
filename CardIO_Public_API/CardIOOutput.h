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


/// CardIOOutputs shall always be instanciated by using the class methods, not any init methods


#pragma mark - Output for Credit card scanner


@interface CardIOOutputCardScanner : CardIOOutput
/// Returns a fresh CardIOOutputCardScanner. The onDetectedCard card will be performed when a credit card is detected.
+(instancetype)outputCardScannerDoOnCardDetection:(void(^)(CardIOView *cardIOView, CardIOCreditCardInfo *detectedCardInfo))onDetectedCard;
@end


#pragma mark - Output for Metadata

@interface CardIOOutputMetadataScanner : CardIOOutput
/// Returns a fresh CardIOOutputMetadataScanner. The metadata types array has to be availabe for a AVCaptureMetadata
+(instancetype)outputMetadataScannerWithTypes:(NSArray*)metadataTypes doOnMetadataDetection:(void(^)(AVCaptureOutput *captureOutput, NSArray *outputMetadataObjects, AVCaptureConnection *fromConnection))onDetectedMetadata;
@end


#pragma mark - Output for Still image


@interface CardIOOutputImageScanner : CardIOOutput
/// Returns a fresh CardIOOutputImageScanner. The doOnScannedImmage and the doOnError block will be called after the
/// scanImageWithMaxWidth:maxHeight:info method was called to request a image scan. The doOnScannedImmage will be called on succes,
/// doOnError will be called when an error occured on taking an image.
+(instancetype)outputImageScannerWithOutputSettings:(NSDictionary*)outputSettings
                                  doOnScannedImmage:(void(^)(UIImage* scannedImage, NSDictionary *info))onScannedImage
                                          doOnError:(void(^)(NSError* error, NSDictionary *info))onError;

/// Requests an image from the CardIOOutputImageScanner. Using maxWitdh and maxHeight reduces the maxSize of the outcomming image.
/// This image will keep his ratio. Using nil on either maxWidth or maxHeight intends the image scanner to use the current present of the session.
/// The info dictionary can be used to maintain any info within the doOnScannedImmage or doOnError - block that will be called.
/// The info dictionary won't be be touched from the scanner.
-(void)scanImageWithMaxWidth:(NSNumber*)maxWidth maxHeight:(NSNumber*)maxHeight info:(NSDictionary *)info;
@end