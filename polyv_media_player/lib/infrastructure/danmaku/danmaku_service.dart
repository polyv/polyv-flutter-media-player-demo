import 'package:flutter/material.dart';

import '../polyv_api_client.dart';
import 'danmaku_model.dart';

/// 弹幕服务接口
///
/// 负责从 Polyv 弹幕 API 或其他数据源获取弹幕数据
/// 以及发送弹幕到服务器
///
/// 架构说明：
/// - 弹幕数据统一在 Flutter(Dart) 层获取和缓存
/// - 原生层不直接实现弹幕 HTTP / Repo 业务逻辑
/// - iOS/Android 只提供播放核心能力（当前播放时间、播放状态等）
abstract class DanmakuService {
  /// 获取指定视频的弹幕列表
  ///
  /// [vid] 视频 ID
  /// [limit] 限制返回数量（可选）
  /// [offset] 偏移量（可选）
  ///
  /// 返回按时间排序的弹幕列表
  Future<List<Danmaku>> fetchDanmakus(String vid, {int? limit, int? offset});

  /// 清除缓存（如果有）
  Future<void> clearCache();
}

/// 弹幕发送服务接口
///
/// 负责将弹幕发送到后端服务器
/// 所有业务校验和节流逻辑在 Flutter 层统一实现
abstract class DanmakuSendService {
  /// 发送弹幕
  ///
  /// [request] 发送请求，包含 vid、text、time、color 等参数
  ///
  /// 返回发送响应，包含后端生成的弹幕 ID
  ///
  /// 抛出 [DanmakuSendException] 当发送失败时
  Future<DanmakuSendResponse> sendDanmaku(DanmakuSendRequest request);

  /// 校验弹幕文本是否合法
  ///
  /// [text] 待校验的文本
  ///
  /// 返回校验结果，如果非法则返回错误消息
  String? validateText(String text);

  /// 获取最小发送间隔（毫秒）
  ///
  /// 用于防止用户发送过于频繁
  int get minSendInterval;

  /// 检查是否允许发送（基于节流策略）
  ///
  /// [lastSendTime] 上次发送时间（毫秒）
  ///
  /// 返回是否允许发送
  bool canSend(int? lastSendTime);

  /// 重置节流状态（用于测试或用户主动操作）
  void resetThrottle();
}

/// 弹幕发送配置
///
/// 定义发送相关的业务规则
class DanmakuSendConfig {
  /// 最小文本长度
  final int minTextLength;

  /// 最大文本长度
  final int maxTextLength;

  /// 最小发送间隔（毫秒）
  final int minSendInterval;

  /// 允许的颜色列表（空表示不限制）
  final List<String> allowedColors;

  /// 默认配置
  factory DanmakuSendConfig.defaultConfig() => DanmakuSendConfig(
    minTextLength: 1,
    maxTextLength: 100,
    minSendInterval: 2000, // 2秒
    allowedColors: const [
      '#ffffff',
      '#fe0302',
      '#ff7204',
      '#ffaa02',
      '#ffd302',
      '#00cd00',
      '#00a2ff',
      '#cc0273',
    ],
  );

  const DanmakuSendConfig({
    this.minTextLength = 1,
    this.maxTextLength = 100,
    this.minSendInterval = 2000,
    this.allowedColors = const [],
  });

  /// 校验颜色是否允许
  bool isColorAllowed(String color) {
    if (allowedColors.isEmpty) return true;
    return allowedColors.contains(color.toLowerCase());
  }
}

/// Mock 弹幕服务实现
///
/// 用于测试和开发，返回预设的弹幕数据
/// 后续可替换为真实的 Polyv API 实现
class MockDanmakuService implements DanmakuService {
  /// 缓存的弹幕数据（key: vid, value: 弹幕列表）
  final Map<String, List<Danmaku>> _cache = {};

  /// 是否启用缓存
  final bool enableCache;

  MockDanmakuService({this.enableCache = true});

