import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polyv_media_player/polyv_media_player.dart';
import 'package:polyv_media_player/utils/plv_logger.dart';
import 'package:provider/provider.dart';
// Example 独有组件
import '../pages/download_center/download_center_page.dart';
import '../player_skin/video_list/video_list_view.dart' show VideoListView;
// ControlBarStateMachine, PlayerGestureController, PlayerGestureDetector, DanmakuInputOverlay,
// Danmaku, DanmakuService, DanmakuSettings 等已通过 polyv_media_player.dart 导出

/// LongVideoPage - 长视频页面（测试播放器）
///
/// 精确还原原型设计：全屏视频 + 覆盖控制栏
class LongVideoPage extends StatefulWidget {
  /// 初始视频 VID - 用于从下载中心点击播放时直接加载指定视频
  final String? initialVid;
  /// 是否为离线播放模式 - 跳过网络列表加载，直接播放指定视频
  final bool isOfflineMode;
  /// 离线播放时的初始标题（从下载任务获取）
  final String? initialTitle;
  /// 离线播放时的初始缩略图（从下载任务获取）
  final String? initialThumbnail;

  const LongVideoPage({
    super.key,
    this.initialVid,
    this.isOfflineMode = false,
    this.initialTitle,
    this.initialThumbnail,
  });

  @override
  State<LongVideoPage> createState() => _LongVideoPageState();
}

class _LongVideoPageState extends State<LongVideoPage> implements DownloadCallbacks {
  late final PlayerController _controller;

  // 控制条状态机（命令式管理）
  final ControlBarStateMachine _controlBarStateMachine =
      ControlBarStateMachine();

  // 播放相关状态
  bool _isPlaying = false;
  bool _isEnded = false;

  // 视频列表相关状态
  VideoListService? _videoListService;
  List<VideoItem> _videos = [];
  VideoItem? _currentVideo;
  bool _isLoadingList = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  String? _listError;

  // 初始加载状态 - 用于显示全屏居中 loading
  bool _isInitialLoading = true;

  // 视频切换相关状态（仅用于防抖，不参与控制条可见性判断）
  bool _isSwitchingVideo = false;
  DateTime? _lastSwitchTime;
  static const int _debounceMs = 1000;

  // 用户是否首次交互（第一个视频加载完成后，控制条保持隐藏直到用户交互）
  bool _hasUserInteracted = false;

  // 弹幕相关状态 - 使用 DanmakuSettings 集中管理
  // 弹幕获取服务 - 延迟初始化，等待配置加载完成
  DanmakuService? _danmakuService;

  // Polyv 配置服务 - 从原生层读取
  final PolyvConfigService _configService = PolyvConfigService();

  // 弹幕发送服务 - 延迟初始化，等待配置加载完成
  DanmakuSendService? _danmakuSendService;

  final DanmakuSettings _danmakuSettings = DanmakuSettings();
  List<Danmaku> _danmakus = const [];

  // 弹幕发送状态
  bool _isSendingDanmaku = false;

  // 横屏状态
  bool _isFullscreen = false;

  late Object _videoViewKeySeed = Object();
  final GlobalKey _danmakuLayerKey = GlobalKey();

  // 视频列表的 GlobalKey，用于控制滚动
  final GlobalKey _videoListKey = GlobalKey();

  // 锁定状态
  bool _isLocked = false;

  // 手势控制器 - 处理滑动手势（seek、亮度、音量）
  final PlayerGestureController _gestureController = PlayerGestureController();

  // DownloadCallbacks 实现
  @override
  DownloadTask? getTaskByVid(String vid) {
    try {
      return context.read<DownloadStateManager>().getTaskByVid(vid);
    } catch (_) {
      return null;
    }
  }

  @override
  DownloadStateManager get stateManager {
    return context.read<DownloadStateManager>();
  }

  @override
  void openDownloadCenter(int initialTabIndex) {
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.push(
      DownloadCenterPage.route(initialTabIndex: initialTabIndex),
    );
  }

  /// 控制条是否应该可见
  ///
  /// 委托给状态机，传入当前播放状态。
  /// 但在用户首次交互之前，控制条始终隐藏。
  /// 播放结束时，控制条始终隐藏，只显示重播按钮。
  bool get _isControlBarVisible =>
      !_isEnded &&
      _hasUserInteracted &&
      _controlBarStateMachine.isVisible(_isPlaying);

  @override
  void initState() {
    super.initState();
    _controller = PlayerController();

    // 监听播放器状态变化
    _controller.addListener(_onPlayerStateChanged);

    // 监听状态机变化
    _controlBarStateMachine.addListener(_onControlBarStateChanged);

    // 初始化配置和服务
    _initializeServices();
  }

