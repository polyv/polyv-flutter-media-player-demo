import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/core/player_state.dart';
import 'package:polyv_media_player/infrastructure/danmaku/danmaku_model.dart';
import '../support/mocks.dart';

/// 测试数据工厂
///
/// 提供生成测试所需数据的辅助方法，避免硬编码测试数据
class TestDataFactory {
  /// 创建默认播放器状态
  static PlayerState createPlayerState({
    PlayerLoadingState loadingState = PlayerLoadingState.idle,
    int position = 0,
    int duration = 60000,
    int bufferedPosition = 0,
    double playbackSpeed = 1.0,
    String? errorMessage,
    String? errorCode,
    String? vid,
    bool subtitleEnabled = false,
    String? currentSubtitleId,
  }) {
    return PlayerState(
      loadingState: loadingState,
      position: position,
      duration: duration,
      bufferedPosition: bufferedPosition,
      playbackSpeed: playbackSpeed,
      errorMessage: errorMessage,
      errorCode: errorCode,
      vid: vid,
      subtitleEnabled: subtitleEnabled,
      currentSubtitleId: currentSubtitleId,
    );
  }

  /// 创建播放中状态
  static PlayerState createPlayingState({
    int position = 5000,
    int duration = 60000,
    double playbackSpeed = 1.0,
  }) {
    return createPlayerState(
      loadingState: PlayerLoadingState.playing,
      position: position,
      duration: duration,
      playbackSpeed: playbackSpeed,
    );
  }

  /// 创建暂停状态
  static PlayerState createPausedState({
    int position = 10000,
    int duration = 60000,
  }) {
    return createPlayerState(
      loadingState: PlayerLoadingState.paused,
      position: position,
      duration: duration,
    );
  }

