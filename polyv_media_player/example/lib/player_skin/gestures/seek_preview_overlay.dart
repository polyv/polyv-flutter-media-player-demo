import 'package:flutter/material.dart';
import '../player_colors.dart';

/// 进度预览覆盖层
///
/// 在用户左右滑动 seek 时显示，展示当前时间预览和进度条
class SeekPreviewOverlay extends StatelessWidget {
  /// seek 进度 (0-1)
  final double progress;

  /// 当前预览位置（毫秒）
  final int currentPosition;

  /// 视频总时长（毫秒）
  final int duration;

  const SeekPreviewOverlay({
    super.key,
    required this.progress,
    required this.currentPosition,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 时间显示
              Text(
                '${_formatTime(currentPosition)} / ${_formatTime(duration)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              // 进度条
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    PlayerColors.progress,
                  ),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
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
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}
