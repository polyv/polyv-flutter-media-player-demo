import 'dart:async';

import 'package:http/http.dart' as http;

import '../../core/player_config.dart';
import 'video_list_models.dart';
import 'video_list_exception.dart';
import 'video_list_api_client.dart';

/// 视频列表服务接口
///
/// 负责从 Polyv API 或其他数据源获取视频列表
/// 以及提供分页、缓存等高级功能
///
/// 架构说明：
/// - 视频列表业务逻辑统一在 Flutter(Dart) 层实现
/// - 原生层不直接访问 Polyv REST API 或维护视频列表业务状态
abstract class VideoListService {
  /// 获取视频列表
  ///
  /// [request] 请求参数（分页、排序、搜索等）
  ///
  /// 返回视频列表响应
  Future<VideoListResponse> fetchVideoList(VideoListRequest request);

  /// 获取单个视频信息
  ///
  /// [vid] 视频 ID
  Future<VideoItem> fetchVideoInfo(String vid);

  /// 清除缓存（如果有）
  Future<void> clearCache();
}

/// Mock 视频列表服务实现
///
/// 用于测试和开发，返回预设的视频数据
/// 后续可替换为真实的 Polyv API 实现
class MockVideoListService implements VideoListService {
  /// 缓存的视频列表数据
  final Map<String, VideoListResponse> _cache = {};

  /// 是否启用缓存
  final bool enableCache;

  /// 是否模拟网络延迟
  final bool simulateDelay;

  /// 是否模拟随机失败（用于测试错误处理）
  final bool simulateRandomFailure;

  MockVideoListService({
    this.enableCache = true,
    this.simulateDelay = true,
    this.simulateRandomFailure = false,
  });

