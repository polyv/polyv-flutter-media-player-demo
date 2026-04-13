import 'package:flutter/material.dart';
import 'time_label.dart';

/// ProgressSlider - 播放进度条组件
///
/// 显示当前播放位置、缓冲进度，支持拖动 seek
class ProgressSlider extends StatefulWidget {
  /// 当前播放进度 (0.0 - 1.0)
  final double value;

  /// 缓冲进度 (0.0 - 1.0)
  final double bufferValue;

  /// 总时长（毫秒）
  final int duration;

  /// 当前位置（毫秒）
  final int position;

  /// Seek 回调
  final ValueChanged<double> onSeek;

  /// 是否显示时间标签
  final bool showTimeLabels;

  const ProgressSlider({
    super.key,
    required this.value,
    required this.bufferValue,
    required this.duration,
    required this.position,
    required this.onSeek,
    this.showTimeLabels = true,
  });

  @override
  State<ProgressSlider> createState() => _ProgressSliderState();
}

class _ProgressSliderState extends State<ProgressSlider>
    with SingleTickerProviderStateMixin {
  late double _sliderValue;
  bool _isDragging = false;

  // 动画控制器：用于非拖动时的平滑过渡
  late final AnimationController _animController;
  late Animation<double> _animation;
  double _animFrom = 0.0;
  double _animTo = 0.0;

  // 播放器专用颜色常量
  static const Color _background = Color(0xFF2D3548);
  static const Color _progress = Color(0xFFE8704D);
  static const Color _buffer = Color(0xFF3D4560);

  // const SliderThemeData 避免每次 build 重新创建
  static const SliderThemeData _sliderTheme = SliderThemeData(
    activeTrackColor: _progress,
    inactiveTrackColor: _background,
    secondaryActiveTrackColor: _buffer,
    thumbColor: _progress,
    overlayColor: Color(0x33E8704D),
    trackHeight: 4,
    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
    trackShape: RoundedRectSliderTrackShape(),
    showValueIndicator: ShowValueIndicator.never,
    overlappingShapeStrokeColor: Colors.transparent,
  );

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.value;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _animation = const AlwaysStoppedAnimation(0.0);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ProgressSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 拖动期间不更新，完全由用户手势控制
    if (_isDragging) return;

    // 进度值变化时，用动画平滑过渡
    if (oldWidget.value != widget.value) {
      _animateTo(widget.value);
    }
  }

  void _animateTo(double target) {
    final currentDisplay = _animController.isCompleted ? _animTo : _sliderValue;

    _animFrom = currentDisplay;
    _animTo = target.clamp(0.0, 1.0);

    // 如果差值极小（< 0.001），直接赋值跳过动画
    if ((_animTo - _animFrom).abs() < 0.001) {
      _animController.value = 1.0;
      _sliderValue = _animTo;
      return;
    }

    _animation = Tween<double>(begin: _animFrom, end: _animTo).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 左侧时间：当前播放位置
        if (widget.showTimeLabels) TimeLabel(milliseconds: widget.position),

        // 进度条
        if (widget.showTimeLabels) const SizedBox(width: 12),
        Expanded(child: _buildSlider()),
        if (widget.showTimeLabels) const SizedBox(width: 12),

        // 右侧时间：总时长
        if (widget.showTimeLabels)
          TimeLabel(
            milliseconds: widget.duration,
            showUnknown: widget.duration <= 0,
          ),
      ],
    );
  }

  Widget _buildSlider() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final displayValue =
            _isDragging ? _sliderValue : _animation.value.clamp(0.0, 1.0);

        return SliderTheme(
          data: _sliderTheme,
          child: Slider(
            value: displayValue,
            secondaryTrackValue: widget.bufferValue.clamp(0.0, 1.0),
            max: 1.0,
            onChangeStart: (_) {
              _animController.stop();
              _sliderValue = _animation.value.clamp(0.0, 1.0);
              _isDragging = true;
            },
            onChanged: (value) {
              _sliderValue = value;
            },
            onChangeEnd: (value) {
              _sliderValue = value;
              _animController.stop();
              _animController.value = 0.0;
              _animation = AlwaysStoppedAnimation(value);
              setState(() {
                _isDragging = false;
              });
              widget.onSeek(value);
            },
          ),
        );
      },
    );
  }
}
