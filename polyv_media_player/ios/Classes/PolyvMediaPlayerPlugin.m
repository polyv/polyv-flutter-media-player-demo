#import "PolyvMediaPlayerPlugin.h"
#import "PLVVideoViewFactory.h"
#import "PLVFlutterEventStreamHandler.h"
#import "PLVFlutterEventEmitter.h"
#import "PLVFlutterDownloadMonitor.h"
#import "PLVFlutterSubtitleCoordinator.h"
#import "PLVFlutterPlayerSession.h"
#import "PLVFlutterMethodRouter.h"
#import <PolyvMediaPlayerSDK/PolyvMediaPlayerSDK.h>
#import <Flutter/Flutter.h>
#import <Flutter/FlutterPlugin.h>
#import <UIKit/UIDevice.h>

#define kMethodChannelName @"com.polyv.media_player/player"
#define kEventChannelName @"com.polyv.media_player/events"
#define kDownloadEventChannelName @"com.polyv.media_player/download_events"
#define kVideoViewType @"com.polyv.media_player/video_view"

// Error codes
static NSString *const kErrorCodeInvalidVid = @"INVALID_VID";
static NSString *const kErrorCodeNetworkError = @"NETWORK_ERROR";
static NSString *const kErrorCodeNotInitialized = @"NOT_INITIALIZED";

// State values
static NSString *const kStateIdle = @"idle";
static NSString *const kStateLoading = @"loading";
static NSString *const kStatePrepared = @"prepared";
static NSString *const kStatePlaying = @"playing";
static NSString *const kStatePaused = @"paused";
static NSString * kStateBuffering = @"buffering";
static NSString *const kStateCompleted = @"completed";
static NSString *const kStateError = @"error";

// 下载事件类型
static NSString *const kDownloadEventTaskRemoved = @"taskRemoved";

// 静态实例，用于视频视图关联
static PolyvMediaPlayerPlugin *_sharedInstance = nil;

@interface PolyvMediaPlayerPlugin () <FlutterPlugin, PLVMediaPlayerCoreDelegate, PLVVodMediaPlayerDelegate>
@property (nonatomic, strong) FlutterMethodChannel *methodChannel;
@property (nonatomic, strong) FlutterEventChannel *eventChannel;
@property (nonatomic, strong) PLVFlutterEventStreamHandler *eventStreamHandler;
@property (nonatomic, strong) FlutterEventChannel *downloadEventChannel;
@property (nonatomic, strong) PLVFlutterEventStreamHandler *downloadEventStreamHandler;
@property (nonatomic, strong) PLVFlutterEventEmitter *eventEmitter;
@property (nonatomic, strong) PLVFlutterDownloadMonitor *downloadMonitor;
@property (nonatomic, strong) PLVFlutterSubtitleCoordinator *subtitleCoordinator;
@property (nonatomic, strong) PLVFlutterMethodRouter *methodRouter;
@property (nonatomic, strong) PLVFlutterPlayerSession *playerSession;
@property (nonatomic, strong) PLVVodMediaPlayer *player;
@property (nonatomic, copy) NSString *currentVid;
@property (nonatomic, strong) PLVVideoViewController *videoViewController; // 改为 strong，防止被提前释放
@property (nonatomic, assign) NSInteger currentQualityIndex; // 当前清晰度索引
@property (nonatomic, strong) PLVVodMediaVideo *currentVideo; // 当前视频对象，用于获取清晰度信息
@property (nonatomic, assign) NSInteger qualitySwitchOperationId;
@property (nonatomic, assign) BOOL shouldSeekToStartOnPrepared;
// 记录当前设备方向，避免重复处理
@property (nonatomic, assign) UIDeviceOrientation lastOrientation;
// 账号配置相关属性
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *readToken;
@property (nonatomic, copy) NSString *writeToken;
@property (nonatomic, copy) NSString *secretKey;
@property (nonatomic, copy) NSString *env;          // 环境标识（预留）
@property (nonatomic, copy) NSString *businessLine; // 业务线标识（预留）

- (void)sendQualityDataForVideo:(PLVVodMediaVideo *)video;
- (void)sendQualityDataForVideo:(PLVVodMediaVideo *)video updateCurrentIndex:(NSInteger)updateIndex;

@end

@implementation PolyvMediaPlayerPlugin

+ (instancetype)sharedInstance {
    return _sharedInstance;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    PolyvMediaPlayerPlugin *instance = [[PolyvMediaPlayerPlugin alloc] init];
    _sharedInstance = instance; // 保存单例引用

    FlutterMethodChannel *methodChannel = [FlutterMethodChannel
        methodChannelWithName:kMethodChannelName
        binaryMessenger:[registrar messenger]];
    instance.methodChannel = methodChannel;
    instance.methodRouter = [[PLVFlutterMethodRouter alloc] initWithPlugin:instance];
    [registrar addMethodCallDelegate:instance channel:methodChannel];

    FlutterEventChannel *eventChannel = [FlutterEventChannel
        eventChannelWithName:kEventChannelName
        binaryMessenger:[registrar messenger]];
    PLVFlutterEventStreamHandler *eventHandler = [[PLVFlutterEventStreamHandler alloc] init];
    instance.eventStreamHandler = eventHandler;
    [eventChannel setStreamHandler:eventHandler];
    instance.eventChannel = eventChannel;

    FlutterEventChannel *downloadEventChannel = [FlutterEventChannel
        eventChannelWithName:kDownloadEventChannelName
        binaryMessenger:[registrar messenger]];
    PLVFlutterEventStreamHandler *downloadEventHandler = [[PLVFlutterEventStreamHandler alloc] init];
    instance.downloadEventStreamHandler = downloadEventHandler;
    [downloadEventChannel setStreamHandler:downloadEventHandler];
    instance.downloadEventChannel = downloadEventChannel;

    instance.eventEmitter = [[PLVFlutterEventEmitter alloc] initWithPlayerStreamHandler:eventHandler
                                                                     downloadStreamHandler:downloadEventHandler];

    instance.downloadMonitor = [[PLVFlutterDownloadMonitor alloc] initWithEventEmitter:instance.eventEmitter];

    instance.subtitleCoordinator = [[PLVFlutterSubtitleCoordinator alloc] initWithEventEmitter:instance.eventEmitter];

    instance.playerSession = [[PLVFlutterPlayerSession alloc] initWithEventEmitter:instance.eventEmitter];

    // 注册视频视图工厂
    PLVVideoViewFactory *viewFactory = [[PLVVideoViewFactory alloc] initWithMessenger:[registrar messenger]];
    [registrar registerViewFactory:viewFactory
                        withId:kVideoViewType];

    // 监听视频视图创建通知
    [[NSNotificationCenter defaultCenter] addObserver:instance
                                             selector:@selector(handleVideoViewCreated:)
                                                 name:@"PLVVideoViewCreated"
                                               object:nil];

    // 监听设备方向变化通知
    [[NSNotificationCenter defaultCenter] addObserver:instance
                                             selector:@selector(handleDeviceOrientationChange:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    // 启用设备方向通知
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];

    // 启动下载状态监控
    [instance startDownloadStatusMonitoring];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopDownloadStatusMonitoring];
}