  @override
  Future<VideoListResponse> fetchVideoList(VideoListRequest request) async {
    // 检查缓存
    final cacheKey = _buildCacheKey(request);
    if (enableCache && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // 模拟网络延迟
    if (simulateDelay) {
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // 模拟随机失败（用于测试）
    if (simulateRandomFailure && _shouldSimulateFailure()) {
      throw VideoListException.network(detail: '模拟网络失败');
    }

    // 生成 mock 数据
    final videos = _generateMockVideos(request);

    // 模拟分页
    final startIndex = (request.page - 1) * request.pageSize;
    final endIndex = startIndex + request.pageSize;
    final pageVideos = startIndex < videos.length
        ? videos.sublist(startIndex, endIndex.clamp(0, videos.length))
        : <VideoItem>[];

    final response = VideoListResponse(
      videos: pageVideos,
      page: request.page,
      pageSize: request.pageSize,
      total: videos.length,
    );

    // 缓存数据
    if (enableCache) {
      _cache[cacheKey] = response;
    }

    return response;
  }

  @override
  Future<VideoItem> fetchVideoInfo(String vid) async {
    // 模拟网络延迟
    if (simulateDelay) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // 从 mock 数据中查找
    final videos = _generateMockVideos(const VideoListRequest());
    final video = videos.where((v) => v.vid == vid).firstOrNull;

    if (video == null) {
      throw VideoListException.parameter(detail: '视频不存在: $vid');
    }

    return video;
  }

  @override
  Future<void> clearCache() async {
    _cache.clear();
  }

  /// 生成缓存键
  String _buildCacheKey(VideoListRequest request) {
    final buffer = StringBuffer()
      ..write('page=${request.page}')
      ..write('&pageSize=${request.pageSize}');
    if (request.orderBy != null) {
      buffer.write('&orderBy=${request.orderBy}');
    }
    if (request.keyword != null) {
      buffer.write('&keyword=${request.keyword}');
    }
    return buffer.toString();
  }

  /// 决定是否模拟失败（5% 概率）
  bool _shouldSimulateFailure() {
    return DateTime.now().millisecond % 20 == 0;
  }

  /// 生成 mock 视频数据
  ///
  /// 与 polyv-vod 原型中的视频数据保持一致
  List<VideoItem> _generateMockVideos(VideoListRequest request) {
    // 模拟视频数据（参考 LongVideoPage.tsx）
    final mockVideos = [
      VideoItem(
        vid: 'e8888b0d3',
        title: '保利威企业宣传片',
        duration: 155, // 02:35
        thumbnail:
            'https://images.unsplash.com/photo-1611162617474-5b21e879e113?w=400&h=225&fit=crop',
        thumbnailHd:
            'https://images.unsplash.com/photo-1611162617474-5b21e879e113?w=800&h=450&fit=crop',
        views: '12.5万',
        updateTime: DateTime.now().subtract(const Duration(days: 7)),
        description: '保利威企业宣传片，展示公司核心产品和服务',
        tags: ['企业', '宣传'],
      ),
      VideoItem(
        vid: 'e8888b0d4',
        title: '云点播服务介绍',
        duration: 320, // 05:20
        thumbnail:
            'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=400&h=225&fit=crop',
        thumbnailHd:
            'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800&h=450&fit=crop',
        views: '8.2万',
        updateTime: DateTime.now().subtract(const Duration(days: 5)),
        description: '详细介绍保利威云点播服务的功能和优势',
        tags: ['产品', '介绍'],
      ),
      VideoItem(
        vid: 'e8888b0d5',
        title: '直播解决方案演示',
        duration: 495, // 08:15
        thumbnail:
            'https://images.unsplash.com/photo-1551434678-e076c223a692?w=400&h=225&fit=crop',
        thumbnailHd:
            'https://images.unsplash.com/photo-1551434678-e076c223a692?w=800&h=450&fit=crop',
        views: '5.6万',
        updateTime: DateTime.now().subtract(const Duration(days: 3)),
        description: '演示保利威直播解决方案的核心功能',
        tags: ['直播', '演示'],
      ),
      VideoItem(
        vid: 'e8888b0d6',
        title: '安全加密技术详解',
        duration: 760, // 12:40
        thumbnail:
            'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=400&h=225&fit=crop',
        thumbnailHd:
            'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=800&h=450&fit=crop',
        views: '3.8万',
        updateTime: DateTime.now().subtract(const Duration(days: 2)),
        description: '深入讲解保利威的安全加密技术和防护措施',
        tags: ['安全', '技术'],
      ),
      VideoItem(
        vid: 'e8888b0d7',
        title: 'API接入教程',
        duration: 930, // 15:30
        thumbnail:
            'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=400&h=225&fit=crop',
        thumbnailHd:
            'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800&h=450&fit=crop',
        views: '2.1万',
        updateTime: DateTime.now().subtract(const Duration(days: 1)),
        description: '详细讲解如何接入和使用保利威 API',
        tags: ['API', '教程'],
      ),
      VideoItem(
        vid: 'e8888b0d8',
        title: '数据分析平台使用指南',
        duration: 645, // 10:45
        thumbnail:
            'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=400&h=225&fit=crop',
        thumbnailHd:
            'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800&h=450&fit=crop',
        views: '4.3万',
        updateTime: DateTime.now(),
        description: '介绍如何使用数据分析平台进行业务分析',
        tags: ['数据', '分析'],
      ),
    ];

    // 应用关键词过滤
    var filteredVideos = mockVideos;
    if (request.keyword != null && request.keyword!.isNotEmpty) {
      final keyword = request.keyword!.toLowerCase();
      filteredVideos = filteredVideos
          .where(
            (v) =>
                v.title.toLowerCase().contains(keyword) ||
                (v.description?.toLowerCase().contains(keyword) ?? false),
          )
          .toList();
    }

    // 应用标签过滤
    if (request.tags != null && request.tags!.isNotEmpty) {
      filteredVideos = filteredVideos
          .where(
            (v) => v.tags?.any((tag) => request.tags!.contains(tag)) ?? false,
          )
          .toList();
    }

    // 应用排序
    if (request.orderBy != null) {
      switch (request.orderBy) {
        case 'updateTime':
          filteredVideos.sort((a, b) {
            final timeA = a.updateTime ?? DateTime(0);
            final timeB = b.updateTime ?? DateTime(0);
            return request.orderDirection == 'desc'
                ? timeB.compareTo(timeA)
                : timeA.compareTo(timeB);
          });
          break;
        case 'duration':
          filteredVideos.sort((a, b) {
            return request.orderDirection == 'desc'
                ? b.duration.compareTo(a.duration)
                : a.duration.compareTo(b.duration);
          });
          break;
        default:
          break;
      }
    }

    return filteredVideos;
  }
}

/// 真实视频列表服务（HTTP）
///
/// 调用 Polyv REST API 获取视频列表
/// 使用 VideoListApiClient 进行统一的 API 调用
class HttpVideoListService implements VideoListService {
  /// 视频列表 API 客户端
  final VideoListApiClient apiClient;

  /// 缓存的视频列表数据（key: cacheKey, value: 响应）
  final Map<String, VideoListResponse> _listCache = {};

  /// 缓存的单个视频信息（key: vid, value: 视频信息）
  final Map<String, _CachedVideoItem> _videoInfoCache = {};

  /// 缓存过期时间（毫秒）
  final int cacheExpiration;

  /// 缓存时间戳（key: cacheKey, value: 过期时间）
  final Map<String, int> _listCacheTimestamps = {};

  /// 视频信息缓存时间戳（key: vid, value: 过期时间）
  final Map<String, int> _videoInfoCacheTimestamps = {};

  /// 是否启用缓存
  final bool enableCache;

  HttpVideoListService({
    required String userId,
    required String readToken,
    required String secretKey,
    String baseUrl = 'https://api.polyv.net',
    http.Client? client,
    this.enableCache = true,
    this.cacheExpiration = 5 * 60 * 1000, // 5 分钟
  }) : apiClient = VideoListApiClient(
         userId: userId,
         readToken: readToken,
         secretKey: secretKey,
         baseUrl: baseUrl,
         client: client,
       );

  @override
  Future<VideoListResponse> fetchVideoList(VideoListRequest request) async {
    // 检查缓存
    final cacheKey = _buildCacheKey(request);
    if (enableCache && _listCache.containsKey(cacheKey)) {
      final timestamp = _listCacheTimestamps[cacheKey] ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // 检查缓存是否过期
      if (now - timestamp < cacheExpiration) {
        return _listCache[cacheKey]!;
      } else {
        // 删除过期缓存
        _listCache.remove(cacheKey);
        _listCacheTimestamps.remove(cacheKey);
      }
    }

    // 调用 API
    final response = await apiClient.fetchVideoList(request);

    // 缓存数据
    if (enableCache) {
      _listCache[cacheKey] = response;
      _listCacheTimestamps[cacheKey] = DateTime.now().millisecondsSinceEpoch;
    }

    return response;
  }

  @override
  Future<VideoItem> fetchVideoInfo(String vid) async {
    // 检查缓存
    if (enableCache && _videoInfoCache.containsKey(vid)) {
      final timestamp = _videoInfoCacheTimestamps[vid] ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - timestamp < cacheExpiration) {
        return _videoInfoCache[vid]!.video;
      } else {
        // 删除过期缓存
        _videoInfoCache.remove(vid);
        _videoInfoCacheTimestamps.remove(vid);
      }
    }

    // 调用 API
    final video = await apiClient.fetchVideoInfo(vid);

    // 缓存数据
    if (enableCache) {
      _videoInfoCache[vid] = _CachedVideoItem(video, DateTime.now());
      _videoInfoCacheTimestamps[vid] = DateTime.now().millisecondsSinceEpoch;
    }

    return video;
  }

  @override
  Future<void> clearCache() async {
    _listCache.clear();
    _listCacheTimestamps.clear();
    _videoInfoCache.clear();
    _videoInfoCacheTimestamps.clear();
  }

  /// 生成缓存键
  String _buildCacheKey(VideoListRequest request) {
    final buffer = StringBuffer()
      ..write('list_page=${request.page}')
      ..write('_pageSize=${request.pageSize}');
    if (request.orderBy != null) {
      buffer.write('_orderBy=${request.orderBy}');
      if (request.orderDirection != null) {
        buffer.write('_${request.orderDirection}');
      }
    }
    if (request.keyword != null) {
      buffer.write('_keyword=${request.keyword}');
    }
    if (request.tags != null && request.tags!.isNotEmpty) {
      buffer.write('_tags=${request.tags!.join(',')}');
    }
    return buffer.toString();
  }

  /// 关闭 API 客户端
  void dispose() {
    apiClient.dispose();
  }
}

/// 视频列表服务工厂
///
/// 用于创建不同类型的视频列表服务
class VideoListServiceFactory {
  /// 创建 Mock 服务
  static MockVideoListService createMock({
    bool enableCache = true,
    bool simulateDelay = true,
    bool simulateRandomFailure = false,
  }) {
    return MockVideoListService(
      enableCache: enableCache,
      simulateDelay: simulateDelay,
      simulateRandomFailure: simulateRandomFailure,
    );
  }

