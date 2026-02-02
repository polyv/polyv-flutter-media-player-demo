import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 测试用的模拟方法通道
///
/// 用于测试平台通道相关功能，避免真实调用原生代码
class MockMethodChannel {
  final String name;
  final Map<String, dynamic> _mockResults = {};
  final List<MethodCall> _receivedCalls = [];

  MockMethodChannel(this.name);

  /// 设置模拟返回值
  void mockResult(String method, dynamic result) {
    _mockResults[method] = result;
  }

  /// 设置模拟异常
  void mockError(String method, PlatformException error) {
    _mockResults[method] = error;
  }

  /// 获取接收到的方法调用
  List<MethodCall> get receivedCalls => List.unmodifiable(_receivedCalls);

  /// 获取指定方法的所有调用
  List<MethodCall> getCallsForMethod(String method) {
    return _receivedCalls.where((call) => call.method == method).toList();
  }

  /// 清除所有调用记录
  void clearCalls() {
    _receivedCalls.clear();
  }

  /// 处理方法调用（测试中使用）
  Future<dynamic> handleCall(MethodCall call) async {
    _receivedCalls.add(call);

    final result = _mockResults[call.method];
    if (result == null) {
      throw MissingMockException(
        'No mock result set for method: ${call.method}. '
        'Use mockResult() to set a return value.',
      );
    }

    if (result is PlatformException) {
      throw result;
    }

    return result;
  }

  /// 验证方法是否被调用
  bool wasMethodCalled(String method) {
    return _receivedCalls.any((call) => call.method == method);
  }

  /// 验证方法被调用的次数
  int getCallCount(String method) {
    return getCallsForMethod(method).length;
  }
}

/// 测试用的模拟事件通道
///
/// 用于模拟原生层发送的事件
class MockEventChannel {
  final String name;
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  MockEventChannel(this.name);

  /// 获取事件流（用于测试）
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  /// 发送模拟事件
  void sendEvent(Map<String, dynamic> event) {
    _controller.add(event);
  }

  /// 发送模拟错误
  void sendError(dynamic error) {
    _controller.addError(error);
  }

  /// 关闭流
  void close() {
    _controller.close();
  }
}

/// 缺少模拟配置的异常
class MissingMockException extends TypeError {
  final String message;

  MissingMockException(this.message);

  @override
  String toString() => 'MissingMockException: $message';
}

/// 平台通道测试工具
///
/// 提供常用的平台通道测试辅助方法
class PlatformChannelTestUtils {
  /// 创建模拟的方法调用处理器
  static Future<dynamic> createMockHandler(
    Map<String, dynamic> mockResponses,
  ) async {
    return (MethodCall call) async {
      final response = mockResponses[call.method];
      if (response == null) {
        throw PlatformException(
          code: 'UNIMPLEMENTED',
          message: 'Method ${call.method} not mocked',
        );
      }
      if (response is Exception) {
        throw response;
      }
      return response;
    };
  }

  /// 验证方法调用参数
  static void verifyMethodCallArgs(
    MethodCall call,
    Map<String, dynamic> expectedArgs,
  ) {
    final actualArgs = call.arguments as Map<String, dynamic>?;
    expect(actualArgs, isNotNull);
    expectedArgs.forEach((key, value) {
      expect(
        actualArgs![key],
        equals(value),
        reason: 'Argument $key does not match',
      );
    });
  }
}
