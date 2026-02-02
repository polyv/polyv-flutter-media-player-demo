library;

/// 测试数据生成工具
///
/// 提供播放器测试所需的模拟数据生成功能

/// 测试数据常量
class TestData {
  /// 默认测试视频 VID
  static const String defaultVid = 'test_video_123';

  /// 另一个测试视频 VID
  static const String alternateVid = 'test_video_456';

  /// 无效的 VID
  static const String invalidVid = '';

  /// 默认测试位置（毫秒）
  static const int defaultPosition = 30000; // 30秒

  /// 默认测试时长（毫秒）
  static const int defaultDuration = 300000; // 5分钟

  /// 默认缓冲位置（毫秒）
  static const int defaultBufferedPosition = 60000; // 1分钟

  /// 默认播放速度
  static const double defaultPlaybackSpeed = 1.0;

  /// 加速播放速度
  static const double fastPlaybackSpeed = 1.5;

  /// 减速播放速度
  static const double slowPlaybackSpeed = 0.75;
}

/// 模拟数据生成器
class MockDataGenerator {
  /// 生成随机的视频 VID
  static String generateVid({String prefix = 'vid_'}) {
    return '$prefix${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 生成随机的播放位置（毫秒）
  static int generatePosition({int max = 3600000}) {
    return DateTime.now().millisecondsSinceEpoch % max;
  }

  /// 生成随机的播放速度 (0.5 - 2.0)
  static double generatePlaybackSpeed() {
    return 0.5 + (DateTime.now().millisecondsSinceEpoch % 15) / 10.0;
  }
}

/// 平台通道模拟数据
class MockPlatformData {
  /// 模拟状态变化事件数据
  static Map<String, dynamic> stateChanged(String state) {
    return {
      'type': 'stateChanged',
      'data': {'state': state},
    };
  }

  /// 模拟进度更新事件数据
  static Map<String, dynamic> progress({
    int position = TestData.defaultPosition,
    int duration = TestData.defaultDuration,
    int bufferedPosition = TestData.defaultBufferedPosition,
  }) {
    return {
      'type': 'progress',
      'data': {
        'position': position,
        'duration': duration,
        'bufferedPosition': bufferedPosition,
      },
    };
  }

  /// 模拟错误事件数据
  static Map<String, dynamic> error({
    String code = 'TEST_ERROR',
    String message = 'Test error message',
  }) {
    return {
      'type': 'error',
      'data': {'code': code, 'message': message},
    };
  }

  /// 模拟清晰度变化事件数据
  static Map<String, dynamic> qualityChanged({
    List<Map<String, dynamic>>? qualities,
    int currentIndex = 0,
  }) {
    return {
      'type': 'qualityChanged',
      'data': {
        'qualities':
            qualities ??
            [
              {'description': '超清', 'value': '1080p', 'isAvailable': true},
              {'description': '高清', 'value': '720p', 'isAvailable': true},
              {'description': '标清', 'value': '480p', 'isAvailable': true},
            ],
        'currentIndex': currentIndex,
      },
    };
  }

  /// 模拟字幕变化事件数据
  static Map<String, dynamic> subtitleChanged({
    List<Map<String, dynamic>>? subtitles,
    int currentIndex = -1,
  }) {
    return {
      'type': 'subtitleChanged',
      'data': {
        'subtitles':
            subtitles ??
            [
              {'language': 'zh', 'label': '中文', 'url': null},
              {'language': 'en', 'label': 'English', 'url': null},
            ],
        'currentIndex': currentIndex,
      },
    };
  }

  /// 模拟播放完成事件数据
  static Map<String, dynamic> completed() {
    return {'type': 'completed', 'data': null};
  }
}

/// 清晰度测试数据工厂
class QualityTestData {
  /// 完整的清晰度列表
  static const List<Map<String, dynamic>> fullQualities = [
    {'description': '4K 超清', 'value': '4k', 'isAvailable': true},
    {'description': '1080P 高清', 'value': '1080p', 'isAvailable': true},
    {'description': '720P 标清', 'value': '720p', 'isAvailable': true},
    {'description': '480P 流畅', 'value': '480p', 'isAvailable': true},
    {'description': '360P 极速', 'value': '360p', 'isAvailable': true},
  ];

  /// 包含自动模式的清晰度列表
  static const List<Map<String, dynamic>> withAuto = [
    {'description': '自动', 'value': 'auto', 'isAvailable': true},
    {'description': '1080P 高清', 'value': '1080p', 'isAvailable': true},
    {'description': '720P 标清', 'value': '720p', 'isAvailable': true},
  ];

  /// 单个清晰度
  static const List<Map<String, dynamic>> singleQuality = [
    {'description': '1080P 高清', 'value': '1080p', 'isAvailable': true},
  ];

  /// 空清晰度列表
  static const List<Map<String, dynamic>> empty = [];

  /// 生成清晰度质量变化事件
  static Map<String, dynamic> qualityChangedEvent({
    List<Map<String, dynamic>> qualities = fullQualities,
    int currentIndex = 0,
  }) {
    return MockPlatformData.qualityChanged(
      qualities: qualities,
      currentIndex: currentIndex,
    );
  }
}

/// 字幕测试数据工厂
class SubtitleTestData {
  /// 完整的字幕列表
  static const List<Map<String, dynamic>> fullSubtitles = [
    {'language': 'zh', 'label': '中文', 'url': null},
    {'language': 'en', 'label': 'English', 'url': null},
    {'language': 'ja', 'label': '日本語', 'url': null},
  ];

  /// 空字幕列表
  static const List<Map<String, dynamic>> empty = [];

  /// 生成字幕变化事件
  static Map<String, dynamic> subtitleChangedEvent({
    List<Map<String, dynamic>> subtitles = fullSubtitles,
    int currentIndex = -1,
  }) {
    return MockPlatformData.subtitleChanged(
      subtitles: subtitles,
      currentIndex: currentIndex,
    );
  }
}
