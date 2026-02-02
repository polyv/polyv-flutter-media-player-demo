#import "PolyvMediaPlayerPlugin.h"
#import "PLVVideoViewFactory.h"
#import "PLVMediaPlayerSubtitleModule.h"
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
static NSString *const kDownloadEventTaskProgress = @"taskProgress";
static NSString *const kDownloadEventTaskCompleted = @"taskCompleted";
static NSString *const kDownloadEventTaskFailed = @"taskFailed";
static NSString *const kDownloadEventTaskRemoved = @"taskRemoved";
static NSString *const kDownloadEventTaskPaused = @"taskPaused";
static NSString *const kDownloadEventTaskResumed = @"taskResumed";

// 静态实例，用于视频视图关联
static PolyvMediaPlayerPlugin *_sharedInstance = nil;

@interface EventStreamHandler : NSObject <FlutterStreamHandler>
@property (nonatomic, copy) FlutterEventSink eventSink;
@end

@implementation EventStreamHandler
- (FlutterError *)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)events {
    NSLog(@"[PolyvPlugin] EventStreamHandler onListen called");
    self.eventSink = events;
    return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
    NSLog(@"[PolyvPlugin] EventStreamHandler onCancel called");
    self.eventSink = nil;
    return nil;
}

- (void)sendEvent:(NSDictionary<NSString *, id> *)event {
    NSLog(@"[PolyvPlugin] EventStreamHandler sendEvent called, sink=%p, event=%@", self.eventSink, event);
    if (self.eventSink) {
        self.eventSink(event);
        NSLog(@"[PolyvPlugin] Event sent successfully");
    } else {
        NSLog(@"[PolyvPlugin] WARNING: eventSink is nil, event not sent!");
    }
}
@end

@interface PolyvMediaPlayerPlugin () <FlutterPlugin, PLVMediaPlayerCoreDelegate, PLVVodMediaPlayerDelegate>
@property (nonatomic, strong) FlutterMethodChannel *methodChannel;
@property (nonatomic, strong) FlutterEventChannel *eventChannel;
@property (nonatomic, strong) EventStreamHandler *eventStreamHandler;
@property (nonatomic, strong) FlutterEventChannel *downloadEventChannel;
@property (nonatomic, strong) EventStreamHandler *downloadEventStreamHandler;
@property (nonatomic, strong) PLVVodMediaPlayer *player;
@property (nonatomic, copy) NSString *currentVid;
@property (nonatomic, strong) PLVVideoViewController *videoViewController; // 改为 strong，防止被提前释放
@property (nonatomic, assign) NSInteger currentQualityIndex; // 当前清晰度索引
@property (nonatomic, strong) PLVVodMediaVideo *currentVideo; // 当前视频对象，用于获取清晰度信息
@property (nonatomic, assign) NSInteger qualitySwitchOperationId;
@property (nonatomic, assign) BOOL shouldSeekToStartOnPrepared;
@property (nonatomic, strong) PLVMediaPlayerSubtitleModule *subtitleModule;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *subtitleTopLabel;
@property (nonatomic, strong) UILabel *subtitleLabel2;
@property (nonatomic, strong) UILabel *subtitleTopLabel2;
// 记录当前设备方向，避免重复处理
@property (nonatomic, assign) UIDeviceOrientation lastOrientation;
// 保存用户选择的字幕配置，用于横竖屏切换后恢复
@property (nonatomic, copy) NSString *currentSubtitleTrackKey;
@property (nonatomic, assign) BOOL currentSubtitleEnabled;
@property (nonatomic, assign) BOOL subtitleStateInitialized;

// 账号配置相关属性
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *readToken;
@property (nonatomic, copy) NSString *writeToken;
@property (nonatomic, copy) NSString *secretKey;
@property (nonatomic, copy) NSString *env;          // 环境标识（预留）
@property (nonatomic, copy) NSString *businessLine; // 业务线标识（预留）

