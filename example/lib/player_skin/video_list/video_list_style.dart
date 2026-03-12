import 'package:flutter/material.dart';

/// 视频列表组件的统一样式常量
///
/// 参考原型设计：
/// - /Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/VideoListItem.tsx
/// - /Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/LongVideoPage.tsx
class VideoListColors {
  // 私有构造函数，防止实例化
  VideoListColors._();

  /// 主色调 - 珊瑚橙 (primary)
  static const Color primary = Color(0xFFE8704D);

  /// 主色调/10 (primary/10)
  static Color get primaryContainer => primary.withValues(alpha: 0.1);

  /// 主色调/90 (primary/90) - 用于播放指示器背景
  static Color get primaryContainer90 => Color.fromARGB(230, 232, 112, 77);

  /// Slate-500 (次要文字颜色)
  static const Color slate500 = Color(0xFF64748B);

  /// Slate-400 (次要文字颜色，用于标题等)
  static const Color slate400 = Color(0xFF94A3B8);

  /// Slate-800 (深色背景)
  static const Color slate800 = Color(0xFF1E293B);

  /// Slate-800/30 (分隔线，30% 透明度)
  static const Color dividerColor = Color(0x4D2D3548);

  /// 黑色/80 (时长徽章背景，80% 不透明度)
  static const Color badgeBackground = Color(0xCC000000);

  /// 黑色/40 (播放指示器遮罩，40% 不透明度)
  static const Color overlayBackground = Color(0x66000000);

  /// 白色
  static const Color white = Colors.white;
}

/// 视频列表组件的尺寸常量
class VideoListDimensions {
  // 私有构造函数，防止实例化
  VideoListDimensions._();

  /// 缩略图宽度 (w-28 = 112px, 基于 4倍基准)
  static const double thumbnailWidth = 112.0;

  /// 缩略图高度 (h-16 = 64px, 基于 4倍基准)
  static const double thumbnailHeight = 64.0;

  /// 缩略图圆角 (rounded-lg = 8px)
  static const double thumbnailRadius = 8.0;

  /// 时长徽章圆角 (rounded = 4px)
  static const double badgeRadius = 4.0;

  /// 播放指示器圆圈大小 (w-8 h-8 = 32px)
  static const double playingIndicatorSize = 32.0;

  /// 播放图标大小 (w-4 h-4 = 16px)
  static const double playIconSize = 16.0;

  /// 容器内边距 (p-4 = 16px)
  static const double containerPadding = 16.0;

  /// 左侧边框宽度 (border-l-2)
  static const double activeBorderWidth = 2.0;

  /// 项之间的间距 (gap-3 = 12px)
  static const double itemGap = 12.0;

  /// 分隔线高度 (1px)
  static const double dividerHeight = 1.0;

  /// 列表标题内边距 (px-4 = 16px 水平, py-3 = 12px 垂直)
  static const double headerPaddingHorizontal = 16.0;
  static const double headerPaddingVertical = 12.0;

  /// 列表项高度估算（用于滚动计算）
  /// = containerPadding * 2 + thumbnailHeight = 32 + 64 = 96 (顶部 16 + 缩略图 64 + 底部 16)
  /// 但实际布局中使用 vertical padding 16，总高度约 96px
  static const double estimatedItemHeight = 96.0;

  /// 列表标题高度估算
  static const double estimatedHeaderHeight = 48.0;
}

/// 视频列表组件的文字样式常量
class VideoListTextStyles {
  // 私有构造函数，防止实例化
  VideoListTextStyles._();

  /// 标题文字样式 (text-sm font-medium)
  static const TextStyle title = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  /// 播放次数文字样式 (text-xs text-slate-500)
  static const TextStyle views = TextStyle(
    fontSize: 12,
    color: VideoListColors.slate500,
    height: 1.2,
  );

  /// 列表标题文字样式 (text-sm font-medium text-slate-400)
  static const TextStyle header = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: VideoListColors.slate400,
    height: 1.3,
  );

  /// 时长徽章文字样式 (text-[10px] text-white font-medium)
  static const TextStyle duration = TextStyle(
    fontSize: 10,
    color: VideoListColors.white,
    fontWeight: FontWeight.w500,
    height: 1.0,
  );

  /// 空状态/错误提示文字样式
  static const TextStyle message = TextStyle(
    fontSize: 14,
    color: VideoListColors.slate400,
  );

  /// "已加载全部"文字样式
  static const TextStyle noMoreData = TextStyle(
    fontSize: 12,
    color: VideoListColors.slate500,
  );

  /// 播放次数前缀文字
  static const String viewsSuffix = '次播放';

  /// 列表标题前缀文字
  static const String headerPrefix = '全部视频 · ';

  /// "已加载全部"文字
  static const String noMoreDataText = '已加载全部';

  /// "暂无视频"文字
  static const String emptyDataText = '暂无视频';

  /// "重试"按钮文字
  static const String retryButtonText = '重试';
}
