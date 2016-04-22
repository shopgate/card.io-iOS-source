//
//  CardIOCameraView.h
//  See the file "LICENSE.md" for the full license governing this code.
//

#if USE_CAMERA || SIMULATE_CAMERA

#import <UIKit/UIKit.h>
#import "CardIOGuideLayer.h"
#import "CardIOVideoStreamDelegate.h"
#import "CardIOOutput.h"

#define kRotationAnimationDuration 0.2f

@class CardIOConfig;
@class CardIOVideoFrame;
@class CardIOVideoStream;
@class CardIOCardScanner;


@protocol CardIOCameraViewDelegate <NSObject>
@optional
- (void)torchChangedStatusIsOn:(BOOL)isTorchOn;

@required
- (void)guidelayerDidSetCardGuideInformation:(CGRect)internalGuideFrame foundTopEdge:(BOOL)foundTop foundLeftEdge:(BOOL)foundLeft foundBottomEdge:(BOOL)foundBottom foundRightEgde:(BOOL)foundRight isRotating:(BOOL)isRotating detectedCard:(BOOL)detectedCard recommendedShowingInstructions:(BOOL)recommendedShowingInstructions;
@end


@interface CardIOCameraView : UIView<CardIOVideoStreamDelegate, CardIOGuideLayerDelegate>

- (id)initWithFrame:(CGRect)frame delegate:(id<CardIOVideoStreamDelegate,CardIOCameraViewDelegate>)delegate config:(CardIOConfig *)config;

- (void)updateLightButtonState;

- (void)willAppear;
- (void)willDisappear;

- (void)startVideoStreamSession;
- (void)stopVideoStreamSession;

- (CGRect)guideFrame;

// CGRect for the actual camera preview area within the cameraView
- (CGRect)cameraPreviewFrame;

/// The torch will be adapted to current forcedTorched
- (void) adaptToForcedTorch;

/// Intends the camera view to apdapt the visibility to the current state in the according config object. This can
/// happen animated or non-animated
-(void)adaptGuideLayerVisibilityAnimated:(BOOL)animated;

/// Intends the camera view to interrupt or to continue the session according to the current state in the config object.
-(void)adaptSessionInterruption;

/// Starts an auto interruption which will interrupt the session for a short time and will continue the session thereafter.
/// On continuing the session the onComplition block will be called. This method can be called several times, all completionBlocks will be called.
-(void)autoInterruptOnCompletion:(void(^)(void))onCompletion;

/// After the scanner was initialzed for using CardIOOutputs, other CardIOOutputs can be be add by using this method.
-(void)addOutput:(CardIOOutput *)output;

/// After the scanner was initialzed fo using CardIOOutputs, CardIOOutputs, that are currently used by the cardIO view
/// can be be removed by using this method.
-(void)removeOutput:(CardIOOutput *)output;


@property(nonatomic, strong, readonly)  CardIOCardScanner *scanner;
@property(nonatomic, weak, readwrite)   id<CardIOVideoStreamDelegate,CardIOCameraViewDelegate> delegate;
@property(nonatomic, strong, readwrite) UIFont *instructionsFont;
@property(nonatomic, assign, readwrite) BOOL suppressFauxCardLayer;

-(void)didReceiveDeviceOrientationNotification:(NSNotification *)notification;

@end

#endif