import 'package:flutter/material.dart';
import 'package:polyv_media_player/polyv_media_player.dart';
import '../player_colors.dart';

/// 清晰度选择器组件
///
/// 显示当前清晰度按钮，点击显示下拉菜单切换清晰度
class QualitySelector extends StatefulWidget {
  /// 播放器控制器
  final PlayerController controller;

  const QualitySelector({super.key, required this.controller});

  @override
  State<QualitySelector> createState() => _QualitySelectorState();
}

class _QualitySelectorState extends State<QualitySelector> {
  /// 下拉菜单是否打开
  bool _isOpen = false;

  /// 获取清晰度标签
  String _getQualityLabel(QualityItem quality) {
    const labels = {
      '4k': '4K 超清',
      '1080p': '1080P 高清',
      '720p': '720P 标清',
      '480p': '480P 流畅',
      '360p': '360P 极速',
      'auto': '自动',
    };
    return labels[quality.value] ?? quality.description;
  }

  /// 获取按钮显示文本
  String _getButtonLabel(QualityItem? currentQuality) {
    if (currentQuality == null || currentQuality.value == 'auto') {
      return ''; // 显示图标
    }
    // 取 value 的大写形式，如 "1080p" -> "1080P"
    return currentQuality.value.toUpperCase();
  }

  /// 构建触发按钮
  Widget _buildButton(
    QualityItem? currentQuality,
    List<QualityItem> qualities,
  ) {
    final isEnabled = qualities.isNotEmpty;
    final label = _getButtonLabel(currentQuality);

    return GestureDetector(
      onTap: isEnabled ? () => setState(() => _isOpen = !_isOpen) : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isEnabled ? Colors.transparent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: label.isEmpty
                ? const Icon(Icons.tune, size: 18, color: PlayerColors.text)
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: PlayerColors.text,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
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
  Widget _buildDropdown(
    List<QualityItem> qualities,
    QualityItem? currentQuality,
  ) {
    return Positioned(
      bottom: 48, // 按钮上方
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(minWidth: 120),
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
                  '画质选择',
                  style: TextStyle(fontSize: 11, color: PlayerColors.textMuted),
                ),
              ),

              const SizedBox(height: 4),

              // 清晰度列表
              ...qualities.map((quality) {
                final isActive = quality.value == currentQuality?.value;
                return _buildQualityItem(quality, isActive);
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建清晰度选项
  Widget _buildQualityItem(QualityItem quality, bool isActive) {
    return InkWell(
      onTap: () {
        // 找到索引并切换
        final index = widget.controller.indexOfQuality(quality);
        if (index >= 0) {
          widget.controller.setQuality(index);
          setState(() => _isOpen = false);
        }
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
              _getQualityLabel(quality),
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
        final qualities = widget.controller.qualities;
        final currentQuality = widget.controller.currentQuality;

        return SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 触发按钮
              _buildButton(currentQuality, qualities),

              // 遮罩层
              if (_isOpen) _buildOverlay(),

              // 下拉菜单
              if (_isOpen && qualities.isNotEmpty)
                _buildDropdown(qualities, currentQuality),
            ],
          ),
        );
      },
    );
  }
}
