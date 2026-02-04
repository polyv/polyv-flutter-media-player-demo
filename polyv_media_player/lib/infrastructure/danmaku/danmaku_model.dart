/// 弹幕数据模型
///
/// 对应 Web 原型 DanmakuLayer.tsx 中的 Danmaku 接口
/// 参考: /Users/nick/projects/polyv/ios/polyv-vod/src/components/player/DanmakuLayer.tsx

/// 弹幕类型枚举
enum DanmakuType {
  /// 滚动弹幕（从右向左）
  scroll,

  /// 顶部固定弹幕
  top,

  /// 底部固定弹幕
  bottom,
}

/// 弹幕字体大小枚举
enum DanmakuFontSize {
  /// 小字号 - 对应 text-xs (12px)
  small,

  /// 中字号 - 对应 text-sm (14px)
  medium,

  /// 大字号 - 对应 text-base (16px)
  large,
}

/// 弹幕数据类
///
/// 包含弹幕的所有核心属性
class Danmaku {
  /// 弹幕唯一标识
  final String id;

  /// 弹幕文本内容
  final String text;

  /// 弹幕出现时间（毫秒）
  final int time;

  /// 弹幕颜色（可选，默认白色）
  final int? color;

  /// 弹幕类型（默认滚动）
  final DanmakuType type;

  const Danmaku({
    required this.id,
    required this.text,
    required this.time,
    this.color,
    this.type = DanmakuType.scroll,
  });

  /// 从 JSON 创建 Danmaku
  factory Danmaku.fromJson(Map<String, dynamic> json) {
    return Danmaku(
      id: json['id'] as String,
      text: json['text'] as String,
      time: json['time'] as int,
      color: json['color'] != null
          ? _parseColor(json['color'].toString())
          : null,
      type: json['type'] != null
          ? _parseDanmakuType(json['type'] as String)
          : DanmakuType.scroll,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'time': time,
      if (color != null) 'color': color?.toRadixString(16),
      'type': type.name,
    };
  }

  /// 创建副本并修改部分属性
  Danmaku copyWith({
    String? id,
    String? text,
    int? time,
    int? color,
    DanmakuType? type,
  }) {
    return Danmaku(
      id: id ?? this.id,
      text: text ?? this.text,
      time: time ?? this.time,
      color: color ?? this.color,
      type: type ?? this.type,
    );
  }

  /// 解析颜色字符串
  ///
  /// 支持以下格式：
  /// - #RRGGBB (如 #FF00FF)
  /// - #AARRGGBB (如 #FFFF00FF，ARGB 格式)
  /// - 0xRRGGBB (如 0xFF00FF)
  /// - 0xAARRGGBB (如 0xFFFF00FF，完整 ARGB)
  /// - RRGGBB / AARRGGBB（无前缀）
  static int? _parseColor(String colorStr) {
    try {
      final input = colorStr.trim();
      if (input.isEmpty) return null;

      String hex;
      int? alpha;

      // 支持 #RRGGBB 或 #AARRGGBB 格式
      if (input.startsWith('#')) {
        hex = input.substring(1);
        if (hex.length == 6) {
          alpha = 0xFF; // 不透明
        } else if (hex.length == 8) {
          // ARGB 格式：alpha 包含在字符串中
          alpha = null;
        } else {
          return null;
        }
      }
      // 支持 0x 前缀格式
      else if (input.startsWith('0x') || input.startsWith('0X')) {
        hex = input.substring(2);
        // 判断是 RRGGBB (6位) 还是 ARGB (8位)
        if (hex.length == 6) {
          alpha = 0xFF; // RRGGBB 格式，默认不透明
        } else if (hex.length == 8) {
          // ARGB 格式，alpha 包含在字符串中
          alpha = null;
        } else {
          return null;
        }
      } else {
        // 无前缀：RRGGBB / AARRGGBB
        hex = input;
        if (hex.length == 6) {
          alpha = 0xFF;
        } else if (hex.length == 8) {
          alpha = null;
        } else {
          return null;
        }
      }

      final value = int.parse(hex, radix: 16);
      if (alpha != null) {
        return (alpha << 24) | value;
      }

      return value;
    } catch (_) {
      // 解析失败，返回 null 使用默认颜色
    }
    return null;
  }

