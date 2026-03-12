import 'dart:async';

import 'package:flutter/foundation.dart';

/// 控制条状态机 - 命令式管理
///
/// 核心思想：控制条可见性由明确的模式驱动，而不是被动响应播放器状态变化。
///
/// 三种模式：
/// - hidden: 明确隐藏（初始加载、切换视频时）
/// - passive: 被动模式（暂停时显示，播放时隐藏）
/// - active: 激活模式（用户主动显示，3秒后自动切换到 passive）

/// 控制条显示模式
enum ControlBarMode {
  /// 明确隐藏（初始状态、切换视频时）
  hidden,

  /// 被动模式（跟随播放器状态：暂停显示，播放隐藏）
  passive,

  /// 激活模式（用户主动显示，3秒后自动切换到 passive）
  active,
}

/// 控制条状态机
///
/// 职责：
/// - 维护控制条的当前模式
/// - 提供模式转换方法（enterHidden, enterPassive, enterActive）
/// - 根据当前模式和播放器状态计算是否应该显示
/// - 管理自动隐藏计时器
class ControlBarStateMachine extends ChangeNotifier {
  ControlBarMode _mode = ControlBarMode.hidden;
  Timer? _hideTimer;

  /// 自动隐藏时长（默认 3 秒）
  final Duration autoHideDuration;

  ControlBarStateMachine({this.autoHideDuration = const Duration(seconds: 3)});

  /// 当前模式
  ControlBarMode get mode => _mode;

  /// 是否处于隐藏模式
  bool get isHidden => _mode == ControlBarMode.hidden;

  /// 是否处于被动模式
  bool get isPassive => _mode == ControlBarMode.passive;

  /// 是否处于激活模式
  bool get isActive => _mode == ControlBarMode.active;

  /// 计算控制条是否应该可见
  ///
  /// [isPlaying] 播放器是否正在播放（仅在 passive 模式下使用）
  bool isVisible(bool isPlaying) {
    switch (_mode) {
      case ControlBarMode.hidden:
        return false;
      case ControlBarMode.passive:
        // 被动模式：暂停时显示，播放时隐藏
        return !isPlaying;
      case ControlBarMode.active:
        // 激活模式：始终显示
        return true;
    }
  }

  /// 进入隐藏模式（用于初始加载、切换视频等场景）
  void enterHidden() {
    _cancelTimer();
    if (_mode != ControlBarMode.hidden) {
      _mode = ControlBarMode.hidden;
      notifyListeners();
    }
  }

  /// 进入被动模式（视频加载完成后）
  void enterPassive() {
    _cancelTimer();
    if (_mode != ControlBarMode.passive) {
      _mode = ControlBarMode.passive;
      notifyListeners();
    }
  }

  /// 进入激活模式（用户点击屏幕等交互）
  ///
  /// [autoHideTimeout] 自动隐藏超时时间，默认使用构造函数传入的 autoHideDuration。设为 null 则不自动隐藏。
  void enterActive({Duration? autoHideTimeout}) {
    _cancelTimer();
    if (_mode != ControlBarMode.active) {
      _mode = ControlBarMode.active;
      notifyListeners();
    }

    // 启动自动隐藏计时器
    final timeout = autoHideTimeout ?? autoHideDuration;
    if (timeout.inMilliseconds > 0) {
      _hideTimer = Timer(timeout, () {
        if (_mode == ControlBarMode.active) {
          enterPassive(); // 计时器到期后切换到被动模式
        }
      });
    }
  }

  /// 切换激活状态（用户点击屏幕）
  ///
  /// 如果当前是激活模式，切换到被动模式；
  /// 如果当前是被动或隐藏模式，切换到激活模式。
  void toggle({Duration? autoHideTimeout}) {
    if (_mode == ControlBarMode.active) {
      enterPassive();
    } else {
      enterActive(autoHideTimeout: autoHideTimeout);
    }
  }

  /// 取消计时器（用于用户持续交互的场景）
  void cancelTimer() {
    _cancelTimer();
  }

  void _cancelTimer() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  String toString() {
    return 'ControlBarStateMachine(mode: $_mode)';
  }
}
