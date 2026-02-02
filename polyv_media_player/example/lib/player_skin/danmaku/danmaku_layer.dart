import 'package:flutter/material.dart';
import 'package:polyv_media_player/infrastructure/danmaku/danmaku_model.dart';

/// 弹幕显示层 Widget
///
/// 精确 1:1 还原 Web 原型 DanmakuLayer.tsx 的 UI 结构和动画效果
/// 参考: /Users/nick/projects/polyv/ios/polyv-vod/src/components/player/DanmakuLayer.tsx
///
/// 核心特性：
/// - 从右向左滚动动画（8秒时长）
/// - 8 条固定轨道，间距 32px，顶部偏移 12px
/// - 根据播放时间驱动弹幕显示
/// - 支持透明度、字体大小调节
/// - 弹幕不拦截视频手势事件
class DanmakuLayer extends StatefulWidget {
  /// 是否启用弹幕
  final bool enabled;

  /// 弹幕透明度 (0.0 - 1.0)
  final double opacity;

  /// 字体大小
  final DanmakuFontSize fontSize;

  /// 当前播放时间（毫秒）
  final int currentTime;

  /// 所有弹幕数据列表
  final List<Danmaku> danmakus;

  /// 弹幕垂直覆盖比例（相对于视频区域高度）
  ///
  /// 默认值为 0.6，与 Web 原型保持一致，仅使用上部分区域显示弹幕，避免与底部控制条严重重叠。
  final double heightFactor;

  const DanmakuLayer({
    super.key,
    required this.enabled,
    required this.opacity,
    required this.fontSize,
    required this.currentTime,
    required this.danmakus,
    this.heightFactor = 0.6,
  });

  @override
  State<DanmakuLayer> createState() => _DanmakuLayerState();
}

class _DanmakuLayerState extends State<DanmakuLayer> {
  /// 活跃弹幕列表（正在屏幕上显示的弹幕）
  final List<ActiveDanmaku> _activeDanmakus = [];

  /// 轨道占用时间表（8条轨道）
  /// 存储每条轨道的占用截止时间戳
  final List<int> _trackEndTime = List.filled(8, 0);

  /// 上一次的播放时间（用于检测 seek 操作）
  int _lastCurrentTime = -1;

  /// 是否已经初始化（首次 build 时触发弹幕更新）
  bool _isInitialized = false;

  /// 弹幕时间窗口（毫秒）
  /// 当前时间前后 1 秒内的弹幕都会被显示（与 iOS 端保持一致）
  static const int _timeWindow = 1000;

  /// 弹幕动画时长（毫秒）
  static const int _animationDuration = 10000;

  /// 字体大小映射
  static const Map<DanmakuFontSize, double> _fontSizes = {
    DanmakuFontSize.small: 12.0,
    DanmakuFontSize.medium: 14.0,
    DanmakuFontSize.large: 16.0,
  };

  /// 字体高度映射（行高）
  static const Map<DanmakuFontSize, double> _lineHeights = {
    DanmakuFontSize.small: 16.0,
    DanmakuFontSize.medium: 20.0,
    DanmakuFontSize.large: 24.0,
  };

  @override
  void didUpdateWidget(DanmakuLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 当 currentTime 变化时，更新活跃弹幕列表
    if (oldWidget.currentTime != widget.currentTime ||
        oldWidget.enabled != widget.enabled ||
        oldWidget.danmakus != widget.danmakus) {
      _updateActiveDanmakus();
    }
  }

