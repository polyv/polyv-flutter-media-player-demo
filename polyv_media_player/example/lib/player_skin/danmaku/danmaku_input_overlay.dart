import 'dart:ui';
import 'package:flutter/material.dart';
import '../player_colors.dart';

/// 移动端弹幕输入全屏覆盖层
///
/// 参考 Web 原型: /Users/nick/projects/polyv/iOS/polyv-vod/src/components/mobile/MobileDanmakuInput.tsx
class DanmakuInputOverlay extends StatefulWidget {
  final Future<void> Function(String text, String color) onSend;
  final VoidCallback onClose;
  final bool isLoading;
  final String placeholder;
  final int maxLength;

  const DanmakuInputOverlay({
    super.key,
    required this.onSend,
    required this.onClose,
    this.isLoading = false,
    this.placeholder = '发送一条友好的弹幕...',
    this.maxLength = 100,
  });

  @override
  State<DanmakuInputOverlay> createState() => _DanmakuInputOverlayState();
}

class _DanmakuInputOverlayState extends State<DanmakuInputOverlay> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // 颜色相关
  String _selectedColor = '#ffffff';
  bool _showColorPicker = false;

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
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    // 自动聚焦
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
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

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isNotEmpty && !widget.isLoading) {
      await widget.onSend(text, _selectedColor);
      _textController.clear();
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // 允许键盘顶起底部内容
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // 点击空白关闭
            Positioned.fill(child: Container(color: Colors.transparent)),

            // 底部输入栏
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {}, // 拦截点击，防止关闭
                child: Container(
                  color: const Color(
                    0xFF18181B,
                  ).withValues(alpha: 0.95), // zinc-900/95
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_showColorPicker) _buildColorPicker(),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  // 设置/颜色按钮
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _showColorPicker = !_showColorPicker;
                                      });
                                    },
                                    icon: Icon(
                                      Icons
                                          .palette_outlined, // 使用调色板图标代替 Settings
                                      color: _showColorPicker
                                          ? PlayerColors.primary
                                          : Colors.white.withValues(alpha: 0.5),
                                      size: 24,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 40,
                                      minHeight: 40,
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // 输入框
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: TextField(
                                        controller: _textController,
                                        focusNode: _focusNode,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: widget.placeholder,
                                          hintStyle: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.4,
                                            ),
                                            fontSize: 14,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 10,
                                              ),
                                          isDense: true,
                                        ),
                                        textInputAction: TextInputAction.send,
                                        onSubmitted: (_) => _handleSend(),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // 发送按钮
                                  GestureDetector(
                                    onTap: _textController.text.trim().isEmpty
                                        ? null
                                        : _handleSend,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color:
                                            _textController.text
                                                .trim()
                                                .isNotEmpty
                                            ? PlayerColors.primary
                                            : Colors.white.withValues(
                                                alpha: 0.1,
                                              ),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: widget.isLoading
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                      Colors.white,
                                                    ),
                                              ),
                                            )
                                          : Icon(
                                              Icons.send_rounded,
                                              color:
                                                  _textController.text
                                                      .trim()
                                                      .isNotEmpty
                                                  ? Colors.white
                                                  : Colors.white.withValues(
                                                      alpha: 0.3,
                                                    ),
                                              size: 20,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final color = _colors[index];
          final colorStr = _colorStrings[index];
          final isSelected = _selectedColor == colorStr;

          return GestureDetector(
            onTap: () => setState(() => _selectedColor = colorStr),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
