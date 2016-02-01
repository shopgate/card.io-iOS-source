//
//  CardIOOutput.m
//  icc
//
//  Created by Shopgate on 11.01.16.
//
//

#import "CardIOOutput+Internal.h"
#import "CardIOUtilities.h"
#import "CardIOMacros.h"
#import "CardIOLogger.h"
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
#ifdef CARDIO_DEBUG
  [CardIOOutputMethodNotOverriddenException raise:@"CardIOOutputMethodNotOverriddenException" format:@"CardIOOutput: <%@> does not override captureOutput()",[self class]];
#endif
  return nil;
}

@end



@implementation CardIOOutputCardScanner

+(instancetype)outputCardScannerDoOnCardDetection:(void(^)(CardIOView *cardIOView, CardIOCreditCardInfo *detectedCardInfo))onDetectedCard{
  if (!onDetectedCard) {
    CardIOLogError(@"%@.%@(): %@ cannot instanciate without completionBlock: %@()!",NSStringFromClass([self class]),NSStringFromSelector(_cmd),NSStringFromClass([self class]),@"onDetectedCard");
    return nil;
  }
  return [[CardIOOutputCardScanner alloc] initCardScannerDoOnCardDetection:onDetectedCard];
}

-(instancetype)init {
  [CardIOOutputManualInitException raise:@"ManuCardIOOutputManualInitException" format:@"You shouldn't initialize %@ by calling alloc() and init(), use a class method instead",[self class]];
  if (self = [super init]){
    return self;
  }
  return nil;
}

-(instancetype)initCardScannerDoOnCardDetection:(void (^)(CardIOView *, CardIOCreditCardInfo *))onDetectedCard{
  if (self = [super init]) {
    self.onDetectedCard = onDetectedCard;
    return self;
  }
  return nil;
}

@end



@implementation CardIOOutputMetadataScanner

+(instancetype)outputMetadataScannerWithTypes:(NSArray*)metadataTypes doOnMetadataDetection:(void (^)(AVCaptureOutput *, NSArray *, AVCaptureConnection *))onDetectedMetadata{
  if (!onDetectedMetadata) {
    CardIOLogError(@"%@.%@(): %@ cannot instanciate without completionBlock: %@()!",NSStringFromClass([self class]),NSStringFromSelector(_cmd),NSStringFromClass([self class]),@"onDetectedMetadata");
    return nil;
  }
  return [[CardIOOutputMetadataScanner alloc] initWithTypes:metadataTypes doOnMetadataDetection:onDetectedMetadata];
}

-(instancetype)init {
  [CardIOOutputManualInitException raise:@"ManuCardIOOutputManualInit" format:@"You shouldn't initialize %@ by calling alloc() and init(), use a class method instead",[self class]];
  if (self = [super init]){
    return self;
  }
  return nil;
}

