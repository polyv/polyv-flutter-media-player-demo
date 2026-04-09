import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/player_controller.dart';
import '../../core/player_events.dart';
import '../../platform_channel/method_channel_handler.dart';
import '../../platform_channel/player_api.dart';
import '../../infrastructure/download/download_task.dart';
import '../../infrastructure/download/download_task_status.dart';
import '../../infrastructure/download/download_state_manager.dart';
import '../../utils/plv_logger.dart';
import '../player_colors.dart';

/// 下载回调接口
///
/// 用于解耦 SettingsMenu 与具体的下载实现
/// Example 应用通过实现此接口提供下载功能
abstract class DownloadCallbacks {
  /// 获取指定 vid 的下载任务
  DownloadTask? getTaskByVid(String vid);

  /// 获取下载状态管理器
  DownloadStateManager get stateManager;

  /// 打开下载中心页面
  ///
  /// [initialTabIndex] 初始标签页索引 (0: 已下载, 1: 下载中)
  void openDownloadCenter(int initialTabIndex);
}

/// 设置菜单组件 - 底部弹出菜单
///
/// 精确参考原型 MobilePortraitMenu.tsx 设计
class SettingsMenu extends StatefulWidget {
  /// 播放器控制器
  final PlayerController controller;

  /// 关闭回调
  final VoidCallback onClose;

  /// 当前播放的视频标题（可选，用于下载功能）
  final String? videoTitle;

  /// 当前播放的视频缩略图（可选，用于下载功能）
  final String? videoThumbnail;

  /// 下载回调（可选，不传则隐藏下载按钮）
  final DownloadCallbacks? downloadCallbacks;

  const SettingsMenu({
    super.key,
    required this.controller,
    required this.onClose,
    this.videoTitle,
    this.videoThumbnail,
    this.downloadCallbacks,
  });

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();

  /// 显示设置菜单
  static Future<void> show({
    required BuildContext context,
    required PlayerController controller,
    String? videoTitle,
    String? videoThumbnail,
    DownloadCallbacks? downloadCallbacks,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SettingsMenu(
        controller: controller,
        onClose: () => Navigator.pop(context),
        videoTitle: videoTitle,
        videoThumbnail: videoThumbnail,
        downloadCallbacks: downloadCallbacks,
      ),
    );
  }
}

class _SettingsMenuState extends State<SettingsMenu> {
  /// BottomSheet 内部 Toast 提示
  String? _toastMessage;
  Timer? _toastTimer;

  @override
  void dispose() {
    _toastTimer?.cancel();
    super.dispose();
  }

