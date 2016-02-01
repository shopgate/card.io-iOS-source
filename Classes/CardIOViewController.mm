//
//  CardIOViewController.m
//  See the file "LICENSE.md" for the full license governing this code.
//

#if USE_CAMERA || SIMULATE_CAMERA

#import "CardIOViewController.h"

#if USE_CAMERA
#import "CardIOIplImage.h"
#endif

#import "CardIOCGGeometry.h"
#import "CardIOVideoFrame.h"
#import "CardIODataEntryViewController.h"
#import "CardIOPaymentViewController.h"
#import "CardIOPaymentViewControllerDelegate.h"
#import "CardIOPaymentViewControllerContinuation.h"
#import "CardIOResource.h"
#import "CardIOMacros.h"
#import "CardIOStyles.h"
#import "CardIOCreditCardNumber.h"
#import "CardIOCreditCardNumberFormatter.h"
#import "CardIOCardScanner.h"
#import "CardIOCreditCardInfo.h"
#import "CardIOAnalytics.h"
#import "CardIOGuideLayer.h"
#import "CardIOContext.h"
#import "CardIOLocalizer.h"
#import "CardIOTransitionView.h"
#import "CardIOView.h"
#import "CardIOViewContinuation.h"
#import "CardIOViewDelegate.h"
#import "CardIOOrientation.h"
#import <stdint.h>

#import "CardIOOutput.h"
#import "CardIOUtilities.h"

#pragma mark - Other constants

#define kStatusBarHeight      20

#define kButtonSizeOutset 20
#define kRotationAnimationDuration 0.2f
#define kButtonRotationDelay (kRotationAnimationDuration + 0.1f)

#define kDropShadowRadius 3.0f
#define kShadowInsets UIEdgeInsetsMake(-kDropShadowRadius, -kDropShadowRadius, -kDropShadowRadius, -kDropShadowRadius)

@interface CardIOViewController () <CardIOViewDelegate>

@property(nonatomic, strong, readwrite) CardIOView         *cardIOView;
@property(nonatomic, strong, readwrite) CALayer            *shadowLayer;
@property(nonatomic, assign, readwrite) BOOL                changeStatusBarHiddenStatus;
@property(nonatomic, assign, readwrite) BOOL                newStatusBarHiddenStatus;
@property(nonatomic, assign, readwrite) BOOL                statusBarWasOriginallyHidden;
@property(nonatomic, strong, readwrite) UIButton           *cancelButton;
@property(nonatomic, strong, readwrite) UIButton           *manualEntryButton;
@property(nonatomic, strong, readwrite) UIButton           *scanImageButton;
@property(nonatomic, assign, readwrite) UIDeviceOrientation deviceOrientation;
@property(nonatomic, assign, readwrite) CGSize              cancelButtonFrameSize;
@property(nonatomic, assign, readwrite) CGSize              manualEntryButtonFrameSize;

@property(nonatomic, strong) AVCaptureSession * testSession;
@property(nonatomic, strong) AVCaptureDevice *_device;
@property(nonatomic, strong) AVCaptureDeviceInput *_input;
@property(nonatomic, strong) CardIOOutputMetadataScanner *_barcodeOutPut;
@property(nonatomic, strong) CardIOOutputImageScanner *_imageScanner;
@property(nonatomic, strong) UIView * guide;
@end

#pragma mark -

@implementation CardIOViewController