  /// 状态机变化回调
  void _onControlBarStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// 初始化配置和服务
  Future<void> _initializeServices() async {
    try {
      // 从原生层加载配置
      final config = await _configService.getConfig();

      // 初始化视频列表服务 - 使用真实 API
      _videoListService = VideoListServiceFactory.createHttp(
        userId: config.userId,
        readToken: config.readToken,
        secretKey: config.secretKey,
      );

      // 初始化弹幕发送服务
      _danmakuSendService = DanmakuSendServiceFactory.createHttp(
        userId: config.userId,
        writeToken: config.writeToken,
        secretKey: config.secretKey,
      );

      // 初始化弹幕获取服务 - 使用真实 API
      _danmakuService = DanmakuServiceFactory.createHttp(
        userId: config.userId,
        readToken: config.readToken,
        secretKey: config.secretKey,
      );

      PlvLogger.d(
        'LongVideoPage: Services initialized with config from native layer',
      );

      // 离线模式：直接播放指定视频，跳过网络列表加载
      if (widget.isOfflineMode && widget.initialVid != null && widget.initialVid!.isNotEmpty) {
        PlvLogger.d('LongVideoPage: Offline mode, loading video directly: ${widget.initialVid}');
        _loadOfflineVideo(widget.initialVid!);
      } else {
        // 在线模式：加载视频列表
        if (mounted) {
          _loadVideoList();
        }
      }
    } catch (e) {
      PlvLogger.w('LongVideoPage: Failed to load config: $e');
      // 降级到 Mock 服务
      _videoListService = VideoListServiceFactory.createMock();
      _danmakuService = DanmakuServiceFactory.createMock();

      // 离线模式：直接播放指定视频
      if (widget.isOfflineMode && widget.initialVid != null && widget.initialVid!.isNotEmpty) {
        PlvLogger.d('LongVideoPage: Offline mode (fallback), loading video directly: ${widget.initialVid}');
        _loadOfflineVideo(widget.initialVid!);
      } else {
        // 即使降级也尝试加载视频列表
        if (mounted) {
          _loadVideoList();
        }
      }
    }
  }

  /// 监听播放器状态变化
  ///
  /// 只负责同步播放状态和检测播放结束，不再处理控制条逻辑。
  /// 控制条可见性由状态机根据模式自动决定。
  void _onPlayerStateChanged() {
    if (!mounted) return;

    final state = _controller.state;
    final isPlaying = _controller.effectiveIsPlaying;
    final isCompleted = state.loadingState == PlayerLoadingState.completed;

    // 检测播放结束
    if (isCompleted && !_isEnded) {
      setState(() {
        _isEnded = true;
        _isPlaying = false;
      });
      // 播放结束时取消可能存在的计时器
      _controlBarStateMachine.cancelTimer();
      return;
    }

    // 同步播放状态
    if (_isPlaying != isPlaying) {
      setState(() {
        _isPlaying = isPlaying;
      });
    }
  }

  /// 处理视频区域单击 - 切换播放/暂停
  ///
  /// 场景覆盖：
  /// - 场景1: 播放中单击暂停
  /// - 场景2: 暂停状态单击播放
  /// - 场景3: 控制栏已显示时单击
  /// - 场景4: 控制栏隐藏时单击
  /// - 场景5: 播放结束状态（重播）
  /// - 场景6: 锁屏状态（只显示控制栏，不切换播放）
  /// - 场景7: 切换视频期间（忽略点击）
  void _handleSingleTap() {
    // 场景6: 锁屏状态下只显示控制栏，不切换播放
    if (_isLocked) {
      // 解锁后显示控制栏
      _controlBarStateMachine.enterActive(
        autoHideTimeout: const Duration(seconds: 3),
      );
      return;
    }

    // 场景7: 切换视频期间不响应
    if (_isSwitchingVideo) return;

    // 场景5: 播放结束状态 - 重播
    if (_isEnded) {
      setState(() => _isEnded = false);
      if (_currentVideo != null) {
        _loadVideo(_currentVideo!.vid);
      }
      // 重播时显示控制栏
      if (!_hasUserInteracted) {
        _hasUserInteracted = true;
      }
      _controlBarStateMachine.enterActive(
        autoHideTimeout: const Duration(seconds: 3),
      );
      return;
    }

    // 场景1&2: 只显示/隐藏控制栏，不切换播放/暂停
    // （播放/暂停由控制栏按钮控制）

    // 场景3: 控制栏已显示时，再次点击立即隐藏
    if (_controlBarStateMachine.isVisible(_isPlaying)) {
      _controlBarStateMachine.enterPassive();
      return;
    }

    // 场景4: 控制栏隐藏时，显示控制栏并启动自动隐藏计时器
    if (!_hasUserInteracted) {
      _hasUserInteracted = true;
    }
    _controlBarStateMachine.enterActive(
      autoHideTimeout: const Duration(seconds: 3),
    );
  }

  /// 处理视频区域双击 - 切换播放/暂停
  ///
  /// 场景覆盖：
  /// - 场景1: 播放中双击暂停
  /// - 场景2: 暂停状态双击播放
  /// - 场景3: 锁屏状态下不响应
  /// - 场景4: 切换视频期间不响应
  void _handleDoubleTap() {
    // 场景3: 锁屏状态下不响应
    if (_isLocked) return;

    // 场景4: 切换视频期间不响应
    if (_isSwitchingVideo) return;

    // 切换播放/暂停
    if (_isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }

    // 双击后显示控制栏并重置自动隐藏计时器
    if (!_hasUserInteracted) {
      _hasUserInteracted = true;
    }
    _controlBarStateMachine.enterActive(
      autoHideTimeout: const Duration(seconds: 3),
    );
  }

