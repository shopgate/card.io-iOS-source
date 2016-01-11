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
+(instancetype)outputCardScannerDoOnCardDetection:(void(^)(CardIOView *cardIOView, CardIOCreditCardInfo *detectedCardInfo))onDetectedCard doOnError:(void(^)(NSError** error))onError;
@end


@interface CardIOOutputBarcodeScanner : CardIOOutput
+(instancetype)outputBarcodeScannerDoOnBarcodeDetection:(void(^)(AVCaptureOutput *captureOutput, NSArray *outputMetadataObjects, AVCaptureConnection *fromConnection))onDetectedBarcode doOnError:(void(^)(NSError** error))onError;
@end

@interface CardIOOutputImageScanner : CardIOOutput
+(instancetype)outputImageScannerDoOnScannedImmage:(void(^)(UIImage* scannedImage))onScannedImage doOnError:(void(^)(NSError** error))onError;
-(void)scanImage;
@end