import 'package:shared_preferences/shared_preferences.dart';
import '../utils/plv_logger.dart';

/// 视频播放进度服务
///
/// 负责保存和加载每个视频的播放进度
/// 支持按视频 VID 存储不同的播放进度
class VideoProgressService {
  /// SharedPreferences 键前缀
  static const String _keyPrefix = 'polyv_video_progress_';

  /// 保存视频播放进度
  ///
  /// 参数:
  /// - [vid] 视频 VID
  /// - [position] 播放位置（毫秒）
  /// - [duration] 视频总时长（毫秒）
  static Future<void> saveProgress({
    required String vid,
    required int position,
    required int duration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _makeKey(vid);

      final data = _ProgressData(
        position: position,
        duration: duration,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await prefs.setString(key, data.toJson());
      PlvLogger.d('[VideoProgressService] Saved progress for $vid: ${position}ms');
    } catch (e) {
      PlvLogger.w('[VideoProgressService] Failed to save progress: $e');
    }
  }

  /// 加载视频播放进度
  ///
  /// 参数:
  /// - [vid] 视频 VID
  ///
  /// 返回: 播放进度数据（毫秒），如果不存在则返回 null
  static Future<int?> loadProgress(String vid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _makeKey(vid);
      final dataStr = prefs.getString(key);

      if (dataStr == null) {
        PlvLogger.d('[VideoProgressService] No saved progress for $vid');
        return null;
      }

      final data = _ProgressData.fromJson(dataStr);
      PlvLogger.d('[VideoProgressService] Loaded progress for $vid: ${data.position}ms');
      return data.position;
    } catch (e) {
      PlvLogger.w('[VideoProgressService] Failed to load progress: $e');
      return null;
    }
  }

  /// 清除指定视频的播放进度
  ///
  /// 用于重播时清除进度，从头开始播放
  static Future<void> clearProgress(String vid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _makeKey(vid);
      await prefs.remove(key);
      PlvLogger.d('[VideoProgressService] Cleared progress for $vid');
    } catch (e) {
      PlvLogger.w('[VideoProgressService] Failed to clear progress: $e');
    }
  }

  /// 生成 SharedPreferences 键
  static String _makeKey(String vid) => '$_keyPrefix$vid';
}

/// 播放进度数据
class _ProgressData {
  /// 播放位置（毫秒）
  final int position;

  /// 视频总时长（毫秒）
  final int duration;

  /// 保存时间戳
  final int timestamp;

  const _ProgressData({
    required this.position,
    required this.duration,
    required this.timestamp,
  });

  /// 转换为 JSON 字符串
  String toJson() {
    return '$position:$duration:$timestamp';
  }

  /// 从 JSON 字符串解析
  factory _ProgressData.fromJson(String json) {
    final parts = json.split(':');
    return _ProgressData(
      position: int.parse(parts[0]),
      duration: int.parse(parts[1]),
      timestamp: int.parse(parts[2]),
    );
  }
}
