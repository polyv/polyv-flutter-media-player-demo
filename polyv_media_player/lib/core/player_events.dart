import 'player_state.dart';

/// 播放器事件类型
enum PlayerEventType {
  /// 播放状态变化
  stateChanged,

  /// 进度更新
  progress,

  /// 错误
  error,

  /// 清晰度变化
  qualityChanged,

  /// 字幕变化
  subtitleChanged,

  /// 播放完成
  completed,
}

/// 播放器事件基类
abstract class PlayerEvent {
  /// 事件类型
  final PlayerEventType type;

  const PlayerEvent(this.type);
}

/// 播放状态变化事件
class StateChangedEvent extends PlayerEvent {
  /// 新的状态
  final PlayerLoadingState state;

  const StateChangedEvent(this.state) : super(PlayerEventType.stateChanged);
}

/// 进度更新事件
class ProgressEvent extends PlayerEvent {
  /// 当前位置（毫秒）
  final int position;

  /// 总时长（毫秒）
  final int duration;

  /// 缓冲位置（毫秒）
  final int bufferedPosition;

  const ProgressEvent({
    required this.position,
    required this.duration,
    required this.bufferedPosition,
  }) : super(PlayerEventType.progress);
}

/// 错误事件
class ErrorEvent extends PlayerEvent {
  /// 错误码
  final String code;

  /// 错误信息
  final String message;

  /// 额外详情
  final Map<String, dynamic>? details;

  const ErrorEvent({required this.code, required this.message, this.details})
    : super(PlayerEventType.error);
}

/// 清晰度变化事件
class QualityChangedEvent extends PlayerEvent {
  /// 清晰度列表
  final List<QualityItem> qualities;

  /// 当前清晰度索引
  final int currentIndex;

  const QualityChangedEvent({
    required this.qualities,
    required this.currentIndex,
  }) : super(PlayerEventType.qualityChanged);
}

/// 清晰度项
class QualityItem {
  /// 清晰度描述（如 "超清"、"高清"、"标清"）
  final String description;

  /// 清晰度值
  final String value;

  /// 是否支持
  final bool isAvailable;

  const QualityItem({
    required this.description,
    required this.value,
    this.isAvailable = true,
  });

  factory QualityItem.fromJson(Map<String, dynamic> json) {
    return QualityItem(
      description: json['description'] as String,
      value: json['value'] as String,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'value': value,
      'isAvailable': isAvailable,
    };
  }

  @override
  String toString() => description;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QualityItem &&
        other.description == description &&
        other.value == value &&
        other.isAvailable == isAvailable;
  }

  @override
  int get hashCode => Object.hash(description, value, isAvailable);
}

/// 字幕变化事件
class SubtitleChangedEvent extends PlayerEvent {
  /// 字幕列表
  final List<SubtitleItem> subtitles;

  /// 当前字幕索引（-1 表示关闭）
  final int currentIndex;

  const SubtitleChangedEvent({
    required this.subtitles,
    required this.currentIndex,
  }) : super(PlayerEventType.subtitleChanged);
}

/// 字幕项
class SubtitleItem {
  /// 字幕轨道键（原生内部可唯一定位的 key）
  ///
  /// iOS: 字幕名称（如 "中文", "English", "双语"）
  /// Android: 字幕组合标识（从 PLVMediaSubtitle.name 映射）
  final String trackKey;

  /// 字幕语言码（如 "zh", "en", "zh+en"）
  final String language;

  /// 字幕标签（展示文案，如「中文」「English」「中+英」）
  final String label;

  /// 字幕 URL（外挂字幕，可选）
  final String? url;

  /// 是否双语字幕
  final bool isBilingual;

  /// 是否原生侧认为的默认轨道（仅作为 Dart 算法输入信号）
  final bool isDefault;

  const SubtitleItem({
    required this.trackKey,
    required this.language,
    required this.label,
    this.url,
    this.isBilingual = false,
    this.isDefault = false,
  });

  /// 从 JSON 创建 SubtitleItem
  ///
  /// 支持新旧两种格式：
  /// - 新格式：{ trackKey, language, label, url?, isBilingual?, isDefault? }
  /// - 旧格式（兼容）：{ language, label, url? }，此时 trackKey = language
  factory SubtitleItem.fromJson(Map<String, dynamic> json) {
    final trackKey = json['trackKey'] as String?;
    final language = json['language'] as String;
    final label = json['label'] as String;

    // 兼容旧格式：如果没有 trackKey，使用 language 作为 trackKey
    final effectiveTrackKey = trackKey ?? language;

    return SubtitleItem(
      trackKey: effectiveTrackKey,
      language: language,
      label: label,
      url: json['url'] as String?,
      isBilingual: json['isBilingual'] as bool? ?? false,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'trackKey': trackKey,
      'language': language,
      'label': label,
      if (url != null) 'url': url,
      'isBilingual': isBilingual,
      'isDefault': isDefault,
    };
  }

  /// 创建双语字幕项
  factory SubtitleItem.bilingual({
    required String trackKey,
    required String label,
  }) {
    return SubtitleItem(
      trackKey: trackKey,
      language: 'zh+en',
      label: label,
      isBilingual: true,
      isDefault: true,
    );
  }

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubtitleItem &&
        other.trackKey == trackKey &&
        other.language == language &&
        other.label == label &&
        other.url == url &&
        other.isBilingual == isBilingual &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return Object.hash(trackKey, language, label, url, isBilingual, isDefault);
  }
}

/// 播放完成事件
class CompletedEvent extends PlayerEvent {
  const CompletedEvent() : super(PlayerEventType.completed);
}