// Story 9.8: 下载状态跟踪
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *downloadPreviousStates; // 记录下载任务的上一次状态，用于检测状态变化
@property (nonatomic, strong) NSTimer *downloadStatusCheckTimer; // 定时检查下载状态变化的定时器
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
    [registrar addMethodCallDelegate:instance channel:methodChannel];

    FlutterEventChannel *eventChannel = [FlutterEventChannel
        eventChannelWithName:kEventChannelName
        binaryMessenger:[registrar messenger]];
    EventStreamHandler *eventHandler = [[EventStreamHandler alloc] init];
    instance.eventStreamHandler = eventHandler;
    [eventChannel setStreamHandler:eventHandler];
    instance.eventChannel = eventChannel;

    FlutterEventChannel *downloadEventChannel = [FlutterEventChannel
        eventChannelWithName:kDownloadEventChannelName
        binaryMessenger:[registrar messenger]];
    EventStreamHandler *downloadEventHandler = [[EventStreamHandler alloc] init];
    instance.downloadEventStreamHandler = downloadEventHandler;
    [downloadEventChannel setStreamHandler:downloadEventHandler];
    instance.downloadEventChannel = downloadEventChannel;

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

    // Story 9.8: 初始化下载状态跟踪并启动定时器
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

    // 如果播放器已存在，设置显示视图
    if (self.player) {
        NSLog(@"[PolyvPlugin] Player exists, setting up display superview");
        [self.player setupDisplaySuperview:videoViewController.containerView];
        NSLog(@"[PolyvPlugin] Display superview set: %@", self.player.displaySuperview);
    } else {
        NSLog(@"[PolyvPlugin] WARNING: videoViewController is still nil, will set up later");
    }
    
    // 如果是新的 videoViewController，需要重新设置字幕 Label
    // 因为旧的字幕 Label 添加在旧的 container 上，横竖屏切换后会失效
    if (isNewViewController && self.currentVideo) {
        NSLog(@"[PolyvPlugin] New videoViewController detected, resetting subtitle labels");
        // 清空旧的字幕 Label 引用，让 setupSubtitleModuleIfNeededForVideo 重新创建
        self.subtitleLabel = nil;
        self.subtitleTopLabel = nil;
        self.subtitleLabel2 = nil;
        self.subtitleTopLabel2 = nil;
        // 同时清空旧的 subtitleModule，避免它持有旧的 label 引用
        self.subtitleModule = nil;
        // 重新设置字幕
        [self setupSubtitleModuleIfNeededForVideo:self.currentVideo];
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
            // 移除旧的字幕 label
            [self.subtitleLabel removeFromSuperview];
            [self.subtitleTopLabel removeFromSuperview];
            [self.subtitleLabel2 removeFromSuperview];
            [self.subtitleTopLabel2 removeFromSuperview];

            // 清空引用
            self.subtitleLabel = nil;
            self.subtitleTopLabel = nil;
            self.subtitleLabel2 = nil;
            self.subtitleTopLabel2 = nil;
            self.subtitleModule = nil;

            // 重新设置字幕
            [self setupSubtitleModuleIfNeededForVideo:self.currentVideo];
        });
    }
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary *args = call.arguments;

    if ([call.method isEqualToString:@"initialize"]) {
        [self handleInitialize:args result:result];
    } else if ([call.method isEqualToString:@"loadVideo"]) {
        [self handleLoadVideo:args result:result];
    } else if ([call.method isEqualToString:@"play"]) {
        [self handlePlay:result];
    } else if ([call.method isEqualToString:@"pause"]) {
        [self handlePause:result];
    } else if ([call.method isEqualToString:@"stop"]) {
        [self handleStop:result];
    } else if ([call.method isEqualToString:@"seekTo"]) {
        [self handleSeekTo:args result:result];
    } else if ([call.method isEqualToString:@"setPlaybackSpeed"]) {
        [self handleSetPlaybackSpeed:args result:result];
    } else if ([call.method isEqualToString:@"setQuality"]) {
        [self handleSetQuality:args result:result];
    } else if ([call.method isEqualToString:@"setSubtitle"]) {
        [self handleSetSubtitle:args result:result];
    } else if ([call.method isEqualToString:@"getQualities"]) {
        [self handleGetQualities:result];
    } else if ([call.method isEqualToString:@"getSubtitles"]) {
        [self handleGetSubtitles:result];
    } else if ([call.method isEqualToString:@"disposePlayer"]) {
        // 释放播放器资源（供 Flutter 层在页面销毁时调用）
        [self clearPlayer];
        result(nil);
    } else if ([call.method isEqualToString:@"pauseDownload"]) {
        // Story 9.7: 暂停下载任务
        [self handlePauseDownload:call.arguments result:result];
    } else if ([call.method isEqualToString:@"resumeDownload"]) {
        // Story 9.7: 恢复下载任务
        [self handleResumeDownload:call.arguments result:result];
    } else if ([call.method isEqualToString:@"retryDownload"]) {
        // Story 9.4: 重试失败的下载任务
        [self handleRetryDownload:call.arguments result:result];
    } else if ([call.method isEqualToString:@"deleteDownload"]) {
        // Story 9.5: 删除下载任务
        [self handleDeleteDownload:call.arguments result:result];
    } else if ([call.method isEqualToString:@"getDownloadList"]) {
        // Story 9.8: 获取下载任务列表（权威同步）
        [self handleGetDownloadList:result];
    } else if ([call.method isEqualToString:@"startDownload"]) {
        // Story 9.9: 创建下载任务（添加视频到下载队列）
        [self handleStartDownload:call.arguments result:result];
    } else {
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
    if (!_player) {
        NSLog(@"[PolyvPlugin] ========== Creating player in lazy getter ==========");
        _player = [[PLVVodMediaPlayer alloc] init];
        _player.coreDelegate = self;
        _player.delegateVodMediaPlayer = self;
        _player.autoPlay = YES; // 自动播放，与原生 demo 一致
        _player.videoToolBox = NO;
        _player.rememberLastPosition = NO;
        _player.seekType = PLVVodMediaPlaySeekTypePrecise;
        NSLog(@"[PolyvPlugin] ========== Player created, delegates set ==========");
    }
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

    self.currentSubtitleTrackKey = nil;
    self.currentSubtitleEnabled = NO;
    self.subtitleStateInitialized = NO;

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
    // 先请求视频，在回调中设置播放器
    NSLog(@"[PolyvPlugin] Requesting video with VID...");
    [PLVVodMediaVideo requestVideoPriorityCacheWithVid:vid completion:^(PLVVodMediaVideo *video, NSError *error) {
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

        // 保存视频对象，用于清晰度切换
        self.currentVideo = video;

        // 从 UserDefaults 恢复用户上次选择的清晰度（如果有）
        NSInteger savedQualityIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"PLVLastSelectedQuality"];
        if (savedQualityIndex > 0) {
            self.currentQualityIndex = savedQualityIndex;
            NSLog(@"[PolyvPlugin] Restored quality index from UserDefaults: %ld", (long)savedQualityIndex);
        } else {
            // 没有保存的清晰度，使用默认的高清（索引2）
            self.currentQualityIndex = 2;
        }

        // 发送清晰度数据
        [self sendQualityDataForVideo:video];

        // 在主线程上设置播放器（确保线程安全）
        dispatch_async(dispatch_get_main_queue(), ^{
            // 关联视频视图
            if (self.videoViewController) {
                NSLog(@"[PolyvPlugin] Setting up display superview BEFORE setVideo");
                [self.player setupDisplaySuperview:self.videoViewController.containerView];
                NSLog(@"[PolyvPlugin] Display superview set: %@", self.player.displaySuperview);
            } else {
                NSLog(@"[PolyvPlugin] WARNING: videoViewController is still nil, will set up later");
            }

            // 设置视频（不自动播放，等待 Dart 层调用 play）
            [self.player setVideo:video];
            NSLog(@"[PolyvPlugin] Video set, playbackState: %ld", (long)self.player.playbackState);

            // 显式重置播放位置到开头，防止 SDK 自动恢复上次播放位置
            [self.player seekToTime:0.0];
            NSLog(@"[PolyvPlugin] Position reset to 0");

            // 初始化字幕模块和字幕视图
            [self setupSubtitleModuleIfNeededForVideo:video];
        });

        result(nil);
    }];
}

/// 离线播放视频
- (void)loadVideoOffline:(NSString *)vid result:(FlutterResult)result {
    // 获取下载目录
    NSString *downloadDir = [[PLVDownloadMediaManager sharedManager] downloadDir];
    NSLog(@"[PolyvPlugin] Download directory: %@", downloadDir);

    if (!downloadDir || downloadDir.length == 0) {
        NSLog(@"[PolyvPlugin] ERROR: Download directory not found");
        [self sendErrorEventWithCode:@"OFFLINE_ERROR" message:@"Download directory not found"];
        [self sendStateChangeEvent:kStateError];
        result([FlutterError errorWithCode:@"OFFLINE_ERROR"
                                    message:@"Download directory not found"
                                    details:nil]);
        return;
    }

    // 在主线程上设置播放器
    dispatch_async(dispatch_get_main_queue(), ^{
        // 关联视频视图
        if (self.videoViewController) {
            NSLog(@"[PolyvPlugin] Setting up display superview for offline playback");
            [self.player setupDisplaySuperview:self.videoViewController.containerView];
        }

        // 创建本地视频对象
        PLVLocalVideo *localVideo = [PLVLocalVideo localVideoWithVid:vid dir:downloadDir];
        if (!localVideo) {
            NSLog(@"[PolyvPlugin] ERROR: Failed to create local video for vid: %@", vid);
            [self sendErrorEventWithCode:@"OFFLINE_ERROR" message:@"Local video not found"];
            [self sendStateChangeEvent:kStateError];
            result([FlutterError errorWithCode:@"OFFLINE_ERROR"
                                        message:@"Local video not found, please download first"
                                        details:nil]);
            return;
        }

        // 设置本地优先播放
        [self.player setLocalPrior:YES];

        // 加载本地视频（使用 setVideo 方法，PLVLocalVideo 继承自 PLVVodMediaVideo）
        [self.player setVideo:localVideo];
        NSLog(@"[PolyvPlugin] Local video loaded, playbackState: %ld", (long)self.player.playbackState);

        // 显式重置播放位置到开头
        [self.player seekToTime:0.0];
        NSLog(@"[PolyvPlugin] Position reset to 0");

        // 尝试获取视频信息用于字幕支持
        // 先请求视频信息（不消耗流量，只获取元数据）
        [PLVVodMediaVideo requestVideoPriorityCacheWithVid:vid completion:^(PLVVodMediaVideo *video, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (video && !error) {
                    // 保存视频对象用于清晰度和字幕
                    self.currentVideo = video;

                    // 从 UserDefaults 恢复用户上次选择的清晰度（如果有）
                    NSInteger savedQualityIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"PLVLastSelectedQuality"];
                    if (savedQualityIndex > 0) {
                        self.currentQualityIndex = savedQualityIndex;
                        NSLog(@"[PolyvPlugin] Restored quality index from UserDefaults (offline): %ld", (long)savedQualityIndex);
                    } else {
                        // 没有保存的清晰度，使用默认的高清（索引2）
                        self.currentQualityIndex = 2;
                    }

                    // 发送清晰度数据
                    [self sendQualityDataForVideo:video];

                    // 初始化字幕模块
                    [self setupSubtitleModuleIfNeededForVideo:video];
                } else {
                    NSLog(@"[PolyvPlugin] Warning: Could not fetch video metadata for offline playback");
                    // 即使获取元数据失败，播放也应该继续
                }
                result(nil);
            });
        }];
    });
}