  /// 解析弹幕类型
  static DanmakuType _parseDanmakuType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'scroll':
        return DanmakuType.scroll;
      case 'top':
        return DanmakuType.top;
      case 'bottom':
        return DanmakuType.bottom;
      default:
        return DanmakuType.scroll;
    }
  }

  @override
  String toString() {
    return 'Danmaku(id: $id, text: $text, time: $time, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Danmaku &&
        other.id == id &&
        other.text == text &&
        other.time == time &&
        other.color == color &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(id, text, time, color, type);
  }
}

/// 活跃弹幕（正在屏幕上显示的弹幕）
///
/// 继承自 Danmaku，增加轨道和开始时间信息
/// 对应 Web 原型中的 ActiveDanmaku 接口
class ActiveDanmaku extends Danmaku {
  /// 分配的轨道索引（0-7）
  final int track;

  /// 开始显示的时间戳（系统时间，毫秒）
  final int startTime;

  const ActiveDanmaku({
    required super.id,
    required super.text,
    required super.time,
    super.color,
    super.type = DanmakuType.scroll,
    required this.track,
    required this.startTime,
  });

  /// 从普通弹幕创建活跃弹幕
  factory ActiveDanmaku.fromDanmaku(
    Danmaku danmaku, {
    required int track,
    required int startTime,
  }) {
    return ActiveDanmaku(
      id: danmaku.id,
      text: danmaku.text,
      time: danmaku.time,
      color: danmaku.color,
      type: danmaku.type,
      track: track,
      startTime: startTime,
    );
  }

  /// 弹幕动画时长（毫秒）
  static const int animationDuration = 10000;

  /// 弹幕时间窗口（毫秒）
  /// 当前时间前后 300ms 内的弹幕都会被显示
  static const int timeWindow = 300;

  /// 检查弹幕是否已过期（超过动画时长）
  bool isExpired(int currentTime) {
    return (currentTime - startTime) >= animationDuration;
  }

  @override
  Danmaku copyWith({
    String? id,
    String? text,
    int? time,
    int? color,
    DanmakuType? type,
    int? track,
    int? startTime,
  }) {
    return ActiveDanmaku(
      id: id ?? this.id,
      text: text ?? this.text,
      time: time ?? this.time,
      color: color ?? this.color,
      type: type ?? this.type,
      track: track ?? this.track,
      startTime: startTime ?? this.startTime,
    );
  }

  @override
  String toString() {
    return 'ActiveDanmaku(id: $id, text: $text, time: $time, track: $track, startTime: $startTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActiveDanmaku &&
        super == other &&
        other.track == track &&
        other.startTime == startTime;
  }

  @override
  int get hashCode {
    return Object.hash(super.hashCode, track, startTime);
  }
}

// ============================================================================
// 弹幕发送相关模型
// ============================================================================

/// 弹幕发送错误类型
///
/// 语义化错误分类，用于 UI 展示不同的错误提示
enum DanmakuSendErrorType {
  /// 网络错误 - 连接失败、超时等
  network,

  /// 认证错误 - 未登录、token 过期等
  auth,

  /// 服务器错误 - 后端返回错误
  server,

  /// 校验错误 - 输入不合法（空文本、超长等）
  validation,

  /// 节流错误 - 发送过于频繁
  throttled,

  /// 未知错误
  unknown,
}

/// 弹幕发送错误
///
/// 包含错误类型和用户友好的错误消息
class DanmakuSendException implements Exception {
  /// 错误类型
  final DanmakuSendErrorType type;

  /// 错误消息（用户友好）
  final String message;

  /// 原始错误（用于调试）
  final Object? originalError;

  const DanmakuSendException({
    required this.type,
    required this.message,
    this.originalError,
  });