- (void)handleVideoViewCreated:(NSNotification *)notification {
    PLVVideoViewController *videoViewController = notification.object;
    NSLog(@"[PolyvPlugin] Video view created: %@", videoViewController);
    
    // 检测是否是新的 videoViewController（横竖屏切换会创建新的）
    BOOL isNewViewController = (self.videoViewController != videoViewController);
    self.videoViewController = videoViewController;

    if (self.subtitleCoordinator && videoViewController.containerView) {
        [self.subtitleCoordinator updateContainerView:videoViewController.containerView];
    }

    // 如果播放器已存在，设置显示视图
    if (self.player) {
        NSLog(@"[PolyvPlugin] Player exists, setting up display superview");
        [self.player setupDisplaySuperview:videoViewController.containerView];
        NSLog(@"[PolyvPlugin] Display superview set: %@", self.player.displaySuperview);
    } else {
        NSLog(@"[PolyvPlugin] WARNING: videoViewController is still nil, will set up later");
    }
}

/// 处理设备方向变化
/// 横竖屏切换时需要重新设置字幕 label，因为 container 的 bounds 发生了变化
- (void)handleDeviceOrientationChange:(NSNotification *)notification {
    UIDeviceOrientation newOrientation = [UIDevice currentDevice].orientation;

    // 只在有效的横竖屏方向时处理（忽略 FaceUp/FaceDown/Unknown）
    BOOL isValidOrientation = UIDeviceOrientationIsPortrait(newOrientation) || UIDeviceOrientationIsLandscape(newOrientation);

    // 更新记录的设备方向（无论是否有效，都更新记录）
    UIDeviceOrientation previousOrientation = self.lastOrientation;
    self.lastOrientation = newOrientation;

    if (!self.currentVideo || !self.videoViewController || !isValidOrientation) {
        return;
    }

    // 检测横竖屏切换
    BOOL wasPortrait = UIDeviceOrientationIsPortrait(previousOrientation);
    BOOL wasLandscape = UIDeviceOrientationIsLandscape(previousOrientation);
    BOOL isNowPortrait = UIDeviceOrientationIsPortrait(newOrientation);
    BOOL isNowLandscape = UIDeviceOrientationIsLandscape(newOrientation);

    // 首次初始化（previousOrientation == 0）不视为切换
    if (previousOrientation == 0) {
        return;
    }

    BOOL orientationChanged = (wasPortrait && isNowLandscape) || (wasLandscape && isNowPortrait);

    if (orientationChanged) {
        NSLog(@"[PolyvPlugin] 横竖屏切换: %@ -> %@", wasLandscape ? @"横屏" : @"竖屏", isNowLandscape ? @"横屏" : @"竖屏");

        // 延迟一小段时间，等待视图布局动画完成
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.subtitleCoordinator resetLabelsAndModule];
        });
    }
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if (!self.methodRouter) {
        self.methodRouter = [[PLVFlutterMethodRouter alloc] initWithPlugin:self];
    }

    BOOL handled = [self.methodRouter handleMethodCall:call result:result];
    if (!handled) {
        result(FlutterMethodNotImplemented);
    }
}

#pragma mark - Helper Methods

/// 确保账号已配置（必须通过 initialize 方法预先注入）
/// 返回 YES 表示配置成功，NO 表示缺少必要配置
- (BOOL)ensureAccountConfiguredOrReturnError:(FlutterResult)result {
    // 检查是否已通过 initialize 方法注入配置
    if (self.userId.length > 0 && self.secretKey.length > 0) {
        return YES;
    }

    // 没有配置，返回错误
    NSLog(@"[PolyvPlugin] ERROR: Account config missing. Please call PolyvConfigService.setAccountConfig() before loading video");
    result([FlutterError errorWithCode:@"NOT_INITIALIZED"
                               message:@"Polyv authentication not configured. Please call PolyvConfigService.setAccountConfig() with userId and secretKey before loading video"
                               details:nil]);
    return NO;
}

#pragma mark - Method Handlers

/// 初始化账号配置
///
/// 此方法由 Flutter 层调用，用于配置播放器所需的账号信息。
/// 支持多次调用以实现热重载（清除旧配置，应用新配置）。
- (void)handleInitialize:(NSDictionary *)args result:(FlutterResult)result {
    NSLog(@"[PolyvPlugin] ========== handleInitialize called ==========");

    // 提取账号字段
    NSString *userId = args[@"userId"];
    NSString *readToken = args[@"readToken"];
    NSString *writeToken = args[@"writeToken"];
    NSString *secretKey = args[@"secretKey"];
    NSString *env = args[@"env"];
    NSString *businessLine = args[@"businessLine"];

    // 校验必填字段（仅 userId 与 secretKey 为必填，其余字段可选）
    if (!userId || userId.length == 0) {
        NSLog(@"[PolyvPlugin] ERROR: userId is empty");
        result([FlutterError errorWithCode:@"INVALID_CONFIG"
                                    message:@"userId is required"
                                    details:nil]);
        return;
    }
    if (!secretKey || secretKey.length == 0) {
        NSLog(@"[PolyvPlugin] ERROR: secretKey is empty");
        result([FlutterError errorWithCode:@"INVALID_CONFIG"
                                    message:@"secretKey is required"
                                    details:nil]);
        return;
    }

    // 保存账号配置（支持热重载）
    self.userId = userId;
    self.readToken = readToken;
    self.writeToken = writeToken;
    self.secretKey = secretKey;
    self.env = env;
    self.businessLine = businessLine;

    NSLog(@"[PolyvPlugin] Account config updated: userId=%@, env=%@, businessLine=%@",
          userId, env ?: @"nil", businessLine ?: @"nil");

    // 同步更新 SDK 的全局账号配置
    // 这样 SDK 的其他模块（如视频列表请求）也能使用这些账号信息
    PLVVodMediaSettings *settings = [PLVVodMediaSettings settingsWithUserid:userId
                                                                      readtoken:readToken
                                                                     writetoken:writeToken
                                                                      secretkey:secretKey];
    settings.logLevel = PLVVodMediaLogLevelAll;

    NSLog(@"[PolyvPlugin] SDK account settings updated successfully");

    result(nil);
}

// Lazy getter for player - 按照demo的模式创建播放器
// 这样确保播放器和代理在视频加载之前就已经正确设置
- (PLVVodMediaPlayer *)player {
    _player = [self.playerSession playerWithCoreDelegate:self vodDelegate:self];
    return _player;
}

