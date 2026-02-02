import 'package:polyv_media_player/infrastructure/danmaku/danmaku_service.dart';

/// 弹幕 Demo 配置
///
/// 这个文件展示了如何在 Demo App 中配置和使用真实的 Polyv 弹幕 API
///
/// 使用方式：
/// ```dart
/// final service = DanmakuDemoConfig.createDanmakuService();
/// final danmakus = await service.fetchDanmakus('video123');
/// ```
class DanmakuDemoConfig {
  /// Polyv 用户 ID
  ///
  /// 从 Polyv 控制台获取
  static const String userId = 'YOUR_USER_ID';

  /// 读取令牌（用于获取弹幕列表）
  ///
  /// 从 Polyv 控制台获取
  static const String readToken = 'YOUR_READ_TOKEN';

  /// 写入令牌（用于发送弹幕）
  ///
  /// 从 Polyv 控制台获取
  static const String writeToken = 'YOUR_WRITE_TOKEN';

  /// 密钥（用于签名）
  ///
  /// 从 Polyv 控制台获取
  static const String secretKey = 'YOUR_SECRET_KEY';

  /// 是否使用真实 API
  ///
  /// 设置为 false 使用 Mock 服务，true 使用真实 API
  static const bool useRealApi = false;

  /// 创建弹幕服务
  ///
  /// 根据 [useRealApi] 配置返回 Mock 服务或真实 HTTP 服务
  static DanmakuService createDanmakuService() {
    if (useRealApi) {
      // 使用真实 API
      if (userId == 'YOUR_USER_ID' ||
          readToken == 'YOUR_READ_TOKEN' ||
          secretKey == 'YOUR_SECRET_KEY') {
        // 未配置真实凭据，使用 Mock 服务
        return DanmakuServiceFactory.createMock();
      }

      return DanmakuServiceFactory.createHttp(
        userId: userId,
        readToken: readToken,
        secretKey: secretKey,
      );
    } else {
      // 使用 Mock 服务
      return DanmakuServiceFactory.createMock();
    }
  }

  /// 创建弹幕发送服务
  ///
  /// 根据 [useRealApi] 配置返回 Mock 服务或真实 HTTP 服务
  static DanmakuSendService createDanmakuSendService({
    DanmakuSendConfig? config,
  }) {
    if (useRealApi) {
      // 使用真实 API
      if (userId == 'YOUR_USER_ID' ||
          writeToken == 'YOUR_WRITE_TOKEN' ||
          secretKey == 'YOUR_SECRET_KEY') {
        // 未配置真实凭据，使用 Mock 服务
        return DanmakuSendServiceFactory.createMock(config: config);
      }

      return DanmakuSendServiceFactory.createHttp(
        userId: userId,
        writeToken: writeToken,
        secretKey: secretKey,
        config: config,
      );
    } else {
      // 使用 Mock 服务
      return DanmakuSendServiceFactory.createMock(config: config);
    }
  }

  /// 检查是否配置了真实凭据
  static bool isConfigured() {
    return useRealApi &&
        userId != 'YOUR_USER_ID' &&
        readToken != 'YOUR_READ_TOKEN' &&
        writeToken != 'YOUR_WRITE_TOKEN' &&
        secretKey != 'YOUR_SECRET_KEY';
  }
}