  /// 从通用异常创建弹幕发送错误
  factory DanmakuSendException.fromError(Object error) {
    if (error is DanmakuSendException) {
      return error;
    }

    // 根据错误类型进行分类
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('network') ||
        errorStr.contains('socket') ||
        errorStr.contains('connection')) {
      return DanmakuSendException(
        type: DanmakuSendErrorType.network,
        message: '网络连接失败，请检查网络设置',
        originalError: error,
      );
    }
    if (errorStr.contains('auth') ||
        errorStr.contains('unauthorized') ||
        errorStr.contains('token')) {
      return DanmakuSendException(
        type: DanmakuSendErrorType.auth,
        message: '登录已过期，请重新登录',
        originalError: error,
      );
    }
    if (errorStr.contains('server') || errorStr.contains('500')) {
      return DanmakuSendException(
        type: DanmakuSendErrorType.server,
        message: '服务器错误，请稍后重试',
        originalError: error,
      );
    }
    if (errorStr.contains('throttle') ||
        errorStr.contains('rate limit') ||
        errorStr.contains('too many')) {
      return DanmakuSendException(
        type: DanmakuSendErrorType.throttled,
        message: '发送过于频繁，请稍后再试',
        originalError: error,
      );
    }

    return DanmakuSendException(
      type: DanmakuSendErrorType.unknown,
      message: '发送失败，请重试',
      originalError: error,
    );
  }

  @override
  String toString() => 'DanmakuSendException($type: $message)';
}

/// 弹幕发送请求
///
/// 包含发送弹幕所需的所有参数
class DanmakuSendRequest {
  /// 视频 ID
  final String vid;

  /// 弹幕文本内容
  final String text;

  /// 弹幕出现时间（毫秒）- 通常为当前播放时间
  final int time;

  /// 弹幕颜色（可选，十六进制字符串，如 #ffffff）
  final String? color;

  /// 弹幕类型（可选，默认滚动）
  final DanmakuType? type;

  /// 字体大小（可选）
  final DanmakuFontSize? fontSize;

  const DanmakuSendRequest({
    required this.vid,
    required this.text,
    required this.time,
    this.color,
    this.type,
    this.fontSize,
  });

  /// 转换为 JSON（用于发送到后端）
  Map<String, dynamic> toJson() {
    return {
      'vid': vid,
      'text': text,
      'time': time,
      if (color != null) 'color': color,
      if (type != null) 'type': type!.name,
      if (fontSize != null) 'fontSize': fontSize!.name,
    };
  }

  /// 创建副本
  DanmakuSendRequest copyWith({
    String? vid,
    String? text,
    int? time,
    String? color,
    DanmakuType? type,
    DanmakuFontSize? fontSize,
  }) {
    return DanmakuSendRequest(
      vid: vid ?? this.vid,
      text: text ?? this.text,
      time: time ?? this.time,
      color: color ?? this.color,
      type: type ?? this.type,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  @override
  String toString() {
    return 'DanmakuSendRequest(vid: $vid, text: $text, time: $time)';
  }
}

/// 弹幕发送响应
///
/// 后端返回的发送结果
class DanmakuSendResponse {
  /// 是否发送成功
  final bool success;

  /// 发送的弹幕 ID（后端生成）
  final String? danmakuId;

  /// 错误信息（如果失败）
  final String? error;

  /// 服务器时间（毫秒）
  final int? serverTime;

  const DanmakuSendResponse({
    required this.success,
    this.danmakuId,
    this.error,
    this.serverTime,
  });

  /// 从 JSON 创建响应
  factory DanmakuSendResponse.fromJson(Map<String, dynamic> json) {
    return DanmakuSendResponse(
      success: json['success'] as bool? ?? false,
      danmakuId: json['danmakuId'] as String?,
      error: json['error'] as String?,
      serverTime: json['serverTime'] as int?,
    );
  }

  /// 创建成功响应
  factory DanmakuSendResponse.success({String? danmakuId, int? serverTime}) {
    return DanmakuSendResponse(
      success: true,
      danmakuId: danmakuId,
      serverTime: serverTime,
    );
  }

  /// 创建失败响应
  factory DanmakuSendResponse.failure(String error) {
    return DanmakuSendResponse(success: false, error: error);
  }

  @override
  String toString() {
    return 'DanmakuSendResponse(success: $success, danmakuId: $danmakuId)';
  }
}
