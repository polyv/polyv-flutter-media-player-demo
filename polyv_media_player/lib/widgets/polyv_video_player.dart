import 'package:flutter/material.dart';
import '../core/player_controller.dart';
import '../core/player_state.dart';
import '../infrastructure/danmaku/danmaku_model.dart';
import '../infrastructure/danmaku/danmaku_service.dart';
import '../services/polyv_config_service.dart';
import 'polyv_video_view.dart';
import '../ui/player_colors.dart';
import '../ui/control_bar_state_machine.dart';
import '../ui/gestures/player_gesture_controller.dart';
import '../ui/gestures/player_gesture_detector.dart';
import '../ui/danmaku/danmaku_layer.dart';
import '../ui/danmaku/danmaku_settings.dart';
import '../ui/danmaku/danmaku_toggle.dart';
import '../ui/danmaku/danmaku_input_overlay.dart';
import '../ui/subtitle_toggle.dart';

/// PolyvVideoPlayer - 开箱即用的全功能视频播放器组件
///
/// 封装了 PlayerController、PolyvVideoView 和所有控制组件，提供简单的 API。
/// 支持弹幕、手势、控制栏自动隐藏等功能。
///
/// ## 基础用法
///
/// ```dart
/// PolyvVideoPlayer(vid: 'your_video_id')
/// ```
///
/// ## 自定义配置
///
/// ```dart
/// PolyvVideoPlayer(
///   vid: 'your_video_id',
///   autoPlay: true,
///   enableDanmaku: true,
///   enableGestures: true,
///   showControls: true,
///   aspectRatio: 16 / 9,
/// )
/// ```
///
/// ## 使用弹幕服务
///
/// ```dart
/// PolyvVideoPlayer(
///   vid: 'your_video_id',
///   danmakuService: myDanmakuService,
///   onDanmakuSend: (text, color) async {
///     // 发送弹幕到服务器
///   },
/// )
/// ```
class PolyvVideoPlayer extends StatefulWidget {
  /// 视频 VID
  final String vid;

  /// 是否自动播放
  final bool autoPlay;

  /// 是否显示控制栏
  final bool showControls;

  /// 是否启用弹幕功能
  final bool enableDanmaku;

  /// 是否启用手势功能（滑动 seek）
  final bool enableGestures;

  /// 是否启用双击全屏
  final bool enableDoubleTapFullscreen;

  /// 控制栏自动隐藏时长（默认 3 秒）
  final Duration autoHideDuration;

  /// 视频宽高比（默认 16:9）
  final double aspectRatio;

  /// 背景颜色
  final Color backgroundColor;

  /// 播放器控制器（可选，用于外部控制）
  ///
  /// 如果不提供，会自动创建一个内部控制器
  final PlayerController? controller;

  /// 弹幕服务（可选）
  ///
  /// 如果不提供，弹幕功能将不可用（但不影响其他功能）
  final DanmakuService? danmakuService;

  /// 弹幕设置（可选）
  ///
  /// 如果不提供，会自动创建一个内部设置对象
  final DanmakuSettings? danmakuSettings;

  /// 弹幕发送回调（可选）
  ///
  /// 当用户发送弹幕时触发
  final Future<void> Function(String text, String color)? onDanmakuSend;

  /// 全屏切换回调（可选）
  ///
  /// 当用户双击触发全屏切换时调用
  final ValueChanged<bool>? onFullscreenChanged;

  /// 是否为全屏模式
  ///
  /// 为 true 时显示全屏布局（顶部栏、锁屏、弹幕发送等）
  final bool isFullscreen;

  /// 是否显示锁屏按钮（仅全屏模式生效）
  final bool showLockButton;

  /// 是否显示弹幕发送按钮（仅全屏模式生效）
  final bool showDanmakuSend;

  /// 是否显示全屏顶部栏
  final bool showTopBar;

  /// 视频标题（用于全屏顶部栏显示）
  final String? videoTitle;

  /// 弹幕发送服务（可选）
  ///
  /// 如果提供，弹幕发送功能将可用
  final DanmakuSendService? danmakuSendService;

  /// 返回按钮回调
  final VoidCallback? onBack;

  /// 更多按钮回调
  final VoidCallback? onMoreTap;

  /// 视频加载完成回调
  final VoidCallback? onLoaded;

  /// 播放状态变化回调
  final ValueChanged<bool>? onPlayingChanged;

