//
//  CardIOVideoStreamDelegate.h
//  See the file "LICENSE.md" for the full license governing this code.
//

@class CardIOVideoFrame;
@class CardIOVideoStream;

@protocol CardIOVideoStreamDelegate<NSObject>

@required

- (void)videoStream:(CardIOVideoStream *)stream didProcessFrame:(CardIOVideoFrame *)processedFrame;

@optional

- (void)videoStream:(CardIOVideoStream *)stream didChangeTorchIsNowOn:(BOOL)isTorchNowOn;

- (BOOL)isSupportedOverlayOrientation:(UIInterfaceOrientation)orientation;
- (UIInterfaceOrientation)defaultSupportedOverlayOrientation;

@end