- (void)handlePlay:(FlutterResult)result {
    NSLog(@"[PolyvPlugin] ========== handlePlay called ==========");
    NSLog(@"[PolyvPlugin] player exists: %@", self.player ? @"YES" : @"NO");
    if (!self.player) {
        NSLog(@"[PolyvPlugin] ERROR: Player is nil!");
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
        [self.player play];
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
    [self.player pause];
    result(nil);
}

- (void)handleStop:(FlutterResult)result {
    // stop 不应该销毁播放器，只停止播放并重置进度
    PLVVodMediaPlayer *plvPlayer = _player;
    if (plvPlayer) {
        [plvPlayer pause];
        // 重置播放进度到开头
        [plvPlayer seekToTime:0];
    }
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
    [self.player seekToTime:time];
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

    @try {
        [self.player switchSpeedRate:speed];
        NSLog(@"[PolyvPlugin] Playback speed set to: %.2f", speed);

        // 发送倍速变化事件回 Flutter，确保 UI 同步
        [self.eventStreamHandler sendEvent:@{
            @"type": @"playbackSpeedChanged",
            @"data": @{
                @"speed": @(speed)
            }
        }];

        result(nil);
    } @catch (NSException *exception) {
        NSLog(@"[PolyvPlugin] ERROR setting playback speed: %@", exception.reason);
        result([FlutterError errorWithCode:kErrorCodeNetworkError
                                    message:exception.reason
                                    details:nil]);
    }
}

- (void)handleSetQuality:(NSDictionary *)args result:(FlutterResult)result {
    NSLog(@"[PolyvPlugin] ========== handleSetQuality called ==========");
    if (!self.player) {
        result([FlutterError errorWithCode:kErrorCodeNotInitialized
                                    message:@"Player not initialized"
                                    details:nil]);
        return;
    }

    NSInteger index = [args[@"index"] integerValue];
    NSLog(@"[PolyvPlugin] Switching to quality index (UI layer): %ld", (long)index);

    // UI 层的索引需要 +1 来匹配 SDK 的枚举值（因为去掉了"自动"选项）
    // iOS SDK 的清晰度枚举: 0=自动, 1=流畅, 2=高清, 3=超清
    // UI 层显示: 流畅, 高清, 超清（对应 SDK 的 1, 2, 3）
    NSInteger sdkIndex = index + 1;

    // 不再检查 qualityCount，因为某些视频的 qualityCount 值可能不准确
    // 直接让 SDK 处理清晰度切换，如果清晰度不可用 SDK 会自动处理

    // 记录当前播放位置和状态，用于切换后恢复
    // 为了避免切换清晰度期间继续播放一小段再 seek 回来导致的音频重复感，
    // 若当前正在播放，则先暂停，再读取当前位置。
    BOOL wasPlaying = (self.player.playbackState == PLVPlaybackStatePlaying);
    if (wasPlaying) {
        [self.player pause];
    }
    NSTimeInterval currentPosition = self.player.currentPlaybackTime;
    NSLog(@"[PolyvPlugin] Current position: %.2f, was playing: %d", currentPosition, wasPlaying);

    NSInteger operationId = (self.qualitySwitchOperationId += 1);
    NSString *vidAtStart = [self.currentVid copy];

    PLVVodMediaQuality quality = (PLVVodMediaQuality)sdkIndex;
    NSLog(@"[PolyvPlugin] Calling setPlayQuality: %ld", (long)quality);

    [self.player setPlayQuality:quality];
    // 保存 SDK 层的索引
    self.currentQualityIndex = sdkIndex;

    // 持久化保存用户选择的清晰度，以便下次进入页面时恢复
    [[NSUserDefaults standardUserDefaults] setInteger:sdkIndex forKey:@"PLVLastSelectedQuality"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"[PolyvPlugin] Saved quality index: %ld", (long)sdkIndex);

    // 发送更新后的清晰度数据（传入 UI 层的索引）
    [self sendQualityDataForVideo:self.currentVideo updateCurrentIndex:sdkIndex];

    // 恢复播放位置和状态
    // 需要延迟一点，让播放器完成清晰度切换
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (operationId != self.qualitySwitchOperationId || ![self.currentVid isEqualToString:vidAtStart]) {
            return;
        }
        if (currentPosition > 0) {
            NSLog(@"[PolyvPlugin] Restoring position to: %.2f", currentPosition);
            [self.player seekToTime:currentPosition];
        }
        if (wasPlaying) {
            NSLog(@"[PolyvPlugin] Resuming playback");
            [self.player play];
        }

        // 显式回传一次播放状态，避免某些情况下 SDK 未触发 playbackState 回调，导致 Flutter UI 图标与实际播放状态不一致
        [self sendStateChangeEvent:(wasPlaying ? kStatePlaying : kStatePaused)];
    });

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

    NSMutableArray<NSDictionary *> *taskList = [NSMutableArray array];

    // 获取所有下载任务（SDK 没有提供统一的 requestDownloadInfoList 方法）
    // 需要分别获取已完成和未完成的任务
    NSArray<PLVDownloadInfo *> *unfinishedDownloads = [[PLVDownloadMediaManager sharedManager] getUnfinishedDownloadList];
    NSArray<PLVDownloadInfo *> *finishedDownloads = [[PLVDownloadMediaManager sharedManager] getFinishedDownloadList];

    // 合并两个数组
    NSMutableArray<PLVDownloadInfo *> *allDownloads = [NSMutableArray arrayWithArray:unfinishedDownloads];
    [allDownloads addObjectsFromArray:finishedDownloads];

    NSLog(@"[PolyvPlugin] Total tasks from SDK: %lu (unfinished: %lu, finished: %lu)",
          (unsigned long)allDownloads.count, (unsigned long)unfinishedDownloads.count, (unsigned long)finishedDownloads.count);

    // 用于检测重复 vid 的集合
    NSMutableSet<NSString *> *seenVids = [NSMutableSet set];

    for (PLVDownloadInfo *info in allDownloads) {
        NSDictionary *taskDict = [self convertDownloadInfoToDict:info];
        if (taskDict) {
            NSString *vid = taskDict[@"vid"];

            // 检测重复 vid
            if ([seenVids containsObject:vid]) {
                NSLog(@"[PolyvPlugin] WARNING: Duplicate vid found in download list: vid=%@", vid);
            } else {
                [seenVids addObject:vid];
            }

            // 只过滤掉没有 vid 的无效任务
            // 之前过滤 waiting 状态 + totalBytes=0 的任务导致新创建的任务被过滤掉
            if (vid.length > 0) {
                [taskList addObject:taskDict];
                NSLog(@"[PolyvPlugin] Adding task to list: vid=%@, status=%@, downloadedBytes=%lld",
                      vid, taskDict[@"status"], [taskDict[@"downloadedBytes"] longLongValue]);
            } else {
                NSLog(@"[PolyvPlugin] Filtering out task without vid");
            }
        }
    }

    NSLog(@"[PolyvPlugin] Returning %lu tasks (filtered from %lu total)", (unsigned long)taskList.count, (unsigned long)allDownloads.count);
    result(taskList);
}

