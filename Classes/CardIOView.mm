//
//  CardIOView.m
//  See the file "LICENSE.md" for the full license governing this code.
//

#if USE_CAMERA && SIMULATE_CAMERA
#error USE_CAMERA and SIMULATE_CAMERA are mutually exclusive!
#endif

#if USE_CAMERA || SIMULATE_CAMERA

#import "CardIOView.h"
#import "CardIOViewContinuation.h"
#import "CardIOUtilities.h"
#import "CardIOCameraView.h"
#import "CardIOCardOverlay.h"
#import "CardIOCardScanner.h"
#import "CardIOConfig+Internal.h"
#import "CardIOCreditCardInfo.h"
#import "CardIODevice.h"
#import "CardIOCGGeometry.h"
#import "CardIOLocalizer.h"
#import "CardIOMacros.h"
#import "CardIOOrientation.h"
#import "CardIOPaymentViewControllerContinuation.h"
#import "CardIOReadCardInfo.h"
#import "CardIOTransitionView.h"
#import "CardIOVideoFrame.h"
#import "CardIOVideoStreamDelegate.h"
#import "CardIOViewDelegate.h"
#import "NSObject+CardioCategoryTest.h"
#import "CardIODetectionMode.h"
#import "CardIOOutput+Internal.h"

NSString * const CardIOScanningOrientationDidChangeNotification = @"CardIOScanningOrientationDidChangeNotification";
NSString * const CardIOCurrentScanningOrientation = @"CardIOCurrentScanningOrientation";
NSString * const CardIOScanningOrientationAnimationDuration = @"CardIOScanningOrientationAnimationDuration";

@interface CardIOView () <CardIOVideoStreamDelegate,CardIOCameraViewDelegate>

@property(nonatomic, strong, readwrite) CardIOConfig *config;
@property(nonatomic, strong, readwrite) CardIOCameraView *cameraView;
@property(nonatomic, strong, readwrite) CardIOReadCardInfo *readCardInfo;
@property(nonatomic, strong, readwrite) UIImage *cardImage;

// These two properties were declared readonly in CardIOViewContinuation.h
@property(nonatomic, strong, readwrite) CardIOCardScanner *scanner;
@property(nonatomic, strong, readwrite) CardIOTransitionView *transitionView;

@property(nonatomic, assign, readwrite) BOOL scanHasBeenStarted;

@end


@implementation CardIOView

#pragma mark - Initialization and layout

- (id)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self commonInit];
    self.backgroundColor = [UIColor clearColor];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self commonInit];
  }
  return self;
}

