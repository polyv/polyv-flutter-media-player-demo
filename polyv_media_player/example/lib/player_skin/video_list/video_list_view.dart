import 'package:flutter/material.dart';
import 'package:polyv_media_player/infrastructure/video_list/video_list_models.dart';
import 'video_list_item.dart';
import 'video_list_header.dart';
import 'video_list_style.dart';

/// 视频列表容器组件
///
/// 精确还原原型设计：/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/LongVideoPage.tsx
///
/// 功能：
/// - 显示视频列表标题（全部视频 · {count}）
/// - ListView.builder 渲染视频项
/// - 支持当前播放高亮
/// - 支持点击切换视频
/// - 支持滚动加载更多
/// - 支持空状态和错误状态
/// - 支持滚动到指定索引
/// - 支持切换状态显示
class VideoListView extends StatefulWidget {
  /// 视频列表
  final List<VideoItem> videos;

  /// 当前播放的视频 ID
  final String? currentVid;

  /// 视频项点击回调
  final ValueChanged<VideoItem> onVideoTap;

  /// 是否正在加载
  final bool isLoading;

  /// 是否正在加载更多
  final bool isLoadingMore;

  /// 是否有更多数据
  final bool hasMore;

  /// 加载更多回调
  final VoidCallback? onLoadMore;

  /// 错误信息
  final String? error;

  /// 空状态提示
  final String? emptyMessage;

  /// 是否正在切换视频（用于禁用点击和显示半透明状态）
  final bool isSwitching;

  const VideoListView({
    super.key,
    required this.videos,
    this.currentVid,
    required this.onVideoTap,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.onLoadMore,
    this.error,
    this.emptyMessage,
    this.isSwitching = false,
  });

  @override
  State<VideoListView> createState() => VideoListViewState();
}

/// VideoListView 的 State 类
///
/// 提供公共方法供外部调用，如 scrollToIndex
class VideoListViewState extends State<VideoListView> {
  /// 滚动控制器
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听，触发加载更多
  void _onScroll() {
    if (widget.onLoadMore == null ||
        widget.isLoadingMore ||
        !widget.hasMore ||
        !mounted) {
      return;
    }

    // 滚动到底部时加载更多
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.onLoadMore!();
    }
  }

  /// 滚动到指定索引的视频项
  ///
  /// [index] 视频在列表中的索引
  /// [alignment] 滚动后该位置在视口中的位置，0.0 表示在顶部，1.0 表示在底部
  void scrollToIndex(int index, {double alignment = 0.0}) {
    if (!mounted || index < 0 || index >= widget.videos.length) {
      return;
    }

    // 使用统一样式常量计算目标位置
    final targetPosition =
        VideoListDimensions.estimatedHeaderHeight +
        (index * VideoListDimensions.estimatedItemHeight);

    // 滚动到目标位置
    _scrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 加载中状态
    if (widget.isLoading && widget.videos.isEmpty) {
      return const _LoadingView();
    }

    // 错误状态
    if (widget.error != null && widget.videos.isEmpty) {
      return _ErrorView(message: widget.error!, onRetry: widget.onLoadMore);
    }

    // 空状态
    if (widget.videos.isEmpty) {
      return _EmptyView(message: widget.emptyMessage ?? '暂无视频');
    }

    // 正常列表
    return Column(
      children: [
        // 列表标题
        VideoListHeader(videoCount: widget.videos.length),

        // 列表内容
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            itemCount:
                widget.videos.length +
                (widget.hasMore
                    ? 1
                    : (widget.videos.isNotEmpty ? 1 : 0)), // 有数据但无更多时显示底部提示
            separatorBuilder: (context, index) => const _ListDivider(),
            itemBuilder: (context, index) {
              // 加载更多指示器或"已加载全部"提示
              if (index >= widget.videos.length) {
                if (widget.isLoadingMore) {
                  return const _LoadingMoreIndicator();
                }
                // 无更多数据时显示提示
                if (!widget.hasMore && widget.videos.isNotEmpty) {
                  return const _NoMoreDataIndicator();
                }
                return const SizedBox.shrink();
              }

              final video = widget.videos[index];
              final isActive = video.vid == widget.currentVid;

              return VideoListItem(
                key: ValueKey(video.vid), // 使用 vid 作为 key，防止重建时滚动
                video: video,
                isActive: isActive,
                onTap: widget.isSwitching
                    ? null // 切换中禁用点击
                    : () => widget.onVideoTap(video),
                isSwitching: widget.isSwitching,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 列表分隔线
///
/// 样式：divide-y divide-slate-800/30
class _ListDivider extends StatelessWidget {
  const _ListDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: VideoListDimensions.dividerHeight,
      color: VideoListColors.dividerColor,
    );
  }
}

/// 加载视图
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(VideoListColors.primary),
      ),
    );
  }
}

/// 错误视图
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorView({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: VideoListColors.slate500,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(message, style: VideoListTextStyles.message),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry!,
              style: ElevatedButton.styleFrom(
                backgroundColor: VideoListColors.primary,
                foregroundColor: VideoListColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('重试'),
            ),
          ],
        ],
      ),
    );
  }
}

/// 空状态视图
class _EmptyView extends StatelessWidget {
  final String message;

  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.video_library_outlined,
            color: VideoListColors.slate500,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(message, style: VideoListTextStyles.message),
        ],
      ),
    );
  }
}

/// 加载更多指示器
class _LoadingMoreIndicator extends StatelessWidget {
  const _LoadingMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(VideoListColors.primary),
        ),
      ),
    );
  }
}

/// 无更多数据指示器
class _NoMoreDataIndicator extends StatelessWidget {
  const _NoMoreDataIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Text(
        VideoListTextStyles.noMoreDataText,
        style: VideoListTextStyles.noMoreData,
      ),
    );
  }
}