/// 将 PLVDownloadInfo 转换为 Flutter 可用的字典格式
- (NSDictionary *)convertDownloadInfoToDict:(PLVDownloadInfo *)info {
    if (!info) return nil;
    
    NSString *vid = info.vid ?: @"";
    NSString *taskId = vid; // 使用 vid 作为任务 ID
    NSString *title = info.title ?: @"未知视频";
    NSString *thumbnail = info.snapshot ?: @"";
    
    // 文件大小信息
    long long totalBytes = info.filesize;
    // SDK 没有 downloadedBytes 属性，使用 progress * filesize 计算
    long long downloadedBytes = (long long)(info.progress * info.filesize);
    
    // 下载速度（SDK 可能不直接提供，设为 0）
    int bytesPerSecond = 0;
    
    // 状态转换
    NSString *status = [self convertDownloadStateToString:info.state];
    
    // 错误信息
    NSString *errorMessage = nil;
    if (info.state == PLVVodDownloadStateFailed) {
        errorMessage = @"下载失败";
    }
    
    // 时间信息
    NSString *createdAt = [[self iso8601Formatter] stringFromDate:[NSDate date]];
    NSString *completedAt = nil;
    if (info.state == PLVVodDownloadStateSuccess) {
        completedAt = [[self iso8601Formatter] stringFromDate:[NSDate date]];
    }
    
    NSMutableDictionary *dict = [@{
        @"id": taskId,
        @"vid": vid,
        @"title": title,
        @"totalBytes": @(totalBytes),
        @"downloadedBytes": @(downloadedBytes),
        @"bytesPerSecond": @(bytesPerSecond),
        @"status": status,
        @"createdAt": createdAt,
    } mutableCopy];
    
    if (thumbnail.length > 0) {
        dict[@"thumbnail"] = thumbnail;
    }
    if (errorMessage) {
        dict[@"errorMessage"] = errorMessage;
    }
    if (completedAt) {
        dict[@"completedAt"] = completedAt;
    }
    
    return dict;
}

/// 将 SDK 下载状态转换为 Flutter 状态字符串
- (NSString *)convertDownloadStateToString:(PLVVodDownloadState)state {
    switch (state) {
        case PLVVodDownloadStatePreparing:
            return @"preparing";
        case PLVVodDownloadStateReady:
            return @"waiting";
        case PLVVodDownloadStateRunning:
            return @"downloading";
        case PLVVodDownloadStateStopping:
        case PLVVodDownloadStateStopped:
            return @"paused";
        case PLVVodDownloadStateSuccess:
            return @"completed";
        case PLVVodDownloadStateFailed:
            return @"error";
        default:
            return @"waiting";
    }
}

