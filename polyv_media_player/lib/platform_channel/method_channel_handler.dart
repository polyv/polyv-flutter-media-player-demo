import 'package:flutter/services.dart';

import 'player_api.dart';
import '../core/player_config.dart';

class MethodChannelHandler {
  /// 初始化播放器账号配置
  ///
  /// 此方法应由 Demo App 在启动时调用，用于配置播放器所需的账号信息。
  /// 支持多次调用以实现热重载（清除旧配置，应用新配置）。
  static Future<void> initialize(MethodChannel channel, PlayerConfig config) {
    return channel.invokeMethod<void>(PlayerMethod.initialize, config.toJson());
  }

  static Future<void> loadVideo(
    MethodChannel channel,
    String vid, {
    bool autoPlay = true,
    bool isOfflineMode = false,
  }) {
    return channel.invokeMethod<void>(PlayerMethod.loadVideo, <String, dynamic>{
      'vid': vid,
      'autoPlay': autoPlay,
      'isOfflineMode': isOfflineMode,
    });
  }

  static Future<void> play(MethodChannel channel) {
    return channel.invokeMethod<void>(PlayerMethod.play);
  }

  static Future<void> pause(MethodChannel channel) {
    return channel.invokeMethod<void>(PlayerMethod.pause);
  }

  static Future<void> stop(MethodChannel channel) {
    return channel.invokeMethod<void>(PlayerMethod.stop);
  }

  /// 释放原生播放器资源
  static Future<void> disposePlayer(MethodChannel channel) {
    return channel.invokeMethod<void>(PlayerMethod.disposePlayer);
  }

  static Future<void> seekTo(MethodChannel channel, int position) {
    return channel.invokeMethod<void>(PlayerMethod.seekTo, <String, dynamic>{
      'position': position,
    });
  }

  static Future<void> setPlaybackSpeed(MethodChannel channel, double speed) {
    return channel.invokeMethod<void>(
      PlayerMethod.setPlaybackSpeed,
      <String, dynamic>{'speed': speed},
    );
  }

  static Future<void> setQuality(
    MethodChannel channel,
    int index, {
    int? position,
  }) {
    return channel.invokeMethod<void>(
      PlayerMethod.setQuality,
      <String, dynamic>{'index': index, 'position': position},
    );
  }

  static Future<void> setSubtitle(MethodChannel channel, int index) {
    return channel.invokeMethod<void>(
      PlayerMethod.setSubtitle,
      <String, dynamic>{'index': index},
    );
  }

  static Future<void> setSubtitleWithKey(
    MethodChannel channel, {
    required bool enabled,
    String? trackKey,
  }) {
    return channel.invokeMethod<void>(
      PlayerMethod.setSubtitle,
      <String, dynamic>{'enabled': enabled, 'trackKey': trackKey},
    );
  }

  /// 获取原生配置信息
  ///
  /// 返回 Map 包含：
  /// - userId: 用户 ID
  /// - readToken: 读取令牌
  /// - writeToken: 写入令牌
  /// - secretKey: 密钥
  static Future<Map<String, String>> getConfig(MethodChannel channel) async {
    final result = await channel.invokeMapMethod<String, dynamic>(
      PlayerMethod.getConfig,
    );
    return {
      'userId': result?['userId']?.toString() ?? '',
      'readToken': result?['readToken']?.toString() ?? '',
      'writeToken': result?['writeToken']?.toString() ?? '',
      'secretKey': result?['secretKey']?.toString() ?? '',
    };
  }

  /// 设置屏幕亮度
  ///
  /// [brightness] 亮度值，范围 0.0 - 1.0
  static Future<void> setScreenBrightness(
    MethodChannel channel,
    double brightness,
  ) {
    final clampedBrightness = brightness.clamp(0.0, 1.0);
    return channel.invokeMethod<void>(
      PlayerMethod.setScreenBrightness,
      <String, dynamic>{'brightness': clampedBrightness},
    );
  }

