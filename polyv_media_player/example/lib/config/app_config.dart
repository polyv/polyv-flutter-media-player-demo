import 'package:flutter/foundation.dart';
import 'package:polyv_media_player/services/polyv_config_service.dart';

/// Polyv 应用配置
///
/// 从编译时定义的环境变量中读取配置
/// 使用方式：
/// ```bash
/// flutter run --dart-define=POLYV_USER_ID=xxx --dart-define=POLYV_SECRET_KEY=xxx
/// ```
class AppConfig {
  /// Polyv 用户 ID（必填）
  static String get userId =>
      const String.fromEnvironment('POLYV_USER_ID', defaultValue: '');

  /// Polyv 密钥（必填）
  static String get secretKey =>
      const String.fromEnvironment('POLYV_SECRET_KEY', defaultValue: '');

  /// 读 Token（可选）
  static String get readToken =>
      const String.fromEnvironment('POLYV_READ_TOKEN', defaultValue: '');

  /// 写 Token（可选）
  static String get writeToken =>
      const String.fromEnvironment('POLYV_WRITE_TOKEN', defaultValue: '');

  /// 检查配置是否有效
  static bool get isValid => userId.isNotEmpty && secretKey.isNotEmpty;

  /// 将配置注入到原生层
  ///
  /// 应在应用启动时调用，在使用播放器功能之前
  static Future<void> inject() async {
    if (!isValid) {
      debugPrint(
        '[AppConfig] WARNING: Polyv config is invalid. '
        'Please use --dart-define=POLYV_USER_ID=xxx --dart-define=POLYV_SECRET_KEY=xxx',
      );
      return;
    }

    try {
      await PolyvConfigService().setAccountConfig(
        userId: userId,
        secretKey: secretKey,
        readToken: readToken.isEmpty ? null : readToken,
        writeToken: writeToken.isEmpty ? null : writeToken,
      );
      debugPrint('[AppConfig] Config injected successfully');
    } catch (e) {
      debugPrint('[AppConfig] Failed to inject config: $e');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'AppConfig(userId: $userId, secretKey: ${secretKey.isNotEmpty ? '***' : ''}, '
        'readToken: ${readToken.isNotEmpty ? '***' : ''}, writeToken: ${writeToken.isNotEmpty ? '***' : ''})';
  }
}
