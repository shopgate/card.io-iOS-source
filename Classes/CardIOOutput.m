//
//  CardIOOutput.m
//  icc
//
//  Created by Shopgate on 11.01.16.
//
//

#import "CardIOOutput+Internal.h"

@interface CardIOOutputManualInitException : NSException
@end
@implementation CardIOOutputManualInitException
@end

@interface CardIOOutputMethodNotOverriddenException : NSException
@end
@implementation CardIOOutputMethodNotOverriddenException
@end


@implementation CardIOOutput
@synthesize captureOutput = _captureOutput;

-(AVCaptureOutput *)captureOutput{
  //has to be overridden
#ifdef DEBUG
  [CardIOOutputMethodNotOverriddenException raise:@"CardIOOutputMethodNotOverriddenException" format:@"CardIOOutput: <%@> does not override captureOutput()",[self class]];
#endif
  return nil;
}

@end



@implementation CardIOOutputCardScanner

+(instancetype)outputCardScannerDoOnCardDetection:(void(^)(CardIOView *cardIOView, CardIOCreditCardInfo *detectedCardInfo))onDetectedCard doOnError:(void(^)(NSError** error))onError{
  return [[CardIOOutputCardScanner alloc] initCardScannerDoOnCardDetection:onDetectedCard doOnError:onError];
}

-(instancetype)init {
  [CardIOOutputManualInitException raise:@"ManuCardIOOutputManualInitException" format:@"You shouldn't initialize %@ by calling alloc() and init(), use a class method instead",[self class]];
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



@implementation CardIOOutputMetadataScanner

+(instancetype)outputMetadataScannerWithTypes:(NSArray*)metadataTypes doOnMetadataDetection:(void (^)(AVCaptureOutput *, NSArray *, AVCaptureConnection *))onDetectedMetadata doOnError:(void (^)(NSError *__autoreleasing *))onError{
  return [[CardIOOutputMetadataScanner alloc] initWithTypes:metadataTypes doOnMetadataDetection:onDetectedMetadata doOnError:onError];
}

-(instancetype)init {
  [CardIOOutputManualInitException raise:@"ManuCardIOOutputManualInit" format:@"You shouldn't initialize %@ by calling alloc() and init(), use a class method instead",[self class]];
  if (self = [super init]){
    return self;
  }
  return nil;
}

-(instancetype)initWithTypes:(NSArray*)metadataTypes doOnMetadataDetection:(void(^)(AVCaptureOutput *captureOutput, NSArray *outputMetadataObjects, AVCaptureConnection *fromConnection))onDetectedMetaData doOnError:(void(^)(NSError** error))onError{
  if (self = [super init]) {
    self.metadataTypes = metadataTypes;
    self.onDetectedMetadata = onDetectedMetaData;
    self.onError = onError;
    return self;
  }
  return nil;
}
-(AVCaptureOutput *)captureOutput{
  if (!_captureOutput) {
    _captureOutput = [self metadataScannerOutput];
  }
  return _captureOutput;
}

-(AVCaptureMetadataOutput*)metadataScannerOutput{
  AVCaptureMetadataOutput * output = [[AVCaptureMetadataOutput alloc] init];
  output.metadataObjectTypes = [output availableMetadataObjectTypes];

  dispatch_queue_t queue = dispatch_queue_create("MetadataDetection", NULL);
  
  [output setMetadataObjectsDelegate:self queue:queue];
  return output;
}

#pragma mark - MetadataObjectsDelegate

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
  self.onDetectedMetadata(captureOutput,metadataObjects,connection);
}

#pragma mark - VideoStreaming

-(void)wasAddedByVideoStream:(CardIOVideoStream *)videoStream{
  ((AVCaptureMetadataOutput*)self.captureOutput).metadataObjectTypes = self.metadataTypes;
  
  //metadata types are no longer needed, so we can release them
  self.metadataTypes = nil;
}

@end




@implementation CardIOOutputImageScanner

-(instancetype)init {
  [CardIOOutputManualInitException raise:@"ManuCardIOOutputManualInit" format:@"You shouldn't initialize %@ by calling alloc() and init(), use a class method instead",[self class]];
  if (self = [super init]){
    return self;
  }
  return nil;
}

+(instancetype)outputImageScannerWithOutputSettings:(NSDictionary*)outputSettings doOnScannedImmage:(void(^)(UIImage* scannedImage))onScannedImage doOnError:(void(^)(NSError** error))onError{
  return [[CardIOOutputImageScanner alloc] initWithOutputSettings:(NSDictionary*)outputSettings doOnScannedImmage:onScannedImage doOnError:onError];
}

-(instancetype)initWithOutputSettings:(NSDictionary*)outputSettings doOnScannedImmage:(void(^)(UIImage* scannedImage))onScannedImage doOnError:(void(^)(NSError** error))onError{
  if ((self = [super init])) {
    self.onScannedImage = onScannedImage;
    self.onError = onError;
    return self;
  }
  return nil;
}

-(AVCaptureOutput *)captureOutput{
    if (!_captureOutput) {
      _captureOutput = [self imageCapturingOutput];
    }
    return _captureOutput;
}

-(AVCaptureStillImageOutput*)imageCapturingOutput{
  AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
  stillImageOutput.outputSettings = self.outputSettings;

  return stillImageOutput;
}


-(void)scanImage{
  
  AVCaptureConnection *videoConnection = nil;
  for (AVCaptureConnection *connection in self.captureOutput.connections) {
    for (AVCaptureInputPort *port in [connection inputPorts]) {
      if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
        videoConnection = connection;
        //videoConnection.videoOrientation = [self videoOrientatationFromCurrentDeviceOrientation];//[self videoOrientatationFromCurrentDeviceOrientation];
        break;
      }
    }
  }
  if (videoConnection) {
    [((AVCaptureStillImageOutput*)self.captureOutput) captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
      self.onScannedImage(nil);
      int test = 0;
    }];
  }
  
  
}

@end