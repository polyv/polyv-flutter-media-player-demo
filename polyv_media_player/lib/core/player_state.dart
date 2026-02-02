import 'package:flutter/foundation.dart';
import 'player_events.dart';

/// 播放器状态枚举
enum PlayerLoadingState {
  /// 空闲状态
  idle,

  /// 加载中
  loading,

  /// 准备完成
  prepared,

  /// 播放中
  playing,

  /// 已暂停
  paused,

  /// 缓冲中
  buffering,

  /// 播放完成
  completed,

  /// 错误状态
  error,
}

/// 播放器状态数据类
class PlayerState {
  /// 加载状态
  final PlayerLoadingState loadingState;

  /// 当前播放位置（毫秒）
  final int position;

  /// 总时长（毫秒）
  final int duration;

  /// 缓冲位置（毫秒）
  final int bufferedPosition;

  /// 播放速度
  final double playbackSpeed;

  /// 错误信息（仅在 error 状态时有值）
  final String? errorMessage;

  /// 错误码（仅在 error 状态时有值）
  final String? errorCode;

  /// 当前视频 VID
  final String? vid;

  /// 字幕是否开启
  final bool subtitleEnabled;

  /// 当前字幕 ID（null 表示关闭字幕）
  final String? currentSubtitleId;

  /// 可用的字幕轨道列表
  final List<SubtitleItem> availableSubtitles;

  const PlayerState({
    required this.loadingState,
    this.position = 0,
    this.duration = 0,
    this.bufferedPosition = 0,
    this.playbackSpeed = 1.0,
    this.errorMessage,
    this.errorCode,
    this.vid,
    this.subtitleEnabled = false,
    this.currentSubtitleId,
    this.availableSubtitles = const [],
  });

  /// 是否正在播放
  bool get isPlaying => loadingState == PlayerLoadingState.playing;

  /// 是否已暂停
  bool get isPaused => loadingState == PlayerLoadingState.paused;

  /// 是否已准备完成
  bool get isPrepared =>
      loadingState == PlayerLoadingState.prepared ||
      loadingState == PlayerLoadingState.playing ||
      loadingState == PlayerLoadingState.paused;

  /// 是否有错误
  bool get hasError => loadingState == PlayerLoadingState.error;

  /// 播放进度 (0.0 - 1.0)
  double get progress {
    if (duration <= 0) return 0.0;
    return position / duration;
  }

  /// 缓冲进度 (0.0 - 1.0)
  double get bufferProgress {
    if (duration <= 0) return 0.0;
    return bufferedPosition / duration;
  }

  /// 复制并修改部分属性
  PlayerState copyWith({
    PlayerLoadingState? loadingState,
    int? position,
    int? duration,
    int? bufferedPosition,
    double? playbackSpeed,
    String? errorMessage,
    String? errorCode,
    String? vid,
    bool? subtitleEnabled,
    String? currentSubtitleId,
    List<SubtitleItem>? availableSubtitles,
  }) {
    return PlayerState(
      loadingState: loadingState ?? this.loadingState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
      vid: vid ?? this.vid,
      subtitleEnabled: subtitleEnabled ?? this.subtitleEnabled,
      currentSubtitleId: currentSubtitleId ?? this.currentSubtitleId,
      availableSubtitles: availableSubtitles ?? this.availableSubtitles,
    );
  }

  /// 创建空闲状态
  factory PlayerState.idle() {
    return const PlayerState(loadingState: PlayerLoadingState.idle);
  }

  /// 创建加载状态
  factory PlayerState.loading(String vid) {
    return PlayerState(loadingState: PlayerLoadingState.loading, vid: vid);
  }

  /// 创建错误状态
  factory PlayerState.error(String code, String message) {
    return PlayerState(
      loadingState: PlayerLoadingState.error,
      errorCode: code,
      errorMessage: message,
    );
  }

  @override
  String toString() {
    return 'PlayerState(loadingState: $loadingState, position: $position, duration: $duration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerState &&
        other.loadingState == loadingState &&
        other.position == position &&
        other.duration == duration &&
        other.bufferedPosition == bufferedPosition &&
        other.playbackSpeed == playbackSpeed &&
        other.errorMessage == errorMessage &&
        other.errorCode == errorCode &&
        other.vid == vid &&
        other.subtitleEnabled == subtitleEnabled &&
        other.currentSubtitleId == currentSubtitleId &&
        listEquals(other.availableSubtitles, availableSubtitles);
  }

  @override
  int get hashCode {
    return Object.hash(
      loadingState,
      position,
      duration,
      bufferedPosition,
      playbackSpeed,
      errorMessage,
      errorCode,
      vid,
      subtitleEnabled,
      currentSubtitleId,
      availableSubtitles,
    );
  }
}
