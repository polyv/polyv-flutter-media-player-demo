import 'package:flutter/material.dart';

/// 播放器颜色常量
///
/// 统一管理播放器 UI 相关的颜色值
class PlayerColors {
  // 私有构造函数，防止实例化
  PlayerColors._();

  /// 最深层背景色
  static const Color background = Color(0xFF121621);

  /// 面板/弹窗背景色
  static const Color surface = Color(0xFF1E2432);

  /// 控件背景色
  static const Color controls = Color(0xFF2D3548);

  /// 已播放进度色（珊瑚橙）
  static const Color progress = Color(0xFFE8704D);

  /// 缓冲进度色
  static const Color progressBuffer = Color(0xFF3D4560);

  /// 主文字色
  static const Color text = Color(0xFFF5F5F5);

  /// 次要文字色
  static const Color textMuted = Color(0xFF8B919E);

  /// 禁用状态叠加色（用于降低不透明度）
  static const Color disabledOverlay = Color(0x40000000);

  /// 选中状态的高亮背景（progress 色带透明度）
  static const Color activeHighlight = Color(
    0x26E8704D,
  ); // 0.15 alpha on 0xFFE8704D

  /// 主色调（别名）
  static const Color primary = progress;
}