- (void)handleLoadVideo:(NSDictionary *)args result:(FlutterResult)result {
    NSLog(@"[PolyvPlugin] ========== handleLoadVideo called ==========");
    NSString *vid = args[@"vid"];
    BOOL isOfflineMode = [args[@"isOfflineMode"] boolValue];
    NSLog(@"[PolyvPlugin] VID: %@, isOfflineMode: %d", vid, isOfflineMode);

    if (!vid || vid.length == 0) {
        NSLog(@"[PolyvPlugin] ERROR: VID is empty");
        result([FlutterError errorWithCode:kErrorCodeInvalidVid
                                    message:@"VID is required"
                                    details:nil]);
        return;
    }

    self.currentVid = vid;
    self.qualitySwitchOperationId += 1;
    self.shouldSeekToStartOnPrepared = YES;

    [self.subtitleCoordinator resetAll];

    // 确保账号已配置（优先使用已有配置，否则从 Info.plist 读取）
    if (![self ensureAccountConfiguredOrReturnError:result]) {
        return;
    }

    // Dart 层统一控制自动播放，原生端不处理 autoPlay
    [self sendStateChangeEvent:kStateLoading];

    // 离线播放模式
    if (isOfflineMode) {
        NSLog(@"[PolyvPlugin] Loading video in OFFLINE mode");
        [self loadVideoOffline:vid result:result];
        return;
    }

    // 在线播放模式
    NSLog(@"[PolyvPlugin] Loading video in ONLINE mode");
    [self loadVideoOnline:vid result:result];
}

/// 在线播放视频
- (void)loadVideoOnline:(NSString *)vid result:(FlutterResult)result {
    NSLog(@"[PolyvPlugin] Requesting video with VID...");

    void (^completionHandler)(PLVVodMediaVideo *video, NSError *error) = ^(PLVVodMediaVideo *video, NSError *error) {
        NSLog(@"[PolyvPlugin] ========== Video request completion handler called ==========");
        NSLog(@"[PolyvPlugin] Error: %@, Video: %@", error, video);

        if (error) {
            NSLog(@"[PolyvPlugin] ERROR loading video: %@", error.localizedDescription);
            [self sendErrorEventWithCode:kErrorCodeNetworkError message:error.localizedDescription];
            [self sendStateChangeEvent:kStateError];
            result([FlutterError errorWithCode:kErrorCodeNetworkError
                                        message:error.localizedDescription
                                        details:nil]);
            return;
        }

        if (!video) {
            NSLog(@"[PolyvPlugin] ERROR: Video is nil");
            [self sendErrorEventWithCode:kErrorCodeInvalidVid message:@"Video not found"];
            [self sendStateChangeEvent:kStateError];
            result([FlutterError errorWithCode:kErrorCodeInvalidVid
                                        message:@"Video not found"
                                        details:nil]);
            return;
        }

        NSLog(@"[PolyvPlugin] ========== Video loaded successfully, duration: %.2f ==========", video.duration);

        self.currentVideo = video;

        NSInteger savedQualityIndex = [self.playerSession lastSelectedQualityIndex];
        if (savedQualityIndex > 0) {
            self.currentQualityIndex = savedQualityIndex;
            NSLog(@"[PolyvPlugin] Restored quality index from playerSession: %ld", (long)savedQualityIndex);
        } else {
            self.currentQualityIndex = 2;
        }

        [self sendQualityDataForVideo:video];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.videoViewController) {
                NSLog(@"[PolyvPlugin] Setting up display superview BEFORE setVideo");
                [self.playerSession preparePlayerWithVideo:video
                                          displaySuperview:self.videoViewController.containerView
                                            applyLocalPrior:NO
                                                localPrior:NO
                                             resetToStart:YES
                                              coreDelegate:self
                                               vodDelegate:self];
            } else {
                NSLog(@"[PolyvPlugin] WARNING: videoViewController is still nil, will set up later");
                [self.playerSession preparePlayerWithVideo:video
                                          displaySuperview:nil
                                            applyLocalPrior:NO
                                                localPrior:NO
                                             resetToStart:YES
                                              coreDelegate:self
                                               vodDelegate:self];
            }

            NSLog(@"[PolyvPlugin] Video set, playbackState: %ld", (long)self.player.playbackState);
            NSLog(@"[PolyvPlugin] Position reset to 0");

            [self setupSubtitleModuleIfNeededForVideo:video];
        });

        result(nil);
    };

    [self.playerSession requestVideoWithVid:vid completion:completionHandler];
}

/// 离线播放视频
///
/// 修复：无网络情况下播放已下载视频
/// 1. 从 PLVDownloadInfo 获取视频元数据（不依赖网络）
/// 2. 使用本地视频文件播放
/// 3. 网络请求失败不影响播放
- (void)loadVideoOffline:(NSString *)vid result:(FlutterResult)result {
    NSString *downloadDir = [self.playerSession downloadDir];
    NSLog(@"[PolyvPlugin] ========== loadVideoOffline called ==========");
    NSLog(@"[PolyvPlugin] VID: %@, Download directory: %@", vid, downloadDir);

    if (!downloadDir || downloadDir.length == 0) {
        NSLog(@"[PolyvPlugin] ERROR: Download directory not found");
        [self sendErrorEventWithCode:@"OFFLINE_ERROR" message:@"Download directory not found"];
        [self sendStateChangeEvent:kStateError];
        result([FlutterError errorWithCode:@"OFFLINE_ERROR"
                                    message:@"Download directory not found"
                                    details:nil]);
        return;
    }

    // Step 1: 从下载管理器获取下载信息（包含视频元数据）
    // 这样可以在无网络时获取清晰度、字幕等信息
    PLVDownloadInfo *downloadInfo = [[PLVDownloadMediaManager sharedManager] getDownloadInfo:vid fileType:PLVDownloadFileTypeVideo];
    BOOL hasMetadataFromDownload = NO;

    if (downloadInfo && downloadInfo.video) {
        NSLog(@"[PolyvPlugin] Found download info with video metadata for vid: %@", vid);
        self.currentVideo = downloadInfo.video;

        NSInteger savedQualityIndex = [self.playerSession lastSelectedQualityIndex];
        if (savedQualityIndex > 0) {
            self.currentQualityIndex = savedQualityIndex;
            NSLog(@"[PolyvPlugin] Restored quality index from playerSession (offline): %ld", (long)savedQualityIndex);
        } else {
            self.currentQualityIndex = 2;
        }

        [self sendQualityDataForVideo:self.currentVideo];
        [self setupSubtitleModuleIfNeededForVideo:self.currentVideo];
        hasMetadataFromDownload = YES;
        NSLog(@"[PolyvPlugin] Metadata loaded from download info, playback can proceed without network");
    } else {
        NSLog(@"[PolyvPlugin] Warning: Download info or video metadata not found, will try network request");
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        // Step 2: 设置显示视图
        if (self.videoViewController) {
            NSLog(@"[PolyvPlugin] Setting up display superview for offline playback");
            [self.playerSession setupDisplaySuperview:self.videoViewController.containerView coreDelegate:self vodDelegate:self];
        }

        // Step 3: 创建本地视频对象
        PLVLocalVideo *localVideo = [self.playerSession localVideoWithVid:vid downloadDir:downloadDir];
        if (!localVideo) {
            NSLog(@"[PolyvPlugin] ERROR: Failed to create local video for vid: %@", vid);
            [self sendErrorEventWithCode:@"OFFLINE_ERROR" message:@"Local video not found"];
            [self sendStateChangeEvent:kStateError];
            result([FlutterError errorWithCode:@"OFFLINE_ERROR"
                                        message:@"Local video not found, please download first"
                                        details:nil]);
            return;
        }

        // Step 4: 设置播放器使用本地视频
        [self.playerSession preparePlayerWithVideo:localVideo
                                  displaySuperview:(self.videoViewController ? self.videoViewController.containerView : nil)
                                    applyLocalPrior:YES
                                        localPrior:YES
                                     resetToStart:YES
                                      coreDelegate:self
                                       vodDelegate:self];

        NSLog(@"[PolyvPlugin] Local video loaded, playbackState: %ld", (long)self.player.playbackState);
        NSLog(@"[PolyvPlugin] Position reset to 0");

        // Step 5: 如果已有元数据，立即返回成功
        // 这样即使无网络，Flutter 层也能收到响应并继续播放
        if (hasMetadataFromDownload) {
            NSLog(@"[PolyvPlugin] Offline playback ready (using cached metadata)");
            result(nil);

            // Step 6: 可选：后台尝试获取最新元数据（不阻塞播放）
            // 这样可以在有网络时更新元数据，但无网络时也能播放
            [self.playerSession requestVideoWithVid:vid completion:^(PLVVodMediaVideo *video, NSError *error) {
                if (video && !error) {
                    NSLog(@"[PolyvPlugin] Updated video metadata from network");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.currentVideo = video;
                        [self sendQualityDataForVideo:video];
                        [self setupSubtitleModuleIfNeededForVideo:video];
                    });
                } else {
                    NSLog(@"[PolyvPlugin] Network request for metadata failed (expected in offline mode): %@", error.localizedDescription);
                }
            }];
        } else {
            // Step 7: 如果没有下载元数据，必须等待网络请求
            // 这种情况下无网络将无法播放（降级行为）
            NSLog(@"[PolyvPlugin] No cached metadata, waiting for network request...");
            void (^offlineMetadataCompletion)(PLVVodMediaVideo *video, NSError *error) = ^(PLVVodMediaVideo *video, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (video && !error) {
                        self.currentVideo = video;

                        NSInteger savedQualityIndex = [self.playerSession lastSelectedQualityIndex];
                        if (savedQualityIndex > 0) {
                            self.currentQualityIndex = savedQualityIndex;
                            NSLog(@"[PolyvPlugin] Restored quality index from playerSession (offline): %ld", (long)savedQualityIndex);
                        } else {
                            self.currentQualityIndex = 2;
                        }

                        [self sendQualityDataForVideo:video];
                        [self setupSubtitleModuleIfNeededForVideo:video];
                        result(nil);
                    } else {
                        NSLog(@"[PolyvPlugin] ERROR: Could not fetch video metadata for offline playback");
                        [self sendErrorEventWithCode:@"OFFLINE_ERROR" message:@"Video metadata not available"];
                        [self sendStateChangeEvent:kStateError];
                        result([FlutterError errorWithCode:@"OFFLINE_ERROR"
                                                    message:@"Video metadata not available, please connect to network first"
                                                    details:nil]);
                    }
                });
            };

            [self.playerSession requestVideoWithVid:vid completion:offlineMetadataCompletion];
        }
    });
}

