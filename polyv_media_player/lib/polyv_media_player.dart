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