/// ISO8601 日期格式化器
- (NSDateFormatter *)iso8601Formatter {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    });
    return formatter;
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
    [self.downloadEventStreamHandler sendEvent:@{
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
        [_player clearPlayer];
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

    self.subtitleModule = nil;

    [self.subtitleLabel removeFromSuperview];
    [self.subtitleTopLabel removeFromSuperview];
    [self.subtitleLabel2 removeFromSuperview];
    [self.subtitleTopLabel2 removeFromSuperview];
    self.subtitleLabel = nil;
    self.subtitleTopLabel = nil;
    self.subtitleLabel2 = nil;
    self.subtitleTopLabel2 = nil;

    self.currentSubtitleTrackKey = nil;
    self.currentSubtitleEnabled = NO;
    self.subtitleStateInitialized = NO;

    self.videoViewController = nil;
}

- (void)sendStateChangeEvent:(NSString *)state {
    NSLog(@"[PolyvPlugin] sendStateChangeEvent: %@", state);
    [self.eventStreamHandler sendEvent:@{
        @"type": @"stateChanged",
        @"data": @{ @"state": state }
    }];
}

- (void)sendProgressEvent {
    if (!self.player) return;

    NSInteger position = (NSInteger)(self.player.currentPlaybackTime * 1000);
    NSInteger duration = (NSInteger)(self.player.duration * 1000);
    NSInteger buffered = (NSInteger)(self.player.playableDuration * 1000);

    [self.eventStreamHandler sendEvent:@{
        @"type": @"progress",
        @"data": @{
            @"position": @(position),
            @"duration": @(duration),
            @"bufferedPosition": @(buffered)
        }
    }];
}

- (void)sendErrorEventWithCode:(NSString *)code message:(NSString *)message {
    [self.eventStreamHandler sendEvent:@{
        @"type": @"error",
        @"data": @{
            @"code": code,
            @"message": message
        }
    }];
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
    NSMutableArray *subtitlesArray = [NSMutableArray array];
    NSInteger currentIndex = -1;

    if (self.currentVideo) {
        // 注意：移除了"双语"选项的自动添加逻辑，与 Android 保持一致
        // 如果需要支持双语字幕，可以在这里恢复 match_srt 的处理

        // 单字幕轨道来自 video.srts
        @try {
            NSArray *srts = [self.currentVideo valueForKey:@"srts"];
            if ([srts isKindOfClass:[NSArray class]]) {
                for (id item in srts) {
                    NSString *title = nil;
                    NSString *url = nil;
                    @try {
                        if ([item respondsToSelector:@selector(title)]) {
                            title = [item valueForKey:@"title"];
                        }
                        if ([item respondsToSelector:@selector(url)]) {
                            url = [item valueForKey:@"url"];
                        }
                    } @catch (__unused NSException *inner) {
                        title = nil;
                        url = nil;
                    }

                    if (title.length == 0) {
                        title = @"";
                    }

                    NSMutableDictionary *subtitleDict = [@{
                        @"trackKey": title,
                        @"language": title,
                        @"label": title,
                        @"isBilingual": @NO,
                        @"isDefault": @NO
                    } mutableCopy];
                    if (url.length > 0) {
                        subtitleDict[@"url"] = url;
                    }

                    if (trackKey && [trackKey isEqualToString:title] && currentIndex == -1) {
                        currentIndex = subtitlesArray.count;
                    }

                    [subtitlesArray addObject:subtitleDict];
                }
            }
        } @catch (__unused NSException *exception) {
            // 忽略 srts 相关异常
        }
    }

    if (!enabled) {
        currentIndex = -1;
        trackKey = nil;
    } else if (currentIndex < 0 && subtitlesArray.count > 0) {
        // 启用字幕但未能匹配到有效轨道时（包括 trackKey 为空或无效），退回到列表第一项
        currentIndex = 0;
        NSDictionary *first = subtitlesArray.firstObject;
        trackKey = [first[@"language"] isKindOfClass:[NSString class]] ? first[@"language"] : nil;
    }

    // 驱动原生字幕渲染
    if (self.subtitleModule) {
        NSString *subtitleName = trackKey;
        if (!enabled || subtitleName.length == 0) {
            subtitleName = @"";
        }
        [self.subtitleModule updateSubtitleWithName:subtitleName show:(enabled && subtitleName.length > 0)];
    }

    // 保存当前字幕配置，用于横竖屏切换后恢复
    self.currentSubtitleEnabled = enabled;
    self.currentSubtitleTrackKey = trackKey;
    self.subtitleStateInitialized = YES;

    NSMutableDictionary *data = [@{
        @"subtitles": subtitlesArray,
        @"currentIndex": @(currentIndex),
        @"enabled": @(enabled)
    } mutableCopy];
    if (trackKey) {
        data[@"trackKey"] = trackKey;
    }

    [self.eventStreamHandler sendEvent:@{
        @"type": @"subtitleChanged",
        @"data": data
    }];
}

#pragma mark - PLVMediaPlayerCoreDelegate

// 播放器首帧渲染
- (void)plvMediaPlayerCore:(PLVMediaPlayerCore *)player firstFrameRendered:(BOOL)rendered {
    NSLog(@"[PolyvPlugin] ========== firstFrameRendered: %d ==========", rendered);
}

// 播放器已准备好播放
- (void)plvMediaPlayerCore:(PLVMediaPlayerCore *)player playerIsPreparedToPlay:(BOOL)prepared {
    NSLog(@"[PolyvPlugin] ========== playerIsPreparedToPlay: %d ==========", prepared);
    if (prepared) {
        if (self.shouldSeekToStartOnPrepared) {
            self.shouldSeekToStartOnPrepared = NO;
            [self.player seekToTime:0.0];
        }

        // 播放器准备好后，确保字幕Label在最上层（播放器视图可能覆盖了字幕）
        [self bringSubtitleLabelsToFront];

        [self sendStateChangeEvent:kStatePrepared];

        // 视频准备完成后，发送字幕轨道信息给 Flutter 层
        // 这样 Flutter 层就能知道有哪些字幕可用，字幕按钮才能正常点击
        NSString *defaultTrackKey = nil;
        BOOL defaultEnabled = NO;

        // 检查是否有可用的字幕
        if (self.currentVideo) {
            @try {
                NSArray *srts = [self.currentVideo valueForKey:@"srts"];
                if ([srts isKindOfClass:[NSArray class]] && srts.count > 0) {
                    // 有字幕，默认启用第一条字幕
                    defaultEnabled = YES;
                    id firstSrt = srts.firstObject;
                    if ([firstSrt respondsToSelector:@selector(title)]) {
                        defaultTrackKey = [firstSrt valueForKey:@"title"];
                    }
                    if (!defaultTrackKey || defaultTrackKey.length == 0) {
                        defaultTrackKey = @"字幕";
                    }
                }
            } @catch (__unused NSException *exception) {
                // 忽略异常
            }
        }

        [self sendSubtitleChangedEventWithEnabled:defaultEnabled trackKey:defaultTrackKey];
    }
}

// 播放器播放状态改变
- (void)plvMediaPlayerCore:(PLVMediaPlayerCore *)player playerPlaybackStateDidChange:(PLVPlaybackState)playbackState {
    NSLog(@"[PolyvPlugin] ========== playerPlaybackStateDidChange: %ld ==========", (long)playbackState);
    NSString *stateStr = kStateIdle;
    switch (playbackState) {
        case PLVPlaybackStatePlaying:
            stateStr = kStatePlaying;
            break;
        case PLVPlaybackStatePaused:
            stateStr = kStatePaused;
            break;
        case PLVPlaybackStateStopped:
            stateStr = kStateIdle;
            break;
        default:
            break;
    }
    NSLog(@"[PolyvPlugin] Sending state: %@", stateStr);
    [self sendStateChangeEvent:stateStr];
}

// 播放器加载状态改变
- (void)plvMediaPlayerCore:(PLVMediaPlayerCore *)player playerLoadStateDidChange:(PLVPlayerLoadState)loadState {
    NSLog(@"[PolyvPlugin] ========== playerLoadStateDidChange: %ld ==========", (long)loadState);
    if (loadState == PLVPlayerLoadStateStalled) {
        [self sendStateChangeEvent:kStateBuffering];
    }
}

// 播放器播放结束
- (void)plvMediaPlayerCore:(PLVMediaPlayerCore *)player playerPlaybackDidFinish:(PLVPlayerFinishReason)finishReson {
    NSLog(@"[PolyvPlugin] ========== playerPlaybackDidFinish: %ld ==========", (long)finishReson);
    if (finishReson == PLVPlayerFinishReasonPlaybackEnded) {
        [self sendStateChangeEvent:kStateCompleted];
    }
}

#pragma mark - PLVVodMediaPlayerDelegate

- (void)PLVVodMediaPlayer:(PLVVodMediaPlayer *)vodMediaPlayer loadMainPlayerFailureWithError:(NSError *)error {
    NSString *message = error ? error.localizedDescription : @"Unknown error";
    [self sendErrorEventWithCode:kErrorCodeNetworkError message:message];
    [self sendStateChangeEvent:kStateError];
}

- (void)PLVVodMediaPlayer:(PLVVodMediaPlayer *)vodMediaPlayer playedProgress:(CGFloat)playedProgress playedTimeString:(NSString *)playedTimeString durationTimeString:(NSString *)durationTimeString {
    [self sendProgressEvent];

    // 确保字幕Label始终在最上层（播放器视图可能重新创建导致字幕被覆盖）
    // 每秒只打印一次日志，避免日志过多
    static NSTimeInterval lastLogTime = 0;
    NSTimeInterval currentTime = vodMediaPlayer.currentPlaybackTime;
    if (currentTime - lastLogTime >= 1.0) {
        NSLog(@"[PolyvPlugin] playedProgress: %.2f, subtitleModule: %@", playedProgress, self.subtitleModule ? @"YES" : @"NO");
        lastLogTime = currentTime;
    }

    [self bringSubtitleLabelsToFront];

    if (self.subtitleModule) {
        [self.subtitleModule showSubtilesWithPlaytime:vodMediaPlayer.currentPlaybackTime];
    }
}

#pragma mark - Quality Data

/// 发送清晰度数据（使用当前保存的清晰度索引）
- (void)sendQualityDataForVideo:(PLVVodMediaVideo *)video {
    [self sendQualityDataForVideo:video updateCurrentIndex:-1];
}

/// 发送清晰度数据，可选择更新当前清晰度索引
- (void)sendQualityDataForVideo:(PLVVodMediaVideo *)video updateCurrentIndex:(NSInteger)updateIndex {
    NSLog(@"[PolyvPlugin] ========== sendQualityDataForVideo called ==========");
    NSLog(@"[PolyvPlugin] qualityCount: %d, preferredQuality: %ld", video.qualityCount, (long)video.preferredQuality);

    // 构建清晰度数据
    NSMutableArray *qualitiesList = [NSMutableArray array];
    NSInteger currentIndex = self.currentQualityIndex;

    // 如果指定了新的索引，更新它
    if (updateIndex >= 0) {
        currentIndex = updateIndex;
        self.currentQualityIndex = updateIndex;
    }

    // iOS SDK 的清晰度枚举: 0=自动, 1=流畅, 2=高清, 3=超清
    // 与 Android 端保持一致：总是显示所有清晰度选项（流畅, 高清, 超清）
    // 不再使用 qualityCount 限制，因为某些视频的 qualityCount 值可能不准确
    NSArray<NSDictionary *> *qualityDefinitions = @[
        @{@"enum": @(PLVVodMediaQualityStandard), @"description": @"流畅", @"value": @"480p"},
        @{@"enum": @(PLVVodMediaQualityHigh), @"description": @"高清", @"value": @"720p"},
        @{@"enum": @(PLVVodMediaQualityUltra), @"description": @"超清", @"value": @"1080p"},
    ];

    // 总是添加所有三个清晰度选项，与 Android 端保持一致
    for (NSDictionary *def in qualityDefinitions) {
        [qualitiesList addObject:@{
            @"description": def[@"description"],
            @"value": def[@"value"],
            @"isAvailable": @YES,
        }];
        NSLog(@"[PolyvPlugin] Added quality: %@ (%@)", def[@"description"], def[@"value"]);
    }

    // 调整 currentIndex：iOS 端原本包含"自动"（索引0），需要减1来匹配新的列表
    // 原索引: 0=自动, 1=流畅, 2=高清, 3=超清
    // 新索引: 0=流畅, 1=高清, 2=超清
    if (currentIndex > 0) {
        currentIndex = currentIndex - 1;
    } else {
        // 如果原本是"自动"（索引0），默认切换到"高清"（新索引1）
        currentIndex = 1;
    }

    // 确保 currentIndex 在有效范围内
    if (currentIndex >= qualitiesList.count) {
        currentIndex = 1; // 默认高清
    }

    NSLog(@"[PolyvPlugin] Sending quality data: %@", qualitiesList);
    NSLog(@"[PolyvPlugin] Current quality index: %ld", (long)currentIndex);

    // 发送清晰度数据事件
    [self.eventStreamHandler sendEvent:@{
        @"type": @"qualityChanged",
        @"data": @{
            @"qualities": qualitiesList,
            @"currentIndex": @(currentIndex)
        }
    }];
}

- (void)setupSubtitleModuleIfNeededForVideo:(PLVVodMediaVideo *)video {
    if (!self.videoViewController || !self.videoViewController.containerView) {
        return;
    }

    // 初始化设备方向记录（用于后续检测横竖屏切换）
    if (self.lastOrientation == 0) {
        self.lastOrientation = [UIDevice currentDevice].orientation;
        NSLog(@"[PolyvPlugin] Initial orientation: %ld", (long)self.lastOrientation);
    }

    UIView *container = self.videoViewController.containerView;
    NSLog(@"[PolyvPlugin] ========== setupSubtitleModuleIfNeededForVideo called ==========");
    NSLog(@"[PolyvPlugin] container.bounds: %@", NSStringFromCGRect(container.bounds));
    NSLog(@"[PolyvPlugin] subtitleLabel exists: %@", self.subtitleLabel ? @"YES" : @"NO");

    if (!self.subtitleLabel) {
        CGRect bounds = container.bounds;
        CGFloat width = bounds.size.width > 0 ? bounds.size.width : [UIScreen mainScreen].bounds.size.width;
        CGFloat height = bounds.size.height > 0 ? bounds.size.height : [UIScreen mainScreen].bounds.size.height;

        UILabel *bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, height - 80.0, width - 32.0, 40.0)];
        bottomLabel.textColor = [UIColor whiteColor];
        bottomLabel.textAlignment = NSTextAlignmentCenter;
        bottomLabel.numberOfLines = 0;
        bottomLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.8];
        bottomLabel.shadowOffset = CGSizeMake(0, 1);
        bottomLabel.backgroundColor = [UIColor clearColor];
        bottomLabel.adjustsFontSizeToFitWidth = YES;
        bottomLabel.minimumScaleFactor = 0.5;

        UILabel *topLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, height - 120.0, width - 32.0, 40.0)];
        topLabel.textColor = [UIColor whiteColor];
        topLabel.textAlignment = NSTextAlignmentCenter;
        topLabel.numberOfLines = 0;
        topLabel.shadowColor = [UIColor colorWithWhite:0 alpha:0.8];
        topLabel.shadowOffset = CGSizeMake(0, 1);
        topLabel.backgroundColor = [UIColor clearColor];
        topLabel.adjustsFontSizeToFitWidth = YES;
        topLabel.minimumScaleFactor = 0.5;

        UILabel *bottomLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(16, height - 40.0, width - 32.0, 30.0)];
        bottomLabel2.textColor = [UIColor whiteColor];
        bottomLabel2.textAlignment = NSTextAlignmentCenter;
        bottomLabel2.numberOfLines = 0;
        bottomLabel2.shadowColor = [UIColor colorWithWhite:0 alpha:0.8];
        bottomLabel2.shadowOffset = CGSizeMake(0, 1);
        bottomLabel2.backgroundColor = [UIColor clearColor];
        bottomLabel2.adjustsFontSizeToFitWidth = YES;
        bottomLabel2.minimumScaleFactor = 0.5;

        UILabel *topLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(16, height - 160.0, width - 32.0, 30.0)];
        topLabel2.textColor = [UIColor whiteColor];
        topLabel2.textAlignment = NSTextAlignmentCenter;
        topLabel2.numberOfLines = 0;
        topLabel2.shadowColor = [UIColor colorWithWhite:0 alpha:0.8];
        topLabel2.shadowOffset = CGSizeMake(0, 1);
        topLabel2.backgroundColor = [UIColor clearColor];
        topLabel2.adjustsFontSizeToFitWidth = YES;
        topLabel2.minimumScaleFactor = 0.5;

        bottomLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        topLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        bottomLabel2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        topLabel2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;

        [container addSubview:topLabel2];
        [container addSubview:bottomLabel2];
        [container addSubview:topLabel];
        [container addSubview:bottomLabel];

        self.subtitleLabel = bottomLabel;
        self.subtitleTopLabel = topLabel;
        self.subtitleLabel2 = bottomLabel2;
        self.subtitleTopLabel2 = topLabel2;

        NSLog(@"[PolyvPlugin] Subtitle labels created and added to container");
        NSLog(@"[PolyvPlugin] bottomLabel frame: %@", NSStringFromCGRect(bottomLabel.frame));
    } else {
        // 确保字幕 Label 始终在最上层（播放器视图可能覆盖了字幕）
        NSLog(@"[PolyvPlugin] Subtitle labels already exist, bringing to front");
        [container bringSubviewToFront:self.subtitleTopLabel2];
        [container bringSubviewToFront:self.subtitleLabel2];
        [container bringSubviewToFront:self.subtitleTopLabel];
        [container bringSubviewToFront:self.subtitleLabel];
    }

    if (!self.subtitleModule) {
        self.subtitleModule = [[PLVMediaPlayerSubtitleModule alloc] init];
        NSLog(@"[PolyvPlugin] SubtitleModule created");
    }

    // 加载字幕模块（会加载默认字幕）
    NSLog(@"[PolyvPlugin] Loading subtitle module with video...");
    [self.subtitleModule loadSubtitlsWithVideoModel:video
                                              label:self.subtitleLabel
                                           topLabel:self.subtitleTopLabel
                                             label2:self.subtitleLabel2
                                          topLabel2:self.subtitleTopLabel2];
    NSLog(@"[PolyvPlugin] Subtitle module loaded");

    // 延迟确保字幕Label在最上层（播放器视图可能在字幕之后才被创建）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"[PolyvPlugin] Delayed bringSubtitleLabelsToFront called");
        [self bringSubtitleLabelsToFront];
    });

    // 如果用户之前有字幕选择，恢复用户选择
    if (self.subtitleStateInitialized && self.currentSubtitleEnabled) {
        NSString *subtitleName = self.currentSubtitleTrackKey;
        if (subtitleName.length == 0 && video) {
            // 如果字幕为空但启用了字幕，使用第一个字幕
            @try {
                NSArray *srts = [video valueForKey:@"srts"];
                if ([srts isKindOfClass:[NSArray class]] && srts.count > 0) {
                    id firstSrt = srts.firstObject;
                    if ([firstSrt respondsToSelector:@selector(title)]) {
                        subtitleName = [firstSrt valueForKey:@"title"];
                    }
                }
            } @catch (__unused NSException *exception) {
            }
        }

        if (subtitleName.length > 0) {
            NSLog(@"[PolyvPlugin] 恢复字幕选择: %@", subtitleName);
            [self.subtitleModule updateSubtitleWithName:subtitleName show:YES];
        }
    }
}