  /// 显示内部 Toast 提示（在 BottomSheet 内部渲染，不受遮罩层影响）
  void _showToast(String message) {
    _toastTimer?.cancel();
    setState(() => _toastMessage = message);
    _toastTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toastMessage = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.transparent,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {}, // 阻止点击内容区域时关闭
          child: Container(
            decoration: const BoxDecoration(
              color: PlayerColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Close button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: widget.onClose,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 内部 Toast 提示
                if (_toastMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _toastMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: PlayerColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: ListenableBuilder(
                    listenable: widget.controller,
                    builder: (context, _) {
                      final qualities = widget.controller.qualities;
                      final currentQuality = widget.controller.currentQuality;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 功能按钮行 - 音频模式、下载
                          _buildFunctionButtons(),

                          const SizedBox(height: 16),

                          // Quality section - 使用原生端发送的清晰度数据
                          if (qualities.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text(
                                '清晰度: 加载中...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: PlayerColors.textMuted,
                                ),
                              ),
                            )
                          else
                            _buildQualitySection(qualities, currentQuality),

                          const SizedBox(height: 16),

                          // Speed section - 移动端倍速选择
                          _buildSpeedSection(),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDownloadCenter({required int initialTabIndex}) {
    widget.downloadCallbacks?.openDownloadCenter(initialTabIndex);
    widget.onClose();
  }

  /// 构建清晰度选择区域
  Widget _buildQualitySection(
    List<QualityItem> qualities,
    QualityItem? currentQuality,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标题
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            '清晰度',
            style: TextStyle(
              fontSize: 12,
              color: PlayerColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // 清晰度按钮列表 - 使用 Row 保持在一行
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: qualities.asMap().entries.map((entry) {
              final index = entry.key;
              final quality = entry.value;
              // 使用 description 对比当前清晰度，避免多个不同清晰度共享同一个 value 时同时高亮
              final isActive =
                  currentQuality != null &&
                  quality.description == currentQuality.description;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildQualityButton(
                  label: quality.description,
                  isActive: isActive,
                  onTap: () {
                    widget.controller.setQuality(index);
                    widget.onClose();
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  /// 构建清晰度按钮
  Widget _buildQualityButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? PlayerColors.progress
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? null
              : Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  /// 构建倍速选择区域
  Widget _buildSpeedSection() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final currentSpeed = widget.controller.state.playbackSpeed;
        // 移动端倍速列表（不包含 0.5x）
        const speeds = [0.75, 1.0, 1.25, 1.5, 2.0];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                '倍速',
                style: TextStyle(
                  fontSize: 12,
                  color: PlayerColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // 倍速按钮列表 - 使用 Row 保持在一行
            Row(
              children: speeds.map((speed) {
                final isActive = speed == currentSpeed;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        widget.controller.setPlaybackSpeed(speed);
                        // 与 Web 原型一致：点击倍速按钮不自动关闭菜单
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isActive
                              ? PlayerColors.progress
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${speed}x',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isActive
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  /// 构建功能按钮行 - 音频模式、下载
  /// 暂时隐藏字幕设置按钮
  Widget _buildFunctionButtons() {
    final downloadCallbacks = widget.downloadCallbacks;

    return Row(
      children: [
        Expanded(
          child: _FunctionButton(
            icon: Icons.headphones_outlined,
            label: '音频模式',
            onTap: _handleAudioMode,
          ),
        ),
        if (downloadCallbacks != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: ListenableBuilder(
              listenable: downloadCallbacks.stateManager,
              builder: (context, _) {
                final vid = widget.controller.state.vid;

                // 调试日志：显示当前 vid 和所有任务的 vid 列表
                PlvLogger.d('[SettingsMenu] DownloadButton: current vid=$vid');
                PlvLogger.d(
                  '[SettingsMenu] DownloadButton: total tasks=${downloadCallbacks.stateManager.totalCount}',
                );
                for (final task in downloadCallbacks.stateManager.tasks) {
                  PlvLogger.d(
                    '[SettingsMenu] DownloadButton: task vid=${task.vid}, id=${task.id}, status=${task.status.name}',
                  );
                }

                final existingTask = (vid == null || vid.isEmpty)
                    ? null
                    : downloadCallbacks.getTaskByVid(vid);

                PlvLogger.d(
                  '[SettingsMenu] DownloadButton: existingTask=$existingTask',
                );

                final String label;
                if (existingTask == null) {
                  label = '下载';
                } else if (existingTask.status == DownloadTaskStatus.completed) {
                  label = '已下载';
                } else if (existingTask.status == DownloadTaskStatus.paused) {
                  label = '已暂停';
                } else if (existingTask.status == DownloadTaskStatus.error) {
                  label = '下载失败';
                } else {
                  label = '下载中';
                }

                PlvLogger.d('[SettingsMenu] DownloadButton: label=$label');

                return _FunctionButton(
                  icon: Icons.download_rounded,
                  label: label,
                  onTap: () {
                    if (existingTask != null) {
                      final initialTabIndex =
                          existingTask.status == DownloadTaskStatus.completed
                          ? 0
                          : 1;
                      _openDownloadCenter(initialTabIndex: initialTabIndex);
                      return;
                    }
                    _handleDownload(downloadCallbacks);
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  /// 处理音频模式按钮点击
  void _handleAudioMode() {
    _showToast('音频模式功能暂未开放');
  }

  /// 处理下载按钮点击
  Future<void> _handleDownload(DownloadCallbacks downloadCallbacks) async {
    final vid = widget.controller.state.vid;
    if (vid == null || vid.isEmpty) {
      if (mounted) {
        _showToast('无法获取视频信息');
      }
      return;
    }

    final stateManager = downloadCallbacks.stateManager;

    // 检查是否已有下载任务
    final existingTask = stateManager.getTaskByVid(vid);
    if (existingTask != null) {
      final initialTabIndex =
          existingTask.status == DownloadTaskStatus.completed ? 0 : 1;
      _openDownloadCenter(initialTabIndex: initialTabIndex);
      return;
    }

    // 没有现有任务，创建新任务
    await _createNewDownloadTask(vid, stateManager);
  }

  /// 创建新的下载任务
  ///
  /// Story 9.9: 调用原生层创建下载任务，而不是只在本地创建内存对象。
  /// 原生 SDK 会将视频添加到下载队列并开始下载。
  /// 创建成功后，从原生层同步权威任务列表到本地状态。
  Future<void> _createNewDownloadTask(
    String vid,
    DownloadStateManager stateManager,
  ) async {
    if (mounted) {
      _showToast('正在创建下载任务...');
    }

    try {
      PlvLogger.d('[SettingsMenu] Calling startDownload with vid: $vid');
      PlvLogger.d(
        '[SettingsMenu] Controller state vid: ${widget.controller.state.vid}',
      );

      // 获取当前播放的清晰度
      final currentQuality = widget.controller.currentQuality;
      final qualityValue = currentQuality?.value; // "480p", "720p", "1080p"
      PlvLogger.d('[SettingsMenu] Current quality: $qualityValue');

      // 调用原生层创建下载任务，传递当前清晰度
      await MethodChannelHandler.startDownload(
        const MethodChannel(PlayerApi.methodChannelName),
        vid,
        title: widget.videoTitle,
        quality: qualityValue,
      );

      PlvLogger.d(
        '[SettingsMenu] startDownload succeeded, syncing from native...',
      );

      // 创建成功后，从原生层同步权威任务列表
      // 这样可以确保本地状态与原生 SDK 保持一致
      final error = await stateManager.syncFromNative();

      if (error != null && mounted) {
        PlvLogger.w('[SettingsMenu] Sync failed: $error');
        _showToast('下载创建成功，但同步失败: $error');
        return;
      }

      PlvLogger.d(
        '[SettingsMenu] Download task created and synced successfully',
      );

      // 验证任务是否被正确添加
      final task = stateManager.getTaskByVid(vid);
      PlvLogger.d(
        '[SettingsMenu] After sync, getTaskByVid($vid) returned: $task',
      );
      if (task != null) {
        PlvLogger.d('[SettingsMenu] Task status: ${task.status.name}');
      }

      // 显示成功提示
      if (mounted) {
        _showToast('已添加到下载队列');
      }

      // 关闭弹窗
      widget.onClose();
    } catch (e) {
      PlvLogger.w('[SettingsMenu] Create download task failed: $e');
      PlvLogger.w('[SettingsMenu] Error type: ${e.runtimeType}');

      // 提取错误消息
      String errorMessage = '创建下载任务失败';
      if (e is PlatformException) {
        errorMessage = e.message ?? errorMessage;
        PlvLogger.w(
          '[SettingsMenu] PlatformException code: ${e.code}, message: ${e.message}',
        );
      } else if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }

      if (mounted) {
        _showToast(errorMessage);
      }
    }
  }
}

/// 功能按钮组件
class _FunctionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FunctionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: PlayerColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
