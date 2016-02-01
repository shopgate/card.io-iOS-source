//
//  CardIOVideoStream.h
//  See the file "LICENSE.md" for the full license governing this code.
//

// Handles a video stream, including setup and teardown, and dispatching frames to be processed.

#if USE_CAMERA || SIMULATE_CAMERA

#import <Foundation/Foundation.h>
#import "CardIOVideoStreamDelegate.h"
#import <AVFoundation/AVFoundation.h>
#import "dmz.h"
#import "CardIOOutput.h"

#define LOG_FPS 1 // for performance tuning/testing

@class CardIOCardScanner;
@class CardIOConfig;

@interface CardIOVideoStream : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate> {
@private
#if USE_CAMERA
  dmz_context *dmz;
#endif
}
- (void)willAppear;
- (void)willDisappear;

- (BOOL)hasTorch;
- (BOOL)canSetTorchLevel;
- (BOOL)torchIsOn;
- (BOOL)setTorchOn:(BOOL)torchShouldBeOn; // returns success value
- (BOOL)hasAutofocus;

- (void)refocus;

- (void)startSession;
- (void)stopSession;

/// Intends the video stream  to interrupt or to continue the session according to the current state in the config object.
-(void)adaptSessionInterruption;

/// Starts an auto interruption which will interrupt the session for a short time and will continue the session thereafter.
/// On continuing the session the onComplition block will be called. This method can be called several times, all completionBlocks will be called.
-(void)autoInterruptOnCompletion:(void(^)(void))onCompletion;

/// After the scanner was initialzed for using CardIOOutputs, other CardIOOutputs can be be add by using this method.
-(void)addOutput:(CardIOOutput*)output;

/// After the scanner was initialzed fo using CardIOOutputs, CardIOOutputs, that are currently used by the cardIO view
/// can be be removed by using this method.
-(void)removeOutput:(CardIOOutput*)output;

#if SIMULATE_CAMERA
- (void)considerItScanned;
#endif

@property(nonatomic, strong, readwrite) CardIOConfig *config;
@property(nonatomic, assign, readonly) BOOL running;
@property(nonatomic, weak, readwrite) id<CardIOVideoStreamDelegate> delegate;
#if SIMULATE_CAMERA
@property(nonatomic, strong, readonly) CALayer *previewLayer;
#else
@property(nonatomic, strong, readonly) AVCaptureVideoPreviewLayer *previewLayer;
#endif
@property(nonatomic, strong, readwrite) CardIOCardScanner *scanner;
@end

#endif //USE_CAMERA || SIMULATE_CAMERA
