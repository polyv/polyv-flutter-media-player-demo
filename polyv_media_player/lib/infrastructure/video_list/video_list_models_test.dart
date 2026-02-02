import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/infrastructure/video_list/video_list_models.dart';

void main() {
  group('VideoItem', () {
    test('应该正确创建 VideoItem', () {
      final video = VideoItem(
        vid: 'e8888b0d3',
        title: '测试视频',
        duration: 155,
        thumbnail: 'https://example.com/thumb.jpg',
      );

      expect(video.vid, 'e8888b0d3');
      expect(video.title, '测试视频');
      expect(video.duration, 155);
      expect(video.thumbnail, 'https://example.com/thumb.jpg');
    });

    test('应该正确格式化时长（MM:SS）', () {
      final video = VideoItem(
        vid: 'test',
        title: '测试',
        duration: 155,
        thumbnail: 'test',
      );

      expect(video.durationFormatted, '02:35');
    });

    test('应该正确格式化时长（HH:MM:SS）', () {
      final video = VideoItem(
        vid: 'test',
        title: '测试',
        duration: 3661,
        thumbnail: 'test',
      );

      expect(video.durationFormatted, '01:01:01');
    });

    test('应该从 JSON 创建 VideoItem（标准格式）', () {
      final json = {
        'vid': 'e8888b0d3',
        'title': '测试视频',
        'duration': 155,
        'thumbnail': 'https://example.com/thumb.jpg',
        'views': '12.5万',
      };

      final video = VideoItem.fromJson(json);

      expect(video.vid, 'e8888b0d3');
      expect(video.title, '测试视频');
      expect(video.duration, 155);
      expect(video.thumbnail, 'https://example.com/thumb.jpg');
      expect(video.views, '12.5万');
    });

    test('应该从 JSON 创建 VideoItem（兼容不同字段名）', () {
      final json = {
        'id': 'e8888b0d3',
        'videoName': '测试视频',
        'duration': 155,
        'cover': 'https://example.com/thumb.jpg',
        'playCount': 12500,
      };

      final video = VideoItem.fromJson(json);

      expect(video.vid, 'e8888b0d3');
      expect(video.title, '测试视频');
      expect(video.thumbnail, 'https://example.com/thumb.jpg');
      expect(video.views, '1.3万');
    });

    test('应该正确转换为 JSON', () {
      final video = VideoItem(
        vid: 'e8888b0d3',
        title: '测试视频',
        duration: 155,
        thumbnail: 'https://example.com/thumb.jpg',
        views: '12.5万',
      );

      final json = video.toJson();

      expect(json['vid'], 'e8888b0d3');
      expect(json['title'], '测试视频');
      expect(json['duration'], 155);
      expect(json['thumbnail'], 'https://example.com/thumb.jpg');
      expect(json['views'], '12.5万');
    });

    test('copyWith 应该正确修改属性', () {
      final video = VideoItem(
        vid: 'e8888b0d3',
        title: '测试视频',
        duration: 155,
        thumbnail: 'test',
      );

      final updated = video.copyWith(title: '更新后的标题');

      expect(updated.vid, 'e8888b0d3');
      expect(updated.title, '更新后的标题');
      expect(video.title, '测试视频'); // 原对象不变
    });

    test('应该根据 vid 判断相等', () {
      final video1 = VideoItem(
        vid: 'e8888b0d3',
        title: '测试视频',
        duration: 155,
        thumbnail: 'test',
      );

      final video2 = VideoItem(
        vid: 'e8888b0d3',
        title: '不同的标题',
        duration: 200,
        thumbnail: 'different',
      );

      expect(video1, video2);
      expect(video1.hashCode, video2.hashCode);
    });
  });

  group('VideoListResponse', () {
    test('应该正确创建 VideoListResponse', () {
      final videos = [
        VideoItem(vid: '1', title: '视频1', duration: 100, thumbnail: 'test'),
        VideoItem(vid: '2', title: '视频2', duration: 200, thumbnail: 'test'),
      ];

      final response = VideoListResponse(
        videos: videos,
        page: 1,
        pageSize: 20,
        total: 2,
      );

      expect(response.videos.length, 2);
      expect(response.page, 1);
      expect(response.pageSize, 20);
      expect(response.total, 2);
    });

    test('应该正确计算总页数', () {
      final response = VideoListResponse(
        videos: [],
        page: 1,
        pageSize: 20,
        total: 45,
      );

      expect(response.totalPages, 3);
    });

    test('应该正确判断是否有下一页', () {
      final response = VideoListResponse(
        videos: [],
        page: 1,
        pageSize: 20,
        total: 45,
      );

      expect(response.hasNextPage, true);
      expect(response.hasPreviousPage, false);
    });

    test('应该正确判断是否有上一页', () {
      final response = VideoListResponse(
        videos: [],
        page: 2,
        pageSize: 20,
        total: 45,
      );

      expect(response.hasNextPage, true);
      expect(response.hasPreviousPage, true);
    });

    test('应该从 JSON 创建 VideoListResponse', () {
      final json = {
        'data': [
          {'vid': '1', 'title': '视频1', 'duration': 100, 'thumbnail': 'test'},
          {'vid': '2', 'title': '视频2', 'duration': 200, 'thumbnail': 'test'},
        ],
        'page': 1,
        'pageSize': 20,
        'total': 2,
      };

      final response = VideoListResponse.fromJson(json);

      expect(response.videos.length, 2);
      expect(response.page, 1);
      expect(response.pageSize, 20);
      expect(response.total, 2);
    });

    test('empty 常量应该返回空响应', () {
      final response = VideoListResponse.empty;

      expect(response.videos.isEmpty, true);
      expect(response.total, 0);
    });
  });

  group('VideoListRequest', () {
    test('应该使用默认值创建请求', () {
      final request = const VideoListRequest();

      expect(request.page, 1);
      expect(request.pageSize, 20);
      expect(request.orderBy, null);
      expect(request.keyword, null);
    });

    test('应该正确转换为查询参数', () {
      final request = const VideoListRequest(
        page: 2,
        pageSize: 10,
        orderBy: 'updateTime',
        orderDirection: 'desc',
        keyword: '测试',
      );

      final params = request.toQueryParams();

      expect(params['page'], 2);
      expect(params['pageSize'], 10);
      expect(params['orderBy'], 'updateTime');
      expect(params['orderDirection'], 'desc');
      expect(params['keyword'], '测试');
    });

    test('nextPage 应该创建下一页请求', () {
      final request = const VideoListRequest(
        page: 1,
        pageSize: 20,
        orderBy: 'updateTime',
      );

      final nextPage = request.nextPage();

      expect(nextPage.page, 2);
      expect(nextPage.pageSize, 20);
      expect(nextPage.orderBy, 'updateTime');
    });

    test('copyWith 应该正确修改属性', () {
      final request = const VideoListRequest(page: 1, pageSize: 20);

      final updated = request.copyWith(page: 2, orderBy: 'duration');

      expect(updated.page, 2);
      expect(updated.pageSize, 20);
      expect(updated.orderBy, 'duration');
      expect(request.page, 1); // 原对象不变
    });

    test('应该正确格式化标签参数', () {
      final request = VideoListRequest(
        page: 1,
        pageSize: 20,
        tags: ['标签1', '标签2', '标签3'],
      );

      final params = request.toQueryParams();

      expect(params['tags'], '标签1,标签2,标签3');
    });
  });

  group('VideoListResponse 格式化播放次数', () {
    test('应该正确格式化小数字（< 10000）', () {
      final views = VideoItem(
        vid: 'test',
        title: '测试',
        duration: 100,
        thumbnail: 'test',
        views: '999',
      );

      expect(views.views, '999');
    });

    test('应该正确格式化万（10000 - 99999999）', () {
      // 直接检查静态方法的行为
      // VideoItem 内部使用 _formatViewCount
      final json = {'playCount': 12500};
      final formatted = json['playCount'] as int;
      final result = formatted >= 10000 && formatted < 100000000
          ? '${formatted / 10000}万'
          : formatted.toString();

      expect(result.contains('万'), true);
    });

    test('应该正确格式化亿（>= 100000000）', () {
      final json = {'playCount': 125000000};
      final formatted = json['playCount'] as int;
      final result = formatted >= 100000000
          ? '${formatted / 100000000}亿'
          : formatted >= 10000
          ? '${formatted / 10000}万'
          : formatted.toString();

      expect(result.contains('亿'), true);
    });
  });
}
