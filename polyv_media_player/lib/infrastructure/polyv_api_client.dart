import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Polyv API 错误类型
///
/// 语义化错误分类，用于 UI 展示不同的错误提示
enum PolyvApiErrorType {
  /// 网络错误 - 连接失败、超时等
  network,

  /// 认证错误 - 签名错误、token 过期等
  auth,

  /// 服务器错误 - 后端返回错误
  server,

  /// 校验错误 - 参数不合法
  validation,

  /// 未知错误
  unknown,
}

/// Polyv API 错误
///
/// 包含错误类型和用户友好的错误消息
class PolyvApiException implements Exception {
  /// 错误类型
  final PolyvApiErrorType type;

  /// 错误消息（用户友好）
  final String message;

  /// HTTP 状态码
  final int? statusCode;

  /// 原始错误（用于调试）
  final Object? originalError;

  const PolyvApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'PolyvApiException($type: $message)';
}

/// Polyv API 响应
///
/// 封装 HTTP 响应数据和元信息
class PolyvApiResponse<T> {
  /// 是否成功
  final bool success;

  /// 响应数据
  final T? data;

  /// 错误信息（如果失败）
  final String? error;

  /// HTTP 状态码
  final int statusCode;

  /// 原始响应体
  final String? rawBody;

  const PolyvApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
    this.rawBody,
  });

  /// 创建成功响应
  factory PolyvApiResponse.success({
    required T? data,
    required int statusCode,
    String? rawBody,
  }) {
    return PolyvApiResponse(
      success: true,
      data: data,
      statusCode: statusCode,
      rawBody: rawBody,
    );
  }

  /// 创建失败响应
  factory PolyvApiResponse.failure({
    required String error,
    required int statusCode,
    String? rawBody,
  }) {
    return PolyvApiResponse(
      success: false,
      error: error,
      statusCode: statusCode,
      rawBody: rawBody,
    );
  }
}

/// Polyv API 客户端
///
/// 统一的 Polyv API 调用基础设施，提供：
/// - 签名生成算法
/// - HTTP 请求封装（GET/POST）
/// - 参数编码
/// - 时间格式转换
/// - 错误处理
///
/// 使用方式：
/// ```dart
/// final apiClient = PolyvApiClient(
///   userId: 'xxx',
///   readToken: 'xxx',
///   writeToken: 'xxx',
///   secretKey: 'xxx',
/// );
///
/// final response = await apiClient.get('/v2/danmu', params: {'vid': 'video123'});
/// ```
class PolyvApiClient {
  /// Polyv 用户 ID
  final String userId;

  /// 读取令牌
  final String readToken;

  /// 写入令牌
  final String writeToken;

  /// 密钥（用于签名）
  final String secretKey;

  /// API 基础 URL
  final String baseUrl;

  /// HTTP 客户端
  final http.Client _client;

