import 'package:flutter/services.dart';

/// 播放器异常
class PlayerException implements Exception {
  /// 错误码
  final String code;

  /// 错误信息
  final String message;

  /// 额外详情
  final dynamic details;

  const PlayerException({
    required this.code,
    required this.message,
    this.details,
  });

  /// 从 PlatformException 创建
  factory PlayerException.fromPlatformException(PlatformException e) {
    final String code = e.code;
    final String? messageNullable = e.message;
    final String message = messageNullable ?? 'An unknown error occurred';
    return PlayerException(
      code: code.isNotEmpty ? code : 'UNKNOWN_ERROR',
      message: message.isNotEmpty ? message : 'An unknown error occurred',
      details: e.details,
    );
  }

  /// 创建无效 VID 错误
  factory PlayerException.invalidVid(String vid) {
    return PlayerException(
      code: 'INVALID_VID',
      message: 'Invalid video ID: $vid',
    );
  }

  /// 创建网络错误
  factory PlayerException.networkError([String? message]) {
    return PlayerException(
      code: 'NETWORK_ERROR',
      message: message ?? 'Network connection failed',
    );
  }

  /// 创建播放器未初始化错误
  factory PlayerException.notInitialized() {
    return const PlayerException(
      code: 'NOT_INITIALIZED',
      message: 'Player has not been initialized',
    );
  }

  /// 创建不支持的操作错误
  factory PlayerException.unsupportedOperation(String operation) {
    return PlayerException(
      code: 'UNSUPPORTED_OPERATION',
      message: 'Unsupported operation: $operation',
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('PlayerException: $code - $message');
    if (details != null) {
      buffer.write(' (details: $details)');
    }
    return buffer.toString();
  }
}
