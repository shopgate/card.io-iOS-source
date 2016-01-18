//
//  CardIOOutput.m
//  icc
//
//  Created by Shopgate on 11.01.16.
//
//

#import "CardIOOutput+Internal.h"
#import "CardIOVideoStream.h"

/** Degrees to Radian **/
#define radians( degrees ) ( ( degrees ) / 180.0 * M_PI )


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

+(instancetype)outputImageScannerWithOutputSettings:(NSDictionary*)outputSettings doOnScannedImmage:(void(^)(UIImage* scannedImage))onScannedImage doOnError:(void(^)(NSError* error,NSString* requestId))onError{
  return [[CardIOOutputImageScanner alloc] initWithOutputSettings:(NSDictionary*)outputSettings doOnScannedImmage:onScannedImage doOnError:onError];
}

-(instancetype)initWithOutputSettings:(NSDictionary*)outputSettings doOnScannedImmage:(void(^)(UIImage* scannedImage))onScannedImage doOnError:(void(^)(NSError* error,NSString* requestId))onError{
  if ((self = [super init])) {
    self.onScannedImage = onScannedImage;
    self.onError = onError;
    self.outputSettings = outputSettings;
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


-(void)scanImageWithMaxWidth:(NSNumber*)maxWidth maxHeight:(NSNumber*)maxHeight requestID:(NSString *)requestID {
  //number in nil is maximal height or width
  
  __block CGFloat block_maxWidth = maxWidth ? MAX([maxWidth floatValue], 1) : 0;
  __block CGFloat block_maxHeight = maxHeight ? MAX([maxHeight floatValue], 1) : 0;
  
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
    __weak typeof(self) weakSelf = self;
    [((AVCaptureStillImageOutput*)self.captureOutput) captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
      
      if (error) {
        weakSelf.onError(error,requestID);
        return;
      }
      
      CGFloat rotationDegrees = 0;
      switch (self.videoStream.interfaceOrientation) {
        case UIInterfaceOrientationUnknown:
          rotationDegrees = 90;
          break;
        case UIInterfaceOrientationPortrait:
          rotationDegrees = 90;
          break;
        case UIInterfaceOrientationPortraitUpsideDown:
          rotationDegrees = -90;
          break;
        case UIInterfaceOrientationLandscapeLeft:
          rotationDegrees = 180 ;
          break;
        case UIInterfaceOrientationLandscapeRight:
          rotationDegrees = 0;
          break;
          
        default:
          break;
      }
      
      
      CFRetain(imageSampleBuffer);
      UIImage * image = [weakSelf imageFromSampleBuffer:imageSampleBuffer withMaxWidth:0 maxHeight:0 RotatedByDegrees:
                         rotationDegrees];
      CFRelease(imageSampleBuffer);
      
      weakSelf.onScannedImage(image);
    }];
  }
  
  
}


