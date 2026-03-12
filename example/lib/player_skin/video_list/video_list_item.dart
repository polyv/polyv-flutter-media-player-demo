import 'dart:io';
import 'package:flutter/material.dart';
import 'package:polyv_media_player/infrastructure/video_list/video_list_models.dart';
import 'video_list_style.dart';

/// 视频列表项组件
///
/// 精确还原原型设计：/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/VideoListItem.tsx
///
/// 样式关键点：
/// - 容器：flex gap-3 p-4, 左侧边框 2px
/// - 激活状态：bg-primary/10 + border-primary
/// - 非激活状态：hover:bg-slate-800/50 + border-transparent
/// - 缩略图：w-28 h-16 (28:16 = 7:4 比例)
/// - 时长徽章：右下角黑色半透明背景
/// - 播放指示器：激活时显示，居中圆形图标
/// - 切换状态：切换中禁用点击且半透明显示
class VideoListItem extends StatelessWidget {
  /// 视频数据
  final VideoItem video;

  /// 是否是当前播放的视频
  final bool isActive;

  /// 点击回调
  final VoidCallback? onTap;

  /// 是否正在切换视频（切换中时禁用点击且半透明显示）
  final bool isSwitching;

  const VideoListItem({
    super.key,
    required this.video,
    required this.isActive,
    required this.onTap,
    this.isSwitching = false,
  });

  @override
  Widget build(BuildContext context) {
    final transparent = Colors.transparent;

    return InkWell(
      onTap: isSwitching ? null : onTap, // 切换中禁用点击
      child: Opacity(
        // 切换中且非激活项时显示半透明
        opacity: isSwitching && !isActive ? 0.5 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            // 激活状态：bg-primary/10, 非激活：hover:bg-slate-800/50
            color: isActive ? VideoListColors.primaryContainer : transparent,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: VideoListDimensions.containerPadding,
            vertical: VideoListDimensions.containerPadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 缩略图容器
              _buildThumbnail(),

              const SizedBox(width: VideoListDimensions.itemGap),

              // 视频信息
              Expanded(child: _buildInfo()),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建缩略图
  Widget _buildThumbnail() {
    return SizedBox(
      width: VideoListDimensions.thumbnailWidth,
      height: VideoListDimensions.thumbnailHeight,
      child: Stack(
        children: [
          // 缩略图背景
          Container(
            decoration: BoxDecoration(
              color: VideoListColors.slate800,
              borderRadius: BorderRadius.circular(
                VideoListDimensions.thumbnailRadius,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildThumbnailImage(),
          ),

          // 时长徽章
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: VideoListColors.badgeBackground,
                borderRadius: BorderRadius.circular(
                  VideoListDimensions.badgeRadius,
                ),
              ),
              child: Text(
                video.durationFormatted,
                style: VideoListTextStyles.duration,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建缩略图图片
  Widget _buildThumbnailImage() {
    // 检查缩略图 URL 是否为空
    final thumbnailUrl = video.thumbnail.trim();
    if (thumbnailUrl.isEmpty) {
      // URL 为空时显示占位图
      return _buildPlaceholder();
    }

    // 解析 URL 以确定加载方式
    final uri = Uri.tryParse(thumbnailUrl);
    final scheme = uri?.scheme;

    // 本地文件 URL (file://)
    if (scheme == 'file') {
      return Image.file(
        File.fromUri(uri!),
        width: 112,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }

    // 绝对路径（以 / 开头）
    if (thumbnailUrl.startsWith('/')) {
      return Image.file(
        File(thumbnailUrl),
        width: 112,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }

    // 网络 URL (http:// 或 https://)
    return Image.network(
      thumbnailUrl,
      width: 112,
      height: 64,
      fit: BoxFit.cover,
      headers: const {'Accept': 'image/*'},
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder();
      },
      cacheWidth: 112,
      cacheHeight: 64,
    );
  }

  /// 构建占位图
  Widget _buildPlaceholder() {
    return SizedBox(
      width: 112,
      height: 64,
      child: Container(
        color: const Color(0xFF1E293B),
        child: const Icon(
          Icons.play_circle_outline,
          color: Color(0xFF475569),
          size: 32,
        ),
      ),
    );
  }

  /// 构建视频信息
  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 标题
        Text(
          video.title,
          style: VideoListTextStyles.title.copyWith(
            color: isActive ? VideoListColors.primary : VideoListColors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // 播放次数
        if (video.views != null)
          Text(
            '${video.views}${VideoListTextStyles.viewsSuffix}',
            style: VideoListTextStyles.views,
          ),
      ],
    );
  }
}
