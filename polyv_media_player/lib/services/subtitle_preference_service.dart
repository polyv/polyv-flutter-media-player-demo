import 'package:shared_preferences/shared_preferences.dart';
import '../core/player_events.dart';

/// 字幕偏好服务
///
/// 负责保存和加载用户的字幕选择偏好
/// 支持按视频 VID 存储不同的字幕偏好
class SubtitlePreferenceService {
  /// SharedPreferences 键前缀
  static const String _keyPrefix = 'polyv_subtitle_';

  /// 保存用户字幕偏好
  ///
  /// 参数:
  /// - [vid] 视频 VID
  /// - [trackKey] 选中的字幕轨道键
  /// - [enabled] 字幕是否开启
  static Future<void> savePreference({
    required String vid,
    required String? trackKey,
    required bool enabled,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 保存字幕开启状态
      await prefs.setBool('$_keyPrefix${vid}_enabled', enabled);

      // 保存轨道键（仅在开启且有选择时）
      if (enabled && trackKey != null) {
        await prefs.setString('$_keyPrefix${vid}_trackKey', trackKey);
      } else {
        // 关闭字幕或未选择时，清除轨道键
        await prefs.remove('$_keyPrefix${vid}_trackKey');
      }

      // 保存最后更新时间
      await prefs.setInt(
        '$_keyPrefix${vid}_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // 静默失败，不影响播放
      // Error saving subtitle preference: $e
    }
  }

  /// 加载用户字幕偏好
  ///
  /// 参数:
  /// - [vid] 视频 VID
  ///
  /// 返回: 字幕偏好数据，如果不存在则返回 null
  static Future<SubtitlePreference?> loadPreference(String vid) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final enabled = prefs.getBool('$_keyPrefix${vid}_enabled');
      final trackKey = prefs.getString('$_keyPrefix${vid}_trackKey');
      final timestamp = prefs.getInt('$_keyPrefix${vid}_timestamp');

      if (enabled == null && trackKey == null) {
        return null;
      }

      return SubtitlePreference(
        vid: vid,
        enabled: enabled ?? false,
        trackKey: trackKey,
        timestamp: timestamp,
      );
    } catch (e) {
      // 静默失败，返回 null
      return null;
    }
  }

  /// 清除指定视频的字幕偏好
  static Future<void> clearPreference(String vid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keyPrefix${vid}_enabled');
      await prefs.remove('$_keyPrefix${vid}_trackKey');
      await prefs.remove('$_keyPrefix${vid}_timestamp');
    } catch (e) {
      // 静默失败
    }
  }

  /// 清除所有字幕偏好
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_keyPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // 静默失败
    }
  }

  /// 获取全局默认字幕语言（跨视频）
  ///
  /// 当视频没有特定偏好时，可以使用全局偏好
  static Future<String?> getGlobalDefaultLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_keyPrefix-global_default_language');
    } catch (e) {
      return null;
    }
  }

  /// 设置全局默认字幕语言
  static Future<void> setGlobalDefaultLanguage(String? language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (language != null && language.isNotEmpty) {
        await prefs.setString('$_keyPrefix-global_default_language', language);
      } else {
        await prefs.remove('$_keyPrefix-global_default_language');
      }
    } catch (e) {
      // 静默失败
    }
  }
}

/// 字幕偏好数据
class SubtitlePreference {
  /// 视频 VID
  final String vid;

  /// 字幕是否开启
  final bool enabled;

  /// 选中的字幕轨道键
  final String? trackKey;

  /// 最后更新时间（毫秒时间戳）
  final int? timestamp;

  const SubtitlePreference({
    required this.vid,
    required this.enabled,
    this.trackKey,
    this.timestamp,
  });

  /// 从 SubtitleItem 创建偏好
  factory SubtitlePreference.fromItem({
    required String vid,
    required SubtitleItem? item,
    required bool enabled,
  }) {
    return SubtitlePreference(
      vid: vid,
      enabled: enabled && item != null,
      trackKey: item?.trackKey,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  String toString() =>
      'SubtitlePreference(vid: $vid, enabled: $enabled, trackKey: $trackKey)';
}
