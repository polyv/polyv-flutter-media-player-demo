import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/infrastructure/danmaku/danmaku_model.dart';
import 'package:polyv_media_player/infrastructure/danmaku/danmaku_service.dart';

void main() {
  group('MockDanmakuSendService Unit Tests', () {
    late MockDanmakuSendService service;

    setUp(() {
      service = MockDanmakuSendService(
        config: DanmakuSendConfig.defaultConfig(),
        simulateDelay: false, // 加快测试速度
        simulateRandomFailure: false, // 确保测试确定性
      );
    });

    group('[P1] Text Validation', () {
      test('[P1] validateText returns null for valid text', () {
        // GIVEN: A MockDanmakuSendService with default config
        // WHEN: Validating valid text inputs
        expect(service.validateText('正常弹幕'), isNull);
        expect(service.validateText('a'), isNull); // 最小长度
        expect(service.validateText('a' * 100), isNull); // 最大长度
        expect(service.validateText('中文English123!@#'), isNull);
      });

      test('[P1] validateText returns error for empty text', () {
        // GIVEN: A MockDanmakuSendService
        // WHEN: Validating empty inputs
        expect(service.validateText(''), '弹幕内容不能为空');
        expect(service.validateText('   '), '弹幕内容不能为空');
        expect(service.validateText('  \n  '), '弹幕内容不能为空');
      });

      test('[P1] validateText returns error for text that is too short', () {
        // GIVEN: A MockDanmakuSendService with min length of 1
        // WHEN: Validating empty text
        expect(service.validateText(''), '弹幕内容不能为空');
      });

      test('[P1] validateText returns error for text that is too long', () {
        // GIVEN: A MockDanmakuSendService with max length of 100
        // WHEN: Validating text exceeding max length
        final longText = 'a' * 101;
        expect(service.validateText(longText), '弹幕内容不能超过 100 个字符');
      });

      test(
        '[P1] validateText returns error for text with illegal characters',
        () {
          // GIVEN: A MockDanmakuSendService
          // WHEN: Validating text with control characters (except LF and CR)
          expect(service.validateText('正常\x00弹幕'), '弹幕内容包含非法字符');
          expect(service.validateText('正常\x01弹幕'), '弹幕内容包含非法字符');
          expect(service.validateText('正常\x1F弹幕'), '弹幕内容包含非法字符');
        },
      );

      test('[P2] validateText allows newline and carriage return', () {
        // GIVEN: A MockDanmakuSendService
        // WHEN: Validating text with LF and CR
        expect(service.validateText('第一行\n第二行'), isNull);
        expect(service.validateText('第一行\r第二行'), isNull);
      });
    });

    group('[P1] Throttling Logic', () {
      test('[P1] canSend returns true when no previous send', () {
        // GIVEN: A service with no previous sends
        // WHEN: Checking if can send
        // THEN: Should return true
        expect(service.canSend(null), isTrue);
      });

      test('[P1] canSend returns false when within throttle period', () {
        // GIVEN: A service with a recent send time
        final now = DateTime.now().millisecondsSinceEpoch;
        final recentTime = now - 1000; // 1 second ago (within 2s throttle)

        // WHEN: Checking if can send
        // THEN: Should return false
        expect(service.canSend(recentTime), isFalse);
      });

      test('[P1] canSend returns true when throttle period has elapsed', () {
        // GIVEN: A service with an old send time
        final now = DateTime.now().millisecondsSinceEpoch;
        final oldTime = now - 2500; // 2.5 seconds ago (past 2s throttle)

        // WHEN: Checking if can send
        // THEN: Should return true
        expect(service.canSend(oldTime), isTrue);
      });

      test('[P1] canSend returns true at exact throttle boundary', () {
        // GIVEN: A service with send time at exact throttle boundary
        final now = DateTime.now().millisecondsSinceEpoch;
        final boundaryTime = now - 2000; // Exactly 2 seconds ago

        // WHEN: Checking if can send
        // THEN: Should return true (boundary is inclusive)
        expect(service.canSend(boundaryTime), isTrue);
      });

      test('[P1] minSendInterval returns config value', () {
        // GIVEN: A service with default config (2s interval)
        // WHEN: Getting min send interval
        // THEN: Should return 2000ms
        expect(service.minSendInterval, 2000);
      });

      test('[P1] resetThrottle clears last send time', () {
        // GIVEN: A service with a last send time
        // WHEN: Resetting throttle
        service.resetThrottle();

        // THEN: Can send should return true (last send time is cleared)
        expect(service.canSend(null), isTrue);
      });
    });

    group('[P1] Send Danmaku - Success Path', () {
      test(
        '[P1] sendDanmaku returns success response for valid request',
        () async {
          // GIVEN: A valid danmaku send request
          final request = DanmakuSendRequest(
            vid: 'test_vid',
            text: '测试弹幕',
            time: 5000,
          );

          // WHEN: Sending danmaku
          final response = await service.sendDanmaku(request);

          // THEN: Should return success response
          expect(response.success, isTrue);
          expect(response.danmakuId, isNotEmpty);
          expect(response.danmakuId, startsWith('mock_test_vid_'));
          expect(response.error, isNull);
        },
      );

      test('[P1] sendDanmaku updates last send time on success', () async {
        // GIVEN: A service and valid request
        final request = DanmakuSendRequest(
          vid: 'test_vid',
          text: '测试弹幕',
          time: 5000,
        );

        // WHEN: Sending danmaku
        await service.sendDanmaku(request);

        // THEN: Last send time should be set
        expect(service.lastSendTime, isNotNull);
        final now = DateTime.now().millisecondsSinceEpoch;
        expect(now - service.lastSendTime!, lessThan(1000)); // Within 1 second
      });

      test('[P1] sendDanmaku includes server time in response', () async {
        // GIVEN: A valid danmaku send request
        final request = DanmakuSendRequest(
          vid: 'test_vid',
          text: '测试弹幕',
          time: 5000,
        );

        // WHEN: Sending danmaku
        final before = DateTime.now().millisecondsSinceEpoch;
        final response = await service.sendDanmaku(request);
        final after = DateTime.now().millisecondsSinceEpoch;

        // THEN: Server time should be current time
        expect(response.serverTime, greaterThanOrEqualTo(before));
        expect(response.serverTime, lessThanOrEqualTo(after));
      });

      test('[P1] sendDanmaku increments danmaku counter', () async {
        // GIVEN: A service
        final request1 = DanmakuSendRequest(
          vid: 'test_vid',
          text: '弹幕1',
          time: 5000,
        );
        final request2 = DanmakuSendRequest(
          vid: 'test_vid',
          text: '弹幕2',
          time: 6000,
        );

        // WHEN: Sending multiple danmakus (with delay to avoid throttle)
        final response1 = await service.sendDanmaku(request1);
        // Reset throttle to allow second send immediately in test
        service.resetThrottle();
        final response2 = await service.sendDanmaku(request2);

        // THEN: Danmaku IDs should have different counter values
        expect(response1.danmakuId, isNot(equals(response2.danmakuId)));
      });
    });

    group('[P1] Send Danmaku - Validation Errors', () {
      test('[P1] sendDanmaku throws exception for empty text', () async {
        // GIVEN: A request with empty text
        final request = DanmakuSendRequest(
          vid: 'test_vid',
          text: '',
          time: 5000,
        );

        // WHEN: Sending danmaku
        // THEN: Should throw validation exception
        expect(
          () => service.sendDanmaku(request),
          throwsA(
            isA<DanmakuSendException>()
                .having((e) => e.type, 'type', DanmakuSendErrorType.validation)
                .having((e) => e.message, 'message', '弹幕内容不能为空'),
          ),
        );
      });

      test(
        '[P1] sendDanmaku throws exception for text that is too long',
        () async {
          // GIVEN: A request with text exceeding max length
          final request = DanmakuSendRequest(
            vid: 'test_vid',
            text: 'a' * 101,
            time: 5000,
          );

          // WHEN: Sending danmaku
          // THEN: Should throw validation exception
          expect(
            () => service.sendDanmaku(request),
            throwsA(
              isA<DanmakuSendException>()
                  .having(
                    (e) => e.type,
                    'type',
                    DanmakuSendErrorType.validation,
                  )
                  .having((e) => e.message, 'message', contains('不能超过')),
            ),
          );
        },
      );

      test('[P1] sendDanmaku trims whitespace before validation', () async {
        // GIVEN: A request with whitespace-only text
        final request = DanmakuSendRequest(
          vid: 'test_vid',
          text: '   ',
          time: 5000,
        );

        // WHEN: Sending danmaku
        // THEN: Should throw validation exception (whitespace trimmed)
        expect(
          () => service.sendDanmaku(request),
          throwsA(
            isA<DanmakuSendException>().having(
              (e) => e.type,
              'type',
              DanmakuSendErrorType.validation,
            ),
          ),
        );
      });
    });

    group('[P1] Send Danmaku - Throttling', () {
      test('[P1] sendDanmaku throws exception when throttled', () async {
        // GIVEN: A service with a recent successful send
        final request1 = DanmakuSendRequest(
          vid: 'test_vid',
          text: '弹幕1',
          time: 5000,
        );
        await service.sendDanmaku(request1);

        final request2 = DanmakuSendRequest(
          vid: 'test_vid',
          text: '弹幕2',
          time: 6000,
        );

        // WHEN: Sending another danmaku immediately
        // THEN: Should throw throttled exception
        expect(
          () => service.sendDanmaku(request2),
          throwsA(
            isA<DanmakuSendException>()
                .having((e) => e.type, 'type', DanmakuSendErrorType.throttled)
                .having((e) => e.message, 'message', contains('秒后再试')),
          ),
        );
      });

      test('[P1] sendDanmaku calculates remaining time correctly', () async {
        // GIVEN: A service with a recent send
        final request1 = DanmakuSendRequest(
          vid: 'test_vid',
          text: '弹幕1',
          time: 5000,
        );
        await service.sendDanmaku(request1);

        final request2 = DanmakuSendRequest(
          vid: 'test_vid',
          text: '弹幕2',
          time: 6000,
        );

        // WHEN: Attempting to send again
        try {
          await service.sendDanmaku(request2);
          fail('Should have thrown exception');
        } on DanmakuSendException catch (e) {
          // THEN: Error message should indicate remaining time (1-2 seconds)
          expect(e.message, contains('秒'));
        }
      });
    });

    group('[P2] Custom Configuration', () {
      test('[P2] accepts custom minTextLength', () {
        // GIVEN: Custom config with min length 5
        final customConfig = DanmakuSendConfig(
          minTextLength: 5,
          maxTextLength: 100,
          minSendInterval: 2000,
        );
        final customService = MockDanmakuSendService(config: customConfig);

        // WHEN: Validating text shorter than min length
        // THEN: Should return error
        expect(customService.validateText('abcd'), contains('5'));
      });

      test('[P2] accepts custom maxTextLength', () {
        // GIVEN: Custom config with max length 50
        final customConfig = DanmakuSendConfig(
          minTextLength: 1,
          maxTextLength: 50,
          minSendInterval: 2000,
        );
        final customService = MockDanmakuSendService(config: customConfig);

        // WHEN: Validating text longer than max length
        // THEN: Should return error
        expect(customService.validateText('a' * 51), contains('50'));
      });

      test('[P2] accepts custom minSendInterval', () {
        // GIVEN: Custom config with 1 second interval
        final customConfig = DanmakuSendConfig(
          minTextLength: 1,
          maxTextLength: 100,
          minSendInterval: 1000,
        );
        final customService = MockDanmakuSendService(config: customConfig);

        // WHEN: Getting min send interval
        // THEN: Should return custom value
        expect(customService.minSendInterval, 1000);
      });
    });

    group('[P3] Edge Cases', () {
      test('[P3] generate unique danmaku IDs for same vid', () async {
        // GIVEN: Same vid but different sends
        final request = DanmakuSendRequest(
          vid: 'same_vid',
          text: '弹幕',
          time: 5000,
        );

        // WHEN: Sending multiple times (resetting throttle between)
        final ids = <String>{};
        for (int i = 0; i < 10; i++) {
          service.resetThrottle();
          final response = await service.sendDanmaku(request);
          ids.add(response.danmakuId!);
        }

        // THEN: All IDs should be unique
        expect(ids.length, 10);
      });

      test('[P3] handles very long video IDs', () async {
        // GIVEN: Request with very long vid
        final longVid = 'a' * 1000;
        final request = DanmakuSendRequest(
          vid: longVid,
          text: '弹幕',
          time: 5000,
        );

        // WHEN: Sending danmaku
        final response = await service.sendDanmaku(request);

        // THEN: Should handle gracefully
        expect(response.success, isTrue);
        expect(response.danmakuId, contains(longVid));
      });
    });
  });

  group('DanmakuSendConfig Unit Tests', () {
    test('[P1] defaultConfig creates valid configuration', () {
      // WHEN: Creating default config
      final config = DanmakuSendConfig.defaultConfig();

      // THEN: Should have expected values
      expect(config.minTextLength, 1);
      expect(config.maxTextLength, 100);
      expect(config.minSendInterval, 2000);
      expect(config.allowedColors, isNotEmpty);
    });

    test('[P1] defaultConfig includes expected colors', () {
      // WHEN: Creating default config
      final config = DanmakuSendConfig.defaultConfig();

      // THEN: Should have 8 colors
      expect(config.allowedColors.length, 8);
      expect(config.allowedColors, contains('#ffffff'));
      expect(config.allowedColors, contains('#fe0302'));
      expect(config.allowedColors, contains('#cc0273'));
    });

    test('[P2] isColorAllowed returns true when no color restriction', () {
      // GIVEN: Config with empty allowed colors
      final config = DanmakuSendConfig(
        minTextLength: 1,
        maxTextLength: 100,
        minSendInterval: 2000,
        allowedColors: const [],
      );

      // WHEN: Checking if any color is allowed
      // THEN: Should return true for all colors
      expect(config.isColorAllowed('#ffffff'), isTrue);
      expect(config.isColorAllowed('#000000'), isTrue);
      expect(config.isColorAllowed('#ff0000'), isTrue);
    });

    test('[P2] isColorAllowed validates against allowed list', () {
      // GIVEN: Config with restricted colors
      final config = DanmakuSendConfig(
        minTextLength: 1,
        maxTextLength: 100,
        minSendInterval: 2000,
        allowedColors: const ['#ffffff', '#ff0000'],
      );

      // WHEN: Checking if colors are allowed
      // THEN: Should only allow listed colors
      expect(config.isColorAllowed('#ffffff'), isTrue);
      expect(config.isColorAllowed('#FFFFFF'), isTrue); // Case insensitive
      expect(config.isColorAllowed('#ff0000'), isTrue);
      expect(config.isColorAllowed('#00ff00'), isFalse);
    });

    test('[P2] constructor creates custom configuration', () {
      // WHEN: Creating custom config
      final config = DanmakuSendConfig(
        minTextLength: 5,
        maxTextLength: 50,
        minSendInterval: 1000,
        allowedColors: const ['#000000', '#ffffff'],
      );

      // THEN: Should have custom values
      expect(config.minTextLength, 5);
      expect(config.maxTextLength, 50);
      expect(config.minSendInterval, 1000);
      expect(config.allowedColors.length, 2);
    });
  });

  group('DanmakuSendServiceFactory Tests', () {
    test('[P1] createMock returns MockDanmakuSendService', () {
      // WHEN: Creating mock send service
      final service = DanmakuSendServiceFactory.createMock();

      // THEN: Should return MockDanmakuSendService
      expect(service, isA<MockDanmakuSendService>());
      expect(service.config.minTextLength, greaterThan(0));
    });

    test('[P1] createMock accepts custom config', () {
      // GIVEN: Custom config
      final customConfig = DanmakuSendConfig(
        minTextLength: 10,
        maxTextLength: 200,
        minSendInterval: 5000,
      );

      // WHEN: Creating service with custom config
      final service = DanmakuSendServiceFactory.createMock(
        config: customConfig,
      );

      // THEN: Should use custom config
      expect(service.config.minTextLength, 10);
      expect(service.config.maxTextLength, 200);
      expect(service.config.minSendInterval, 5000);
    });

    test('[P1] createHttp returns HttpDanmakuSendService', () {
      // WHEN: Creating HTTP send service
      final service = DanmakuSendServiceFactory.createHttp(
        userId: 'test_user',
        writeToken: 'test_write_token',
        secretKey: 'test_secret',
      );

      // THEN: Should return HttpDanmakuSendService
      expect(service, isA<HttpDanmakuSendService>());
      expect(service.minSendInterval, 2000); // Default config
    });
  });
}
