import 'package:flutter/material.dart';
import 'package:polyv_media_player/polyv_media_player.dart';
import 'player_gesture_controller.dart';
import 'seek_preview_overlay.dart';
import '../double_tap_detector.dart';

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

  /// 播放器控制器
  final PlayerController playerController;

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

  /// 单击发生时记录，用于与滑动区分
  bool _hasSignificantPanMovement = false;

  @override
  void initState() {
    super.initState();
    // 监听播放器时长变化，更新手势控制器
    widget.playerController.addListener(_onPlayerStateChanged);
  }

  @override
  void dispose() {
    widget.playerController.removeListener(_onPlayerStateChanged);
    super.dispose();
  }

  /// 播放器状态变化回调
  void _onPlayerStateChanged() {
    // 更新视频时长
    final duration = widget.playerController.state.duration;
    if (duration > 0) {
      widget.gestureController.setDuration(duration);
      // 初始化 seek 进度为当前播放位置
      final currentProgress = widget.playerController.state.progress;
      if (mounted) {
        widget.gestureController.updateSeekProgress(currentProgress);
      }
    }
  }

  /// 处理点击（由 DoubleTapDetector 调用）
  void _handleTap() {
    if (!widget.isLocked && !_hasSignificantPanMovement) {
      widget.onTap?.call();
    }
  }

  /// 处理双击（由 DoubleTapDetector 调用）
  void _handleDoubleTap() {
    if (!widget.isLocked) {
      widget.onDoubleTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);

        // 构建 Slider Detector（处理滑动手势）
        final sliderDetector = GestureDetector(
          // 滑动开始
          onPanStart: widget.isLocked
              ? null
              : (details) {
                  _hasSignificantPanMovement = false;
                  widget.gestureController.handleDragStart(details);
                },
          // 滑动更新
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
          // 滑动结束
          onPanEnd: widget.isLocked
              ? null
              : (details) {
                  final seekPosition = widget.gestureController.handleDragEnd();

                  // 如果是 seek 手势，执行 seek 操作
                  if (seekPosition != null) {
                    widget.playerController.seekTo(seekPosition);
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
          // 滑动取消
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
          behavior: HitTestBehavior.translucent,
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
                            (state.seekProgress *
                                    widget.playerController.state.duration)
                                .toInt(),
                        duration: widget.playerController.state.duration
                            .toInt(),
                      );
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        );

        // 使用 DoubleTapDetector 处理单击和双击（避免 GestureDetector 的 Timer 问题）
        return DoubleTapDetector(
          onTap: _handleTap,
          onDoubleTap: _handleDoubleTap,
          child: sliderDetector,
        );
      },
    );
  }
}