/// 确保字幕Label始终在最上层（播放器视图可能覆盖了字幕）
- (void)bringSubtitleLabelsToFront {
    if (!self.videoViewController || !self.videoViewController.containerView) {
        return;
    }

    UIView *container = self.videoViewController.containerView;

    // 打印视图层级用于调试
    NSLog(@"[PolyvPlugin] ========== bringSubtitleLabelsToFront ==========");
    NSLog(@"[PolyvPlugin] container.bounds: %@, container.frame: %@", NSStringFromCGRect(container.bounds), NSStringFromCGRect(container.frame));
    NSLog(@"[PolyvPlugin] containerView subviews count: %lu", (unsigned long)container.subviews.count);

    // 更新字幕Label的frame以适应containerView的当前大小
    // 因为containerView的size可能会变化（例如横竖屏切换、视图调整等）
    [self updateSubtitleLabelFrames];

    // 打印字幕Label的frame
    NSLog(@"[PolyvPlugin] subtitleLabel.frame: %@", NSStringFromCGRect(self.subtitleLabel.frame));
    NSLog(@"[PolyvPlugin] subtitleTopLabel.frame: %@", NSStringFromCGRect(self.subtitleTopLabel.frame));
    NSLog(@"[PolyvPlugin] subtitleLabel.text: '%@'", self.subtitleLabel.text);

    for (int i = 0; i < container.subviews.count; i++) {
        UIView *subview = container.subviews[i];
        NSLog(@"[PolyvPlugin]   [%d] %@ (frame=%@, hidden=%d)", i,
              NSStringFromClass(subview.class),
              NSStringFromCGRect(subview.frame),
              subview.isHidden);
    }

    // 确保所有字幕Label都在最上层
    if (self.subtitleTopLabel2 && self.subtitleTopLabel2.superview == container) {
        [container bringSubviewToFront:self.subtitleTopLabel2];
        NSLog(@"[PolyvPlugin] Brought subtitleTopLabel2 to front");
    }
    if (self.subtitleLabel2 && self.subtitleLabel2.superview == container) {
        [container bringSubviewToFront:self.subtitleLabel2];
        NSLog(@"[PolyvPlugin] Brought subtitleLabel2 to front");
    }
    if (self.subtitleTopLabel && self.subtitleTopLabel.superview == container) {
        [container bringSubviewToFront:self.subtitleTopLabel];
        NSLog(@"[PolyvPlugin] Brought subtitleTopLabel to front");
    }
    if (self.subtitleLabel && self.subtitleLabel.superview == container) {
        [container bringSubviewToFront:self.subtitleLabel];
        NSLog(@"[PolyvPlugin] Brought subtitleLabel to front");
    }
}

