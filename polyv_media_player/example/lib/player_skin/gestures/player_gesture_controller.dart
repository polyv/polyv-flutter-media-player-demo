import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polyv_media_player/polyv_media_player.dart';

/// 手势类型枚举
///
/// 用于识别用户执行的不同滑动手势类型
enum GestureType {
  /// 无手势/未确定
  none,

  /// 左右滑动 seek（进度控制）
  horizontalSeek,

  /// 左侧上下滑动亮度调节
  brightnessAdjust,

  /// 右侧上下滑动音量调节
  volumeAdjust,
}

/// 手势状态模型
///
/// 管理滑动手势的当前状态，包括类型、进度、亮度和音量值
@immutable
class GestureState {
  /// 当前手势类型
  final GestureType type;

  /// seek 进度 (0-1)
  final double seekProgress;

  /// 亮度值 (0-1)
  final double brightness;

  /// 音量值 (0-1)
  final double volume;

  /// 是否显示提示 UI
  final bool showHint;

  const GestureState({
    this.type = GestureType.none,
    this.seekProgress = 0,
    this.brightness = 0.5,
    this.volume = 0.5,
    this.showHint = false,
  });

  /// 创建副本，可选择性修改部分字段
  GestureState copyWith({
    GestureType? type,
    double? seekProgress,
    double? brightness,
    double? volume,
    bool? showHint,
  }) {
    return GestureState(
      type: type ?? this.type,
      seekProgress: seekProgress ?? this.seekProgress,
      brightness: brightness ?? this.brightness,
      volume: volume ?? this.volume,
      showHint: showHint ?? this.showHint,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GestureState &&
        other.type == type &&
        other.seekProgress == seekProgress &&
        other.brightness == brightness &&
        other.volume == volume &&
        other.showHint == showHint;
  }

  @override
  int get hashCode {
    return Object.hash(type, seekProgress, brightness, volume, showHint);
  }
}

/// 播放器手势控制器
///
/// 负责处理视频播放区域的滑动手势，包括：
/// - 左右滑动：快进/快退
/// - 左侧上下滑动：调节亮度
/// - 右侧上下滑动：调节音量
///
/// 使用 Provider 模式，手势状态变化时通知监听器更新 UI
class PlayerGestureController extends ChangeNotifier {
  /// 当前手势状态
  GestureState _state = const GestureState();

  /// 提示隐藏定时器
  Timer? _hintHideTimer;

  /// 提示显示时长
  static const Duration _hintHideDuration = Duration(seconds: 2);

  /// 手势方向判断的最小滑动距离（像素）
  /// 增加阈值以减少误触发，特别是在用户点击时的手抖
  static const double _minPanDistance = 20;

  /// 手势开始时的位置
  Offset? _startPosition;

  /// 手势方向确定标志
  bool _directionLocked = false;

  /// seek 开始时的播放进度
  double _startSeekProgress = 0;

  /// 视频总时长（毫秒），用于 seek 计算
  int _duration = 0;

  /// Platform Channel 用于调用原生方法
  static const _channel = MethodChannel(PlayerApi.methodChannelName);

  /// 当前系统亮度缓存（用于初始化滑动起点）
  double? _cachedBrightness;

  /// 最后一次识别的手势类型（用于测试）
  GestureType _lastGestureType = GestureType.none;

  /// 手势是否正在进行（用于提示隐藏计时）
  bool _isGestureInProgress = false;

  /// 获取当前手势状态
  GestureState get state => _state;

  /// 获取最后一次识别的手势类型（用于测试验证）
  GestureType get lastGestureType => _lastGestureType;

  /// 更新 seek 进度（用于同步播放器当前进度）
  void updateSeekProgress(double progress) {
    if (_state.type == GestureType.none) {
      _state = _state.copyWith(seekProgress: progress);
      _startSeekProgress = progress;
    }
  }

  /// 设置视频总时长
  void setDuration(int durationMs) {
    _duration = durationMs;
  }

  /// 处理滑动开始
  ///
  /// 记录起始位置，重置手势类型但保留当前进度作为 seek 起点
  void handleDragStart(DragStartDetails details) {
    _startPosition = details.globalPosition;
    _directionLocked = false;
    _isGestureInProgress = true;
    // 取消之前的提示隐藏定时器
    _hintHideTimer?.cancel();
    // 保留当前 seekProgress 作为滑动起点，不重置为 0
    _updateState(
      GestureState(
        seekProgress: _state.seekProgress,
        brightness: _state.brightness,
        volume: _state.volume,
      ),
    );
  }

