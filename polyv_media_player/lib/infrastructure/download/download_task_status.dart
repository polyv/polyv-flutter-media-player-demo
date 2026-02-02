/// 下载任务状态枚举
///
/// 对应原生 SDK 的下载状态：
/// - Android: PLVMediaDownloadStatus
/// - iOS: PLVVodDownloadState
enum DownloadTaskStatus {
  /// 准备中 - 任务已创建，正在初始化
  preparing,

  /// 等待下载 - 任务在队列中等待
  waiting,

  /// 下载中 - 正在下载
  downloading,

  /// 已暂停 - 用户暂停或系统暂停
  paused,

  /// 已完成 - 下载成功完成
  completed,

  /// 失败 - 下载失败，可重试
  error,
}

/// 下载任务状态扩展方法
extension DownloadTaskStatusExtension on DownloadTaskStatus {
  /// 是否为活跃下载状态（准备中、等待中、下载中）
  bool get isActive {
    switch (this) {
      case DownloadTaskStatus.preparing:
      case DownloadTaskStatus.waiting:
      case DownloadTaskStatus.downloading:
        return true;
      case DownloadTaskStatus.paused:
      case DownloadTaskStatus.completed:
      case DownloadTaskStatus.error:
        return false;
    }
  }

  /// 是否为可显示在"下载中"Tab的状态
  bool get isInProgress {
    switch (this) {
      case DownloadTaskStatus.preparing:
      case DownloadTaskStatus.waiting:
      case DownloadTaskStatus.downloading:
      case DownloadTaskStatus.paused:
      case DownloadTaskStatus.error:
        return true;
      case DownloadTaskStatus.completed:
        return false;
    }
  }

  /// 是否为终端状态（已完成或失败）
  bool get isTerminal {
    return this == DownloadTaskStatus.completed ||
        this == DownloadTaskStatus.error;
  }

  /// 获取状态显示文本
  String get displayLabel {
    switch (this) {
      case DownloadTaskStatus.preparing:
        return '准备中';
      case DownloadTaskStatus.waiting:
        return '等待中';
      case DownloadTaskStatus.downloading:
        return '下载中';
      case DownloadTaskStatus.paused:
        return '已暂停';
      case DownloadTaskStatus.completed:
        return '已完成';
      case DownloadTaskStatus.error:
        return '下载失败';
    }
  }
}
