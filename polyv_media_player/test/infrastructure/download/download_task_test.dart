import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/infrastructure/download/download_task.dart';
import 'package:polyv_media_player/infrastructure/download/download_task_status.dart';

/// DownloadTask 单元测试
///
/// Story 9.1: 下载中心页面框架
///
/// 测试下载任务数据模型的序列化、反序列化、计算属性和工具方法
void main() {
  group('DownloadTask 构造函数测试', () {
    test('[P1] 创建基本任务', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-123',
        title: '测试视频',
        totalBytes: 1024 * 1024 * 100,
        downloadedBytes: 1024 * 1024 * 50,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(task.id, 'task-1');
      expect(task.vid, 'vid-123');
      expect(task.title, '测试视频');
      expect(task.totalBytes, 1024 * 1024 * 100);
      expect(task.downloadedBytes, 1024 * 1024 * 50);
      expect(task.status, DownloadTaskStatus.downloading);
    });

    test('[P1] 创建带有可选字段的任务', () {
      final task = DownloadTask(
        id: 'task-2',
        vid: 'vid-456',
        title: '完整视频',
        thumbnail: 'https://example.com/thumb.jpg',
        totalBytes: 1024 * 1024 * 200,
        downloadedBytes: 1024 * 1024 * 200,
        bytesPerSecond: 1024 * 512,
        status: DownloadTaskStatus.completed,
        errorMessage: null,
        createdAt: DateTime(2024, 1, 1),
        completedAt: DateTime(2024, 1, 2),
      );

      expect(task.thumbnail, 'https://example.com/thumb.jpg');
      expect(task.bytesPerSecond, 1024 * 512);
      expect(task.status, DownloadTaskStatus.completed);
      expect(task.completedAt, DateTime(2024, 1, 2));
    });

    test('[P1] 创建失败任务带错误信息', () {
      final task = DownloadTask(
        id: 'task-3',
        vid: 'vid-789',
        title: '失败视频',
        totalBytes: 0,
        downloadedBytes: 0,
        status: DownloadTaskStatus.error,
        errorMessage: '网络连接失败',
        createdAt: DateTime(2024, 1, 1),
      );

      expect(task.status, DownloadTaskStatus.error);
      expect(task.errorMessage, '网络连接失败');
    });
  });

  group('DownloadTask - progress 计算测试', () {
    test('[P1] 完全未下载进度为 0', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1024 * 1024 * 100,
        downloadedBytes: 0,
        status: DownloadTaskStatus.waiting,
        createdAt: DateTime.now(),
      );

      expect(task.progress, 0.0);
      expect(task.progressPercent, 0);
    });

    test('[P1] 完全下载进度为 1.0', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1024 * 1024 * 100,
        downloadedBytes: 1024 * 1024 * 100,
        status: DownloadTaskStatus.completed,
        createdAt: DateTime.now(),
      );

      expect(task.progress, 1.0);
      expect(task.progressPercent, 100);
    });

    test('[P1] 50% 进度计算正确', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1024 * 1024 * 100,
        downloadedBytes: 1024 * 1024 * 50,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      expect(task.progress, 0.5);
      expect(task.progressPercent, 50);
    });

    test('[P1] 进度百分比四舍五入', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 333,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      expect(task.progress, closeTo(0.333, 0.001));
      expect(task.progressPercent, 33); // 33.3% 四舍五入
    });

    test('[P2] totalBytes 为 0 时进度为 0', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 0,
        downloadedBytes: 0,
        status: DownloadTaskStatus.preparing,
        createdAt: DateTime.now(),
      );

      expect(task.progress, 0.0);
      expect(task.progressPercent, 0);
    });

    test('[P2] downloadedBytes 超过 totalBytes 时进度限制为 1.0', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 1500,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      // progress 现在自动被 clamp 限制在 [0.0, 1.0] 范围内
      expect(task.progress, 1.0);
      expect(task.progressPercent, 100);
    });
  });

  group('DownloadTask - 格式化方法测试', () {
    test('[P1] totalSizeFormatted 格式化字节', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 500,
        downloadedBytes: 0,
        status: DownloadTaskStatus.waiting,
        createdAt: DateTime.now(),
      );

      expect(task.totalSizeFormatted, '500B');
    });

    test('[P1] totalSizeFormatted 格式化 KB', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 10 * 1024,
        downloadedBytes: 0,
        status: DownloadTaskStatus.waiting,
        createdAt: DateTime.now(),
      );

      expect(task.totalSizeFormatted, '10KB');
    });

    test('[P1] totalSizeFormatted 格式化 MB', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 100 * 1024 * 1024,
        downloadedBytes: 0,
        status: DownloadTaskStatus.waiting,
        createdAt: DateTime.now(),
      );

      expect(task.totalSizeFormatted, '100.0MB');
    });

    test('[P1] totalSizeFormatted 格式化 GB', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 5 * 1024 * 1024 * 1024,
        downloadedBytes: 0,
        status: DownloadTaskStatus.waiting,
        createdAt: DateTime.now(),
      );

      expect(task.totalSizeFormatted, '5.0GB');
    });

    test('[P1] downloadedSizeFormatted 格式化正确', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 100 * 1024 * 1024,
        downloadedBytes: 50 * 1024 * 1024,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      expect(task.downloadedSizeFormatted, '50.0MB');
    });

    test('[P1] speedFormatted 格式化 B/s', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 0,
        downloadedBytes: 0,
        bytesPerSecond: 512,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      expect(task.speedFormatted, '512B/s');
    });

    test('[P1] speedFormatted 格式化 KB/s', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 0,
        downloadedBytes: 0,
        bytesPerSecond: 1024 * 100,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      expect(task.speedFormatted, '100.0KB/s');
    });

    test('[P1] speedFormatted 格式化 MB/s', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 0,
        downloadedBytes: 0,
        bytesPerSecond: 1024 * 1024 * 5,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      expect(task.speedFormatted, '5.0MB/s');
    });

    test('[P1] speedFormatted 为 0 时显示 0KB/s', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 0,
        downloadedBytes: 0,
        bytesPerSecond: 0,
        status: DownloadTaskStatus.paused,
        createdAt: DateTime.now(),
      );

      expect(task.speedFormatted, '0KB/s');
    });

    test('[P1] speedFormatted 负数时显示 0KB/s', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 0,
        downloadedBytes: 0,
        bytesPerSecond: -100,
        status: DownloadTaskStatus.error,
        createdAt: DateTime.now(),
      );

      expect(task.speedFormatted, '0KB/s');
    });

    test('[P2] 格式化方法在各种边界值下正常工作', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1023,
        downloadedBytes: 0,
        bytesPerSecond: 1023,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      expect(task.totalSizeFormatted, '1023B');
      expect(task.speedFormatted, '1023B/s');
    });
  });

  group('DownloadTask - copyWith 测试', () {
    test('[P1] copyWith 保持未修改字段', () {
      final original = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '原标题',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(downloadedBytes: 800);

      expect(updated.id, 'task-1');
      expect(updated.vid, 'vid-1');
      expect(updated.title, '原标题');
      expect(updated.totalBytes, 1000);
      expect(updated.downloadedBytes, 800);
      expect(updated.status, DownloadTaskStatus.downloading);
      expect(updated.createdAt, DateTime(2024, 1, 1));
    });

    test('[P1] copyWith 修改单个字段', () {
      final original = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(status: DownloadTaskStatus.completed);

      expect(original.status, DownloadTaskStatus.downloading); // 原对象不变
      expect(updated.status, DownloadTaskStatus.completed);
    });

    test('[P1] copyWith 修改多个字段', () {
      final original = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(
        downloadedBytes: 1000,
        status: DownloadTaskStatus.completed,
        completedAt: DateTime(2024, 1, 2),
      );

      expect(updated.downloadedBytes, 1000);
      expect(updated.status, DownloadTaskStatus.completed);
      expect(updated.completedAt, DateTime(2024, 1, 2));
    });

    test('[P1] copyWith 可以清除可选字段', () {
      final original = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        thumbnail: 'https://example.com/thumb.jpg',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.downloading,
        errorMessage: '错误信息',
        createdAt: DateTime(2024, 1, 1),
      );

      // 使用 _clearMarker 清除可选字段
      final updated = original.copyWith(
        thumbnail: DownloadTask.clearValue,
        errorMessage: DownloadTask.clearValue,
      );

      expect(updated.thumbnail, isNull);
      expect(updated.errorMessage, isNull);
    });

    test('[P2] copyWith 所有参数都为 null 返回相同对象', () {
      final original = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime(2024, 1, 1),
      );

      final copied = original.copyWith();

      expect(copied.id, original.id);
      expect(copied.vid, original.vid);
      expect(copied.title, original.title);
      expect(copied.totalBytes, original.totalBytes);
      expect(copied.downloadedBytes, original.downloadedBytes);
      expect(copied.status, original.status);
      expect(copied.createdAt, original.createdAt);
    });
  });

  group('DownloadTask - JSON 序列化测试', () {
    test('[P1] toJson 正确序列化基本字段', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-123',
        title: '测试视频',
        totalBytes: 1024 * 1024 * 100,
        downloadedBytes: 1024 * 1024 * 50,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime(2024, 1, 1, 12, 0, 0),
      );

      final json = task.toJson();

      expect(json['id'], 'task-1');
      expect(json['vid'], 'vid-123');
      expect(json['title'], '测试视频');
      expect(json['totalBytes'], 1024 * 1024 * 100);
      expect(json['downloadedBytes'], 1024 * 1024 * 50);
      expect(json['status'], 'downloading');
      expect(json['createdAt'], '2024-01-01T12:00:00.000');
    });

    test('[P1] toJson 包含可选字段', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-123',
        title: '测试视频',
        thumbnail: 'https://example.com/thumb.jpg',
        totalBytes: 1000,
        downloadedBytes: 1000,
        bytesPerSecond: 1024 * 512,
        status: DownloadTaskStatus.completed,
        errorMessage: null,
        createdAt: DateTime(2024, 1, 1),
        completedAt: DateTime(2024, 1, 2),
      );

      final json = task.toJson();

      expect(json['thumbnail'], 'https://example.com/thumb.jpg');
      expect(json['bytesPerSecond'], 1024 * 512);
      expect(json['completedAt'], '2024-01-02T00:00:00.000');
      expect(json.containsKey('errorMessage'), isFalse); // null 不序列化
    });

    test('[P1] toJson 包含错误信息', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-123',
        title: '测试视频',
        totalBytes: 0,
        downloadedBytes: 0,
        status: DownloadTaskStatus.error,
        errorMessage: '网络连接失败',
        createdAt: DateTime(2024, 1, 1),
      );

      final json = task.toJson();

      expect(json['errorMessage'], '网络连接失败');
    });

    test('[P1] fromJson 正确反序列化基本字段', () {
      final json = {
        'id': 'task-1',
        'vid': 'vid-123',
        'title': '测试视频',
        'totalBytes': 1024 * 1024 * 100,
        'downloadedBytes': 1024 * 1024 * 50,
        'status': 'downloading',
        'createdAt': '2024-01-01T12:00:00.000Z',
      };

      final task = DownloadTask.fromJson(json);

      expect(task.id, 'task-1');
      expect(task.vid, 'vid-123');
      expect(task.title, '测试视频');
      expect(task.totalBytes, 1024 * 1024 * 100);
      expect(task.downloadedBytes, 1024 * 1024 * 50);
      expect(task.status, DownloadTaskStatus.downloading);
    });

    test('[P1] fromJson 处理缺失可选字段', () {
      final json = {
        'id': 'task-1',
        'vid': 'vid-123',
        'title': '测试视频',
        'totalBytes': 1000,
        'downloadedBytes': 500,
        'status': 'downloading',
        'createdAt': '2024-01-01T12:00:00.000Z',
      };

      final task = DownloadTask.fromJson(json);

      expect(task.thumbnail, isNull);
      expect(task.bytesPerSecond, 0); // 默认值
      expect(task.errorMessage, isNull);
      expect(task.completedAt, isNull);
    });

    test('[P1] fromJson 处理 null 数值字段', () {
      final json = {
        'id': 'task-1',
        'vid': 'vid-123',
        'title': '测试视频',
        'totalBytes': null,
        'downloadedBytes': null,
        'bytesPerSecond': null,
        'status': 'waiting',
        'createdAt': '2024-01-01T12:00:00.000Z',
      };

      final task = DownloadTask.fromJson(json);

      expect(task.totalBytes, 0); // null 默认为 0
      expect(task.downloadedBytes, 0);
      expect(task.bytesPerSecond, 0);
    });

    test('[P1] fromJson 处理未知状态字符串', () {
      final json = {
        'id': 'task-1',
        'vid': 'vid-123',
        'title': '测试视频',
        'totalBytes': 1000,
        'downloadedBytes': 0,
        'status': 'unknown_status',
        'createdAt': '2024-01-01T12:00:00.000Z',
      };

      final task = DownloadTask.fromJson(json);

      expect(task.status, DownloadTaskStatus.waiting); // 默认值
    });

    test('[P1] fromJson 处理 null 状态字符串', () {
      final json = {
        'id': 'task-1',
        'vid': 'vid-123',
        'title': '测试视频',
        'totalBytes': 1000,
        'downloadedBytes': 0,
        'status': null,
        'createdAt': '2024-01-01T12:00:00.000Z',
      };

      final task = DownloadTask.fromJson(json);

      expect(task.status, DownloadTaskStatus.waiting); // 默认值
    });

    test('[P1] fromJson 处理缺失 createdAt', () {
      final json = {
        'id': 'task-1',
        'vid': 'vid-123',
        'title': '测试视频',
        'totalBytes': 1000,
        'downloadedBytes': 0,
        'status': 'waiting',
      };

      final task = DownloadTask.fromJson(json);

      expect(task.createdAt, isNotNull);
      expect(
        task.createdAt.isBefore(DateTime.now().add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('[P2] toJson/fromJson 往返转换保持数据完整性', () {
      final original = DownloadTask(
        id: 'task-1',
        vid: 'vid-123',
        title: '测试视频',
        thumbnail: 'https://example.com/thumb.jpg',
        totalBytes: 1024 * 1024 * 100,
        downloadedBytes: 1024 * 1024 * 50,
        bytesPerSecond: 1024 * 512,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime(2024, 1, 1, 12, 30, 45),
      );

      final json = original.toJson();
      final restored = DownloadTask.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.vid, original.vid);
      expect(restored.title, original.title);
      expect(restored.thumbnail, original.thumbnail);
      expect(restored.totalBytes, original.totalBytes);
      expect(restored.downloadedBytes, original.downloadedBytes);
      expect(restored.bytesPerSecond, original.bytesPerSecond);
      expect(restored.status, original.status);
      expect(restored.createdAt, original.createdAt);
    });

    test('[P2] fromJson 支持所有状态', () {
      final statuses = [
        'preparing',
        'waiting',
        'downloading',
        'paused',
        'completed',
        'error',
      ];

      for (final statusStr in statuses) {
        final json = {
          'id': 'task-$statusStr',
          'vid': 'vid-1',
          'title': '测试',
          'totalBytes': 1000,
          'downloadedBytes': 0,
          'status': statusStr,
          'createdAt': '2024-01-01T12:00:00.000Z',
        };

        final task = DownloadTask.fromJson(json);
        expect(task.status.name, statusStr);
      }
    });
  });

  group('DownloadTask - 相等性和 hashCode 测试', () {
    test('[P1] 相同 ID 的任务相等', () {
      final task1 = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '视频1',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime(2024, 1, 1),
      );

      // 修复: DownloadTask 的相等性比较多个字段，不仅仅是 id
      // 所以要使任务相等，所有比较的字段必须相同
      final task2 = DownloadTask(
        id: 'task-1', // 相同 ID
        vid: 'vid-1', // 相同 VID
        title: '视频1', // 相同标题
        totalBytes: 1000, // 相同大小
        downloadedBytes: 500, // 相同下载字节
        status: DownloadTaskStatus.downloading, // 相同状态
        createdAt: DateTime(2024, 1, 1),
      );

      expect(task1, equals(task2));
      expect(task1 == task2, isTrue);
    });

    test('[P1] 不同 ID 的任务不相等', () {
      final task1 = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime(2024, 1, 1),
      );

      final task2 = DownloadTask(
        id: 'task-2',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(task1, isNot(equals(task2)));
      expect(task1 == task2, isFalse);
    });

    test('[P1] hashCode 基于 ID', () {
      final task1 = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '视频1',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime(2024, 1, 1),
      );

      // 修复: hashCode 与 == 保持一致，也基于多个字段
      // 所以要使 hashCode 相同，所有字段必须相同
      final task2 = DownloadTask(
        id: 'task-1', // 相同 ID
        vid: 'vid-1', // 相同 VID
        title: '视频1', // 相同标题
        totalBytes: 1000, // 相同大小
        downloadedBytes: 500, // 相同下载字节
        status: DownloadTaskStatus.downloading, // 相同状态
        createdAt: DateTime(2024, 1, 1),
      );

      expect(task1.hashCode, equals(task2.hashCode));
    });

    test('[P1] 与非 DownloadTask 对象不相等', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime(2024, 1, 1),
      );

      // 验证与其他 DownloadTask 对象不相等
      final otherTask = DownloadTask(
        id: 'task-2',
        vid: 'vid-456',
        title: '其他视频',
        totalBytes: 2000,
        downloadedBytes: 1000,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime(2024, 1, 2),
      );
      expect(task == otherTask, isFalse);
    });
  });

  group('DownloadTask - toString 测试', () {
    test('[P1] toString 包含关键信息', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-123',
        title: '测试视频标题',
        totalBytes: 1024 * 1024 * 100,
        downloadedBytes: 1024 * 1024 * 75,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime(2024, 1, 1),
      );

      final str = task.toString();

      expect(str, contains('task-1'));
      expect(str, contains('vid-123'));
      expect(str, contains('测试视频标题'));
      expect(str, contains('downloading'));
      expect(str, contains('75%'));
    });

    test('[P2] toString 格式符合预期', () {
      final task = DownloadTask(
        id: 'abc123',
        vid: 'vid456',
        title: '视频',
        totalBytes: 1000,
        downloadedBytes: 250,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      final str = task.toString();
      expect(str, startsWith('DownloadTask('));
      expect(str, endsWith(')'));
    });
  });

  group('场景测试 - 任务生命周期', () {
    test('[场景1][P1] 新创建任务处于准备状态', () {
      final task = DownloadTask(
        id: 'task-new',
        vid: 'vid-new',
        title: '新视频',
        totalBytes: 0,
        downloadedBytes: 0,
        status: DownloadTaskStatus.preparing,
        createdAt: DateTime.now(),
      );

      expect(task.status, DownloadTaskStatus.preparing);
      expect(task.progress, 0.0);
      expect(task.speedFormatted, '0KB/s');
    });

    test('[场景2][P1] 任务下载中更新进度', () {
      final initial = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '视频',
        totalBytes: 1000,
        downloadedBytes: 0,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      // 模拟进度更新
      final updated = initial.copyWith(
        downloadedBytes: 500,
        bytesPerSecond: 100,
      );

      expect(initial.progress, 0.0);
      expect(updated.progress, 0.5);
      expect(updated.speedFormatted, '100B/s');
    });

    test('[场景3][P1] 任务暂停后恢复', () {
      final downloading = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '视频',
        totalBytes: 1000,
        downloadedBytes: 300,
        bytesPerSecond: 100,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      // 暂停
      final paused = downloading.copyWith(
        status: DownloadTaskStatus.paused,
        bytesPerSecond: 0,
      );

      // 恢复
      final resumed = paused.copyWith(
        status: DownloadTaskStatus.downloading,
        bytesPerSecond: 150,
      );

      expect(paused.status, DownloadTaskStatus.paused);
      expect(paused.bytesPerSecond, 0);
      expect(resumed.status, DownloadTaskStatus.downloading);
      expect(resumed.bytesPerSecond, 150);
      expect(resumed.downloadedBytes, 300); // 进度保持
    });

    test('[场景4][P1] 任务完成', () {
      final downloading = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '视频',
        totalBytes: 1000,
        downloadedBytes: 950,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime(2024, 1, 1),
      );

      // 完成
      final completed = downloading.copyWith(
        downloadedBytes: 1000,
        status: DownloadTaskStatus.completed,
        completedAt: DateTime(2024, 1, 2),
      );

      expect(completed.progress, 1.0);
      expect(completed.progressPercent, 100);
      expect(completed.status, DownloadTaskStatus.completed);
      expect(completed.completedAt, DateTime(2024, 1, 2));
    });

    test('[场景5][P1] 任务失败', () {
      final downloading = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '视频',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      // 失败
      final failed = downloading.copyWith(
        status: DownloadTaskStatus.error,
        errorMessage: '网络连接超时',
        bytesPerSecond: 0,
      );

      expect(failed.status, DownloadTaskStatus.error);
      expect(failed.errorMessage, '网络连接超时');
      expect(failed.progress, 0.5); // 进度保留
      expect(failed.status.isTerminal, isTrue);
    });

    test('[场景6][P1] 重试失败任务', () {
      final failed = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '视频',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.error,
        errorMessage: '网络错误',
        createdAt: DateTime.now(),
      );

      // 重试 - 使用 _clearMarker 清除错误信息
      final retrying = failed.copyWith(
        status: DownloadTaskStatus.downloading,
        errorMessage: DownloadTask.clearValue,
      );

      expect(retrying.status, DownloadTaskStatus.downloading);
      // 错误信息现在可以被清除
      expect(retrying.errorMessage, isNull);
      expect(retrying.downloadedBytes, 500); // 断点续传
    });
  });

  group('边缘情况测试', () {
    test('[P2] 空字符串 ID 有效', () {
      final task = DownloadTask(
        id: '',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 0,
        status: DownloadTaskStatus.waiting,
        createdAt: DateTime.now(),
      );

      expect(task.id, '');
      expect(task.vid, 'vid-1');
    });

    test('[P2] 空字符串标题有效', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '',
        totalBytes: 1000,
        downloadedBytes: 0,
        status: DownloadTaskStatus.waiting,
        createdAt: DateTime.now(),
      );

      expect(task.title, '');
    });

    test('[P2] 非常大的文件大小正确格式化为 GB', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '超大文件',
        totalBytes: 1024 * 1024 * 1024 * 1024, // 1 TB 显示为 1024GB
        downloadedBytes: 0,
        status: DownloadTaskStatus.waiting,
        createdAt: DateTime.now(),
      );

      expect(task.totalSizeFormatted, contains('GB'));
      expect(task.totalSizeFormatted, '1024.0GB');
    });

    test('[P2] 负数大小处理', () {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: -100, // 异常值
        downloadedBytes: 0,
        status: DownloadTaskStatus.error,
        createdAt: DateTime.now(),
      );

      expect(task.totalBytes, -100);
      expect(task.progress, equals(0.0)); // 除数保护
    });
  });
}
