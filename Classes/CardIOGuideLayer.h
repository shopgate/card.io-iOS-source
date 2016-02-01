//
//  CardGuideOverlayView.h
//  See the file "LICENSE.md" for the full license governing this code.
//

#if USE_CAMERA || SIMULATE_CAMERA

#import <UIKit/UIKit.h>

#define kDefaultGuideColor [UIColor colorWithRed:0.0f green:1.0f blue:0.0f alpha:1.0f]

@protocol CardIOGuideLayerDelegate <NSObject>
@required
- (void)guideLayerDidLayout:(CGRect)internalGuideFrame;
- (void)guidelayerDidSetCardGuideInformation:(CGRect)internalGuideFrame foundTopEdge:(BOOL)foundTop foundLeftEdge:(BOOL)foundLeft foundBottomEdge:(BOOL)foundBottom foundRightEgde:(BOOL)foundRight isRotating:(BOOL)isRotating detectedCard:(BOOL)detectedCard;
@end

/**
 * This layer is meant to be layered atop a camera preview; it provides guidance about where to hold
 * the card, and what edges are currently recognized.
 *
 * It should be a sublayer of the camera preview, with the same size.
 */

@class CardIOVideoFrame;

@interface CardIOGuideLayer : CALayer

- (id)initWithDelegate:(id<CardIOGuideLayerDelegate>)guideLayerDelegate;

- (CGRect)guideFrame;

- (void)showCardFound:(BOOL)found;

- (void)didRotateToDeviceOrientation:(UIDeviceOrientation)deviceOrientation;

@property(nonatomic, strong, readwrite) UIColor *guideColor;
@property(nonatomic, strong, readwrite) CardIOVideoFrame *videoFrame;
@property(nonatomic, assign, readwrite) CFTimeInterval animationDuration;
@property(nonatomic, assign, readwrite) UIDeviceOrientation deviceOrientation;
@property(nonatomic, strong, readwrite) CAGradientLayer *fauxCardLayer;

@property(nonatomic, assign, readwrite) BOOL isEnabledExternalCardInformation;
@end

#endif
