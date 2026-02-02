import 'package:flutter/foundation.dart';
import 'package:polyv_media_player/infrastructure/danmaku/danmaku_model.dart';

/// 弹幕设置状态管理类
///
/// 使用 ChangeNotifier 模式集中管理弹幕开关与样式设置
/// 对齐 architecture.md 中的 Provider 状态管理模式
///
/// 职责：
/// - 管理 enabled、opacity、fontSize 状态
/// - 提供状态变更方法
/// - 支持状态持久化（预留接口）
class DanmakuSettings extends ChangeNotifier {
  /// 是否启用弹幕
  bool _enabled = true;

  /// 弹幕透明度 (0.0 - 1.0)
  double _opacity = 1.0;

  /// 弹幕字体大小
  DanmakuFontSize _fontSize = DanmakuFontSize.medium;

  /// 创建默认设置
  DanmakuSettings({
    bool enabled = true,
    double opacity = 1.0,
    DanmakuFontSize fontSize = DanmakuFontSize.medium,
  }) : _enabled = enabled,
       _opacity = opacity,
       _fontSize = fontSize;

  /// 是否启用弹幕
  bool get enabled => _enabled;

  /// 弹幕透明度 (0.0 - 1.0)
  double get opacity => _opacity;

  /// 弹幕字体大小
  DanmakuFontSize get fontSize => _fontSize;

  /// 切换弹幕开关
  void toggle() {
    _enabled = !_enabled;
    notifyListeners();
  }

  /// 设置弹幕开关状态
  void setEnabled(bool value) {
    if (_enabled != value) {
      _enabled = value;
      notifyListeners();
    }
  }

  /// 设置弹幕透明度
  ///
  /// [value] 透明度值，范围 0.0 - 1.0
  void setOpacity(double value) {
    final clampedValue = value.clamp(0.0, 1.0);
    if ((_opacity - clampedValue).abs() > 0.001) {
      _opacity = clampedValue;
      notifyListeners();
    }
  }

  /// 设置弹幕字体大小
  void setFontSize(DanmakuFontSize value) {
    if (_fontSize != value) {
      _fontSize = value;
      notifyListeners();
    }
  }

  /// 创建副本
  DanmakuSettings copyWith({
    bool? enabled,
    double? opacity,
    DanmakuFontSize? fontSize,
  }) {
    return DanmakuSettings(
      enabled: enabled ?? _enabled,
      opacity: opacity ?? _opacity,
      fontSize: fontSize ?? _fontSize,
    );
  }

  /// 从 JSON 创建（用于持久化）
  factory DanmakuSettings.fromJson(Map<String, dynamic> json) {
    return DanmakuSettings(
      enabled: json['enabled'] as bool? ?? true,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      fontSize: DanmakuFontSize.values.firstWhere(
        (e) => e.name == json['fontSize'],
        orElse: () => DanmakuFontSize.medium,
      ),
    );
  }

  /// 转换为 JSON（用于持久化）
  Map<String, dynamic> toJson() {
    return {
      'enabled': _enabled,
      'opacity': _opacity,
      'fontSize': _fontSize.name,
    };
  }

  @override
  String toString() {
    return 'DanmakuSettings(enabled: $_enabled, opacity: $_opacity, fontSize: $_fontSize)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DanmakuSettings &&
        other._enabled == _enabled &&
        other._opacity == _opacity &&
        other._fontSize == _fontSize;
  }

  @override
  int get hashCode {
    return Object.hash(_enabled, _opacity, _fontSize);
  }
}
