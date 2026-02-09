#import "PLVFlutterPlayerSession.h"

#import "PLVFlutterEventEmitter.h"

#if __has_feature(modules)
@import PolyvMediaPlayerSDK;
#else
#import <PolyvMediaPlayerSDK/PolyvMediaPlayerSDK.h>
#endif

@class UIView;

@interface PLVFlutterPlayerSession ()

@property (nonatomic, strong) PLVFlutterEventEmitter *eventEmitter;
@property (nonatomic, strong) PLVVodMediaPlayer *player;

@end

@implementation PLVFlutterPlayerSession

- (instancetype)initWithEventEmitter:(PLVFlutterEventEmitter *)eventEmitter {
    self = [super init];
    if (self) {
        _eventEmitter = eventEmitter;
    }
    return self;
}

- (PLVVodMediaPlayer *)playerWithCoreDelegate:(id)coreDelegate vodDelegate:(id)vodDelegate {
    if (!self.player) {
        NSLog(@"[PolyvPlugin] ========== Creating player in session ==========");
        self.player = [[PLVVodMediaPlayer alloc] init];
        self.player.autoPlay = YES;
        self.player.videoToolBox = NO;
        self.player.rememberLastPosition = YES;  // 与原生 demo 一致
        self.player.seekType = PLVVodMediaPlaySeekTypePrecise;
    }

    if (coreDelegate && self.player.coreDelegate != coreDelegate) {
        self.player.coreDelegate = coreDelegate;
    }
    if (vodDelegate && self.player.delegateVodMediaPlayer != vodDelegate) {
        self.player.delegateVodMediaPlayer = vodDelegate;
    }

    return self.player;
}

- (BOOL)setupDisplaySuperview:(UIView *)displaySuperview coreDelegate:(id)coreDelegate vodDelegate:(id)vodDelegate {
    if (!displaySuperview) {
        return NO;
    }
    PLVVodMediaPlayer *player = [self playerWithCoreDelegate:coreDelegate vodDelegate:vodDelegate];
    if (!player) {
        return NO;
    }
    [player setupDisplaySuperview:displaySuperview];
    return YES;
}

- (BOOL)setVideo:(PLVVodMediaVideo *)video coreDelegate:(id)coreDelegate vodDelegate:(id)vodDelegate {
    if (!video) {
        return NO;
    }
    PLVVodMediaPlayer *player = [self playerWithCoreDelegate:coreDelegate vodDelegate:vodDelegate];
    if (!player) {
        return NO;
    }
    [player setVideo:video];
    return YES;
}

- (BOOL)setLocalPrior:(BOOL)localPrior coreDelegate:(id)coreDelegate vodDelegate:(id)vodDelegate {
    PLVVodMediaPlayer *player = [self playerWithCoreDelegate:coreDelegate vodDelegate:vodDelegate];
    if (!player) {
        return NO;
    }
    [player setLocalPrior:localPrior];
    return YES;
}

- (BOOL)preparePlayerWithVideo:(PLVVodMediaVideo *)video
                displaySuperview:(UIView * _Nullable)displaySuperview
                  applyLocalPrior:(BOOL)applyLocalPrior
                      localPrior:(BOOL)localPrior
                   resetToStart:(BOOL)resetToStart
                    coreDelegate:(id)coreDelegate
                     vodDelegate:(id)vodDelegate {
    if (!video) {
        return NO;
    }

    PLVVodMediaPlayer *player = [self playerWithCoreDelegate:coreDelegate vodDelegate:vodDelegate];
    if (!player) {
        return NO;
    }

    if (displaySuperview) {
        [player setupDisplaySuperview:displaySuperview];
    }
    if (applyLocalPrior) {
        [player setLocalPrior:localPrior];
    }
    [player setVideo:video];
    if (resetToStart) {
        [player seekToTime:0.0];
    }
    return YES;
}

- (void)requestVideoWithVid:(NSString *)vid completion:(void (^)(PLVVodMediaVideo * _Nullable video, NSError * _Nullable error))completion {
    if (vid.length == 0) {
        if (completion) {
            completion(nil, nil);
        }
        return;
    }

    [PLVVodMediaVideo requestVideoPriorityCacheWithVid:vid completion:^(PLVVodMediaVideo *video, NSError *error) {
        if (completion) {
            completion(video, error);
        }
    }];
}

- (PLVLocalVideo * _Nullable)localVideoWithVid:(NSString *)vid downloadDir:(NSString *)downloadDir {
    if (vid.length == 0 || downloadDir.length == 0) {
        return nil;
    }
    return [PLVLocalVideo localVideoWithVid:vid dir:downloadDir];
}