-(instancetype)initWithTypes:(NSArray*)metadataTypes doOnMetadataDetection:(void(^)(AVCaptureOutput *captureOutput, NSArray *outputMetadataObjects, AVCaptureConnection *fromConnection))onDetectedMetaData{
  if (self = [super init]) {
    if (!metadataTypes || metadataTypes.count==0) {
      CardIOLogDebug(@"%@.%@(): No specific metadata types given, all available metadata types will be used!", NSStringFromClass([self class]),NSStringFromSelector(_cmd));
    }
    
    self.metadataTypes = metadataTypes;
    self.onDetectedMetadata = onDetectedMetaData;
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
  dispatch_async(dispatch_get_main_queue(), ^{
    self.onDetectedMetadata(captureOutput,metadataObjects,connection);
  });
}

#pragma mark - VideoStreaming

-(void)wasAddedByVideoStream:(CardIOVideoStream *)videoStream{
  if (!self.metadataTypes.count) {
    self.metadataTypes = [((AVCaptureMetadataOutput*)self.captureOutput) availableMetadataObjectTypes];
  }
  ((AVCaptureMetadataOutput*)self.captureOutput).metadataObjectTypes = self.metadataTypes;
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

+(instancetype)outputImageScannerWithOutputSettings:(NSDictionary*)outputSettings doOnScannedImmage:(void(^)(UIImage* scannedImage, NSDictionary *info))onScannedImage doOnError:(void(^)(NSError* error, NSDictionary *info))onError{
  if (!onScannedImage) {
    CardIOLogError(@"%@.%@(): %@ cannot instanciate without completionBlock: %@()!",NSStringFromClass([self class]),NSStringFromSelector(_cmd),NSStringFromClass([self class]),@"onScannedImage");
    return nil;
  }
  if (!onError) {
    CardIOLogError(@"%@.%@(): %@ cannot instanciate without errorBlock: %@()!",NSStringFromClass([self class]),NSStringFromSelector(_cmd),NSStringFromClass([self class]),@"onError");
    return nil;
  }
  return [[CardIOOutputImageScanner alloc] initWithOutputSettings:(NSDictionary*)outputSettings doOnScannedImmage:onScannedImage doOnError:onError];
}

-(instancetype)initWithOutputSettings:(NSDictionary*)outputSettings doOnScannedImmage:(void(^)(UIImage* scannedImage, NSDictionary *info))onScannedImage doOnError:(void(^)(NSError* error, NSDictionary* info))onError{
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


-(void)scanImageWithMaxWidth:(NSNumber*)maxWidth maxHeight:(NSNumber*)maxHeight info:(NSDictionary *)info {
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
        weakSelf.onError(error,info);
        return;
      }
      
      CGFloat rotationDegrees = 0;
      switch (self.currentInterfaceOrientation) {
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
      UIImage * image = [weakSelf imageFromSampleBuffer:imageSampleBuffer withMaxWidth:block_maxWidth maxHeight:block_maxHeight RotatedByDegrees:
                         rotationDegrees];
      CFRelease(imageSampleBuffer);
      
      weakSelf.onScannedImage(image,info);
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
  

  
  //context for resized image
  size_t zIntBitmapBytesPerRow  = (size_t)(resizeSize.width * 4); // rgb alpha
  size_t zIntBitmapTotalBytes  = (size_t)(zIntBitmapBytesPerRow * resizeSize.height);
  
  void * ptrToBitmap = malloc(zIntBitmapTotalBytes);
  if (ptrToBitmap == NULL) {
    NSLog(@"makeContext error on malloc");
    exit(1);
  } // end if
  
  CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
  CGContextRef resizedImageRef = CGBitmapContextCreate(
                                                         ptrToBitmap,
                                                         (size_t)resizeSize.width,
                                                         (size_t)resizeSize.height,
                                                         8,
                                                         zIntBitmapBytesPerRow,
                                                         colorSpaceRef,
                                                         kCGImageAlphaNoneSkipFirst
                                                         );
  
  //CGContextRetain(resizedImageRef);
  CGRect rectResizedImage = CGRectMake(0.0,0.0,resizeSize.width,resizeSize.height);
  
  // Create a Quartz image from the pixel data in the bitmap graphics context
  CGImageRef quartzImage = CGBitmapContextCreateImage(context);
  
  // Free up the context and color space
  CGContextRelease(context);
  CGColorSpaceRelease(colorSpace);
  
  
  CGContextDrawImage (resizedImageRef,rectResizedImage,quartzImage);
  CGImageRef imageRef = CGBitmapContextCreateImage(resizedImageRef);
  
  
  UIImage * ouputImage = [self imageRotatedFrom:[UIImage imageWithCGImage:imageRef] byDegrees:rotation];
  
  // Unlock the pixel buffer
  CVPixelBufferUnlockBaseAddress(imageBuffer,0);
  
  
  // final memory management
  CGColorSpaceRelease(colorSpaceRef);
  CGContextRelease(resizedImageRef);
  CGImageRelease(quartzImage);
  CGImageRelease(imageRef);
  
  return (ouputImage);
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