  /// 播放完成回调
  final VoidCallback? onCompleted;

  /// 播放错误回调
  final ValueChanged<String>? onError;

  /// 视频视图的 key seed，用于强制重建视频视图
  ///
  /// 当这个值改变时，视频视图会被完全重建，清除旧画面
  final Object? videoViewKeySeed;

  /// 弹幕显示区域高度因子（0.0 - 1.0，默认 0.6）
  ///
  /// 仅使用上层区域显示弹幕，避免与底部控制栏重叠
  final double danmakuHeightFactor;

  const PolyvVideoPlayer({
    super.key,
    required this.vid,
    this.autoPlay = true,
    this.showControls = true,
    this.enableDanmaku = true,
    this.enableGestures = true,
    this.enableDoubleTapFullscreen = true,
    this.autoHideDuration = const Duration(seconds: 3),
    this.aspectRatio = 16 / 9,
    this.backgroundColor = Colors.black,
    this.controller,
    this.danmakuService,
    this.danmakuSettings,
    this.onDanmakuSend,
    this.onFullscreenChanged,
    this.isFullscreen = false,
    this.showLockButton = false,
    this.showDanmakuSend = false,
    this.showTopBar = false,
    this.videoTitle,
    this.danmakuSendService,
    this.onBack,
    this.onMoreTap,
    this.onLoaded,
    this.onPlayingChanged,
    this.onCompleted,
    this.onError,
    this.videoViewKeySeed,
    this.danmakuHeightFactor = 0.6,
  });

  @override
  State<PolyvVideoPlayer> createState() => _PolyvVideoPlayerState();
}

class _PolyvVideoPlayerState extends State<PolyvVideoPlayer> {
  late final PlayerController _controller;
  late final ControlBarStateMachine _controlBarStateMachine;
  late final PlayerGestureController _gestureController;
  late final DanmakuSettings _danmakuSettings;

  bool _isControllerOwned = false;
  bool _isDanmakuSettingsOwned = false;
  bool _isLoaded = false;
  bool _isPlaying = false;
  bool _isEnded = false;
  String? _error;

  /// 弹幕数据
  List<Danmaku> _danmakus = [];

  /// 锁屏状态
  bool _isLocked = false;

  /// 弹幕发送中
  bool _isSendingDanmaku = false;

  /// 内部创建的弹幕服务
  DanmakuService? _ownedDanmakuService;

  /// 内部创建的弹幕发送服务
  DanmakuSendService? _ownedDanmakuSendService;

  @override
  void initState() {
    super.initState();

    // 初始化控制器
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = PlayerController();
      _isControllerOwned = true;
    }

    // 初始化控制栏状态机
    _controlBarStateMachine = ControlBarStateMachine(
      autoHideDuration: widget.autoHideDuration,
    );

    // 初始化手势控制器
    _gestureController = PlayerGestureController();

    // 初始化弹幕设置
    if (widget.danmakuSettings != null) {
      _danmakuSettings = widget.danmakuSettings!;
    } else {
      _danmakuSettings = DanmakuSettings();
      _isDanmakuSettingsOwned = true;
    }

    // 自动初始化弹幕服务
    _initializeDanmakuServices();

