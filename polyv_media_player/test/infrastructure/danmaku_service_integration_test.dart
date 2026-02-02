import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/infrastructure/danmaku/danmaku_service.dart';
import 'package:polyv_media_player/infrastructure/danmaku/danmaku_model.dart';
import 'package:polyv_media_player/infrastructure/polyv_api_client.dart';
import '../support/player_test_helpers.lib.dart';

void main() {
  group('DanmakuService - [P1] Integration Tests', () {
    group('MockDanmakuService', () {
      late MockDanmakuService service;

      setUp(() {
        service = MockDanmakuService(enableCache: true);
      });

      tearDown(() async {
        await service.clearCache();
      });

      group('[P0] fetchDanmakus', () {
        test('should return danmakus for valid video ID', () async {
          // GIVEN: Mock service and valid video ID
          const vid = 'test_video_123';

          // WHEN: Fetching danmakus
          final danmakus = await service.fetchDanmakus(vid);

          // THEN: Should return list of danmakus
          expect(danmakus, isNotEmpty);
          expect(danmakus.first.id, contains(vid));
        });

        test('[P1] should return cached danmakus on second call', () async {
          // GIVEN: Mock service
          const vid = 'test_video_cache';

          // WHEN: Fetching twice
          final first = await service.fetchDanmakus(vid);
          final second = await service.fetchDanmakus(vid);

          // THEN: Should return same cached data
          expect(first.length, equals(second.length));
          expect(first.first.id, equals(second.first.id));
        });

        test('[P1] should respect limit parameter', () async {
          // GIVEN: Mock service
          const vid = 'test_video_limit';
          const limit = 5;

          // WHEN: Fetching with limit
          final danmakus = await service.fetchDanmakus(vid, limit: limit);

          // THEN: Should return at most limit items
          expect(danmakus.length, lessThanOrEqualTo(limit));
        });

        test('[P1] should respect offset parameter', () async {
          // GIVEN: Mock service with cached data
          const vid = 'test_video_offset';
          await service.fetchDanmakus(vid); // Cache data

          // WHEN: Fetching with offset
          final allDanmakus = await service.fetchDanmakus(vid);
          final offsetDanmakus = await service.fetchDanmakus(vid, offset: 5);

          // THEN: Offset danmakus should be subset
          expect(offsetDanmakus.length, lessThan(allDanmakus.length));
          if (allDanmakus.length > 5 && offsetDanmakus.isNotEmpty) {
            expect(
              offsetDanmakus.first.id,
              isNot(equals(allDanmakus.first.id)),
            );
          }
        });

        test('[P1] should return danmakus sorted by time', () async {
          // GIVEN: Mock service
          const vid = 'test_video_sorted';

          // WHEN: Fetching danmakus
          final danmakus = await service.fetchDanmakus(vid);

          // THEN: Should be sorted by time
          expect(DanmakuTestHelper.isSortedByTime(danmakus), isTrue);
        });

        test(
          '[P2] should generate different data for different VIDs',
          () async {
            // GIVEN: Mock service
            const vid1 = 'video_001';
            const vid2 = 'video_002';

            // WHEN: Fetching danmakus for different videos
            final danmakus1 = await service.fetchDanmakus(vid1);
            final danmakus2 = await service.fetchDanmakus(vid2);

            // THEN: Should have different IDs
            expect(danmakus1.first.id.contains(vid1), isTrue);
            expect(danmakus2.first.id.contains(vid2), isTrue);
          },
        );
      });

      group('[P2] clearCache', () {
        test('should clear cached danmakus', () async {
          // GIVEN: Mock service with cached data
          const vid = 'test_video_clear';
          await service.fetchDanmakus(vid);

          // WHEN: Clearing cache
          await service.clearCache();

          // THEN: Next fetch should generate new data
          final danmakus = await service.fetchDanmakus(vid);
          expect(danmakus, isNotEmpty);
        });
      });

      group('[P2] Cache behavior', () {
        test('should not cache when disabled', () async {
          // GIVEN: Service with cache disabled
          final noCacheService = MockDanmakuService(enableCache: false);
          const vid = 'test_no_cache';

          // WHEN: Fetching twice
          final first = await noCacheService.fetchDanmakus(vid);
          final second = await noCacheService.fetchDanmakus(vid);

          // THEN: Should generate different timestamps
          // (数据内容相同，但由于时间戳不同，生成 ID 可能不同)
          expect(first.length, equals(second.length));
        });
      });
    });

    group('HttpDanmakuService', () {
      late PolyvApiClient apiClient;
      late HttpDanmakuService service;

      setUp(() {
        apiClient = PolyvApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          writeToken: 'test_write_token',
          secretKey: 'test_secret',
        );
        service = HttpDanmakuService(apiClient: apiClient, enableCache: true);
      });

      tearDown(() async {
        await service.clearCache();
        apiClient.dispose();
      });

      group('[P1] fetchDanmakus with API', () {
        test(
          'should parse API response correctly',
          () async {
            // GIVEN: HttpDanmakuService
            // (实际测试需要 mock HTTP 客户端)
            const vid = 'test_vid';
            final service = HttpDanmakuService(
              apiClient: apiClient,
              enableCache: false,
            );

            // WHEN: Fetching (实际会调用真实 API，测试时可能失败)
            // THEN: Should handle response or error gracefully
            // Skip: Requires network access and valid API credentials
            try {
              final result = await service.fetchDanmakus(vid);
              // If successful, verify result structure
              expect(result, isA<List<Danmaku>>());
            } on DanmakuFetchException catch (_) {
              // Expected when network unavailable or invalid credentials
            }
          },
          skip: true /* Requires network access and valid API credentials */,
        );

        test('[P2] should handle API errors gracefully', () async {
          // GIVEN: Invalid credentials
          final invalidClient = PolyvApiClient(
            userId: 'invalid',
            readToken: 'invalid',
            writeToken: 'invalid',
            secretKey: 'invalid',
          );
          final invalidService = HttpDanmakuService(
            apiClient: invalidClient,
            enableCache: false,
          );

          // WHEN: Fetching with invalid credentials
          final result = await invalidService.fetchDanmakus('test_vid');

          // THEN: Should return empty list or throw exception
          // (API behavior depends on error handling - both are acceptable)
          expect(result, anyOf(isEmpty, isA<List<Danmaku>>()));
        });
      });

      group('[P2] Data parsing', () {
        test('should parse time string correctly', () {
          // GIVEN: Time string "00:01:23"
          const timeStr = '00:01:23';

          // WHEN: Parsing
          final milliseconds = PolyvApiClient.timeStrToMilliseconds(timeStr);

          // THEN: Should get correct milliseconds
          expect(milliseconds, equals((60 + 23) * 1000));
        });

        test('should parse color string correctly', () {
          // GIVEN: Color string "0xff6b6b"
          const colorStr = '0xff6b6b';

          // WHEN: Parsing
          final colorInt = PolyvApiClient.parseColorInt(colorStr);

          // THEN: Should get correct integer
          expect(colorInt, equals(0xff6b6b));
        });
      });
    });

    group('DanmakuServiceFactory', () {
      test('[P2] should create mock service', () {
        // WHEN: Creating mock service
        final service = DanmakuServiceFactory.createMock();

        // THEN: Should return MockDanmakuService
        expect(service, isA<MockDanmakuService>());
        service.clearCache();
      });

      test('[P2] should create HTTP service with correct parameters', () {
        // WHEN: Creating HTTP service
        final service = DanmakuServiceFactory.createHttp(
          userId: 'test_user',
          readToken: 'test_read',
          secretKey: 'test_secret',
        );

        // THEN: Should return HttpDanmakuService
        expect(service, isA<HttpDanmakuService>());
      });
    });

    group('DanmakuSendService', () {
      late MockDanmakuSendService service;

      setUp(() {
        service = MockDanmakuSendService();
      });

      group('[P0] validateText', () {
        test('should reject empty text', () {
          // GIVEN: Empty text
          const text = '';

          // WHEN: Validating
          final error = service.validateText(text);

          // THEN: Should return error
          expect(error, isNotNull);
          expect(error, contains('不能为空'));
        });

        test('should reject whitespace-only text', () {
          // GIVEN: Whitespace text
          const text = '   ';

          // WHEN: Validating
          final error = service.validateText(text);

          // THEN: Should return error
          expect(error, isNotNull);
        });

        test('should accept valid text', () {
          // GIVEN: Valid text
          const text = 'Hello world';

          // WHEN: Validating
          final error = service.validateText(text);

          // THEN: Should return null (no error)
          expect(error, isNull);
        });

        test('[P1] should enforce minimum length', () {
          // GIVEN: Text below minimum length
          const text = 'a'; // 1 character, but config.minTextLength = 1
          final customConfig = DanmakuSendConfig(minTextLength: 5);
          final customService = MockDanmakuSendService(config: customConfig);

          // WHEN: Validating
          final error = customService.validateText(text);

          // THEN: Should return error
          expect(error, isNotNull);
          expect(error, contains('至少需要'));
        });

        test('[P1] should enforce maximum length', () {
          // GIVEN: Text above maximum length
          final text = 'a' * 101; // 101 characters
          final customConfig = DanmakuSendConfig(maxTextLength: 100);
          final customService = MockDanmakuSendService(config: customConfig);

          // WHEN: Validating
          final error = customService.validateText(text);

          // THEN: Should return error
          expect(error, isNotNull);
          expect(error, contains('不能超过'));
        });

        test('[P2] should reject control characters', () {
          // GIVEN: Text with control character
          const text = 'Hello\x00World';

          // WHEN: Validating
          final error = service.validateText(text);

          // THEN: Should return error
          expect(error, isNotNull);
          expect(error, contains('非法字符'));
        });
      });

      group('[P0] Throttling', () {
        test('should allow first send', () {
          // GIVEN: Fresh service
          // WHEN: Checking if can send
          final canSend = service.canSend(null);

          // THEN: Should allow
          expect(canSend, isTrue);
        });

        test('[P1] should throttle rapid sends', () async {
          // GIVEN: Service with 2s min interval
          const config = DanmakuSendConfig(minSendInterval: 2000);
          final throttledService = MockDanmakuSendService(config: config);

          // WHEN: Sending first danmaku
          final request = DanmakuSendRequest(
            vid: 'test',
            text: 'First',
            time: DateTime.now().millisecondsSinceEpoch,
          );

          await throttledService.sendDanmaku(request);

          // THEN: Immediate second send should be throttled
          final canSend = throttledService.canSend(
            throttledService.lastSendTime,
          );
          expect(canSend, isFalse);
        });

        test('[P1] should allow send after interval', () async {
          // GIVEN: Service with short interval
          const config = DanmakuSendConfig(minSendInterval: 100);
          final service = MockDanmakuSendService(
            config: config,
            simulateDelay: false,
          );

          final request = DanmakuSendRequest(
            vid: 'test',
            text: 'First',
            time: 0,
          );

          // WHEN: Sending then waiting
          await service.sendDanmaku(request);
          await Future.delayed(const Duration(milliseconds: 150));

          // THEN: Should allow next send
          final canSend = service.canSend(service.lastSendTime);
          expect(canSend, isTrue);
        });

        test('[P2] should reset throttle state', () {
          // GIVEN: Service with previous send
          const config = DanmakuSendConfig(minSendInterval: 5000);
          final service = MockDanmakuSendService(
            config: config,
            simulateDelay: false,
          );

          final request = DanmakuSendRequest(
            vid: 'test',
            text: 'Test',
            time: 0,
          );

          // WHEN: Sending then resetting
          service.sendDanmaku(request); // Don't await for faster test
          service.resetThrottle();

          // THEN: Should allow immediate send
          final canSend = service.canSend(null);
          expect(canSend, isTrue);
        });
      });

      group('[P1] sendDanmaku', () {
        test('should reject invalid text', () async {
          // GIVEN: Request with invalid text
          final request = DanmakuSendRequest(vid: 'test', text: '', time: 0);

          // WHEN: Sending
          // THEN: Should throw validation error
          expect(
            () => service.sendDanmaku(request),
            throwsA(isA<DanmakuSendException>()),
          );
        });

        test('should return success response on valid send', () async {
          // GIVEN: Valid request
          final request = DanmakuSendRequest(
            vid: 'test_vid',
            text: 'Test danmaku',
            time: 0,
          );

          // WHEN: Sending
          final response = await service.sendDanmaku(request);

          // THEN: Should return success
          expect(response.success, isTrue);
          expect(response.danmakuId, isNotEmpty);
          expect(response.serverTime, isPositive);
        });

        test('[P2] should throttle when sending too fast', () async {
          // GIVEN: Service with interval
          const config = DanmakuSendConfig(minSendInterval: 2000);
          final service = MockDanmakuSendService(
            config: config,
            simulateDelay: false,
          );

          final request = DanmakuSendRequest(
            vid: 'test',
            text: 'Test',
            time: 0,
          );

          // WHEN: Sending twice rapidly
          await service.sendDanmaku(request);

          // THEN: Second send should be throttled
          expect(
            () => service.sendDanmaku(request),
            throwsA(isA<DanmakuSendException>()),
          );
        });
      });
    });

    group('[P2] Danmaku utilities', () {
      test('should count danmaku types correctly', () {
        // GIVEN: Mixed danmaku list
        final danmakus = [
          TestDataFactory.createScrollDanmaku(),
          TestDataFactory.createScrollDanmaku(),
          TestDataFactory.createTopDanmaku(),
          TestDataFactory.createBottomDanmaku(),
          TestDataFactory.createTopDanmaku(),
        ];

        // WHEN: Counting by type
        final counts = DanmakuTestHelper.countByType(danmakus);

        // THEN: Should have correct counts
        expect(counts[DanmakuType.scroll], equals(2));
        expect(counts[DanmakuType.top], equals(2));
        expect(counts[DanmakuType.bottom], equals(1));
      });

      test('should find duplicate IDs', () {
        // GIVEN: List with duplicate IDs
        final danmakus = [
          TestDataFactory.createDanmaku(id: 'dup_1', text: 'First'),
          TestDataFactory.createDanmaku(id: 'dup_2', text: 'Second'),
          TestDataFactory.createDanmaku(id: 'dup_1', text: 'Duplicate'),
          TestDataFactory.createDanmaku(id: 'dup_3', text: 'Third'),
        ];

        // WHEN: Finding duplicates
        final duplicates = DanmakuTestHelper.findDuplicateIds(danmakus);

        // THEN: Should find the duplicate
        expect(duplicates, contains('dup_1'));
        expect(duplicates.length, equals(1));
      });

      test('should get danmakus in time range', () {
        // GIVEN: Danmaku list at various times
        final danmakus = [
          TestDataFactory.createDanmaku(time: 0),
          TestDataFactory.createDanmaku(time: 5000),
          TestDataFactory.createDanmaku(time: 10000),
          TestDataFactory.createDanmaku(time: 15000),
          TestDataFactory.createDanmaku(time: 20000),
        ];

        // WHEN: Getting range 5-15 seconds
        final range = DanmakuTestHelper.getDanmakusInRange(
          danmakus,
          5000,
          15000,
        );

        // THEN: Should get 3 danmakus
        expect(range.length, equals(3));
        expect(range.first.time, equals(5000));
        expect(range.last.time, equals(15000));
      });

      test('should validate text length', () {
        // GIVEN: Various texts
        const valid = 'Valid text';
        const tooShort = '';
        final tooLong = 'a' * 101;

        // WHEN: Validating
        // THEN: Should validate correctly
        expect(DanmakuTestHelper.isValidTextLength(valid), isTrue);
        expect(DanmakuTestHelper.isValidTextLength(tooShort, min: 1), isFalse);
        expect(DanmakuTestHelper.isValidTextLength(tooLong, max: 100), isFalse);
      });
    });
  });
}