  /// 更新活跃弹幕列表
  ///
  /// 核心逻辑：
  /// 1. 检测 seek 操作，清空活跃弹幕
  /// 2. 找到应该触发的弹幕：time <= currentTime 且在时间窗口内
  /// 3. 防止重复：只添加不在活跃列表中的弹幕
  /// 4. 弹幕持续滚动直到动画完成（8秒）
  /// 5. 分配到最空闲的轨道
  void _updateActiveDanmakus() {
    if (!widget.enabled) {
      // 弹幕关闭时清空活跃弹幕
      if (_activeDanmakus.isNotEmpty) {
        setState(() {
          _activeDanmakus.clear();
          _lastCurrentTime = -1;
        });
      }
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final currentTime = widget.currentTime;

    // 检测 seek 操作：如果时间发生跳跃（向后或向前大跳跃），清空活跃弹幕
    final isSeekingBackwards =
        _lastCurrentTime >= 0 && currentTime < _lastCurrentTime;
    final isSeekingForwards =
        _lastCurrentTime >= 0 &&
        currentTime > _lastCurrentTime + 2000; // 超过 2 秒认为是 seek

    if (isSeekingBackwards || isSeekingForwards) {
      // Seek 操作：清空活跃弹幕和轨道状态
      setState(() {
        _activeDanmakus.clear();
        for (int i = 0; i < _trackEndTime.length; i++) {
          _trackEndTime[i] = 0;
        }
      });
    }
    // 记录是否为本次 DanmakuLayer 生命周期内的首次更新
    final bool isInitialUpdate = _lastCurrentTime < 0;
    _lastCurrentTime = currentTime;

    // 获取当前活跃弹幕的 ID 集合，用于防止重复
    final activeIds = _activeDanmakus.map((ad) => ad.id).toSet();

    // 1. 找到应该触发/显示的弹幕
    // 常规情况下：使用 _timeWindow 仅触发“刚到时间”的新弹幕
    // 首次更新（例如横竖屏切换导致 DanmakuLayer 重新创建时）：
    //   使用完整动画窗口 [time, time + _animationDuration] 重新构建当前仍在屏幕上的弹幕，
    //   确保正在滚动中的弹幕在横竖屏切换后继续从正确位置滚动。
    final shouldTriggerDanmakus = widget.danmakus.where((d) {
      if (isInitialUpdate) {
        final int start = d.time;
        final int end = d.time + _animationDuration;
        return currentTime >= start && currentTime <= end;
      } else {
        return d.time <= currentTime && d.time >= currentTime - _timeWindow;
      }
    }).toList();

    // 2. 找出需要添加的新弹幕（在窗口内但不在活跃列表中的）
    final toAdd = <ActiveDanmaku>[];

    for (final d in shouldTriggerDanmakus) {
      // 跳过已经在活跃列表中的弹幕
      if (activeIds.contains(d.id)) continue;

      int track;

      if (d.type == DanmakuType.scroll) {
        // 滚动弹幕：分配到最空闲的轨道
        final minEndTime = _trackEndTime.reduce((a, b) => a < b ? a : b);
        track = _trackEndTime.indexOf(minEndTime);
        _trackEndTime[track] = now + _animationDuration;
      } else if (d.type == DanmakuType.top) {
        // 顶部固定弹幕：使用轨道 0-3（上半部分）
        final topTracksEndTimes = _trackEndTime.sublist(0, 4);
        final minEndTime = topTracksEndTimes.reduce((a, b) => a < b ? a : b);
        track = _trackEndTime.indexOf(minEndTime);
        _trackEndTime[track] = now + _animationDuration;
      } else {
        // 底部固定弹幕：使用轨道 4-7（下半部分）
        final bottomTracksEndTimes = _trackEndTime.sublist(4, 8);
        final minEndTime = bottomTracksEndTimes.reduce((a, b) => a < b ? a : b);
        track = 4 + bottomTracksEndTimes.indexOf(minEndTime);
        _trackEndTime[track] = now + _animationDuration;
      }

      // 创建活跃弹幕
      int startTime;
      if (isInitialUpdate) {
        // 对于首次更新（如横竖屏切换），根据当前播放时间推导一个“虚拟开始时间”，
        // 使得动画已进行的时间约等于 currentTime - d.time，从而保证弹幕位置连续。
        final int elapsedSinceAppear = currentTime - d.time;
        startTime = now - elapsedSinceAppear;
      } else {
        // 常规情况下，从当前时间开始动画（保持原有行为）
        startTime = now;
      }

      toAdd.add(
        ActiveDanmaku.fromDanmaku(d, track: track, startTime: startTime),
      );
    }

    // 3. 找出需要移除的弹幕（只在动画完成时移除）
    final toRemove = <ActiveDanmaku>[];
    for (final ad in _activeDanmakus) {
      final animationExpired = (now - ad.startTime) >= _animationDuration;
      if (animationExpired) {
        toRemove.add(ad);
      }
    }

    // 4. 应用更新
    if (toAdd.isNotEmpty || toRemove.isNotEmpty) {
      setState(() {
        // 移除动画完成的弹幕
        for (final d in toRemove) {
          _activeDanmakus.remove(d);
        }
        // 添加新触发的弹幕
        _activeDanmakus.addAll(toAdd);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 首次 build 时初始化弹幕
    if (!_isInitialized) {
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateActiveDanmakus();
      });
    }

    // 弹幕关闭时不渲染
    if (!widget.enabled) {
      return const SizedBox.shrink();
    }

    // 计算字体大小和行高
    final fontSize = _fontSizes[widget.fontSize] ?? 14.0;
    final lineHeight = _lineHeights[widget.fontSize] ?? 20.0;

    return Opacity(
      opacity: widget.opacity.clamp(0.0, 1.0),
      child: IgnorePointer(
        // 弹幕不拦截手势事件，确保不遮挡视频主要内容
        child: Align(
          alignment: Alignment.topCenter,
          child: FractionallySizedBox(
            widthFactor: 1.0,
            // 仅使用视频区域的上部分显示弹幕，避免与底部进度条和控制条重叠
            heightFactor: widget.heightFactor,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 获取实际可用的弹幕区域高度
                final availableHeight = constraints.maxHeight;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 渲染所有活跃弹幕
                    for (final danmaku in _activeDanmakus)
                      _DanmakuItem(
                        key: ValueKey('${danmaku.id}_${danmaku.startTime}'),
                        danmaku: danmaku,
                        fontSize: fontSize,
                        lineHeight: lineHeight,
                        availableHeight: availableHeight,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _activeDanmakus.clear();
    super.dispose();
  }
}

/// 单个弹幕项 Widget
///
/// 使用 AnimatedBuilder 实现从右向左的滚动动画
class _DanmakuItem extends StatefulWidget {
  final ActiveDanmaku danmaku;
  final double fontSize;
  final double lineHeight;
  final double availableHeight;

  const _DanmakuItem({
    super.key,
    required this.danmaku,
    required this.fontSize,
    required this.lineHeight,
    required this.availableHeight,
  });

  @override
  State<_DanmakuItem> createState() => _DanmakuItemState();
}

class _DanmakuItemState extends State<_DanmakuItem>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;
  double? _textWidth;
  bool _isFirstFrame = true;
  double? _initialTop;

  @override
  void initState() {
    super.initState();

    final trackHeight = widget.availableHeight / 8;
    _initialTop = widget.danmaku.track * trackHeight;

    // 只有滚动弹幕才需要动画控制器
    if (widget.danmaku.type == DanmakuType.scroll) {
      // 动画总时长
      const totalDuration = Duration(milliseconds: 10000);

      // 创建动画控制器
      _controller = AnimationController(duration: totalDuration, vsync: this);

      // 创建从 1.0 到 0.0 的动画（1.0 = 右侧，0.0 = 左侧）
      _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller!);
    }
  }

  /// 启动动画
  void _startAnimation() {
    if (_controller == null || _controller!.isAnimating) return;

    // 计算动画已进行的时间
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - widget.danmaku.startTime;

    // 如果动画已进行超过 100ms，跳过已过去的时间
    if (elapsed > 100 && elapsed < 10000) {
      final progress = elapsed / 10000;
      _controller!.value = 1.0 - progress;
      _controller!.forward();
    } else {
      // 从头开始，弹幕从屏幕右侧完全滑入
      _controller!.forward(from: 0.0);
    }
  }

  /// 获取弹幕文本宽度
  double _getTextWidth(BuildContext context) {
    if (_textWidth != null) return _textWidth!;

    // 使用 TextPainter 计算宽度
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.danmaku.text,
        style: TextStyle(
          color: widget.danmaku.color ?? Colors.white,
          fontSize: widget.fontSize,
          height: widget.lineHeight / widget.fontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    _textWidth = textPainter.width;
    return _textWidth!;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxTop = (widget.availableHeight - widget.lineHeight).clamp(
      0.0,
      double.infinity,
    );
    final top = (_initialTop ?? 0.0).clamp(0.0, maxTop);

    // 滚动弹幕：使用动画
    if (widget.danmaku.type == DanmakuType.scroll && _animation != null) {
      // 首次 build 时启动动画
      if (_isFirstFrame) {
        _isFirstFrame = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startAnimation();
        });
      }

      final screenWidth = MediaQuery.of(context).size.width;
      final textWidth = _getTextWidth(context);

      return AnimatedBuilder(
        animation: _animation!,
        builder: (context, child) {
          // animation value 从 1.0 到 0.0
          // 1.0 时：弹幕整体位于屏幕右侧完全不可见区域 (left = screenWidth)
          // 0.0 时：弹幕整体位于屏幕左侧完全不可见区域 (left = -textWidth)
          // 这样弹幕会从屏幕外右侧滑入，再从屏幕外左侧滑出
          final left =
              -textWidth + (screenWidth + textWidth) * _animation!.value;
          return Positioned(top: top, left: left, child: child!);
        },
        child: _DanmakuText(
          danmaku: widget.danmaku,
          fontSize: widget.fontSize,
          lineHeight: widget.lineHeight,
        ),
      );
    }

    // 顶部/底部固定弹幕：居中显示，不滚动
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Center(
        child: _DanmakuText(
          danmaku: widget.danmaku,
          fontSize: widget.fontSize,
          lineHeight: widget.lineHeight,
        ),
      ),
    );
  }
}

/// 弹幕文本 Widget
///
/// 负责渲染弹幕文本，应用颜色和字体样式
class _DanmakuText extends StatelessWidget {
  final ActiveDanmaku danmaku;
  final double fontSize;
  final double lineHeight;

  const _DanmakuText({
    required this.danmaku,
    required this.fontSize,
    required this.lineHeight,
  });

  @override
  Widget build(BuildContext context) {
    // 获取弹幕颜色，默认白色
    final color = danmaku.color ?? Colors.white;

    return Text(
      danmaku.text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        height: lineHeight / fontSize,
        shadows: const [
          // 添加文字阴影，确保在不同背景色上都能看清
          Shadow(offset: Offset(1, 1), blurRadius: 2, color: Color(0x80000000)),
        ],
      ),
      // 不限制宽度，让文本自然展开
      overflow: TextOverflow.visible,
      softWrap: false,
    );
  }
}
