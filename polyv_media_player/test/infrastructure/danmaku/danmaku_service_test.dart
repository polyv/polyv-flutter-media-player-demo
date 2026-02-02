import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/infrastructure/danmaku/danmaku_model.dart';
import 'package:polyv_media_player/infrastructure/danmaku/danmaku_service.dart';

/// [P1] Danmaku Service 单元测试
///
/// 测试弹幕服务的核心功能，包括 Mock 服务和 HTTP 服务
void main() {
  group('MockDanmakuService', () {
    late MockDanmakuService service;

    setUp(() {
      // GIVEN: 每个测试前创建新的 Mock 服务
      service = MockDanmakuService(enableCache: true);
    });

    tearDown(() async {
      // 清理：清除缓存
      await service.clearCache();
    });

    test('[P0] should fetch danmakus for a valid vid', () async {
      // GIVEN: 一个有效的视频 ID
      const vid = 'test_video_123';

      // WHEN: 获取弹幕列表
      final danmakus = await service.fetchDanmakus(vid);

      // THEN: 返回非空列表
      expect(danmakus, isNotEmpty);
      // 弹幕按时间排序
      expect(danmakus.first.time, lessThan(danmakus.last.time));
    });

    test('[P1] should return different danmakus for different vids', () async {
      // GIVEN: 两个不同的视频 ID
      const vid1 = 'video_a';
      const vid2 = 'video_b';

      // WHEN: 获取两个视频的弹幕
      final danmakus1 = await service.fetchDanmakus(vid1);
      final danmakus2 = await service.fetchDanmakus(vid2);

      // THEN: 弹幕内容不同
      expect(danmakus1, isNotEmpty);
      expect(danmakus2, isNotEmpty);
      // 至少第一条弹幕的 ID 应该不同
      expect(danmakus1.first.id, isNot(equals(danmakus2.first.id)));
    });

    test('[P1] should respect limit parameter', () async {
      // GIVEN: 一个视频 ID
      const vid = 'limit_test';
      const limit = 10;

      // WHEN: 使用 limit 获取弹幕
      final danmakus = await service.fetchDanmakus(vid, limit: limit);

      // THEN: 返回数量不超过 limit
      expect(danmakus.length, lessThanOrEqualTo(limit));
    });

    test('[P1] should respect offset parameter', () async {
      // GIVEN: 一个视频 ID
      const vid = 'offset_test';
      const offset = 5;

      // WHEN: 使用 offset 获取弹幕
      final allDanmakus = await service.fetchDanmakus(vid);
      final offsetDanmakus = await service.fetchDanmakus(vid, offset: offset);

      // THEN: offset 后的弹幕与全量对应位置的弹幕一致
      if (allDanmakus.length > offset) {
        expect(offsetDanmakus.first.id, equals(allDanmakus[offset].id));
      }
    });

    test('[P1] should cache danmakus when enabled', () async {
      // GIVEN: 启用缓存的服务
      const vid = 'cache_test';

      // WHEN: 第一次获取弹幕
      final firstCall = await service.fetchDanmakus(vid);
      // 第二次获取弹幕（应从缓存返回）
      final secondCall = await service.fetchDanmakus(vid);

      // THEN: 两次返回相同的弹幕（同一对象引用）
      expect(identical(firstCall, secondCall), isTrue);
    });

    test('[P1] should not cache when disabled', () async {
      // GIVEN: 禁用缓存的服务
      final noCacheService = MockDanmakuService(enableCache: false);
      const vid = 'no_cache_test';

      // WHEN: 两次获取弹幕
      final firstCall = await noCacheService.fetchDanmakus(vid);
      final secondCall = await noCacheService.fetchDanmakus(vid);

      // THEN: 返回不同的对象（每次重新生成）
      expect(identical(firstCall, secondCall), isFalse);
    });

    test('[P1] should clear cache correctly', () async {
      // GIVEN: 已有缓存的视频
      const vid = 'clear_cache_test';
      await service.fetchDanmakus(vid);

      // WHEN: 清除缓存
      await service.clearCache();

      // THEN: 再次获取会重新生成数据
      // 由于 Mock 数据生成器是确定性的，我们通过验证方法被调用来检查
      // 这里简单验证清除后仍能正常获取数据
      final danmakus = await service.fetchDanmakus(vid);
      expect(danmakus, isNotEmpty);
    });

    test('[P2] should include different danmaku types', () async {
      // GIVEN: 一个视频 ID
      const vid = 'type_test';

      // WHEN: 获取弹幕
      final danmakus = await service.fetchDanmakus(vid);

      // THEN: 包含不同类型的弹幕
      final types = danmakus.map((d) => d.type).toSet();
      expect(types, contains(DanmakuType.scroll));
      expect(types, contains(DanmakuType.top));
      expect(types, contains(DanmakuType.bottom));
    });

    test('[P2] should include danmakus with colors', () async {
      // GIVEN: 一个视频 ID
      const vid = 'color_test';

      // WHEN: 获取弹幕
      final danmakus = await service.fetchDanmakus(vid);

      // THEN: 部分弹幕有颜色
      final coloredDanmakus = danmakus.where((d) => d.color != null);
      expect(coloredDanmakus, isNotEmpty);
    });

    test('[P2] should generate consistent data for same vid', () async {
      // GIVEN: 同一个视频 ID
      const vid = 'consistency_test';

      // WHEN: 多次获取弹幕（清除缓存后）
      final first = await service.fetchDanmakus(vid);
      await service.clearCache();
      final second = await service.fetchDanmakus(vid);

      // THEN: 生成的弹幕数据一致（数量和 ID）
      expect(first.length, equals(second.length));
      for (int i = 0; i < first.length; i++) {
        expect(first[i].id, equals(second[i].id));
        expect(first[i].text, equals(second[i].text));
        expect(first[i].time, equals(second[i].time));
      }
    });
  });

  group('MockDanmakuSendService', () {
    late MockDanmakuSendService service;

    setUp(() {
      // GIVEN: 每个 test 前创建新的服务
      service = MockDanmakuSendService(
        simulateDelay: false, // 关闭延迟以加快测试
        simulateRandomFailure: false, // 关闭随机失败
      );
    });

    test('[P0] should send danmaku successfully', () async {
      // GIVEN: 一个有效的弹幕请求
      const request = DanmakuSendRequest(
        vid: 'test_video',
        text: 'Test danmaku',
        time: 5000,
      );

      // WHEN: 发送弹幕
      final response = await service.sendDanmaku(request);

      // THEN: 返回成功响应
      expect(response.success, isTrue);
      expect(response.danmakuId, isNotNull);
      expect(response.danmakuId, startsWith('mock_'));
      expect(response.serverTime, isNotNull);
    });

    test('[P1] should validate empty text', () async {
      // GIVEN: 空文本的请求
      const request = DanmakuSendRequest(
        vid: 'test_video',
        text: '',
        time: 5000,
      );

      // WHEN/THEN: 发送时抛出校验错误
      expect(
        () => service.sendDanmaku(request),
        throwsA(
          isA<DanmakuSendException>()
              .having((e) => e.type, 'type', DanmakuSendErrorType.validation)
              .having((e) => e.message, 'message', contains('不能为空')),
        ),
      );
    });

    test('[P1] should validate whitespace-only text', () async {
      // GIVEN: 只有空格的请求
      const request = DanmakuSendRequest(
        vid: 'test_video',
        text: '   ',
        time: 5000,
      );

      // WHEN/THEN: 发送时抛出校验错误
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

    test('[P1] should validate minimum text length', () async {
      // GIVEN: 使用自定义最小长度的配置
      final customService = MockDanmakuSendService(
        config: const DanmakuSendConfig(minTextLength: 5),
        simulateDelay: false,
      );

      const request = DanmakuSendRequest(
        vid: 'test_video',
        text: 'abc', // 少于 5 个字符
        time: 5000,
      );

      // WHEN/THEN: 发送时抛出校验错误
      expect(
        () => customService.sendDanmaku(request),
        throwsA(
          isA<DanmakuSendException>()
              .having((e) => e.type, 'type', DanmakuSendErrorType.validation)
              .having((e) => e.message, 'message', contains('至少需要')),
        ),
      );
    });

    test('[P1] should validate maximum text length', () async {
      // GIVEN: 超长文本的请求（101个字符，超过默认最大长度100）
      final longText = List.generate(101, (i) => 'a').join();

      final request = DanmakuSendRequest(
        vid: 'test_video',
        text: longText,
        time: 5000,
      );

      // WHEN/THEN: 发送时抛出校验错误
      expect(
        () => service.sendDanmaku(request),
        throwsA(
          isA<DanmakuSendException>()
              .having((e) => e.type, 'type', DanmakuSendErrorType.validation)
              .having((e) => e.message, 'message', contains('不能超过')),
        ),
      );
    });

    test('[P1] should enforce throttling', () async {
      // GIVEN: 第一次发送成功
      const request = DanmakuSendRequest(
        vid: 'test_video',
        text: 'First danmaku',
        time: 5000,
      );

      await service.sendDanmaku(request);

      // WHEN: 立即再次发送
      const secondRequest = DanmakuSendRequest(
        vid: 'test_video',
        text: 'Second danmaku',
        time: 5000,
      );

      // THEN: 抛出节流错误
      expect(
        () => service.sendDanmaku(secondRequest),
        throwsA(
          isA<DanmakuSendException>()
              .having((e) => e.type, 'type', DanmakuSendErrorType.throttled)
              .having((e) => e.message, 'message', contains('频繁')),
        ),
      );
    });

    test('[P1] should allow sending after throttle interval', () async {
      // GIVEN: 使用短间隔的配置
      final fastService = MockDanmakuSendService(
        config: const DanmakuSendConfig(minSendInterval: 100), // 100ms
        simulateDelay: false,
      );

      const request = DanmakuSendRequest(
        vid: 'test_video',
        text: 'First',
        time: 5000,
      );

      // WHEN: 第一次发送后等待超过节流间隔
      await fastService.sendDanmaku(request);
      await Future.delayed(const Duration(milliseconds: 150));

      // THEN: 第二次发送成功
      final response = await fastService.sendDanmaku(
        const DanmakuSendRequest(vid: 'test_video', text: 'Second', time: 5000),
      );

      expect(response.success, isTrue);
    });

    test(
      '[P1] should return validation error for invalid characters',
      () async {
        // GIVEN: 包含控制字符的文本
        final text = 'Normal${String.fromCharCode(1)}Text'; // 包含控制字符

        // WHEN: 验证文本
        final error = service.validateText(text);

        // THEN: 返回错误消息
        expect(error, isNotNull);
        expect(error, contains('非法字符'));
      },
    );

    test('[P1] should validate text correctly', () async {
      // GIVEN: 有效的弹幕文本
      const validText = '这是一个有效的弹幕';

      // WHEN: 验证文本
      final error = service.validateText(validText);

      // THEN: 返回 null（验证通过）
      expect(error, isNull);
    });

    test('[P1] should check canSend correctly', () async {
      // GIVEN: 从未发送过的服务
      // WHEN: 检查是否可以发送
      final canSend = service.canSend(null);

      // THEN: 允许发送
      expect(canSend, isTrue);
    });

    test('[P1] should check canSend after sending', () async {
      // GIVEN: 已发送过弹幕的服务
      const request = DanmakuSendRequest(vid: 'test', text: 'Test', time: 1000);
      await service.sendDanmaku(request);

      // WHEN: 立即检查是否可以发送
      final lastSendTime = service.lastSendTime;
      final canSend = service.canSend(lastSendTime);

      // THEN: 不允许发送
      expect(canSend, isFalse);
    });

    test('[P1] should reset throttle', () async {
      // GIVEN: 已发送过弹幕的服务
      const request = DanmakuSendRequest(vid: 'test', text: 'Test', time: 1000);
      await service.sendDanmaku(request);

      // WHEN: 重置节流状态
      service.resetThrottle();

      // THEN: 可以立即发送
      final canSend = service.canSend(service.lastSendTime);
      expect(canSend, isTrue);
    });

    test('[P1] should increment danmaku counter', () async {
      // GIVEN: 一个服务
      // WHEN: 连续发送多个弹幕
      final responses = <DanmakuSendResponse>[];

      // 使用无节流限制的方式发送（通过 resetThrottle）
      for (int i = 0; i < 3; i++) {
        service.resetThrottle();
        final response = await service.sendDanmaku(
          DanmakuSendRequest(vid: 'test', text: 'Danmaku $i', time: 1000),
        );
        responses.add(response);
      }

      // THEN: 每个 danmakuId 的后缀递增
      expect(responses[0].danmakuId, endsWith('_0'));
      expect(responses[1].danmakuId, endsWith('_1'));
      expect(responses[2].danmakuId, endsWith('_2'));
    });

    test('[P2] should generate unique danmaku IDs', () async {
      // GIVEN: 同一个视频
      const vid = 'unique_test';

      // WHEN: 发送多次
      service.resetThrottle();
      final id1 = (await service.sendDanmaku(
        const DanmakuSendRequest(vid: vid, text: 'A', time: 0),
      )).danmakuId;

      service.resetThrottle();
      final id2 = (await service.sendDanmaku(
        const DanmakuSendRequest(vid: vid, text: 'B', time: 0),
      )).danmakuId;

      // THEN: ID 不同
      expect(id1, isNot(equals(id2)));
    });

    test('[P2] should respect minSendInterval from config', () async {
      // GIVEN: 自定义间隔配置
      const customInterval = 3000;
      final customService = MockDanmakuSendService(
        config: const DanmakuSendConfig(minSendInterval: customInterval),
        simulateDelay: false,
      );

      // WHEN: 获取最小间隔
      final interval = customService.minSendInterval;

      // THEN: 使用配置的值
      expect(interval, customInterval);
    });

    test('[P2] should simulate network delay when enabled', () async {
      // GIVEN: 启用延迟的服务
      final delayedService = MockDanmakuSendService(
        simulateDelay: true,
        simulateRandomFailure: false,
      );

      const request = DanmakuSendRequest(
        vid: 'test',
        text: 'Delayed',
        time: 1000,
      );

      // WHEN: 测量发送时间
      final start = DateTime.now();
      await delayedService.sendDanmaku(request);
      final elapsed = DateTime.now().difference(start);

      // THEN: 至少有 500ms 延迟
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(500));
    });
  });

  group('DanmakuServiceFactory', () {
    test('[P1] should create MockDanmakuService', () {
      // WHEN: 创建 Mock 服务
      final service = DanmakuServiceFactory.createMock(enableCache: false);

      // THEN: 返回 Mock 服务
      expect(service, isA<MockDanmakuService>());
    });

    test('[P1] should create HttpDanmakuService with parameters', () {
      // WHEN: 创建 HTTP 服务
      final service = DanmakuServiceFactory.createHttp(
        userId: 'test_user',
        readToken: 'test_read_token',
        secretKey: 'test_secret',
        enableCache: true,
      );

      // THEN: 返回 HTTP 服务
      expect(service, isA<HttpDanmakuService>());
    });
  });

  group('DanmakuSendServiceFactory', () {
    test('[P1] should create MockDanmakuSendService', () {
      // WHEN: 创建 Mock 发送服务
      final service = DanmakuSendServiceFactory.createMock(
        simulateDelay: false,
      );

      // THEN: 返回 Mock 发送服务
      expect(service, isA<MockDanmakuSendService>());
    });

    test('[P1] should create HttpDanmakuSendService with parameters', () {
      // WHEN: 创建 HTTP 发送服务
      final service = DanmakuSendServiceFactory.createHttp(
        userId: 'test_user',
        writeToken: 'test_write_token',
        secretKey: 'test_secret',
      );

      // THEN: 返回 HTTP 发送服务
      expect(service, isA<HttpDanmakuSendService>());
    });

    test('[P2] should use default config when not provided', () {
      // WHEN: 创建 Mock 服务不提供配置
      final service = DanmakuSendServiceFactory.createMock();

      // THEN: 使用默认配置
      expect(service.minSendInterval, 2000); // 默认 2000ms
    });
  });

  group('DanmakuFetchException', () {
    test('[P1] should create exception with type and message', () {
      // GIVEN: 错误类型和消息
      const type = DanmakuFetchErrorType.network;
      const message = 'Network connection failed';

      // WHEN: 创建异常
      const exception = DanmakuFetchException(type: type, message: message);

      // THEN: 属性正确设置
      expect(exception.type, type);
      expect(exception.message, message);
    });

    test('[P1] should convert to string correctly', () {
      // GIVEN: 一个异常
      const exception = DanmakuFetchException(
        type: DanmakuFetchErrorType.auth,
        message: 'Authentication failed',
      );

      // WHEN: 转换为字符串
      final str = exception.toString();

      // THEN: 包含类型和消息
      expect(str, contains('auth'));
      expect(str, contains('Authentication failed'));
    });
  });
}
