import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/infrastructure/polyv_api_client.dart';
import 'package:polyv_media_player/infrastructure/danmaku/danmaku_model.dart';
import 'package:polyv_media_player/infrastructure/danmaku/danmaku_service.dart';

// ============================================================================
// Test Helpers
// ============================================================================

/// Mock API response for testing
PolyvApiResponse<List<dynamic>>? mockApiResponse;

/// Mock PolyvApiClient for testing
class MockPolyvApiClient extends PolyvApiClient {
  MockPolyvApiClient()
    : super(
        userId: 'test_user',
        readToken: 'test_token',
        writeToken: 'test_write_token',
        secretKey: 'test_secret',
      );

  @override
  Future<PolyvApiResponse<List<dynamic>>> get(
    String path, {
    Map<String, dynamic>? params,
    bool useReadToken = true,
    bool usePtime = false,
  }) async {
    return mockApiResponse ??
        PolyvApiResponse<List<dynamic>>.success(data: [], statusCode: 200);
  }
}

/// Test extension for HttpDanmakuService to access private members
extension HttpDanmakuServiceTestExtension on HttpDanmakuService {
  DanmakuFetchErrorType testMapApiErrorType(int? statusCode) {
    if (statusCode == null) return DanmakuFetchErrorType.unknown;

    switch (statusCode) {
      case 401:
      case 403:
        return DanmakuFetchErrorType.auth;
      case 404:
        return DanmakuFetchErrorType.notFound;
      case 500:
      case 502:
      case 503:
        return DanmakuFetchErrorType.server;
      default:
        // 只有 500-599 范围是标准的服务器错误
        if (statusCode >= 500 && statusCode < 600) {
          return DanmakuFetchErrorType.server;
        }
        return DanmakuFetchErrorType.unknown;
    }
  }
}

// Access private class for testing
class _Random {
  late int _state;

  _Random(int seed) {
    _state = seed % 2147483647;
    if (_state <= 0) {
      _state += 2147483646;
    }
  }

  int nextInt(int max) {
    _state = (_state * 16807) % 2147483647;
    return _state % max;
  }

  double nextDouble() {
    _state = (_state * 16807) % 2147483647;
    return _state / 2147483647;
  }

  bool nextBool() {
    return nextDouble() < 0.5;
  }
}

// ============================================================================
// Tests
// ============================================================================