/// 更新字幕Label的frame以适应containerView的当前大小
- (void)updateSubtitleLabelFrames {
    if (!self.videoViewController || !self.videoViewController.containerView) {
        return;
    }

    UIView *container = self.videoViewController.containerView;
    CGRect bounds = container.bounds;

    // 如果container的size无效，使用当前字幕Label的frame或屏幕尺寸
    if (bounds.size.width <= 0 || bounds.size.height <= 0) {
        bounds = [UIScreen mainScreen].bounds;
    }

    CGFloat width = bounds.size.width;
    CGFloat height = bounds.size.height;

    // 更新所有字幕Label的frame
    if (self.subtitleLabel) {
        self.subtitleLabel.frame = CGRectMake(16, height - 80.0, width - 32.0, 40.0);
    }
    if (self.subtitleTopLabel) {
        self.subtitleTopLabel.frame = CGRectMake(16, height - 120.0, width - 32.0, 40.0);
    }
    if (self.subtitleLabel2) {
        self.subtitleLabel2.frame = CGRectMake(16, height - 40.0, width - 32.0, 30.0);
    }
    if (self.subtitleTopLabel2) {
        self.subtitleTopLabel2.frame = CGRectMake(16, height - 160.0, width - 32.0, 30.0);
    }
}

#pragma mark - Story 9.8: Download Status Monitoring

