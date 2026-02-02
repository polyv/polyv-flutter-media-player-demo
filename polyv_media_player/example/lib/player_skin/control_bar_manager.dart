library;

/// ControlBarManager - 控制条状态管理器
///
/// 统一管理控制条的显示/隐藏逻辑，解决状态碎片化问题。
/// 所有控制条可见性的判断都通过这个类进行，确保逻辑清晰、可调试。
///
/// 使用方式：
/// ```dart
/// final manager = ControlBarManager(
///   isPlaying: _controller.state.isPlaying,
///   isSwitchingVideo: _isSwitchingVideo,
///   isEnded: _isEnded,
///   isInitialLoading: _isInitialLoading,
///   isLocked: _isLocked,
/// );
/// final isVisible = manager.isControlBarVisible;
/// ```

/// 控制条状态
enum ControlBarState {
  /// 明确隐藏
  hidden,

  /// 明确显示
  visible,
}

/// 控制条管理器
///
/// 职责：
/// - 集中管理所有影响控制条可见性的状态
/// - 提供单一来源的状态计算方法
/// - 支持调试时查看状态原因
class ControlBarManager {
  /// 播放器是否正在播放
  final bool isPlaying;

  /// 是否正在切换视频
  final bool isSwitchingVideo;

  /// 播放是否已结束
  final bool isEnded;

  /// 是否初始加载中
  final bool isInitialLoading;

  /// 用户最近是否交互过（点击屏幕等）
  final bool userRecentlyInteracted;

  /// 屏幕是否已锁定（锁定后隐藏控制条）
  final bool isLocked;

  /// 自动隐藏计时器是否激活中
  final bool isHideTimerActive;

  /// 上次用户交互的时间（用于判断"最近"）
  final DateTime? lastUserInteractionTime;

  /// 自动隐藏超时时间（毫秒）
  final int autoHideTimeoutMs;

  /// 构造函数
  ControlBarManager({
    required this.isPlaying,
    required this.isSwitchingVideo,
    required this.isEnded,
    required this.isInitialLoading,
    this.userRecentlyInteracted = false,
    this.isLocked = false,
    this.isHideTimerActive = false,
    this.lastUserInteractionTime,
    this.autoHideTimeoutMs = 3000,
  });

  /// 复制并修改部分状态
  ControlBarManager copyWith({
    bool? isPlaying,
    bool? isSwitchingVideo,
    bool? isEnded,
    bool? isInitialLoading,
    bool? userRecentlyInteracted,
    bool? isLocked,
    bool? isHideTimerActive,
    DateTime? lastUserInteractionTime,
    int? autoHideTimeoutMs,
  }) {
    return ControlBarManager(
      isPlaying: isPlaying ?? this.isPlaying,
      isSwitchingVideo: isSwitchingVideo ?? this.isSwitchingVideo,
      isEnded: isEnded ?? this.isEnded,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      userRecentlyInteracted:
          userRecentlyInteracted ?? this.userRecentlyInteracted,
      isLocked: isLocked ?? this.isLocked,
      isHideTimerActive: isHideTimerActive ?? this.isHideTimerActive,
      lastUserInteractionTime:
          lastUserInteractionTime ?? this.lastUserInteractionTime,
      autoHideTimeoutMs: autoHideTimeoutMs ?? this.autoHideTimeoutMs,
    );
  }

