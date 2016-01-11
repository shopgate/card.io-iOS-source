//
//  CardIOOutput+Internal.h
//  icc
//
//  Created by Shopgate on 11.01.16.
//
//

#import "CardIOOutput.h"

#import "CardIOVideoStream.h"

@interface CardIOOutputManualInit : NSException
@end



@interface CardIOOutput ()
@property (nonatomic, weak) CardIOVideoStream * videoStream;
@end



@interface CardIOOutputCardScanner ()
@property (nonatomic, copy) void(^onDetectedCard)(CardIOView *cardIOView, CardIOCreditCardInfo *detectedCardInfo;
@property (nonatomic, copy) void(^onError)(NSError** error);
-(instancetype)initCardScannerDoOnCardDetection:(void(^)(CardIOView *cardIOView, CardIOCreditCardInfo *detectedCardInfo))onDetectedCard doOnError:(void(^)(NSError** error))onError;
@end


@interface CardIOOutputBarcodeScanner ()
@property (nonatomic, copy) void(^onDetectedBarcode)(AVCaptureOutput *captureOutput, NSArray *outputMetadataObjects, AVCaptureConnection *fromConnection);
@property (nonatomic, copy) void(^onError)(NSError** error);
-(instancetype)initDoOnBarcodeDetection:(void(^)(AVCaptureOutput *captureOutput, NSArray *outputMetadataObjects, AVCaptureConnection *fromConnection))onDetectedBarcode doOnError:(void(^)(NSError** error))onError;
@end





@interface CardIOOutputImageScanner ()
@property (nonatomic, copy) void(^onScannedImage)(UIImage* scannedImage);
@property (nonatomic, copy) void(^onError)(NSError** error);
-(instancetype)initDoOnScannedImmage:(void(^)(UIImage* scannedImage))onScannedImage doOnError:(void(^)(NSError** error))onError;
@end