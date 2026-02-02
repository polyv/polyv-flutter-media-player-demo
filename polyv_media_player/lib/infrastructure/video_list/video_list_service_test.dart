import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/core/player_config.dart';
import 'package:polyv_media_player/infrastructure/video_list/video_list_models.dart';
import 'package:polyv_media_player/infrastructure/video_list/video_list_exception.dart';
import 'package:polyv_media_player/infrastructure/video_list/video_list_service.dart';

void main() {
  group('MockVideoListService', () {
    late MockVideoListService service;

    setUp(() {
      service = MockVideoListService(enableCache: false, simulateDelay: false);
    });

    test('应该返回视频列表', () async {
      final request = const VideoListRequest(page: 1, pageSize: 20);
      final response = await service.fetchVideoList(request);

      expect(response.videos.isNotEmpty, true);
      expect(response.page, 1);
      expect(response.pageSize, 20);
    });

    test('应该返回 mock 数据中的视频', () async {
      final request = const VideoListRequest(page: 1, pageSize: 20);
      final response = await service.fetchVideoList(request);

      // 检查是否包含预期的 mock 数据
      expect(response.videos.any((v) => v.vid == 'e8888b0d3'), true);
      expect(response.videos.any((v) => v.title.contains('保利威')), true);
    });

    test('应该支持分页', () async {
      final request1 = const VideoListRequest(page: 1, pageSize: 2);
      final response1 = await service.fetchVideoList(request1);

      final request2 = const VideoListRequest(page: 2, pageSize: 2);
      final response2 = await service.fetchVideoList(request2);

      expect(response1.videos.length, 2);
      expect(response2.videos.length, 2);
      // 不同页的视频应该不同
      expect(response1.videos.first.vid != response2.videos.first.vid, true);
    });

    test('应该支持关键词搜索', () async {
      final request = VideoListRequest(page: 1, pageSize: 20, keyword: 'API');
      final response = await service.fetchVideoList(request);

      expect(response.videos.isNotEmpty, true);
      expect(
        response.videos.every(
          (v) =>
              v.title.toLowerCase().contains('api') ||
              (v.description?.toLowerCase().contains('api') ?? false),
        ),
        true,
      );
    });

    test('应该支持标签过滤', () async {
      final request = VideoListRequest(page: 1, pageSize: 20, tags: ['企业']);
      final response = await service.fetchVideoList(request);

      expect(response.videos.isNotEmpty, true);
      expect(
        response.videos.every((v) => v.tags?.contains('企业') ?? false),
        true,
      );
    });

    test('应该支持按更新时间排序', () async {
      final request = VideoListRequest(
        page: 1,
        pageSize: 20,
        orderBy: 'updateTime',
        orderDirection: 'desc',
      );
      final response = await service.fetchVideoList(request);

      expect(response.videos.isNotEmpty, true);
      // 检查是否按时间降序排列
      for (int i = 0; i < response.videos.length - 1; i++) {
        final current = response.videos[i].updateTime ?? DateTime(0);
        final next = response.videos[i + 1].updateTime ?? DateTime(0);
        expect(current.isAfter(next) || current.isAtSameMomentAs(next), true);
      }
    });

    test('应该支持按时长排序', () async {
      final request = VideoListRequest(
        page: 1,
        pageSize: 20,
        orderBy: 'duration',
        orderDirection: 'asc',
      );
      final response = await service.fetchVideoList(request);

      expect(response.videos.isNotEmpty, true);
      // 检查是否按时长升序排列
      for (int i = 0; i < response.videos.length - 1; i++) {
        expect(
          response.videos[i].duration <= response.videos[i + 1].duration,
          true,
        );
      }
    });

    test('应该能获取单个视频信息', () async {
      final video = await service.fetchVideoInfo('e8888b0d3');

      expect(video.vid, 'e8888b0d3');
      expect(video.title.isNotEmpty, true);
      expect(video.duration > 0, true);
    });

    test('获取不存在的视频应该抛出异常', () async {
      expect(
        () => service.fetchVideoInfo('nonexistent'),
        throwsA(isA<VideoListException>()),
      );
    });

    test('清除缓存后应该重新获取数据', () async {
      final serviceWithCache = MockVideoListService(
        enableCache: true,
        simulateDelay: false,
      );
      final request = const VideoListRequest(page: 1, pageSize: 20);

      // 第一次请求
      final response1 = await serviceWithCache.fetchVideoList(request);
      // 修改响应数据（模拟）
      // 第二次请求应该从缓存返回
      final response2 = await serviceWithCache.fetchVideoList(request);

      expect(response1.videos.length, response2.videos.length);

      // 清除缓存
      await serviceWithCache.clearCache();

      // 清除缓存后再请求，应该重新获取
      final response3 = await serviceWithCache.fetchVideoList(request);
      expect(response3.videos.length, response1.videos.length);
    });

    test('模拟网络延迟应该生效', () async {
      final serviceWithDelay = MockVideoListService(
        enableCache: false,
        simulateDelay: true,
      );

      final stopwatch = Stopwatch()..start();
      await serviceWithDelay.fetchVideoList(const VideoListRequest());
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds >= 300, true);
    });
  });

  group('VideoListServiceFactory', () {
    test('应该创建 Mock 服务', () {
      final service = VideoListServiceFactory.createMock(
        enableCache: true,
        simulateDelay: false,
      );

      expect(service, isA<MockVideoListService>());
    });

    test('应该创建 HTTP 服务', () {
      final service = VideoListServiceFactory.createHttp(
        userId: 'test_user',
        readToken: 'test_read_token',
        secretKey: 'test_secret',
        enableCache: true,
      );

      expect(service, isA<HttpVideoListService>());
    });

    test('从配置创建服务（useHttp=false）', () {
      final config = const PlayerConfig(
        userId: 'test_user',
        readToken: 'test_read_token',
        secretKey: 'test_secret',
        writeToken: 'test_write_token',
      );

      final service = VideoListServiceFactory.fromConfig(
        config,
        useHttp: false,
      );

      expect(service, isA<MockVideoListService>());
    });

    test('从配置创建服务（useHttp=true）', () {
      final config = const PlayerConfig(
        userId: 'test_user',
        readToken: 'test_read_token',
        secretKey: 'test_secret',
        writeToken: 'test_write_token',
      );

      final service = VideoListServiceFactory.fromConfig(config, useHttp: true);

      expect(service, isA<HttpVideoListService>());
    });
  });

  group('VideoListException', () {
    test('应该包含错误类型和消息', () {
      const exception = VideoListException(
        type: VideoListErrorType.network,
        message: '网络连接失败',
      );

      expect(exception.type, VideoListErrorType.network);
      expect(exception.message, '网络连接失败');
    });

    test('从状态码创建认证错误', () {
      final exception = VideoListException.fromStatusCode(401);

      expect(exception.type, VideoListErrorType.auth);
      expect(exception.statusCode, 401);
    });

    test('从状态码创建服务器错误', () {
      final exception = VideoListException.fromStatusCode(500);

      expect(exception.type, VideoListErrorType.server);
      expect(exception.statusCode, 500);
    });

    test('从状态码创建参数错误', () {
      final exception = VideoListException.fromStatusCode(400);

      expect(exception.type, VideoListErrorType.parameter);
      expect(exception.statusCode, 400);
    });

    test('工厂方法应该创建特定类型的错误', () {
      final authError = VideoListException.auth(detail: 'Token 失效');
      expect(authError.type, VideoListErrorType.auth);
      expect(authError.message, 'Token 失效');

      final networkError = VideoListException.network();
      expect(networkError.type, VideoListErrorType.network);

      final serverError = VideoListException.server();
      expect(serverError.type, VideoListErrorType.server);

      final paramError = VideoListException.parameter();
      expect(paramError.type, VideoListErrorType.parameter);
    });

    test('toString 应该返回有用的调试信息', () {
      const exception = VideoListException(
        type: VideoListErrorType.network,
        message: '网络连接失败',
      );

      final str = exception.toString();
      expect(str.contains('VideoListException'), true);
      expect(str.contains('network'), true);
      expect(str.contains('网络连接失败'), true);
    });
  });
}
