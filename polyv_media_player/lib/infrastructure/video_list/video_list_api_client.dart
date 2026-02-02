import 'package:http/http.dart' as http;

import '../polyv_api_client.dart';
import 'video_list_models.dart';
import 'video_list_exception.dart';

/// 视频列表 API 客户端
///
/// 封装 Polyv REST API 的视频列表相关接口
/// 使用 Flutter 层统一实现签名、分页、错误分类等业务逻辑
///
/// 架构说明：
/// - 视频列表获取的业务逻辑统一在 Flutter(Dart) 层实现
/// - 原生层不直接访问 Polyv REST API 或维护视频列表业务状态
/// - 原生层仅作为 SDK 与后端之间的桥接
class VideoListApiClient {
  /// Polyv 用户 ID
  final String userId;

  /// Polyv API 客户端
  final PolyvApiClient apiClient;

  /// API 基础 URL
  final String baseUrl;

  /// HTTP 客户端
  final http.Client _client;

  /// 创建视频列表 API 客户端
  ///
  /// [userId] Polyv 用户 ID
  /// [readToken] 读取令牌
  /// [secretKey] 密钥（用于签名）
  /// [baseUrl] API 基础 URL（可选）
  /// [client] HTTP 客户端（可选，用于测试）
  VideoListApiClient({
    required this.userId,
    required String readToken,
    required String secretKey,
    this.baseUrl = 'https://api.polyv.net',
    http.Client? client,
  }) : apiClient = PolyvApiClient(
         userId: userId,
         readToken: readToken,
         writeToken: '', // 获取视频列表不需要 writeToken
         secretKey: secretKey,
         baseUrl: baseUrl,
         client: client,
       ),
       _client = client ?? http.Client();

  /// 获取视频列表
  ///
  /// [request] 请求参数（分页、排序、搜索等）
  ///
  /// 返回视频列表响应
  ///
  /// 抛出 [VideoListException] 当请求失败时
  ///
  /// API 端点: /v2/video/{userId}/list (参考 iOS PLVVodMediaVideoNetwork)
  Future<VideoListResponse> fetchVideoList(VideoListRequest request) async {
    try {
      // 构建请求参数 - 使用 Polyv API 要求的参数名
      // 注意：Polyv API 使用 pageNum 和 numPerPage，而不是 page 和 pageSize
      final params = <String, dynamic>{
        'pageNum': request.page,
        'numPerPage': request.pageSize,
      };
      if (request.orderBy != null) {
        params['orderBy'] = request.orderBy;
      }
      if (request.orderDirection != null) {
        params['orderDirection'] = request.orderDirection;
      }
      if (request.keyword != null && request.keyword!.isNotEmpty) {
        params['keyword'] = request.keyword;
      }
      if (request.tags != null && request.tags!.isNotEmpty) {
        params['tags'] = request.tags!.join(',');
      }

      // 调用 API - 使用正确的端点格式 /v2/video/{userId}/list
      // 注意：视频列表 API 使用 ptime 而不是 timestamp，且不需要 readtoken
      final response = await apiClient.get(
        '/v2/video/$userId/list',
        params: params,
        useReadToken: false,
        usePtime: true,
      );

      if (!response.success) {
        throw VideoListException(
          type: _mapApiErrorType(response.statusCode),
          message: response.error ?? '获取视频列表失败',
          statusCode: response.statusCode,
        );
      }

      // 解析响应数据
      final dataList = response.data;
      if (dataList == null || dataList.isEmpty) {
        return VideoListResponse(
          videos: [],
          page: request.page,
          pageSize: request.pageSize,
          total: 0,
        );
      }

      // 转换为 VideoItem 模型
      final videos = dataList
          .map((item) => VideoItem.fromJson(item as Map<String, dynamic>))
          .toList();

      // 计算总数：
      // - 如果返回的视频数少于 pageSize，说明这是最后一页
      // - 否则可能还有更多数据，使用估算值
      final int total;
      if (videos.length < request.pageSize) {
        // 最后一页，精确计算总数
        total = (request.page - 1) * request.pageSize + videos.length;
      } else {
        // 当前页已满，可能还有更多数据
        // 注意：真实总数需要 API 返回，这里使用保守估算
        total = request.page * request.pageSize;
      }

      return VideoListResponse(
        videos: videos,
        page: request.page,
        pageSize: request.pageSize,
        total: total,
      );
    } on VideoListException {
      rethrow;
    } on PolyvApiException catch (e) {
      throw VideoListException(
        type: _mapApiErrorType(e.statusCode),
        message: e.message,
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      throw VideoListException.fromError(e);
    }
  }

  /// 获取单个视频信息
  ///
  /// [vid] 视频 ID
  ///
  /// 返回视频信息
  ///
  /// 抛出 [VideoListException] 当请求失败时
  Future<VideoItem> fetchVideoInfo(String vid) async {
    try {
      // 构建请求参数
      final params = <String, dynamic>{'vid': vid};

      // 调用 API
      final response = await apiClient.get(
        '/v2/video/info',
        params: params,
        useReadToken: true,
      );

      if (!response.success) {
        throw VideoListException(
          type: _mapApiErrorType(response.statusCode),
          message: response.error ?? '获取视频信息失败',
          statusCode: response.statusCode,
        );
      }

      // 解析响应数据
      final data = response.data;
      if (data == null || data.isEmpty) {
        throw VideoListException.parameter(detail: '视频不存在: $vid');
      }

      // 转换为 VideoItem 模型
      return VideoItem.fromJson(data.first as Map<String, dynamic>);
    } on VideoListException {
      rethrow;
    } on PolyvApiException catch (e) {
      throw VideoListException(
        type: _mapApiErrorType(e.statusCode),
        message: e.message,
        statusCode: e.statusCode,
        originalError: e,
      );
    } catch (e) {
      throw VideoListException.fromError(e);
    }
  }

  /// 将 API 错误类型映射为视频列表错误类型
  VideoListErrorType _mapApiErrorType(int? statusCode) {
    if (statusCode == null) return VideoListErrorType.unknown;

    switch (statusCode) {
      case 401:
      case 403:
        return VideoListErrorType.auth;
      case 404:
        return VideoListErrorType.parameter;
      case 400:
        return VideoListErrorType.parameter;
      case 500:
      case 502:
      case 503:
        return VideoListErrorType.server;
      default:
        if (statusCode >= 500 && statusCode < 600) {
          return VideoListErrorType.server;
        }
        if (statusCode >= 400 && statusCode < 500) {
          return VideoListErrorType.parameter;
        }
        return VideoListErrorType.network;
    }
  }

  /// 关闭 HTTP 客户端
  void dispose() {
    _client.close();
    apiClient.dispose();
  }
}
