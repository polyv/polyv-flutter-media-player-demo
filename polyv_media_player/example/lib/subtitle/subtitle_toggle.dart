import 'package:flutter/material.dart';
import 'package:polyv_media_player/polyv_media_player.dart';
import '../player_skin/player_colors.dart';

/// 字幕开关组件
///
/// 显示字幕图标按钮，点击显示下拉菜单切换字幕
/// 精确参考原型 SubtitleToggle.tsx 设计
class SubtitleToggle extends StatefulWidget {
  /// 播放器控制器
  final PlayerController controller;

  const SubtitleToggle({super.key, required this.controller});

  @override
  State<SubtitleToggle> createState() => _SubtitleToggleState();
}

class _SubtitleToggleState extends State<SubtitleToggle> {
  /// 获取按钮图标
  IconData _getButtonIcon() {
    // 使用 Icons.subtitles 作为字幕图标
    // 如果开启了字幕，图标保持一致（与原型一致）
    return Icons.subtitles;
  }

  /// 构建触发按钮
  Widget _buildButton(bool isEnabled, List<SubtitleItem> subtitles) {
    final hasSubtitles = subtitles.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: hasSubtitles
          ? () {
              debugPrint(
                '[SubtitleToggle] button tapped, will open subtitle sheet. isEnabled=$isEnabled, hasSubtitles=$hasSubtitles',
              );
              _openSubtitleSheet();
            }
          : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isEnabled ? PlayerColors.activeHighlight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Opacity(
          opacity: hasSubtitles ? 1.0 : 0.4,
          child: Icon(
            _getButtonIcon(),
            size: 18,
            color: isEnabled ? PlayerColors.progress : PlayerColors.text,
          ),
        ),
      ),
    );
  }

  Future<void> _openSubtitleSheet() async {
    final subtitles = widget.controller.subtitles;
    if (subtitles.isEmpty) {
      return;
    }

    final isEnabled = widget.controller.state.subtitleEnabled;
    final currentSubtitleId = widget.controller.state.currentSubtitleId;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (sheetContext) {
        return SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 200),
                  decoration: BoxDecoration(
                    color: PlayerColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PlayerColors.controls, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Text(
                          '字幕选择',
                          style: TextStyle(
                            fontSize: 12,
                            color: PlayerColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildSubtitleItem(
                        label: '关闭字幕',
                        isActive: !isEnabled,
                        onTap: () {
                          widget.controller.setSubtitleWithKey(
                            enabled: false,
                            trackKey: null,
                          );
                          Navigator.of(sheetContext).pop();
                        },
                      ),
                      const SizedBox(height: 2),
                      ..._sortedSubtitles(subtitles).map((subtitle) {
                        final isActive =
                            isEnabled && currentSubtitleId == subtitle.trackKey;
                        return _buildSubtitleItem(
                          label: subtitle.label,
                          isActive: isActive,
                          isBilingual: subtitle.isBilingual,
                          onTap: () {
                            widget.controller.setSubtitleWithKey(
                              enabled: true,
                              trackKey: subtitle.trackKey,
                            );
                            Navigator.of(sheetContext).pop();
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建字幕选项
  Widget _buildSubtitleItem({
    required String label,
    required bool isActive,
    bool isBilingual = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        debugPrint(
          '[SubtitleToggle] item tapped: label=$label, isActive=$isActive, isBilingual=$isBilingual',
        );
        onTap();
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
              label,
              style: TextStyle(
                fontSize: 14,
                color: isActive ? PlayerColors.progress : PlayerColors.text,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (isBilingual) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? PlayerColors.progress.withValues(alpha: 0.2)
                      : PlayerColors.textMuted.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  '双语',
                  style: TextStyle(
                    fontSize: 9,
                    color: isActive
                        ? PlayerColors.progress
                        : PlayerColors.textMuted,
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (isActive)
              const Icon(Icons.check, size: 16, color: PlayerColors.progress),
          ],
        ),
      ),
    );
  }

  /// 按默认算法排序字幕：双语 → 原生默认 → 其他
  List<SubtitleItem> _sortedSubtitles(List<SubtitleItem> subtitles) {
    final bilingual = subtitles.where((s) => s.isBilingual).toList();
    final defaults = subtitles
        .where((s) => s.isDefault && !s.isBilingual)
        .toList();
    final others = subtitles
        .where((s) => !s.isBilingual && !s.isDefault)
        .toList();

    return [...bilingual, ...defaults, ...others];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final subtitles = widget.controller.subtitles;
        final isEnabled = widget.controller.state.subtitleEnabled;

        return SizedBox(
          width: 40,
          height: 40,
          child: _buildButton(isEnabled, subtitles),
        );
      },
    );
  }
}