- (id)init {
  if((self = [super initWithNibName:nil bundle:nil])) {
    if (iOS_7_PLUS) {
      self.automaticallyAdjustsScrollViewInsets = YES;
      self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    else {
      self.wantsFullScreenLayout = YES;
    }
    _statusBarWasOriginallyHidden = [UIApplication sharedApplication].statusBarHidden;
  }
  [CardIOUtilities setExternalLogging:^(NSUInteger loglevel,NSString *message) {
    NSLog(@"[CARDIO]: %@",message);
  }];
  return self;
}





#pragma mark - View Load/Unload sequence

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

  self.view.backgroundColor = [UIColor colorWithWhite:0.15f alpha:1.0f];
  
//  AVCaptureSession * session;
//  session = [[AVCaptureSession alloc] init];
//  self.testSession = session;
//  
//  AVCaptureVideoPreviewLayer *prevLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
//  prevLayer.frame = self.view.bounds;
//  prevLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//  
//  [self.view.layer addSublayer:prevLayer];
  
  NSMutableDictionary* barCodeTypes;
  
  barCodeTypes = @{
                   @"org.gs1.UPC-E" : @"UPC_E",
                   @"org.iso.Code39" : @"CODE_39",
                   @"org.gs1.EAN-13" : @"EAN_13",
                   @"org.gs1.EAN-8" : @"EAN_8",
                   @"com.intermec.Code93" : @"CODE_93",
                   @"org.iso.Code128" : @"CODE_128",
                   @"org.iso.PDF417" : @"PDF_417",
                   @"org.iso.QRCode" : @"QR_CODE",
                   @"org.iso.Aztec" : @"AZTEC"
                   };
  
  barCodeTypes = [barCodeTypes mutableCopy];
  [((NSMutableDictionary*)barCodeTypes) addEntriesFromDictionary:@{
                                                                   @"org.ansi.Interleaved2of5" : @"ITF",
                                                                   @"org.iso.DataMatrix" : @"DATA_MATRIX"
                                                                   }];
  
  
  

  CGRect cardIOViewFrame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
  cardIOViewFrame = CGRectRoundedToNearestPixel(cardIOViewFrame);
  
  
  CardIOOutputImageScanner * imageOutput = [CardIOOutputImageScanner
                                            outputImageScannerWithOutputSettings:[NSDictionary dictionaryWithObject:
                                                                                                           [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                                                                                                                      forKey:(id)kCVPixelBufferPixelFormatTypeKey]
                                            doOnScannedImmage:^(UIImage *scannedImage, NSDictionary *info) {
                                              int test = 0;
                                              //TODO
                                            } doOnError:^(NSError *error, NSDictionary *info) {
                                            }];
  self._imageScanner = imageOutput;
  
  CardIOOutputMetadataScanner * barcodeOutout = [CardIOOutputMetadataScanner outputMetadataScannerWithTypes:[barCodeTypes allKeys] doOnMetadataDetection:^(AVCaptureOutput *captureOutput, NSArray *outputMetadataObjects, AVCaptureConnection *fromConnection) {
    for (AVMetadataObject *metadataObject in outputMetadataObjects) {
      
      NSString *codeType = [barCodeTypes objectForKey:metadataObject.type];
      
      if(codeType) {
        NSString *detectionString = [(AVMetadataMachineReadableCodeObject *)metadataObject stringValue];
        
        NSLog(@"Scan: %@",detectionString);
        break;
      }
    }
  }];
  self._barcodeOutPut = barcodeOutout;
  
  
  CardIOOutputCardScanner * cardScannerOutput = [CardIOOutputCardScanner
                                           outputCardScannerDoOnCardDetection:^(CardIOView *cardIOView, CardIOCreditCardInfo *detectedCardInfo) {
                                             [self cardIOView:cardIOView didScanCard:detectedCardInfo];
                                           }];
  
  

  self.cardIOView = [[CardIOView alloc] initWithFrame:cardIOViewFrame outputs:@[barcodeOutout,imageOutput/*,cardScannerOutput*/] captureSessionPreset:AVCaptureSessionPresetInputPriority];

  //self.cardIOView = [[CardIOView alloc] initWithFrame:cardIOViewFrame];
  //self.cardIOView.delegate = self;
  
  self.cardIOView.languageOrLocale = self.context.languageOrLocale;
  self.cardIOView.useCardIOLogo = self.context.useCardIOLogo;
  self.cardIOView.hideCardIOLogo = YES;
  self.cardIOView.guideColor = nil; //TODO, does not work
  self.cardIOView.scannedImageDuration = 0;
  self.cardIOView.allowFreelyRotatingCardGuide = NO;
  self.cardIOView.allowedInterfaceOrientationMask = UIInterfaceOrientationPortrait;
  self.cardIOView.scanInstructions = @"FOO";//self.context.scanInstructions; todo
  self.cardIOView.scanExpiry = self.context.collectExpiry && self.context.scanExpiry;
  

  self.cardIOView.detectionMode = self.context.detectionMode;

  self.guide = [[UIView alloc] initWithFrame:self.view.bounds];
  self.guide.alpha = 1.f;
  self.guide.backgroundColor = [UIColor colorWithRed:0.5 green:0 blue:0 alpha:0.3f];
  self.guide.tintColor = [UIColor colorWithRed:0.5 green:0 blue:0 alpha:0.3f];
  /*self.cardIOView.externalCardGuideInformation = ^void (CGRect guideFrame, BOOL topEdgeRecognized, BOOL leftEdgeRecognized, BOOL  bottomEdgeRecognized, BOOL rightEdgeRecognized, BOOL isRotating, BOOL detectedCard, BOOL recommendedShowingInstructions) {
    //debug joe
#ifdef DEBUG
    //TODO: joe
    self.guide.frame = guideFrame;
    NSLog(@"%@",@"EXTERNAL GUIDE FRAME");
    int test = 0;
#endif
    //debug end
    };*/

  
  
  [self.view addSubview:self.cardIOView];
  [self.view addSubview:self.guide];

  _cancelButton = [self makeButtonWithTitle:CardIOLocalizedString(@"cancel", self.context.languageOrLocale) // Cancel
                               withSelector:@selector(cancel:)];
  _cancelButtonFrameSize = self.cancelButton.frame.size;
  [self.view addSubview:self.cancelButton];

  if (!self.context.disableManualEntryButtons) {
    _manualEntryButton = [self makeButtonWithTitle:CardIOLocalizedString(@"manual_entry", self.context.languageOrLocale) // Enter Manually
                                      withSelector:@selector(manualEntry:)];
    _manualEntryButtonFrameSize = self.manualEntryButton.frame.size;
    [self.view addSubview:self.manualEntryButton];
  }
  
  _scanImageButton = [self makeButtonWithTitle:@"Scan Image" withSelector:@selector(scanImage:)];
  //TODO: NSbundle has to be extended with this string
  [self.view addSubview:self.scanImageButton];

  
   //Add shadow to camera preview
  _shadowLayer = [CALayer layer];
  self.shadowLayer.shadowRadius = kDropShadowRadius;
  self.shadowLayer.shadowColor = [UIColor blackColor].CGColor;
  self.shadowLayer.shadowOffset = CGSizeMake(0.0f, 0.0f);
  self.shadowLayer.shadowOpacity = 0.5f;
  self.shadowLayer.masksToBounds = NO;
  [self.cardIOView.layer insertSublayer:self.shadowLayer atIndex:0]; // must go *behind* everything original
  

  
  self.cardIOView.forceTorchToBeOn = NO;
  //[self.cardIOView setHiddenCardGuide:YES animated:YES];
  //[self performSelector:@selector(testInterruption) withObject:nil afterDelay:5];
  self.cardIOView.autoSessionStop = NO;
  //[self performSelector:@selector(testDisable) withObject:nil afterDelay:5];
  [self performSelector:@selector(addCardScanner:) withObject:cardScannerOutput afterDelay:7];
}


-(void)addCardScanner:(CardIOOutputCardScanner*)cardScanner {
  [self.cardIOView addOutput:cardScanner];
  //[self performSelector:@selector(stopTestTorch) withObject:nil afterDelay:30];
}

-(void)testTorch {
  [self.cardIOView setForceTorchToBeOn:YES];
  [self performSelector:@selector(stopTestTorch) withObject:nil afterDelay:30];
}

-(void)stopTestTorch{
  [self.cardIOView setForceTorchToBeOn:NO];
}

-(void)testInterruption {
  [self.cardIOView setForceSessionInterruption:YES];
  [self performSelector:@selector(stopTestInterruption) withObject:nil afterDelay:5];
}

-(void)stopTestInterruption{
  [self.cardIOView setForceSessionInterruption:NO];
}

-(void)testDisable{
  [self.cardIOView setCardScannerEnabled:NO animated:YES];
  [self performSelector:@selector(stopTestDisable) withObject:nil afterDelay:40];
}

-(void)stopTestDisable{
  [self.cardIOView setCardScannerEnabled:YES animated:YES];
}

-(void)scanImage:(UIButton*)scanImageButton {
  [self._imageScanner scanImageWithMaxWidth:@2048 maxHeight:@2048 info:@{@"requestID" : @"fooBar"}];
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];

  self.cardIOView.frame = self.view.bounds;

  // Only muck around with the status bar at all if we're in full screen modal style
  if (self.navigationController.modalPresentationStyle == UIModalPresentationFullScreen
      && [CardIOMacros appHasViewControllerBasedStatusBar]
      && !self.statusBarWasOriginallyHidden) {

    self.changeStatusBarHiddenStatus = YES;
    self.newStatusBarHiddenStatus = YES;
  }
}

