import 'package:flutter/material.dart';
import 'video_list_style.dart';

/// 视频列表标题组件
///
/// 精确还原原型设计：/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/LongVideoPage.tsx
///
/// 样式关键点：
/// - padding: px-4 py-3
/// - 文字：text-sm font-medium text-slate-400
/// - 格式："全部视频 · {count}"
class VideoListHeader extends StatelessWidget {
  /// 视频总数
  final int videoCount;

  const VideoListHeader({super.key, required this.videoCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VideoListDimensions.headerPaddingHorizontal,
        vertical: VideoListDimensions.headerPaddingVertical,
      ),
      child: Text(
        '${VideoListTextStyles.headerPrefix}$videoCount',
        style: VideoListTextStyles.header,
      ),
    );
  }
}
