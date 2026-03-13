import 'dart:async';
import 'package:flutter/material.dart';
import 'player_gesture_controller.dart';
import 'seek_preview_overlay.dart';

/// 播放器手势检测器
///
/// 统一处理视频播放区域的所有手势：
/// - 单击：显示控制栏（不切换播放/暂停）
/// - 双击：全屏切换
/// - 左右滑动：seek 进度
class PlayerGestureDetector extends StatefulWidget {
  /// 子组件（通常是视频视图）
  final Widget child;

  /// 手势控制器
  final PlayerGestureController gestureController;

  /// 播放器控制器（用于获取时长和执行 seek）
  final dynamic playerController;

  /// 单击回调
  final VoidCallback? onTap;

  /// 双击回调
  final VoidCallback? onDoubleTap;

  /// 是否锁定（锁定时禁用滑动手势）
  final bool isLocked;

  const PlayerGestureDetector({
    super.key,
    required this.child,
    required this.gestureController,
    required this.playerController,
    this.onTap,
    this.onDoubleTap,
    this.isLocked = false,
  });

  @override
  State<PlayerGestureDetector> createState() => _PlayerGestureDetectorState();
}

class _PlayerGestureDetectorState extends State<PlayerGestureDetector> {
  /// 抑制单击的阈值（像素）
  /// 与 PlayerGestureController 的 _minPanDistance 保持一致
  static const double _suppressTapThreshold = 20.0;

  /// 重置标志的延迟时间
  static const Duration _resetDelay = Duration(milliseconds: 100);

  /// 双击检测时间窗口（减少到 200ms 以提高单击响应速度）
  static const Duration _doubleTapDelay = Duration(milliseconds: 200);

  /// 单击发生时记录，用于与滑动区分
  bool _hasSignificantPanMovement = false;

  /// 上一次点击的时间戳（毫秒）
  int? _lastTapTime;

  /// 延迟确认单击的定时器
  Timer? _singleTapTimer;

  /// 获取播放器时长（毫秒）
  int get _duration {
    // 动态访问 playerController.state.duration
    try {
      return widget.playerController?.state?.duration ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// 获取播放器当前进度 (0-1)
  double get _progress {
    try {
      return widget.playerController?.state?.progress ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// 执行 seek 操作
  void _seekTo(int positionMs) {
    try {
      widget.playerController?.seekTo(positionMs);
    } catch (_) {
      // 忽略 seek 失败
    }
  }

  @override
  void initState() {
    super.initState();
    // 监听播放器时长变化，更新手势控制器
    try {
      widget.playerController?.addListener(_onPlayerStateChanged);
    } catch (_) {
      // 忽略
    }
  }

  @override
  void dispose() {
    _singleTapTimer?.cancel();
    try {
      widget.playerController?.removeListener(_onPlayerStateChanged);
    } catch (_) {
      // 忽略
    }
    super.dispose();
  }

  /// 播放器状态变化回调
  void _onPlayerStateChanged() {
    // 更新视频时长
    final duration = _duration;
    if (duration > 0) {
      widget.gestureController.setDuration(duration);
      // 初始化 seek 进度为当前播放位置
      final currentProgress = _progress;
      if (mounted) {
        widget.gestureController.updateSeekProgress(currentProgress);
      }
    }
  }

  /// 处理点击（自定义双击检测）
  ///
  /// 锁定状态下也允许点击，以便显示解锁按钮
  void _handleTap() {
    if (_hasSignificantPanMovement) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    // 检测双击
    if (_lastTapTime != null &&
        now - _lastTapTime! < _doubleTapDelay.inMilliseconds) {
      // 双击：取消单击定时器，立即触发双击回调
      _singleTapTimer?.cancel();
      _lastTapTime = null;
      if (!widget.isLocked) {
        widget.onDoubleTap?.call();
      }
    } else {
      // 可能是单击，启动延迟确认
      _lastTapTime = now;
      _singleTapTimer?.cancel();
      _singleTapTimer = Timer(_doubleTapDelay, () {
        // 延迟到期后，如果时间戳没有变化（没有新的点击），触发单击
        if (_lastTapTime == now) {
          widget.onTap?.call();
          _lastTapTime = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);

        // 使用单个 GestureDetector 处理所有手势，避免嵌套冲突
        return GestureDetector(
          // 点击手势（自定义双击检测）
          onTap: widget.isLocked ? null : _handleTap,
          // 滑动手势
          onPanStart: widget.isLocked
              ? null
              : (details) {
                  _hasSignificantPanMovement = false;
                  widget.gestureController.handleDragStart(details);
                },
          onPanUpdate: widget.isLocked
              ? null
              : (details) {
                  final dx = details.delta.dx.abs();
                  final dy = details.delta.dy.abs();

                  // 检测是否有明显的滑动移动
                  if (dx > _suppressTapThreshold ||
                      dy > _suppressTapThreshold) {
                    _hasSignificantPanMovement = true;
                  }

                  widget.gestureController.handleDragUpdate(
                    details,
                    screenSize,
                  );
                },
          onPanEnd: widget.isLocked
              ? null
              : (details) {
                  final seekPosition = widget.gestureController.handleDragEnd();

                  // 如果是 seek 手势，执行 seek 操作
                  if (seekPosition != null) {
                    _seekTo(seekPosition);
                  }

                  // 延迟重置标志，避免与 onTap 冲突
                  Future.delayed(_resetDelay, () {
                    if (mounted) {
                      setState(() {
                        _hasSignificantPanMovement = false;
                      });
                    }
                  });
                },
          onPanCancel: widget.isLocked
              ? null
              : () {
                  widget.gestureController.handleDragCancel();

                  // 延迟重置标志
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      setState(() {
                        _hasSignificantPanMovement = false;
                      });
                    }
                  });
                },
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              widget.child,
              // 手势提示覆盖层
              AnimatedBuilder(
                animation: widget.gestureController,
                builder: (context, _) {
                  final state = widget.gestureController.state;
                  if (!state.showHint) {
                    return const SizedBox.shrink();
                  }

                  switch (state.type) {
                    case GestureType.horizontalSeek:
                      return SeekPreviewOverlay(
                        progress: state.seekProgress,
                        currentPosition:
                            (state.seekProgress * _duration).toInt(),
                        duration: _duration,
                      );
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
