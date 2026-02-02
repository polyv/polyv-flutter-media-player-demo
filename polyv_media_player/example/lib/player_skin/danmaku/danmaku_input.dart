import 'package:flutter/material.dart';
import '../player_colors.dart';

/// 弹幕输入组件
///
/// 参考 Web 原型: /Users/nick/projects/polyv/ios/polyv-vod/src/components/player/DanmakuInput.tsx
///
/// 功能：
/// - 弹幕文本输入
/// - 颜色选择
/// - 发送按钮（禁用/加载态）
/// - Emoji 按钮（占位，后续扩展）
class DanmakuInput extends StatefulWidget {
  /// 发送回调
  final Future<void> Function(String text, String color) onSend;

  /// 是否禁用（如未登录、播放器未就绪等）
  final bool disabled;

  /// 是否正在发送（加载态）
  final bool isLoading;

  /// 占位符文本
  final String placeholder;

  /// 最大文本长度
  final int maxLength;

  const DanmakuInput({
    super.key,
    required this.onSend,
    this.disabled = false,
    this.isLoading = false,
    this.placeholder = '发个弹幕吧...',
    this.maxLength = 100,
  });

  @override
  State<DanmakuInput> createState() => _DanmakuInputState();
}

class _DanmakuInputState extends State<DanmakuInput> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// 当前选中的颜色
  String _selectedColor = '#ffffff';

  /// 是否显示颜色选择面板
  bool _showColorPicker = false;

  /// 可选颜色列表（与 Web 原型一致）
  static const List<Color> _colors = [
    Color(0xFFFFFFFF), // 白色
    Color(0xFFFE0302), // 红色
    Color(0xFFFF7204), // 橙色
    Color(0xFFFFAA02), // 黄色
    Color(0xFFFFD302), // 金黄
    Color(0xFF00CD00), // 绿色
    Color(0xFF00A2FF), // 蓝色
    Color(0xFFCC0273), // 粉色
  ];

  /// 对应的十六进制颜色字符串
  static const List<String> _colorStrings = [
    '#ffffff',
    '#fe0302',
    '#ff7204',
    '#ffaa02',
    '#ffd302',
    '#00cd00',
    '#00a2ff',
    '#cc0273',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 获取当前颜色（作为 Color 对象）
  Color get _currentColor {
    final index = _colorStrings.indexOf(_selectedColor);
    if (index >= 0 && index < _colors.length) {
      return _colors[index];
    }
    return _colors[0];
  }

  /// 检查是否可以发送（文本非空且不在加载中）
  bool get _canSend =>
      _textController.text.trim().isNotEmpty &&
      !widget.disabled &&
      !widget.isLoading;

  /// 发送弹幕
  Future<void> _handleSend() async {
    if (!_canSend) return;

    final text = _textController.text.trim();
    final color = _selectedColor;

    try {
      await widget.onSend(text, color);

      // 发送成功后清空输入框
      if (mounted) {
        _textController.clear();
        _focusNode.unfocus();
      }
    } catch (e) {
      // 错误由调用方处理，这里不做额外处理
    }
  }

  /// 选择颜色
  void _selectColor(String colorString) {
    setState(() {
      _selectedColor = colorString;
      _showColorPicker = false;
    });
    // 选中颜色后重新聚焦输入框
    _focusNode.requestFocus();
  }

  /// 切换颜色选择器显示
  void _toggleColorPicker() {
    setState(() {
      _showColorPicker = !_showColorPicker;
    });
    if (_showColorPicker) {
      // 打开颜色选择器时失焦输入框
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: PlayerColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          // 颜色选择按钮
          _buildColorButton(),

          const SizedBox(width: 4),

          // Emoji 按钮（占位）
          _buildEmojiButton(),

          const SizedBox(width: 4),

          // 输入框
          Expanded(child: _buildInput()),

          const SizedBox(width: 4),

          // 发送按钮
          _buildSendButton(),
        ],
      ),
    );
  }

  /// 颜色选择按钮
  Widget _buildColorButton() {
    return GestureDetector(
      onTap: widget.disabled ? null : _toggleColorPicker,
      child: MouseRegion(
        cursor: widget.disabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Stack(
            children: [
              // 图标（调色板）
              Icon(
                Icons.palette_outlined,
                size: 14,
                color: widget.disabled ? PlayerColors.textMuted : _currentColor,
              ),
              // 颜色选择面板
              if (_showColorPicker) _buildColorPicker(),
            ],
          ),
        ),
      ),
    );
  }

  /// 颜色选择面板
  Widget _buildColorPicker() {
    return Stack(
      children: [
        // 背景遮罩（点击关闭）
        Positioned.fill(
          child: GestureDetector(
            onTap: () => setState(() => _showColorPicker = false),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        // 面板本身
        Positioned(
          bottom: 40,
          left: 0,
          child: GestureDetector(
            onTap: () {}, // 防止点击面板时关闭
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: PlayerColors.surface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_colors.length, (index) {
                  final color = _colors[index];
                  final colorStr = _colorStrings[index];
                  final isSelected = colorStr == _selectedColor;

                  return GestureDetector(
                    onTap: () => _selectColor(colorStr),
                    child: Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Emoji 按钮（占位，后续扩展）
  Widget _buildEmojiButton() {
    return GestureDetector(
      onTap: widget.disabled
          ? null
          : () {
              // TODO: 实现 Emoji 选择面板
            },
      child: MouseRegion(
        cursor: widget.disabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Icon(
            Icons.sentiment_satisfied_outlined,
            size: 14,
            color: widget.disabled ? PlayerColors.textMuted : PlayerColors.text,
          ),
        ),
      ),
    );
  }

  /// 输入框
  Widget _buildInput() {
    return TextField(
      controller: _textController,
      focusNode: _focusNode,
      enabled: !widget.disabled && !widget.isLoading,
      maxLength: widget.maxLength,
      decoration: InputDecoration(
        hintText: widget.placeholder,
        hintStyle: const TextStyle(color: PlayerColors.textMuted, fontSize: 14),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
        counterText: '', // 隐藏字符计数
      ),
      style: const TextStyle(color: PlayerColors.text, fontSize: 14),
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => _handleSend(),
    );
  }

  /// 发送按钮
  Widget _buildSendButton() {
    final canSend = _canSend;

    return GestureDetector(
      onTap: canSend ? _handleSend : null,
      child: MouseRegion(
        cursor: canSend
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      PlayerColors.progress,
                    ),
                  ),
                )
              : Icon(
                  Icons.send_outlined,
                  size: 14,
                  color: canSend
                      ? PlayerColors.progress
                      : PlayerColors.textMuted,
                ),
        ),
      ),
    );
  }
}

/// 简化版弹幕输入组件（仅显示输入框和发送按钮）
///
/// 适用于不需要颜色选择器的场景
class SimpleDanmakuInput extends StatefulWidget {
  final Future<void> Function(String text) onSend;
  final bool disabled;
  final bool isLoading;
  final String placeholder;
  final int maxLength;

  const SimpleDanmakuInput({
    super.key,
    required this.onSend,
    this.disabled = false,
    this.isLoading = false,
    this.placeholder = '发个弹幕吧...',
    this.maxLength = 100,
  });

  @override
  State<SimpleDanmakuInput> createState() => _SimpleDanmakuInputState();
}

class _SimpleDanmakuInputState extends State<SimpleDanmakuInput> {
  late final TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: PlayerColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              enabled: !widget.disabled && !widget.isLoading,
              maxLength: widget.maxLength,
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: const TextStyle(
                  color: PlayerColors.textMuted,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
                counterText: '',
              ),
              style: const TextStyle(color: PlayerColors.text, fontSize: 14),
              textInputAction: TextInputAction.send,
              onSubmitted: widget.disabled || widget.isLoading
                  ? null
                  : (text) async {
                      final trimmed = text.trim();
                      if (trimmed.isNotEmpty) {
                        await widget.onSend(trimmed);
                        _textController.clear();
                        _focusNode.unfocus();
                      }
                    },
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.disabled || widget.isLoading
                ? null
                : () async {
                    final text = _textController.text.trim();
                    if (text.isNotEmpty) {
                      await widget.onSend(text);
                      _textController.clear();
                      _focusNode.unfocus();
                    }
                  },
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              child: widget.isLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          PlayerColors.progress,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.send_outlined,
                      size: 14,
                      color:
                          _textController.text.trim().isNotEmpty &&
                              !widget.disabled
                          ? PlayerColors.progress
                          : PlayerColors.textMuted,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