/// 启动下载状态监控
- (void)startDownloadStatusMonitoring {
    self.downloadPreviousStates = [NSMutableDictionary dictionary];

    // 记录初始状态（SDK 没有提供统一的 requestDownloadInfoList 方法）
    NSArray<PLVDownloadInfo *> *unfinishedDownloads = [[PLVDownloadMediaManager sharedManager] getUnfinishedDownloadList];
    NSArray<PLVDownloadInfo *> *finishedDownloads = [[PLVDownloadMediaManager sharedManager] getFinishedDownloadList];
    NSMutableArray<PLVDownloadInfo *> *allDownloads = [NSMutableArray arrayWithArray:unfinishedDownloads];
    [allDownloads addObjectsFromArray:finishedDownloads];

    for (PLVDownloadInfo *info in allDownloads) {
        NSString *vid = info.vid ?: @"";
        self.downloadPreviousStates[vid] = @(info.state);
    }

    // 启动定时器，每秒检查一次下载状态变化
    self.downloadStatusCheckTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                     target:self
                                                                   selector:@selector(checkDownloadStatusChanges)
                                                                   userInfo:nil
                                                                    repeats:YES];

    NSLog(@"[PolyvPlugin] Download status monitoring started with %lu tasks", (unsigned long)allDownloads.count);
}

/// 停止下载状态监控
- (void)stopDownloadStatusMonitoring {
    if (self.downloadStatusCheckTimer) {
        [self.downloadStatusCheckTimer invalidate];
        self.downloadStatusCheckTimer = nil;
        NSLog(@"[PolyvPlugin] Download status monitoring stopped");
    }
}

/// 检查下载状态变化并推送事件
- (void)checkDownloadStatusChanges {
    // 获取所有下载任务（SDK 没有提供统一的 requestDownloadInfoList 方法）
    NSArray<PLVDownloadInfo *> *unfinishedDownloads = [[PLVDownloadMediaManager sharedManager] getUnfinishedDownloadList];
    NSArray<PLVDownloadInfo *> *finishedDownloads = [[PLVDownloadMediaManager sharedManager] getFinishedDownloadList];
    NSMutableArray<PLVDownloadInfo *> *allDownloads = [NSMutableArray arrayWithArray:unfinishedDownloads];
    [allDownloads addObjectsFromArray:finishedDownloads];

    for (PLVDownloadInfo *info in allDownloads) {
        NSString *vid = info.vid ?: @"";
        if (vid.length == 0) continue;

        PLVVodDownloadState currentState = info.state;
        NSNumber *previousStateNumber = self.downloadPreviousStates[vid];
        PLVVodDownloadState previousState = previousStateNumber ? (PLVVodDownloadState)[previousStateNumber integerValue] : PLVVodDownloadStatePreparing;

        // 检测状态变化
        if (currentState != previousState) {
            NSLog(@"[PolyvPlugin] Download state changed for vid=%@: %ld -> %ld",
                  vid, (long)previousState, (long)currentState);

            [self handleDownloadStateChanged:info fromState:previousState toState:currentState];

            // 更新记录的状态
            self.downloadPreviousStates[vid] = @(currentState);
        }

        // 对于所有活跃下载状态的任务，定期发送进度更新
        // 包括：准备中、就绪、运行中等状态，确保 Flutter 层能实时看到进度变化
        if (currentState == PLVVodDownloadStateRunning ||
            currentState == PLVVodDownloadStatePreparing ||
            currentState == PLVVodDownloadStatePreparingTask ||
            currentState == PLVVodDownloadStateReady) {
            [self sendDownloadProgressEvent:info];
        }
    }
}

/// 处理下载状态变化
- (void)handleDownloadStateChanged:(PLVDownloadInfo *)info
                        fromState:(PLVVodDownloadState)fromState
                          toState:(PLVVodDownloadState)toState {
    NSString *vid = info.vid ?: @"";

    // 根据新状态发送对应事件
    switch (toState) {
        case PLVVodDownloadStateSuccess:
            [self sendDownloadCompletedEvent:info];
            break;

        case PLVVodDownloadStateFailed:
            [self sendDownloadFailedEvent:info];
            break;

        case PLVVodDownloadStateStopping:
        case PLVVodDownloadStateStopped:
            [self sendDownloadPausedEvent:info];
            break;

        case PLVVodDownloadStateRunning:
            // 如果之前是暂停状态，现在恢复下载
            if (fromState == PLVVodDownloadStateStopped || fromState == PLVVodDownloadStateStopping) {
                [self sendDownloadResumedEvent:info];
            }
            break;

        default:
            break;
    }
}

/// 发送下载进度事件
- (void)sendDownloadProgressEvent:(PLVDownloadInfo *)info {
    NSString *vid = info.vid ?: @"";
    if (vid.length == 0) return;

    // SDK 没有 downloadedBytes 属性，使用 progress * filesize 计算
    long long downloadedBytes = (long long)(info.progress * info.filesize);

    [self.downloadEventStreamHandler sendEvent:@{
        @"type": kDownloadEventTaskProgress,
        @"data": @{
            @"id": vid,
            @"downloadedBytes": @(downloadedBytes),
            @"totalBytes": @(info.filesize),
            @"bytesPerSecond": @(0), // iOS SDK 不直接提供速度信息
            @"status": [self convertDownloadStateToString:info.state]
        }
    }];
}

/// 发送下载完成事件
- (void)sendDownloadCompletedEvent:(PLVDownloadInfo *)info {
    NSString *vid = info.vid ?: @"";
    if (vid.length == 0) return;

    NSString *completedAt = [[self iso8601Formatter] stringFromDate:[NSDate date]];

    [self.downloadEventStreamHandler sendEvent:@{
        @"type": kDownloadEventTaskCompleted,
        @"data": @{
            @"id": vid,
            @"completedAt": completedAt
        }
    }];
}

/// 发送下载失败事件
- (void)sendDownloadFailedEvent:(PLVDownloadInfo *)info {
    NSString *vid = info.vid ?: @"";
    if (vid.length == 0) return;

    [self.downloadEventStreamHandler sendEvent:@{
        @"type": kDownloadEventTaskFailed,
        @"data": @{
            @"id": vid,
            @"errorMessage": @"下载失败"
        }
    }];
}

/// 发送下载暂停事件
- (void)sendDownloadPausedEvent:(PLVDownloadInfo *)info {
    NSString *vid = info.vid ?: @"";
    if (vid.length == 0) return;

    [self.downloadEventStreamHandler sendEvent:@{
        @"type": kDownloadEventTaskPaused,
        @"data": @{
            @"id": vid
        }
    }];
}

/// 发送下载恢复事件
- (void)sendDownloadResumedEvent:(PLVDownloadInfo *)info {
    NSString *vid = info.vid ?: @"";
    if (vid.length == 0) return;

    // SDK 没有 downloadedBytes 属性，使用 progress * filesize 计算
    long long downloadedBytes = (long long)(info.progress * info.filesize);

    [self.downloadEventStreamHandler sendEvent:@{
        @"type": kDownloadEventTaskProgress,  // 使用 taskProgress 而不是 taskResumed，包含进度信息
        @"data": @{
            @"id": vid,
            @"downloadedBytes": @(downloadedBytes),
            @"totalBytes": @(info.filesize),
            @"bytesPerSecond": @(0), // iOS SDK 不直接提供速度信息
            @"status": @"downloading"
        }
    }];
    NSLog(@"[PolyvPlugin] Send resumed event for vid=%@ with downloadedBytes=%lld", vid, downloadedBytes);
}

@end