  @override
  Future<List<Danmaku>> fetchDanmakus(
    String vid, {
    int? limit,
    int? offset,
  }) async {
    // 如果启用缓存且已有数据，直接返回
    if (enableCache && _cache.containsKey(vid)) {
      var danmakus = _cache[vid]!;
      if (limit != null) {
        danmakus = danmakus.take(limit).toList();
      }
      if (offset != null && offset > 0) {
        danmakus = danmakus.skip(offset).toList();
      }
      return danmakus;
    }

    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 100));

    // 生成 mock 数据
    final danmakus = _generateMockDanmakus(vid);

    // 缓存数据
    if (enableCache) {
      _cache[vid] = danmakus;
    }

    // 应用 limit 和 offset
    var result = danmakus;
    if (limit != null) {
      result = result.take(limit).toList();
    }
    if (offset != null && offset > 0) {
      result = result.skip(offset).toList();
    }

    return result;
  }

  @override
  Future<void> clearCache() async {
    _cache.clear();
  }

  /// 生成 mock 弹幕数据
  ///
  /// 根据不同的 VID 生成不同的弹幕数据
  /// 使用混合方式：
  /// 1. 固定场景弹幕：在特定时间点生成有意义的弹幕
  /// 2. 常规弹幕：按固定间隔生成（每 2 秒）
  List<Danmaku> _generateMockDanmakus(String vid) {
    final danmakus = <Danmaku>[];
    int counter = 0; // 局部计数器，确保同一 VID 生成相同 ID

    // 辅助函数：添加一条固定弹幕
    void addDanmaku(int time, String text, [DanmakuType? type, Color? color]) {
      danmakus.add(
        Danmaku(
          id: '${vid}_$counter',
          text: text,
          time: time,
          color: color,
          type: type ?? DanmakuType.scroll,
        ),
      );
      counter++;
    }

    // ============ 固定场景弹幕 ============
    // 这些弹幕在固定时间点出现，方便测试 seek 功能

    // 0-5秒：开场欢迎
    addDanmaku(500, '我来啦！', null, const Color(0xFFFF6B6B));
    addDanmaku(1000, '打卡！', null, const Color(0xFF4ECDC4));
    addDanmaku(2000, '前排围观');
    addDanmaku(3000, '期待！');
    addDanmaku(4000, '老师来了', DanmakuType.top, const Color(0xFFFFE66D));
    addDanmaku(5000, '开始上课了');

    // 10秒：第一个知识点
    addDanmaku(10000, '这个重点！', DanmakuType.top, const Color(0xFFFF6B6B));
    addDanmaku(10200, '记下来记下来');
    addDanmaku(10500, '考试要考', null, const Color(0xFFFFE66D));

    // 15秒：高能预警
    addDanmaku(15000, '前方高能！', DanmakuType.top, const Color(0xFFFF6B6B));
    addDanmaku(15100, '高能预警！', DanmakuType.top, const Color(0xFFFF6B6B));
    addDanmaku(15200, '注意看！', DanmakuType.top, const Color(0xFFFF6B6B));

    // 20秒：精彩时刻
    addDanmaku(20000, '哇哦');
    addDanmaku(20100, '厉害了', null, const Color(0xFF4ECDC4));
    addDanmaku(20300, '学到了');
    addDanmaku(20500, '这个方法好');

    // 30秒：中间总结
    addDanmaku(30000, '到这里为止...', DanmakuType.bottom, const Color(0xFFFFE66D));
    addDanmaku(30200, '总结一下', DanmakuType.bottom, const Color(0xFFFFE66D));
    addDanmaku(30500, '懂了懂了');

    // 40秒：又一个重点
    addDanmaku(40000, '关键在这里', DanmakuType.top, const Color(0xFFFF6B6B));
    addDanmaku(40200, '重点来了');
    addDanmaku(40500, '仔细听');

    // 50秒：接近结尾
    addDanmaku(50000, '这就结束了？');
    addDanmaku(50200, '还没看够', null, const Color(0xFF95E1D3));
    addDanmaku(50500, '期待下一期');

    // 59秒：结尾
    addDanmaku(59000, '感谢老师！', DanmakuType.bottom, const Color(0xFFFF6B6B));
    addDanmaku(59200, '一键三连', DanmakuType.bottom, const Color(0xFFFFE66D));
    addDanmaku(59500, '已收藏');
    addDanmaku(59800, '下次见', DanmakuType.bottom);

    // ============ 常规弹幕 ============
    // 每 2 秒生成一些常规弹幕，模拟真实弹幕流
    const regularTexts = [
      '666',
      '不错',
      '厉害',
      '好看',
      '赞',
      '棒',
      '哈哈',
      '666666',
      '👍',
      '👏',
      '不错哦',
      '可以',
    ];

    final regularColors = [
      null,
      null,
      null,
      const Color(0xFF4ECDC4),
      const Color(0xFF95E1D3),
    ];

    int regularIndex = 0;
    for (int time = 0; time <= 58000; time += 2000) {
      // 每个时间点添加 1-3 条常规弹幕
      final count = (time % 6000 == 0) ? 3 : 1;

      for (int i = 0; i < count; i++) {
        final textIndex = regularIndex % regularTexts.length;
        final colorIndex = regularIndex % regularColors.length;
        regularIndex++;

        // 错开时间，避免完全重叠
        final offset = i * 100;
        addDanmaku(
          time + offset,
          regularTexts[textIndex],
          null,
          regularColors[colorIndex],
        );
      }
    }

    // 按时间排序
    danmakus.sort((a, b) => a.time.compareTo(b.time));

    return danmakus;
  }
}

