import 'package:flutter/material.dart';
import 'danmaku_settings.dart';

/// 弹幕开关组件
///
/// 简化版本，只包含弹幕开关按钮
/// 参考: /Users/nick/projects/polyv/ios/polyv-vod/src/components/player/DanmakuToggle.tsx
///
/// 核心特性：
/// - 弹幕开关按钮（带图标状态切换）
class DanmakuToggle extends StatefulWidget {
  /// 弹幕设置状态
  final DanmakuSettings settings;

  const DanmakuToggle({super.key, required this.settings});

  @override
  State<DanmakuToggle> createState() => _DanmakuToggleState();
}

class _DanmakuToggleState extends State<DanmakuToggle> {
  @override
  Widget build(BuildContext context) {
    return _PlayerControlButton(
      icon: Icon(
        widget.settings.enabled
            ? Icons.chat_bubble
            : Icons.chat_bubble_outline_rounded,
        size: 18,
      ),
      tooltip: widget.settings.enabled ? '关闭弹幕' : '开启弹幕',
      onPressed: () {
        setState(() {
          widget.settings.toggle();
        });
      },
      size: _ButtonSize.md,
      active: widget.settings.enabled,
    );
  }
}

/// 播放器控制按钮基类
///
/// 对应原型 PlayerControlButton.tsx
class _PlayerControlButton extends StatefulWidget {
  final Widget icon;
  final String? tooltip;
  final VoidCallback onPressed;
  final _ButtonSize size;
  final bool active;

  const _PlayerControlButton({
    required this.icon,
    this.tooltip,
    required this.onPressed,
    this.size = _ButtonSize.md,
    this.active = false,
  });

  @override
  State<_PlayerControlButton> createState() => _PlayerControlButtonState();
}

class _PlayerControlButtonState extends State<_PlayerControlButton> {
  @override
  Widget build(BuildContext context) {
    final sizeClass = widget.size;
    final primaryColor = const Color(0xFFE8704D);

    return Tooltip(
      message: widget.tooltip ?? '',
      preferBelow: false,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: sizeClass.width,
          height: sizeClass.height,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: widget.active
                ? IconTheme(
                    data: IconThemeData(color: primaryColor),
                    child: widget.icon,
                  )
                : IconTheme(
                    data: const IconThemeData(color: Color(0xFFF5F5F5)),
                    child: widget.icon,
                  ),
          ),
        ),
      ),
    );
  }
}

/// 按钮尺寸枚举
enum _ButtonSize {
  md(40, 40); // w-10 h-10

  final double width;
  final double height;

  const _ButtonSize(this.width, this.height);
}
