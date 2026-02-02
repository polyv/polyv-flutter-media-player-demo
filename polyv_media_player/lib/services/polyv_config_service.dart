import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../platform_channel/player_api.dart';
import '../platform_channel/method_channel_handler.dart';

/// Polyv 配置模型
class PolyvConfigModel {
  final String userId;
  final String readToken;
  final String writeToken;
  final String secretKey;

  const PolyvConfigModel({
    required this.userId,
    required this.readToken,
    required this.writeToken,
    required this.secretKey,
  });

  /// 从 JSON 创建
  factory PolyvConfigModel.fromJson(Map<String, dynamic> json) {
    return PolyvConfigModel(
      userId: json['userId']?.toString() ?? '',
      readToken: json['readToken']?.toString() ?? '',
      writeToken: json['writeToken']?.toString() ?? '',
      secretKey: json['secretKey']?.toString() ?? '',
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'readToken': readToken,
      'writeToken': writeToken,
      'secretKey': secretKey,
    };
  }

  /// 判断配置是否有效
  bool get isValid => userId.isNotEmpty && secretKey.isNotEmpty;

  @override
  String toString() {
    return 'PolyvConfigModel(userId: $userId, readToken: ${readToken.isNotEmpty ? '***' : ''}, secretKey: ${secretKey.isNotEmpty ? '***' : ''})';
  }
}

/// Polyv 配置服务
///
/// 单例模式，负责从原生层读取并缓存 Polyv 配置信息
/// 支持从 Flutter 层向原生层注入配置（替代 Info.plist/AndroidManifest 配置）
class PolyvConfigService {
  /// 单例实例
  static final PolyvConfigService _instance = PolyvConfigService._internal();
  factory PolyvConfigService() => _instance;
  PolyvConfigService._internal();

  /// Method Channel
  final MethodChannel _methodChannel = MethodChannel(
    PlayerApi.methodChannelName,
  );

  /// 缓存的配置
  PolyvConfigModel? _config;

  /// 加载状态
  bool _isLoading = false;

  /// 是否已从 Flutter 层注入配置
  bool _isConfigInjected = false;

  /// 获取当前配置（如果已加载）
  PolyvConfigModel? get config => _config;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 是否已加载配置
  bool get isConfigLoaded => _config != null;

  /// 是否已从 Flutter 层注入配置
  bool get isConfigInjected => _isConfigInjected;

  /// 从原生层获取配置
  ///
  /// 首次调用时会从原生层读取，后续调用会返回缓存的值
  /// 如果 forceReload 为 true，则会强制从原生层重新读取
  Future<PolyvConfigModel> getConfig({bool forceReload = false}) async {
    // 如果已有配置且不强制重新加载，直接返回缓存
    if (_config != null && !forceReload) {
      return _config!;
    }

    // 防止重复加载
    if (_isLoading) {
      // 等待当前加载完成
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 50));
        return _isLoading;
      });
      if (_config != null) {
        return _config!;
      }
    }

    _isLoading = true;

    try {
      debugPrint('[PolyvConfigService] Loading config from native layer...');

      final configMap = await MethodChannelHandler.getConfig(_methodChannel);

      _config = PolyvConfigModel.fromJson(configMap);

      debugPrint('[PolyvConfigService] Config loaded: $_config');

      if (!_config!.isValid) {
        debugPrint('[PolyvConfigService] WARNING: Config is invalid!');
      }

      return _config!;
    } catch (e) {
      debugPrint('[PolyvConfigService] Failed to load config: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// 清除缓存的配置
  void clearCache() {
    debugPrint('[PolyvConfigService] Clearing config cache');
    _config = null;
  }

  /// 获取用户 ID（快捷方法）
  Future<String> getUserId() async {
    final config = await getConfig();
    return config.userId;
  }

  /// 获取 Read Token（快捷方法）
  Future<String> getReadToken() async {
    final config = await getConfig();
    return config.readToken;
  }

  /// 获取 Write Token（快捷方法）
  Future<String> getWriteToken() async {
    final config = await getConfig();
    return config.writeToken;
  }

  /// 获取 Secret Key（快捷方法）
  Future<String> getSecretKey() async {
    final config = await getConfig();
    return config.secretKey;
  }

  /// 向原生层注入配置
  ///
  /// 此方法允许在运行时动态设置账号信息，替代 Info.plist/AndroidManifest 配置
  /// 建议在应用启动时调用，使用 --dart-define 传入的配置
  ///
  /// 示例：
  /// ```dart
  /// await PolyvConfigService().setAccountConfig(
  ///   userId: const String.fromEnvironment('POLYV_USER_ID'),
  ///   secretKey: const String.fromEnvironment('POLYV_SECRET_KEY'),
  ///   readToken: const String.fromEnvironment('POLYV_READ_TOKEN'),
  ///   writeToken: const String.fromEnvironment('POLYV_WRITE_TOKEN'),
  /// );
  /// ```
  Future<void> setAccountConfig({
    required String userId,
    required String secretKey,
    String? readToken,
    String? writeToken,
  }) async {
    debugPrint('[PolyvConfigService] Injecting account config...');

    try {
      await _methodChannel.invokeMethod('initialize', {
        'userId': userId,
        'secretKey': secretKey,
        'readToken': readToken ?? '',
        'writeToken': writeToken ?? '',
      });

      // 更新本地缓存
      _config = PolyvConfigModel(
        userId: userId,
        readToken: readToken ?? '',
        writeToken: writeToken ?? '',
        secretKey: secretKey,
      );
      _isConfigInjected = true;

      debugPrint(
        '[PolyvConfigService] Account config injected successfully: userId=$userId',
      );
    } catch (e) {
      debugPrint('[PolyvConfigService] Failed to inject account config: $e');
      rethrow;
    }
  }
}
