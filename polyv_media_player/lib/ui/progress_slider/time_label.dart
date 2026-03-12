import 'package:flutter/material.dart';

/// TimeLabel - 时间显示组件
///
/// 用于显示视频播放时间（当前时间 / 总时长）
class TimeLabel extends StatelessWidget {
  /// 时间（毫秒）
  final int milliseconds;

  /// 是否显示为"未知"（用于时长未知时）
  final bool showUnknown;

  const TimeLabel({
    super.key,
    required this.milliseconds,
    this.showUnknown = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = showUnknown ? '--:--' : _formatTime(milliseconds);

    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFF8B919E), // PlayerColors.textMuted
        height: 1.3,
      ),
    );
  }

  /// 格式化时间：毫秒 → MM:SS 或 HH:MM:SS
  String _formatTime(int ms) {
    if (ms <= 0) return '00:00';

    final seconds = ms ~/ 1000;
    final mins = seconds ~/ 60;
    final secs = seconds % 60;

    if (mins >= 60) {
      final hours = mins ~/ 60;
      final remainingMins = mins % 60;
      return '$hours:${remainingMins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