-(instancetype)initWithFrame:(CGRect)frame outputs:(NSArray *)outputs {
  if (self = [self initWithFrame:frame]) {
    [self additionalInitWithOutputs:outputs captureSessionPreset:nil]; //nil = default of cardIO will be used
  }
  return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder outputs:(NSArray *)outputs {
  if (self = [self initWithCoder:aDecoder]) {
    [self additionalInitWithOutputs:outputs captureSessionPreset:nil];//nil = default of cardIO will be used
  }
  return self;
}

-(instancetype)initWithFrame:(CGRect)frame outputs:(NSArray *)outputs captureSessionPreset:(NSString *)sessionPreset {
  if (self = [self initWithFrame:frame]) {
    [self additionalInitWithOutputs:outputs captureSessionPreset:sessionPreset];
  }
  return self;
}

-(instancetype)initWithFrame:(CGRect)frame outputs:(NSArray *)outputs captureSessionPreset:(NSString *)sessionPreset fullscreenPreviewLayer:(BOOL)fullsScreenPreviewLayer{
  if (self = [self initWithFrame:frame outputs:outputs captureSessionPreset:sessionPreset]){
    self.config.fullscreenPreviewLayer = fullsScreenPreviewLayer;
  }
  return self;
}


- (void)commonInit {
  // test that categories are enabled
  @try {
    [NSObject testForObjCLinkerFlag];
  } @catch (NSException *exception) {
    [NSException raise:@"CardIO-IncompleteIntegration" format:@"Please add -ObjC to 'Other Linker Flags' in your project settings. (%@)", exception];
  }

  _config = [[CardIOConfig alloc] init];
  _config.scannedImageDuration = 1.0;
  _config.autoSessionStop = YES;
  _config.cardScannerEnabled = YES;
}

-(void)additionalInitWithOutputs:(NSArray*)outputs captureSessionPreset:(NSString *)sessionPreset {
  if (!outputs) {
    CardIOLogVerbose(@"CardIOView init with outputs where the outputs were nil. Outputs have to be added separately");
    outputs = [NSArray array];
  }
  self.config.outputs = outputs;
  self.config.forcedSessionPreset = sessionPreset;
  
  //define whether cardscanner is enabled or not
  _config.cardScannerEnabled = NO;
  for (CardIOOutput *output in self.config.outputs) {
    if ([[output class] isSubclassOfClass:[CardIOOutputCardScanner class]]) {
      _config.cardScannerEnabled = YES;
    }
  }
       
}

- (CGSize)sizeThatFits:(CGSize)size {
  return [self.cameraView sizeThatFits:size];
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  self.cameraView.frame = self.bounds;
  [self.cameraView sizeToFit];
  self.cameraView.center = CenterOfRect(CGRectZeroWithSize(self.bounds.size));

  [self.cameraView layoutIfNeeded];
}

- (void)setHidden:(BOOL)hidden {
  if (hidden != self.hidden) {
    if (hidden) {
      [self implicitStop];
      [super setHidden:hidden];
    }
    else {
      [super setHidden:hidden];
      [self implicitStart];
    }
  }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
  if (!newSuperview) {
    [self implicitStop];
  }
  [super willMoveToSuperview:newSuperview];
}

- (void)didMoveToSuperview {
  [super didMoveToSuperview];
  if (self.superview) {
    [self implicitStart];
  }
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
  if (!newWindow) {
    [self implicitStop];
  }
  [super willMoveToWindow:newWindow];
}

- (void)didMoveToWindow {
  [super didMoveToWindow];
  if (self.window) {
    [self implicitStart];
  }
}

- (void)implicitStart {
  if (!self.scanHasBeenStarted && self.window && self.superview && !self.hidden) {
    if (![CardIOUtilities canReadCardWithCamera]) {
        if (self.delegate && !self.config.outputs) {
          //only card-scanner - delegate is used
          [self.delegate cardIOView:self didScanCard:nil];
        } else {
          //outputs are used - card scaner completion block will be used
          [self sendCardInfoViaOutput:nil];
        }
      return;
    }
    
    self.scanHasBeenStarted = YES;
    
    CardIOLog(@"Creating cameraView");
    self.cameraView = [[CardIOCameraView alloc] initWithFrame:CGRectZeroWithSize(self.frame.size)
                                                     delegate:self
                                                       config:self.config];
    [self addSubview:self.cameraView];
    [self.cameraView willAppear];
    
    [self performSelector:@selector(startSession) withObject:nil afterDelay:0.0f];
  }
}

- (void)implicitStop {
  if (self.scanHasBeenStarted) {
    self.scanHasBeenStarted = NO;
    [self stopSession];
    [self.cameraView willDisappear];
    [self.cameraView removeFromSuperview];
    self.cameraView = nil;
  }
}

#pragma mark - Property accessors (passthroughs to Config, but with direct action)

-(void)setForceTorchToBeOn:(BOOL)forceTorchToBeOn{
  CardIOLogVerbose(@"Torch forced to be %@", forceTorchToBeOn ? @"ON" : @"OFF");
  self.config.forceTorchToBeOn = forceTorchToBeOn;
  [self.cameraView adaptToForcedTorch];
}

-(void)setCardScannerEnabled:(BOOL)cardScannerEnabled{
  [self setCardScannerEnabled:cardScannerEnabled animated:NO];
}

-(void)setCardScannerEnabled:(BOOL)cardScannerEnabled animated:(BOOL)animated {
  if (!self.config.outputs) {
    CardIOLogWarn(@"CardScanner cannot be enabled or disabled when not using CardIOOutputs. Scanner will remain enabled.");
    return;
  }
  for (CardIOOutput *output in self.config.outputs) {
    if ([[output class] isSubclassOfClass:[CardIOOutputCardScanner class]]) {
      CardIOLogWarn(@"CardScanner cannot be enabled or disabled when outputs doesn't contain card scanner.");
      return;
    }
  }
  if (self.cardScannerEnabled != cardScannerEnabled){
    CardIOLogVerbose(@"Cardscanner will be%@ set to %@ABLED.", animated ? @" animated" : @"", cardScannerEnabled ? @"EN" : @"DIS");
    self.config.cardScannerEnabled = cardScannerEnabled;
    [self.cameraView adaptGuideLayerVisibilityAnimated:animated];
  }
}

-(void)setForceSessionInterruption:(BOOL)forceSessionInterruption {
  CardIOLogVerbose(@"CardIO will%@ be forced to interrupt session.", forceSessionInterruption ? @"" : @" no longer");
  self.config.forceSessionInterruption = forceSessionInterruption;
  [self.cameraView adaptSessionInterruption];
}

-(void)setAllowedInterfaceOrientationMask:(UIInterfaceOrientationMask)allowedInterfaceOrientationMask {
  self.config.allowedInterfaceOrientationMask = allowedInterfaceOrientationMask;
  [self.cameraView didReceiveDeviceOrientationNotification:nil];
}

-(void)setExternalCardGuideInformation:(CardGuideInformation)externalCardGuideInformation {
  self.config.externalCardGuideInformation = externalCardGuideInformation;
  [self.cameraView adaptGuideLayerVisibilityAnimated:NO];
}

#pragma mark - Property accessors (passthroughs to CardIOCameraView)

- (CGRect)cameraPreviewFrame {
  return [self.cameraView cameraPreviewFrame];
}

- (CardIOCardScanner *)scanner {
  return self.cameraView.scanner;
}

#pragma mark - Video session start/stop

- (void)startSession {
  if (self.cameraView) {
    CardIOLog(@"Starting CameraViewController session");
    
    [self.cameraView startVideoStreamSession];
    
    [self.config.scanReport reportEventWithLabel:@"scan_start" withScanner:self.cameraView.scanner];
  }
}

- (void)stopSession {
  if (self.cameraView) {
    CardIOLog(@"Stopping CameraViewController session");
    [self.cameraView stopVideoStreamSession];
  }
}

#pragma mark - outputs

-(void)addOutput:(CardIOOutput *)output {
  if (!output) {
    CardIOLogError(@"Couldn't add nil as output, output has to be a CardIOOutput");
    return;
  }
  if (!IS_CARDIOOUTPUT(output)) {
    CardIOLogError(@"Couldn't add output from type <%@>, since it isn't a CardIOOutput", ClassStringFromObject(output));
    return;
  }
  if (self.cameraView){
    //the camera view has been instanciated, the camera view, so it hass to add
    [self.cameraView addOutput:output];
  } else {
    //the view has not yet instanciated a camera view and thus no avcaputre session, so it's enough to add this in the config
    [self.config addOutput:output];
  }
}

-(void)removeOutput:(CardIOOutput *)output {
  if (!output) {
    CardIOLogError(@"Couldn't remove nil as output, output has to be a CardIOOutput");
    return;
  }
  if (!IS_CARDIOOUTPUT(output)) {
    CardIOLogError(@"Couldn't remove output from type <%@>, since it isn't a CardIOOutput", ClassStringFromObject(output));
    return;
  }
  if (self.cameraView){
    //the camera view has to remove it
    [self.cameraView removeOutput:output];
  } else {
    //the view has not yet instanciated a camera view and thus no avcaputre session, so it's enough to remove this in the config
    [self.config removeOutput:output];
  }
}

#pragma mark - CardIOVideoStreamDelegate method and related methods

- (void)videoStream:(CardIOVideoStream *)stream didProcessFrame:(CardIOVideoFrame *)processedFrame {
  [self didDetectCard:processedFrame];
  
  if(processedFrame.scanner.complete) {
    [self didScanCard:processedFrame];
  }
}

- (void)didDetectCard:(CardIOVideoFrame *)processedFrame {
  if (self.config.isAutoInterupted) {
    //if it is currently auto interrupted we do not proccess any frame
    return;
  }
  
  if(processedFrame.foundAllEdges && processedFrame.focusOk) {
    if(self.detectionMode == CardIODetectionModeCardImageOnly) {
      if (self.config.autoSessionStop){
        [self stopSession];
      } else {
        [self.cameraView autoInterruptOnCompletion:[self continueAfterDetectedCard]];
      }
      [self vibrate];
      
      CardIOCreditCardInfo *cardInfo = [[CardIOCreditCardInfo alloc] init];
      self.cardImage = [processedFrame imageWithGrayscale:NO];
      cardInfo.cardImage = self.cardImage;
      
      [self.config.scanReport reportEventWithLabel:@"scan_detection" withScanner:processedFrame.scanner];
      
      [self successfulScan:cardInfo];
    }
  }
}

- (void)didScanCard:(CardIOVideoFrame *)processedFrame {
  if (self.config.isAutoInterupted) {
    //if it is currently auto interrupted we do not proccess any frame
    return;
  }
  
  if (self.config.autoSessionStop) {
    [self stopSession];
  } else {
    [self.cameraView autoInterruptOnCompletion:[self continueAfterDetectedCard]];
  }
  [self vibrate];

  self.readCardInfo = processedFrame.scanner.cardInfo;
  CardIOCreditCardInfo *cardInfo = [[CardIOCreditCardInfo alloc] init];
  cardInfo.cardNumber = self.readCardInfo.numbers;
  cardInfo.expiryMonth = self.readCardInfo.expiryMonth;
  cardInfo.expiryYear = self.readCardInfo.expiryYear;
  cardInfo.scanned = YES;

  self.cardImage = [processedFrame imageWithGrayscale:NO];
  cardInfo.cardImage = self.cardImage;
  
  [self.config.scanReport reportEventWithLabel:@"scan_success" withScanner:processedFrame.scanner];
  
  [self successfulScan:cardInfo];
}

-(void)sendCardInfoViaOutput:(CardIOCreditCardInfo*)cardInfo {
  for (CardIOOutput *output in self.config.outputs) {
    if ([[output class] isSubclassOfClass:[CardIOOutputCardScanner class]]) {
      ((CardIOOutputCardScanner*)output).onDetectedCard(self,cardInfo);
    }
  }
}

-(void(^)(void)) continueAfterDetectedCard {
  __block CardIOView *block_self = self;
  void(^continueBlock)() = ^() {
      block_self.readCardInfo = nil;
      block_self.cardImage = nil;
      [self.transitionView removeFromSuperview];
      self.transitionView = nil;
  };
  
  return continueBlock;
}

- (void)successfulScan:(CardIOCreditCardInfo *)cardInfo {
  // Even if not showing a transitionView (because self.scannedImageDuration == 0), we still create it.
  // This is because the CardIODataEntryView gets its cardImage from the transitionView. (A bit of a kludge, yes.)
  UIImage *annotatedImage = [CardIOCardOverlay cardImage:self.cardImage withDisplayInfo:self.readCardInfo annotated:YES];
  CGRect cameraPreviewFrame = [self cameraPreviewFrame];
  
  CGAffineTransform r = CGAffineTransformIdentity;
  CardIOPaymentViewController *vc = [CardIOPaymentViewController cardIOPaymentViewControllerForResponder:self];
  if (vc != nil &&
      [UIDevice currentDevice].orientation != UIDeviceOrientationPortrait &&
      vc.modalPresentationStyle == UIModalPresentationFullScreen) {
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (deviceOrientation == UIDeviceOrientationFaceUp || deviceOrientation == UIDeviceOrientationFaceDown) {
      deviceOrientation = (UIDeviceOrientation) vc.initialInterfaceOrientationForViewcontroller;
    }
    InterfaceToDeviceOrientationDelta delta = orientationDelta(UIInterfaceOrientationPortrait, deviceOrientation);
    CGFloat rotation = -rotationForOrientationDelta(delta); // undo the orientation delta
    r = CGAffineTransformMakeRotation(rotation);
  }
  
  self.transitionView = [[CardIOTransitionView alloc] initWithFrame:cameraPreviewFrame cardImage:annotatedImage transform:r];

  if (self.scannedImageDuration > 0.0) {
    [self addSubview:self.transitionView];
    
    [self.transitionView animateWithCompletion:^{
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.scannedImageDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
        if (self.delegate && !self.config.outputs) {
          [self.delegate cardIOView:self didScanCard:cardInfo];
        } else {
          [self sendCardInfoViaOutput:cardInfo];
        }
        [self.transitionView removeFromSuperview];
      });
    }];
  }
  else {
    if (self.delegate && !self.config.outputs) {
      self.transitionView.hidden = YES;
      [self.delegate cardIOView:self didScanCard:cardInfo];
    } else if (self.config.outputs) {
      [self sendCardInfoViaOutput:cardInfo];
    }
  }
}

