import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../platform_channel/event_channel_handler.dart';
import '../platform_channel/method_channel_handler.dart';
import '../platform_channel/player_api.dart';
import '../services/subtitle_preference_service.dart';
import '../infrastructure/download/download_state_manager.dart';
import 'player_exception.dart';
import 'player_state.dart';
import 'player_events.dart';

/// Method Channel 名称
const String _kMethodChannelName = PlayerApi.methodChannelName;

/// Event Channel 名称
const String _kEventChannelName = PlayerApi.eventChannelName;

/// 播放器控制器
///
/// 使用 Provider 模式，继承 ChangeNotifier 以支持状态监听
class PlayerController extends ChangeNotifier {
  /// Method Channel 用于调用原生方法
  final MethodChannel _methodChannel;

  /// Event Channel 用于接收原生事件
  final EventChannel _eventChannel;

  /// 事件订阅
  StreamSubscription<dynamic>? _eventSubscription;

  /// 当前播放器状态
  PlayerState _state = PlayerState.idle();

  /// 清晰度列表
  List<QualityItem> _qualities = const [];

  /// 当前清晰度索引
  int _currentQualityIndex = 0;

  /// 字幕列表
  List<SubtitleItem> _subtitles = const [];

  /// 当前字幕索引（-1 表示关闭）
  int _currentSubtitleIndex = -1;

  /// 是否已释放
  bool _disposed = false;

  /// 获取当前播放器状态
  PlayerState get state => _state;

  /// 获取清晰度列表
  List<QualityItem> get qualities => List.unmodifiable(_qualities);

  int indexOfQuality(QualityItem quality) {
    if (_qualities.isEmpty) return -1;

    final byDescription = _qualities.indexWhere(
      (q) => q.description == quality.description,
    );
    if (byDescription >= 0) return byDescription;

    final byValue = _qualities.indexWhere((q) => q.value == quality.value);
    if (byValue >= 0) return byValue;

    return _qualities.indexOf(quality);
  }

  /// 获取当前清晰度
  QualityItem? get currentQuality {
    if (_qualities.isEmpty || _currentQualityIndex < 0) {
      return null;
    }
    return _qualities[_currentQualityIndex];
  }

  /// 获取字幕列表（向后兼容，同 availableSubtitles）
  List<SubtitleItem> get subtitles => availableSubtitles;

  /// 获取可用的字幕列表（包含双语标记等完整信息）
  List<SubtitleItem> get availableSubtitles => _state.availableSubtitles;

  /// 获取当前字幕
  SubtitleItem? get currentSubtitle {
    if (_subtitles.isEmpty || _currentSubtitleIndex < 0) {
      return null;
    }
    return _subtitles[_currentSubtitleIndex];
  }

  /// 构造函数
  PlayerController({String? methodChannelName, String? eventChannelName})
    : _methodChannel = MethodChannel(methodChannelName ?? _kMethodChannelName),
      _eventChannel = EventChannel(eventChannelName ?? _kEventChannelName) {
    _initEventChannel();
    _initMethodCallHandler();
  }

  /// 初始化事件监听
  void _initEventChannel() {
    _eventSubscription = EventChannelHandler.receiveStream(
      _eventChannel,
    ).listen(_onEvent, onError: _onEventError);
  }