- (void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
  [self.cardIOView layoutIfNeeded]; // otherwise self.cardIOView's layoutSubviews doesn't get called until *after* viewDidLayoutSubviews returns!

  // Re-layout shadow
  CGRect cameraPreviewFrame = self.cardIOView.cameraPreviewFrame;
  UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:UIEdgeInsetsInsetRect(cameraPreviewFrame, kShadowInsets)];
  self.shadowLayer.shadowPath = shadowPath.CGPath;

  [self layoutButtonsForCameraPreviewFrame:self.cardIOView.cameraPreviewFrame];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  self.deviceOrientation = UIDeviceOrientationUnknown;

  self.cardIOView.hidden = NO;
  [self.navigationController setNavigationBarHidden:YES animated:animated];

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(didReceiveDeviceOrientationNotification:)
                                               name:UIDeviceOrientationDidChangeNotification
                                             object:[UIDevice currentDevice]];
  [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];

  [self didReceiveDeviceOrientationNotification:nil];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];

  if (self.changeStatusBarHiddenStatus) {
    [[UIApplication sharedApplication] setStatusBarHidden:self.newStatusBarHiddenStatus withAnimation:UIStatusBarAnimationFade];
    if (iOS_7_PLUS) {
      [self setNeedsStatusBarAppearanceUpdate];
    }
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  self.cardIOView.hidden = YES;
  if (self.changeStatusBarHiddenStatus) {
    [[UIApplication sharedApplication] setStatusBarHidden:self.statusBarWasOriginallyHidden withAnimation:UIStatusBarAnimationFade];
    if (iOS_7_PLUS) {
      [self setNeedsStatusBarAppearanceUpdate];
    }
  }
  [super viewWillDisappear:animated];
}