// Create a UIImage from sample buffer data
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer withMaxWidth:(CGFloat)setMaxWidth maxHeight:(CGFloat)setMaxHeight RotatedByDegrees:(CGFloat)rotation{
  //a float value of 0 for setMaxWidth or setMaxHeight means width or height of buffer
  
  // Get a CMSampleBuffer's Core Video image buffer for the media data
  CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  // Lock the base address of the pixel buffer
  CVPixelBufferLockBaseAddress(imageBuffer, 0);
  
  // Get the number of bytes per row for the pixel buffer
  void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
  
  // Get the number of bytes per row for the pixel buffer
  size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
  // Get the pixel buffer width and height
  size_t width = CVPixelBufferGetWidth(imageBuffer);
  size_t height = CVPixelBufferGetHeight(imageBuffer);
  
  // Create a device-dependent RGB color space
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  
  // Create a bitmap graphics context with the sample buffer data
  CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                               bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
  
  BOOL turned = (fabs((double)rotation)==90.f); //turned 90° or -90?
  
  CGFloat maxWidth = setMaxWidth >= 1.f ? setMaxWidth : (turned ? height : width);
  CGFloat maxHeight = setMaxHeight >= 1.f ? setMaxHeight : (turned ? width : height);
  
  CGFloat resizeMaxWidth = turned ? maxHeight : maxWidth;
  CGFloat resizeMaxHeight = turned ? maxWidth : maxHeight;
  
  //resize image
  CGFloat ratioPic = ((CGFloat)width)/((CGFloat)height);
  CGFloat ratioResult = resizeMaxWidth/resizeMaxHeight;
  
  CGSize resizeSize = ratioPic<=ratioResult ?
  CGSizeMake(  (NSInteger)(width/(height/resizeMaxHeight)), resizeMaxHeight)
  : CGSizeMake(resizeMaxWidth, (NSInteger)(height/(width/resizeMaxWidth))   );
  
  
  CGContextRef resizedImageRef = [self makeContextOfSize:resizeSize];
  CGContextRetain(resizedImageRef);
  CGRect rectResizedImage = CGRectMake(0.0,0.0,resizeSize.width,resizeSize.height);
  
  // Create a Quartz image from the pixel data in the bitmap graphics context
  CGImageRef quartzImage = CGBitmapContextCreateImage(context);
  
  // Free up the context and color space
  CGContextRelease(context);
  CGColorSpaceRelease(colorSpace);
  
  
  CGContextDrawImage (resizedImageRef,rectResizedImage,quartzImage);
  CGImageRef Test = CGBitmapContextCreateImage(resizedImageRef);
  
  
  UIImage * ouputImage = [self imageRotatedFrom:[UIImage imageWithCGImage:Test] byDegrees:rotation];
  
  // Unlock the pixel buffer
  CVPixelBufferUnlockBaseAddress(imageBuffer,0);
  
  
  // final memory management
  CGContextRelease(resizedImageRef);
  CGImageRelease(quartzImage);
  CGImageRelease(Test);
  
  return (ouputImage);
}

-(CGContextRef)makeContextOfSize:(CGSize)pSize {
  
  size_t zIntBitmapBytesPerRow  = (size_t)(pSize.width * 4); // rgb alpha
  size_t zIntBitmapTotalBytes  = (size_t)(zIntBitmapBytesPerRow * pSize.height);
  
  void * ptrToBitmap = malloc(zIntBitmapTotalBytes);
  if (ptrToBitmap == NULL) {
    NSLog(@"makeContext error on malloc");
    exit(1);
  } // end if
  
  CGContextRef zBitmapContextRef = CGBitmapContextCreate(
                                                         ptrToBitmap,
                                                         (size_t)pSize.width,
                                                         (size_t)pSize.height,
                                                         8,
                                                         zIntBitmapBytesPerRow,
                                                         CGColorSpaceCreateDeviceRGB(),
                                                         kCGImageAlphaNoneSkipFirst
                                                         );

  CFAutorelease(zBitmapContextRef);
  
  return zBitmapContextRef;
}

- (UIImage *)imageRotatedFrom:(UIImage*)image byDegrees:(CGFloat)degrees{
  // calculate the size of the rotated view's containing box for our drawing space
  if ( (abs((int)degrees)%360)==0 ) {
    return image;
  }
  
  
  UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,image.size.width, image.size.height)];
  CGAffineTransform t = CGAffineTransformMakeRotation((CGFloat)radians(degrees));
  rotatedViewBox.transform = t;
  CGSize rotatedSize = rotatedViewBox.frame.size;
  
  // Create the bitmap context
  UIGraphicsBeginImageContext(rotatedSize);
  CGContextRef bitmap = UIGraphicsGetCurrentContext();
  
  // Move the origin to the middle of the image so we will rotate and scale around the center.
  CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
  
  // Rotate the image context
  CGContextRotateCTM(bitmap, (CGFloat)radians(degrees));
  
  // Now, draw the rotated/scaled image into the context
  CGContextScaleCTM(bitmap, 1.0, -1.0);
  CGContextDrawImage(bitmap, CGRectMake(-image.size.width / 2, -image.size.height / 2, image.size.width, image.size.height), [image CGImage]);
  
  UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return newImage;
  
}
@end