  /// 创建真实的 HTTP 服务
  ///
  /// [userId] Polyv 用户 ID
  /// [readToken] 读取令牌
  /// [secretKey] 密钥（用于签名）
  /// [baseUrl] API 基础 URL（可选）
  /// [enableCache] 是否启用缓存（可选）
  /// [cacheExpiration] 缓存过期时间（可选，默认 5 分钟）
  static HttpVideoListService createHttp({
    required String userId,
    required String readToken,
    required String secretKey,
    String baseUrl = 'https://api.polyv.net',
    bool enableCache = true,
    int cacheExpiration = 5 * 60 * 1000,
  }) {
    return HttpVideoListService(
      userId: userId,
      readToken: readToken,
      secretKey: secretKey,
      baseUrl: baseUrl,
      enableCache: enableCache,
      cacheExpiration: cacheExpiration,
    );
  }

  /// 从 PlayerConfig 创建服务
  ///
  /// [config] 播放器配置
  /// [useHttp] 是否使用 HTTP 服务（默认 false，使用 Mock）
  /// [enableCache] 是否启用缓存（可选）
  static VideoListService fromConfig(
    PlayerConfig config, {
    bool useHttp = false,
    bool enableCache = true,
  }) {
    if (useHttp) {
      return createHttp(
        userId: config.userId,
        readToken: config.readToken,
        secretKey: config.secretKey,
        enableCache: enableCache,
      );
    } else {
      return createMock(enableCache: enableCache);
    }
  }
}

/// 缓存的视频信息包装类
///
/// 用于存储视频信息和缓存时间
class _CachedVideoItem {
  /// 视频信息
  final VideoItem video;

  /// 缓存时间
  final DateTime cachedAt;

  _CachedVideoItem(this.video, this.cachedAt);
}
