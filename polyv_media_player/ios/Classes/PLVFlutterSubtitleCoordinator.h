#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class PLVVodMediaVideo;
@class PLVFlutterEventEmitter;

@interface PLVFlutterSubtitleCoordinator : NSObject

- (instancetype)initWithEventEmitter:(PLVFlutterEventEmitter *)eventEmitter;

- (void)updateContainerView:(UIView *)containerView;

- (void)resetLabelsAndModule;
- (void)resetAll;

- (void)setupIfNeededForVideo:(PLVVodMediaVideo *)video;
- (void)bringSubtitleLabelsToFront;
- (void)updateSubtitleLabelFrames;

- (void)showSubtitlesWithPlaytime:(NSTimeInterval)playtime;

- (void)sendSubtitleChangedEventWithVideo:(PLVVodMediaVideo *)video enabled:(BOOL)enabled trackKey:(NSString *)trackKey;

@end