  /// 创建 API 客户端
  PolyvApiClient({
    required this.userId,
    required this.readToken,
    required this.writeToken,
    required this.secretKey,
    this.baseUrl = 'https://api.polyv.net',
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// 执行 GET 请求
  ///
  /// [path] API 路径（如 '/v2/danmu'）
  /// [params] 查询参数
  /// [useReadToken] 是否使用 readToken（默认 true，获取数据时）
  /// [usePtime] 是否使用 ptime 代替 timestamp（默认 false，视频列表 API 需要设为 true）
  Future<PolyvApiResponse<List<dynamic>>> get(
    String path, {
    Map<String, dynamic>? params,
    bool useReadToken = true,
    bool usePtime = false,
  }) async {
    final queryParams = Map<String, dynamic>.from(params ?? {});

    // 添加鉴权参数
    // 注意：视频列表 API 不需要 readtoken，只需要 userid 和 ptime
    if (useReadToken && !usePtime) {
      queryParams['userid'] = userId;
      queryParams['readtoken'] = readToken;
    } else if (!usePtime) {
      queryParams['userid'] = userId;
      queryParams['writetoken'] = writeToken;
    } else {
      // 视频列表 API - 只需要 userid
      queryParams['userid'] = userId;
    }

    // 添加时间戳和签名
    // 视频列表 API 使用 ptime（毫秒），其他 API 使用 timestamp（字符串）
    if (usePtime) {
      queryParams['ptime'] = DateTime.now().millisecondsSinceEpoch;
    } else {
      queryParams['timestamp'] = DateTime.now().millisecondsSinceEpoch
          .toString();
    }
    queryParams['sign'] = _generateSign(queryParams);

    try {
      final uri = Uri.parse('$baseUrl$path').replace(
        queryParameters: queryParams.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );

      final response = await _client.get(uri);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 尝试解析为 JSON
        try {
          final jsonData = json.decode(response.body);

          // 如果返回的是数组，直接返回
          if (jsonData is List) {
            return PolyvApiResponse<List<dynamic>>.success(
              data: jsonData,
              statusCode: response.statusCode,
              rawBody: response.body,
            );
          }

          // 如果返回的是对象，检查是否有 code 字段
          if (jsonData is Map) {
            final code = jsonData['code'];
            if (code != null && code != 200) {
              throw PolyvApiException(
                type: _mapErrorType(code),
                message: jsonData['message']?.toString() ?? '请求失败',
                statusCode: response.statusCode,
              );
            }

            // 返回数据部分
            return PolyvApiResponse<List<dynamic>>.success(
              data: jsonData['data'] as List<dynamic>?,
              statusCode: response.statusCode,
              rawBody: response.body,
            );
          }

          return PolyvApiResponse<List<dynamic>>.success(
            data: jsonData as List<dynamic>?,
            statusCode: response.statusCode,
            rawBody: response.body,
          );
        } on FormatException {
          // 不是 JSON，返回原始数据
          return PolyvApiResponse<List<dynamic>>.failure(
            error: '响应格式错误',
            statusCode: response.statusCode,
            rawBody: response.body,
          );
        }
      } else {
        throw PolyvApiException(
          type: _mapStatusCode(response.statusCode),
          message: 'HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw PolyvApiException(
        type: PolyvApiErrorType.network,
        message: '网络连接失败: ${e.message}',
        originalError: e,
      );
    } on PolyvApiException {
      rethrow;
    } catch (e) {
      throw PolyvApiException(
        type: PolyvApiErrorType.unknown,
        message: '请求失败: $e',
        originalError: e,
      );
    }
  }

  /// 执行 POST 请求
  ///
  /// [path] API 路径（如 '/v2/danmu/add'）
  /// [bodyParams] 请求体参数
  /// [useWriteToken] 是否使用 writeToken（默认 true，发送数据时）
  Future<PolyvApiResponse<Map<String, dynamic>?>> post(
    String path, {
    Map<String, dynamic>? bodyParams,
    bool useWriteToken = true,
  }) async {
    final params = Map<String, dynamic>.from(bodyParams ?? {});

    // 添加鉴权参数
    if (useWriteToken) {
      params['userid'] = userId;
      params['writetoken'] = writeToken;
    } else {
      params['userid'] = userId;
      params['readtoken'] = readToken;
    }

    // 添加时间戳和签名
    params['timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();
    params['sign'] = _generateSign(params);

    try {
      final uri = Uri.parse('$baseUrl$path');

      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: _encodeParams(params),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final jsonData = json.decode(response.body);

          if (jsonData is Map) {
            final code = jsonData['code'];
            if (code != null && code != 200) {
              throw PolyvApiException(
                type: _mapErrorType(code),
                message: jsonData['message']?.toString() ?? '请求失败',
                statusCode: response.statusCode,
              );
            }

            return PolyvApiResponse<Map<String, dynamic>?>.success(
              data: jsonData['data'] as Map<String, dynamic>?,
              statusCode: response.statusCode,
              rawBody: response.body,
            );
          }

          return PolyvApiResponse<Map<String, dynamic>?>.success(
            data: jsonData as Map<String, dynamic>?,
            statusCode: response.statusCode,
            rawBody: response.body,
          );
        } on FormatException {
          return PolyvApiResponse<Map<String, dynamic>?>.failure(
            error: '响应格式错误',
            statusCode: response.statusCode,
            rawBody: response.body,
          );
        }
      } else {
        throw PolyvApiException(
          type: _mapStatusCode(response.statusCode),
          message: 'HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw PolyvApiException(
        type: PolyvApiErrorType.network,
        message: '网络连接失败: ${e.message}',
        originalError: e,
      );
    } on PolyvApiException {
      rethrow;
    } catch (e) {
      throw PolyvApiException(
        type: PolyvApiErrorType.unknown,
        message: '请求失败: $e',
        originalError: e,
      );
    }
  }

  /// 生成请求签名
  ///
  /// 签名算法（参考 iOS PLVVodMediaVideoNetwork）：
  /// 1. 移除 sign 参数
  /// 2. 按 key 字母顺序排序
  /// 3. 拼接参数为 "key1=value1&key2=value2&..." 格式
  /// 4. 追加 secretKey
  /// 5. 计算 SHA1 哈希
  String _generateSign(Map<String, dynamic> params) {
    // 移除 sign 本身（如果存在）
    final signParams = Map<String, dynamic>.from(params);
    signParams.remove('sign');

    // 按 key 排序（不区分大小写）
    final sortedKeys = signParams.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    // 拼接参数为 "key=value&key=value" 格式
    final buffer = StringBuffer();
    for (int i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      buffer.write('$key=${signParams[key]}');
      if (i < sortedKeys.length - 1) {
        buffer.write('&');
      }
    }

    // 添加 secretKey
    buffer.write(secretKey);

    // SHA1 哈希
    final bytes = utf8.encode(buffer.toString());
    final digest = sha1.convert(bytes);

    return digest.toString().toUpperCase();
  }

  /// 编码表单参数
  String _encodeParams(Map<String, dynamic> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
        )
        .join('&');
  }

  /// 将错误码映射为错误类型
  PolyvApiErrorType _mapErrorType(dynamic code) {
    if (code == null) return PolyvApiErrorType.unknown;

    // 支持数值型和字符串型错误码
    final codeInt = code is int ? code : int.tryParse(code.toString());
    if (codeInt == null) return PolyvApiErrorType.unknown;

    switch (codeInt) {
      case 401:
      case 403:
        return PolyvApiErrorType.auth;
      case 400:
        return PolyvApiErrorType.validation;
      case 500:
      case 502:
      case 503:
        return PolyvApiErrorType.server;
      default:
        return PolyvApiErrorType.unknown;
    }
  }

  /// 将 HTTP 状态码映射为错误类型
  PolyvApiErrorType _mapStatusCode(int statusCode) {
    switch (statusCode) {
      case 401:
      case 403:
        return PolyvApiErrorType.auth;
      case 400:
        return PolyvApiErrorType.validation;
      case 500:
      case 502:
      case 503:
        return PolyvApiErrorType.server;
      default:
        return PolyvApiErrorType.network;
    }
  }

  /// 将毫秒时间转换为 HH:MM:SS 格式
  static String millisecondsToTimeStr(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// 将 HH:MM:SS 格式转换为毫秒
  static int timeStrToMilliseconds(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 3) return 0;

    try {
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final s = int.parse(parts[2]);
      return (h * 3600 + m * 60 + s) * 1000;
    } catch (_) {
      return 0;
    }
  }

  /// 将颜色字符串（0xRRGGBB）解析为整数值
  static int parseColorInt(String colorStr) {
    final str = colorStr.toLowerCase().replaceAll('0x', '').replaceAll('#', '');
    return int.tryParse(str, radix: 16) ?? 0xFFFFFF;
  }

  /// 将颜色整数值格式化为 0xRRGGBB 格式
  static String formatColorInt(int color) {
    return '0x${color.toRadixString(16).padLeft(6, '0')}';
  }

  /// 关闭 HTTP 客户端
  void dispose() {
    _client.close();
  }
}
