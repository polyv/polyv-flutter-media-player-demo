import 'package:flutter/material.dart';
import 'package:polyv_media_player/polyv_media_player.dart';

/// 倍速选择器组件
///
/// 显示当前倍速按钮，点击显示下拉菜单切换倍速
/// 精确参考原型 SpeedSelector.tsx 设计
class SpeedSelector extends StatefulWidget {
  /// 播放器控制器
  final PlayerController controller;

  const SpeedSelector({super.key, required this.controller});

  @override
  State<SpeedSelector> createState() => _SpeedSelectorState();
}

class _SpeedSelectorState extends State<SpeedSelector> {
  /// 下拉菜单是否打开
  bool _isOpen = false;

  /// 可选倍速列表
  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  /// 获取按钮显示文本或图标
  Widget _getButtonContent(double currentSpeed) {
    if (currentSpeed == 1.0) {
      // 1.0x 时显示仪表盘图标
      return const Icon(Icons.speed, size: 18, color: PlayerColors.text);
    }
    // 其他倍速显示文本
    return Text(
      '${currentSpeed}x',
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: PlayerColors.text,
        letterSpacing: -0.3, // tabular-nums 效果
      ),
    );
  }

  /// 获取倍速显示文本
  String _getSpeedLabel(double speed) {
    if (speed == 1.0) return '正常';
    return '${speed}x';
  }

  /// 构建触发按钮
  Widget _buildButton(double currentSpeed) {
    final isActive = currentSpeed != 1.0;

    return GestureDetector(
      onTap: () => setState(() => _isOpen = !_isOpen),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? PlayerColors.activeHighlight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: _getButtonContent(currentSpeed)),
      ),
    );
  }

  /// 构建遮罩层
  Widget _buildOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _isOpen = false),
        behavior: HitTestBehavior.opaque,
        child: Container(color: Colors.transparent),
      ),
    );
  }

  /// 构建下拉菜单
  Widget _buildDropdown(double currentSpeed) {
    return Positioned(
      bottom: 48, // 按钮上方
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 140, // 固定宽度，确保 Row 中的 Spacer 能正常工作
          decoration: BoxDecoration(
            color: PlayerColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: PlayerColors.controls, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(
                  '播放速度',
                  style: TextStyle(fontSize: 11, color: PlayerColors.textMuted),
                ),
              ),

              const SizedBox(height: 4),

              // 倍速列表
              ..._speeds.map((speed) {
                final isActive = speed == currentSpeed;
                return _buildSpeedItem(speed, isActive);
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建倍速选项
  Widget _buildSpeedItem(double speed, bool isActive) {
    return InkWell(
      onTap: () {
        widget.controller.setPlaybackSpeed(speed);
        setState(() => _isOpen = false);
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? PlayerColors.activeHighlight : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Text(
              _getSpeedLabel(speed),
              style: TextStyle(
                fontSize: 14,
                color: isActive ? PlayerColors.progress : PlayerColors.text,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (isActive)
              const Icon(Icons.check, size: 16, color: PlayerColors.progress),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final currentSpeed = widget.controller.state.playbackSpeed;

        return SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 触发按钮
              _buildButton(currentSpeed),

              // 遮罩层
              if (_isOpen) _buildOverlay(),

              // 下拉菜单
              if (_isOpen) _buildDropdown(currentSpeed),
            ],
          ),
        );
      },
    );
  }
}