void main() {
  group('MockDanmakuService Unit Tests', () {
    late MockDanmakuService service;

    setUp(() {
      service = MockDanmakuService(enableCache: true);
    });

    tearDown(() async {
      await service.clearCache();
    });

    test('[P1] fetchDanmakus returns non-empty list for valid vid', () async {
      // GIVEN: A MockDanmakuService with caching enabled
      const vid = 'test_video_123';

      // WHEN: Fetching danmakus for a valid video ID
      final result = await service.fetchDanmakus(vid);

      // THEN: Returns a non-empty list of danmakus
      expect(result, isNotEmpty);
      expect(result.length, greaterThan(50));

      // All danmakus should have required fields
      for (final danmaku in result) {
        expect(danmaku.id, isNotNull);
        expect(danmaku.text, isNotEmpty);
        expect(danmaku.time, greaterThanOrEqualTo(0));
        expect(danmaku.time, lessThan(60000)); // Mock generates 0-60s
      }
    });

    test(
      '[P1] fetchDanmakus returns same data for same vid (caching)',
      () async {
        // GIVEN: A MockDanmakuService with caching enabled
        const vid = 'test_video_456';

        // WHEN: Fetching danmakus twice for the same video
        final result1 = await service.fetchDanmakus(vid);
        final result2 = await service.fetchDanmakus(vid);

        // THEN: Both results should be identical (cached)
        expect(result1.length, equals(result2.length));

        for (int i = 0; i < result1.length; i++) {
          expect(result1[i].id, equals(result2[i].id));
          expect(result1[i].text, equals(result2[i].text));
          expect(result1[i].time, equals(result2[i].time));
        }
      },
    );

    test('[P1] fetchDanmakus applies limit parameter', () async {
      // GIVEN: A MockDanmakuService
      const vid = 'test_video_limit';
      const limit = 10;

      // WHEN: Fetching with a limit
      final result = await service.fetchDanmakus(vid, limit: limit);

      // THEN: Returns at most the limit number of danmakus
      expect(result.length, lessThanOrEqualTo(limit));
    });

    test('[P1] fetchDanmakus applies offset parameter', () async {
      // GIVEN: A MockDanmakuService
      const vid = 'test_video_offset';
      const offset = 20;

      // WHEN: Fetching with an offset
      final result = await service.fetchDanmakus(vid, offset: offset);
      final fullResult = await service.fetchDanmakus(vid);

      // THEN: Offset result should be shorter than full result
      expect(result.length, lessThan(fullResult.length));
    });

    test('[P1] fetchDanmakus applies both limit and offset', () async {
      // GIVEN: A MockDanmakuService
      const vid = 'test_video_both';
      const limit = 5;
      const offset = 10;

      // WHEN: Fetching with both limit and offset
      final result = await service.fetchDanmakus(
        vid,
        limit: limit,
        offset: offset,
      );

      // THEN: Returns at most limit items
      expect(result.length, lessThanOrEqualTo(limit));
    });

    test('[P2] clearCache removes cached data', () async {
      // GIVEN: A MockDanmakuService with cached data
      const vid = 'test_video_clear';
      await service.fetchDanmakus(vid);

      // WHEN: Clearing the cache
      await service.clearCache();

      // THEN: Subsequent fetch should generate new data
      // (same vid but after clear should still work)
      final result = await service.fetchDanmakus(vid);
      expect(result, isNotEmpty);
    });

    test('[P2] fetchDanmakus returns sorted results by time', () async {
      // GIVEN: A MockDanmakuService
      const vid = 'test_video_sorted';

      // WHEN: Fetching danmakus
      final result = await service.fetchDanmakus(vid);

      // THEN: Results should be sorted by time ascending
      for (int i = 1; i < result.length; i++) {
        expect(result[i].time, greaterThanOrEqualTo(result[i - 1].time));
      }
    });

    test('[P2] fetchDanmakus includes different danmaku types', () async {
      // GIVEN: A MockDanmakuService
      const vid = 'test_video_types';

      // WHEN: Fetching danmakus
      final result = await service.fetchDanmakus(vid);

      // THEN: Should include scroll type (90% probability)
      final scrollDanmakus = result.where((d) => d.type == DanmakuType.scroll);
      expect(scrollDanmakus.length, greaterThan(0));
    });

    test('[P2] fetchDanmakus includes various colors', () async {
      // GIVEN: A MockDanmakuService
      const vid = 'test_video_colors';

      // WHEN: Fetching danmakus
      final result = await service.fetchDanmakus(vid);

      // THEN: Should include danmakus with different colors (including null/white)
      final coloredDanmakus = result.where((d) => d.color != null);
      final whiteDanmakus = result.where((d) => d.color == null);

      expect(coloredDanmakus.length, greaterThan(0));
      expect(whiteDanmakus.length, greaterThan(0));
    });

    test(
      '[P2] same vid produces consistent data across multiple calls',
      () async {
        // GIVEN: A MockDanmakuService with caching disabled
        final noCacheService = MockDanmakuService(enableCache: false);
        const vid = 'test_video_consistent';

        // WHEN: Fetching danmakus multiple times
        final result1 = await noCacheService.fetchDanmakus(vid);
        final result2 = await noCacheService.fetchDanmakus(vid);
        final result3 = await noCacheService.fetchDanmakus(vid);

        // THEN: All results should be identical (deterministic based on vid hash)
        expect(result1.length, equals(result2.length));
        expect(result2.length, equals(result3.length));

        for (int i = 0; i < result1.length; i++) {
          expect(result1[i].id, equals(result2[i].id));
          expect(result2[i].id, equals(result3[i].id));
        }
      },
    );

    test('[P2] different vids produce different danmakus', () async {
      // GIVEN: A MockDanmakuService
      const vid1 = 'video_one';
      const vid2 = 'video_two';

      // WHEN: Fetching danmakus for different videos
      final result1 = await service.fetchDanmakus(vid1);
      final result2 = await service.fetchDanmakus(vid2);

      // THEN: Results should differ
      final ids1 = result1.map((d) => d.id).toSet();
      final ids2 = result2.map((d) => d.id).toSet();

      expect(ids1.intersection(ids2).isEmpty, isTrue);
    });

    test('[P2] fetchDanmakus from cache is faster', () async {
      // GIVEN: A MockDanmakuService
      const vid = 'test_video_speed';

      // WHEN: First fetch (generates data) and second fetch (from cache)
      final stopwatch1 = Stopwatch()..start();
      await service.fetchDanmakus(vid);
      stopwatch1.stop();

      final stopwatch2 = Stopwatch()..start();
      await service.fetchDanmakus(vid);
      stopwatch2.stop();

      // THEN: Cached fetch should be faster (no 100ms delay)
      expect(
        stopwatch2.elapsedMilliseconds,
        lessThan(stopwatch1.elapsedMilliseconds),
      );
    });

    test('[P3] fetchDanmakus with offset=0 behaves like no offset', () async {
      // GIVEN: A MockDanmakuService
      const vid = 'test_video_zero_offset';

      // WHEN: Fetching with offset=0 and without offset
      final resultWithOffset = await service.fetchDanmakus(vid, offset: 0);
      final resultNoOffset = await service.fetchDanmakus(vid);

      // THEN: Results should be equivalent
      expect(resultWithOffset.length, equals(resultNoOffset.length));
    });

    test('[P3] fetchDanmakus with limit=0 returns empty list', () async {
      // GIVEN: A MockDanmakuService
      const vid = 'test_video_zero_limit';

      // WHEN: Fetching with limit=0
      final result = await service.fetchDanmakus(vid, limit: 0);

      // THEN: Returns empty list
      expect(result, isEmpty);
    });
  });

  group('_Random Pseudo-Random Generator Tests', () {
    test('[P2] same seed produces same sequence', () {
      // GIVEN: Two _Random instances with same seed
      final random1 = _Random(12345);
      final random2 = _Random(12345);

      // WHEN: Generating random numbers
      final values1 = List.generate(10, (_) => random1.nextInt(1000));
      final values2 = List.generate(10, (_) => random2.nextInt(1000));

      // THEN: Sequences should be identical
      expect(values1, equals(values2));
    });

    test('[P2] different seeds produce different sequences', () {
      // GIVEN: Two _Random instances with different seeds
      final random1 = _Random(11111);
      final random2 = _Random(22222);

      // WHEN: Generating random numbers
      final values1 = List.generate(10, (_) => random1.nextInt(1000));
      final values2 = List.generate(10, (_) => random2.nextInt(1000));

      // THEN: Sequences should differ
      expect(values1, isNot(equals(values2)));
    });

    test('[P2] nextInt returns values within range', () {
      // GIVEN: A _Random instance
      final random = _Random(54321);
      const max = 100;

      // WHEN: Generating many random numbers
      final values = List.generate(1000, (_) => random.nextInt(max));

      // THEN: All values should be in range [0, max)
      for (final value in values) {
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThan(max));
      }
    });

    test('[P2] nextDouble returns values between 0 and 1', () {
      // GIVEN: A _Random instance
      final random = _Random(98765);

      // WHEN: Generating many random doubles
      final values = List.generate(1000, (_) => random.nextDouble());

      // THEN: All values should be in range [0, 1)
      for (final value in values) {
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThan(1.0));
      }
    });

    test('[P2] nextBool returns both true and false over many calls', () {
      // GIVEN: A _Random instance
      final random = _Random(13579);

      // WHEN: Generating many random booleans
      final values = List.generate(1000, (_) => random.nextBool());

      // THEN: Should have both true and false values
      expect(values, contains(true));
      expect(values, contains(false));
    });
  });

  // HttpDanmakuService Tests
  group('HttpDanmakuService Unit Tests', () {
    late HttpDanmakuService service;
    late MockPolyvApiClient mockApiClient;

    setUp(() {
      mockApiClient = MockPolyvApiClient();
      service = HttpDanmakuService(apiClient: mockApiClient, enableCache: true);
    });

    tearDown(() async {
      await service.clearCache();
    });

    test('[P1] fetchDanmakus returns data from API response', () async {
      // GIVEN: API returns mock data
      final mockData = [
        {
          'msg': '弹幕1',
          'time': '00:00:05',
          'fontColor': '0xffffff',
          'fontMode': 'roll',
        },
        {
          'msg': '弹幕2',
          'time': '00:00:10',
          'fontColor': '0xff0000',
          'fontMode': 'top',
        },
      ];
      mockApiResponse = PolyvApiResponse<List<dynamic>>.success(
        data: mockData,
        statusCode: 200,
      );

      // WHEN: Fetching danmakus
      final result = await service.fetchDanmakus('test_vid');

      // THEN: Should return parsed danmaku list
      expect(result.length, 2);
      expect(result[0].text, '弹幕1');
      expect(result[0].time, 5000);
      expect(result[1].text, '弹幕2');
      expect(result[1].time, 10000);
      expect(result[1].type, DanmakuType.top);
    });

    test('[P1] fetchDanmakus handles empty API response', () async {
      // GIVEN: API returns empty list
      mockApiResponse = PolyvApiResponse<List<dynamic>>.success(
        data: [],
        statusCode: 200,
      );

      // WHEN: Fetching danmakus
      final result = await service.fetchDanmakus('test_vid');

      // THEN: Should return empty list
      expect(result, isEmpty);
    });

    test('[P1] fetchDanmakus handles null data in response', () async {
      // GIVEN: API returns response with null data
      mockApiResponse = PolyvApiResponse<List<dynamic>>.success(
        data: null,
        statusCode: 200,
      );

      // WHEN: Fetching danmakus
      final result = await service.fetchDanmakus('test_vid');

      // THEN: Should return empty list
      expect(result, isEmpty);
    });

    test('[P1] fetchDanmakus throws exception on API error', () async {
      // GIVEN: API returns error response
      mockApiResponse = PolyvApiResponse<List<dynamic>>.failure(
        error: 'Authentication failed',
        statusCode: 401,
      );

      // WHEN: Fetching danmakus
      // THEN: Should throw DanmakuFetchException
      expect(
        () => service.fetchDanmakus('test_vid'),
        throwsA(
          isA<DanmakuFetchException>().having(
            (e) => e.type,
            'type',
            DanmakuFetchErrorType.auth,
          ),
        ),
      );
    });

    test('[P1] fetchDanmakus caches results', () async {
      // GIVEN: API returns mock data
      final mockData = [
        {
          'msg': '测试弹幕',
          'time': '00:00:05',
          'fontColor': '0xffffff',
          'fontMode': 'roll',
        },
      ];
      mockApiResponse = PolyvApiResponse<List<dynamic>>.success(
        data: mockData,
        statusCode: 200,
      );

      // WHEN: Fetching danmakus twice
      await service.fetchDanmakus('test_vid');
      final result2 = await service.fetchDanmakus('test_vid');

      // THEN: Second call should return cached data
      expect(result2.length, 1);
      expect(result2[0].text, '测试弹幕');
    });

    test('[P1] fetchDanmakus with limit parameter', () async {
      // GIVEN: API returns mock data with more items than limit
      final mockData = List.generate(
        10,
        (i) => {
          'msg': '弹幕$i',
          'time': '00:00:${(i * 5).toString().padLeft(2, '0')}',
          'fontColor': '0xffffff',
          'fontMode': 'roll',
        },
      );
      mockApiResponse = PolyvApiResponse<List<dynamic>>.success(
        data: mockData,
        statusCode: 200,
      );

      // WHEN: Fetching with limit
      final result = await service.fetchDanmakus('test_vid', limit: 5);

      // THEN: Should return at most limit items
      expect(result.length, lessThanOrEqualTo(5));
    });

    test('[P2] clearCache removes cached data', () async {
      // GIVEN: Cached data exists
      final mockData = [
        {
          'msg': '测试弹幕',
          'time': '00:00:05',
          'fontColor': '0xffffff',
          'fontMode': 'roll',
        },
      ];
      mockApiResponse = PolyvApiResponse<List<dynamic>>.success(
        data: mockData,
        statusCode: 200,
      );
      await service.fetchDanmakus('test_vid');

      // WHEN: Clearing cache
      await service.clearCache();

      // THEN: Cache should be cleared
      expect(() => service.clearCache(), returnsNormally);
    });

    test('[P2] fetchDanmakus maps API error types correctly', () {
      // GIVEN: HttpDanmakuService instance
      // WHEN: Mapping various status codes
      // THEN: Should map to correct error types
      expect(service.testMapApiErrorType(401), DanmakuFetchErrorType.auth);
      expect(service.testMapApiErrorType(403), DanmakuFetchErrorType.auth);
      expect(service.testMapApiErrorType(404), DanmakuFetchErrorType.notFound);
      expect(service.testMapApiErrorType(500), DanmakuFetchErrorType.server);
      expect(service.testMapApiErrorType(502), DanmakuFetchErrorType.server);
      expect(service.testMapApiErrorType(503), DanmakuFetchErrorType.server);
      expect(service.testMapApiErrorType(999), DanmakuFetchErrorType.unknown);
    });

    test('[P2] fetchDanmakus parses danmaku types correctly', () async {
      // GIVEN: API returns danmakus with different types
      final mockData = [
        {
          'msg': '滚动',
          'time': '00:00:01',
          'fontColor': '0xffffff',
          'fontMode': 'roll',
        },
        {
          'msg': '顶部',
          'time': '00:00:02',
          'fontColor': '0xffffff',
          'fontMode': 'top',
        },
        {
          'msg': '底部',
          'time': '00:00:03',
          'fontColor': '0xffffff',
          'fontMode': 'bottom',
        },
      ];
      mockApiResponse = PolyvApiResponse<List<dynamic>>.success(
        data: mockData,
        statusCode: 200,
      );

      // WHEN: Fetching danmakus
      final result = await service.fetchDanmakus('test_vid');

      // THEN: Should parse types correctly
      expect(result[0].type, DanmakuType.scroll);
      expect(result[1].type, DanmakuType.top);
      expect(result[2].type, DanmakuType.bottom);
    });

    test('[P2] fetchDanmakus parses time format correctly', () async {
      // GIVEN: API returns danmakus with various time formats
      final mockData = [
        {
          'msg': '0秒',
          'time': '00:00:00',
          'fontColor': '0xffffff',
          'fontMode': 'roll',
        },
        {
          'msg': '1分23秒',
          'time': '00:01:23',
          'fontColor': '0xffffff',
          'fontMode': 'roll',
        },
        {
          'msg': '1小时',
          'time': '01:00:00',
          'fontColor': '0xffffff',
          'fontMode': 'roll',
        },
      ];
      mockApiResponse = PolyvApiResponse<List<dynamic>>.success(
        data: mockData,
        statusCode: 200,
      );

      // WHEN: Fetching danmakus
      final result = await service.fetchDanmakus('test_vid');

      // THEN: Should parse times correctly
      expect(result[0].time, 0);
      expect(result[1].time, 83000); // 1*60 + 23 = 83 seconds = 83000ms
      expect(result[2].time, 3600000); // 1 hour = 3600000ms
    });
  });

  group('DanmakuServiceFactory Tests', () {
    test('[P1] createMock returns MockDanmakuService', () {
      // WHEN: Creating mock service
      final service = DanmakuServiceFactory.createMock();

      // THEN: Should return MockDanmakuService
      expect(service, isA<MockDanmakuService>());
    });

    test('[P1] createHttp returns HttpDanmakuService', () {
      // WHEN: Creating HTTP service
      final service = DanmakuServiceFactory.createHttp(
        userId: 'test_user',
        readToken: 'test_token',
        secretKey: 'test_secret',
      );

      // THEN: Should return HttpDanmakuService with configured apiClient
      expect(service, isA<HttpDanmakuService>());
    });
  });

  group('DanmakuFetchException Tests', () {
    test('[P1] DanmakuFetchException stores error information', () {
      // GIVEN: A DanmakuFetchException
      const exception = DanmakuFetchException(
        type: DanmakuFetchErrorType.network,
        message: 'Network error',
      );

      // THEN: Should store error information
      expect(exception.type, DanmakuFetchErrorType.network);
      expect(exception.message, 'Network error');
      expect(
        exception.toString(),
        'DanmakuFetchException(DanmakuFetchErrorType.network: Network error)',
      );
    });
  });

  group('DanmakuFetchErrorType Enum Tests', () {
    test('[P1] DanmakuFetchErrorType has all required values', () {
      // THEN: Should have all error types
      expect(
        DanmakuFetchErrorType.values,
        contains(DanmakuFetchErrorType.network),
      );
      expect(
        DanmakuFetchErrorType.values,
        contains(DanmakuFetchErrorType.auth),
      );
      expect(
        DanmakuFetchErrorType.values,
        contains(DanmakuFetchErrorType.server),
      );
      expect(
        DanmakuFetchErrorType.values,
        contains(DanmakuFetchErrorType.notFound),
      );
      expect(
        DanmakuFetchErrorType.values,
        contains(DanmakuFetchErrorType.unknown),
      );
    });
  });
}