- (void)handlePlay:(FlutterResult)result {
    NSLog(@"[PolyvPlugin] ========== handlePlay called ==========");
    NSLog(@"[PolyvPlugin] player exists: %@", self.player ? @"YES" : @"NO");
    if (!self.player) {
        result([FlutterError errorWithCode:kErrorCodeNotInitialized
                                    message:@"Player not initialized"
                                    details:nil]);
        return;
    }

    NSLog(@"[PolyvPlugin] playbackState: %ld", (long)self.player.playbackState);
    NSLog(@"[PolyvPlugin] video: %@", self.player.video);
    NSLog(@"[PolyvPlugin] displaySuperview: %@", self.player.displaySuperview);
    NSLog(@"[PolyvPlugin] coreDelegate: %@", self.player.coreDelegate);

    // 确保在主线程上调用 play
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[PolyvPlugin] Calling play on main thread");
        [self.playerSession playWithCoreDelegate:self vodDelegate:self];
        NSLog(@"[PolyvPlugin] play method called, playbackState now: %ld", (long)self.player.playbackState);

        // 延迟检查状态
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"[PolyvPlugin] After 0.5s, playbackState: %ld", (long)self.player.playbackState);
        });
    });

    result(nil);
}

 - (void)handlePause:(FlutterResult)result {
     if (!self.player) {
         result([FlutterError errorWithCode:kErrorCodeNotInitialized
                                     message:@"Player not initialized"
                                     details:nil]);
         return;
     }
     [self.playerSession pauseWithCoreDelegate:self vodDelegate:self];
     result(nil);
 }

 - (void)handleStop:(FlutterResult)result {
     // stop 不应该销毁播放器，只停止播放并重置进度
     [self.playerSession stopWithCoreDelegate:self vodDelegate:self];
     [self sendStateChangeEvent:kStateIdle];
     result(nil);
 }

 - (void)handleSeekTo:(NSDictionary *)args result:(FlutterResult)result {
     if (!self.player) {
         result([FlutterError errorWithCode:kErrorCodeNotInitialized
                                     message:@"Player not initialized"
                                     details:nil]);
         return;
     }

      NSInteger position = [args[@"position"] integerValue];
      NSTimeInterval time = position / 1000.0;
      [self.playerSession seekToTime:time coreDelegate:self vodDelegate:self];
      result(nil);
  }

- (void)handleSetPlaybackSpeed:(NSDictionary *)args result:(FlutterResult)result {
    NSLog(@"[PolyvPlugin] ========== handleSetPlaybackSpeed called ==========");
    if (!self.player) {
        result([FlutterError errorWithCode:kErrorCodeNotInitialized
                                    message:@"Player not initialized"
                                    details:nil]);
        return;
    }

     CGFloat speed = [args[@"speed"] doubleValue];
     NSLog(@"[PolyvPlugin] Setting playback speed to: %.2f", speed);

    // iOS SDK 使用 switchSpeedRate: 方法设置倍速
    // 倍速范围通常为 0.5 - 2.0
    if (speed < 0.5 || speed > 3.0) {
        NSLog(@"[PolyvPlugin] WARNING: Speed %.2f is outside recommended range [0.5, 3.0]", speed);
        // 返回错误而不是继续执行
        result([FlutterError errorWithCode:@"UNSUPPORTED_SPEED"
                                    message:[NSString stringWithFormat:@"Speed %.2f is outside supported range [0.5, 3.0]", speed]
                                    details:nil]);
        return;
    }

     NSString *errorCode = nil;
     NSString *errorMessage = nil;
     BOOL success = NO;
     success = [self.playerSession setPlaybackSpeed:speed
                                       coreDelegate:self
                                        vodDelegate:self
                                          errorCode:&errorCode
                                       errorMessage:&errorMessage];

    if (!success) {
        result([FlutterError errorWithCode:(errorCode ?: kErrorCodeNetworkError)
                                    message:(errorMessage ?: @"Failed to set playback speed")
                                    details:nil]);
        return;
    }

     NSLog(@"[PolyvPlugin] Playback speed set to: %.2f", speed);
     [self.eventEmitter sendPlayerEvent:@{
         @"type": @"playbackSpeedChanged",
         @"data": @{
             @"speed": @(speed)
         }
     }];
     result(nil);
 }

