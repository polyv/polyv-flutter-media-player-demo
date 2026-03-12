library;

/// Polyv Media Player Plugin
///
/// A Flutter plugin for Polyv Media Player SDK (iOS/Android).
/// 提供视频播放核心能力，UI 由 Demo App 示例实现。

// Core exports
export 'core/player_controller.dart';
export 'core/player_state.dart';
export 'core/player_events.dart';
export 'core/player_exception.dart';
export 'core/player_config.dart';

// Platform Channel exports
export 'platform_channel/player_api.dart';
export 'platform_channel/method_channel_handler.dart';

// Services exports
export 'services/subtitle_preference_service.dart';
export 'services/video_progress_service.dart';
export 'services/player_initializer.dart';
export 'services/polyv_config_service.dart';

// Infrastructure exports (shared business services)
export 'infrastructure/danmaku/danmaku_model.dart';
export 'infrastructure/danmaku/danmaku_service.dart';
export 'infrastructure/video_list/video_list_models.dart';
export 'infrastructure/video_list/video_list_exception.dart';
export 'infrastructure/video_list/video_list_service.dart';
export 'infrastructure/download/download_task.dart';
export 'infrastructure/download/download_task_status.dart';
export 'infrastructure/download/download_state_manager.dart';

// Widget exports
export 'widgets/polyv_video_view.dart';
export 'widgets/polyv_video_player.dart';

// UI component exports
export 'ui/player_colors.dart';
export 'ui/control_bar.dart';
export 'ui/subtitle_toggle.dart';
export 'ui/progress_slider/progress_slider.dart';
export 'ui/progress_slider/time_label.dart';
export 'ui/quality_selector/quality_selector.dart';
export 'ui/speed_selector/speed_selector.dart';

// UI feature component exports
export 'ui/control_bar_state_machine.dart';
export 'ui/double_tap_detector.dart';
export 'ui/gestures/gestures.dart';
export 'ui/danmaku/danmaku.dart';
export 'ui/settings_menu/settings_menu.dart';

import 'services/polyv_config_service.dart';

/// Polyv Media Player 主类
///
/// 提供便捷的初始化和配置方法
class PolyvMediaPlayer {
  PolyvMediaPlayer._();

  /// 初始化 Polyv SDK
  ///
  /// 必须在使用播放器之前调用，通常在 main() 中
  ///
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///
  ///   await PolyvMediaPlayer.initialize(
  ///     userId: 'your_user_id',
  ///     secretKey: 'your_secret_key',
  ///   );
  ///
  ///   runApp(const MyApp());
  /// }
  /// ```
  static Future<void> initialize({
    required String userId,
    required String secretKey,
    String? readToken,
    String? writeToken,
  }) async {
    await PolyvConfigService().setAccountConfig(
      userId: userId,
      secretKey: secretKey,
      readToken: readToken,
      writeToken: writeToken,
    );
  }

  /// 检查 SDK 是否已初始化
  static bool get isInitialized => PolyvConfigService().isConfigInjected;

  /// 获取当前配置的用户 ID
  static Future<String> get userId async => PolyvConfigService().getUserId();
}