#pragma mark - Make the Cancel and Manual Entry buttons

- (UIButton *)makeButtonWithTitle:(NSString *)title withSelector:(SEL)selector {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];

  NSMutableDictionary *attributes = [@{
                                       NSStrokeWidthAttributeName : [NSNumber numberWithFloat:-1.0f]   // negative value => do both stroke & fill
                                       } mutableCopy];

  attributes[NSFontAttributeName] = [UIFont boldSystemFontOfSize:18.0f];
  attributes[NSForegroundColorAttributeName] = [UIColor colorWithWhite:1.0f alpha:0.8f];
  [button setAttributedTitle:[[NSAttributedString alloc] initWithString:title attributes:attributes] forState:UIControlStateNormal];

  attributes[NSForegroundColorAttributeName] = [UIColor whiteColor];
  [button setAttributedTitle:[[NSAttributedString alloc] initWithString:title attributes:attributes] forState:UIControlStateHighlighted];

  CGSize buttonTitleSize = [button.titleLabel.attributedText size];
#ifdef __LP64__
  buttonTitleSize.height = ceil(buttonTitleSize.height);
  buttonTitleSize.width = ceil(buttonTitleSize.width);
#else
  buttonTitleSize.height = ceilf(buttonTitleSize.height);
  buttonTitleSize.width = ceilf(buttonTitleSize.width);
#endif
  button.bounds = CGRectMake(0, 0, buttonTitleSize.width + kButtonSizeOutset, buttonTitleSize.height + kButtonSizeOutset);

  [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];

  return button;
}

#pragma mark - View Controller orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  return [self.navigationController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

