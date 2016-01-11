//
//  CardIOOutput.m
//  icc
//
//  Created by Shopgate on 11.01.16.
//
//

#import "CardIOOutput+Internal.h"


@implementation CardIOOutputManualInit
@end



@implementation CardIOOutput

-(instancetype)init {
  if (self = [super init]){
    return self;
  }
  return nil;
}


@end



@implementation CardIOOutputCardScanner
+(instancetype)outputCardScannerDoOnCardDetection:(void(^)(CardIOView *cardIOView, CardIOCreditCardInfo *detectedCardInfo))onDetectedCard doOnError:(void(^)(NSError** error))onError{
  return [[CardIOOutputCardScanner alloc] initCardScannerDoOnCardDetection:onDetectedCard doOnError:onError];
}

-(instancetype)init {
  [CardIOOutputManualInit raise:@"ManuCardIOOutputManualInit" format:@"You shouldn't initialize %@ by calling alloc() and init(), use a class method instead",[self class]];
  if (self = [super init]){
    return self;
  }
  return nil;
}

-(instancetype)initCardScannerDoOnCardDetection:(void (^)(CardIOView *, CardIOCreditCardInfo *))onDetectedCard doOnError:(void (^)(NSError *__autoreleasing *))onError{
  if (self = [super init]) {
    self.onDetectedCard = onDetectedCard;
    self.onError = onError;
    return self;
  }
  return nil;
}
@end



@implementation CardIOOutputBarcodeScanner

+(instancetype)outputBarcodeScannerDoOnBarcodeDetection:(void (^)(AVCaptureOutput *, NSArray *, AVCaptureConnection *))onDetectedBarcode doOnError:(void (^)(NSError *__autoreleasing *))onError{
  return [[CardIOOutputBarcodeScanner alloc] initDoOnBarcodeDetection:onDetectedBarcode doOnError:onError];
}

-(instancetype)init {
  [CardIOOutputManualInit raise:@"ManuCardIOOutputManualInit" format:@"You shouldn't initialize %@ by calling alloc() and init(), use a class method instead",[self class]];
  if (self = [super init]){
    return self;
  }
  return nil;
}

-(instancetype)initDoOnBarcodeDetection:(void(^)(AVCaptureOutput *captureOutput, NSArray *outputMetadataObjects, AVCaptureConnection *fromConnection))onDetectedBarcode doOnError:(void(^)(NSError** error))onError{
  if (self = [super init]) {
    self.onDetectedBarcode = onDetectedBarcode;
    self.onError = onError;
    return self;
  }
  return nil;
}
@end




@implementation CardIOOutputImageScanner

-(instancetype)init {
  [CardIOOutputManualInit raise:@"ManuCardIOOutputManualInit" format:@"You shouldn't initialize %@ by calling alloc() and init(), use a class method instead",[self class]];
  if (self = [super init]){
    return self;
  }
  return nil;
}

+(instancetype)outputImageScannerDoOnScannedImmage:(void(^)(UIImage* scannedImage))onScannedImage doOnError:(void(^)(NSError** error))onError{
  return [[CardIOOutputImageScanner alloc] initDoOnScannedImmage:onScannedImage doOnError:onError];
}

-(instancetype)initDoOnScannedImmage:(void(^)(UIImage* scannedImage))onScannedImage doOnError:(void(^)(NSError** error))onError{
  if ((self = [super init])) {
    self.onScannedImage = onScannedImage;
    self.onError = onError;
    return self;
  }
  return nil;
}

-(void)scanImage{
  
}

@end