  /// 创建错误状态
  static PlayerState createErrorState({
    String errorCode = 'TEST_ERROR',
    String errorMessage = 'Test error message',
  }) {
    return createPlayerState(
      loadingState: PlayerLoadingState.error,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }

  /// 创建弹幕
  static Danmaku createDanmaku({
    String? id,
    String text = 'Test danmaku',
    int time = 0,
    Color? color,
    DanmakuType type = DanmakuType.scroll,
  }) {
    return Danmaku(
      id: id ?? 'test_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      time: time,
      color: color,
      type: type,
    );
  }

  /// 创建弹幕列表
  static List<Danmaku> createDanmakus(int count, {int startTime = 0}) {
    return List.generate(
      count,
      (i) => createDanmaku(
        id: 'test_$i',
        text: 'Danmaku $i',
        time: startTime + (i * 1000),
      ),
    );
  }

  /// 创建顶部弹幕
  static Danmaku createTopDanmaku({String text = 'Top danmaku', int time = 0}) {
    return createDanmaku(
      text: text,
      time: time,
      type: DanmakuType.top,
      color: const Color(0xFFFF6B6B),
    );
  }

  /// 创建底部弹幕
  static Danmaku createBottomDanmaku({
    String text = 'Bottom danmaku',
    int time = 0,
  }) {
    return createDanmaku(
      text: text,
      time: time,
      type: DanmakuType.bottom,
      color: const Color(0xFFFFE66D),
    );
  }

  /// 创建滚动弹幕
  static Danmaku createScrollDanmaku({
    String text = 'Scroll danmaku',
    int time = 0,
  }) {
    return createDanmaku(text: text, time: time, type: DanmakuType.scroll);
  }

  /// 创建视频 ID
  static String createVid([String suffix = '']) {
    return 'test_video${suffix}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 创建时间戳（毫秒）
  static int createTimeStamp({
    int hours = 0,
    int minutes = 0,
    int seconds = 0,
  }) {
    return (hours * 3600 + minutes * 60 + seconds) * 1000;
  }

  /// 创建播放器事件数据
  static Map<String, dynamic> createPlayerEventData({
    required String type,
    Map<String, dynamic>? data,
  }) {
    return {'type': type, if (data != null) 'data': data};
  }

  /// 创建状态变化事件
  static Map<String, dynamic> createStateChangeEvent(String state) {
    return createPlayerEventData(type: 'stateChanged', data: {'state': state});
  }

  /// 创建进度事件
  static Map<String, dynamic> createProgressEvent({
    required int position,
    int? duration,
    int? bufferedPosition,
  }) {
    return createPlayerEventData(
      type: 'progress',
      data: {
        'position': position,
        if (duration != null) 'duration': duration,
        if (bufferedPosition != null) 'bufferedPosition': bufferedPosition,
      },
    );
  }

  /// 创建错误事件
  static Map<String, dynamic> createErrorEvent({
    String code = 'UNKNOWN_ERROR',
    String message = 'An error occurred',
  }) {
    return createPlayerEventData(
      type: 'error',
      data: {'code': code, 'message': message},
    );
  }

  /// 创建清晰度变化事件
  static Map<String, dynamic> createQualityChangeEvent({
    required List<Map<String, dynamic>> qualities,
    required int currentIndex,
  }) {
    return createPlayerEventData(
      type: 'qualityChanged',
      data: {'qualities': qualities, 'currentIndex': currentIndex},
    );
  }

  /// 创建字幕变化事件
  static Map<String, dynamic> createSubtitleChangeEvent({
    required List<Map<String, dynamic>> subtitles,
    required int currentIndex,
    bool enabled = true,
    String? trackKey,
  }) {
    return createPlayerEventData(
      type: 'subtitleChanged',
      data: {
        'subtitles': subtitles,
        'currentIndex': currentIndex,
        'enabled': enabled,
        if (trackKey != null) 'trackKey': trackKey,
      },
    );
  }

  /// 创建清晰度项
  static Map<String, dynamic> createQualityItem({
    String bitrate = '2000000',
    String height = '1080',
    String qualityName = '1080P',
  }) {
    return {'bitrate': bitrate, 'height': height, 'qualityName': qualityName};
  }

  /// 创建字幕项
  static Map<String, dynamic> createSubtitleItem({
    required String language,
    String languageName = 'English',
    String? url,
  }) {
    return {
      'language': language,
      'languageName': languageName,
      if (url != null) 'url': url,
    };
  }
}

/// 状态转换测试辅助类
///
/// 用于验证播放器状态转换的正确性
class StateTransitionTester {
  final List<PlayerState> _stateHistory = [];
  PlayerState? _previousState;

  /// 记录状态
  void recordState(PlayerState state) {
    if (_previousState != null) {
      _stateHistory.add(_previousState!);
    }
    _previousState = state;
  }

  /// 验证状态转换是否合法
  bool isValidTransition(PlayerLoadingState from, PlayerLoadingState to) {
    // 定义合法的状态转换
    const validTransitions = {
      PlayerLoadingState.idle: [
        PlayerLoadingState.loading,
        PlayerLoadingState.error,
      ],
      PlayerLoadingState.loading: [
        PlayerLoadingState.prepared,
        PlayerLoadingState.playing,
        PlayerLoadingState.paused,
        PlayerLoadingState.error,
      ],
      PlayerLoadingState.prepared: [
        PlayerLoadingState.playing,
        PlayerLoadingState.paused,
        PlayerLoadingState.buffering,
        PlayerLoadingState.error,
        PlayerLoadingState.completed,
      ],
      PlayerLoadingState.playing: [
        PlayerLoadingState.paused,
        PlayerLoadingState.buffering,
        PlayerLoadingState.completed,
        PlayerLoadingState.error,
      ],
      PlayerLoadingState.paused: [
        PlayerLoadingState.playing,
        PlayerLoadingState.buffering,
        PlayerLoadingState.error,
      ],
      PlayerLoadingState.buffering: [
        PlayerLoadingState.playing,
        PlayerLoadingState.paused,
        PlayerLoadingState.error,
      ],
      PlayerLoadingState.completed: [
        PlayerLoadingState.idle,
        PlayerLoadingState.loading,
      ],
      PlayerLoadingState.error: [
        PlayerLoadingState.idle,
        PlayerLoadingState.loading,
      ],
    };

    return validTransitions[from]?.contains(to) ?? false;
  }

  /// 获取状态历史
  List<PlayerState> get stateHistory => List.unmodifiable(_stateHistory);

  /// 获取当前状态
  PlayerState? get currentState => _previousState;

  /// 清除历史
  void clear() {
    _stateHistory.clear();
    _previousState = null;
  }

  /// 验证状态转换路径
  bool verifyTransitionPath(List<PlayerLoadingState> expectedPath) {
    if (_stateHistory.length + 1 < expectedPath.length) {
      return false;
    }

    for (int i = 0; i < expectedPath.length - 1; i++) {
      if (!isValidTransition(expectedPath[i], expectedPath[i + 1])) {
        return false;
      }
    }

    return true;
  }
}

/// 平台通道测试辅助类
///
/// 提供平台通道测试的通用方法
class PlatformChannelTestHelper {
  final MockMethodChannel methodChannel;
  final MockEventChannel eventChannel;

  PlatformChannelTestHelper({
    required this.methodChannel,
    required this.eventChannel,
  });

  /// 设置默认的方法调用响应
  void setupDefaultResponses() {
    methodChannel.mockResult('loadVideo', null);
    methodChannel.mockResult('play', null);
    methodChannel.mockResult('pause', null);
    methodChannel.mockResult('stop', null);
    methodChannel.mockResult('seekTo', null);
    methodChannel.mockResult('setPlaybackSpeed', null);
    methodChannel.mockResult('setQuality', null);
    methodChannel.mockResult('setSubtitle', null);
  }

  /// 验证方法调用
  void verifyMethodCall(String method, {Map<String, dynamic>? arguments}) {
    expect(
      methodChannel.wasMethodCalled(method),
      isTrue,
      reason: 'Expected method $method to be called',
    );

    if (arguments != null) {
      final calls = methodChannel.getCallsForMethod(method);
      expect(calls, isNotEmpty, reason: 'No calls found for method $method');

      final lastCall = calls.last;
      final actualArgs = lastCall.arguments as Map<String, dynamic>?;

      expect(actualArgs, isNotNull, reason: 'Expected arguments to be a Map');

      arguments.forEach((key, value) {
        expect(
          actualArgs![key],
          equals(value),
          reason: 'Argument $key does not match',
        );
      });
    }
  }

  /// 发送测试事件
  void sendTestEvent(Map<String, dynamic> event) {
    eventChannel.sendEvent(event);
  }

  /// 发送状态变化事件
  void sendStateChange(String state) {
    sendTestEvent(TestDataFactory.createStateChangeEvent(state));
  }

  /// 发送进度更新
  void sendProgress({
    required int position,
    int? duration,
    int? bufferedPosition,
  }) {
    sendTestEvent(
      TestDataFactory.createProgressEvent(
        position: position,
        duration: duration,
        bufferedPosition: bufferedPosition,
      ),
    );
  }

  /// 发送错误事件
  void sendError({String code = 'TEST_ERROR', String message = 'Test error'}) {
    sendTestEvent(
      TestDataFactory.createErrorEvent(code: code, message: message),
    );
  }
}

/// 弹幕测试辅助类
class DanmakuTestHelper {
  /// 验证弹幕是否按时间排序
  static bool isSortedByTime(List<dynamic> danmakus) {
    for (int i = 0; i < danmakus.length - 1; i++) {
      final d1 = danmakus[i] as Danmaku;
      final d2 = danmakus[i + 1] as Danmaku;
      if (d1.time > d2.time) {
        return false;
      }
    }
    return true;
  }

  /// 验证弹幕是否有重复 ID
  static List<String> findDuplicateIds(List<dynamic> danmakus) {
    final ids = <String>{};
    final duplicates = <String>[];

    for (final item in danmakus) {
      final d = item as Danmaku;
      if (ids.contains(d.id)) {
        if (!duplicates.contains(d.id)) {
          duplicates.add(d.id);
        }
      } else {
        ids.add(d.id);
      }
    }

    return duplicates;
  }

  /// 统计弹幕类型分布
  static Map<DanmakuType, int> countByType(List<dynamic> danmakus) {
    final counts = <DanmakuType, int>{};

    for (final item in danmakus) {
      final d = item as Danmaku;
      counts[d.type] = (counts[d.type] ?? 0) + 1;
    }

    return counts;
  }

  /// 获取指定时间范围内的弹幕
  static List<dynamic> getDanmakusInRange(
    List<dynamic> danmakus,
    int startTime,
    int endTime,
  ) {
    return danmakus.where((item) {
      final d = item as Danmaku;
      return d.time >= startTime && d.time <= endTime;
    }).toList();
  }

  /// 验证弹幕文本长度
  static bool isValidTextLength(String text, {int min = 1, int max = 100}) {
    final trimmed = text.trim();
    return trimmed.length >= min && trimmed.length <= max;
  }
}