- (BOOL)shouldAutorotate {
  return [self.navigationController shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations {
  return [self.navigationController supportedInterfaceOrientations];
}

#pragma mark - Button orientation

- (void)didReceiveDeviceOrientationNotification:(NSNotification *)notification {
  UIDeviceOrientation newDeviceOrientation;
  CGRect cameraPreviewFrame = self.cardIOView.cameraPreviewFrame;
  switch ([UIDevice currentDevice].orientation) {
    case UIDeviceOrientationPortrait:
      newDeviceOrientation = UIDeviceOrientationPortrait;
      break;
    case UIDeviceOrientationPortraitUpsideDown:
      newDeviceOrientation = UIDeviceOrientationPortraitUpsideDown;
      break;
    case UIDeviceOrientationLandscapeLeft:
      newDeviceOrientation = UIDeviceOrientationLandscapeLeft;
      cameraPreviewFrame = CGRectWithRotatedRect(cameraPreviewFrame);
      break;
    case UIDeviceOrientationLandscapeRight:
      newDeviceOrientation = UIDeviceOrientationLandscapeRight;
      cameraPreviewFrame = CGRectWithRotatedRect(cameraPreviewFrame);
      break;
    default:
      if (self.deviceOrientation == UIDeviceOrientationUnknown) {
        newDeviceOrientation = (UIDeviceOrientation)((CardIOPaymentViewController *)self.navigationController).initialInterfaceOrientationForViewcontroller;
      }
      else {
        newDeviceOrientation = self.deviceOrientation;
      }
      break;
  }

  if (![self isSupportedOverlayOrientation:(UIInterfaceOrientation)newDeviceOrientation]) {
    if ([self isSupportedOverlayOrientation:(UIInterfaceOrientation)self.deviceOrientation]) {
      newDeviceOrientation = self.deviceOrientation;
    }
    else {
      UIInterfaceOrientation orientation = [self defaultSupportedOverlayOrientation];
      if (orientation != UIDeviceOrientationUnknown) {
        newDeviceOrientation = (UIDeviceOrientation)orientation;
      }
    }
  }

  if (newDeviceOrientation != self.deviceOrientation) {
    self.deviceOrientation = newDeviceOrientation;

    // Also update initialInterfaceOrientationForViewcontroller, so that CardIOView will present its transition view in the correct orientation
    ((CardIOPaymentViewController *)self.navigationController).initialInterfaceOrientationForViewcontroller = (UIInterfaceOrientation)newDeviceOrientation;

    if (cameraPreviewFrame.size.width == 0 || cameraPreviewFrame.size.height == 0) {
      [self.view setNeedsLayout];
    }
    else {
      [UIView animateWithDuration:kRotationAnimationDuration animations:^{[self layoutButtonsForCameraPreviewFrame:cameraPreviewFrame];}];
    }
  }
}

- (void)layoutButtonsForCameraPreviewFrame:(CGRect)cameraPreviewFrame {
  if (cameraPreviewFrame.size.width == 0 || cameraPreviewFrame.size.height == 0) {
    return;
  }

  // - When setting each button's frame, it's simplest to do that without any rotational transform applied to the button.
  //   So immediately prior to setting the frame, we set `button.transform = CGAffineTransformIdentity`.
  // - Later in this method we set a new transform for each button.
  // - We call [CATransaction setDisableActions:YES] to suppress the visible animation to the
  //   CGAffineTransformIdentity position; for reasons we haven't explored, this is only desirable for the
  //   InterfaceToDeviceOrientationRotatedClockwise and InterfaceToDeviceOrientationRotatedCounterclockwise rotations.
  //   (Thanks to https://github.com/card-io/card.io-iOS-source/issues/30 for the [CATransaction setDisableActions:YES] suggestion.)

  InterfaceToDeviceOrientationDelta delta = orientationDelta([UIApplication sharedApplication].statusBarOrientation, self.deviceOrientation);
  BOOL disableTransactionActions = (delta == InterfaceToDeviceOrientationRotatedClockwise ||
                                    delta == InterfaceToDeviceOrientationRotatedCounterclockwise);
  
  if (disableTransactionActions) {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
  }

  self.cancelButton.transform = CGAffineTransformIdentity;
  self.cancelButton.frame = CGRectWithXYAndSize(cameraPreviewFrame.origin.x + 5.0f,
                                                CGRectGetMaxY(cameraPreviewFrame) - self.cancelButtonFrameSize.height - 5.0f,
                                                self.cancelButtonFrameSize);

  if (self.manualEntryButton) {
    self.manualEntryButton.transform = CGAffineTransformIdentity;
    self.manualEntryButton.frame = CGRectWithXYAndSize(CGRectGetMaxX(cameraPreviewFrame) - self.manualEntryButtonFrameSize.width - 5.0f,
                                                       CGRectGetMaxY(cameraPreviewFrame) - self.manualEntryButtonFrameSize.height - 5.0f,
                                                       self.manualEntryButtonFrameSize);
  }
  
  if (self.scanImageButton){
    self.scanImageButton.transform = CGAffineTransformIdentity;
    self.scanImageButton.frame = CGRectWithXYAndSize(self.cancelButton.frame.origin.x,
                                                       self.cancelButton.frame.origin.y - self.scanImageButton.frame.size.height - 10.0f,
                                                       self.scanImageButton.frame.size);
  }

  if (disableTransactionActions) {
    [CATransaction commit];
  }

  CGAffineTransform r;
  CGFloat rotation = -rotationForOrientationDelta(delta); // undo the orientation delta
  r = CGAffineTransformMakeRotation(rotation);

  switch (delta) {
    case InterfaceToDeviceOrientationSame:
    case InterfaceToDeviceOrientationUpsideDown: {
      self.cancelButton.transform = r;
      self.manualEntryButton.transform = r;
      break;
    }
    case InterfaceToDeviceOrientationRotatedClockwise:
    case InterfaceToDeviceOrientationRotatedCounterclockwise: {
      CGFloat cancelDelta = (self.cancelButtonFrameSize.width - self.cancelButtonFrameSize.height) / 2;
      CGFloat manualEntryDelta = (self.manualEntryButtonFrameSize.width - self.manualEntryButtonFrameSize.height) / 2;
      if (delta == InterfaceToDeviceOrientationRotatedClockwise) {
        cancelDelta = -cancelDelta;
        manualEntryDelta = -manualEntryDelta;
      }
      self.cancelButton.transform = CGAffineTransformTranslate(r, cancelDelta, -cancelDelta);
      self.manualEntryButton.transform = CGAffineTransformTranslate(r, manualEntryDelta, manualEntryDelta);
      break;
    }
    default: {
      break;
    }
  }
}

// Overlay orientation has the same constraints as the view controller,
// unless self.config.allowFreelyRotatingCardGuide == YES.

- (UIInterfaceOrientationMask)supportedOverlayOrientationsMask {
  UIInterfaceOrientationMask supportedOverlayOrientationsMask = UIInterfaceOrientationMaskAll;
  CardIOPaymentViewController *vc = [CardIOPaymentViewController cardIOPaymentViewControllerForResponder:self];
  if (vc) {
    supportedOverlayOrientationsMask = [vc supportedOverlayOrientationsMask];
  }
  return supportedOverlayOrientationsMask;
}

- (BOOL)isSupportedOverlayOrientation:(UIInterfaceOrientation)orientation {
  return (([self supportedOverlayOrientationsMask] & (1 << orientation)) != 0);
}

- (UIInterfaceOrientation)defaultSupportedOverlayOrientation {
  if (self.context.allowFreelyRotatingCardGuide) {
    return UIInterfaceOrientationPortrait;
  }
  else {
    UIInterfaceOrientation defaultOrientation = UIInterfaceOrientationUnknown;
    UIInterfaceOrientationMask supportedOverlayOrientationsMask = [self supportedOverlayOrientationsMask];
    for (NSInteger orientation = UIInterfaceOrientationMaskPortrait;
         orientation <= UIInterfaceOrientationLandscapeRight;
         orientation++) {
      if ((supportedOverlayOrientationsMask & (1 << orientation)) != 0) {
        defaultOrientation = (UIInterfaceOrientation)orientation;
        break;
      }
    }
    return defaultOrientation;
  }
}

#pragma mark - Status bar preferences (iOS 7)

- (BOOL)prefersStatusBarHidden {
  if (self.changeStatusBarHiddenStatus) {
    return self.newStatusBarHiddenStatus;
  }
  else {
    return YES;
  }
}

- (UIStatusBarStyle) preferredStatusBarStyle {
  return UIStatusBarStyleLightContent;
}

#pragma mark - Handle button taps

- (void)manualEntry:(id)sender {
  [self.context.scanReport reportEventWithLabel:@"scan_manual_entry" withScanner:self.cardIOView.scanner];

  CardIOPaymentViewController *root = (CardIOPaymentViewController *)self.navigationController;

  CardIODataEntryViewController *manualEntryViewController = [[CardIODataEntryViewController alloc] initWithContext:self.context withStatusBarHidden:self.statusBarWasOriginallyHidden];
  manualEntryViewController.manualEntry = YES;
  root.currentViewControllerIsDataEntry = YES;
  root.initialInterfaceOrientationForViewcontroller = (UIInterfaceOrientation)self.deviceOrientation;

  if (iOS_8_PLUS) {
    // The presentViewController:/dismissViewControllerAnimated: kludge was necessary for
    // some edge case that I can currently neither recall nor reproduce.
    // In any case, though, the kludge crashes on iOS 8 Beta 2.
    // So, at least for the moment, avoid it in iOS 8!
    [root pushViewController:manualEntryViewController animated:YES];
    //
    // 17 Sep 2014 further notes:
    // Can prevent the iOS 8 crash by adding `dispatch_after` as follows:
    //    [self.navigationController presentViewController:[[UIViewController alloc] init] animated:NO completion:^{
    //      dispatch_after(0, dispatch_get_main_queue(), ^{
    //        [self.navigationController dismissViewControllerAnimated:NO completion:^{
    //          [root pushViewController:manualEntryViewController animated:YES];
    //        }];
    //      });
    //    }];
    // However, this results in some ugly flashiness. (Even uglier on iOS 7 than on iOS 8.)
    // So, for now, let's just wait and see whether that mysterious orientation-related edge case turns up someday under iOS 8.
  }
  else {
    // Force the system to again ask CardIOPaymentViewController for its preferred orientation
    [self.navigationController presentViewController:[[UIViewController alloc] init] animated:NO completion:^{
      [self.navigationController dismissViewControllerAnimated:NO completion:^{
        [root pushViewController:manualEntryViewController animated:YES];
      }];
    }];
  }
}


- (void)cancel:(id)sender {
  [self.context.scanReport reportEventWithLabel:@"scan_cancel" withScanner:self.cardIOView.scanner];

  // Hiding the CardIOView causes it to call its stopSession method, thus eliminating a visible stutter.
  // See https://github.com/card-io/card.io-iOS-SDK/issues/97
  self.cardIOView.hidden = YES;

  [self.navigationController setNavigationBarHidden:NO animated:YES]; // to restore the color of the status bar!

  CardIOPaymentViewController *root = (CardIOPaymentViewController *)self.navigationController;
  [root.paymentDelegate userDidCancelPaymentViewController:root];
}


#pragma mark - CardIOViewDelegate method

- (void)cardIOView:(CardIOView *)cardIOView didScanCard:(CardIOCreditCardInfo *)cardInfo {
  
  
  /*
  [cardIOView setForceSessionInterruption:YES];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [cardIOView setForceSessionInterruption:NO];
  });
  */
  
  return;
  self.context.detectionMode = cardIOView.detectionMode;  // may have changed from Auto to CardImageOnly

  if (![cardInfo.cardNumber length] || self.context.suppressScanConfirmation
      || (self.context.detectionMode == CardIODetectionModeCardImageOnly)) {
    CardIOPaymentViewController *root = (CardIOPaymentViewController *)self.navigationController;
    [root setNavigationBarHidden:NO animated:YES]; // to restore the color of the status bar!

    if ([cardInfo.cardNumber length]
        || (self.context.detectionMode == CardIODetectionModeCardImageOnly)
        ) {
      [root.paymentDelegate userDidProvideCreditCardInfo:cardInfo inPaymentViewController:root];
    }
    else {
      [root.paymentDelegate userDidCancelPaymentViewController:root];
    }
  }
  else {
    CardIODataEntryViewController *dataEntryViewController = [[CardIODataEntryViewController alloc] initWithContext:self.context withStatusBarHidden:self.statusBarWasOriginallyHidden];
    dataEntryViewController.cardImage = cardIOView.transitionView.cardView.image;
    dataEntryViewController.cardInfo = cardInfo;
    dataEntryViewController.manualEntry = self.context.suppressScannedCardImage;

    CGPoint newCenter = [self.view convertPoint:cardIOView.transitionView.cardView.center fromView:cardIOView.transitionView];
    newCenter.y -= NavigationBarHeightForOrientation(self.interfaceOrientation);

    dataEntryViewController.cardImageCenter = newCenter; // easier to pass this in than to recalculate it!
    dataEntryViewController.cardImageSize = CGSizeApplyAffineTransform(cardIOView.transitionView.cardView.bounds.size, cardIOView.transitionView.cardView.transform);

    // WTF? on iPad, the key window is sometimes nil!
    UIWindow *mostImportantWindow = [[UIApplication sharedApplication] keyWindow];
    if (!mostImportantWindow) {
      mostImportantWindow = [[[UIApplication sharedApplication] windows] lastObject];
    }
    dataEntryViewController.priorKeyWindow = mostImportantWindow;

    UIWindow *floatingCardWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    floatingCardWindow.opaque = NO;
    floatingCardWindow.backgroundColor = [UIColor clearColor];

    UIImageView *floatingCardView = [[UIImageView alloc] initWithImage:cardIOView.transitionView.cardView.image];
    floatingCardView.bounds = CGRectZeroWithSize(dataEntryViewController.cardImageSize);
    floatingCardView.center = [floatingCardWindow convertPoint:cardIOView.transitionView.cardView.center fromView:[cardIOView.transitionView.cardView superview]];
    floatingCardView.contentMode = UIViewContentModeScaleAspectFit;
    floatingCardView.backgroundColor = [UIColor blackColor];
    floatingCardView.layer.cornerRadius = ((CGFloat) 9.0f) * (floatingCardView.bounds.size.width / ((CGFloat) 300.0f)); // matches the card, adjusted for view size. (view is ~300 px wide on phone.)
    floatingCardView.layer.masksToBounds = YES;
    floatingCardView.layer.borderColor = [UIColor grayColor].CGColor;
    floatingCardView.layer.borderWidth = 2.0f;
    floatingCardView.transform = CGAffineTransformMakeRotation(orientationToRotation(self.interfaceOrientation));
    floatingCardView.hidden = cardIOView.transitionView.hidden;

    [floatingCardWindow addSubview:floatingCardView];

    // this is all that is needed to display a window. makeKeyAndVisible: causes all kinds of havoc that doesn't get cleared until after the app is killed.
    floatingCardWindow.hidden = NO;

    dataEntryViewController.floatingCardView = floatingCardView;
    dataEntryViewController.floatingCardWindow = floatingCardWindow;

    CardIOPaymentViewController *root = (CardIOPaymentViewController *)self.navigationController;
    root.currentViewControllerIsDataEntry = YES;
    root.initialInterfaceOrientationForViewcontroller = (UIInterfaceOrientation)self.deviceOrientation;

    if (iOS_8_PLUS) {
      // The presentViewController:/dismissViewControllerAnimated: kludge was necessary for
      // some edge case that I can currently neither recall nor reproduce.
      // In any case, though, the kludge crashes on iOS 8 Beta 2.
      // So, at least for the moment, avoid it in iOS 8!
      [root pushViewController:dataEntryViewController animated:NO];
      //
      // 17 Sep 2014 further notes:
      // Can prevent the iOS 8 crash by adding `dispatch_after` as follows:
      //      [self.navigationController presentViewController:[[UIViewController alloc] init] animated:NO completion:^{
      //        dispatch_after(0, dispatch_get_main_queue(), ^{
      //          [self.navigationController dismissViewControllerAnimated:NO completion:^{
      //            [root pushViewController:dataEntryViewController animated:NO];
      //          }];
      //        });
      //      }];
      // However, this results in some ugly flashiness. (Even uglier on iOS 7 than on iOS 8.)
      // So, for now, let's just wait and see whether that mysterious orientation-related edge case turns up someday under iOS 8.
    }
    else {
      // Force the system to again ask CardIOPaymentViewController for its preferred orientation
      [self.navigationController presentViewController:[[UIViewController alloc] init] animated:NO completion:^{
        [self.navigationController dismissViewControllerAnimated:NO completion:^{
          [root pushViewController:dataEntryViewController animated:NO];
        }];
      }];
    }
  }
}

@end

#endif //USE_CAMERA || SIMULATE_CAMERA
