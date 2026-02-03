#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class PLVVodMediaPlayer;
@class PLVVodMediaVideo;
@class PLVLocalVideo;
@class PLVFlutterEventEmitter;
@class UIView;

@interface PLVFlutterPlayerSession : NSObject

- (instancetype)initWithEventEmitter:(PLVFlutterEventEmitter *)eventEmitter;

- (PLVVodMediaPlayer *)playerWithCoreDelegate:(id)coreDelegate vodDelegate:(id)vodDelegate;

- (BOOL)setupDisplaySuperview:(UIView *)displaySuperview coreDelegate:(id)coreDelegate vodDelegate:(id)vodDelegate;
- (BOOL)setVideo:(PLVVodMediaVideo *)video coreDelegate:(id)coreDelegate vodDelegate:(id)vodDelegate;
- (BOOL)setLocalPrior:(BOOL)localPrior coreDelegate:(id)coreDelegate vodDelegate:(id)vodDelegate;

- (BOOL)preparePlayerWithVideo:(PLVVodMediaVideo *)video
                displaySuperview:(UIView * _Nullable)displaySuperview
                  applyLocalPrior:(BOOL)applyLocalPrior
                      localPrior:(BOOL)localPrior
                   resetToStart:(BOOL)resetToStart
                    coreDelegate:(id)coreDelegate
                     vodDelegate:(id)vodDelegate;

- (void)requestVideoWithVid:(NSString *)vid completion:(void (^)(PLVVodMediaVideo * _Nullable video, NSError * _Nullable error))completion;
- (PLVLocalVideo * _Nullable)localVideoWithVid:(NSString *)vid downloadDir:(NSString *)downloadDir;

- (NSString * _Nullable)downloadDir;
- (NSInteger)lastSelectedQualityIndex;

- (BOOL)playWithCoreDelegate:(id)coreDelegate vodDelegate:(id)vodDelegate;
- (BOOL)pauseWithCoreDelegate:(id)coreDelegate vodDelegate:(id)vodDelegate;
- (BOOL)stopWithCoreDelegate:(id)coreDelegate vodDelegate:(id)vodDelegate;
- (BOOL)seekToTime:(NSTimeInterval)time coreDelegate:(id)coreDelegate vodDelegate:(id)vodDelegate;
- (BOOL)setPlaybackSpeed:(CGFloat)speed
           coreDelegate:(id)coreDelegate
            vodDelegate:(id)vodDelegate
              errorCode:(NSString * _Nullable * _Nullable)errorCode
          errorMessage:(NSString * _Nullable * _Nullable)errorMessage;

- (void)clearPlayer;

@end
