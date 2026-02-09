import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../platform_channel/event_channel_handler.dart';
import '../platform_channel/method_channel_handler.dart';
import '../platform_channel/player_api.dart';
import '../services/subtitle_preference_service.dart';
import '../services/video_progress_service.dart';
import '../infrastructure/download/download_state_manager.dart';
import '../utils/plv_logger.dart';
import 'player_exception.dart';
import 'player_state.dart';
import 'player_events.dart';
import 'player_event_parser.dart';
import 'subtitle_selection_policy.dart';
import 'system_locale_provider.dart';
import 'offline_playback_decider.dart';

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

  final PlayerEventParser _eventParser;
  final SubtitleSelectionPolicy _subtitleSelectionPolicy;
  final SystemLocaleProvider _systemLocaleProvider;
  final OfflinePlaybackDecider _offlinePlaybackDecider;

  /// 是否已释放
  bool _disposed = false;

  /// 上次保存进度的时间（用于节流）
  int? _lastProgressSaveTime;

  /// 当前视频是否已恢复过播放进度（避免重复恢复）
  bool _hasRestoredProgress = false;

  /// 切换视频期间的最后位置（用于在切换前保存进度）
  int? _pendingSavePosition;
  int? _pendingSaveDuration;

  /// 是否正在切换视频（用于忽略切换期间的进度更新）
  bool _isSwitchingVideo = false;

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
  PlayerController({
    String? methodChannelName,
    String? eventChannelName,
    PlayerEventParser? eventParser,
    SubtitleSelectionPolicy? subtitleSelectionPolicy,
    SystemLocaleProvider? systemLocaleProvider,
    OfflinePlaybackDecider? offlinePlaybackDecider,
  }) : _methodChannel = MethodChannel(methodChannelName ?? _kMethodChannelName),
       _eventChannel = EventChannel(eventChannelName ?? _kEventChannelName),
       _eventParser = eventParser ?? const PlayerEventParser(),
       _subtitleSelectionPolicy =
           subtitleSelectionPolicy ?? const SubtitleSelectionPolicy(),
       _systemLocaleProvider =
           systemLocaleProvider ?? const PlatformSystemLocaleProvider(),
       _offlinePlaybackDecider =
           offlinePlaybackDecider ??
           OfflinePlaybackDecider(
             isDownloaded: (vid) {
               try {
                 return DownloadStateManager.instance.isCompleted(vid);
               } catch (e) {
                 PlvLogger.w(
                   '[PlayerController] Error checking offline mode for vid $vid: $e',
                 );
                 return false;
               }
             },
           ) {
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
        PlvLogger.d('[PlayerController] Unknown method call: ${call.method}');
    }
  }

  /// 处理事件
  void _onEvent(dynamic event) {
    // 频繁日志已移除，减少控制台噪音
    if (_disposed) {
      PlvLogger.d(
        '[PlayerController] _onEvent: controller is disposed, ignoring',
      );
      return;
    }

    final parsed = _eventParser.tryParse(event);
    if (parsed == null) {
      PlvLogger.d(
        '[PlayerController] _onEvent: event is not Map, it is ${event.runtimeType}',
      );
      return;
    }

    final typeStr = parsed.type;
    final data = parsed.data;

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
        PlvLogger.d('[PlayerController] Unknown event type: $typeStr');
    }
  }

  /// 处理事件错误
  void _onEventError(dynamic error) {
    PlvLogger.w('[PlayerController] Event error: $error');
  }

  /// 处理状态变化
  void _handleStateChanged(Map<dynamic, dynamic>? data) {
    if (data == null) return;

    final stateStr = data['state']?.toString();
    final newState = _parseLoadingState(stateStr);

    PlvLogger.d('[PlayerController] _handleStateChanged: $stateStr -> $newState, hasRestored: $_hasRestoredProgress');

    _updateState(_state.copyWith(loadingState: newState));

    // 当视频准备完成时，清除切换标志并尝试恢复之前保存的播放进度
    // 必须在 prepared 状态时恢复，因为原生层在 prepared 之后会 seek 到 0
    if (newState == PlayerLoadingState.prepared && !_hasRestoredProgress) {
      PlvLogger.d('[PlayerController] _handleStateChanged: Triggering progress restore at prepared');
      _hasRestoredProgress = true;
      _isSwitchingVideo = false; // 清除切换标志
      _restoreSavedProgress();
    }
  }

  /// 恢复之前保存的播放进度
  Future<void> _restoreSavedProgress() async {
    final vid = _state.vid;
    if (vid == null || vid.isEmpty) {
      PlvLogger.w('[PlayerController] _restoreSavedProgress: vid is null or empty');
      return;
    }

    PlvLogger.d('[PlayerController] _restoreSavedProgress: Attempting to restore progress for $vid');

    try {
      final savedPosition = await VideoProgressService.loadProgress(vid);
      PlvLogger.d('[PlayerController] _restoreSavedProgress: savedPosition = $savedPosition');

      if (savedPosition != null && savedPosition > 0) {
        PlvLogger.d('[PlayerController] _restoreSavedProgress: Seeking to $savedPosition ms');
        // 先暂停，确保 seek 时不会开始播放
        await pause();
        // 延迟确保原生层的 seekToTime:0.0 已完成
        await Future.delayed(const Duration(milliseconds: 200));
        await seekTo(savedPosition);

        // 恢复进度后继续播放（因为 loadVideo 默认 autoPlay=true）
        await play();
        PlvLogger.d('[PlayerController] _restoreSavedProgress: Successfully restored to $savedPosition ms and resumed playback');
      } else {
        PlvLogger.d('[PlayerController] _restoreSavedProgress: No saved position to restore');
      }
    } catch (e) {
      PlvLogger.w('[PlayerController] Failed to restore saved progress: $e');
    }
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

    // 如果正在切换视频，忽略进度更新（防止 stop() 导致的 position=0 覆盖新视频进度）
    // 但仍然更新 pendingSavePosition，以便在加载新视频前保存旧视频的最后进度
    if (_isSwitchingVideo) {
      PlvLogger.d('[PlayerController] Ignoring progress save during video switch');
      return;
    }

    // 节流保存播放进度（避免频繁写入 SharedPreferences）
    _saveProgressThrottled(position, duration);
  }

  /// 节流保存播放进度
  ///
  /// 基于时间间隔节流，避免频繁写入 SharedPreferences
  void _saveProgressThrottled(int position, int duration) {
    final now = DateTime.now().millisecondsSinceEpoch;
    const minInterval = 1000; // 1秒

    // 检查是否需要保存（基于时间间隔）
    if (_lastProgressSaveTime == null ||
        (now - (_lastProgressSaveTime ?? 0)) >= minInterval) {
      _lastProgressSaveTime = now;

      // 保存当前状态用于可能的延迟保存
      _pendingSavePosition = position;
      _pendingSaveDuration = duration;

      final vid = _state.vid;
      if (vid == null || vid.isEmpty) {
        PlvLogger.w('[PlayerController] Cannot save progress: vid is null or empty');
        return;
      }

      PlvLogger.d('[PlayerController] Saving progress: ${position}ms for vid: $vid');

      // 异步保存，不阻塞播放
      VideoProgressService.saveProgress(
        vid: vid,
        position: position,
        duration: duration,
      );
    }
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
    PlvLogger.d('[PlayerController] _handleQualityChanged called, data: $data');
    if (data == null) return;

    final qualitiesList = data['qualities'] as List<dynamic>?;
    final currentIndex = data['currentIndex'] as int? ?? 0;

    PlvLogger.d(
      '[PlayerController] qualitiesList: $qualitiesList, currentIndex: $currentIndex',
    );

    if (qualitiesList != null) {
      _qualities = qualitiesList.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return QualityItem.fromJson(map);
      }).toList();
      _currentQualityIndex = currentIndex;
      PlvLogger.d(
        '[PlayerController] Updated qualities: ${_qualities.length} items, current: $_currentQualityIndex',
      );
      notifyListeners();
    }
  }

  /// 处理字幕变化
  void _handleSubtitleChanged(Map<dynamic, dynamic>? data) {
    PlvLogger.d(
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

      PlvLogger.d(
        '[PlayerController] Parsed subtitles: count=${_subtitles.length}, currentIndex=$currentIndex, enabled=$enabled, trackKey=$trackKey',
      );

      // 如果是关闭字幕事件（enabled == false 且 currentIndex < 0），
      // 不要触发默认算法或用户偏好恢复，直接更新为关闭状态。
      if (!enabled && currentIndex < 0) {
        PlvLogger.d(
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

      PlvLogger.d(
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
          PlvLogger.d(
            '[PlayerController] Applying user preference: ${preference.trackKey} at index $savedIndex',
          );
          await setSubtitleWithKey(
            enabled: true,
            trackKey: preference.trackKey,
          );
          return;
        } else {
          PlvLogger.d(
            '[PlayerController] Saved subtitle trackKey "${preference.trackKey}" not found in current list',
          );
        }
      } else {
        PlvLogger.d(
          '[PlayerController] No saved subtitle preference for vid: $vid',
        );
      }

      // 没有有效偏好，使用默认算法
      _applyDefaultSelection();
    } catch (e) {
      PlvLogger.w(
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
      PlvLogger.d(
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
        PlvLogger.w(
          '[PlayerController] Failed to sync default subtitle to native: $e',
        );
      });
    } else {
      // 没有可用字幕
      PlvLogger.d(
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
      PlvLogger.d(
        '[PlayerController] Selected bilingual subtitle at index $bilingualIndex',
      );
      return bilingualIndex;
    }

    // 2. 单语与系统语言匹配
    final systemLanguageIndex = _findBestLanguageMatchIndex();
    if (systemLanguageIndex >= 0) {
      PlvLogger.d(
        '[PlayerController] Selected system language match at index $systemLanguageIndex',
      );
      return systemLanguageIndex;
    }

    // 3. 其次选择原生标记为默认的
    final defaultIndex = _subtitles.indexWhere((s) => s.isDefault);
    if (defaultIndex >= 0) {
      PlvLogger.d(
        '[PlayerController] Selected default subtitle at index $defaultIndex',
      );
      return defaultIndex;
    }

    // 4. 否则选择第一条字幕
    PlvLogger.d('[PlayerController] Selected first subtitle at index 0');
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
    final locale = _systemLocaleProvider.currentLocale;
    PlvLogger.d(
      '[PlayerController] System locale: ${locale.languageCode}-${locale.scriptCode}-${locale.countryCode}',
    );

    final index = _subtitleSelectionPolicy.findBestLanguageMatchIndex(
      subtitles: _subtitles,
      locale: locale,
    );
    PlvLogger.d('[PlayerController] Best language match index: $index');
    return index;
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
    return _subtitleSelectionPolicy.determineCurrentSubtitleId(
      enabled: enabled,
      trackKey: trackKey,
      currentIndex: currentIndex,
      subtitles: _subtitles,
    );
  }

  /// 处理倍速变化（来自原生端的事件回流）
  void _handlePlaybackSpeedChanged(Map<dynamic, dynamic>? data) {
    if (data == null) return;

    final speed = data['speed'] as double?;
    if (speed != null) {
      _updateState(_state.copyWith(playbackSpeed: speed));
      PlvLogger.d(
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
      PlvLogger.d(
        '[PlayerController] loadVideo called with vid: $vid, autoPlay: $autoPlay',
      );

      // 在切换视频前，先保存当前视频的最后进度
      // 这是为了防止 stop() 导致的延迟进度事件覆盖新视频的进度
      final currentVid = _state.vid;
      if (currentVid != null &&
          currentVid.isNotEmpty &&
          currentVid != vid &&
          _pendingSavePosition != null &&
          _pendingSaveDuration != null) {
        PlvLogger.d(
          '[PlayerController] Saving final progress for $currentVid before switching: ${_pendingSavePosition}ms',
        );
        VideoProgressService.saveProgress(
          vid: currentVid,
          position: _pendingSavePosition!,
          duration: _pendingSaveDuration!,
        );
      }

      // 重置节流状态和恢复标志
      _lastProgressSaveTime = null;
      _hasRestoredProgress = false;
      _pendingSavePosition = null;
      _pendingSaveDuration = null;

      // 设置切换标志，忽略切换期间的进度更新
      _isSwitchingVideo = true;

      // 使用 copyWith 保留当前倍速状态，但重置 position/duration/bufferedPosition
      // 稍后会尝试恢复保存的播放进度
      _updateState(_state.copyWith(
        loadingState: PlayerLoadingState.loading,
        vid: vid,
        position: 0,
        duration: 0,
        bufferedPosition: 0,
      ));
      PlvLogger.d(
        '[PlayerController] State updated to loading, vid: ${_state.vid}, speed: ${_state.playbackSpeed}',
      );

      // 自动检测离线播放模式
      final isOfflineMode = _checkIsOfflineMode(vid);
      PlvLogger.d(
        '[PlayerController] Offline mode: $isOfflineMode for vid: $vid',
      );

      await MethodChannelHandler.loadVideo(
        _methodChannel,
        vid,
        autoPlay: autoPlay,
        isOfflineMode: isOfflineMode,
      );
      PlvLogger.d('[PlayerController] Platform channel call completed');

      // 加载完成后，清除切换标志（prepared 状态会自动清除）
    } on PlatformException catch (e) {
      // 发生异常时也要清除切换标志
      _isSwitchingVideo = false;
      PlvLogger.w(
        '[PlayerController] PlatformException: ${e.message}, code: ${e.code}',
      );
      throw PlayerException.fromPlatformException(e);
    } catch (e) {
      // 发生异常时也要清除切换标志
      _isSwitchingVideo = false;
      PlvLogger.w('[PlayerController] Exception: $e');
      rethrow;
    }
  }

  /// 检查指定 VID 是否可以离线播放
  ///
  /// 通过 DownloadStateManager 检查视频是否已完成下载。
  /// 如果视频已下载完成，返回 true 表示应该使用离线模式。
  bool _checkIsOfflineMode(String vid) {
    return _offlinePlaybackDecider.shouldUseOfflineMode(vid);
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

  /// 重播（从头开始播放）
  ///
  /// 清除当前视频的播放进度记录，并从头开始播放
  Future<void> replay() async {
    final vid = _state.vid;
    if (vid != null && vid.isNotEmpty) {
      // 清除保存的播放进度
      await VideoProgressService.clearProgress(vid);
    }

    // 跳转到开头并播放
    await seekTo(0);
    await play();
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
      PlvLogger.d(
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
      PlvLogger.d(
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
      PlvLogger.w('[PlayerController] Failed to save subtitle preference: $e');
    });
  }

  /// 释放资源
  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    // 优先尝试释放原生播放器资源（异步，不等待结果）
    MethodChannelHandler.disposePlayer(_methodChannel).catchError((e) {
      PlvLogger.w(
        '[PlayerController] Error disposing native player during dispose: $e',
      );
    });

    // 再尝试停止播放（异步，不等待结果）
    stop().catchError((e) {
      PlvLogger.w(
        '[PlayerController] Error stopping player during dispose: $e',
      );
    });

    _eventSubscription?.cancel();
    _methodChannel.setMethodCallHandler(null);
    super.dispose();
  }
}
