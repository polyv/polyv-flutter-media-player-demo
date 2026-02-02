import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:polyv_media_player/infrastructure/video_list/video_list_api_client.dart';
import 'package:polyv_media_player/infrastructure/video_list/video_list_exception.dart';
import 'package:polyv_media_player/infrastructure/video_list/video_list_models.dart';

void main() {
  group('VideoListApiClient', () {
    group('[P0] fetchVideoList - 成功场景', () {
      test('[P0] 应该成功获取视频列表', () async {
        // GIVEN: Mock HTTP client returning successful response
        final mockClient = MockClient((request) async {
          return http.Response(
            '{"code":200,"status":"success","data":[{"vid":"e8888b0d3","title":"Test1","duration":155,"thumbnail":"https://example.com/thumb1.jpg"},{"vid":"e8888b0d4","title":"Test2","duration":320,"thumbnail":"https://example.com/thumb2.jpg"}]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = VideoListApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN: 请求视频列表
        final request = const VideoListRequest(page: 1, pageSize: 20);
        final response = await apiClient.fetchVideoList(request);

        // THEN: 返回正确的视频列表
        expect(response.videos.length, 2);
        expect(response.videos[0].vid, 'e8888b0d3');
        expect(response.videos[0].title, 'Test1');
        expect(response.videos[1].vid, 'e8888b0d4');
        expect(response.page, 1);
        expect(response.pageSize, 20);

        apiClient.dispose();
      });

      test('[P0] 应该返回空列表当没有数据时', () async {
        // GIVEN: API 返回空数据
        final mockClient = MockClient((request) async {
          return http.Response(
            '{"code":200,"status":"success","data":[]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = VideoListApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN: 请求视频列表
        final request = const VideoListRequest(page: 1, pageSize: 20);
        final response = await apiClient.fetchVideoList(request);

        // THEN: 返回空列表
        expect(response.videos.isEmpty, true);
        expect(response.total, 0);

        apiClient.dispose();
      });
    });

    group('[P1] fetchVideoList - 错误处理', () {
      test('[P1] 应该抛出认证错误当返回 401 时', () async {
        // GIVEN: API 返回 401
        final mockClient = MockClient((request) async {
          return http.Response('{"code": 401, "message": "Unauthorized"}', 401);
        });

        final apiClient = VideoListApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN/THEN: 请求应该抛出认证错误
        expect(
          () => apiClient.fetchVideoList(const VideoListRequest()),
          throwsA(
            isA<VideoListException>().having(
              (e) => e.type,
              'type',
              VideoListErrorType.auth,
            ),
          ),
        );

        apiClient.dispose();
      });

      test('[P1] 应该抛出参数错误当返回 400 时', () async {
        // GIVEN: API 返回 400
        final mockClient = MockClient((request) async {
          return http.Response('{"code": 400, "message": "Bad Request"}', 400);
        });

        final apiClient = VideoListApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN/THEN: 请求应该抛出参数错误
        expect(
          () => apiClient.fetchVideoList(const VideoListRequest()),
          throwsA(
            isA<VideoListException>().having(
              (e) => e.type,
              'type',
              VideoListErrorType.parameter,
            ),
          ),
        );

        apiClient.dispose();
      });

      test('[P1] 应该抛出服务器错误当返回 500 时', () async {
        // GIVEN: API 返回 500
        final mockClient = MockClient((request) async {
          return http.Response(
            '{"code": 500, "message": "Internal Server Error"}',
            500,
          );
        });

        final apiClient = VideoListApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN/THEN: 请求应该抛出服务器错误
        expect(
          () => apiClient.fetchVideoList(const VideoListRequest()),
          throwsA(
            isA<VideoListException>().having(
              (e) => e.type,
              'type',
              VideoListErrorType.server,
            ),
          ),
        );

        apiClient.dispose();
      });

      test('[P1] 应该抛出网络错误当网络失败时', () async {
        // GIVEN: 网络请求失败
        final mockClient = MockClient((request) async {
          throw http.ClientException('Network connection failed');
        });

        final apiClient = VideoListApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN/THEN: 请求应该抛出网络错误
        expect(
          () => apiClient.fetchVideoList(const VideoListRequest()),
          throwsA(isA<VideoListException>()),
        );

        apiClient.dispose();
      });
    });

    group('[P0] fetchVideoInfo - 成功场景', () {
      test('[P0] 应该成功获取单个视频信息', () async {
        // GIVEN: API 返回视频信息
        final mockClient = MockClient((request) async {
          return http.Response(
            '{"code":200,"status":"success","data":[{"vid":"e8888b0d3","title":"Test","duration":155,"thumbnail":"https://example.com/thumb.jpg"}]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = VideoListApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN: 请求视频信息
        final video = await apiClient.fetchVideoInfo('e8888b0d3');

        // THEN: 返回正确的视频信息
        expect(video.vid, 'e8888b0d3');
        expect(video.title, 'Test');
        expect(video.duration, 155);

        apiClient.dispose();
      });
    });

    group('[P1] fetchVideoInfo - 错误处理', () {
      test('[P1] 获取不存在的视频应该抛出参数错误', () async {
        // GIVEN: API 返回空数据
        final mockClient = MockClient((request) async {
          return http.Response(
            '{"code":200,"status":"success","data":[]}',
            200,
          );
        });

        final apiClient = VideoListApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN/THEN: 请求应该抛出参数错误
        expect(
          () => apiClient.fetchVideoInfo('nonexistent'),
          throwsA(
            isA<VideoListException>().having(
              (e) => e.type,
              'type',
              VideoListErrorType.parameter,
            ),
          ),
        );

        apiClient.dispose();
      });

      test('[P1] 应该正确处理 API 错误响应', () async {
        // GIVEN: API 返回错误
        final mockClient = MockClient((request) async {
          return http.Response(
            '{"code": 404, "message": "Video not found"}',
            404,
          );
        });

        final apiClient = VideoListApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN/THEN: 请求应该抛出参数错误
        expect(
          () => apiClient.fetchVideoInfo('e8888b0d3'),
          throwsA(
            isA<VideoListException>().having(
              (e) => e.type,
              'type',
              VideoListErrorType.parameter,
            ),
          ),
        );

        apiClient.dispose();
      });
    });

    group('[P2] 错误类型映射', () {
      test('[P2] 403 应该映射为认证错误', () async {
        final mockClient = MockClient((request) async {
          return http.Response('{"code": 403, "message": "Forbidden"}', 403);
        });

        final apiClient = VideoListApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        expect(
          () => apiClient.fetchVideoList(const VideoListRequest()),
          throwsA(
            isA<VideoListException>().having(
              (e) => e.type,
              'type',
              VideoListErrorType.auth,
            ),
          ),
        );

        apiClient.dispose();
      });

      test('[P2] 502 应该映射为服务器错误', () async {
        final mockClient = MockClient((request) async {
          return http.Response('{"code": 502, "message": "Bad Gateway"}', 502);
        });

        final apiClient = VideoListApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        expect(
          () => apiClient.fetchVideoList(const VideoListRequest()),
          throwsA(
            isA<VideoListException>().having(
              (e) => e.type,
              'type',
              VideoListErrorType.server,
            ),
          ),
        );

        apiClient.dispose();
      });

      test('[P2] 503 应该映射为服务器错误', () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            '{"code": 503, "message": "Service Unavailable"}',
            503,
          );
        });

        final apiClient = VideoListApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        expect(
          () => apiClient.fetchVideoList(const VideoListRequest()),
          throwsA(
            isA<VideoListException>().having(
              (e) => e.type,
              'type',
              VideoListErrorType.server,
            ),
          ),
        );

        apiClient.dispose();
      });
    });

    group('[P2] 边界情况', () {
      test('[P2] 应该处理 JSON 解析错误', () async {
        // GIVEN: API 返回无效的 JSON
        final mockClient = MockClient((request) async {
          return http.Response('invalid json', 200);
        });

        final apiClient = VideoListApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN/THEN: 请求应该抛出错误
        expect(
          () => apiClient.fetchVideoList(const VideoListRequest()),
          throwsA(isA<VideoListException>()),
        );

        apiClient.dispose();
      });

      test('[P2] 应该处理缺少必要字段的响应', () async {
        // GIVEN: API 返回缺少 vid 的数据
        final mockClient = MockClient((request) async {
          return http.Response(
            '{"code":200,"status":"success","data":[{"title":"Test","duration":155}]}',
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = VideoListApiClient(
          userId: 'test_user',
          readToken: 'test_read_token',
          secretKey: 'test_secret',
          client: mockClient,
        );

        // WHEN: 请求视频列表
        final response = await apiClient.fetchVideoList(
          const VideoListRequest(page: 1, pageSize: 20),
        );

        // THEN: 应该处理缺失字段（使用默认值）
        expect(response.videos.isNotEmpty, true);
        expect(response.videos[0].vid, ''); // 默认空字符串

        apiClient.dispose();
      });
    });
  });
}
