/// 视频列表数据模型
///
/// 对应 Web 原型 LongVideoPage.tsx 和 VideoListItem.tsx 中的 Video 接口
/// 参考: /Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/VideoListItem.tsx
///
/// 视频项模型
///
/// 包含视频列表中单个视频的核心属性
/// 与 polyv-vod 原型中的 Video 接口保持一致
class VideoItem {
  /// 视频 ID（vid）
  final String vid;

  /// 视频标题
  final String title;

  /// 视频时长（秒）
  final int duration;

  /// 视频时长格式化字符串（MM:SS 或 HH:MM:SS）
  String get durationFormatted => _formatDuration(duration);

  /// 缩略图 URL（第一帧截图）
  final String thumbnail;

  /// 高清缩略图 URL（可选）
  final String? thumbnailHd;

  /// 播放次数（可选）
  final String? views;

  /// 更新时间（可选，用于排序）
  final DateTime? updateTime;

  /// 视频简介（可选）
  final String? description;

  /// 视频标签（可选）
  final List<String>? tags;

  const VideoItem({
    required this.vid,
    required this.title,
    required this.duration,
    required this.thumbnail,
    this.thumbnailHd,
    this.views,
    this.updateTime,
    this.description,
    this.tags,
  });

  /// 从 JSON 创建 VideoItem
  ///
  /// 支持多种 API 响应格式：
  /// - Polyv REST API 标准格式
  /// - 自定义格式
  factory VideoItem.fromJson(Map<String, dynamic> json) {
    // 提取 vid（支持多种字段名）
    final vid =
        json['vid'] as String? ??
        json['videoId'] as String? ??
        json['id'] as String? ??
        '';

    // 提取标题（支持多种字段名）
    final title =
        json['title'] as String? ??
        json['videoName'] as String? ??
        json['name'] as String? ??
        '';

    // 提取时长（支持多种格式）
    // - 整数（秒）
    // - 字符串 "HH:MM:SS" 或 "MM:SS" 格式（Polyv API 返回格式）
    final duration = _parseDuration(json['duration']);

    // 提取缩略图 - 支持更多可能的字段名（包括下划线格式）
    final thumbnail =
        json['thumbnail'] as String? ??
        json['cover'] as String? ??
        json['imageUrl'] as String? ??
        json['firstImage'] as String? ??
        json['first_image'] as String? ?? // Polyv API 返回的字段名
        json['image'] as String? ??
        json['pic'] as String? ??
        json['snapshot'] as String? ??
        json['wxheadurl'] as String? ??
        '';

    // 提取播放次数
    final views =
        json['views'] as String? ??
        json['times'] as String? ??
        _formatViewCount(
          json['playCount'] as int? ?? json['plays'] as int? ?? 0,
        );

    // 提取更新时间
    // 支持多种格式：
    // - ISO 8601 字符串 (如 "2024-01-15T10:30:00Z")
    // - Unix 时间戳（秒，如 1705307400）
    // - Unix 时间戳（毫秒，如 1705307400000）
    DateTime? updateTime;
    final updateTimeVal =
        json['updateTime'] ?? json['modified'] ?? json['time'];
    if (updateTimeVal != null) {
      updateTime = _parseDateTime(updateTimeVal);
    }

    // 提取标签
    final tags = json['tags'] as List<dynamic>?;
    final tagsList = tags?.map((e) => e.toString()).toList();

    return VideoItem(
      vid: vid,
      title: title,
      duration: duration,
      thumbnail: thumbnail,
      thumbnailHd: json['thumbnailHd'] as String? ?? json['coverHd'] as String?,
      views: views,
      updateTime: updateTime,
      description: json['description'] as String?,
      tags: tagsList,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'vid': vid,
      'title': title,
      'duration': duration,
      'thumbnail': thumbnail,
    };
    if (thumbnailHd != null) json['thumbnailHd'] = thumbnailHd;
    if (views != null) json['views'] = views;
    if (updateTime != null) json['updateTime'] = updateTime!.toIso8601String();
    if (description != null) json['description'] = description;
    if (tags != null) json['tags'] = tags;
    return json;
  }

