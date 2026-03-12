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

class _ProgressSliderState extends State<ProgressSlider> {
  late double _sliderValue;
  bool _isDragging = false;
  int _dragEndFrame = 0; // 拖动结束时的帧计数，用于冷却期

  // 播放器专用颜色常量
  static const Color _background = Color(0xFF2D3548); // PlayerColors.controls
  static const Color _progress = Color(0xFFE8704D); // PlayerColors.progress
  static const Color _buffer = Color(0xFF3D4560); // PlayerColors.progressBuffer

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.value;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(ProgressSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 拖动期间或冷却期内（拖动结束后2帧内），不更新滑块值
    if (_isDragging || _dragEndFrame > 0) {
      if (_dragEndFrame > 0) {
        _dragEndFrame--;
      }
      return;
    }

    // 正常更新
    _sliderValue = widget.value;
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
    return SliderTheme(
      data: SliderThemeData(
        // 已播放进度颜色
        activeTrackColor: _progress,
        // 未播放进度颜色（背景）
        inactiveTrackColor: _background,
        // 缓冲进度颜色
        secondaryActiveTrackColor: _buffer,
        // 拖动手柄颜色
        thumbColor: _progress,
        // 按下时的阴影颜色
        overlayColor: _progress.withValues(alpha: 0.2),
        // 轨道高度
        trackHeight: 4,
        // 手柄形状和大小
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        // 轨道形状
        trackShape: const RoundedRectSliderTrackShape(),
        // 不显示刻度
        showValueIndicator: ShowValueIndicator.never,
        // 叠加轨道（已播放和缓冲在同一轨道）
        overlappingShapeStrokeColor: Colors.transparent,
      ),
      child: Slider(
        value: _isDragging ? _sliderValue : widget.value.clamp(0.0, 1.0),
        secondaryTrackValue: widget.bufferValue.clamp(0.0, 1.0),
        max: 1.0,
        // 拖动开始
        onChangeStart: (_) {
          setState(() => _isDragging = true);
        },
        // 拖动中：只更新本地状态
        onChanged: (value) {
          setState(() => _sliderValue = value);
        },
        // 拖动结束：执行 seek
        onChangeEnd: (value) {
          setState(() {
            _sliderValue = value;
            _isDragging = false; // 立即结束拖动状态
            _dragEndFrame = 2; // 设置2帧冷却期，防止旧值覆盖
          });
          widget.onSeek(value);
        },
      ),
    );
  }
}