  Future<void> _loadVideo(String vid) async {
    try {
      await _controller.loadVideo(vid);

      // 加载弹幕数据
      _loadDanmakus(vid);

      if (mounted) {
        setState(() {
          _isPlaying = _controller.effectiveIsPlaying;
          _isEnded = false;
        });
      }
    } catch (e) {
      PlvLogger.w('加载视频失败: $e');
    }
  }

  /// 加载弹幕数据
  Future<void> _loadDanmakus(String vid) async {
    final service = _danmakuService;
    if (service == null) {
      PlvLogger.w('弹幕服务未初始化');
      return;
    }

    try {
      final danmakus = await service.fetchDanmakus(vid);
      if (mounted) {
        setState(() {
          _danmakus = danmakus;
        });
      }
    } catch (e) {
      PlvLogger.w('加载弹幕失败: $e');
    }
  }

  /// 离线模式：直接加载指定视频，跳过网络列表加载
  ///
  /// 用于从下载中心点击已下载视频时直接播放，无需网络连接。
  Future<void> _loadOfflineVideo(String vid) async {
    try {
      // 从下载任务获取标题和缩略图（如果有）
      final title = widget.initialTitle ?? 'Video_$vid';
      final thumbnail = widget.initialThumbnail ?? '';

      // 创建一个临时的 VideoItem 用于显示
      final tempVideo = VideoItem(
        vid: vid,
        title: title,
        duration: 0,
        thumbnail: thumbnail,
      );

      _currentVideo = tempVideo;
      _videos = [tempVideo];  // 设置为单元素列表，避免 UI 异常
      _isLoadingList = false;
      _listError = null;

      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }

      // 加载视频（自动检测离线播放模式）
      // PlayerController 会通过 DownloadStateManager.instance.isCompleted(vid) 检测离线模式
      await _controller.loadVideo(vid);

      PlvLogger.d('LongVideoPage: Offline video loaded: $vid, title: $title');
    } catch (e) {
      PlvLogger.w('LongVideoPage: Failed to load offline video: $e');
      if (mounted) {
        setState(() {
          _listError = '加载失败: $e';
          _isInitialLoading = false;
        });
      }
    }
  }

  /// 加载视频列表
  Future<void> _loadVideoList({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _listError = null;
    }

    final service = _videoListService;
    if (service == null) {
      PlvLogger.d('_loadVideoList: Video list service not initialized yet');
      return;
    }

    try {
      final response = await service.fetchVideoList(
        VideoListRequest(page: _currentPage, pageSize: _pageSize),
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _videos = response.videos;
          } else {
            _videos = [..._videos, ...response.videos];
          }
          _hasMore = response.hasNextPage;
          _isLoadingList = false;
          _isLoadingMore = false;
          _listError = null;
        });

        // 首次加载完成后，加载第一个视频或指定的 initialVid
        if (_isInitialLoading) {
          VideoItem firstVideo;

          // 如果指定了 initialVid，优先查找该视频
          if (widget.initialVid != null && widget.initialVid!.isNotEmpty) {
            final targetVideo = _videos.firstWhere(
              (v) => v.vid == widget.initialVid,
              orElse: () => _videos.first,
            );
            firstVideo = targetVideo;
          } else {
            firstVideo = _videos.first;
          }

          _currentVideo = firstVideo;

          // 加载视频（自动检测离线播放模式）
          await _controller.loadVideo(firstVideo.vid);
          _loadDanmakus(firstVideo.vid);

          if (mounted) {
            setState(() {
              _isInitialLoading = false;
              _isPlaying = _controller.effectiveIsPlaying;
            });
            // 第一个视频加载完成，但控制条保持隐藏直到用户交互
            // 状态机保持在 hidden 模式
          }
        }
      }
    } catch (e) {
      PlvLogger.w('加载视频列表失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingList = false;
          _isLoadingMore = false;
          _isInitialLoading = false;
          _listError = '加载失败，请重试';
        });
      }
    }
  }

  /// 加载更多视频
  Future<void> _loadMoreVideos() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    _currentPage++;
    await _loadVideoList();
  }

  /// 点击视频项切换视频
  ///
  /// 实现防抖机制：在切换过程中忽略新的切换请求，防止快速连续点击
  /// 实现加载状态反馈：切换过程中显示加载指示器
  /// 实现错误处理：加载失败时恢复原视频并显示错误提示
  Future<void> _onVideoTap(VideoItem video) async {
    // 防抖检查：如果正在切换，忽略请求
    if (_isSwitchingVideo) {
      PlvLogger.d('_onVideoTap: 视频切换正在进行中，忽略请求');
      return;
    }

    // 防抖时间检查（1秒内不允许重复切换）
    if (_lastSwitchTime != null) {
      final elapsed = DateTime.now().difference(_lastSwitchTime!);
      if (elapsed.inMilliseconds < _debounceMs) {
        PlvLogger.d('_onVideoTap: 防抖中，忽略视频切换请求');
        return;
      }
    }

    // 检查是否是同一个视频
    if (_currentVideo?.vid == video.vid) {
      PlvLogger.d('_onVideoTap: 已经在播放视频 ${video.vid}');
      return;
    }

    // 保存之前的视频，用于错误恢复
    final previousVideo = _currentVideo;

    // 进入隐藏模式（切换视频期间隐藏控制条）
    _controlBarStateMachine.enterHidden();

    // 重置用户交互标志（切换视频后需要再次点击才会显示控制条）
    _hasUserInteracted = false;

    // 先显示黑色遮罩，再停止播放器和重建视图
    // 这样可以避免旧视频画面在视图重建期间闪烁
    setState(() {
      _isSwitchingVideo = true;
      _lastSwitchTime = DateTime.now();
      _currentVideo = video;
    });

    // 等待黑色遮罩显示
    await Future.delayed(const Duration(milliseconds: 50));

    // 停止播放器
    _controller.stop();

    // 改变 keySeed 强制重建视频视图，清除旧画面
    _videoViewKeySeed = Object();

    // 等待播放器停止和视图重建
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      // 加载新视频
      await _controller.loadVideo(video.vid);

      // 加载新视频的弹幕
      _loadDanmakus(video.vid);

      // 等待视频开始播放
      await Future.delayed(const Duration(milliseconds: 700));

      // 切换完成，隐藏遮罩
      if (mounted) {
        setState(() {
          _isSwitchingVideo = false;
          _isPlaying = _controller.effectiveIsPlaying;
          _isEnded = false;
        });
        // 恢复用户交互状态，避免需要点两下
        _hasUserInteracted = true;
      }

      PlvLogger.d('_onVideoTap: 成功切换到视频：${video.title}');
    } catch (e) {
      PlvLogger.w('_onVideoTap: 视频切换失败：$e');

      // 错误恢复
      _controlBarStateMachine.enterPassive();

      if (mounted && previousVideo != null) {
        setState(() {
          _isSwitchingVideo = false;
          _currentVideo = previousVideo;
        });

        // 重新加载原视频
        _controller
            .loadVideo(previousVideo.vid)
            .then((_) {
              _loadDanmakus(previousVideo.vid);
            })
            .catchError((error) {
              PlvLogger.w('_onVideoTap: 恢复原视频失败：$error');
            });

        _showSnackBar('视频切换失败，请重试');
      }
    }
  }

  @override
  void dispose() {
    // 恢复屏幕方向和系统UI
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _controller.removeListener(_onPlayerStateChanged);
    _controller.dispose();
    _controlBarStateMachine.dispose();
    _danmakuSettings.dispose();
    _gestureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 初始加载状态：显示全屏居中的 loading
    if (_isInitialLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: const Color(0xFF6366F1), // primary color
              ),
              const SizedBox(height: 16),
              const Text(
                '加载中...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // 横屏模式：全屏显示，无顶部栏，无底部列表区域
    if (_isFullscreen) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) async {
          if (didPop) return;
          // 在横屏模式下，按返回键应先退出横屏，而不是返回上一页
          await _exitFullscreen();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 视频视图 - 始终渲染，用遮罩覆盖
              Positioned.fill(
                child: PolyvVideoView(keySeed: _videoViewKeySeed),
              ),

              // 弹幕显示层
              _buildDanmakuLayer(),

              // 手势检测器 - 处理单击、双击、滑动
              Positioned.fill(
                child: PlayerGestureDetector(
                  gestureController: _gestureController,
                  playerController: _controller,
                  isLocked: _isLocked,
                  onTap: _handleSingleTap,
                  onDoubleTap: _handleDoubleTap,
                  child: const SizedBox.shrink(),
                ),
              ),

              // 中间播放按钮
              _buildCenterPlayButton(),

              // 重播界面
              _buildReplayOverlay(),

              // 横屏控制栏（包含弹幕输入按钮）
              _buildLandscapeControls(),

              // 切换视频时的黑色遮罩
              if (_isSwitchingVideo)
                Positioned.fill(child: Container(color: Colors.black)),
            ],
          ),
        ),
      );
    }

    // 竖屏模式：正常布局
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // 顶部导航栏
          _buildTopBar(),

          // 视频显示区域
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                // 视频视图 - 始终渲染，用遮罩覆盖
                PolyvVideoView(keySeed: _videoViewKeySeed),

                // 弹幕显示层
                _buildDanmakuLayer(),

                // 手势检测器 - 处理单击、双击、滑动
                Positioned.fill(
                  child: PlayerGestureDetector(
                    gestureController: _gestureController,
                    playerController: _controller,
                    isLocked: _isLocked,
                    onTap: _handleSingleTap,
                    onDoubleTap: _handleDoubleTap,
                    child: const SizedBox.shrink(),
                  ),
                ),

                // 中间播放按钮
                _buildCenterPlayButton(),

                // 重播界面
                _buildReplayOverlay(),

                _buildPortraitMoreButton(),

                // 底部控制栏（竖屏，无弹幕输入按钮）
                _buildBottomControls(isFullscreen: false),

                // 切换视频时的黑色遮罩
                if (_isSwitchingVideo)
                  Positioned.fill(child: Container(color: Colors.black)),
              ],
            ),
          ),

          // 视频信息区域
          _buildVideoInfo(),

          // 视频列表区域
          Expanded(
            child: Container(
              color: const Color(0xFF0A0A0F),
              child: VideoListView(
                key: _videoListKey,
                videos: _videos,
                currentVid: _currentVideo?.vid,
                onVideoTap: _onVideoTap,
                isLoading: _isLoadingList,
                isLoadingMore: _isLoadingMore,
                hasMore: _hasMore,
                onLoadMore: _loadMoreVideos,
                error: _listError,
                isSwitching: _isSwitchingVideo,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建弹幕显示层
  ///
  /// 横竖屏统一使用 heightFactor=0.6，仅使用上部分区域显示弹幕，避免与底部控制条重叠。
  Widget _buildDanmakuLayer() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return AnimatedBuilder(
            animation: _danmakuSettings,
            builder: (context, _) {
              return DanmakuLayer(
                key: _danmakuLayerKey,
                enabled: _danmakuSettings.enabled,
                opacity: _danmakuSettings.opacity,
                fontSize: _danmakuSettings.fontSize,
                currentTime: _controller.state.position,
                danmakus: _danmakus,
                heightFactor: 0.6,
              );
            },
          );
        },
      ),
    );
  }

  /// 构建顶部栏
  Widget _buildTopBar() {
    return Container(
      color: const Color(0xFF0F172A),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            children: [
              // 居中标题
              const Center(
                child: Text(
                  '长视频',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),

              // 左右按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 返回按钮
                  IconButton(
                    iconSize: 24,
                    color: Colors.white,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_rounded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    alignment: Alignment.centerLeft,
                  ),

                  // 右侧按钮组
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        iconSize: 24,
                        color: Colors.white,
                        onPressed: () {},
                        icon: const Icon(Icons.share_rounded),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建视频信息区域
  ///
  /// 精确还原原型设计：/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/LongVideoPage.tsx
  /// - px-4 py-4
  /// - 标题：text-lg font-semibold text-white
  /// - 次要信息：text-sm text-slate-400（播放次数、时长）
  Widget _buildVideoInfo() {
    if (_currentVideo == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.5), // slate-900/50
        border: Border(
          bottom: BorderSide(
            color: const Color(0x4D2D3548), // slate-800/30
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 标题
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentVideo!.title,
                  style: const TextStyle(
                    fontSize: 18, // text-lg
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (_currentVideo!.views != null) ...[
                      Text(
                        '${_currentVideo!.views}次播放',
                        style: const TextStyle(
                          fontSize: 14, // text-sm
                          color: Color(0xFF94A3B8), // text-slate-400
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Text(
                      _currentVideo!.durationFormatted,
                      style: const TextStyle(
                        fontSize: 14, // text-sm
                        color: Color(0xFF94A3B8), // text-slate-400
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 中间播放按钮
  ///
  /// 显示条件：
  /// - 控制栏可见 且 (正在暂停 或 播放结束)
  /// - 播放结束时始终显示
  Widget _buildCenterPlayButton() {
    // 切换视频期间不显示播放按钮
    if (_isSwitchingVideo) {
      return const SizedBox.shrink();
    }

    // 在以下情况显示中央播放按钮：
    // 控制栏可见时显示（用于切换播放/暂停）
    final shouldShow = _isControlBarVisible;

    // 使用 AnimatedOpacity 实现淡入淡出效果，而不是提前返回
    // 这样可以确保动画效果正常播放
    return Positioned.fill(
      child: Center(
        child: AnimatedOpacity(
          opacity: shouldShow ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: IgnorePointer(
            ignoring: !shouldShow,
            child: GestureDetector(
              onTap: () {
                // 中央按钮点击直接切换播放/暂停
                if (_isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isEnded
                      ? Icons.replay_rounded
                      : _isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 重播界面（播放结束时显示）
  Widget _buildReplayOverlay() {
    if (!_isEnded) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.3),
              Colors.black.withValues(alpha: 0.5),
            ],
          ),
        ),
        child: Center(
          child: GestureDetector(
            onTap: () {
              // 重播 - 使用 replay 方法清除进度并从头播放
              setState(() => _isEnded = false);
              _controller.replay();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 刷新图标
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                // 重播文案
                const Text(
                  '重播',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建横屏模式控制层
  ///
  /// 包含：顶部栏、右侧弹幕栏、底部控制栏、左侧锁定栏
  Widget _buildLandscapeControls() {
    // 切换视频期间不显示控制条
    if (_isSwitchingVideo) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Stack(
        children: [
          // 锁定状态下的解锁按钮
          // 注意：锁定状态下解锁按钮始终可见且可点击
          if (_isLocked) _buildLandscapeLeftBarLocked(),

          // 非锁定状态下的控制栏
          if (!_isLocked)
            IgnorePointer(
              ignoring: !_isControlBarVisible,
              child: AnimatedOpacity(
                opacity: _isControlBarVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Stack(
                  children: [
                    // 顶部栏
                    _buildLandscapeTopBar(),

                    // 右侧弹幕栏
                    _buildLandscapeRightBar(),

                    // 底部控制栏
                    _buildLandscapeBottomBar(),

                    // 左侧锁定按钮 (用于锁定)
                    _buildLandscapeLeftBarUnlocked(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 横屏左侧锁定栏 (未锁定状态 - 显示解锁图标用于点击锁定)
  ///
  /// 注意：原型中 icon 是 Unlock，点击变成 Lock 状态
  Widget _buildLandscapeLeftBarUnlocked() {
    return Positioned(
      left: 16,
      top: 0,
      bottom: 0,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.lock_open_rounded, color: Colors.white70),
            onPressed: () {
              setState(() {
                _isLocked = true;
              });
              // 锁定后隐藏控制条
              _controlBarStateMachine.enterHidden();
              _showSnackBar('屏幕已锁定');
            },
          ),
        ),
      ),
    );
  }

  /// 横屏左侧锁定栏 (锁定状态 - 显示锁定图标用于点击解锁)
  Widget _buildLandscapeLeftBarLocked() {
    // 锁定状态下，通常点击屏幕会显示锁定按钮，再次点击锁定按钮才解锁
    // 这里简化为：总是显示锁定按钮，点击解锁
    return Positioned(
      left: 16,
      top: 0,
      bottom: 0,
      child: Center(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _isLocked = false;
            });
            // 解锁后显示控制条，3秒后自动隐藏
            _controlBarStateMachine.enterActive(
              autoHideTimeout: const Duration(seconds: 3),
            );
            _showSnackBar('屏幕已解锁');
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded, color: Colors.white),
          ),
        ),
      ),
    );
  }

  /// 横屏顶部栏
  Widget _buildLandscapeTopBar() {
    // 获取安全区域内边距（顶部安全区域，如刘海屏）
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8 + topPadding,
          bottom: 8,
        ),
        child: Row(
          children: [
            // 返回按钮
            _buildBackButton(),
            const SizedBox(width: 8),
            // 标题（动态显示当前视频标题，限制最大宽度）
            Expanded(
              child: Text(
                _currentVideo?.title ?? '视频',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            // 更多按钮
            _buildMoreButton(),
          ],
        ),
      ),
    );
  }

  /// 返回按钮
  Widget _buildBackButton() {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_rounded,
          color: Colors.white,
          size: 24,
        ),
        padding: EdgeInsets.zero,
        onPressed: _exitFullscreen,
      ),
    );
  }

  /// 更多按钮
  Widget _buildMoreButton() {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        icon: const Icon(
          Icons.more_horiz_rounded,
          color: Colors.white,
          size: 24,
        ),
        padding: EdgeInsets.zero,
        onPressed: () {
          SettingsMenu.show(
            context: context,
            controller: _controller,
            videoTitle: _currentVideo?.title,
            videoThumbnail: _currentVideo?.thumbnail,
            downloadCallbacks: this,
          );
        },
      ),
    );
  }

  /// 横屏右侧弹幕控制栏
  Widget _buildLandscapeRightBar() {
    return Positioned(
      right: 16,
      top: 0,
      bottom: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 弹幕开关
            Container(
              decoration: BoxDecoration(
                color: _danmakuSettings.enabled
                    ? PlayerColors.primary.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.subtitles_outlined,
                  color: _danmakuSettings.enabled
                      ? Colors.white
                      : Colors.white70,
                ),
                onPressed: () {
                  setState(() => _danmakuSettings.toggle());
                },
              ),
            ),
            const SizedBox(height: 16),
            // 发弹幕按钮
            GestureDetector(
              onTap: _showDanmakuInputOverlay,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '发弹幕',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 横屏底部控制栏
  Widget _buildLandscapeBottomBar() {
    // 获取安全区域内边距
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 12 + bottomPadding,
          top: 40,
        ),
        child: Row(
          children: [
            _buildPlayPauseButton(),
            const SizedBox(width: 8),
            // Time
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Text(
                  '${_formatTime(_controller.state.position)} / ${_formatTime(_controller.state.duration)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
            const SizedBox(width: 16),
            // Progress
            Expanded(child: _VideoProgressBar(controller: _controller)),
            const SizedBox(width: 16),
            // 字幕开关（横屏显示）
            SubtitleToggle(controller: _controller),
            const SizedBox(width: 8),
            // Fullscreen toggle
            _buildFullscreenButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitMoreButton() {
    if (_isSwitchingVideo || !_isControlBarVisible) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 8,
      right: 8,
      child: IconButton(
        icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
        onPressed: () {
          SettingsMenu.show(
            context: context,
            controller: _controller,
            videoTitle: _currentVideo?.title,
            videoThumbnail: _currentVideo?.thumbnail,
            downloadCallbacks: this,
          );
        },
      ),
    );
  }

  /// 显示全屏弹幕输入覆盖层
  void _showDanmakuInputOverlay() {
    if (!_controller.state.isPrepared) {
      _showSnackBar('播放器未就绪');
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: DanmakuInputOverlay(
              onSend: (text, color) => _handleSendDanmakuDirect(text, color),
              onClose: () {
                Navigator.of(context).pop();
              },
              isLoading: _isSendingDanmaku,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        icon: Icon(
          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 28,
        ),
        padding: EdgeInsets.zero,
        onPressed: () {
          if (_isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
        },
      ),
    );
  }

  Widget _buildFullscreenButton() {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        icon: Icon(
          _isFullscreen
              ? Icons.fullscreen_exit_rounded
              : Icons.fullscreen_rounded,
          color: Colors.white,
          size: 24,
        ),
        padding: EdgeInsets.zero,
        onPressed: _toggleFullscreen,
      ),
    );
  }

  Future<void> _toggleFullscreen() async {
    if (_isFullscreen) {
      // 退出全屏
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      // 进入全屏
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }

    if (mounted) {
      setState(() {
        _isFullscreen = !_isFullscreen;
        // Reset locked state when toggling
        _isLocked = false;
      });
      // 切换全屏后进入被动模式
      _controlBarStateMachine.enterPassive();
    }
  }

  Future<void> _exitFullscreen() async {
    if (_isFullscreen) {
      await _toggleFullscreen();
    } else {
      Navigator.pop(context);
    }
  }

  /// 构建底部控制栏 (竖屏模式)
  Widget _buildBottomControls({bool isFullscreen = false}) {
    // 切换视频期间不显示控制条
    if (_isSwitchingVideo || !_isControlBarVisible) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: !_isControlBarVisible,
        child: AnimatedOpacity(
          opacity: _isControlBarVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // 点击控制栏：如果正在播放，重启隐藏计时器
              if (_isPlaying) {
                _controlBarStateMachine.enterActive(
                  autoHideTimeout: const Duration(seconds: 3),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 0,
                bottom: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 进度条
                  SizedBox(
                    height: 20,
                    child: _VideoProgressBar(controller: _controller),
                  ),

                  const SizedBox(height: 4),

                  // 播放控制按钮行
                  Row(
                    children: [
                      // 播放/暂停按钮
                      _buildPlayPauseButton(),

                      const SizedBox(width: 8),

                      // 时间显示
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          return Text(
                            '${_formatTime(_controller.state.position)} / ${_formatTime(_controller.state.duration)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          );
                        },
                      ),

                      const Spacer(),

                      // 字幕开关（竖屏显示，与横屏一致）
                      SubtitleToggle(controller: _controller),

                      const SizedBox(width: 8),

                      // 弹幕开关与设置按钮
                      DanmakuToggle(settings: _danmakuSettings),

                      const SizedBox(width: 8),

                      // 全屏按钮
                      _buildFullscreenButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 直接在控制条中发送弹幕（横屏模式）
  Future<void> _handleSendDanmakuDirect(String text, String color) async {
    if (_isSendingDanmaku) return;

    final currentVid = _currentVideo?.vid;
    if (currentVid == null) {
      _showSnackBar('视频信息未加载');
      return;
    }

    setState(() => _isSendingDanmaku = true);

    try {
      // 获取当前播放时间
      final currentTime = _controller.state.position;

      // 构建发送请求
      final request = DanmakuSendRequest(
        vid: currentVid,
        text: text,
        time: currentTime,
        color: color,
      );

      // 发送弹幕
      final service = _danmakuSendService;
      if (service == null) {
        _showSnackBar('弹幕服务未初始化');
        return;
      }
      final response = await service.sendDanmaku(request);

      if (response.success && mounted) {
        // 创建新弹幕并添加到列表
        final newDanmaku = Danmaku(
          id:
              response.danmakuId ??
              'local_${DateTime.now().millisecondsSinceEpoch}',
          text: text,
          time: currentTime,
          color: _parseColor(color),
        );

        setState(() {
          _danmakus = [..._danmakus, newDanmaku];
        });

        if (mounted) {
          _showSnackBar('弹幕发送成功');
        }
      }
    } on DanmakuSendException catch (e) {
      if (mounted) {
        _showSnackBar(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('发送失败，请重试');
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingDanmaku = false);
      }
    }
  }

  /// 解析颜色字符串为 Color 对象
  int? _parseColor(String colorStr) {
    if (!colorStr.startsWith('#')) return null;
    try {
      final value = int.parse(colorStr.substring(1), radix: 16);
      return 0xFF000000 | value;
    } catch (_) {
      return null;
    }
  }

  /// 显示 SnackBar 提示
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 格式化时间：毫秒 → MM:SS 或 HH:MM:SS
  String _formatTime(int ms) {
    if (ms <= 0) return '00:00';

    final seconds = ms ~/ 1000;
    final mins = seconds ~/ 60;
    final secs = seconds % 60;

    if (mins >= 60) {
      final hours = mins ~/ 60;
      final remainingMins = mins % 60;
      return '$hours:${remainingMins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}

/// 视频进度条组件
///
/// 精确还原原型设计：灰色轨道 + 红色进度点
class _VideoProgressBar extends StatefulWidget {
  final PlayerController controller;

  const _VideoProgressBar({required this.controller});

  @override
  State<_VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<_VideoProgressBar> {
  double _dragValue = 0.0;
  bool _isDragging = false;
  int _dragEndFrame = 0; // 拖动结束后的冷却期帧数
  DateTime? _seekStartTime;
  double _lastDisplayValue = 0.0; // 上一帧用于展示的进度值（0.0 - 1.0）
  DateTime? _lastProgressUpdateTime; // 上一次进度更新的时间

  @override
  Widget build(BuildContext context) {
    // 冷却期递减
    if (_dragEndFrame > 0 && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _dragEndFrame--;
          });
        }
      });
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final progress = widget.controller.state.progress;
          final bufferProgress = widget.controller.state.bufferProgress;
          final clampedProgress = progress.clamp(0.0, 1.0);
          final now = DateTime.now();
          final isInSeekHold =
              _seekStartTime != null &&
              now.difference(_seekStartTime!) <
                  const Duration(milliseconds: 600);

          // 拖动期间或冷却期内使用拖动值，否则使用实际进度
          double displayValue;
          if (_isDragging || _dragEndFrame > 0) {
            displayValue = _dragValue;
          } else if (isInSeekHold &&
              (clampedProgress - _dragValue).abs() > 0.02) {
            // 拖动结束后的短暂时间窗口内，如果原生回调的进度小于目标拖动值
            //（例如先回到 0% 再跳到目标位置），则继续使用拖动目标值，避免 UI 闪烁
            displayValue = _dragValue;
          } else {
            // 额外保护：在短时间内出现大幅度回退（例如从 50% 突然回到 0%），
            // 视为异常进度更新（常见于 Android 切换清晰度时播放器内部重置），
            // 此时继续使用上一帧的进度，避免进度条从头再跳回当前。
            bool isSuspiciousBackwardJump = false;
            if (_lastProgressUpdateTime != null) {
              final dt = now.difference(_lastProgressUpdateTime!);
              final durationMs = widget.controller.state.duration;
              final last = _lastDisplayValue;

              // 只在 2 秒内的更新中检查，且总时长有效
              if (dt < const Duration(seconds: 2) && durationMs > 0) {
                final deltaMs = (last - clampedProgress).abs() * durationMs;
                // 检测是否是重播操作：如果新进度接近 0%，说明是合法的重播/seek到开头
                final isReplayToStart = clampedProgress < 0.01;
                if (clampedProgress < last && deltaMs > 1000 && !isReplayToStart) {
                  isSuspiciousBackwardJump = true;
                }
              }
            }

            displayValue = isSuspiciousBackwardJump
                ? _lastDisplayValue
                : clampedProgress;
          }

          _lastDisplayValue = displayValue;
          _lastProgressUpdateTime = now;

          return SliderTheme(
            data: SliderThemeData(
              // 已播放进度颜色 - 与 progress_slider.dart 保持一致
              activeTrackColor: const Color(0xFFE8704D),
              // 未播放进度颜色（背景）
              inactiveTrackColor: const Color(0xFF2D3548),
              // 缓冲进度颜色
              secondaryActiveTrackColor: const Color(0xFF3D4560),
              // 拖动手柄颜色
              thumbColor: const Color(0xFFE8704D),
              // 按下时的阴影
              overlayColor: const Color(0x33E8704D),
              // 轨道高度
              trackHeight: 2,
              // 手柄形状和大小 - 圆点
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              // 轨道形状 - 去除默认内边距
              trackShape: const RectangularSliderTrackShape(),
              // 不显示数值指示器
              showValueIndicator: ShowValueIndicator.never,
              // 叠加轨道
              overlappingShapeStrokeColor: Colors.transparent,
            ),
            child: Slider(
              value: displayValue,
              secondaryTrackValue: bufferProgress.clamp(0.0, 1.0),
              max: 1.0,
              // 拖动开始
              onChangeStart: (_) {
                setState(() {
                  _isDragging = true;
                  _seekStartTime = null;
                });
              },
              // 拖动中：只更新本地状态，不触发 seek
              onChanged: (value) {
                setState(() => _dragValue = value);
              },
              // 拖动结束：执行 seek
              onChangeEnd: (value) {
                setState(() {
                  _dragValue = value;
                  _isDragging = false; // 立即结束拖动状态
                  _dragEndFrame = 2; // 设置2帧冷却期
                  _seekStartTime = DateTime.now();
                });
                final pos = (value * widget.controller.state.duration).toInt();
                widget.controller.seekTo(pos);
              },
            ),
          );
        },
      ),
    );
  }
}
