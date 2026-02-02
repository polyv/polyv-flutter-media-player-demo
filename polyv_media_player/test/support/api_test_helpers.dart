import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:polyv_media_player/infrastructure/polyv_api_client.dart';

/// API 测试辅助工具类
///
/// 提供 API 测试中常用的 Mock 和验证功能
class ApiTestHelpers {
  /// 创建 Mock HTTP 客户端
  ///
  /// [handler] 请求处理器，返回预期的 HTTP 响应
  /// [delay] 模拟网络延迟（毫秒），默认无延迟
  static MockClient createMockClient(
    Future<http.Response> Function(http.Request) handler, {
    int? delay,
  }) {
    return MockClient((request) async {
      if (delay != null) {
        await Future.delayed(Duration(milliseconds: delay));
      }
      return handler(request);
    });
  }

  /// 创建成功的 JSON 响应
  static http.Response successJsonResponse(Map<String, dynamic> data) {
    return http.Response(
      json.encode(data),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  /// 创建成功的 JSON 数组响应
  static http.Response successJsonListResponse(List<dynamic> data) {
    return http.Response(
      json.encode(data),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  /// 创建错误响应
  static http.Response errorResponse(int statusCode, String message) {
    return http.Response(
      json.encode({'error': message, 'code': statusCode}),
      statusCode,
      headers: {'content-type': 'application/json'},
    );
  }

  /// 创建网络错误响应
  static http.Response networkErrorResponse() {
    return http.Response('Network error', 500);
  }

  /// 创建空的 JSON 响应
  static http.Response emptyJsonResponse() {
    return http.Response(
      json.encode({}),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  /// 验证请求 URL
  static void verifyUrl(http.Request request, String expectedPath) {
    expect(
      request.url.path.endsWith(expectedPath),
      isTrue,
      reason:
          'Expected URL path to end with $expectedPath, got ${request.url.path}',
    );
  }

  /// 验证请求包含查询参数
  static void verifyQueryParams(
    http.Request request,
    Map<String, String> expectedParams,
  ) {
    final actualParams = request.url.queryParameters;
    for (final entry in expectedParams.entries) {
      expect(
        actualParams[entry.key],
        entry.value,
        reason: 'Expected query param ${entry.key} to be ${entry.value}',
      );
    }
  }

  /// 验证请求包含特定的查询参数键（忽略值）
  static void verifyHasQueryParams(
    http.Request request,
    List<String> paramKeys,
  ) {
    final actualParams = request.url.queryParameters;
    for (final key in paramKeys) {
      expect(
        actualParams.containsKey(key),
        isTrue,
        reason: 'Expected query param $key to be present',
      );
    }
  }

  /// 验证请求包含鉴权参数
  static void verifyAuthParams(
    http.Request request, {
    required String userId,
    String? tokenType, // 'readtoken' or 'writetoken'
    String? tokenValue,
  }) {
    final params = request.url.queryParameters;
    expect(params['userid'], userId);

    if (tokenType != null && tokenValue != null) {
      expect(params[tokenType], tokenValue);
    }

    // 验证签名参数存在
    expect(params.containsKey('sign'), isTrue);
    expect(params.containsKey('timestamp'), isTrue);
  }
}

/// 弹幕 API 响应构建器
///
/// 用于构建符合 Polyv API 格式的弹幕响应
class DanmakuApiResponseBuilder {
  final List<Map<String, dynamic>> _danmakus = [];

  /// 添加弹幕
  DanmakuApiResponseBuilder addDanmaku({
    required String msg,
    required String time,
    String fontColor = '0xffffff',
    String fontMode = 'roll',
  }) {
    _danmakus.add({
      'msg': msg,
      'time': time,
      'fontColor': fontColor,
      'fontMode': fontMode,
    });
    return this;
  }

  /// 构建成功响应
  http.Response buildSuccess() {
    return ApiTestHelpers.successJsonListResponse(_danmakus);
  }

  /// 构建空响应
  http.Response buildEmpty() {
    return ApiTestHelpers.successJsonListResponse([]);
  }

  /// 清空构建器
  DanmakuApiResponseBuilder clear() {
    _danmakus.clear();
    return this;
  }
}

/// 弹幕发送 API 响应构建器
///
/// 用于构建弹幕发送响应
class DanmakuSendResponseBuilder {
  bool _success = true;
  String? _danmakuId;
  String? _error;

  /// 设置成功状态
  DanmakuSendResponseBuilder success({String? danmakuId}) {
    _success = true;
    _danmakuId =
        danmakuId ?? 'mock_danmaku_${DateTime.now().millisecondsSinceEpoch}';
    _error = null;
    return this;
  }

  /// 设置失败状态
  DanmakuSendResponseBuilder failure(String error) {
    _success = false;
    _error = error;
    _danmakuId = null;
    return this;
  }

  /// 构建 HTTP 响应
  http.Response build({int statusCode = 200}) {
    if (_success) {
      return ApiTestHelpers.successJsonResponse({
        'code': 200,
        'data': {'id': _danmakuId},
      });
    } else {
      return http.Response(
        json.encode({'code': statusCode, 'message': _error}),
        statusCode,
        headers: {'content-type': 'application/json'},
      );
    }
  }
}

/// PolyvApiClient 测试扩展
///
/// 提供访问私有方法的测试接口
extension PolyvApiClientTesting on PolyvApiClient {
  /// 测试用：生成签名
  String generateSignForTest(Map<String, dynamic> params) {
    // 使用反射或复制签名逻辑
    final signParams = Map<String, dynamic>.from(params);
    signParams.remove('sign');

    final sortedKeys = signParams.keys.toList()..sort();

    final buffer = StringBuffer();
    for (final key in sortedKeys) {
      buffer.write(signParams[key].toString());
    }
    buffer.write(secretKey);

    final bytes = utf8.encode(buffer.toString());
    final digest = sha1.convert(bytes);

    return digest.toString().toUpperCase();
  }

  /// 测试用：编码参数
  String encodeParamsForTest(Map<String, dynamic> params) {
    return params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
        )
        .join('&');
  }
}

/// 测试辅助函数：验证签名的正确性
void verifySignature(
  String expectedSign,
  Map<String, dynamic> params,
  String secretKey,
) {
  final signParams = Map<String, dynamic>.from(params);
  signParams.remove('sign');

  final sortedKeys = signParams.keys.toList()..sort();

  final buffer = StringBuffer();
  for (final key in sortedKeys) {
    buffer.write(signParams[key].toString());
  }
  buffer.write(secretKey);

  final bytes = utf8.encode(buffer.toString());
  final digest = sha1.convert(bytes);
  final calculatedSign = digest.toString().toUpperCase();

  expect(
    calculatedSign,
    expectedSign,
    reason:
        'Signature mismatch. Expected: $expectedSign, Calculated: $calculatedSign',
  );
}