  /// 计算控制条是否应该可见
  ///
  /// 这是控制条可见性的单一真相来源（Single Source of Truth）。
  /// 所有影响控制条显示的条件都在这里明确列出。
  ///
  /// 核心规则：
  /// - 控制条默认隐藏
  /// - 只有在明确的几种情况下才显示
  bool get isControlBarVisible {
    // 规则表：按优先级排序
    // ====================

    // 0. 强制隐藏的情况（无需其他判断）
    if (isSwitchingVideo) {
      _debugReason = '切换视频期间，隐藏控制条';
      return false;
    }
    if (isEnded) {
      _debugReason = '播放已结束，隐藏控制条';
      return false;
    }
    if (isInitialLoading) {
      _debugReason = '初始加载中，隐藏控制条';
      return false;
    }
    if (isLocked) {
      _debugReason = '屏幕已锁定，隐藏控制条';
      return false;
    }

    // 1. 用户主动触发交互：显示控制条
    //（包括点击屏幕、显示设置菜单等）
    if (userRecentlyInteracted) {
      _debugReason = '用户主动触发交互，显示控制条';
      return true;
    }

    // 2. 暂停状态：显示控制条（方便用户继续播放）
    if (!isPlaying) {
      _debugReason = '暂停状态，显示控制条';
      return true;
    }

    // 3. 播放中且用户交互超时：隐藏控制条
    //（这是默认情况，用户没在操作且正在播放，应该隐藏）
    _debugReason = '播放中且无用户交互，隐藏控制条';
    return false;
  }

  /// 用于调试的状态原因（最近一次计算的原因）
  static String _debugReason = '';

  /// 获取最近一次状态计算的原因（用于调试）
  static String get debugReason => _debugReason;

  /// 是否应该启动自动隐藏计时器
  bool get shouldStartHideTimer {
    // 只有在播放中且控制条可见时才启动计时器
    return isPlaying && isControlBarVisible;
  }

  /// 创建"用户交互"状态
  ControlBarManager withUserInteraction() {
    return copyWith(
      userRecentlyInteracted: true,
      lastUserInteractionTime: DateTime.now(),
    );
  }

  /// 创建"切换视频"状态
  ControlBarManager withSwitchingVideo(bool switching) {
    return copyWith(
      isSwitchingVideo: switching,
      // 切换开始时清除用户交互状态，确保控制条隐藏
      userRecentlyInteracted: false,
    );
  }

  /// 创建"播放结束"状态
  ControlBarManager withEnded(bool ended) {
    return copyWith(isEnded: ended);
  }

  /// 创建"锁定"状态
  ControlBarManager withLocked(bool locked) {
    return copyWith(
      isLocked: locked,
      // 锁定时清除用户交互状态
      userRecentlyInteracted: !locked,
    );
  }

  /// 创建"计时器状态"
  ControlBarManager withHideTimerActive(bool active) {
    return copyWith(isHideTimerActive: active);
  }

  /// 检查用户交互是否超时（用于自动重置 userRecentlyInteracted）
  bool get isUserInteractionExpired {
    if (lastUserInteractionTime == null) return true;
    if (userRecentlyInteracted) {
      // 如果正在播放，用户交互超时后应该隐藏控制条
      final elapsed = DateTime.now().difference(lastUserInteractionTime!);
      return elapsed.inMilliseconds >= autoHideTimeoutMs;
    }
    return true;
  }

  /// 重置用户交互状态（当超时时调用）
  ControlBarManager withResetUserInteraction() {
    return copyWith(
      userRecentlyInteracted: false,
      lastUserInteractionTime: null,
    );
  }

  @override
  String toString() {
    return 'ControlBarManager('
        'visible: $isControlBarVisible, '
        'reason: "$debugReason", '
        'isPlaying: $isPlaying, '
        'isSwitching: $isSwitchingVideo, '
        'isEnded: $isEnded, '
        'isInitialLoading: $isInitialLoading, '
        'userInteracted: $userRecentlyInteracted, '
        'isLocked: $isLocked, '
        'hideTimerActive: $isHideTimerActive'
        ')';
  }

  /// 状态转换的快捷方法
  ControlBarManager asPlaying({bool playing = true}) {
    return copyWith(isPlaying: playing);
  }

  ControlBarManager asLoaded({bool loading = false}) {
    return copyWith(isInitialLoading: loading);
  }

  /// 调试信息：显示当前状态和可见性原因
  String get debugInfo {
    return 'ControlBarManager(debugReason): ${isControlBarVisible ? "VISIBLE" : "HIDDEN"} '
        '(playing=$isPlaying, switching=$isSwitchingVideo, '
        'ended=$isEnded, initialLoading=$isInitialLoading, '
        'userInteracted=$userRecentlyInteracted, locked=$isLocked, '
        'timerActive=$isHideTimerActive)';
  }
}