  /// 格式化时长为 MM:SS 或 HH:MM:SS
  static String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// 解析时长（支持多种格式）
  ///
  /// 支持格式：
  /// - 整数（秒）
  /// - 字符串 "HH:MM:SS" 或 "MM:SS" 格式（Polyv API 返回格式）
  static int _parseDuration(dynamic value) {
    if (value == null) return 0;

    // 如果是整数，直接返回
    if (value is int) {
      return value;
    }

    // 如果是字符串，尝试解析
    if (value is String) {
      final str = value.toString().trim();

      // 尝试直接解析为整数（秒）
      final asInt = int.tryParse(str);
      if (asInt != null) return asInt;

      // 解析 "HH:MM:SS" 或 "MM:SS" 格式
      final parts = str.split(':');
      if (parts.length == 2) {
        // MM:SS 格式
        final m = int.tryParse(parts[0]) ?? 0;
        final s = int.tryParse(parts[1]) ?? 0;
        return m * 60 + s;
      } else if (parts.length == 3) {
        // HH:MM:SS 格式
        final h = int.tryParse(parts[0]) ?? 0;
        final m = int.tryParse(parts[1]) ?? 0;
        final s = int.tryParse(parts[2]) ?? 0;
        return h * 3600 + m * 60 + s;
      }
    }

    // 如果是 double，取整后返回
    if (value is double) {
      return value.toInt();
    }

    return 0;
  }

  /// 解析多种时间格式为 DateTime
  ///
  /// 支持格式：
  /// - ISO 8601 字符串 (如 "2024-01-15T10:30:00Z")
  /// - Unix 时间戳（秒，如 1705307400）
  /// - Unix 时间戳（毫秒，如 1705307400000）
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    // 字符串格式 - 尝试 ISO 8601 解析
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        // ISO 解析失败，可能不是标准格式
      }
    }

    // 数值格式 - 尝试 Unix 时间戳
    int? timestamp;
    if (value is int) {
      timestamp = value;
    } else if (value is double) {
      timestamp = value.toInt();
    } else if (value is String) {
      timestamp = int.tryParse(value);
    }

    if (timestamp != null) {
      // 判断是秒还是毫秒
      // 毫秒时间戳通常大于 10 位（10000000000 = 2286-11-20）
      if (timestamp > 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      }
    }

    return null;
  }

  /// 格式化播放次数
  static String _formatViewCount(int count) {
    if (count < 10000) {
      return count.toString();
    } else if (count < 100000000) {
      final w = count / 10000;
      final wStr = w.toStringAsFixed(1);
      return '${wStr.replaceAll('.0', '')}万';
    } else {
      final yi = count / 100000000;
      final yiStr = yi.toStringAsFixed(1);
      return '${yiStr.replaceAll('.0', '')}亿';
    }
  }

  /// 创建副本并修改部分属性
  VideoItem copyWith({
    String? vid,
    String? title,
    int? duration,
    String? thumbnail,
    String? thumbnailHd,
    String? views,
    DateTime? updateTime,
    String? description,
    List<String>? tags,
  }) {
    return VideoItem(
      vid: vid ?? this.vid,
      title: title ?? this.title,
      duration: duration ?? this.duration,
      thumbnail: thumbnail ?? this.thumbnail,
      thumbnailHd: thumbnailHd ?? this.thumbnailHd,
      views: views ?? this.views,
      updateTime: updateTime ?? this.updateTime,
      description: description ?? this.description,
      tags: tags ?? this.tags,
    );
  }

  @override
  String toString() {
    return 'VideoItem(vid: $vid, title: $title, duration: $durationFormatted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoItem && other.vid == vid;
  }

  @override
  int get hashCode => vid.hashCode;
}

/// 视频列表响应模型
///
/// 封装视频列表 API 的响应数据
class VideoListResponse {
  /// 视频列表
  final List<VideoItem> videos;

  /// 当前页码（从 1 开始）
  final int page;

  /// 每页数量
  final int pageSize;

  /// 总记录数
  final int total;

  /// 总页数
  int get totalPages => (total / pageSize).ceil();