/// 真实弹幕服务（HTTP）
///
/// 调用 Polyv 弹幕 API 获取历史弹幕列表
/// 使用 PolyvApiClient 进行统一的 API 调用
class HttpDanmakuService implements DanmakuService {
  /// Polyv API 客户端
  final PolyvApiClient apiClient;

  /// 缓存的弹幕数据（key: vid, value: 弹幕列表）
  final Map<String, List<Danmaku>> _cache = {};

  /// 是否启用缓存
  final bool enableCache;

  HttpDanmakuService({required this.apiClient, this.enableCache = true});

  @override
  Future<List<Danmaku>> fetchDanmakus(
    String vid, {
    int? limit,
    int? offset,
  }) async {
    // 如果启用缓存且已有数据，直接返回
    if (enableCache && _cache.containsKey(vid)) {
      var danmakus = _cache[vid]!;
      if (limit != null) {
        danmakus = danmakus.take(limit).toList();
      }
      if (offset != null && offset > 0) {
        danmakus = danmakus.skip(offset).toList();
      }
      return danmakus;
    }

    try {
      // 构建请求参数
      final params = <String, dynamic>{'vid': vid};
      if (limit != null) {
        params['limit'] = limit;
      }

      // 调用 API
      final response = await apiClient.get('/v2/danmu', params: params);

      if (!response.success) {
        throw DanmakuFetchException(
          type: _mapApiErrorType(response.statusCode),
          message: response.error ?? '获取弹幕失败',
        );
      }

      // 解析响应数据
      final dataList = response.data;
      if (dataList == null) {
        return [];
      }

      // 转换为 Danmaku 模型
      final danmakus = dataList.map((item) {
        return _parseDanmakuFromApi(vid, item as Map<String, dynamic>);
      }).toList();

      // 数据清洗：去重（基于 id）和时间排序
      final uniqueDanmakus = _deduplicateAndSort(danmakus);

      // 缓存数据（缓存完整数据）
      if (enableCache) {
        _cache[vid] = uniqueDanmakus;
      }

      // 应用 limit 和 offset 到结果
      var result = uniqueDanmakus;
      if (limit != null) {
        result = result.take(limit).toList();
      }
      if (offset != null && offset > 0) {
        result = result.skip(offset).toList();
      }

      return result;
    } on PolyvApiException catch (e) {
      throw DanmakuFetchException(
        type: _mapApiErrorType(e.statusCode),
        message: e.message,
      );
    } on DanmakuFetchException {
      rethrow;
    } catch (e) {
      throw DanmakuFetchException(
        type: DanmakuFetchErrorType.unknown,
        message: '获取弹幕失败: $e',
      );
    }
  }

  @override
  Future<void> clearCache() async {
    _cache.clear();
  }

  /// 从 API 响应解析弹幕数据
  Danmaku _parseDanmakuFromApi(String vid, Map<String, dynamic> item) {
    // 解析时间 (HH:MM:SS -> 毫秒)
    final timeStr = item['time'] as String? ?? '00:00:00';
    final time = PolyvApiClient.timeStrToMilliseconds(timeStr);

    // 解析颜色 (0xRRGGBB -> Color)
    final colorStr = item['fontColor'] as String? ?? '0xffffff';
    final colorInt = PolyvApiClient.parseColorInt(colorStr);

    // 解析类型 (fontMode -> DanmakuType)
    final fontMode = item['fontMode'] as String? ?? 'roll';
    final type = _parseDanmakuType(fontMode);

    // 生成唯一 ID
    final id = '${vid}_${timeStr}_${item['msg']?.hashCode ?? 0}';

    return Danmaku(
      id: id,
      text: item['msg'] as String? ?? '',
      time: time,
      color: Color(0xFF000000 | colorInt),
      type: type,
    );
  }

