import 'package:flutter/material.dart';
import '../core/player_controller.dart';
import '../core/player_state.dart';
import '../core/player_events.dart';
import '../infrastructure/danmaku/danmaku_model.dart';
import '../infrastructure/danmaku/danmaku_service.dart';
import 'polyv_video_view.dart';
import '../ui/player_colors.dart';
import '../ui/control_bar_state_machine.dart';
import '../ui/gestures/player_gesture_controller.dart';
import '../ui/gestures/player_gesture_detector.dart';
import '../ui/danmaku/danmaku_layer.dart';
import '../ui/danmaku/danmaku_settings.dart';
import '../ui/danmaku/danmaku_toggle.dart';

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

  /// 视频加载完成回调
  final VoidCallback? onLoaded;

  /// 播放状态变化回调
  final ValueChanged<bool>? onPlayingChanged;

  /// 播放完成回调
  final VoidCallback? onCompleted;

  /// 播放错误回调
  final ValueChanged<String>? onError;

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
    this.onLoaded,
    this.onPlayingChanged,
    this.onCompleted,
    this.onError,
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
  String? _error;

  /// 弹幕数据
  List<Danmaku> _danmakus = [];

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

    _controller.addListener(_onPlayerStateChanged);
    _loadVideo();
  }

  @override
  void didUpdateWidget(PolyvVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果 VID 变化，重新加载视频
    if (oldWidget.vid != widget.vid) {
      _loadVideo();
    }
  }

  Future<void> _loadVideo() async {
    if (!mounted) return;

    // 进入隐藏模式
    _controlBarStateMachine.enterHidden();

    setState(() {
      _isLoaded = false;
      _error = null;
    });

    try {
      await _controller.loadVideo(widget.vid, autoPlay: widget.autoPlay);

      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
        widget.onLoaded?.call();

        // 视频加载完成，进入被动模式
        _controlBarStateMachine.enterPassive();
      }

      // 加载弹幕数据
      if (widget.enableDanmaku && widget.danmakuService != null) {
        _loadDanmakus();
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

  Future<void> _loadDanmakus() async {
    if (widget.danmakuService == null) return;

    try {
      final danmakus = await widget.danmakuService!.fetchDanmakus(widget.vid);
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

    if (_isPlaying != isPlaying) {
      _isPlaying = isPlaying;
      widget.onPlayingChanged?.call(isPlaying);
    }

    // 更新手势控制器的时长
    if (state.duration > 0) {
      _gestureController.setDuration(state.duration);
      _gestureController.updateSeekProgress(state.progress);
    }

    // 检查播放完成
    if (state.loadingState == PlayerLoadingState.completed) {
      widget.onCompleted?.call();
    }

    // 检查错误
    if (state.hasError && state.errorMessage != null) {
      widget.onError?.call(state.errorMessage!);
    }
  }

  void _handleTap() {
    if (widget.showControls) {
      _controlBarStateMachine.toggle();
    }
  }

  void _handleDoubleTap() {
    if (widget.enableDoubleTapFullscreen) {
      widget.onFullscreenChanged?.call(true);
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
    return Container(
      color: widget.backgroundColor,
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Stack(
          children: [
            // 1. 视频视图（带手势检测）
            _buildVideoView(),

            // 2. 弹幕层（可选）
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
                  );
                },
              ),

            // 3. 加载状态
            if (!_isLoaded && _error == null)
              const Center(
                child: CircularProgressIndicator(
                  color: PlayerColors.progress,
                ),
              ),

            // 4. 错误状态
            if (_error != null) _buildErrorWidget(),

            // 5. 控制栏（带自动隐藏）
            if (widget.showControls && _isLoaded)
              ListenableBuilder(
                listenable: _controlBarStateMachine,
                builder: (context, _) {
                  final isVisible = _controlBarStateMachine.isVisible(_isPlaying);
                  return AnimatedOpacity(
                    opacity: isVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !isVisible,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _buildControlBar(),
                      ),
                    ),
                  );
                },
              ),

            // 6. 中央播放按钮（暂停时显示）
            if (_isLoaded && !_isPlaying && _error == null)
              _buildCenterPlayButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoView() {
    if (widget.enableGestures) {
      return PlayerGestureDetector(
        gestureController: _gestureController,
        playerController: _controller,
        onTap: _handleTap,
        onDoubleTap: _handleDoubleTap,
        child: const PolyvVideoView(),
      );
    }

    // 不启用手势时，只处理点击
    return GestureDetector(
      onTap: _handleTap,
      onDoubleTap: widget.enableDoubleTapFullscreen
          ? () => widget.onFullscreenChanged?.call(true)
          : null,
      behavior: HitTestBehavior.translucent,
      child: const PolyvVideoView(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white54,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            '加载失败',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadVideo,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: PlayerColors.surface),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 进度条
          _buildProgressSlider(),

          const SizedBox(height: 12),

          // 播放控制按钮行
          Row(
            children: [
              // 播放/暂停按钮
              _buildPlayPauseButton(),

              const Spacer(),

              // 弹幕开关（可选）
              if (widget.enableDanmaku)
                DanmakuToggle(settings: _danmakuSettings),

              const SizedBox(width: 8),

              // 倍速选择器
              _buildSpeedButton(),

              const SizedBox(width: 8),

              // 清晰度选择器
              _buildQualityButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSlider() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;
        return Row(
          children: [
            _buildTimeLabel(state.position),
            const SizedBox(width: 12),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: PlayerColors.progress,
                  inactiveTrackColor: PlayerColors.controls,
                  secondaryActiveTrackColor: PlayerColors.progressBuffer,
                  thumbColor: PlayerColors.progress,
                  overlayColor: PlayerColors.progress.withValues(alpha: 0.2),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                ),
                child: Slider(
                  value: state.progress.clamp(0.0, 1.0),
                  secondaryTrackValue:
                      state.bufferProgress.clamp(0.0, 1.0),
                  max: 1.0,
                  onChanged: (value) {
                    final position =
                        (value * state.duration).toInt();
                    _controller.seekTo(position);
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildTimeLabel(
              state.duration,
              showUnknown: state.duration <= 0,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeLabel(int milliseconds, {bool showUnknown = false}) {
    final text = showUnknown ? '--:--' : _formatTime(milliseconds);

    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: PlayerColors.textMuted,
        height: 1.3,
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

        return IconButton(
          iconSize: 40,
          color: Colors.white,
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
        );
      },
    );
  }

  Widget _buildSpeedButton() {
    return _SpeedButton(
      controller: _controller,
    );
  }

  Widget _buildQualityButton() {
    return _QualityButton(
      controller: _controller,
    );
  }

  Widget _buildCenterPlayButton() {
    return Center(
      child: GestureDetector(
        onTap: () => _controller.play(),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            size: 48,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// 内部倍速按钮
class _SpeedButton extends StatefulWidget {
  final PlayerController controller;

  const _SpeedButton({required this.controller});

  @override
  State<_SpeedButton> createState() => _SpeedButtonState();
}

class _SpeedButtonState extends State<_SpeedButton> {
  bool _isOpen = false;
  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final currentSpeed = widget.controller.state.playbackSpeed;

        return SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => setState(() => _isOpen = !_isOpen),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: currentSpeed != 1.0
                        ? PlayerColors.activeHighlight
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: currentSpeed == 1.0
                        ? const Icon(
                            Icons.speed,
                            size: 18,
                            color: PlayerColors.text,
                          )
                        : Text(
                            '${currentSpeed}x',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: PlayerColors.text,
                            ),
                          ),
                  ),
                ),
              ),
              if (_isOpen) _buildDropdown(currentSpeed),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown(double currentSpeed) {
    return Positioned(
      bottom: 48,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 140,
          decoration: BoxDecoration(
            color: PlayerColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: PlayerColors.controls, width: 1),
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _speeds.map((speed) {
              final isActive = speed == currentSpeed;
              return InkWell(
                onTap: () {
                  widget.controller.setPlaybackSpeed(speed);
                  setState(() => _isOpen = false);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? PlayerColors.activeHighlight
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Text(
                        speed == 1.0 ? '正常' : '${speed}x',
                        style: TextStyle(
                          fontSize: 14,
                          color: isActive
                              ? PlayerColors.progress
                              : PlayerColors.text,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      if (isActive)
                        const Icon(
                          Icons.check,
                          size: 16,
                          color: PlayerColors.progress,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// 内部清晰度按钮
class _QualityButton extends StatefulWidget {
  final PlayerController controller;

  const _QualityButton({required this.controller});

  @override
  State<_QualityButton> createState() => _QualityButtonState();
}

class _QualityButtonState extends State<_QualityButton> {
  bool _isOpen = false;

  String _getLabel(QualityItem? quality) {
    if (quality == null || quality.value == 'auto') return '';
    return quality.value.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final qualities = widget.controller.qualities;
        final currentQuality = widget.controller.currentQuality;
        final label = _getLabel(currentQuality);

        return SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: qualities.isNotEmpty
                    ? () => setState(() => _isOpen = !_isOpen)
                    : null,
                child: Opacity(
                  opacity: qualities.isNotEmpty ? 1.0 : 0.4,
                  child: Container(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: label.isEmpty
                          ? const Icon(
                              Icons.tune,
                              size: 18,
                              color: PlayerColors.text,
                            )
                          : Text(
                              label,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: PlayerColors.text,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              if (_isOpen && qualities.isNotEmpty)
                _buildDropdown(qualities, currentQuality),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown(
    List<QualityItem> qualities,
    QualityItem? currentQuality,
  ) {
    const labels = {
      '4k': '4K 超清',
      '1080p': '1080P 高清',
      '720p': '720P 标清',
      '480p': '480P 流畅',
      '360p': '360P 极速',
      'auto': '自动',
    };

    return Positioned(
      bottom: 48,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(minWidth: 120),
          decoration: BoxDecoration(
            color: PlayerColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: PlayerColors.controls, width: 1),
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: qualities.map<Widget>((quality) {
              final isActive = quality.value == currentQuality?.value;
              return InkWell(
                onTap: () {
                  final index = widget.controller.indexOfQuality(quality);
                  if (index >= 0) {
                    widget.controller.setQuality(index);
                    setState(() => _isOpen = false);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? PlayerColors.activeHighlight
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Text(
                        labels[quality.value] ?? quality.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isActive
                              ? PlayerColors.progress
                              : PlayerColors.text,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      const Spacer(),
                      if (isActive)
                        const Icon(
                          Icons.check,
                          size: 16,
                          color: PlayerColors.progress,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