  /// 是否有下一页
  bool get hasNextPage => page < totalPages;

  /// 是否有上一页
  bool get hasPreviousPage => page > 1;

  const VideoListResponse({
    required this.videos,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  /// 空响应
  static const empty = VideoListResponse(
    videos: [],
    page: 1,
    pageSize: 20,
    total: 0,
  );

  /// 从 JSON 创建 VideoListResponse
  ///
  /// 支持多种 API 响应格式：
  /// - Polyv REST API 标准格式
  /// - 自定义分页格式
  factory VideoListResponse.fromJson(Map<String, dynamic> json) {
    // 提取视频列表
    final dataList =
        json['data'] as List<dynamic>? ??
        json['videos'] as List<dynamic>? ??
        json['list'] as List<dynamic>? ??
        [];

    final videos = dataList
        .map((item) => VideoItem.fromJson(item as Map<String, dynamic>))
        .toList();

    // 提取分页信息
    final page = json['page'] as int? ?? json['pageNum'] as int? ?? 1;
    final pageSize =
        json['pageSize'] as int? ??
        json['perPage'] as int? ??
        json['limit'] as int? ??
        20;
    final total =
        json['total'] as int? ?? json['count'] as int? ?? videos.length;

    return VideoListResponse(
      videos: videos,
      page: page,
      pageSize: pageSize,
      total: total,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'data': videos.map((v) => v.toJson()).toList(),
      'page': page,
      'pageSize': pageSize,
      'total': total,
    };
  }

  /// 创建下一页的响应（预加载用）
  VideoListResponse nextPage(List<VideoItem> moreVideos) {
    return VideoListResponse(
      videos: [...videos, ...moreVideos],
      page: page + 1,
      pageSize: pageSize,
      total: total,
    );
  }

  @override
  String toString() {
    return 'VideoListResponse(page: $page/$totalPages, videos: ${videos.length}/$total)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoListResponse &&
        other.page == page &&
        other.pageSize == pageSize &&
        other.total == total &&
        _listEquals(other.videos, videos);
  }

  @override
  int get hashCode => Object.hash(page, pageSize, total, videos.hashCode);

  /// 比较两个列表是否相等
  bool _listEquals(List<VideoItem> a, List<VideoItem> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// 视频列表请求参数
///
/// 封装获取视频列表的请求参数
class VideoListRequest {
  /// 页码（从 1 开始）
  final int page;

  /// 每页数量（默认 20）
  final int pageSize;

  /// 排序字段（可选）：updateTime, duration, views
  final String? orderBy;

  /// 排序方向（可选）：asc, desc
  final String? orderDirection;

  /// 搜索关键词（可选）
  final String? keyword;

  /// 标签过滤（可选）
  final List<String>? tags;

  const VideoListRequest({
    this.page = 1,
    this.pageSize = 20,
    this.orderBy,
    this.orderDirection,
    this.keyword,
    this.tags,
  });

  /// 转换为查询参数
  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (orderBy != null) params['orderBy'] = orderBy;
    if (orderDirection != null) params['orderDirection'] = orderDirection;
    if (keyword != null && keyword!.isNotEmpty) params['keyword'] = keyword;
    if (tags != null && tags!.isNotEmpty) params['tags'] = tags!.join(',');
    return params;
  }

  /// 创建下一页请求
  VideoListRequest nextPage() {
    return VideoListRequest(
      page: page + 1,
      pageSize: pageSize,
      orderBy: orderBy,
      orderDirection: orderDirection,
      keyword: keyword,
      tags: tags,
    );
  }

  /// 创建副本并修改部分属性
  VideoListRequest copyWith({
    int? page,
    int? pageSize,
    String? orderBy,
    String? orderDirection,
    String? keyword,
    List<String>? tags,
  }) {
    return VideoListRequest(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      orderBy: orderBy ?? this.orderBy,
      orderDirection: orderDirection ?? this.orderDirection,
      keyword: keyword ?? this.keyword,
      tags: tags ?? this.tags,
    );
  }

  @override
  String toString() {
    return 'VideoListRequest(page: $page, pageSize: $pageSize)';
  }
}
