import 'dart:io';
import 'package:flutter/material.dart';
import 'package:polyv_media_player/polyv_media_player.dart';

/// 下载中任务卡片组件
///
/// 精确还原 HTML 原型设计：
/// - 缩略图区域：w-24 h-14 (96x56px)，带失败状态遮罩
/// - 内容区域：标题、进度条、状态信息
/// - 进度条：h-1.5 (6px)，支持不同状态样式和 300ms 动画过渡
/// - 操作按钮：暂停/继续、删除
///
/// 参考: /Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/DownloadCenterPage.tsx#L186-287
class DownloadingTaskItem extends StatelessWidget {
  // 缩略图尺寸 (对应 Tailwind w-24 h-14)
  static const double _thumbnailWidth = 96;
  static const double _thumbnailHeight = 56;

  // 缩略图圆角 (对应 Tailwind rounded-lg)
  static const double _thumbnailBorderRadius = 8;

  // 进度条高度 (对应 Tailwind h-1.5)
  static const double _progressBarHeight = 6;

  // 进度条圆角 (对应 Tailwind rounded-full)
  static const double _progressBarBorderRadius = 3;

  // 进度条动画时长 (对应 CSS transition-all duration-300)
  static const int _progressAnimationDurationMs = 300;

  // 默认图标尺寸
  static const double _defaultIconSize = 24;

  // 按钮最小尺寸
  static const double _buttonMinSize = 40;

  /// 下载任务数据
  final DownloadTask task;

  /// 暂停/继续回调（Story 9.3 实现）
  final VoidCallback? onPauseResume; // 可以是 async回调

  /// 删除回调（Story 9.5 实现）
  final VoidCallback? onDelete;

  /// 重试回调（失败状态时显示）
  final VoidCallback? onRetry;

  const DownloadingTaskItem({
    super.key,
    required this.task,
    this.onPauseResume,
    this.onDelete,
    this.onRetry,
  });

  Widget _thumbnailPlaceholder() {
    return const Icon(
      Icons.play_circle_outline,
      color: Color(0xFF475569), // slate-600
      size: _defaultIconSize,
    );
  }