  /// 处理滑动更新
  ///
  /// 根据滑动方向和位置执行对应的操作：
  /// - 水平滑动：seek 进度
  /// - 左侧垂直滑动：调节亮度
  /// - 右侧垂直滑动：调节音量
  void handleDragUpdate(DragUpdateDetails details, Size screenSize) {
    final startPos = _startPosition;
    if (startPos == null) return;

    // 边界检查：视频未加载时忽略手势
    if (_duration <= 0) return;

    final dx = details.globalPosition.dx - startPos.dx;
    final dy = details.globalPosition.dy - startPos.dy;

    // 判断手势方向（使用绝对值比较）
    if (!_directionLocked) {
      final absDx = dx.abs();
      final absDy = dy.abs();

      // 滑动距离超过阈值才锁定方向
      if (absDx > _minPanDistance || absDy > _minPanDistance) {
        _directionLocked = true;

        if (absDx > absDy) {
          // 水平滑动 - seek
          _startSeekProgress = _state.seekProgress;
          _updateState(_state.copyWith(type: GestureType.horizontalSeek));
        } else {
          // 垂直滑动 - 判断左侧还是右侧（使用起始位置）
          final isLeftSide = startPos.dx < screenSize.width / 2;
          if (isLeftSide) {
            // 左侧 - 亮度
            _updateState(_state.copyWith(type: GestureType.brightnessAdjust));
          } else {
            // 右侧 - 音量
            _updateState(_state.copyWith(type: GestureType.volumeAdjust));
          }
        }
      } else {
        // 滑动距离未达到阈值，不处理
        return;
      }
    }

    // 根据手势类型执行对应操作
    switch (_state.type) {
      case GestureType.horizontalSeek:
        _handleSeekUpdate(dx, screenSize.width);
        break;
      case GestureType.brightnessAdjust:
        _handleBrightnessUpdate(dy, screenSize.height);
        break;
      case GestureType.volumeAdjust:
        _handleVolumeUpdate(dy, screenSize.height);
        break;
      default:
        break;
    }

    // 显示提示
    _showHint();
  }

  /// 处理滑动结束
  ///
  /// 如果是 seek 手势，返回目标 seek 位置供调用者执行
  /// 其他手势会立即执行对应的系统操作
  int? handleDragEnd() {
    int? seekPosition;

    // 保存最后识别的手势类型（用于测试验证）
    _lastGestureType = _state.type;

    if (_state.type == GestureType.horizontalSeek) {
      // seek 手势：返回目标位置
      final targetProgress = _state.seekProgress.clamp(0.0, 1.0);
      seekPosition = (targetProgress * _duration).toInt();
    }

    // 重置手势识别状态，但保留提示状态（提示由定时器控制自动隐藏）
    _startPosition = null;
    _directionLocked = false;
    _isGestureInProgress = false;

    // 只重置手势类型和位置相关状态，保留 showHint
    _updateState(
      GestureState(
        type: GestureType.none,
        brightness: _state.brightness,
        volume: _state.volume,
        seekProgress: _state.seekProgress,
        showHint: _state.showHint, // 保留提示状态
      ),
    );

    // 启动提示隐藏定时器（手势结束后才开始计时）
    _startHintHideTimer();

    return seekPosition;
  }

  /// 处理滑动取消
  ///
  /// 用户中断手势时重置状态（与 handleDragEnd 保持一致）
  void handleDragCancel() {
    _startPosition = null;
    _directionLocked = false;
    _isGestureInProgress = false;

    // 与 handleDragEnd 保持一致，保留当前值
    _updateState(
      GestureState(
        type: GestureType.none,
        brightness: _state.brightness,
        volume: _state.volume,
        seekProgress: _state.seekProgress,
      ),
    );

    // 启动提示隐藏定时器
    _startHintHideTimer();
  }

