import 'download_task_status.dart';

/// 下载任务数据模型
///
/// 表示一个视频下载任务，包含任务的所有状态信息。
/// 对应 Web 原型中的 DownloadItem 接口。
/// 参考: /Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/DownloadCenterPage.tsx
class DownloadTask {
  /// 任务唯一标识
  final String id;

  /// 视频 VID
  final String vid;

  /// 视频标题
  final String title;

  /// 视频缩略图 URL（可选）
  final String? thumbnail;

  /// 文件总大小（字节）
  final int totalBytes;

  /// 已下载大小（字节）
  final int downloadedBytes;

  /// 下载进度 0.0-1.0
  ///
  /// 进度值被限制在 [0.0, 1.0] 范围内，即使 downloadedBytes 超过 totalBytes
  /// 也返回 1.0（表示已完成），避免 UI 层需要额外处理边界情况。
  double get progress {
    if (totalBytes <= 0) return 0.0;
    final rawProgress = downloadedBytes / totalBytes;
    return rawProgress.clamp(0.0, 1.0);
  }

  /// 下载进度百分比 (0-100)
  int get progressPercent => (progress * 100).round();

  /// 当前下载速度（字节/秒）
  final int bytesPerSecond;

  /// 任务状态
  final DownloadTaskStatus status;

  /// 错误信息（如果有）
  final String? errorMessage;

  /// 创建时间
  final DateTime createdAt;

  /// 完成时间（如果有）
  final DateTime? completedAt;

  const DownloadTask({
    required this.id,
    required this.vid,
    required this.title,
    this.thumbnail,
    required this.totalBytes,
    required this.downloadedBytes,
    this.bytesPerSecond = 0,
    required this.status,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
  });

  /// 用于标记需要清除的可选字段
  ///
  /// 使用方式: `task.copyWith(thumbnail: DownloadTask.clearValue)`
  static const Object clearValue = Object();

  /// 创建副本并修改部分属性
  ///
  /// 要清除可选字段（thumbnail 或 errorMessage），传入 [clearValue]。
  /// 例如: `task.copyWith(thumbnail: DownloadTask.clearValue)`
  DownloadTask copyWith({
    String? id,
    String? vid,
    String? title,
    Object? thumbnail,
    int? totalBytes,
    int? downloadedBytes,
    int? bytesPerSecond,
    DownloadTaskStatus? status,
    Object? errorMessage,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      vid: vid ?? this.vid,
      title: title ?? this.title,
      thumbnail: thumbnail == clearValue
          ? null
          : (thumbnail as String?) ?? this.thumbnail,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      bytesPerSecond: bytesPerSecond ?? this.bytesPerSecond,
      status: status ?? this.status,
      errorMessage: errorMessage == clearValue
          ? null
          : (errorMessage as String?) ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// 格式化文件大小显示
  String get totalSizeFormatted => _formatBytes(totalBytes);

  /// 格式化已下载大小显示
  String get downloadedSizeFormatted => _formatBytes(downloadedBytes);

  /// 格式化下载速度显示
  String get speedFormatted {
    if (bytesPerSecond <= 0) return '0KB/s';
    if (bytesPerSecond < 1024) return '${bytesPerSecond}B/s';
    if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)}KB/s';
    }
    return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)}MB/s';
  }

  /// 格式化字节为可读字符串
  static String _formatBytes(int bytes) {
    const kb = 1024;
    const mb = 1024 * kb;
    const gb = 1024 * mb;

    if (bytes < kb) return '${bytes}B';
    if (bytes < mb) return '${(bytes / kb).toStringAsFixed(0)}KB';
    if (bytes < gb) return '${(bytes / mb).toStringAsFixed(1)}MB';
    return '${(bytes / gb).toStringAsFixed(1)}GB';
  }

  /// 从 JSON 创建 DownloadTask（用于从原生层接收数据）
  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      id: json['id'] as String,
      vid: json['vid'] as String,
      title: json['title'] as String,
      thumbnail: json['thumbnail'] as String?,
      totalBytes: json['totalBytes'] as int? ?? 0,
      downloadedBytes: json['downloadedBytes'] as int? ?? 0,
      bytesPerSecond: json['bytesPerSecond'] as int? ?? 0,
      status: _parseStatus(json['status'] as String?),
      errorMessage: json['errorMessage'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  /// 转换为 JSON（用于发送到原生层）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vid': vid,
      'title': title,
      if (thumbnail != null) 'thumbnail': thumbnail,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
      'bytesPerSecond': bytesPerSecond,
      'status': status.name,
      if (errorMessage != null) 'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    };
  }

  /// 解析状态字符串
  static DownloadTaskStatus _parseStatus(String? statusStr) {
    if (statusStr == null) return DownloadTaskStatus.waiting;
    for (final status in DownloadTaskStatus.values) {
      if (status.name == statusStr) return status;
    }
    return DownloadTaskStatus.waiting;
  }

  @override
  String toString() {
    return 'DownloadTask(id: $id, vid: $vid, title: $title, '
        'status: $status.name, progress: $progressPercent%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DownloadTask &&
        other.id == id &&
        other.downloadedBytes == downloadedBytes &&
        other.totalBytes == totalBytes &&
        other.bytesPerSecond == bytesPerSecond &&
        other.status == status &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
    id,
    downloadedBytes,
    totalBytes,
    bytesPerSecond,
    status,
    errorMessage,
  );
}
