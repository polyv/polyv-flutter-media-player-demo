import 'dart:async';
import 'package:flutter/material.dart';

/// 双击手势检测器
///
/// 精确区分单击和双击行为，使用 300ms 延迟机制。
///
/// 使用场景：
/// - 需要精确控制单击/双击不同行为
/// - 避免使用 Flutter GestureDetector 的 onDoubleTap（已知有兼容性问题）
///
/// 使用示例：
/// ```dart
/// DoubleTapDetector(
///   onTap: () => print('单击'),
///   onDoubleTap: () => print('双击'),
///   child: VideoView(),
/// )
/// ```
class DoubleTapDetector extends StatefulWidget {
  /// 默认双击检测时间窗口（300ms，与原型保持一致）
  static const defaultDoubleTapDelay = Duration(milliseconds: 300);

  /// 单击回调（在确认不是双击后触发，300ms 延迟）
  final VoidCallback? onTap;

  /// 双击回调（第二次点击后立即触发）
  final VoidCallback? onDoubleTap;

  /// 子组件
  final Widget child;

  /// 双击检测时间窗口（默认 300ms，与原型保持一致）
  final Duration doubleTapDelay;

  const DoubleTapDetector({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.doubleTapDelay = defaultDoubleTapDelay,
  });

  @override
  State<DoubleTapDetector> createState() => _DoubleTapDetectorState();
}

class _DoubleTapDetectorState extends State<DoubleTapDetector> {
  /// 上一次点击的时间戳（毫秒）
  int? _lastTapTime;

  /// 延迟确认单击的定时器
  Timer? _singleTapTimer;

  @override
  void dispose() {
    _singleTapTimer?.cancel();
    super.dispose();
  }

  /// 处理点击事件
  ///
  /// 逻辑：
  /// 1. 如果在 doubleTapDelay 内有第二次点击 → 触发双击
  /// 2. 如果 doubleTapDelay 内没有第二次点击 → 触发单击
  void _handleTap() {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (_lastTapTime != null &&
        now - _lastTapTime! < widget.doubleTapDelay.inMilliseconds) {
      // 双击：取消单击定时器，立即触发双击回调
      _singleTapTimer?.cancel();
      _lastTapTime = null;
      widget.onDoubleTap?.call();
    } else {
      // 可能是单击，启动延迟确认
      _lastTapTime = now;
      _singleTapTimer?.cancel();
      _singleTapTimer = Timer(widget.doubleTapDelay, () {
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
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