  /// 获取屏幕亮度
  ///
  /// 返回当前屏幕亮度值，范围 0.0 - 1.0
  /// 如果获取失败，返回 0.5（默认值）
  static Future<double> getScreenBrightness(MethodChannel channel) async {
    try {
      final result = await channel.invokeMethod<double>(
        PlayerMethod.getScreenBrightness,
      );
      return result?.clamp(0.0, 1.0) ?? 0.5;
    } catch (e) {
      return 0.5;
    }
  }

  /// 设置系统音量
  ///
  /// [volume] 音量值，范围 0.0 - 1.0
  static Future<void> setVolume(MethodChannel channel, double volume) {
    final clampedVolume = volume.clamp(0.0, 1.0);
    return channel.invokeMethod<void>(PlayerMethod.setVolume, <String, dynamic>{
      'volume': clampedVolume,
    });
  }

  /// Story 9.3: 暂停下载任务
  ///
  /// [vid] 视频 VID
  static Future<void> pauseDownload(MethodChannel channel, String vid) {
    return channel.invokeMethod<void>(
      PlayerMethod.pauseDownload,
      <String, dynamic>{'vid': vid},
    );
  }

  /// Story 9.3: 继续下载任务
  ///
  /// [vid] 视频 VID
  static Future<void> resumeDownload(MethodChannel channel, String vid) {
    return channel.invokeMethod<void>(
      PlayerMethod.resumeDownload,
      <String, dynamic>{'vid': vid},
    );
  }

  /// Story 9.3: 重试下载任务
  ///
  /// [vid] 视频 VID
  static Future<void> retryDownload(MethodChannel channel, String vid) {
    return channel.invokeMethod<void>(
      PlayerMethod.retryDownload,
      <String, dynamic>{'vid': vid},
    );
  }

  /// Story 9.5: 删除下载任务
  ///
  /// [vid] 视频 VID
  static Future<void> deleteDownload(MethodChannel channel, String vid) {
    return channel.invokeMethod<void>(
      PlayerMethod.deleteDownload,
      <String, dynamic>{'vid': vid},
    );
  }

  /// Story 9.8: 获取下载任务列表（权威同步）
  ///
  /// 从原生 SDK 获取当前所有下载任务的权威列表。
  /// 返回任务列表的 JSON 数组，每个任务包含：
  /// - id: 任务 ID
  /// - vid: 视频 VID
  /// - title: 视频标题
  /// - thumbnail: 缩略图 URL（可选）
  /// - totalBytes: 文件总大小
  /// - downloadedBytes: 已下载大小
  /// - bytesPerSecond: 下载速度
  /// - status: 任务状态（preparing/waiting/downloading/paused/completed/error）
  /// - errorMessage: 错误信息（可选）
  /// - createdAt: 创建时间（ISO8601 格式）
  /// - completedAt: 完成时间（ISO8601 格式，可选）
  static Future<List<Map<String, dynamic>>> getDownloadList(
    MethodChannel channel,
  ) async {
    final result = await channel.invokeMethod<List<dynamic>>(
      PlayerMethod.getDownloadList,
    );
    if (result == null) return [];
    return result
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  /// Story 9.9: 创建下载任务（添加视频到下载队列）
  ///
  /// 调用原生层创建新的下载任务。原生 SDK 会将视频添加到下载队列并开始下载。
  ///
  /// 参数：
  /// - vid: 视频 VID
  /// - title: 视频标题（可选，用于显示）
  ///
  /// 返回值：
  /// - 成功时返回 null
  /// - 失败时抛出 PlatformException
  static Future<void> startDownload(
    MethodChannel channel,
    String vid, {
    String? title,
    String? quality, // 清晰度值: "480p", "720p", "1080p"
  }) {
    return channel.invokeMethod<void>(
      PlayerMethod.startDownload,
      <String, dynamic>{
        'vid': vid,
        if (title != null) 'title': title,
        if (quality != null) 'quality': quality,
      },
    );
  }
}
