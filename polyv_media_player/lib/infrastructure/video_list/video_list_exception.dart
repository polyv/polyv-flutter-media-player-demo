/// 视频列表错误类型
///
/// 语义化错误分类，用于 UI 展示不同的错误提示
enum VideoListErrorType {
  /// 网络错误 - 连接失败、超时等
  network,

  /// 认证错误 - 签名错误、token 过期等
  auth,

  /// 服务器错误 - 后端返回错误
  server,

  /// 校验错误 - 参数不合法
  validation,

  /// 参数错误 - 参数缺失或格式错误
  parameter,

  /// 未知错误
  unknown,
}

/// 视频列表错误
///
/// 包含错误类型和用户友好的错误消息
class VideoListException implements Exception {
  /// 错误类型
  final VideoListErrorType type;

  /// 错误消息（用户友好）
  final String message;

  /// HTTP 状态码
  final int? statusCode;

  /// 原始错误（用于调试）
  final Object? originalError;

  const VideoListException({
    required this.type,
    required this.message,
    this.statusCode,
    this.originalError,
  });

  /// 从通用异常创建视频列表错误
  factory VideoListException.fromError(Object error) {
    if (error is VideoListException) {
      return error;
    }

    // 根据错误类型进行分类
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('network') ||
        errorStr.contains('socket') ||
        errorStr.contains('connection') ||
        errorStr.contains('timeout')) {
      return VideoListException(
        type: VideoListErrorType.network,
        message: '网络连接失败，请检查网络设置',
        originalError: error,
      );
    }

    if (errorStr.contains('auth') ||
        errorStr.contains('unauthorized') ||
        errorStr.contains('token') ||
        errorStr.contains('sign')) {
      return VideoListException(
        type: VideoListErrorType.auth,
        message: '账号认证失败，请检查账号配置',
        originalError: error,
      );
    }

    if (errorStr.contains('server') ||
        errorStr.contains('500') ||
        errorStr.contains('502') ||
        errorStr.contains('503')) {
      return VideoListException(
        type: VideoListErrorType.server,
        message: '服务器错误，请稍后重试',
        originalError: error,
      );
    }

    if (errorStr.contains('parameter') ||
        errorStr.contains('invalid') ||
        errorStr.contains('400')) {
      return VideoListException(
        type: VideoListErrorType.parameter,
        message: '请求参数错误',
        originalError: error,
      );
    }

    return VideoListException(
      type: VideoListErrorType.unknown,
      message: '获取视频列表失败，请重试',
      originalError: error,
    );
  }

  /// 从 HTTP 状态码创建错误
  factory VideoListException.fromStatusCode(int statusCode) {
    final type = _mapStatusCode(statusCode);
    final message = _getDefaultMessage(type, statusCode);
    return VideoListException(
      type: type,
      message: message,
      statusCode: statusCode,
    );
  }

  /// 认证错误
  factory VideoListException.auth({String? detail}) {
    return VideoListException(
      type: VideoListErrorType.auth,
      message: detail ?? '账号认证失败，请检查账号配置',
    );
  }

  /// 网络错误
  factory VideoListException.network({String? detail}) {
    return VideoListException(
      type: VideoListErrorType.network,
      message: detail ?? '网络连接失败，请检查网络设置',
    );
  }

  /// 服务器错误
  factory VideoListException.server({String? detail}) {
    return VideoListException(
      type: VideoListErrorType.server,
      message: detail ?? '服务器错误，请稍后重试',
    );
  }

  /// 参数错误
  factory VideoListException.parameter({String? detail}) {
    return VideoListException(
      type: VideoListErrorType.parameter,
      message: detail ?? '请求参数错误',
    );
  }

  /// 将 HTTP 状态码映射为错误类型
  static VideoListErrorType _mapStatusCode(int statusCode) {
    switch (statusCode) {
      case 401:
      case 403:
        return VideoListErrorType.auth;
      case 400:
        return VideoListErrorType.parameter;
      case 404:
        return VideoListErrorType.parameter;
      case 500:
      case 502:
      case 503:
        return VideoListErrorType.server;
      default:
        if (statusCode >= 500) {
          return VideoListErrorType.server;
        }
        if (statusCode >= 400) {
          return VideoListErrorType.parameter;
        }
        return VideoListErrorType.network;
    }
  }

  /// 获取默认错误消息
  static String _getDefaultMessage(VideoListErrorType type, int statusCode) {
    switch (type) {
      case VideoListErrorType.network:
        return '网络连接失败，请检查网络设置';
      case VideoListErrorType.auth:
        return '账号认证失败 (HTTP $statusCode)，请检查账号配置';
      case VideoListErrorType.server:
        return '服务器错误 (HTTP $statusCode)，请稍后重试';
      case VideoListErrorType.parameter:
        return '请求参数错误 (HTTP $statusCode)';
      case VideoListErrorType.validation:
        return '数据校验失败';
      case VideoListErrorType.unknown:
        return '获取视频列表失败 (HTTP $statusCode)';
    }
  }

  @override
  String toString() => 'VideoListException($type: $message)';
}