- (void)vibrate {
  AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
}

#pragma mark - CardIOCameraViewDelegate method and related methods

-(void)guidelayerDidSetCardGuideInformation:(CGRect)internalGuideFrame foundTopEdge:(BOOL)foundTop foundLeftEdge:(BOOL)foundLeft foundBottomEdge:(BOOL)foundBottom foundRightEgde:(BOOL)foundRight isRotating:(BOOL)isRotating detectedCard:(BOOL)detectedCard recommendedShowingInstructions:(BOOL)recommendedShowingInstructions{

  if (!CGPointEqualToPoint(self.cameraView.frame.origin,CGPointZero) ) {
    internalGuideFrame = CGRectOffset(internalGuideFrame, self.cameraView.frame.origin.x , self.cameraView.frame.origin.y);
  }
  
  if (self.config.externalCardGuideInformation) {
    self.config.externalCardGuideInformation(internalGuideFrame,foundTop,foundLeft,foundBottom,foundRight,isRotating,detectedCard, recommendedShowingInstructions);
  }
}


#pragma mark - Description method

#define DESCRIBE_BOOL(property) (self.property ? "; " #property : "")

- (NSString *)description {
  return [NSString stringWithFormat:@"{delegate: %@; %s%s%s%s%s}"
          ,self.delegate
          ,DESCRIBE_BOOL(useCardIOLogo)
          ,DESCRIBE_BOOL(hideCardIOLogo)
          ,DESCRIBE_BOOL(allowFreelyRotatingCardGuide)
          ,DESCRIBE_BOOL(scanExpiry)
          ,(self.detectionMode == CardIODetectionModeCardImageAndNumber
            ? "DetectNumber"
            : (self.detectionMode == CardIODetectionModeCardImageOnly
               ? "DetectImage"
               : "DetectAuto"))
          ];
}