- (void)handleSetQuality:(NSDictionary *)args result:(FlutterResult)result {
    if (!self.player) {
        result([FlutterError errorWithCode:kErrorCodeNotInitialized
                                    message:@"Player not initialized"
                                    details:nil]);
        return;
    }

    NSInteger index = [args[@"index"] integerValue];

    // UI 层的索引需要 +1 来匹配 SDK 的枚举值（因为去掉了"自动"选项）
    // iOS SDK 的清晰度枚举: 0=自动, 1=流畅, 2=高清, 3=超清
    // UI 层显示: 流畅, 高清, 超清（对应 SDK 的 1, 2, 3）
    NSInteger sdkIndex = index + 1;
    PLVVodMediaQuality quality = (PLVVodMediaQuality)sdkIndex;

    // 调用 SDK 的 setPlayQuality: 方法
    // SDK 内部会自动处理续播、URL 切换等
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.player setPlayQuality:quality];
    });

    // 保存 SDK 层的索引
    self.currentQualityIndex = sdkIndex;

    // 持久化保存用户选择的清晰度
    if (self.currentQualityIndex > 0) {
        [[NSUserDefaults standardUserDefaults] setInteger:sdkIndex forKey:@"PLVLastSelectedQuality"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    // 发送更新后的清晰度数据
    [self sendQualityDataForVideo:self.currentVideo updateCurrentIndex:sdkIndex];

    result(nil);
}

- (void)handleSetSubtitle:(NSDictionary *)args result:(FlutterResult)result {
    if (!self.player) {
        result([FlutterError errorWithCode:kErrorCodeNotInitialized
                                    message:@"Player not initialized"
                                    details:nil]);
        return;
    }

    // 兼容旧接口：setSubtitle(index) 与新接口：setSubtitleWithKey({ enabled, trackKey })

    BOOL hasNewApiArgs = (args[@"enabled"] != nil) || (args[@"trackKey"] != nil);

    if (!hasNewApiArgs) {
        // 旧接口：通过 index 控制字幕，-1 表示关闭
        NSInteger index = [args[@"index"] integerValue];

        if (index < 0) {
            // 关闭字幕
            [self sendSubtitleChangedEventWithEnabled:NO trackKey:nil];
            result(nil);
            return;
        }

        // 根据当前视频的 srts 列表推导 trackKey
        NSString *trackKey = nil;
        if (self.currentVideo && [self.currentVideo.srts isKindOfClass:[NSArray class]]) {
            NSArray *srts = (NSArray *)self.currentVideo.srts;
            if (index < (NSInteger)srts.count) {
                id item = srts[index];
                @try {
                    // PLVVodMediaVideoSubtitleItem *item，有 title 属性
                    if ([item respondsToSelector:@selector(title)]) {
                        trackKey = [item valueForKey:@"title"];
                    }
                } @catch (__unused NSException *exception) {
                    trackKey = nil;
                }
            }
        }

        [self sendSubtitleChangedEventWithEnabled:(trackKey != nil) trackKey:trackKey];
        result(nil);
        return;
    }

    // 新接口：setSubtitleWithKey({ enabled, trackKey })
    BOOL enabled = YES;
    id enabledValue = args[@"enabled"];
    if ([enabledValue isKindOfClass:[NSNumber class]]) {
        enabled = [enabledValue boolValue];
    }
    NSString *trackKey = [args[@"trackKey"] isKindOfClass:[NSString class]] ? args[@"trackKey"] : nil;

    if (!enabled) {
        // 关闭字幕
        [self sendSubtitleChangedEventWithEnabled:NO trackKey:nil];
        result(nil);
        return;
    }

    // 开启字幕：直接使用传入的 trackKey，subtitles 列表与当前视频字幕对齐
    [self sendSubtitleChangedEventWithEnabled:YES trackKey:trackKey];
    result(nil);
}

- (void)handleGetQualities:(FlutterResult)result {
    // TODO: quality API needs SDK documentation
    // 暂时返回空列表
    result(@[]);
}

- (void)handleGetSubtitles:(FlutterResult)result {
    // TODO: subtitle API needs SDK documentation
    // 暂时返回空列表
    result(@[]);
}

/// Story 9.7: 暂停下载任务
///
/// 调用 PLVDownloadMediaManager 的 stopDownloadTask: 方法
- (void)handlePauseDownload:(NSDictionary *)args result:(FlutterResult)result {
    NSLog(@"[PolyvPlugin] ========== handlePauseDownload called ==========");
    NSString *vid = args[@"vid"];
    NSLog(@"[PolyvPlugin] VID: %@", vid);

    if (!vid || vid.length == 0) {
        NSLog(@"[PolyvPlugin] ERROR: VID is empty");
        result([FlutterError errorWithCode:@"INVALID_ARGUMENT"
                                   message:@"VID is required"
                                   details:nil]);
        return;
    }

    // 根据 vid 获取下载信息
    PLVDownloadInfo *downloadInfo = [[PLVDownloadMediaManager sharedManager] getDownloadInfo:vid fileType:PLVDownloadFileTypeVideo];
    if (!downloadInfo) {
        NSLog(@"[PolyvPlugin] ERROR: Download task not found for vid: %@", vid);
        result([FlutterError errorWithCode:@"NOT_FOUND"
                                   message:@"Download task not found"
                                   details:nil]);
        return;
    }

    // 调用 SDK 暂停下载，添加错误处理以实现强一致性
    @try {
        [[PLVDownloadMediaManager sharedManager] stopDownloadTask:downloadInfo];
        NSLog(@"[PolyvPlugin] Download paused for vid: %@", vid);
        result(nil);
    } @catch (NSException *exception) {
        NSLog(@"[PolyvPlugin] ERROR: Failed to pause download - %@", exception.reason);
        result([FlutterError errorWithCode:@"SDK_ERROR"
                                   message:exception.reason ?: @"Failed to pause download"
                                   details:nil]);
    }
}

/// Story 9.7: 恢复下载任务
///
/// 调用 PLVDownloadMediaManager 的 startDownloadTask:highPriority: 方法
- (void)handleResumeDownload:(NSDictionary *)args result:(FlutterResult)result {
    NSLog(@"[PolyvPlugin] ========== handleResumeDownload called ==========");
    NSString *vid = args[@"vid"];
    NSLog(@"[PolyvPlugin] VID: %@", vid);

    if (!vid || vid.length == 0) {
        NSLog(@"[PolyvPlugin] ERROR: VID is empty");
        result([FlutterError errorWithCode:@"INVALID_ARGUMENT"
                                   message:@"VID is required"
                                   details:nil]);
        return;
    }

    // 根据 vid 获取下载信息
    PLVDownloadInfo *downloadInfo = [[PLVDownloadMediaManager sharedManager] getDownloadInfo:vid fileType:PLVDownloadFileTypeVideo];
    if (!downloadInfo) {
        NSLog(@"[PolyvPlugin] ERROR: Download task not found for vid: %@", vid);
        result([FlutterError errorWithCode:@"NOT_FOUND"
                                   message:@"Download task not found"
                                   details:nil]);
        return;
    }

    // 调用 SDK 恢复下载，添加错误处理以实现强一致性
    @try {
        [[PLVDownloadMediaManager sharedManager] startDownloadTask:downloadInfo highPriority:NO];
        NSLog(@"[PolyvPlugin] Download resumed for vid: %@", vid);
        result(nil);
    } @catch (NSException *exception) {
        NSLog(@"[PolyvPlugin] ERROR: Failed to resume download - %@", exception.reason);
        result([FlutterError errorWithCode:@"SDK_ERROR"
                                   message:exception.reason ?: @"Failed to resume download"
                                   details:nil]);
    }
}

/// Story 9.4/9.7: 重试失败的下载任务
///
/// 调用 PLVDownloadMediaManager 的 startDownloadTask:highPriority: 方法
- (void)handleRetryDownload:(NSDictionary *)args result:(FlutterResult)result {
    NSLog(@"[PolyvPlugin] ========== handleRetryDownload called ==========");
    NSString *vid = args[@"vid"];
    NSLog(@"[PolyvPlugin] VID: %@", vid);

    if (!vid || vid.length == 0) {
        NSLog(@"[PolyvPlugin] ERROR: VID is empty");
        result([FlutterError errorWithCode:@"INVALID_ARGUMENT"
                                   message:@"VID is required"
                                   details:nil]);
        return;
    }

    // 根据 vid 获取下载信息
    PLVDownloadInfo *downloadInfo = [[PLVDownloadMediaManager sharedManager] getDownloadInfo:vid fileType:PLVDownloadFileTypeVideo];
    if (!downloadInfo) {
        NSLog(@"[PolyvPlugin] ERROR: Download task not found for vid: %@", vid);
        result([FlutterError errorWithCode:@"NOT_FOUND"
                                   message:@"Download task not found"
                                   details:nil]);
        return;
    }

    // 调用 SDK 重试下载（与恢复相同，使用 startDownloadTask），添加错误处理以实现强一致性
    @try {
        [[PLVDownloadMediaManager sharedManager] startDownloadTask:downloadInfo highPriority:NO];
        NSLog(@"[PolyvPlugin] Download retry started for vid: %@", vid);
        result(nil);
    } @catch (NSException *exception) {
        NSLog(@"[PolyvPlugin] ERROR: Failed to retry download - %@", exception.reason);
        result([FlutterError errorWithCode:@"SDK_ERROR"
                                   message:exception.reason ?: @"Failed to retry download"
                                   details:nil]);
    }
}

/// Story 9.8: 获取下载任务列表（权威同步）
///
/// 从 PLVDownloadMediaManager 获取所有下载任务，转换为 Flutter 可用的格式
- (void)handleGetDownloadList:(FlutterResult)result {
    NSLog(@"[PolyvPlugin] ========== handleGetDownloadList called ==========");

    if (!self.downloadMonitor) {
        self.downloadMonitor = [[PLVFlutterDownloadMonitor alloc] initWithEventEmitter:self.eventEmitter];
    }
    result([self.downloadMonitor fetchDownloadTaskList]);
}

/// Story 9.5/9.7: 删除下载任务
///
/// 调用 PLVDownloadMediaManager 的 removeDownloadTask:error: 方法
- (void)handleDeleteDownload:(NSDictionary *)args result:(FlutterResult)result {
    NSLog(@"[PolyvPlugin] ========== handleDeleteDownload called ==========");
    NSString *vid = args[@"vid"];
    NSLog(@"[PolyvPlugin] VID: %@", vid);

    if (!vid || vid.length == 0) {
        NSLog(@"[PolyvPlugin] ERROR: VID is empty");
        result([FlutterError errorWithCode:@"INVALID_ARGUMENT"
                                   message:@"VID is required"
                                   details:nil]);
        return;
    }

    // 根据 vid 获取下载信息
    PLVDownloadInfo *downloadInfo = [[PLVDownloadMediaManager sharedManager] getDownloadInfo:vid fileType:PLVDownloadFileTypeVideo];
    if (!downloadInfo) {
        // 强一致性：下载任务不存在，返回 NOT_FOUND 错误（而非视为成功）
        NSLog(@"[PolyvPlugin] ERROR: Download task not found for vid: %@", vid);
        result([FlutterError errorWithCode:@"NOT_FOUND"
                                   message:@"Download task not found"
                                   details:nil]);
        return;
    }

    // 调用 SDK 删除下载任务
    // 注意：removeDownloadTask:error: 方法返回 void，通过 error 参数判断是否成功
    NSError *error = nil;
    [[PLVDownloadMediaManager sharedManager] removeDownloadTask:downloadInfo error:&error];

    if (error) {
        NSLog(@"[PolyvPlugin] ERROR: Failed to delete download task - %@", error.localizedDescription);
        result([FlutterError errorWithCode:@"DELETE_FAILED"
                                   message:error.localizedDescription
                                   details:nil]);
        return;
    }

    NSLog(@"[PolyvPlugin] Download deleted for vid: %@", vid);
    
    // 发送 taskRemoved 事件通知 Flutter 层
    [self.eventEmitter sendDownloadEvent:@{
        @"type": kDownloadEventTaskRemoved,
        @"data": @{
            @"id": vid
        }
    }];
    
    result(nil);
}

/// Story 9.9: 创建下载任务（添加视频到下载队列）
///
/// 调用 PLVDownloadMediaManager 的 addVideoTask:quality: 方法
- (void)handleStartDownload:(NSDictionary *)args result:(FlutterResult)result {
    NSLog(@"[PolyvPlugin] ========== handleStartDownload called ==========");
    NSString *vid = args[@"vid"];
    NSString *quality = args[@"quality"]; // "480p", "720p", "1080p"
    NSLog(@"[PolyvPlugin] VID: %@, Quality: %@", vid, quality);

    if (!vid || vid.length == 0) {
        NSLog(@"[PolyvPlugin] ERROR: VID is empty");
        result([FlutterError errorWithCode:@"INVALID_ARGUMENT"
                                   message:@"VID is required"
                                   details:nil]);
        return;
    }

    // 检查账号配置是否已初始化
    if (!self.userId || self.userId.length == 0) {
        NSLog(@"[PolyvPlugin] ERROR: Account not configured. Please call initialize() first.");
        result([FlutterError errorWithCode:@"NOT_INITIALIZED"
                                   message:@"Account not configured. Please call initialize() first."
                                   details:nil]);
        return;
    }

    // 设置 accountId（必须设置才能开始下载）
    [[PLVDownloadMediaManager sharedManager] setAccountID:self.userId];

    // 检查是否已有相同 VID 的下载任务
    PLVDownloadInfo *existingInfo = [[PLVDownloadMediaManager sharedManager] getDownloadInfo:vid fileType:PLVDownloadFileTypeVideo];
    if (existingInfo) {
        NSLog(@"[PolyvPlugin] Download task already exists for vid: %@", vid);
        // 任务已存在，视为成功（幂等性）
        result(nil);
        return;
    }

    // 根据传入的清晰度值映射到 iOS SDK 的清晰度枚举
    // 默认使用高清
    PLVVodMediaQuality downloadQuality = PLVVodMediaQualityHigh;
    if (quality) {
        if ([quality isEqualToString:@"480p"]) {
            downloadQuality = PLVVodMediaQualityStandard;
        } else if ([quality isEqualToString:@"720p"]) {
            downloadQuality = PLVVodMediaQualityHigh;
        } else if ([quality isEqualToString:@"1080p"]) {
            downloadQuality = PLVVodMediaQualityUltra;
        }
    }
    NSLog(@"[PolyvPlugin] Using quality: %ld", (long)downloadQuality);

    // 请求视频信息
    [PLVVodMediaVideo requestVideoPriorityCacheWithVid:vid completion:^(PLVVodMediaVideo *video, NSError *error) {
        if (error) {
            NSLog(@"[PolyvPlugin] ERROR: Failed to request video for download - %@", error.localizedDescription);
            result([FlutterError errorWithCode:@"NETWORK_ERROR"
                                       message:[NSString stringWithFormat:@"Failed to request video: %@", error.localizedDescription]
                                       details:nil]);
            return;
        }

        if (!video) {
            NSLog(@"[PolyvPlugin] ERROR: Video not found for vid: %@", vid);
            result([FlutterError errorWithCode:@"VIDEO_NOT_FOUND"
                                       message:@"Video not found"
                                       details:nil]);
            return;
        }

        // 添加下载任务（使用当前播放的清晰度）
        @try {
            PLVDownloadInfo *downloadInfo = [[PLVDownloadMediaManager sharedManager] addVideoTask:video quality:downloadQuality];

            if (!downloadInfo) {
                NSLog(@"[PolyvPlugin] ERROR: Failed to create download task");
                result([FlutterError errorWithCode:@"SDK_ERROR"
                                           message:@"Failed to create download task"
                                           details:nil]);
                return;
            }

            NSLog(@"[PolyvPlugin] Download task created successfully for vid: %@, quality: %ld", vid, (long)downloadQuality);

            // 如果 autoStart 为 NO，需要手动启动下载
            if (![PLVDownloadMediaManager sharedManager].autoStart) {
                [[PLVDownloadMediaManager sharedManager] startDownload];
            }

            result(nil);
        } @catch (NSException *exception) {
            NSLog(@"[PolyvPlugin] ERROR: Exception while creating download task - %@", exception.reason);
            result([FlutterError errorWithCode:@"SDK_ERROR"
                                       message:exception.reason ?: @"Failed to create download task"
                                       details:nil]);
        }
    }];
}

#pragma mark - Helper Methods

- (void)clearPlayer {
    // 清理播放器资源，但不置nil（使用lazy getter模式）
    if (_player) {
        [self.playerSession clearPlayer];
        _player = nil;
    }

    UIView *containerView = self.videoViewController.containerView;
    if (containerView) {
        containerView.backgroundColor = [UIColor blackColor];
        containerView.layer.contents = nil;

        NSArray<UIView *> *subviews = [containerView.subviews copy];
        for (UIView *subview in subviews) {
            [subview removeFromSuperview];
        }

        NSArray<CALayer *> *sublayers = [containerView.layer.sublayers copy];
        Class avPlayerLayerClass = NSClassFromString(@"AVPlayerLayer");
        for (CALayer *layer in sublayers) {
            BOOL isAVPlayerLayer = (avPlayerLayerClass && [layer isKindOfClass:avPlayerLayerClass]);
            BOOL looksLikePlayerLayer = [NSStringFromClass([layer class]) containsString:@"Player"];
            if (isAVPlayerLayer || looksLikePlayerLayer) {
                [layer removeFromSuperlayer];
            }
        }
    }
    self.currentVid = nil;
    self.currentVideo = nil;

    // 保存当前清晰度到 UserDefaults（持久化），这样下次进入页面时可以恢复
    // 注意：currentQualityIndex 是 SDK 层的索引（0=自动, 1=流畅, 2=高清, 3=超清）
    if (self.currentQualityIndex > 0) {
        [[NSUserDefaults standardUserDefaults] setInteger:self.currentQualityIndex forKey:@"PLVLastSelectedQuality"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSLog(@"[PolyvPlugin] Saved quality index: %ld", (long)self.currentQualityIndex);
    }

    self.currentQualityIndex = 0;

    [self.subtitleCoordinator resetAll];
    self.lastOrientation = 0;

    self.videoViewController = nil;
}

- (void)sendStateChangeEvent:(NSString *)state {
    NSLog(@"[PolyvPlugin] sendStateChangeEvent: %@", state);
    [self.playerSession sendStateChangeEvent:state];
}

- (void)sendProgressEvent {
    [self.playerSession sendProgressEvent];
}

- (void)sendErrorEventWithCode:(NSString *)code message:(NSString *)message {
    [self.playerSession sendErrorEventWithCode:code message:message];
}

/// 发送字幕变化事件
///
/// 事件格式：
/// {
///   "type": "subtitleChanged",
///   "data": {
///     "subtitles": [ {
///       "trackKey": String,
///       "language": String,
///       "label": String,
///       "url"?: String,
///       "isBilingual": Bool,
///       "isDefault": Bool
///     }, ... ],
///     "currentIndex": Int, // -1 表示关闭
///     "enabled": Bool,
///     "trackKey"?: String
///   }
/// }
- (void)sendSubtitleChangedEventWithEnabled:(BOOL)enabled trackKey:(NSString *)trackKey {
    if (self.videoViewController && self.videoViewController.containerView) {
        [self.subtitleCoordinator updateContainerView:self.videoViewController.containerView];
    }
    [self.subtitleCoordinator sendSubtitleChangedEventWithVideo:self.currentVideo enabled:enabled trackKey:trackKey];
}

- (void)PLVVodMediaPlayer:(PLVVodMediaPlayer *)vodMediaPlayer playedProgress:(CGFloat)playedProgress playedTimeString:(NSString *)playedTimeString durationTimeString:(NSString *)durationTimeString {
    [self sendProgressEvent];

    static NSTimeInterval lastLogTime = 0;
    NSTimeInterval currentTime = vodMediaPlayer.currentPlaybackTime;
    if (currentTime - lastLogTime >= 1.0) {
        NSLog(@"[PolyvPlugin] playedProgress: %.2f", playedProgress);
        lastLogTime = currentTime;
    }

    [self bringSubtitleLabelsToFront];
    [self.subtitleCoordinator showSubtitlesWithPlaytime:vodMediaPlayer.currentPlaybackTime];
}

- (void)PLVVodMediaPlayer:(PLVVodMediaPlayer *)vodMediaPlayer loadMainPlayerFailureWithError:(NSError * _Nullable)error {
    NSString *message = error ? (error.localizedDescription ?: @"Unknown error") : @"Unknown error";
    [self sendErrorEventWithCode:kErrorCodeNetworkError message:message];
    [self sendStateChangeEvent:kStateError];
}

- (void)plvMediaPlayerCore:(PLVMediaPlayerCore *)player playerIsPreparedToPlay:(BOOL)prepared {
    if (prepared) {
        [self sendStateChangeEvent:kStatePrepared];

        // 发送字幕列表事件（与 Android 保持一致，在 onPrepared 时发送）
        // 默认开启字幕，让 Flutter 层根据默认算法选择字幕
        [self sendSubtitleChangedEventWithEnabled:YES trackKey:nil];

        // 重播场景：如果 shouldSeekToStartOnPrepared 为 YES，seek 到 0
        // 这确保重播时从头播放，而不是从 SDK 恢复的上次位置
        if (self.shouldSeekToStartOnPrepared) {
            NSLog(@"[PolyvPlugin] shouldSeekToStartOnPrepared=YES, seeking to 0");
            [self.player seekToTime:0.0];
            self.shouldSeekToStartOnPrepared = NO;
        }
    }
}

- (void)plvMediaPlayerCore:(PLVMediaPlayerCore *)player playerLoadStateDidChange:(PLVPlayerLoadState)loadState {
    if (loadState & PLVPlayerLoadStateStalled) {
        [self sendStateChangeEvent:kStateBuffering];
        return;
    }

    PLVPlaybackState playbackState = player.playbackState;
    if (playbackState == PLVPlaybackStatePlaying) {
        [self sendStateChangeEvent:kStatePlaying];
    } else if (playbackState == PLVPlaybackStatePaused) {
        [self sendStateChangeEvent:kStatePaused];
    }
}

- (void)plvMediaPlayerCore:(PLVMediaPlayerCore *)player playerPlaybackStateDidChange:(PLVPlaybackState)playbackState {
    switch (playbackState) {
        case PLVPlaybackStatePlaying:
            [self sendStateChangeEvent:kStatePlaying];
            break;
        case PLVPlaybackStatePaused:
            [self sendStateChangeEvent:kStatePaused];
            break;
        case PLVPlaybackStateStopped:
            [self sendStateChangeEvent:kStateIdle];
            break;
        default:
            break;
    }
}

- (void)plvMediaPlayerCore:(PLVMediaPlayerCore *)player playerPlaybackDidFinish:(PLVPlayerFinishReason)finishReson {
    if (finishReson == PLVPlayerFinishReasonPlaybackEnded) {
        [self sendStateChangeEvent:kStateCompleted];
        [self.playerSession sendCompletedEvent];
    } else if (finishReson == PLVPlayerFinishReasonPlaybackError) {
        [self sendStateChangeEvent:kStateError];
    } else {
        [self sendStateChangeEvent:kStateIdle];
    }
}

- (void)sendQualityDataForVideo:(PLVVodMediaVideo *)video {
    [self sendQualityDataForVideo:video updateCurrentIndex:-1];
}

- (void)sendQualityDataForVideo:(PLVVodMediaVideo *)video updateCurrentIndex:(NSInteger)updateIndex {
    if (!video) {
        return;
    }

    NSMutableArray *qualitiesList = [NSMutableArray array];
    NSInteger currentIndex = self.currentQualityIndex;

    if (updateIndex >= 0) {
        currentIndex = updateIndex;
        self.currentQualityIndex = updateIndex;
    }

    // 定义所有可能的清晰度（按顺序：流畅、高清、超清）
    // 注意：iOS SDK 的清晰度枚举: 0=自动, 1=流畅, 2=高清, 3=超清
    NSArray<NSDictionary *> *qualityDefinitions = @[
        @{@"enum": @(PLVVodMediaQualityStandard), @"description": @"流畅", @"value": @"480p"},
        @{@"enum": @(PLVVodMediaQualityHigh), @"description": @"高清", @"value": @"720p"},
        @{@"enum": @(PLVVodMediaQualityUltra), @"description": @"超清", @"value": @"1080p"},
    ];

    // 根据 video.qualityCount 动态决定显示多少个清晰度选项
    NSInteger availableQualityCount = video.qualityCount;
    if (availableQualityCount <= 0 || availableQualityCount > 3) {
        availableQualityCount = 3;
    }

    // 只显示前 availableQualityCount 个清晰度选项
    for (NSInteger i = 0; i < availableQualityCount; i++) {
        NSDictionary *def = qualityDefinitions[i];
        [qualitiesList addObject:@{
            @"description": def[@"description"],
            @"value": def[@"value"],
            @"isAvailable": @YES,
        }];
    }

    // 调整 currentIndex 以匹配新的列表
    // 原来的 currentIndex 是 SDK 层的索引（1=流畅, 2=高清, 3=超清）
    // 需要确保它在当前视频支持的范围内

    // 先将 SDK 层索引转换为 UI 层索引
    NSInteger uiCurrentIndex = 0;

    if (currentIndex > 0 && currentIndex <= qualityDefinitions.count) {
        uiCurrentIndex = currentIndex - 1;
    }

    // 确保 uiCurrentIndex 在有效范围内
    if (uiCurrentIndex >= availableQualityCount) {
        uiCurrentIndex = availableQualityCount - 1;
    }
    if (uiCurrentIndex < 0) {
        uiCurrentIndex = 0;
    }

    // 更新 currentQualityIndex 以匹配实际使用的清晰度
    NSInteger adjustedSdkIndex = uiCurrentIndex + 1;
    if (adjustedSdkIndex != currentIndex) {
        self.currentQualityIndex = adjustedSdkIndex;
    }

    [self.eventEmitter sendPlayerEvent:@{
        @"type": @"qualityChanged",
        @"data": @{
            @"qualities": qualitiesList,
            @"currentIndex": @(uiCurrentIndex)
        }
    }];
}

- (void)setupSubtitleModuleIfNeededForVideo:(PLVVodMediaVideo *)video {
    if (!self.videoViewController || !self.videoViewController.containerView) {
        return;
    }

    if (self.lastOrientation == 0) {
        self.lastOrientation = [UIDevice currentDevice].orientation;
        NSLog(@"[PolyvPlugin] Initial orientation: %ld", (long)self.lastOrientation);
    }
    [self.subtitleCoordinator updateContainerView:self.videoViewController.containerView];
    [self.subtitleCoordinator setupIfNeededForVideo:video];
}

/// 确保字幕Label始终在最上层（播放器视图可能覆盖了字幕）
- (void)bringSubtitleLabelsToFront {
    [self.subtitleCoordinator bringSubtitleLabelsToFront];
}

/// 更新字幕Label的frame以适应containerView的当前大小
- (void)updateSubtitleLabelFrames {
    [self.subtitleCoordinator updateSubtitleLabelFrames];
}

#pragma mark - Story 9.8: Download Status Monitoring

/// 启动下载状态监控
- (void)startDownloadStatusMonitoring {
    if (!self.downloadMonitor) {
        self.downloadMonitor = [[PLVFlutterDownloadMonitor alloc] initWithEventEmitter:self.eventEmitter];
    }

    [self.downloadMonitor startMonitoring];
}

/// 停止下载状态监控
- (void)stopDownloadStatusMonitoring {
    if (self.downloadMonitor) {
        [self.downloadMonitor stopMonitoring];
    }
}

@end