  Widget _buildThumbnailImage() {
    final thumbnail = task.thumbnail;
    if (thumbnail == null || thumbnail.isEmpty) {
      return _thumbnailPlaceholder();
    }

    final uri = Uri.tryParse(thumbnail);
    final scheme = uri?.scheme;

    if (scheme == 'file') {
      return Image.file(
        File.fromUri(uri!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _thumbnailPlaceholder(),
      );
    }

    if (scheme == 'http' || scheme == 'https') {
      return Image.network(
        thumbnail,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _thumbnailPlaceholder(),
      );
    }

    if (thumbnail.startsWith('/')) {
      return Image.file(
        File(thumbnail),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _thumbnailPlaceholder(),
      );
    }

    return Image.network(
      thumbnail,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _thumbnailPlaceholder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isError = task.status == DownloadTaskStatus.error;
    final isPaused = task.status == DownloadTaskStatus.paused;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 缩略图
          _buildThumbnail(isError),

          const SizedBox(width: 12),

          // 内容区域
          Expanded(child: _buildContent(isError, isPaused)),

          const SizedBox(width: 8),

          // 操作按钮
          _buildActions(isError, isPaused),
        ],
      ),
    );
  }

  /// 缩略图
  ///
  /// - 尺寸: w-24 h-14 (96x56px)
  /// - 圆角: rounded-lg (8px)
  /// - 失败状态: 显示红色遮罩 + 错误图标
  Widget _buildThumbnail(bool isError) {
    return Container(
      width: _thumbnailWidth,
      height: _thumbnailHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // slate-800
        borderRadius: BorderRadius.circular(_thumbnailBorderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildThumbnailImage(),
          if (isError)
            Container(
              color: const Color(0x33EF4444), // red-500/20
              child: const Center(
                child: Icon(
                  Icons.error_outline,
                  color: Color(0xFFF87171), // red-400
                  size: _defaultIconSize,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 内容区域
  ///
  /// 包含：
  /// - 标题（最多2行，超出省略）
  /// - 进度条（带动画）
  /// - 状态信息（百分比/状态文本 · 文件大小 · 速度）
  Widget _buildContent(bool isError, bool isPaused) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Text(
          task.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 8),

        // 进度条 - 使用 AnimatedContainer 实现 300ms 动画
        _buildProgressBar(isError, isPaused),

        const SizedBox(height: 6),

        // 状态信息
        _buildStatusInfo(isError, isPaused),
      ],
    );
  }

  /// 进度条
  ///
  /// - 高度: h-1.5 (6px)
  /// - 背景: bg-slate-800
  /// - 圆角: rounded-full
  /// - 颜色:
  ///   - 下载中: bg-gradient-to-r from-primary to-primary/80
  ///   - 暂停: bg-slate-500
  ///   - 失败: bg-red-500
  /// - 动画: transition-all duration-300 (使用 AnimatedContainer)
  Widget _buildProgressBar(bool isError, bool isPaused) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: _progressBarHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B), // slate-800
            borderRadius: BorderRadius.circular(_progressBarBorderRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: Duration(milliseconds: _progressAnimationDurationMs),
              curve: Curves.easeOut,
              width: constraints.maxWidth * task.progress.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                gradient: isError
                    ? null
                    : isPaused
                    ? null
                    : const LinearGradient(
                        colors: [
                          Color(0xFFE8704D),
                          Color(0xFFC75E42),
                        ], // primary to primary/80
                      ),
                color: isError
                    ? const Color(0xFFEF4444) // red-500
                    : isPaused
                    ? const Color(0xFF64748B) // slate-500
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 状态信息
  ///
  /// 格式: [状态/百分比] · [文件大小] · [速度]
  /// - 下载中: "67% · 128MB · 2.3MB/s"
  /// - 暂停: "已暂停 · 128MB"
  /// - 失败: "下载失败 · 128MB"
  Widget _buildStatusInfo(bool isError, bool isPaused) {
    return Row(
      children: [
        // 状态文本或百分比
        Text(
          isError
              ? '下载失败'
              : isPaused
              ? '已暂停'
              : '${task.progressPercent}%',
          style: TextStyle(
            fontSize: 12,
            color: isError
                ? const Color(0xFFF87171) // red-400
                : const Color(0xFF94A3B8), // slate-400
          ),
        ),
        const Text(
          ' · ',
          style: TextStyle(fontSize: 12, color: Color(0xFF475569)), // slate-600
        ),
        // 文件大小
        Text(
          task.totalSizeFormatted,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B), // slate-500
          ),
        ),
        // 下载速度（仅在下载中且速度大于0时显示）
        if (task.status == DownloadTaskStatus.downloading &&
            task.bytesPerSecond > 0) ...[
          const Text(
            ' · ',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
            ), // slate-600
          ),
          Text(
            task.speedFormatted,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF34D399), // emerald-400
            ),
          ),
        ],
      ],
    );
  }

  /// 操作按钮
  ///
  /// - 错误状态: 显示重试按钮（播放图标）
  /// - 其他状态: 显示暂停/继续按钮
  /// - 所有状态: 显示删除按钮
  Widget _buildActions(bool isError, bool isPaused) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 错误状态显示重试按钮，否则显示暂停/继续按钮
        if (isError)
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded),
            color: const Color(0xFFE8704D), // primary
            onPressed: onRetry,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: _buttonMinSize,
              minHeight: _buttonMinSize,
            ),
          )
        else
          IconButton(
            icon: Icon(
              isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
            color: const Color(0xFF94A3B8), // slate-400
            onPressed: onPauseResume,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: _buttonMinSize,
              minHeight: _buttonMinSize,
            ),
          ),

        // 删除按钮
        IconButton(
          icon: const Icon(Icons.close_rounded),
          color: const Color(0xFF64748B), // slate-500
          onPressed: onDelete,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: _buttonMinSize,
            minHeight: _buttonMinSize,
          ),
        ),
      ],
    );
  }
}