- (NSString * _Nullable)downloadDir {
    return [[PLVDownloadMediaManager sharedManager] downloadDir];
}

- (NSInteger)lastSelectedQualityIndex {
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"PLVLastSelectedQuality"];
}

- (BOOL)sendProgressEvent {
    if (!self.player || !self.eventEmitter) {
        return NO;
    }

    NSInteger position = (NSInteger)(self.player.currentPlaybackTime * 1000);
    NSInteger duration = (NSInteger)(self.player.duration * 1000);
    NSInteger buffered = (NSInteger)(self.player.playableDuration * 1000);

    [self.eventEmitter sendPlayerEvent:@{
        @"type": @"progress",
        @"data": @{
            @"position": @(position),
            @"duration": @(duration),
            @"bufferedPosition": @(buffered)
        }
    }];
    return YES;
}

- (BOOL)sendStateChangeEvent:(NSString *)state {
    if (!self.eventEmitter || state.length == 0) {
        return NO;
    }

    [self.eventEmitter sendPlayerEvent:@{
        @"type": @"stateChanged",
        @"data": @{ @"state": state }
    }];
    return YES;
}

- (BOOL)sendErrorEventWithCode:(NSString *)code message:(NSString *)message {
    if (!self.eventEmitter || code.length == 0) {
        return NO;
    }
    NSString *safeMessage = message ?: @"";

    [self.eventEmitter sendPlayerEvent:@{
        @"type": @"error",
        @"data": @{
            @"code": code,
            @"message": safeMessage
        }
    }];
    return YES;
}

- (BOOL)sendCompletedEvent {
    if (!self.eventEmitter) {
        return NO;
    }
    [self.eventEmitter sendPlayerEvent:@{
        @"type": @"completed",
        @"data": @{}
    }];
    return YES;
}

- (BOOL)playWithCoreDelegate:(id)coreDelegate vodDelegate:(id)vodDelegate {
    PLVVodMediaPlayer *player = [self playerWithCoreDelegate:coreDelegate vodDelegate:vodDelegate];
    if (!player) {
        return NO;
    }
    [player play];
    return YES;
}

- (BOOL)pauseWithCoreDelegate:(id)coreDelegate vodDelegate:(id)vodDelegate {
    PLVVodMediaPlayer *player = [self playerWithCoreDelegate:coreDelegate vodDelegate:vodDelegate];
    if (!player) {
        return NO;
    }
    [player pause];
    return YES;
}

- (BOOL)stopWithCoreDelegate:(id)coreDelegate vodDelegate:(id)vodDelegate {
    PLVVodMediaPlayer *player = [self playerWithCoreDelegate:coreDelegate vodDelegate:vodDelegate];
    if (!player) {
        return NO;
    }
    [player pause];
    [player seekToTime:0];
    return YES;
}

- (BOOL)seekToTime:(NSTimeInterval)time coreDelegate:(id)coreDelegate vodDelegate:(id)vodDelegate {
    PLVVodMediaPlayer *player = [self playerWithCoreDelegate:coreDelegate vodDelegate:vodDelegate];
    if (!player) {
        return NO;
    }
    [player seekToTime:time];
    return YES;
}

- (BOOL)setPlaybackSpeed:(CGFloat)speed
            coreDelegate:(id)coreDelegate
             vodDelegate:(id)vodDelegate
               errorCode:(NSString * _Nullable * _Nullable)errorCode
            errorMessage:(NSString * _Nullable * _Nullable)errorMessage {
    PLVVodMediaPlayer *player = [self playerWithCoreDelegate:coreDelegate vodDelegate:vodDelegate];
    if (!player) {
        if (errorCode) {
            *errorCode = @"NOT_INITIALIZED";
        }
        if (errorMessage) {
            *errorMessage = @"Player not initialized";
        }
        return NO;
    }

    if (speed < 0.5 || speed > 3.0) {
        if (errorCode) {
            *errorCode = @"UNSUPPORTED_SPEED";
        }
        if (errorMessage) {
            *errorMessage = [NSString stringWithFormat:@"Speed %.2f is outside supported range [0.5, 3.0]", speed];
        }
        return NO;
    }

    @try {
        [player switchSpeedRate:speed];
        return YES;
    } @catch (NSException *exception) {
        if (errorCode) {
            *errorCode = @"SDK_ERROR";
        }
        if (errorMessage) {
            *errorMessage = exception.reason;
        }
        return NO;
    }
}

- (void)clearPlayer {
    if (self.player) {
        [self.player clearPlayer];
        self.player = nil;
    }
}

@end
