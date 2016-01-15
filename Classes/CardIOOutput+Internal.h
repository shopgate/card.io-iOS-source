//
//  CardIOOutput+Internal.h
//  icc
//
//  Created by Shopgate on 11.01.16.
//
//

#import "CardIOOutput.h"

#import "CardIOVideoStream.h"


@protocol CARDIOOutputVideoStreaming <NSObject>
@optional
-(void)wasAddedByVideoStream:(CardIOVideoStream*)videoStream;
@end


@interface CardIOOutput ()<CARDIOOutputVideoStreaming> {
  @protected
    AVCaptureOutput * _captureOutput;
}
@property (nonatomic, weak) CardIOVideoStream * videoStream;
@property (nonatomic, strong, readonly) AVCaptureOutput * captureOutput;
@end



@interface CardIOOutputCardScanner ()
@property (nonatomic, copy) void(^onDetectedCard)(CardIOView *cardIOView, CardIOCreditCardInfo *detectedCardInfo);
@property (nonatomic, copy) void(^onError)(NSError** error);
-(instancetype)initCardScannerDoOnCardDetection:(void(^)(CardIOView *cardIOView, CardIOCreditCardInfo *detectedCardInfo))onDetectedCard doOnError:(void(^)(NSError** error))onError;
@end


@interface CardIOOutputMetadataScanner ()<AVCaptureMetadataOutputObjectsDelegate>
@property (nonatomic, strong) NSArray* metadataTypes;
@property (nonatomic, copy) void(^onDetectedMetadata)(AVCaptureOutput *captureOutput, NSArray *outputMetadataObjects, AVCaptureConnection *fromConnection);
@property (nonatomic, copy) void(^onError)(NSError** error);
-(instancetype)initWithTypes:(NSArray*)metadataTypes doOnMetadataDetection:(void(^)(AVCaptureOutput *captureOutput, NSArray *outputMetadataObjects, AVCaptureConnection *fromConnection))onDetectedMetadata doOnError:(void(^)(NSError** error))onError;
@end





@interface CardIOOutputImageScanner ()
@property (nonatomic, copy) void(^onScannedImage)(UIImage* scannedImage);
@property (nonatomic, copy) void(^onError)(NSError** error);
@property (nonatomic, strong) NSDictionary* outputSettings;
-(instancetype)initWithOutputSettings:(NSDictionary*)outputSettings doOnScannedImmage:(void(^)(UIImage* scannedImage))onScannedImage doOnError:(void(^)(NSError** error))onError;
@end