#pragma mark - Manual property implementations (passthrough to config)

#define CONFIG_PASSTHROUGH_GETTER(t, prop) \
- (t)prop { \
return self.config.prop; \
}

#define CONFIG_PASSTHROUGH_SETTER(t, prop_lc, prop_uc) \
- (void)set##prop_uc:(t)prop_lc { \
self.config.prop_lc = prop_lc; \
}

#define CONFIG_PASSTHROUGH_READWRITE(t, prop_lc, prop_uc) \
CONFIG_PASSTHROUGH_GETTER(t, prop_lc) \
CONFIG_PASSTHROUGH_SETTER(t, prop_lc, prop_uc)

CONFIG_PASSTHROUGH_READWRITE(NSString *, languageOrLocale, LanguageOrLocale)
CONFIG_PASSTHROUGH_READWRITE(BOOL, useCardIOLogo, UseCardIOLogo)
CONFIG_PASSTHROUGH_READWRITE(BOOL, hideCardIOLogo, HideCardIOLogo)
CONFIG_PASSTHROUGH_READWRITE(UIColor *, guideColor, GuideColor)
CONFIG_PASSTHROUGH_READWRITE(CGFloat, scannedImageDuration, ScannedImageDuration)
CONFIG_PASSTHROUGH_READWRITE(BOOL, allowFreelyRotatingCardGuide, AllowFreelyRotatingCardGuide)

