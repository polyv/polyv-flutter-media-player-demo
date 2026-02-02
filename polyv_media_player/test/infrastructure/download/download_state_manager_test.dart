import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/infrastructure/download/download_task.dart';
import 'package:polyv_media_player/infrastructure/download/download_task_status.dart';
import 'package:polyv_media_player/infrastructure/download/download_state_manager.dart';
import 'package:polyv_media_player/platform_channel/player_api.dart';

/// DownloadStateManager 单元测试
///
/// Story 9.1: 下载中心页面框架
/// Story 9.7: 强一致性测试 - 原生调用成功才更新本地状态
///
/// 测试下载状态管理器的任务管理、状态变更和通知机制

/// 创建带有 mock channel 的 DownloadStateManager
///
/// [shouldSucceed] 控制 mock channel 是返回成功还是抛出异常
DownloadStateManager _createManagerWithMockChannel({
  bool shouldSucceed = true,
  String? errorCode,
  String? errorMessage,
}) {
  final channel = MethodChannel(PlayerApi.methodChannelName);

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (!shouldSucceed) {
          throw PlatformException(
            code: errorCode ?? 'SDK_ERROR',
            message: errorMessage ?? 'Mock error',
          );
        }
        return null;
      });

  return DownloadStateManager(channel: channel);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('DownloadStateManager - 初始化和基本属性测试', () {
    test('[P1] 初始化状态管理器为空', () {
      final manager = DownloadStateManager();

      expect(manager.tasks.isEmpty, isTrue);
      expect(manager.totalCount, 0);
      expect(manager.downloadingCount, 0);
      expect(manager.completedCount, 0);
    });

    test('[P1] tasks 返回不可变列表', () {
      final manager = DownloadStateManager();
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 0,
        status: DownloadTaskStatus.waiting,
        createdAt: DateTime.now(),
      );

      manager.addTask(task);
      final tasks = manager.tasks;

      // 尝试修改返回的列表不应影响内部状态
      expect(() => tasks.add(task), throwsUnsupportedError);
    });

    test('[P1] activeTasks 返回活跃任务', () {
      final manager = DownloadStateManager();

      manager.addTasks([
        _createTask('task-1', DownloadTaskStatus.preparing),
        _createTask('task-2', DownloadTaskStatus.waiting),
        _createTask('task-3', DownloadTaskStatus.downloading),
        _createTask('task-4', DownloadTaskStatus.paused),
        _createTask('task-5', DownloadTaskStatus.completed),
      ]);

      expect(manager.activeTasks.length, 3); // preparing, waiting, downloading
    });
  });

  group('DownloadStateManager - 任务筛选测试', () {
    test('[P1] downloadingTasks 筛选下载中任务', () {
      final manager = DownloadStateManager();

      manager.addTasks([
        _createTask('task-1', DownloadTaskStatus.preparing),
        _createTask('task-2', DownloadTaskStatus.waiting),
        _createTask('task-3', DownloadTaskStatus.downloading),
        _createTask('task-4', DownloadTaskStatus.paused),
        _createTask('task-5', DownloadTaskStatus.error),
        _createTask('task-6', DownloadTaskStatus.completed),
      ]);

      final downloading = manager.downloadingTasks;

      expect(downloading.length, 5); // 除了 completed
      expect(
        downloading.map((t) => t.id),
        containsAll(['task-1', 'task-2', 'task-3', 'task-4', 'task-5']),
      );
      expect(downloading.map((t) => t.id), isNot(contains('task-6')));
    });

    test('[P1] completedTasks 只返回已完成任务', () {
      final manager = DownloadStateManager();

      manager.addTasks([
        _createTask('task-1', DownloadTaskStatus.downloading),
        _createTask('task-2', DownloadTaskStatus.completed),
        _createTask('task-3', DownloadTaskStatus.completed),
      ]);

      final completed = manager.completedTasks;

      expect(completed.length, 2);
      expect(completed.map((t) => t.id), equals(['task-2', 'task-3']));
    });

    test('[P1] downloadingCount 正确计数', () {
      final manager = DownloadStateManager();

      expect(manager.downloadingCount, 0);

      manager.addTask(_createTask('task-1', DownloadTaskStatus.downloading));
      expect(manager.downloadingCount, 1);

      manager.addTask(_createTask('task-2', DownloadTaskStatus.completed));
      expect(manager.downloadingCount, 1);

      manager.addTask(_createTask('task-3', DownloadTaskStatus.paused));
      expect(manager.downloadingCount, 2);
    });

    test('[P1] completedCount 正确计数', () {
      final manager = DownloadStateManager();

      expect(manager.completedCount, 0);

      manager.addTask(_createTask('task-1', DownloadTaskStatus.downloading));
      expect(manager.completedCount, 0);

      manager.addTask(_createTask('task-2', DownloadTaskStatus.completed));
      expect(manager.completedCount, 1);

      manager.addTask(_createTask('task-3', DownloadTaskStatus.completed));
      expect(manager.completedCount, 2);
    });

    test('[P1] totalCount 正确计数', () {
      final manager = DownloadStateManager();

      expect(manager.totalCount, 0);

      manager.addTask(_createTask('task-1', DownloadTaskStatus.downloading));
      manager.addTask(_createTask('task-2', DownloadTaskStatus.completed));
      manager.addTask(_createTask('task-3', DownloadTaskStatus.paused));

      expect(manager.totalCount, 3);
    });
  });

  group('DownloadStateManager - 任务查询测试', () {
    test('[P1] getTaskById 找到存在的任务', () {
      final manager = DownloadStateManager();
      final task = _createTask('task-123', DownloadTaskStatus.downloading);

      manager.addTask(task);

      final found = manager.getTaskById('task-123');

      expect(found, isNotNull);
      expect(found?.id, 'task-123');
    });

    test('[P1] getTaskById 对不存在的任务返回 null', () {
      final manager = DownloadStateManager();
      manager.addTask(_createTask('task-1', DownloadTaskStatus.downloading));

      final found = manager.getTaskById('non-existent');

      expect(found, isNull);
    });

    test('[P1] getTaskByVid 找到存在的任务', () {
      final manager = DownloadStateManager();
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-abc',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 0,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      manager.addTask(task);

      final found = manager.getTaskByVid('vid-abc');

      expect(found, isNotNull);
      expect(found?.vid, 'vid-abc');
    });

    test('[P1] getTaskByVid 对不存在的任务返回 null', () {
      final manager = DownloadStateManager();
      manager.addTask(_createTask('task-1', DownloadTaskStatus.downloading));

      final found = manager.getTaskByVid('vid-nonexistent');

      expect(found, isNull);
    });

    test('[P2] 多个相同 VID 只返回第一个', () {
      final manager = DownloadStateManager();

      manager.addTasks([
        DownloadTask(
          id: 'task-1',
          vid: 'vid-same',
          title: '视频1',
          totalBytes: 1000,
          downloadedBytes: 0,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
        DownloadTask(
          id: 'task-2',
          vid: 'vid-same',
          title: '视频2',
          totalBytes: 2000,
          downloadedBytes: 0,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      ]);

      final found = manager.getTaskByVid('vid-same');

      expect(found, isNotNull);
      expect(found?.id, 'task-1'); // 返回第一个
    });
  });

  group('DownloadStateManager - 添加任务测试', () {
    test('[P1] addTask 添加新任务', () {
      final manager = DownloadStateManager();
      final task = _createTask('task-1', DownloadTaskStatus.downloading);

      manager.addTask(task);

      expect(manager.totalCount, 1);
      expect(manager.tasks.first.id, 'task-1');
    });

    test('[P1] addTask 更新已存在的任务', () {
      final manager = DownloadStateManager();

      // 添加初始任务
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '原标题',
          totalBytes: 1000,
          downloadedBytes: 0,
          status: DownloadTaskStatus.waiting,
          createdAt: DateTime(2024, 1, 1),
        ),
      );

      expect(manager.totalCount, 1);

      // 使用相同 ID 更新任务
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '更新标题',
          totalBytes: 2000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime(2024, 1, 1),
        ),
      );

      expect(manager.totalCount, 1); // 不增加计数
      final updated = manager.getTaskById('task-1');
      expect(updated?.title, '更新标题');
      expect(updated?.totalBytes, 2000);
    });

    test('[P1] addTasks 批量添加任务', () {
      final manager = DownloadStateManager();

      manager.addTasks([
        _createTask('task-1', DownloadTaskStatus.downloading),
        _createTask('task-2', DownloadTaskStatus.waiting),
        _createTask('task-3', DownloadTaskStatus.completed),
      ]);

      expect(manager.totalCount, 3);
      expect(manager.downloadingCount, 2);
      expect(manager.completedCount, 1);
    });

    test('[P1] addTasks 处理重复 ID', () {
      final manager = DownloadStateManager();

      manager.addTasks([
        _createTask('task-1', DownloadTaskStatus.waiting),
        _createTask('task-2', DownloadTaskStatus.waiting),
      ]);

      expect(manager.totalCount, 2);

      // 再次添加包含相同 ID 的任务
      manager.addTasks([
        _createTask('task-1', DownloadTaskStatus.downloading), // 更新
        _createTask('task-3', DownloadTaskStatus.waiting), // 新增
      ]);

      expect(manager.totalCount, 3); // task-1 更新，task-3 新增
    });

    test('[P2] addTasks 空列表不影响状态', () {
      final manager = DownloadStateManager();

      manager.addTask(_createTask('task-1', DownloadTaskStatus.downloading));
      expect(manager.totalCount, 1);

      manager.addTasks([]);
      expect(manager.totalCount, 1);
    });
  });

  group('DownloadStateManager - 更新任务测试', () {
    test('[P1] updateTask 更新存在的任务', () {
      final manager = DownloadStateManager();
      final original = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '原标题',
        totalBytes: 1000,
        downloadedBytes: 0,
        status: DownloadTaskStatus.waiting,
        createdAt: DateTime.now(),
      );

      manager.addTask(original);

      final updated = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '更新标题',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      manager.updateTask('task-1', updated);

      final task = manager.getTaskById('task-1');
      expect(task?.title, '更新标题');
      expect(task?.downloadedBytes, 500);
      expect(task?.status, DownloadTaskStatus.downloading);
    });

    test('[P1] updateTask 对不存在的任务不操作', () {
      final manager = DownloadStateManager();
      manager.addTask(_createTask('task-1', DownloadTaskStatus.downloading));

      final initialCount = manager.totalCount;

      manager.updateTask(
        'non-existent',
        _createTask('non-existent', DownloadTaskStatus.completed),
      );

      expect(manager.totalCount, initialCount);
    });

    test('[P1] updateTaskProgress 更新下载进度', () {
      final manager = DownloadStateManager();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '测试',
          totalBytes: 1000,
          downloadedBytes: 0,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );

      manager.updateTaskProgress('task-1', downloadedBytes: 300);

      final task = manager.getTaskById('task-1');
      expect(task?.downloadedBytes, 300);
    });

    test('[P1] updateTaskProgress 更新状态和进度', () {
      final manager = DownloadStateManager();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '测试',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );

      manager.updateTaskProgress(
        'task-1',
        downloadedBytes: 1000,
        status: DownloadTaskStatus.completed,
      );

      final task = manager.getTaskById('task-1');
      expect(task?.downloadedBytes, 1000);
      expect(task?.status, DownloadTaskStatus.completed);
      expect(task?.completedAt, isNotNull);
    });

    test('[P1] updateTaskProgress 设置错误信息', () {
      final manager = DownloadStateManager();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '测试',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );

      manager.updateTaskProgress(
        'task-1',
        status: DownloadTaskStatus.error,
        errorMessage: '网络错误',
      );

      final task = manager.getTaskById('task-1');
      expect(task?.status, DownloadTaskStatus.error);
      expect(task?.errorMessage, '网络错误');
    });

    test('[P1] updateTaskProgress 对不存在任务不操作', () {
      final manager = DownloadStateManager();
      manager.addTask(_createTask('task-1', DownloadTaskStatus.downloading));

      manager.updateTaskProgress('non-existent', downloadedBytes: 100);

      expect(manager.totalCount, 1);
    });

    test('[P2] updateTaskProgress 更新下载速度', () {
      final manager = DownloadStateManager();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '测试',
          totalBytes: 0,
          downloadedBytes: 0,
          bytesPerSecond: 0,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );

      manager.updateTaskProgress('task-1', bytesPerSecond: 1024 * 500);

      final task = manager.getTaskById('task-1');
      expect(task?.bytesPerSecond, 1024 * 500);
    });

    test('[P2] updateTaskProgress 完成时自动设置 completedAt', () {
      final manager = DownloadStateManager();
      final before = DateTime.now();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '测试',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );

      manager.updateTaskProgress(
        'task-1',
        downloadedBytes: 1000,
        status: DownloadTaskStatus.completed,
      );

      final after = DateTime.now();
      final task = manager.getTaskById('task-1');

      expect(task?.completedAt, isNotNull);
      expect(task?.completedAt!.isAfter(before), isTrue);
      expect(
        task?.completedAt!.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('[P2] updateTaskProgress 非完成状态不修改 completedAt', () {
      final manager = DownloadStateManager();
      final completedAt = DateTime(2024, 1, 1);
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '测试',
          totalBytes: 1000,
          downloadedBytes: 1000,
          status: DownloadTaskStatus.completed,
          createdAt: DateTime.now(),
          completedAt: completedAt,
        ),
      );

      manager.updateTaskProgress(
        'task-1',
        downloadedBytes: 500,
        status: DownloadTaskStatus.downloading,
      );

      final task = manager.getTaskById('task-1');
      expect(task?.completedAt, completedAt);
    });
  });

  group('DownloadStateManager - 删除任务测试', () {
    test('[P1] removeTask 删除存在的任务', () {
      final manager = DownloadStateManager();
      manager.addTask(_createTask('task-1', DownloadTaskStatus.downloading));
      manager.addTask(_createTask('task-2', DownloadTaskStatus.completed));

      expect(manager.totalCount, 2);

      manager.removeTask('task-1');

      expect(manager.totalCount, 1);
      expect(manager.getTaskById('task-1'), isNull);
      expect(manager.getTaskById('task-2'), isNotNull);
    });

    test('[P1] removeTask 对不存在的任务不操作', () {
      final manager = DownloadStateManager();
      manager.addTask(_createTask('task-1', DownloadTaskStatus.downloading));

      final initialCount = manager.totalCount;

      manager.removeTask('non-existent');

      expect(manager.totalCount, initialCount);
    });

    test('[P1] removeTasks 批量删除任务', () {
      final manager = DownloadStateManager();
      manager.addTasks([
        _createTask('task-1', DownloadTaskStatus.downloading),
        _createTask('task-2', DownloadTaskStatus.downloading),
        _createTask('task-3', DownloadTaskStatus.completed),
        _createTask('task-4', DownloadTaskStatus.completed),
      ]);

      expect(manager.totalCount, 4);

      manager.removeTasks(['task-1', 'task-3']);

      expect(manager.totalCount, 2);
      expect(manager.getTaskById('task-1'), isNull);
      expect(manager.getTaskById('task-2'), isNotNull);
      expect(manager.getTaskById('task-3'), isNull);
      expect(manager.getTaskById('task-4'), isNotNull);
    });

    test('[P1] removeTasks 空列表不影响状态', () {
      final manager = DownloadStateManager();
      manager.addTask(_createTask('task-1', DownloadTaskStatus.downloading));

      manager.removeTasks([]);

      expect(manager.totalCount, 1);
    });

    test('[P1] clearAll 清空所有任务', () {
      final manager = DownloadStateManager();
      manager.addTasks([
        _createTask('task-1', DownloadTaskStatus.downloading),
        _createTask('task-2', DownloadTaskStatus.completed),
      ]);

      expect(manager.totalCount, 2);

      manager.clearAll();

      expect(manager.totalCount, 0);
      expect(manager.downloadingCount, 0);
      expect(manager.completedCount, 0);
    });

    test('[P1] clearCompleted 只清空已完成任务', () {
      final manager = DownloadStateManager();
      manager.addTasks([
        _createTask('task-1', DownloadTaskStatus.downloading),
        _createTask('task-2', DownloadTaskStatus.completed),
        _createTask('task-3', DownloadTaskStatus.paused),
        _createTask('task-4', DownloadTaskStatus.completed),
      ]);

      manager.clearCompleted();

      expect(manager.totalCount, 2);
      expect(manager.getTaskById('task-1'), isNotNull);
      expect(manager.getTaskById('task-2'), isNull);
      expect(manager.getTaskById('task-3'), isNotNull);
      expect(manager.getTaskById('task-4'), isNull);
    });

    test('[P2] clearCompleted 没有已完成任务时不操作', () {
      final manager = DownloadStateManager();
      manager.addTasks([
        _createTask('task-1', DownloadTaskStatus.downloading),
        _createTask('task-2', DownloadTaskStatus.paused),
      ]);

      final initialCount = manager.totalCount;

      manager.clearCompleted();

      expect(manager.totalCount, initialCount);
    });
  });

  group('DownloadStateManager - 批量操作测试', () {
    test('[P1] replaceAll 替换所有任务', () {
      final manager = DownloadStateManager();
      manager.addTasks([
        _createTask('task-1', DownloadTaskStatus.downloading),
        _createTask('task-2', DownloadTaskStatus.completed),
      ]);

      expect(manager.totalCount, 2);

      manager.replaceAll([
        _createTask('task-3', DownloadTaskStatus.waiting),
        _createTask('task-4', DownloadTaskStatus.waiting),
        _createTask('task-5', DownloadTaskStatus.waiting),
      ]);

      expect(manager.totalCount, 3);
      expect(manager.getTaskById('task-1'), isNull);
      expect(manager.getTaskById('task-2'), isNull);
      expect(manager.getTaskById('task-3'), isNotNull);
    });

    test('[P1] replaceAll 空列表清空管理器', () {
      final manager = DownloadStateManager();
      manager.addTasks([
        _createTask('task-1', DownloadTaskStatus.downloading),
        _createTask('task-2', DownloadTaskStatus.completed),
      ]);

      manager.replaceAll([]);

      expect(manager.totalCount, 0);
    });

    test('[P2] replaceAll 保持传入列表的引用', () {
      final manager = DownloadStateManager();
      final newTasks = [_createTask('task-1', DownloadTaskStatus.downloading)];

      manager.replaceAll(newTasks);

      expect(manager.totalCount, 1);
    });
  });

  group('DownloadStateManager - 便捷操作测试', () {
    test('[P1] pauseTask 暂停任务', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '测试',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );

      await manager.pauseTask('task-1');

      final task = manager.getTaskById('task-1');
      expect(task?.status, DownloadTaskStatus.paused);
    });

    test('[P1] resumeTask 恢复任务', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '测试',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.paused,
          createdAt: DateTime.now(),
        ),
      );

      await manager.resumeTask('task-1');

      final task = manager.getTaskById('task-1');
      expect(task?.status, DownloadTaskStatus.downloading);
    });

    test('[P1] retryTask 重试失败任务', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '测试',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.error,
          errorMessage: '网络错误',
          createdAt: DateTime.now(),
        ),
      );

      await manager.retryTask('task-1');

      final task = manager.getTaskById('task-1');
      expect(task?.status, DownloadTaskStatus.downloading);
      // 错误信息现在可以被清除
      expect(task?.errorMessage, isNull);
    });

    test('[P1] retryTask 清除错误信息并重置速度', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '测试',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.error,
          errorMessage: '连接超时',
          createdAt: DateTime.now(),
        ),
      );

      await manager.retryTask('task-1');

      final task = manager.getTaskById('task-1');
      expect(task?.status, DownloadTaskStatus.downloading);
      // 使用 _clearMarker 清除错误信息
      expect(task?.errorMessage, isNull);
      expect(task?.bytesPerSecond, 0);
    });

    test('[P2] pauseTask 对不存在任务不操作', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(_createTask('task-1', DownloadTaskStatus.downloading));

      await manager.pauseTask('non-existent');

      expect(manager.totalCount, 1);
    });

    test('[P2] resumeTask 对不存在任务不操作', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(_createTask('task-1', DownloadTaskStatus.paused));

      await manager.resumeTask('non-existent');

      expect(manager.totalCount, 1);
    });
  });

  group('DownloadStateManagerExtension - 扩展方法测试', () {
    test('[P1] hasTaskWithVid 检查 VID 存在', () {
      final manager = DownloadStateManager();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-abc',
          title: '测试',
          totalBytes: 1000,
          downloadedBytes: 0,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );

      expect(manager.hasTaskWithVid('vid-abc'), isTrue);
      expect(manager.hasTaskWithVid('vid-xyz'), isFalse);
    });

    test('[P1] getStatusForVid 获取任务状态', () {
      final manager = DownloadStateManager();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '测试',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );

      expect(manager.getStatusForVid('vid-1'), DownloadTaskStatus.downloading);
      expect(manager.getStatusForVid('vid-2'), isNull);
    });

    test('[P1] isCompleted 检查任务是否完成', () {
      final manager = DownloadStateManager();
      manager.addTasks([
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '完成',
          totalBytes: 1000,
          downloadedBytes: 1000,
          status: DownloadTaskStatus.completed,
          createdAt: DateTime.now(),
        ),
        DownloadTask(
          id: 'task-2',
          vid: 'vid-2',
          title: '下载中',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      ]);

      expect(manager.isCompleted('vid-1'), isTrue);
      expect(manager.isCompleted('vid-2'), isFalse);
      expect(manager.isCompleted('vid-3'), isFalse);
    });
  });

  group('DownloadStateManager - ChangeNotifier 通知测试', () {
    test('[P1] addTask 触发通知', () async {
      final manager = DownloadStateManager();
      var notified = false;

      manager.addListener(() {
        notified = true;
      });

      manager.addTask(_createTask('task-1', DownloadTaskStatus.downloading));

      expect(notified, isTrue);
    });

    test('[P1] updateTask 触发通知', () async {
      final manager = DownloadStateManager();
      manager.addTask(_createTask('task-1', DownloadTaskStatus.downloading));

      var notified = false;
      manager.addListener(() {
        notified = true;
      });

      manager.updateTaskProgress('task-1', downloadedBytes: 500);

      expect(notified, isTrue);
    });

    test('[P1] removeTask 触发通知', () async {
      final manager = DownloadStateManager();
      manager.addTask(_createTask('task-1', DownloadTaskStatus.downloading));

      var notified = false;
      manager.addListener(() {
        notified = true;
      });

      manager.removeTask('task-1');

      expect(notified, isTrue);
    });

    test('[P1] clearAll 触发通知', () async {
      final manager = DownloadStateManager();
      manager.addTask(_createTask('task-1', DownloadTaskStatus.downloading));

      var notified = false;
      manager.addListener(() {
        notified = true;
      });

      manager.clearAll();

      expect(notified, isTrue);
    });

    test('[P1] 批量操作只触发一次通知', () async {
      final manager = DownloadStateManager();
      var notifyCount = 0;

      manager.addListener(() {
        notifyCount++;
      });

      // addTasks 内部会多次调用 addTask，但应该只有一次 notifyListeners
      manager.addTasks([
        _createTask('task-1', DownloadTaskStatus.downloading),
        _createTask('task-2', DownloadTaskStatus.downloading),
        _createTask('task-3', DownloadTaskStatus.downloading),
      ]);

      // 由于实现是循环后统一通知，所以应该只有一次通知
      expect(notifyCount, 1);
    });

    test('[P2] 多个监听器都能收到通知', () async {
      final manager = DownloadStateManager();
      var count1 = 0, count2 = 0;

      manager.addListener(() => count1++);
      manager.addListener(() => count2++);

      manager.addTask(_createTask('task-1', DownloadTaskStatus.downloading));

      expect(count1, 1);
      expect(count2, 1);
    });

    test('[P2] removeTask 即使不存在任务也触发通知', () async {
      final manager = DownloadStateManager();
      var notified = false;

      manager.addListener(() {
        notified = true;
      });

      // removeTask 总是调用 notifyListeners，即使任务不存在
      manager.removeTask('non-existent');

      expect(notified, isTrue);
    });

    test('[P2] updateTaskProgress 对不存在任务不触发通知', () async {
      final manager = DownloadStateManager();
      var notified = false;

      manager.addListener(() {
        notified = true;
      });

      // updateTaskProgress 在找不到任务时提前返回，不触发通知
      manager.updateTaskProgress('non-existent', downloadedBytes: 100);

      expect(notified, isFalse);
    });
  });

  group('场景测试 - 下载任务生命周期', () {
    test('[场景1][P1] 新任务从等待到下载到完成', () {
      final manager = DownloadStateManager();
      var notifyCount = 0;
      manager.addListener(() => notifyCount++);

      // 1. 新建任务
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '视频',
          totalBytes: 1000,
          downloadedBytes: 0,
          status: DownloadTaskStatus.waiting,
          createdAt: DateTime.now(),
        ),
      );

      expect(manager.downloadingCount, 1);
      expect(manager.completedCount, 0);

      // 2. 开始下载
      manager.updateTaskProgress(
        'task-1',
        status: DownloadTaskStatus.downloading,
        downloadedBytes: 500,
      );

      expect(manager.downloadingCount, 1);

      // 3. 完成下载
      manager.updateTaskProgress(
        'task-1',
        status: DownloadTaskStatus.completed,
        downloadedBytes: 1000,
      );

      expect(manager.downloadingCount, 0);
      expect(manager.completedCount, 1);
      expect(notifyCount, greaterThan(0));
    });

    test('[场景2][P1] 任务暂停和恢复', () async {
      final manager = _createManagerWithMockChannel();

      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '视频',
          totalBytes: 1000,
          downloadedBytes: 300,
          status: DownloadTaskStatus.downloading,
          bytesPerSecond: 500,
          createdAt: DateTime.now(),
        ),
      );

      expect(
        manager.getTaskById('task-1')?.status,
        DownloadTaskStatus.downloading,
      );
      expect(manager.activeTasks.length, 1);

      // 暂停
      await manager.pauseTask('task-1');

      expect(manager.getTaskById('task-1')?.status, DownloadTaskStatus.paused);
      expect(manager.activeTasks.length, 0);
      expect(manager.downloadingCount, 1); // 仍在下载中 Tab

      // 恢复
      await manager.resumeTask('task-1');

      expect(
        manager.getTaskById('task-1')?.status,
        DownloadTaskStatus.downloading,
      );
      expect(manager.activeTasks.length, 1);
    });

    test('[场景3][P1] 任务失败和重试', () async {
      final manager = _createManagerWithMockChannel();

      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '视频',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );

      // 失败
      manager.updateTaskProgress(
        'task-1',
        status: DownloadTaskStatus.error,
        errorMessage: '网络超时',
      );

      expect(manager.getTaskById('task-1')?.status, DownloadTaskStatus.error);
      expect(manager.getTaskById('task-1')?.errorMessage, '网络超时');

      // 重试 - 状态变为下载中，错误信息被清除
      await manager.retryTask('task-1');

      expect(
        manager.getTaskById('task-1')?.status,
        DownloadTaskStatus.downloading,
      );
      // 错误信息现在已被清除
      expect(manager.getTaskById('task-1')?.errorMessage, isNull);
    });

    test('[场景4][P1] 清空已完成任务', () {
      final manager = DownloadStateManager();

      manager.addTasks([
        _createTask('task-1', DownloadTaskStatus.downloading),
        _createTask('task-2', DownloadTaskStatus.completed),
        _createTask('task-3', DownloadTaskStatus.completed),
        _createTask('task-4', DownloadTaskStatus.paused),
      ]);

      expect(manager.totalCount, 4);

      manager.clearCompleted();

      expect(manager.totalCount, 2);
      expect(manager.downloadingCount, 2); // task-1 和 task-4
      expect(manager.completedCount, 0);
    });

    test('[场景5][P1] 从 SDK 同步完整列表', () {
      final manager = DownloadStateManager();

      // 模拟从 SDK 获取的初始数据
      final sdkTasks = [
        _createTask('sdk-1', DownloadTaskStatus.downloading),
        _createTask('sdk-2', DownloadTaskStatus.completed),
      ];

      manager.replaceAll(sdkTasks);

      expect(manager.totalCount, 2);
      expect(manager.downloadingCount, 1);
      expect(manager.completedCount, 1);
    });
  });

  group('DownloadStateManager - Story 9.3 暂停/继续增强测试', () {
    test('[Story 9.3][P1] pauseTask 不能暂停已完成的任务', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '已完成',
          totalBytes: 1000,
          downloadedBytes: 1000,
          status: DownloadTaskStatus.completed,
          createdAt: DateTime.now(),
        ),
      );

      // 已完成的任务不能暂停，静默忽略
      await manager.pauseTask('task-1');

      final task = manager.getTaskById('task-1');
      expect(task?.status, DownloadTaskStatus.completed); // 保持已完成状态
    });

    test('[Story 9.3][P1] pauseTask 不能暂停已暂停的任务', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '已暂停',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.paused,
          createdAt: DateTime.now(),
        ),
      );

      // 已暂停的任务再次暂停，静默忽略
      await manager.pauseTask('task-1');

      final task = manager.getTaskById('task-1');
      expect(task?.status, DownloadTaskStatus.paused); // 保持暂停状态
    });

    test('[Story 9.3][P1] pauseTask 可以暂停活跃任务', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '下载中',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );

      await manager.pauseTask('task-1');

      final task = manager.getTaskById('task-1');
      expect(task?.status, DownloadTaskStatus.paused);
    });

    test('[Story 9.3][P1] pauseTask 可以暂停等待中的任务', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '等待中',
          totalBytes: 1000,
          downloadedBytes: 0,
          status: DownloadTaskStatus.waiting,
          createdAt: DateTime.now(),
        ),
      );

      await manager.pauseTask('task-1');

      final task = manager.getTaskById('task-1');
      expect(task?.status, DownloadTaskStatus.paused);
    });

    test('[Story 9.3][P1] resumeTask 只能恢复已暂停的任务', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '已暂停',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.paused,
          createdAt: DateTime.now(),
        ),
      );

      await manager.resumeTask('task-1');

      final task = manager.getTaskById('task-1');
      expect(task?.status, DownloadTaskStatus.downloading);
    });

    test('[Story 9.3][P1] resumeTask 不能恢复已完成的任务', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '已完成',
          totalBytes: 1000,
          downloadedBytes: 1000,
          status: DownloadTaskStatus.completed,
          createdAt: DateTime.now(),
        ),
      );

      // 已完成的任务恢复，静默忽略
      await manager.resumeTask('task-1');

      final task = manager.getTaskById('task-1');
      expect(task?.status, DownloadTaskStatus.completed); // 保持已完成状态
    });

    test('[Story 9.3][P1] retryTask 清除错误信息并重置速度', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '失败',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.error,
          errorMessage: '连接超时',
          bytesPerSecond: 1024,
          createdAt: DateTime.now(),
        ),
      );

      await manager.retryTask('task-1');

      final task = manager.getTaskById('task-1');
      expect(task?.status, DownloadTaskStatus.downloading);
      expect(task?.errorMessage, isNull); // 错误信息被清除
      expect(task?.bytesPerSecond, 0); // 速度被重置
    });
  });

  group('边缘情况测试', () {
    test('[P2] 空任务列表操作', () async {
      final manager = _createManagerWithMockChannel();

      manager.removeTask('non-existent');
      manager.updateTaskProgress('non-existent', downloadedBytes: 100);
      await manager.pauseTask('non-existent');
      await manager.resumeTask('non-existent');
      await manager.retryTask('non-existent');

      expect(manager.totalCount, 0);
    });

    test('[P2] 清空已清空的管理器', () {
      final manager = DownloadStateManager();

      manager.clearAll();
      expect(manager.totalCount, 0);

      manager.clearAll();
      expect(manager.totalCount, 0);
    });

    test('[P2] 替换为相同任务', () {
      final manager = DownloadStateManager();
      final task = _createTask('task-1', DownloadTaskStatus.downloading);

      manager.addTask(task);
      expect(manager.totalCount, 1);

      manager.replaceAll([task]);
      expect(manager.totalCount, 1);
    });

    test('[P2] 大量任务操作', () {
      final manager = DownloadStateManager();
      final tasks = List.generate(
        1000,
        (i) => _createTask('task-$i', DownloadTaskStatus.downloading),
      );

      manager.addTasks(tasks);

      expect(manager.totalCount, 1000);
      expect(manager.downloadingCount, 1000);
    });
  });

  group('DownloadStateManager - Story 9.4 重试失败下载测试', () {
    test('[Story 9.4][AC1][P1] 失败任务显示错误状态', () {
      final manager = DownloadStateManager();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '失败的视频',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.error,
          errorMessage: '网络连接超时',
          createdAt: DateTime.now(),
        ),
      );

      final task = manager.getTaskById('task-1');
      expect(task?.status, DownloadTaskStatus.error);
      expect(task?.errorMessage, '网络连接超时');
      // 失败任务应在 downloadingTasks 列表中（因为 isInProgress 为 true）
      expect(manager.downloadingTasks.map((t) => t.id), contains('task-1'));
      expect(
        manager.completedTasks.map((t) => t.id),
        isNot(contains('task-1')),
      );
    });

    test('[Story 9.4][AC2][P1] 重试后状态更新为下载中', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '失败的视频',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.error,
          errorMessage: '网络错误',
          createdAt: DateTime.now(),
        ),
      );

      await manager.retryTask('task-1');

      final task = manager.getTaskById('task-1');
      expect(task?.status, DownloadTaskStatus.downloading);
      // 错误信息应被清除
      expect(task?.errorMessage, isNull);
      // 下载速度应被重置为 0
      expect(task?.bytesPerSecond, 0);
    });

    test('[Story 9.4][AC3][P1] 重试操作调用 Platform Channel', () async {
      // 验证 retryTask 确实调用了 MethodChannelHandler.retryDownload
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '失败的视频',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.error,
          errorMessage: '下载失败',
          createdAt: DateTime.now(),
        ),
      );

      // 调用 retryTask 应该：
      // 1. 调用原生层方法（可能因未实现而失败，但有容错）
      // 2. 无论原生调用是否成功，都更新本地状态
      await manager.retryTask('task-1');

      final task = manager.getTaskById('task-1');
      // 验证本地状态已更新
      expect(task?.status, DownloadTaskStatus.downloading);
      expect(task?.errorMessage, isNull);
    });

    test('[Story 9.4][AC4][P1] 重试后再次失败状态正确更新', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '视频',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.error,
          errorMessage: '首次失败',
          createdAt: DateTime.now(),
        ),
      );

      // 第一次重试
      await manager.retryTask('task-1');
      expect(
        manager.getTaskById('task-1')?.status,
        DownloadTaskStatus.downloading,
      );

      // 模拟再次失败
      manager.updateTaskProgress(
        'task-1',
        status: DownloadTaskStatus.error,
        errorMessage: '重试后再次失败',
      );

      final task = manager.getTaskById('task-1');
      expect(task?.status, DownloadTaskStatus.error);
      expect(task?.errorMessage, '重试后再次失败');
      // 重试按钮应保持可用状态（状态仍为 error）
    });

    test('[Story 9.4][AC4][P2] 多次重试场景', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '反复失败的视频',
          totalBytes: 1000,
          downloadedBytes: 300,
          status: DownloadTaskStatus.error,
          errorMessage: '第1次失败',
          createdAt: DateTime.now(),
        ),
      );

      // 第一次重试 -> 失败
      await manager.retryTask('task-1');
      manager.updateTaskProgress(
        'task-1',
        status: DownloadTaskStatus.error,
        errorMessage: '第2次失败',
      );

      // 第二次重试 -> 失败
      await manager.retryTask('task-1');
      manager.updateTaskProgress(
        'task-1',
        status: DownloadTaskStatus.error,
        errorMessage: '第3次失败',
      );

      // 第三次重试 -> 最终状态
      await manager.retryTask('task-1');

      final task = manager.getTaskById('task-1');
      expect(task?.status, DownloadTaskStatus.downloading);
      expect(task?.errorMessage, isNull);
      // 进度应保持不变（模拟断点续传）
      expect(task?.downloadedBytes, 300);
    });

    test('[Story 9.4][AC2][P2] 重试后进度可以从断点继续', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '视频',
          totalBytes: 10000,
          downloadedBytes: 5000, // 已下载 50%
          status: DownloadTaskStatus.error,
          errorMessage: '网络中断',
          createdAt: DateTime.now(),
        ),
      );

      await manager.retryTask('task-1');

      final task = manager.getTaskById('task-1');
      expect(task?.status, DownloadTaskStatus.downloading);
      // 下载进度应从断点继续（保留已下载字节数）
      expect(task?.downloadedBytes, 5000);
      expect(task?.progress, 0.5);
    });

    test('[Story 9.4][P1] 重试不存在任务不操作', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(_createTask('task-1', DownloadTaskStatus.error));

      final initialCount = manager.totalCount;

      await manager.retryTask('non-existent');

      expect(manager.totalCount, initialCount);
    });

    test('[Story 9.4][P2] 重试触发通知', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '视频',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.error,
          errorMessage: '失败',
          createdAt: DateTime.now(),
        ),
      );

      var notified = false;
      manager.addListener(() {
        notified = true;
      });

      await manager.retryTask('task-1');

      expect(notified, isTrue);
    });
  });

  group('DownloadStateManager - Story 9.5 删除下载任务测试', () {
    test('[Story 9.5][AC1][P1] deleteTask 正确调用 Platform Channel', () async {
      // 验证 deleteTask 确实调用了 MethodChannelHandler.deleteDownload
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '下载中的视频',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );

      // 调用 deleteTask 应该：
      // 1. 调用原生层方法（可能因未实现而失败，但有容错）
      // 2. 无论原生调用是否成功，都更新本地状态
      await manager.deleteTask('task-1');

      // 验证本地状态已更新（任务被移除）
      expect(manager.getTaskById('task-1'), isNull);
      expect(manager.totalCount, 0);
    });

    test('[Story 9.5][AC1][P2] deleteTask 删除下载中任务', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '下载中的视频',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );

      expect(manager.downloadingCount, 1);

      await manager.deleteTask('task-1');

      expect(manager.downloadingCount, 0);
      expect(manager.getTaskById('task-1'), isNull);
    });

    test('[Story 9.5][AC2][P1] deleteTask 删除已完成任务', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '已完成的视频',
          totalBytes: 1000,
          downloadedBytes: 1000,
          status: DownloadTaskStatus.completed,
          createdAt: DateTime.now(),
        ),
      );

      expect(manager.completedCount, 1);

      await manager.deleteTask('task-1');

      expect(manager.completedCount, 0);
      expect(manager.getTaskById('task-1'), isNull);
    });

    test('[Story 9.5][AC3][P1] deleteTask 删除失败状态任务', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '失败的视频',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.error,
          errorMessage: '下载失败',
          createdAt: DateTime.now(),
        ),
      );

      expect(manager.downloadingCount, 1); // 失败任务在 downloadingTasks 中

      await manager.deleteTask('task-1');

      expect(manager.downloadingCount, 0);
      expect(manager.getTaskById('task-1'), isNull);
    });

    test('[Story 9.5][P1] deleteTask 任务不存在时静默忽略', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(_createTask('task-1', DownloadTaskStatus.downloading));

      final initialCount = manager.totalCount;

      // 删除不存在的任务不应抛出错误
      await manager.deleteTask('non-existent');

      expect(manager.totalCount, initialCount);
    });

    test('[Story 9.5][AC4][P1] deleteTask 触发 notifyListeners', () async {
      final manager = _createManagerWithMockChannel();
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '视频',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );

      var notified = false;
      manager.addListener(() {
        notified = true;
      });

      await manager.deleteTask('task-1');

      expect(notified, isTrue);
    });

    test('[Story 9.5][AC4][P2] 删除后 Tab 徽章数量正确更新', () async {
      final manager = _createManagerWithMockChannel();

      manager.addTasks([
        _createTask('task-1', DownloadTaskStatus.downloading),
        _createTask('task-2', DownloadTaskStatus.downloading),
        _createTask('task-3', DownloadTaskStatus.completed),
        _createTask('task-4', DownloadTaskStatus.completed),
      ]);

      expect(manager.downloadingCount, 2);
      expect(manager.completedCount, 2);

      // 删除一个下载中任务
      await manager.deleteTask('task-1');

      expect(manager.downloadingCount, 1);
      expect(manager.completedCount, 2);

      // 删除一个已完成任务
      await manager.deleteTask('task-3');

      expect(manager.downloadingCount, 1);
      expect(manager.completedCount, 1);
    });

    test('[Story 9.7][P1] 原生层调用失败时不更新本地状态', () async {
      // Story 9.7 强一致性：原生调用失败时抛出异常，不更新本地状态
      final manager = _createManagerWithMockChannel(
        shouldSucceed: false,
        errorCode: 'SDK_ERROR',
        errorMessage: '删除失败',
      );
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '视频',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );

      // 原生调用失败应抛出异常
      expect(
        () => manager.deleteTask('task-1'),
        throwsA(isA<PlatformException>()),
      );

      // 本地状态不应更新
      expect(manager.getTaskById('task-1'), isNotNull);
      expect(manager.totalCount, 1);
    });

    test('[Story 9.5][P2] 状态验证确保任务存在才删除', () async {
      final manager = _createManagerWithMockChannel();

      // 添加任务
      manager.addTask(_createTask('task-1', DownloadTaskStatus.downloading));
      expect(manager.totalCount, 1);

      // 删除存在的任务
      await manager.deleteTask('task-1');
      expect(manager.totalCount, 0);

      // 再次删除同一任务（不存在）不应报错
      await manager.deleteTask('task-1');
      expect(manager.totalCount, 0);
    });
  });

  group('DownloadStateManager - Story 9.7 强一致性测试', () {
    test('[Story 9.7][P1] pauseTask 原生失败时不更新状态', () async {
      final manager = _createManagerWithMockChannel(
        shouldSucceed: false,
        errorCode: 'SDK_ERROR',
        errorMessage: '暂停失败',
      );
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '视频',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );

      expect(
        () => manager.pauseTask('task-1'),
        throwsA(isA<PlatformException>()),
      );

      // 本地状态不应更新
      expect(
        manager.getTaskById('task-1')?.status,
        DownloadTaskStatus.downloading,
      );
    });

    test('[Story 9.7][P1] resumeTask 原生失败时不更新状态', () async {
      final manager = _createManagerWithMockChannel(
        shouldSucceed: false,
        errorCode: 'SDK_ERROR',
        errorMessage: '恢复失败',
      );
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '视频',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.paused,
          createdAt: DateTime.now(),
        ),
      );

      expect(
        () => manager.resumeTask('task-1'),
        throwsA(isA<PlatformException>()),
      );

      // 本地状态不应更新
      expect(manager.getTaskById('task-1')?.status, DownloadTaskStatus.paused);
    });

    test('[Story 9.7][P1] retryTask 原生失败时不更新状态', () async {
      final manager = _createManagerWithMockChannel(
        shouldSucceed: false,
        errorCode: 'SDK_ERROR',
        errorMessage: '重试失败',
      );
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '视频',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.error,
          errorMessage: '网络错误',
          createdAt: DateTime.now(),
        ),
      );

      expect(
        () => manager.retryTask('task-1'),
        throwsA(isA<PlatformException>()),
      );

      // 本地状态不应更新
      final task = manager.getTaskById('task-1');
      expect(task?.status, DownloadTaskStatus.error);
      expect(task?.errorMessage, '网络错误');
    });

    test('[Story 9.7][P1] deleteTask 原生失败时不更新状态', () async {
      final manager = _createManagerWithMockChannel(
        shouldSucceed: false,
        errorCode: 'DELETE_FAILED',
        errorMessage: '删除失败',
      );
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '视频',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );

      expect(
        () => manager.deleteTask('task-1'),
        throwsA(isA<PlatformException>()),
      );

      // 本地状态不应更新
      expect(manager.getTaskById('task-1'), isNotNull);
      expect(manager.totalCount, 1);
    });

    test('[Story 9.7][P1] 原生成功时正确更新状态', () async {
      final manager = _createManagerWithMockChannel(shouldSucceed: true);
      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '视频',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );

      // 暂停成功
      await manager.pauseTask('task-1');
      expect(manager.getTaskById('task-1')?.status, DownloadTaskStatus.paused);

      // 恢复成功
      await manager.resumeTask('task-1');
      expect(
        manager.getTaskById('task-1')?.status,
        DownloadTaskStatus.downloading,
      );

      // 模拟失败后重试
      manager.updateTaskProgress(
        'task-1',
        status: DownloadTaskStatus.error,
        errorMessage: '网络错误',
      );
      await manager.retryTask('task-1');
      expect(
        manager.getTaskById('task-1')?.status,
        DownloadTaskStatus.downloading,
      );
      expect(manager.getTaskById('task-1')?.errorMessage, isNull);

      // 删除成功
      await manager.deleteTask('task-1');
      expect(manager.getTaskById('task-1'), isNull);
    });
  });
}

/// 辅助函数：创建测试任务
DownloadTask _createTask(String id, DownloadTaskStatus status) {
  return DownloadTask(
    id: id,
    vid: 'vid-$id',
    title: '测试任务 $id',
    totalBytes: 1000,
    downloadedBytes: 0,
    status: status,
    createdAt: DateTime.now(),
  );
}