    _controller.addListener(_onPlayerStateChanged);
    _loadVideo();
  }

  /// 自动初始化弹幕服务
  Future<void> _initializeDanmakuServices() async {
    // 如果已提供外部服务，无需初始化
    if (widget.danmakuService != null && widget.danmakuSendService != null) {
      return;
    }

    // 只有在启用弹幕功能时才初始化
    if (!widget.enableDanmaku && !widget.showDanmakuSend) {
      return;
    }

    try {
      final config = await PolyvConfigService().getConfig();

      // 自动创建弹幕服务
      if (widget.danmakuService == null && widget.enableDanmaku) {
        _ownedDanmakuService = DanmakuServiceFactory.createHttp(
          userId: config.userId,
          readToken: config.readToken,
          secretKey: config.secretKey,
        );
      }

      // 自动创建弹幕发送服务
      if (widget.danmakuSendService == null && widget.showDanmakuSend) {
        _ownedDanmakuSendService = DanmakuSendServiceFactory.createHttp(
          userId: config.userId,
          writeToken: config.writeToken,
          secretKey: config.secretKey,
        );
      }
    } catch (e) {
      debugPrint(
        'PolyvVideoPlayer: Failed to auto-initialize danmaku services: $e',
      );
    }
  }

  @override
  void didUpdateWidget(PolyvVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果 VID 变化，重新加载视频
    if (oldWidget.vid != widget.vid) {
      // 立即隐藏控制条，防止闪烁
      _controlBarStateMachine.enterHidden();
      setState(() {
        _isLoaded = false;
      });
      // 延迟加载，等待外部黑色遮罩渲染完成
      _loadVideoWithDelay();
    }
  }

  /// 延迟加载视频，等待黑色遮罩渲染完成
  Future<void> _loadVideoWithDelay() async {
    // 等待黑色遮罩渲染完成
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      await _loadVideo();
    }
  }

  Future<void> _loadVideo() async {
    if (!mounted) return;

    // 如果 VID 为空，不尝试加载视频
    if (widget.vid.isEmpty) {
      return;
    }

    // 如果控制器已经加载了相同的视频，跳过重新加载（例如全屏切换时）
    // 这样可以避免视频重新加载导致的卡顿
    if (_controller.state.vid == widget.vid && _controller.state.isPrepared) {
      // 从控制器同步当前状态
      final isCompleted = _controller.state.loadingState == PlayerLoadingState.completed;
      setState(() {
        _isLoaded = true;
        _error = null;
        _isEnded = isCompleted;
        _isPlaying = _controller.effectiveIsPlaying;
      });
      return;
    }

    // 进入隐藏模式
    _controlBarStateMachine.enterHidden();

    setState(() {
      _isLoaded = false;
      _error = null;
      _isEnded = false;
      _isLocked = false;
    });

    try {
      await _controller.loadVideo(widget.vid, autoPlay: widget.autoPlay);

      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
        widget.onLoaded?.call();

        // 视频加载完成，保持隐藏模式
        // 控制条只在用户点击时才显示
        // _controlBarStateMachine.enterPassive();
      }

      // 加载弹幕数据
      if (widget.enableDanmaku) {
        final service = widget.danmakuService ?? _ownedDanmakuService;
        if (service != null) {
          _loadDanmakus(service);
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        setState(() {
          _error = errorMsg;
        });
        widget.onError?.call(errorMsg);
      }
    }
  }

  Future<void> _loadDanmakus(DanmakuService service) async {
    try {
      final danmakus = await service.fetchDanmakus(widget.vid);
      if (mounted) {
        setState(() {
          _danmakus = danmakus;
        });
      }
    } catch (e) {
      // 弹幕加载失败不影响视频播放
      debugPrint('Failed to load danmakus: $e');
    }
  }

  void _onPlayerStateChanged() {
    final state = _controller.state;
    final isPlaying = _controller.effectiveIsPlaying;
    final isCompleted = state.loadingState == PlayerLoadingState.completed;

    // 检测播放结束
    if (isCompleted && !_isEnded) {
      setState(() {
        _isEnded = true;
        _isPlaying = false;
      });
      _controlBarStateMachine.enterHidden();
      // 重置播放进度到开头，避免下次进入时直接结束
      _controller.seekTo(0);
      widget.onCompleted?.call();
      return;
    }

    // 同步播放状态（需要 setState 来更新控制条显示）
    if (_isPlaying != isPlaying) {
      setState(() {
        _isPlaying = isPlaying;
      });
      widget.onPlayingChanged?.call(isPlaying);
    }

    // 更新手势控制器的时长
    if (state.duration > 0) {
      _gestureController.setDuration(state.duration);
      _gestureController.updateSeekProgress(state.progress);
    }

    // 检查错误
    if (state.hasError && state.errorMessage != null) {
      widget.onError?.call(state.errorMessage!);
    }
  }

  void _handleTap() {
    if (widget.showControls) {
      _controlBarStateMachine.toggle(isPlaying: _isPlaying);
    }
  }

  void _handleDoubleTap() {
    // 竖屏双击：暂停/播放视频（不再触发全屏）
    if (_controller.state.isPrepared) {
      // 使用 effectiveIsPlaying 获取更准确的播放状态
      final isPlaying = _controller.effectiveIsPlaying;
      if (isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    }
  }

  // ==================== 全屏模式功能 ====================

  /// 锁屏
  void _lockScreen() {
    _controlBarStateMachine.enterHidden();
    setState(() => _isLocked = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: const Text('屏幕已锁定'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 解锁屏幕
  void _unlockScreen() {
    setState(() => _isLocked = false);
    _controlBarStateMachine.enterPassive();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: const Text('屏幕已解锁'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 显示弹幕发送覆盖层
  void _showDanmakuInputOverlay() {
    if (!_controller.state.isPrepared) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: DanmakuInputOverlay(
              onSend: (text, color) => _handleSendDanmaku(text, color),
              onClose: () => Navigator.of(context).pop(),
              isLoading: _isSendingDanmaku,
            ),
          );
        },
      ),
    );
  }

  /// 发送弹幕
  Future<void> _handleSendDanmaku(String text, String color) async {
    if (_isSendingDanmaku) return;

    final vid = widget.vid;
    if (vid.isEmpty) return;

    setState(() => _isSendingDanmaku = true);

    try {
      final currentTime = _controller.state.position;
      final request = DanmakuSendRequest(
        vid: vid,
        text: text,
        time: currentTime,
        color: color,
      );

      final service = widget.danmakuSendService ?? _ownedDanmakuSendService;
      if (service == null) return;

      final response = await service.sendDanmaku(request);

      if (response.success && mounted) {
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

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('弹幕发送成功'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to send danmaku: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is DanmakuSendException ? e.message : '发送失败，请重试'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingDanmaku = false);
    }
  }

  int? _parseColor(String colorStr) {
    if (!colorStr.startsWith('#')) return null;
    try {
      final value = int.parse(colorStr.substring(1), radix: 16);
      return 0xFF000000 | value;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlayerStateChanged);
    _controlBarStateMachine.dispose();
    _gestureController.dispose();

    if (_isControllerOwned) {
      _controller.dispose();
    }

    if (_isDanmakuSettingsOwned) {
      _danmakuSettings.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 全屏模式
    if (widget.isFullscreen) {
      return _buildFullscreenMode();
    }

    // 普通模式
    return Container(
      color: widget.backgroundColor,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Stack(
          children: [
            // 1. 视频视图（不启用手势时包含点击处理）
            _buildVideoView(),

            // 2. 手势检测层（覆盖整个区域，仅在启用手势时添加）
            if (widget.enableGestures && !_isEnded)
              Positioned.fill(
                child: PlayerGestureDetector(
                  gestureController: _gestureController,
                  playerController: _controller,
                  onTap: _handleTap,
                  onDoubleTap: _handleDoubleTap,
                  isLocked: _isLocked,
                  child: const SizedBox.shrink(),
                ),
              ),

            // 3. 弹幕层（可选）
            if (widget.enableDanmaku && _isLoaded)
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  return DanmakuLayer(
                    enabled: _danmakuSettings.enabled,
                    opacity: _danmakuSettings.opacity,
                    fontSize: _danmakuSettings.fontSize,
                    currentTime: _controller.state.position,
                    danmakus: _danmakus,
                    heightFactor: widget.danmakuHeightFactor,
                  );
                },
              ),

            // 3. 加载状态
            if (!_isLoaded && _error == null)
              const Center(
                child: CircularProgressIndicator(color: PlayerColors.progress),
              ),

            // 4. 错误状态
            if (_error != null) _buildErrorWidget(),

            // 5. 重播界面（视频播放结束时显示）
            if (_isEnded) _buildReplayOverlay(),

            // 6. 控制栏（带自动隐藏）
            if (widget.showControls && _isLoaded)
              ListenableBuilder(
                listenable: _controlBarStateMachine,
                builder: (context, _) {
                  final isVisible = _controlBarStateMachine.isVisible(
                    _isPlaying,
                  );
                  return AnimatedOpacity(
                    opacity: isVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !isVisible,
                      child: GestureDetector(
                        // 点击控制栏区域时，隐藏控制栏（但让按钮点击优先）
                        onTap: _handleTap,
                        behavior: HitTestBehavior.deferToChild,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _buildControlBar(),
                        ),
                      ),
                    ),
                  );
                },
              ),

            // 7. 更多按钮（竖屏模式，右上角）
            if (widget.showControls && widget.onMoreTap != null && _isLoaded)
              ListenableBuilder(
                listenable: _controlBarStateMachine,
                builder: (context, _) {
                  final isVisible = _controlBarStateMachine.isVisible(_isPlaying);
                  if (!isVisible) return const SizedBox.shrink();

                  return Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
                      onPressed: widget.onMoreTap,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  /// 构建全屏模式
  Widget _buildFullscreenMode() {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 视频视图
          PolyvVideoView(keySeed: widget.videoViewKeySeed),

          // 2. 手势检测层（覆盖整个区域，仅在未锁定时添加）
          if (!_isLocked && widget.enableGestures && !_isEnded)
            Positioned.fill(
              child: PlayerGestureDetector(
                gestureController: _gestureController,
                playerController: _controller,
                onTap: () {
                  _controlBarStateMachine.toggle(isPlaying: _isPlaying);
                },
                onDoubleTap: () {
                  if (_isPlaying) {
                    _controller.pause();
                  } else {
                    _controller.play();
                  }
                },
                isLocked: false,
                child: const SizedBox.shrink(),
              ),
            ),

          // 3. 锁定时的点击处理（只显示解锁按钮）
          if (_isLocked)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  _controlBarStateMachine.enterActive();
                },
                behavior: HitTestBehavior.translucent,
                child: const SizedBox.shrink(),
              ),
            ),

          // 4. 弹幕层
          if (widget.enableDanmaku && _isLoaded)
            ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return DanmakuLayer(
                  enabled: _danmakuSettings.enabled,
                  opacity: _danmakuSettings.opacity,
                  fontSize: _danmakuSettings.fontSize,
                  currentTime: _controller.state.position,
                  danmakus: _danmakus,
                  heightFactor: widget.danmakuHeightFactor,
                );
              },
            ),

          // 5. 加载状态
          if (!_isLoaded && _error == null)
            const Center(
              child: CircularProgressIndicator(color: PlayerColors.progress),
            ),

          // 6. 错误状态
          if (_error != null) _buildErrorWidget(),

          // 7. 重播界面
          if (_isEnded) _buildReplayOverlay(),

          // 8. 锁定状态：只显示解锁按钮
          if (_isLocked) _buildLockedOverlay(),

          // 9. 未锁定状态：显示完整控制层
          if (!_isLocked && widget.showControls && _isLoaded)
            ListenableBuilder(
              listenable: _controlBarStateMachine,
              builder: (context, _) {
                final isVisible = _controlBarStateMachine.isVisible(_isPlaying);
                return AnimatedOpacity(
                  opacity: isVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !isVisible,
                    child: Stack(
                      children: [
                        // 顶部栏
                        if (widget.showTopBar)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: _buildFullscreenTopBar(topPadding),
                          ),

                        // 底部栏
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _buildFullscreenBottomBar(bottomPadding),
                        ),

                        // 锁屏按钮
                        if (widget.showLockButton) _buildLockButton(),

                        // 弹幕发送按钮
                        if (widget.showDanmakuSend &&
                            widget.danmakuSendService != null)
                          _buildDanmakuSendButton(),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// 全屏顶部栏
  Widget _buildFullscreenTopBar(double topPadding) {
    return Container(
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
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
                size: 24,
              ),
              padding: EdgeInsets.zero,
              onPressed: widget.onBack,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.videoTitle ?? '视频',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (widget.onMoreTap != null)
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                onPressed: widget.onMoreTap,
              ),
            ),
        ],
      ),
    );
  }

  /// 全屏底部栏
  Widget _buildFullscreenBottomBar(double bottomPadding) {
    return Container(
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
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return Text(
                '${_formatTime(_controller.state.position)} / ${_formatTime(_controller.state.duration)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(child: _buildFullscreenProgressBar()),
          const SizedBox(width: 16),
          SubtitleToggle(controller: _controller),
          const SizedBox(width: 8),
          _buildExitFullscreenButton(),
        ],
      ),
    );
  }

  /// 全屏进度条
  Widget _buildFullscreenProgressBar() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;
        return SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFFE8704D),
            inactiveTrackColor: const Color(0xFF2D3548),
            secondaryActiveTrackColor: const Color(0xFF3D4560),
            thumbColor: const Color(0xFFE8704D),
            overlayColor: const Color(0x33E8704D),
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            trackShape: const RectangularSliderTrackShape(),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
          ),
          child: Slider(
            value: state.progress.clamp(0.0, 1.0),
            secondaryTrackValue: state.bufferProgress.clamp(0.0, 1.0),
            max: 1.0,
            onChanged: (value) {
              final position = (value * state.duration).toInt();
              _controller.seekTo(position);
            },
          ),
        );
      },
    );
  }

  /// 退出全屏按钮
  Widget _buildExitFullscreenButton() {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        icon: const Icon(
          Icons.fullscreen_exit_rounded,
          color: Colors.white,
          size: 24,
        ),
        padding: EdgeInsets.zero,
        onPressed: widget.onBack,
      ),
    );
  }

  /// 锁定状态 overlay
  Widget _buildLockedOverlay() {
    return Positioned(
      left: 16,
      top: 0,
      bottom: 0,
      child: Center(
        child: GestureDetector(
          onTap: _unlockScreen,
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

  /// 锁屏按钮
  Widget _buildLockButton() {
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
            onPressed: _lockScreen,
          ),
        ),
      ),
    );
  }

  /// 弹幕发送按钮
  Widget _buildDanmakuSendButton() {
    return Positioned(
      right: 16,
      top: 0,
      bottom: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: _danmakuSettings.enabled
                    ? const Color(0xFF6366F1).withValues(alpha: 0.8)
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

  /// 重播界面
  Widget _buildReplayOverlay() {
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
              setState(() => _isEnded = false);
              _controller.replay();
              _controlBarStateMachine.enterPassive();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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

  Widget _buildVideoView() {
    // 视频视图现在只是 PolyvVideoView
    // 手势检测由 Stack 中的 PlayerGestureDetector 层处理（如果启用）
    // 如果不启用手势，需要在这里处理点击
    if (!widget.enableGestures) {
      return GestureDetector(
        onTap: _handleTap,
        onDoubleTap: widget.enableDoubleTapFullscreen
            ? () => widget.onFullscreenChanged?.call(true)
            : null,
        behavior: HitTestBehavior.translucent,
        child: PolyvVideoView(keySeed: widget.videoViewKeySeed),
      );
    }
    return PolyvVideoView(keySeed: widget.videoViewKeySeed);
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white54, size: 48),
          const SizedBox(height: 8),
          Text(
            '加载失败',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _loadVideo, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
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
      padding: const EdgeInsets.only(left: 12, right: 12, top: 0, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 进度条
          SizedBox(height: 20, child: _buildProgressBar()),

          const SizedBox(height: 4),

          // 播放控制按钮行
          Row(
            children: [
              // 播放/暂停按钮
              _buildPlayPauseButton(),

              const SizedBox(width: 8),

              // 时间显示 (00:00 / 00:00)
              ListenableBuilder(
                listenable: _controller,
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

              // 字幕开关
              SubtitleToggle(controller: _controller),

              const SizedBox(width: 8),

              // 弹幕开关（可选）
              if (widget.enableDanmaku)
                DanmakuToggle(settings: _danmakuSettings),

              const SizedBox(width: 8),

              // 全屏按钮
              _buildFullscreenButton(),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建进度条（与原版 long_video_page 样式一致）
  Widget _buildProgressBar() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final progress = _controller.state.progress;
        final bufferProgress = _controller.state.bufferProgress;
        final clampedProgress = progress.clamp(0.0, 1.0);

        return SliderTheme(
          data: SliderThemeData(
            // 已播放进度颜色
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
            // 手柄形状和大小
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            // 轨道形状
            trackShape: const RectangularSliderTrackShape(),
            // 不显示数值指示器
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: Slider(
            value: clampedProgress,
            secondaryTrackValue: bufferProgress.clamp(0.0, 1.0),
            max: 1.0,
            onChanged: (value) {
              final position = (value * _controller.state.duration).toInt();
              _controller.seekTo(position);
            },
          ),
        );
      },
    );
  }

  /// 构建全屏按钮
  Widget _buildFullscreenButton() {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        icon: const Icon(
          Icons.fullscreen_rounded,
          color: Colors.white,
          size: 24,
        ),
        padding: EdgeInsets.zero,
        onPressed: () => widget.onFullscreenChanged?.call(true),
      ),
    );
  }

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
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildPlayPauseButton() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final isPlaying = _controller.effectiveIsPlaying;
        final isPrepared = _controller.state.isPrepared;

        return SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            iconSize: 28,
            color: Colors.white,
            padding: EdgeInsets.zero,
            onPressed: isPrepared
                ? () {
                    if (isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  }
                : null,
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
          ),
        );
      },
    );
  }
}
