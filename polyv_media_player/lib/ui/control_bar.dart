import 'package:flutter/material.dart';
import 'package:polyv_media_player/polyv_media_player.dart';

/// ControlBar - 播放器控制栏组件
///
/// 包含播放/暂停按钮、进度条、清晰度选择器和倍速选择器
class ControlBar extends StatelessWidget {
  final PlayerController controller;

  const ControlBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: PlayerColors.surface),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 进度条
          ProgressSlider(
            value: controller.state.progress,
            bufferValue: controller.state.bufferProgress,
            duration: controller.state.duration,
            position: controller.state.position,
            onSeek: (value) {
              final position = (value * controller.state.duration).toInt();
              controller.seekTo(position);
            },
          ),

          const SizedBox(height: 12),

          // 播放控制按钮行
          Row(
            children: [
              // 播放/暂停按钮
              _buildPlayPauseButton(),

              const Spacer(),

              // 倍速选择器
              SpeedSelector(controller: controller),

              const SizedBox(width: 8),

              // 字幕开关
              SubtitleToggle(controller: controller),

              const SizedBox(width: 8),

              // 清晰度选择器
              QualitySelector(controller: controller),

              const SizedBox(width: 8),

              // 停止按钮
              _buildStopButton(),
            ],
          ),
        ],
      ),
    );
  }

  /// 播放/暂停按钮
  Widget _buildPlayPauseButton() {
    final isPlaying = controller.effectiveIsPlaying;
    final isPrepared = controller.state.isPrepared;

    return IconButton(
      iconSize: 40,
      color: Colors.white,
      onPressed: isPrepared
          ? () {
              if (isPlaying) {
                controller.pause();
              } else {
                controller.play();
              }
            }
          : null,
      icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
    );
  }

  /// 停止按钮
  Widget _buildStopButton() {
    final isPrepared = controller.state.isPrepared;

    return IconButton(
      iconSize: 32,
      color: Colors.white54,
      onPressed: isPrepared ? () => controller.stop() : null,
      icon: const Icon(Icons.stop_rounded),
    );
  }
}