  /// 解析弹幕类型
  DanmakuType _parseDanmakuType(String fontMode) {
    switch (fontMode.toLowerCase()) {
      case 'top':
        return DanmakuType.top;
      case 'bottom':
        return DanmakuType.bottom;
      case 'roll':
      case 'scroll':
      default:
        return DanmakuType.scroll;
    }
  }

  /// 数据清洗：去重并按时间排序
  ///
  /// 1. 去重：基于 id 移除重复弹幕
  /// 2. 排序：按时间升序排列
  List<Danmaku> _deduplicateAndSort(List<Danmaku> danmakus) {
    if (danmakus.isEmpty) return danmakus;

    // 使用 Set 去重（基于 id）
    final uniqueMap = <String, Danmaku>{};
    for (final danmaku in danmakus) {
      // 如果有重复 id，保留第一个（通常时间更早的）
      uniqueMap.putIfAbsent(danmaku.id, () => danmaku);
    }

    // 转换回列表并按时间排序
    final uniqueDanmakus = uniqueMap.values.toList();
    uniqueDanmakus.sort((a, b) => a.time.compareTo(b.time));

    return uniqueDanmakus;
  }

  /// 将 API 错误类型映射为弹幕获取错误类型
  DanmakuFetchErrorType _mapApiErrorType(int? statusCode) {
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

/// 弹幕获取错误类型
///
/// 语义化错误分类，用于 UI 展示不同的错误提示
enum DanmakuFetchErrorType {
  /// 网络错误 - 连接失败、超时等
  network,

  /// 认证错误 - 签名错误、token 过期等
  auth,

  /// 服务器错误 - 后端返回错误
  server,

  /// 资源未找到
  notFound,

  /// 未知错误
  unknown,
}

/// 弹幕获取错误
///
/// 包含错误类型和用户友好的错误消息
class DanmakuFetchException implements Exception {
  /// 错误类型
  final DanmakuFetchErrorType type;

  /// 错误消息（用户友好）
  final String message;

  const DanmakuFetchException({required this.type, required this.message});

  @override
  String toString() => 'DanmakuFetchException($type: $message)';
}

/// 弹幕服务工厂
///
/// 用于创建不同类型的弹幕服务
class DanmakuServiceFactory {
  /// 创建 Mock 弹幕服务
  static MockDanmakuService createMock({bool enableCache = true}) {
    return MockDanmakuService(enableCache: enableCache);
  }

  /// 创建真实的 HTTP 弹幕服务
  ///
  /// [userId] Polyv 用户 ID
  /// [readToken] 读取令牌
  /// [secretKey] 密钥（用于签名）
  static HttpDanmakuService createHttp({
    required String userId,
    required String readToken,
    required String secretKey,
    bool enableCache = true,
  }) {
    final apiClient = PolyvApiClient(
      userId: userId,
      readToken: readToken,
      writeToken: '', // 获取弹幕不需要 writeToken
      secretKey: secretKey,
    );

    return HttpDanmakuService(apiClient: apiClient, enableCache: enableCache);
  }
}

/// Mock 弹幕发送服务实现
///
/// 用于测试和开发，模拟发送弹幕到服务器
/// 后续可替换为真实的 Polyv API 实现
class MockDanmakuSendService implements DanmakuSendService {
  /// 发送配置
  final DanmakuSendConfig config;

  /// 上次发送时间（毫秒）
  int? _lastSendTime;

  /// 生成的弹幕计数器
  int _danmakuCounter = 0;

  /// 是否模拟网络延迟
  final bool simulateDelay;

  /// 是否模拟随机失败（用于测试错误处理）
  final bool simulateRandomFailure;

  MockDanmakuSendService({
    this.config = const DanmakuSendConfig(),
    this.simulateDelay = true,
    this.simulateRandomFailure = false,
  });

  @override
  int get minSendInterval => config.minSendInterval;

  @override
  String? validateText(String text) {
    final trimmed = text.trim();

    // 检查是否为空
    if (trimmed.isEmpty) {
      return '弹幕内容不能为空';
    }

    // 检查最小长度
    if (trimmed.length < config.minTextLength) {
      return '弹幕内容至少需要 ${config.minTextLength} 个字符';
    }

    // 检查最大长度
    if (trimmed.length > config.maxTextLength) {
      return '弹幕内容不能超过 ${config.maxTextLength} 个字符';
    }

    // 检查是否包含非法字符（示例：只允许中文、英文、数字、常用标点）
    // 简化校验：不允许控制字符
    for (int i = 0; i < trimmed.length; i++) {
      final codeUnit = trimmed.codeUnitAt(i);
      if (codeUnit < 32 && codeUnit != 10 && codeUnit != 13) {
        return '弹幕内容包含非法字符';
      }
    }

    return null; // 校验通过
  }

  @override
  bool canSend(int? lastSendTime) {
    if (lastSendTime == null) return true;

    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - lastSendTime) >= config.minSendInterval;
  }

  @override
  void resetThrottle() {
    _lastSendTime = null;
  }

  @override
  Future<DanmakuSendResponse> sendDanmaku(DanmakuSendRequest request) async {
    // 先校验文本
    final validationError = validateText(request.text);
    if (validationError != null) {
      throw DanmakuSendException(
        type: DanmakuSendErrorType.validation,
        message: validationError,
      );
    }

    // 检查节流
    if (!canSend(_lastSendTime)) {
      final remainingTime =
          config.minSendInterval -
          (DateTime.now().millisecondsSinceEpoch - (_lastSendTime ?? 0));
      throw DanmakuSendException(
        type: DanmakuSendErrorType.throttled,
        message: '发送过于频繁，请 ${(remainingTime / 1000).ceil()} 秒后再试',
      );
    }

    // 模拟网络延迟
    if (simulateDelay) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 模拟随机失败（用于测试）
    if (simulateRandomFailure && _shouldSimulateFailure()) {
      throw DanmakuSendException(
        type: DanmakuSendErrorType.network,
        message: '网络连接失败',
      );
    }

    // 更新发送时间
    _lastSendTime = DateTime.now().millisecondsSinceEpoch;

    // 生成模拟响应
    final danmakuId = 'mock_${request.vid}_${_danmakuCounter++}';
    final serverTime = DateTime.now().millisecondsSinceEpoch;

    return DanmakuSendResponse.success(
      danmakuId: danmakuId,
      serverTime: serverTime,
    );
  }

  /// 决定是否模拟失败（10% 概率）
  bool _shouldSimulateFailure() {
    return DateTime.now().millisecond % 10 == 0;
  }

  /// 获取上次发送时间（用于测试）
  int? get lastSendTime => _lastSendTime;
}

/// 弹幕发送服务工厂
///
/// 用于创建不同类型的发送服务
class DanmakuSendServiceFactory {
  /// 创建 Mock 发送服务
  static MockDanmakuSendService createMock({
    DanmakuSendConfig? config,
    bool simulateDelay = true,
    bool simulateRandomFailure = false,
  }) {
    return MockDanmakuSendService(
      config: config ?? DanmakuSendConfig.defaultConfig(),
      simulateDelay: simulateDelay,
      simulateRandomFailure: simulateRandomFailure,
    );
  }