  /// 处理 seek 更新
  ///
  /// 根据水平滑动距离计算新的播放进度
  /// 每屏滑动 3 分钟（180秒）
  void _handleSeekUpdate(double dx, double screenWidth) {
    const seekRangeSeconds = 180; // 每屏滑动 3 分钟

    // 计算滑动比例
    final deltaPercent = dx / screenWidth;

    // 转换为时间比例（考虑视频总时长）
    final durationSeconds = _duration / 1000;
    final rangePercent = durationSeconds > 0
        ? seekRangeSeconds / durationSeconds
        : 1.0;

    // 计算新进度
    var newProgress = _startSeekProgress + (deltaPercent * rangePercent);
    newProgress = newProgress.clamp(0.0, 1.0);

    _updateState(_state.copyWith(seekProgress: newProgress));
  }

  /// 处理亮度更新
  ///
  /// 根据垂直滑动距离调整屏幕亮度
  /// 上滑增加亮度，下滑降低亮度
  void _handleBrightnessUpdate(double dy, double screenHeight) {
    // 使用状态中的当前值作为起点（初始为 0.5）
    final startValue = _state.brightness;

    // 首次调节时异步获取系统亮度并更新缓存（用于下次滑动）
    if (_cachedBrightness == null) {
      _fetchSystemBrightness();
    }

    // 屏幕高度的 0.4 倍作为灵敏度基准
    final delta = dy / (screenHeight * 0.4);
    var newBrightness = startValue - delta; // 上增下减
    newBrightness = newBrightness.clamp(0.0, 1.0);

    // 更新缓存和系统亮度
    _cachedBrightness = newBrightness;
    _updateSystemBrightness(newBrightness);

    _updateState(_state.copyWith(brightness: newBrightness));
  }

  /// 处理音量更新
  ///
  /// 根据垂直滑动距离调整播放音量
  /// 上滑增加音量，下滑降低音量
  void _handleVolumeUpdate(double dy, double screenHeight) {
    // 使用状态中的当前值作为起点（初始为 0.5）
    final startValue = _state.volume;

    // 屏幕高度的 0.4 倍作为灵敏度基准
    final delta = dy / (screenHeight * 0.4);
    var newVolume = startValue - delta; // 上增下减
    newVolume = newVolume.clamp(0.0, 1.0);

    // 更新系统音量
    _updateSystemVolume(newVolume);

    _updateState(_state.copyWith(volume: newVolume));
  }

  /// 获取当前系统亮度（异步）
  void _fetchSystemBrightness() {
    MethodChannelHandler.getScreenBrightness(_channel)
        .then((value) {
          _cachedBrightness = value;
        })
        .catchError((e) {
          debugPrint('PlayerGestureController: 获取亮度失败: $e');
          _cachedBrightness = 0.5;
        });
  }

  /// 更新系统屏幕亮度
  ///
  /// 通过 Platform Channel 调用原生 API
  /// iOS: [UIScreen mainScreen].brightness = brightness;
  /// Android: window.attributes.screenBrightness = brightness;
  void _updateSystemBrightness(double brightness) {
    MethodChannelHandler.setScreenBrightness(_channel, brightness).catchError((
      e,
    ) {
      debugPrint('PlayerGestureController: 设置亮度失败: $e');
    });
  }

  /// 更新系统音量
  ///
  /// 通过 Platform Channel 调用原生 API
  /// iOS: 使用 MPVolumeView 的滑块控件（实际通过系统音量控制）
  /// Android: audioManager.setStreamVolume(...)
  void _updateSystemVolume(double volume) {
    MethodChannelHandler.setVolume(_channel, volume).catchError((e) {
      debugPrint('PlayerGestureController: 设置音量失败: $e');
    });
  }

  /// 显示提示
  void _showHint() {
    if (!_state.showHint) {
      _updateState(_state.copyWith(showHint: true));
    }
    // 不再每次调用都重置定时器，改为在手势结束时启动
  }

  /// 启动提示隐藏定时器（手势结束后才开始计时）
  void _startHintHideTimer() {
    _hintHideTimer?.cancel();
    _hintHideTimer = Timer(_hintHideDuration, () {
      if (_state.showHint && !_isGestureInProgress) {
        _updateState(_state.copyWith(showHint: false));
      }
    });
  }

  /// 更新状态并通知监听器
  void _updateState(GestureState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _hintHideTimer?.cancel();
    super.dispose();
  }
}
