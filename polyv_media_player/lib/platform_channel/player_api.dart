/// Platform Channel 常量定义
class PlayerApi {
  /// Method Channel 名称
  static const String methodChannelName = 'com.polyv.media_player/player';

  /// Event Channel 名称
  static const String eventChannelName = 'com.polyv.media_player/events';

  static const String downloadEventChannelName =
      'com.polyv.media_player/download_events';

  /// 私有构造函数，防止实例化
  PlayerApi._();
}

/// Method 方法名称
class PlayerMethod {
  /// 初始化账号配置
  static const String initialize = 'initialize';

  /// 加载视频
  static const String loadVideo = 'loadVideo';

  /// 播放
  static const String play = 'play';

  /// 暂停
  static const String pause = 'pause';

  /// 停止
  static const String stop = 'stop';

  /// 跳转
  static const String seekTo = 'seekTo';

  /// 设置播放速度
  static const String setPlaybackSpeed = 'setPlaybackSpeed';

  /// 切换清晰度
  static const String setQuality = 'setQuality';

  /// 设置字幕
  static const String setSubtitle = 'setSubtitle';

  /// 获取清晰度列表
  static const String getQualities = 'getQualities';

  /// 获取字幕列表
  static const String getSubtitles = 'getSubtitles';

  /// 释放原生播放器资源
  static const String disposePlayer = 'disposePlayer';

  /// 获取配置信息（从原生层读取）
  static const String getConfig = 'getConfig';

  /// 设置屏幕亮度
  static const String setScreenBrightness = 'setScreenBrightness';

  /// 获取屏幕亮度
  static const String getScreenBrightness = 'getScreenBrightness';

  /// 设置系统音量
  static const String setVolume = 'setVolume';

  /// Story 9.3: 暂停下载
  static const String pauseDownload = 'pauseDownload';

  /// Story 9.3: 继续下载
  static const String resumeDownload = 'resumeDownload';

  /// Story 9.3: 重试下载
  static const String retryDownload = 'retryDownload';

  /// Story 9.5: 删除下载
  static const String deleteDownload = 'deleteDownload';

  /// Story 9.8: 获取下载任务列表（权威同步）
  static const String getDownloadList = 'getDownloadList';

  /// Story 9.9: 创建下载任务（添加视频到下载队列）
  static const String startDownload = 'startDownload';

  /// 私有构造函数，防止实例化
  PlayerMethod._();
}

/// Event 事件名称常量
class PlayerEventName {
  /// 播放状态变化
  static const String stateChanged = 'stateChanged';

  /// 进度更新
  static const String progress = 'progress';

  /// 错误
  static const String error = 'error';

  /// 清晰度变化
  static const String qualityChanged = 'qualityChanged';

  /// 字幕变化
  static const String subtitleChanged = 'subtitleChanged';

  /// 倍速变化
  static const String playbackSpeedChanged = 'playbackSpeedChanged';

  /// 播放完成
  static const String completed = 'completed';

  /// 私有构造函数，防止实例化
  PlayerEventName._();
}

/// 播放状态常量
class PlayerStateValue {
  /// 空闲
  static const String idle = 'idle';

  /// 加载中
  static const String loading = 'loading';

  /// 准备完成
  static const String prepared = 'prepared';

  /// 播放中
  static const String playing = 'playing';

  /// 已暂停
  static const String paused = 'paused';

  /// 缓冲中
  static const String buffering = 'buffering';

  /// 播放完成
  static const String completed = 'completed';

  /// 错误
  static const String error = 'error';

  /// 私有构造函数，防止实例化
  PlayerStateValue._();
}

/// 错误码常量
class PlayerErrorCode {
  /// 无效的 VID
  static const String invalidVid = 'INVALID_VID';

  /// 网络错误
  static const String networkError = 'NETWORK_ERROR';

  /// 解码错误
  static const String decoderError = 'DECODER_ERROR';

  /// 未初始化
  static const String notInitialized = 'NOT_INITIALIZED';

  /// 不支持的操作
  static const String unsupportedOperation = 'UNSUPPORTED_OPERATION';

  /// 私有构造函数，防止实例化
  PlayerErrorCode._();
}
