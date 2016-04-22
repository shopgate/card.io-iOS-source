//
//  CardIOConfig.h
//  See the file "LICENSE.md" for the full license governing this code.
//

#import <Foundation/Foundation.h>
#import "CardIOAnalytics.h"
#import "CardIODetectionMode.h"

@interface CardIOConfig : NSObject
@property(nonatomic, strong, readwrite) CardIOAnalytics *scanReport;

@property(nonatomic, copy, readwrite)   NSString *languageOrLocale;
@property(nonatomic, assign, readwrite) BOOL useCardIOLogo;
@property(nonatomic, retain, readwrite) UIColor *guideColor;
@property(nonatomic, assign, readwrite) CGFloat scannedImageDuration;
@property(nonatomic, assign, readwrite) BOOL allowFreelyRotatingCardGuide;
@property (nonatomic, assign, readwrite) UIInterfaceOrientationMask allowedInterfaceOrientationMask;
@property(nonatomic, assign, readwrite) BOOL scanExpiry;
@property(nonatomic, copy, readwrite)   NSString *scanInstructions;
@property(nonatomic, assign, readwrite) BOOL hideCardIOLogo;
@property(nonatomic, retain, readwrite) UIView *scanOverlayView;
@property(nonatomic, assign, readwrite) BOOL forceTorchToBeOn;
@property(nonatomic, assign, readwrite) BOOL automaticTorchModeEnabled;
@property(nonatomic, assign, readwrite) BOOL automaticVibrationModeEnabled;
@property(nonatomic, assign, readwrite) BOOL cardScannerEnabled;
@property(nonatomic, strong, readwrite) NSString * forcedSessionPreset;
@property(nonatomic, assign, readwrite) BOOL forceSessionInterruption;
@property(nonatomic, assign, readwrite) BOOL autoSessionStop;
@property(nonatomic, assign, readonly)  BOOL isAutoInterupted;
@property(nonatomic, assign, readwrite)  BOOL fullscreenPreviewLayer;
@property(nonatomic, assign, readwrite)  BOOL animatedShutter;

@property(nonatomic, assign, readwrite) CardIODetectionMode detectionMode;

@property(nonatomic, copy, readwrite)void(^externalCardGuideInformation)(CGRect guideFrame, BOOL topEdgeRecognized, BOOL leftEdgeRecognized, BOOL  bottomEdgeRecognized, BOOL rightEdgeRecognized, BOOL isRotating, BOOL detectedCard, BOOL recommendedShowingInstructions);

@property(nonatomic, copy) NSArray *outputs;
@end
