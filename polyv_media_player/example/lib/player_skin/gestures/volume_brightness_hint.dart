import 'package:flutter/material.dart';
import '../player_colors.dart';
import 'player_gesture_controller.dart';

/// 音量/亮度提示组件
///
/// 在用户上下滑动调节音量或亮度时显示，展示图标和进度条
class VolumeBrightnessHint extends StatelessWidget {
  /// 手势类型（亮度或音量）
  final GestureType type;

  /// 当前值 (0-1)
  final double value;

  const VolumeBrightnessHint({
    super.key,
    required this.type,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isBrightness = type == GestureType.brightnessAdjust;
    final icon = isBrightness
        ? Icons.brightness_6_rounded
        : Icons.volume_up_rounded;

    return Positioned.fill(
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 图标
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: 12),
              // 垂直进度条
              SizedBox(
                width: 4,
                height: 100,
                child: RotatedBox(
                  quarterTurns: isBrightness ? -1 : 0,
                  child: LinearProgressIndicator(
                    value: value.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      PlayerColors.progress,
                    ),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 百分比文字
              Text(
                '${(value.clamp(0.0, 1.0) * 100).toInt()}%',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
