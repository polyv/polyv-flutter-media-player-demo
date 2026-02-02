import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/polyv_media_player.dart';

/// PlayerException 单元测试
///
/// 测试播放器异常类的各种工厂方法和错误处理
void main() {
  group('PlayerException - 基础构造', () {
    test('[P1] 使用基础构造函数创建异常', () {
      // GIVEN: 错误码和错误信息
      const code = 'TEST_ERROR';
      const message = 'Test error message';

      // WHEN: 创建 PlayerException
      final exception = PlayerException(code: code, message: message);

      // THEN: 异常应该包含正确的错误码和信息
      expect(exception.code, code);
      expect(exception.message, message);
      expect(exception.details, isNull);
    });

    test('[P1] 异常可以包含额外详情', () {
      // GIVEN: 错误码、信息和详情
      const code = 'TEST_ERROR';
      const message = 'Test error message';
      const details = {'key': 'value'};

      // WHEN: 创建带详情的异常
      final exception = PlayerException(
        code: code,
        message: message,
        details: details,
      );

      // THEN: 异常应该包含详情
      expect(exception.details, equals(details));
    });
  });

  group('PlayerException - fromPlatformException', () {
    test('[P1] 从 PlatformException 创建异常', () {
      // GIVEN: PlatformException
      final platformException = PlatformException(
        code: 'PLATFORM_ERROR',
        message: 'Platform error message',
        details: {'detail': 'info'},
      );

      // WHEN: 转换为 PlayerException
      final playerException = PlayerException.fromPlatformException(
        platformException,
      );

      // THEN: 应该包含原始错误信息
      expect(playerException.code, 'PLATFORM_ERROR');
      expect(playerException.message, 'Platform error message');
      expect(playerException.details, {'detail': 'info'});
    });

    test('[P1] 处理空的错误码和信息', () {
      // GIVEN: 空的 PlatformException
      final platformException = PlatformException(code: '', message: '');

      // WHEN: 转换为 PlayerException
      final playerException = PlayerException.fromPlatformException(
        platformException,
      );

      // THEN: 应该使用默认值
      expect(playerException.code, 'UNKNOWN_ERROR');
      expect(playerException.message, 'An unknown error occurred');
    });

    test('[P1] 处理 null 消息', () {
      // GIVEN: 没有 message 的 PlatformException
      final platformException = PlatformException(code: 'TEST_CODE');

      // WHEN: 转换为 PlayerException
      final playerException = PlayerException.fromPlatformException(
        platformException,
      );

      // THEN: 应该使用默认消息
      expect(playerException.code, 'TEST_CODE');
      expect(playerException.message, 'An unknown error occurred');
    });
  });

  group('PlayerException - 工厂方法', () {
    test('[P1] invalidVid 创建无效 VID 异常', () {
      // GIVEN: 无效的 VID
      const invalidVid = '';

      // WHEN: 创建 invalidVid 异常
      final exception = PlayerException.invalidVid(invalidVid);

      // THEN: 应该包含正确的错误码和信息
      expect(exception.code, 'INVALID_VID');
      expect(exception.message, contains(invalidVid));
      expect(exception.message, contains('Invalid video ID'));
    });

    test('[P1] invalidVid 使用非空 VID', () {
      // GIVEN: 一个 VID
      const vid = 'invalid_vid_format';

      // WHEN: 创建 invalidVid 异常
      final exception = PlayerException.invalidVid(vid);

      // THEN: 消息应该包含该 VID
      expect(exception.message, contains(vid));
    });

    test('[P1] networkError 创建网络错误异常', () {
      // WHEN: 创建默认网络错误
      final exception = PlayerException.networkError();

      // THEN: 应该有正确的错误码和默认消息
      expect(exception.code, 'NETWORK_ERROR');
      expect(exception.message, 'Network connection failed');
    });

    test('[P1] networkError 支持自定义消息', () {
      // GIVEN: 自定义错误消息
      const customMessage = 'Connection timeout';

      // WHEN: 创建带自定义消息的网络错误
      final exception = PlayerException.networkError(customMessage);

      // THEN: 应该使用自定义消息
      expect(exception.code, 'NETWORK_ERROR');
      expect(exception.message, customMessage);
    });

    test('[P1] notInitialized 创建未初始化异常', () {
      // WHEN: 创建未初始化异常
      final exception = PlayerException.notInitialized();

      // THEN: 应该有正确的错误码和消息
      expect(exception.code, 'NOT_INITIALIZED');
      expect(exception.message, 'Player has not been initialized');
    });

    test('[P1] unsupportedOperation 创建不支持的操作异常', () {
      // GIVEN: 不支持的操作
      const operation = 'setSpeed(3.0)';

      // WHEN: 创建不支持的操作异常
      final exception = PlayerException.unsupportedOperation(operation);

      // THEN: 应该包含操作信息
      expect(exception.code, 'UNSUPPORTED_OPERATION');
      expect(exception.message, contains(operation));
      expect(exception.message, contains('Unsupported operation'));
    });
  });

  group('PlayerException - toString', () {
    test('[P2] toString 包含错误码和消息', () {
      // GIVEN: 一个异常
      const code = 'TEST_ERROR';
      const message = 'Test error';
      final exception = PlayerException(code: code, message: message);

      // WHEN: 调用 toString
      final str = exception.toString();

      // THEN: 应该包含错误码和消息
      expect(str, contains('PlayerException'));
      expect(str, contains(code));
      expect(str, contains(message));
    });

    test('[P2] toString 包含详情（如果有）', () {
      // GIVEN: 带详情的异常
      final exception = PlayerException(
        code: 'TEST_ERROR',
        message: 'Test error',
        details: {'key': 'value'},
      );

      // WHEN: 调用 toString
      final str = exception.toString();

      // THEN: 应该包含详情信息
      expect(str, contains('details'));
    });
  });

  group('PlayerException - 异常类型检查', () {
    test('[P2] 是 Exception 类型', () {
      // GIVEN: PlayerException
      final exception = PlayerException(code: 'TEST', message: 'Test');

      // THEN: 应该是 Exception 的实例
      expect(exception, isA<Exception>());
    });

    test('[P2] 可以被 throw 和 catch', () {
      // GIVEN: 一个异常
      final exception = PlayerException(code: 'TEST', message: 'Test error');

      // WHEN/THEN: 可以被捕获
      expect(() => throw exception, throwsA(isA<PlayerException>()));
    });

    test('[P2] catch 后可以访问属性', () async {
      // GIVEN: 一个异常
      final exception = PlayerException(
        code: 'TEST_CODE',
        message: 'TEST_MESSAGE',
      );

      // WHEN: 抛出并捕获异常
      try {
        throw exception;
      } on PlayerException catch (e) {
        // THEN: 可以访问异常属性
        expect(e.code, 'TEST_CODE');
        expect(e.message, 'TEST_MESSAGE');
      }
    });
  });
}