  /// 创建真实的 HTTP 发送服务
  ///
  /// [userId] Polyv 用户 ID
  /// [writeToken] 写入令牌
  /// [secretKey] 密钥（用于签名）
  /// [config] 发送配置（可选）
  static HttpDanmakuSendService createHttp({
    required String userId,
    required String writeToken,
    required String secretKey,
    DanmakuSendConfig? config,
  }) {
    return HttpDanmakuSendService(
      userId: userId,
      writeToken: writeToken,
      secretKey: secretKey,
      config: config ?? DanmakuSendConfig.defaultConfig(),
    );
  }
}

/// 真实弹幕发送服务（HTTP）
///
/// 调用 Polyv 弹幕发送 API 将弹幕发送到服务器
/// 使用 PolyvApiClient 进行统一的 API 调用
/// 参考 iOS Demo: PLVMediaPlayerDanmuModule.m
class HttpDanmakuSendService implements DanmakuSendService {
  /// Polyv API 客户端
  final PolyvApiClient apiClient;

  /// 发送配置
  final DanmakuSendConfig config;

  /// 上次发送时间（毫秒）
  int? _lastSendTime;

  HttpDanmakuSendService({
    required String userId,
    required String writeToken,
    required String secretKey,
    required this.config,
  }) : apiClient = PolyvApiClient(
         userId: userId,
         readToken: '', // 发送弹幕不需要 readToken
         writeToken: writeToken,
         secretKey: secretKey,
       );

  @override
  int get minSendInterval => config.minSendInterval;