  /// 初始化方法调用处理器
  void _initMethodCallHandler() {
    _methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  /// 处理来自原生层的方法调用
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      default:
        debugPrint('[PlayerController] Unknown method call: ${call.method}');
    }
  }

  /// 处理事件
  void _onEvent(dynamic event) {
    // 频繁日志已移除，减少控制台噪音
    if (_disposed) {
      debugPrint(
        '[PlayerController] _onEvent: controller is disposed, ignoring',
      );
      return;
    }

    // 接受 Map 类型（无论是 Map<String, dynamic> 还是 Map<Object?, Object?>）
    if (event is! Map) {
      debugPrint(
        '[PlayerController] _onEvent: event is not Map, it is ${event.runtimeType}',
      );
      return;
    }

    final typeStr = event['type']?.toString();
    final data = event['data'] as Map<dynamic, dynamic>?;

    switch (typeStr) {
      case PlayerEventName.stateChanged:
        _handleStateChanged(data);
        break;
      case PlayerEventName.progress:
        _handleProgress(data);
        break;
      case PlayerEventName.error:
        _handleError(data);
        break;
      case PlayerEventName.qualityChanged:
        _handleQualityChanged(data);
        break;
      case PlayerEventName.subtitleChanged:
        _handleSubtitleChanged(data);
        break;
      case PlayerEventName.playbackSpeedChanged:
        _handlePlaybackSpeedChanged(data);
        break;
      case PlayerEventName.completed:
        _handleCompleted();
        break;
      default:
        debugPrint('[PlayerController] Unknown event type: $typeStr');
    }
  }

  /// 处理事件错误
  void _onEventError(dynamic error) {
    debugPrint('[PlayerController] Event error: $error');
  }

  /// 处理状态变化
  void _handleStateChanged(Map<dynamic, dynamic>? data) {
    if (data == null) return;

    final stateStr = data['state']?.toString();
    final newState = _parseLoadingState(stateStr);

    _updateState(_state.copyWith(loadingState: newState));
  }

  /// 处理进度更新
  void _handleProgress(Map<dynamic, dynamic>? data) {
    if (data == null) return;

    final position = data['position'] as int? ?? 0;
    final duration = data['duration'] as int? ?? _state.duration;
    final buffered = data['bufferedPosition'] as int? ?? 0;

    _updateState(
      _state.copyWith(
        position: position,
        duration: duration,
        bufferedPosition: buffered,
      ),
    );
  }

  /// 处理错误
  void _handleError(Map<dynamic, dynamic>? data) {
    if (data == null) return;

    final code = data['code']?.toString() ?? 'UNKNOWN_ERROR';
    final message = data['message']?.toString() ?? 'An unknown error occurred';

    _updateState(PlayerState.error(code, message));
  }

  /// 处理清晰度变化
  void _handleQualityChanged(Map<dynamic, dynamic>? data) {
    debugPrint('[PlayerController] _handleQualityChanged called, data: $data');
    if (data == null) return;

    final qualitiesList = data['qualities'] as List<dynamic>?;
    final currentIndex = data['currentIndex'] as int? ?? 0;

    debugPrint(
      '[PlayerController] qualitiesList: $qualitiesList, currentIndex: $currentIndex',
    );

    if (qualitiesList != null) {
      _qualities = qualitiesList.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return QualityItem.fromJson(map);
      }).toList();
      _currentQualityIndex = currentIndex;
      debugPrint(
        '[PlayerController] Updated qualities: ${_qualities.length} items, current: $_currentQualityIndex',
      );
      notifyListeners();
    }
  }

  /// 处理字幕变化
  void _handleSubtitleChanged(Map<dynamic, dynamic>? data) {
    debugPrint(
      '[PlayerController] _handleSubtitleChanged called, raw data: $data',
    );
    if (data == null) return;

    final subtitlesList = data['subtitles'] as List<dynamic>?;
    final currentIndex = data['currentIndex'] as int? ?? -1;
    final enabled = data['enabled'] as bool? ?? true;
    final trackKey = data['trackKey'] as String?;

    if (subtitlesList != null) {
      // 注意：EventChannel 传过来的 Map 通常是 Map<Object?, Object?>，
      // 不能直接强转为 Map<String, dynamic>，否则在运行时会抛类型错误，
      // 导致整个 subtitleChanged 事件处理失败，从而使 subtitles 一直为空。
      // 这里通过 Map<String, dynamic>.from 安全地做一次复制与类型收窄。
      _subtitles = subtitlesList.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return SubtitleItem.fromJson(map);
      }).toList();

      debugPrint(
        '[PlayerController] Parsed subtitles: count=${_subtitles.length}, currentIndex=$currentIndex, enabled=$enabled, trackKey=$trackKey',
      );

      // 如果是关闭字幕事件（enabled == false 且 currentIndex < 0），
      // 不要触发默认算法或用户偏好恢复，直接更新为关闭状态。
      if (!enabled && currentIndex < 0) {
        debugPrint(
          '[PlayerController] Received disable-subtitle event from native (enabled=false, currentIndex<0), updating state to disabled.',
        );
        _currentSubtitleIndex = -1;
        _updateState(
          _state.copyWith(
            subtitleEnabled: false,
            currentSubtitleId: null,
            availableSubtitles: List.unmodifiable(_subtitles),
          ),
        );
        return;
      }

      // 原生端未指定索引（例如某些平台首次加载仅回传列表），
      // 优先检查用户偏好，然后应用默认算法。
      if (currentIndex < 0) {
        // AC4: 优先恢复用户偏好
        _applyUserPreferenceOrFallback();
        return;
      }

      _currentSubtitleIndex = currentIndex;

      // 计算当前字幕 ID（支持双语/单语，兼容 trackKey 和 index 两种来源）
      final newCurrentSubtitleId = _determineCurrentSubtitleId(
        enabled: enabled && currentIndex >= 0,
        trackKey:
            trackKey ??
            (currentIndex >= 0 ? _subtitles[currentIndex].trackKey : null),
        currentIndex: currentIndex,
      );

      // 如果选择了默认字幕且当前未开启，则开启字幕
      final effectiveEnabled = currentIndex >= 0 ? true : enabled;

      _updateState(
        _state.copyWith(
          subtitleEnabled: effectiveEnabled,
          currentSubtitleId: newCurrentSubtitleId,
          availableSubtitles: List.unmodifiable(_subtitles),
        ),
      );

      debugPrint(
        '[PlayerController] _handleSubtitleChanged updated state: subtitleEnabled=${_state.subtitleEnabled}, currentSubtitleId=${_state.currentSubtitleId}, availableSubtitles=${_subtitles.length}',
      );
    }
  }

  /// 应用用户偏好或回退到默认算法
  ///
  /// AC4: 优先恢复用户之前选择的字幕语言
  /// 如果没有保存的偏好或偏好不可用，则回退到默认选择算法
  Future<void> _applyUserPreferenceOrFallback() async {
    final vid = _state.vid;
    if (vid == null || vid.isEmpty) {
      // 没有 VID，使用默认算法
      _applyDefaultSelection();
      return;
    }

    try {
      // 异步加载用户偏好
      final preference = await SubtitlePreferenceService.loadPreference(vid);

      if (preference != null &&
          preference.enabled &&
          preference.trackKey != null) {
        // 检查保存的 trackKey 是否仍在可用字幕列表中
        final savedIndex = _subtitles.indexWhere(
          (s) => s.trackKey == preference.trackKey,
        );

        if (savedIndex >= 0) {
          // 找到保存的字幕，应用用户偏好
          debugPrint(
            '[PlayerController] Applying user preference: ${preference.trackKey} at index $savedIndex',
          );
          await setSubtitleWithKey(
            enabled: true,
            trackKey: preference.trackKey,
          );
          return;
        } else {
          debugPrint(
            '[PlayerController] Saved subtitle trackKey "${preference.trackKey}" not found in current list',
          );
        }
      } else {
        debugPrint(
          '[PlayerController] No saved subtitle preference for vid: $vid',
        );
      }

      // 没有有效偏好，使用默认算法
      _applyDefaultSelection();
    } catch (e) {
      debugPrint(
        '[PlayerController] Error loading subtitle preference: $e, using default selection',
      );
      _applyDefaultSelection();
    }
  }

  /// 应用默认字幕选择算法
  void _applyDefaultSelection() {
    final defaultIndex = _selectDefaultSubtitleIndex();

    if (defaultIndex >= 0 && defaultIndex < _subtitles.length) {
      final targetSubtitle = _subtitles[defaultIndex];
      debugPrint(
        '[PlayerController] Applying default selection: ${targetSubtitle.trackKey} at index $defaultIndex',
      );

      _currentSubtitleIndex = defaultIndex;
      _updateState(
        _state.copyWith(
          subtitleEnabled: true,
          currentSubtitleId: targetSubtitle.trackKey,
          availableSubtitles: List.unmodifiable(_subtitles),
        ),
      );

      // 同步到原生层（不阻塞，异步执行）
      setSubtitleWithKey(
        enabled: true,
        trackKey: targetSubtitle.trackKey,
      ).catchError((e) {
        debugPrint(
          '[PlayerController] Failed to sync default subtitle to native: $e',
        );
      });
    } else {
      // 没有可用字幕
      debugPrint(
        '[PlayerController] No available subtitles, disabling subtitle',
      );
      _currentSubtitleIndex = -1;
      _updateState(
        _state.copyWith(
          subtitleEnabled: false,
          currentSubtitleId: null,
          availableSubtitles: List.unmodifiable(_subtitles),
        ),
      );
    }
  }

  /// 选择默认字幕索引
  ///
  /// 默认选择算法（AC3 完整版）：
  /// 1. 双语字幕优先（isBilingual == true）
  /// 2. 单语与系统语言匹配（zh-Hans/zh 优先中文，en-US/en 优先英文）
  /// 3. 原生标记为默认的（isDefault == true）
  /// 4. 兜底策略：选择第一条字幕
  ///
  /// 返回值：选中的字幕索引，如果没有可用字幕则返回 -1
  int _selectDefaultSubtitleIndex() {
    if (_subtitles.isEmpty) return -1;

    // 1. 优先选择双语字幕
    final bilingualIndex = _subtitles.indexWhere((s) => s.isBilingual);
    if (bilingualIndex >= 0) {
      debugPrint(
        '[PlayerController] Selected bilingual subtitle at index $bilingualIndex',
      );
      return bilingualIndex;
    }

    // 2. 单语与系统语言匹配
    final systemLanguageIndex = _findBestLanguageMatchIndex();
    if (systemLanguageIndex >= 0) {
      debugPrint(
        '[PlayerController] Selected system language match at index $systemLanguageIndex',
      );
      return systemLanguageIndex;
    }

    // 3. 其次选择原生标记为默认的
    final defaultIndex = _subtitles.indexWhere((s) => s.isDefault);
    if (defaultIndex >= 0) {
      debugPrint(
        '[PlayerController] Selected default subtitle at index $defaultIndex',
      );
      return defaultIndex;
    }

    // 4. 否则选择第一条字幕
    debugPrint('[PlayerController] Selected first subtitle at index 0');
    return 0;
  }

  /// 根据系统语言查找最佳匹配的字幕索引
  ///
  /// 匹配规则：
  /// - zh-Hans, zh-Hans-CN, zh-CN, zh → 优先匹配中文
  /// - en-US, en-GB, en → 优先匹配英文
  /// - 其他语言码的前缀匹配
  ///
  /// 返回值：最佳匹配的索引，未找到返回 -1
  int _findBestLanguageMatchIndex() {
    final platformDispatcher = ui.PlatformDispatcher.instance;
    final systemLanguage =
        platformDispatcher.locale.languageCode; // 如 "zh", "en"
    final systemScript =
        platformDispatcher.locale.scriptCode; // 如 "Hans", "Latn"
    final systemCountry = platformDispatcher.locale.countryCode; // 如 "CN", "US"

    debugPrint(
      '[PlayerController] System locale: $systemLanguage-$systemScript-$systemCountry',
    );

    // 构建完整的语言标签用于匹配，优先级从高到低
    final possibleTags = <String>[
      if (systemScript != null && systemCountry != null)
        '$systemLanguage-$systemScript-$systemCountry', // zh-Hans-CN
      if (systemScript != null) '$systemLanguage-$systemScript', // zh-Hans
      if (systemCountry != null) '$systemLanguage-$systemCountry', // zh-CN
      systemLanguage, // zh
    ];

    debugPrint('[PlayerController] Possible language tags: $possibleTags');

    // 按优先级查找匹配
    for (final tag in possibleTags) {
      final index = _subtitles.indexWhere((s) {
        final lang = s.language.toLowerCase();
        return lang == tag.toLowerCase() ||
            lang.startsWith('$tag-') ||
            tag.startsWith('$lang-');
      });
      if (index >= 0) {
        debugPrint(
          '[PlayerController] Found language match: $tag -> index $index',
        );
        return index;
      }
    }

    // 尝试模糊匹配（仅使用语言码前缀）
    for (final tag in possibleTags) {
      final langPrefix = tag.split('-')[0];
      final index = _subtitles.indexWhere((s) {
        final lang = s.language.toLowerCase().split('-')[0];
        return lang == langPrefix;
      });
      if (index >= 0) {
        debugPrint(
          '[PlayerController] Found fuzzy language match: $langPrefix -> index $index',
        );
        return index;
      }
    }

    debugPrint('[PlayerController] No system language match found');
    return -1;
  }

  /// 确定当前字幕 ID
  ///
  /// 优先使用 trackKey（来自原生端的轨道标识），否则使用 currentIndex
  /// 当字幕关闭时返回 null
  ///
  /// 参数:
  /// - [enabled] 字幕是否开启
  /// - [trackKey] 原生端返回的轨道标识（如 "中文", "English" 或 "双语"）
  /// - [currentIndex] 当前选中的字幕索引（-1 表示关闭）
  ///
  /// 返回: 当前字幕的 language 标识，或 null（字幕关闭时）
  String? _determineCurrentSubtitleId({
    required bool enabled,
    required String? trackKey,
    required int currentIndex,
  }) {
    // 字幕关闭
    if (!enabled) return null;

    // 优先使用原生端提供的 trackKey（兼容双语和单语）
    if (trackKey != null && trackKey.isNotEmpty) {
      return trackKey;
    }

    // 降级方案：使用索引查找
    if (currentIndex >= 0 && currentIndex < _subtitles.length) {
      return _subtitles[currentIndex].language;
    }

    // 默认返回 null（字幕关闭或无效状态）
    return null;
  }

  /// 处理倍速变化（来自原生端的事件回流）
  void _handlePlaybackSpeedChanged(Map<dynamic, dynamic>? data) {
    if (data == null) return;

    final speed = data['speed'] as double?;
    if (speed != null) {
      _updateState(_state.copyWith(playbackSpeed: speed));
      debugPrint(
        '[PlayerController] Playback speed updated from native: $speed',
      );
    }
  }

  /// 处理播放完成
  void _handleCompleted() {
    _updateState(_state.copyWith(loadingState: PlayerLoadingState.completed));
  }

  /// 更新状态并通知监听者
  void _updateState(PlayerState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  /// 解析加载状态
  PlayerLoadingState _parseLoadingState(String? stateStr) {
    switch (stateStr) {
      case PlayerStateValue.idle:
        return PlayerLoadingState.idle;
      case PlayerStateValue.loading:
        return PlayerLoadingState.loading;
      case PlayerStateValue.prepared:
        return PlayerLoadingState.prepared;
      case PlayerStateValue.playing:
        return PlayerLoadingState.playing;
      case PlayerStateValue.paused:
        return PlayerLoadingState.paused;
      case PlayerStateValue.buffering:
        return PlayerLoadingState.buffering;
      case PlayerStateValue.completed:
        return PlayerLoadingState.completed;
      case PlayerStateValue.error:
        return PlayerLoadingState.error;
      default:
        return PlayerLoadingState.idle;
    }
  }

  /// 加载视频
  ///
  /// [vid] 视频 ID
  /// [autoPlay] 是否自动播放，默认 true
  Future<void> loadVideo(String vid, {bool autoPlay = true}) async {
    try {
      debugPrint(
        '[PlayerController] loadVideo called with vid: $vid, autoPlay: $autoPlay',
      );
      _updateState(PlayerState.loading(vid));
      debugPrint(
        '[PlayerController] State updated to loading, vid: ${_state.vid}',
      );

      // 自动检测离线播放模式
      final isOfflineMode = _checkIsOfflineMode(vid);
      debugPrint(
        '[PlayerController] Offline mode: $isOfflineMode for vid: $vid',
      );

      await MethodChannelHandler.loadVideo(
        _methodChannel,
        vid,
        autoPlay: autoPlay,
        isOfflineMode: isOfflineMode,
      );
      debugPrint('[PlayerController] Platform channel call completed');
    } on PlatformException catch (e) {
      debugPrint(
        '[PlayerController] PlatformException: ${e.message}, code: ${e.code}',
      );
      throw PlayerException.fromPlatformException(e);
    } catch (e) {
      debugPrint('[PlayerController] Exception: $e');
      rethrow;
    }
  }

  /// 检查指定 VID 是否可以离线播放
  ///
  /// 通过 DownloadStateManager 检查视频是否已完成下载。
  /// 如果视频已下载完成，返回 true 表示应该使用离线模式。
  bool _checkIsOfflineMode(String vid) {
    try {
      return DownloadStateManager.instance.isCompleted(vid);
    } catch (e) {
      // 如果获取下载状态失败（例如单例未正确初始化），
      // 默认返回 false 使用在线播放
      debugPrint(
        '[PlayerController] Error checking offline mode for vid $vid: $e',
      );
      return false;
    }
  }

  /// 播放
  Future<void> play() async {
    try {
      await MethodChannelHandler.play(_methodChannel);
    } on PlatformException catch (e) {
      throw PlayerException.fromPlatformException(e);
    }
  }

  /// 暂停
  Future<void> pause() async {
    try {
      await MethodChannelHandler.pause(_methodChannel);
    } on PlatformException catch (e) {
      throw PlayerException.fromPlatformException(e);
    }
  }

  /// 停止
  Future<void> stop() async {
    try {
      await MethodChannelHandler.stop(_methodChannel);
      // 保持 vid，只重置状态和进度
      _updateState(
        _state.copyWith(loadingState: PlayerLoadingState.idle, position: 0),
      );
    } on PlatformException catch (e) {
      throw PlayerException.fromPlatformException(e);
    }
  }

  /// 跳转到指定位置
  ///
  /// [position] 目标位置（毫秒）
  Future<void> seekTo(int position) async {
    try {
      await MethodChannelHandler.seekTo(_methodChannel, position);
    } on PlatformException catch (e) {
      throw PlayerException.fromPlatformException(e);
    }
  }

  /// 设置播放速度
  ///
  /// [speed] 播放速度，0.5 - 2.0
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      await MethodChannelHandler.setPlaybackSpeed(_methodChannel, speed);
      // 乐观更新：立即更新本地状态，提供即时 UI 反馈
      // 原生端也会发送 playbackSpeedChanged 事件作为确认
      _updateState(_state.copyWith(playbackSpeed: speed));
    } on PlatformException catch (e) {
      throw PlayerException.fromPlatformException(e);
    }
  }

  /// 切换清晰度
  ///
  /// [index] 清晰度索引
  Future<void> setQuality(int index) async {
    if (index < 0 || index >= _qualities.length) {
      throw PlayerException.unsupportedOperation(
        'Invalid quality index: $index',
      );
    }

    try {
      await MethodChannelHandler.setQuality(_methodChannel, index);
    } on PlatformException catch (e) {
      throw PlayerException.fromPlatformException(e);
    }
  }

  /// 设置字幕
  ///
  /// [index] 字幕索引，-1 表示关闭字幕
  Future<void> setSubtitle(int index) async {
    if (index < -1 || index >= _subtitles.length) {
      throw PlayerException.unsupportedOperation(
        'Invalid subtitle index: $index',
      );
    }

    try {
      await MethodChannelHandler.setSubtitle(_methodChannel, index);
    } on PlatformException catch (e) {
      throw PlayerException.fromPlatformException(e);
    }
  }

  /// 设置字幕（新接口，支持 enabled 和 trackKey）
  ///
  /// [enabled] 是否开启字幕
  /// [trackKey] 字幕轨道键，null 表示关闭字幕
  Future<void> setSubtitleWithKey({
    required bool enabled,
    String? trackKey,
  }) async {
    try {
      debugPrint(
        '[PlayerController] setSubtitleWithKey called: enabled=$enabled, trackKey=$trackKey',
      );
      await MethodChannelHandler.setSubtitleWithKey(
        _methodChannel,
        enabled: enabled,
        trackKey: trackKey,
      );
      _updateState(
        _state.copyWith(subtitleEnabled: enabled, currentSubtitleId: trackKey),
      );
      debugPrint(
        '[PlayerController] setSubtitleWithKey completed, state.subtitleEnabled=${_state.subtitleEnabled}, state.currentSubtitleId=${_state.currentSubtitleId}',
      );
      _saveSubtitlePreference(enabled, trackKey);
    } on PlatformException catch (e) {
      throw PlayerException.fromPlatformException(e);
    }
  }

  /// 切换字幕开关状态
  ///
  /// 如果当前有选中的字幕，则切换开关；如果没有选中字幕，则选择第一条字幕
  Future<void> toggleSubtitle() async {
    if (_state.subtitleEnabled) {
      // 当前开启，关闭字幕
      await setSubtitleWithKey(enabled: false, trackKey: null);
    } else {
      // 当前关闭，尝试开启
      if (_state.currentSubtitleId != null) {
        // 使用之前的选择
        await setSubtitleWithKey(
          enabled: true,
          trackKey: _state.currentSubtitleId,
        );
      } else if (_subtitles.isNotEmpty) {
        // 选择第一条字幕（或默认字幕）
        final defaultIndex = _selectDefaultSubtitleIndex();
        if (defaultIndex >= 0) {
          await setSubtitleWithKey(
            enabled: true,
            trackKey: _subtitles[defaultIndex].trackKey,
          );
        }
      }
    }
  }

  /// 保存字幕偏好（异步，不阻塞）
  void _saveSubtitlePreference(bool enabled, String? trackKey) {
    final vid = _state.vid;
    if (vid == null || vid.isEmpty) return;

    SubtitlePreferenceService.savePreference(
      vid: vid,
      trackKey: trackKey,
      enabled: enabled,
    ).catchError((e) {
      debugPrint('[PlayerController] Failed to save subtitle preference: $e');
    });
  }

  /// 释放资源
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    // 优先尝试释放原生播放器资源（异步，不等待结果）
    MethodChannelHandler.disposePlayer(_methodChannel).catchError((e) {
      debugPrint(
        '[PlayerController] Error disposing native player during dispose: $e',
      );
    });

    // 再尝试停止播放（异步，不等待结果）
    stop().catchError((e) {
      debugPrint('[PlayerController] Error stopping player during dispose: $e');
    });

    _eventSubscription?.cancel();
    _methodChannel.setMethodCallHandler(null);
    super.dispose();
  }
}
