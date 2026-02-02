import 'package:flutter/services.dart';
import '../core/player_config.dart';
import '../core/player_exception.dart';
import '../platform_channel/method_channel_handler.dart';
import '../platform_channel/player_api.dart';

/// 播放器初始化服务
///
/// 提供 static 方法用于初始化播放器账号配置。
/// 此服务仅由 Demo App 使用，用于统一配置播放器账号信息。
class PlayerInitializer {
  /// Method Channel 实例
  static const MethodChannel _methodChannel = MethodChannel(
    PlayerApi.methodChannelName,
  );

  /// 当前生效的账号配置
  static PlayerConfig? _currentConfig;

  /// 获取当前生效的账号配置
  static PlayerConfig? get currentConfig => _currentConfig;

  /// 初始化播放器账号配置
  ///
  /// 此方法应在 App 启动时调用，用于配置播放器所需的账号信息。
  /// 支持多次调用以实现热重载（清除旧配置，应用新配置）。
  ///
  /// 参数:
  /// - [config] 账号配置对象，包含 userId、readToken、writeToken、secretKey 等字段
  ///
  /// 抛出:
  /// - [PlayerException] 当原生层返回错误时
  static Future<void> initialize(PlayerConfig config) async {
    // 校验配置
    final errors = config.validate();
    if (errors.isNotEmpty) {
      throw ArgumentError('Invalid PlayerConfig: ${errors.join(', ')}');
    }

    // 调用原生层初始化方法
    try {
      await MethodChannelHandler.initialize(_methodChannel, config);
      _currentConfig = config;
    } on PlatformException catch (e) {
      throw PlayerException(
        code: e.code,
        message: e.message ?? 'Failed to initialize player config',
      );
    }
  }

  /// 重置当前配置
  static void reset() {
    _currentConfig = null;
  }
}