  @override
  String? validateText(String text) {
    final trimmed = text.trim();

    // 检查是否为空
    if (trimmed.isEmpty) {
      return '弹幕内容不能为空';
    }

    // 检查最小长度
    if (trimmed.length < config.minTextLength) {
      return '弹幕内容至少需要 ${config.minTextLength} 个字符';
    }

    // 检查最大长度
    if (trimmed.length > config.maxTextLength) {
      return '弹幕内容不能超过 ${config.maxTextLength} 个字符';
    }

    // 检查是否包含非法字符
    for (int i = 0; i < trimmed.length; i++) {
      final codeUnit = trimmed.codeUnitAt(i);
      if (codeUnit < 32 && codeUnit != 10 && codeUnit != 13) {
        return '弹幕内容包含非法字符';
      }
    }

    return null; // 校验通过
  }

  @override
  bool canSend(int? lastSendTime) {
    if (lastSendTime == null) return true;

    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - lastSendTime) >= config.minSendInterval;
  }

  @override
  void resetThrottle() {
    _lastSendTime = null;
  }

  @override
  Future<DanmakuSendResponse> sendDanmaku(DanmakuSendRequest request) async {
    // 先校验文本
    final validationError = validateText(request.text);
    if (validationError != null) {
      throw DanmakuSendException(
        type: DanmakuSendErrorType.validation,
        message: validationError,
      );
    }

    // 检查节流
    if (!canSend(_lastSendTime)) {
      final remainingTime =
          config.minSendInterval -
          (DateTime.now().millisecondsSinceEpoch - (_lastSendTime ?? 0));
      throw DanmakuSendException(
        type: DanmakuSendErrorType.throttled,
        message: '发送过于频繁，请 ${(remainingTime / 1000).ceil()} 秒后再试',
      );
    }

    try {
      // 构建请求参数
      final params = <String, dynamic>{
        'vid': request.vid,
        'msg': request.text.trim(),
        'time': PolyvApiClient.millisecondsToTimeStr(request.time),
        'fontSize': _mapFontSize(request.fontSize),
        'fontMode': _mapType(request.type),
        'fontColor': _formatColor(request.color),
      };

      // 调用 API
      final response = await apiClient.post(
        '/v2/danmu/add',
        bodyParams: params,
      );

      if (!response.success) {
        throw DanmakuSendException(
          type: _mapApiErrorType(response.statusCode),
          message: response.error ?? '发送失败',
        );
      }

      // 更新发送时间
      _lastSendTime = DateTime.now().millisecondsSinceEpoch;

      return DanmakuSendResponse.success(
        danmakuId: response.data?['id']?.toString(),
        serverTime: DateTime.now().millisecondsSinceEpoch,
      );
    } on PolyvApiException catch (e) {
      throw DanmakuSendException(
        type: _mapApiErrorType(e.statusCode),
        message: e.message,
      );
    } on DanmakuSendException {
      rethrow;
    } catch (e) {
      throw DanmakuSendException(
        type: DanmakuSendErrorType.unknown,
        message: '发送失败: $e',
      );
    }
  }

  /// 将 DanmakuFontSize 映射为 API 的 fontSize 参数
  int _mapFontSize(DanmakuFontSize? fontSize) {
    switch (fontSize) {
      case DanmakuFontSize.small:
        return 12;
      case DanmakuFontSize.medium:
        return 14;
      case DanmakuFontSize.large:
        return 16;
      default:
        return 14;
    }
  }

  /// 将 DanmakuType 映射为 API 的 fontMode 参数
  String _mapType(DanmakuType? type) {
    switch (type) {
      case DanmakuType.top:
        return 'top';
      case DanmakuType.bottom:
        return 'bottom';
      default:
        return 'roll'; // scroll 或默认
    }
  }

  /// 将颜色格式化为 API 需要的格式 (0xRRGGBB)
  String _formatColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) {
      return '0xffffff';
    }
    // 移除 # 前缀并添加 0x 前缀
    final color = hexColor.startsWith('#') ? hexColor.substring(1) : hexColor;
    return '0x$color';
  }

  /// 将 API 错误类型映射为弹幕发送错误类型
  DanmakuSendErrorType _mapApiErrorType(int? statusCode) {
    if (statusCode == null) return DanmakuSendErrorType.unknown;

    switch (statusCode) {
      case 401:
      case 403:
        return DanmakuSendErrorType.auth;
      case 400:
        return DanmakuSendErrorType.validation;
      case 500:
      case 502:
      case 503:
        return DanmakuSendErrorType.server;
      default:
        if (statusCode >= 500) {
          return DanmakuSendErrorType.server;
        }
        return DanmakuSendErrorType.unknown;
    }
  }

  /// 关闭 API 客户端
  void dispose() {
    apiClient.dispose();
  }
}