CONFIG_PASSTHROUGH_READWRITE(NSString *, scanInstructions, ScanInstructions)
CONFIG_PASSTHROUGH_READWRITE(BOOL, scanExpiry, ScanExpiry)
CONFIG_PASSTHROUGH_READWRITE(UIView *, scanOverlayView, ScanOverlayView)
CONFIG_PASSTHROUGH_READWRITE(BOOL, autoSessionStop, AutoSessionStop)

CONFIG_PASSTHROUGH_READWRITE(CardIODetectionMode, detectionMode, DetectionMode)

CONFIG_PASSTHROUGH_GETTER(BOOL, forceTorchToBeOn)
CONFIG_PASSTHROUGH_GETTER(BOOL, cardScannerEnabled)
CONFIG_PASSTHROUGH_GETTER(BOOL, forceSessionInterruption)
CONFIG_PASSTHROUGH_GETTER(UIInterfaceOrientationMask, allowedInterfaceOrientationMask)
CONFIG_PASSTHROUGH_GETTER(CardGuideInformation, externalCardGuideInformation)

@end

#else // USE_CAMERA || SIMULATE_CAMERA

#import "CardIOView.h"

NSString * const CardIOScanningOrientationDidChangeNotification = @"CardIOScanningOrientationDidChangeNotification";
NSString * const CardIOCurrentScanningOrientation = @"CardIOCurrentScanningOrientation";
NSString * const CardIOScanningOrientationAnimationDuration = @"CardIOScanningOrientationAnimationDuration";

@implementation CardIOView

@end

#endif  // USE_CAMERA || SIMULATE_CAMERA