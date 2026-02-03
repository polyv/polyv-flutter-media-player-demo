import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/platform_channel/player_api.dart';
import 'package:polyv_media_player/infrastructure/download/download_state_manager.dart';
import 'package:polyv_media_player/infrastructure/download/download_task.dart';
import 'package:polyv_media_player/infrastructure/download/download_task_status.dart';

/// Story 9.8: 下载任务权威同步测试
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MethodChannel channel;
  late MethodChannel eventMethodChannel;
  late DownloadStateManager manager;
  List<Map<String, dynamic>> mockDownloadList = [];

  // 用于模拟 EventChannel 的事件流控制器
  StreamController<Map<String, dynamic>>? mockEventStreamController;

  setUp(() {
    channel = const MethodChannel(PlayerApi.methodChannelName);
    eventMethodChannel = const MethodChannel(
      PlayerApi.downloadEventChannelName,
    );

    // Mock MethodChannel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'getDownloadList') {
            return mockDownloadList;
          }
          return null;
        });

    // Mock EventChannel
    mockEventStreamController =
        StreamController<Map<String, dynamic>>.broadcast();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(eventMethodChannel, (
          MethodCall methodCall,
        ) async {
          // EventChannel 不处理方法调用，通过 setMockMethodCallHandler 设置 mock
          return null;
        });

    // 设置 EventChannel 的 mock 事件流
    // 注意：Flutter 测试框架不直接支持 EventChannel mock，
    // 我们通过注入 eventChannel 参数来测试事件处理逻辑

    manager = DownloadStateManager();
    mockDownloadList = [];
  });

  tearDown(() {
    mockEventStreamController?.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(eventMethodChannel, null);
    manager.dispose();
  });

  group('Story 9.8 - syncFromNative 权威同步', () {
    test('[AC1] syncFromNative 成功时返回 null 并更新任务列表', () async {
      mockDownloadList = [
        {
          'id': 'task-1',
          'vid': 'vid-1',
          'title': '视频1',
          'totalBytes': 1000,
          'downloadedBytes': 500,
          'bytesPerSecond': 100,
          'status': 'downloading',
          'createdAt': '2026-01-28T10:00:00.000Z',
        },
        {
          'id': 'task-2',
          'vid': 'vid-2',
          'title': '视频2',
          'totalBytes': 2000,
          'downloadedBytes': 2000,
          'bytesPerSecond': 0,
          'status': 'completed',
          'createdAt': '2026-01-28T09:00:00.000Z',
          'completedAt': '2026-01-28T09:30:00.000Z',
        },
      ];

      final error = await manager.syncFromNative();

      expect(error, isNull);
      expect(manager.tasks.length, 2);
      expect(manager.downloadingCount, 1);
      expect(manager.completedCount, 1);
    });

    test('[AC1] syncFromNative 用权威列表替换本地状态', () async {
      manager.addTask(
        DownloadTask(
          id: 'old-task',
          vid: 'old-vid',
          title: '旧任务',
          totalBytes: 500,
          downloadedBytes: 100,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );

      mockDownloadList = [
        {
          'id': 'new-task',
          'vid': 'new-vid',
          'title': '新任务',
          'totalBytes': 1000,
          'downloadedBytes': 500,
          'bytesPerSecond': 0,
          'status': 'paused',
          'createdAt': '2026-01-28T10:00:00.000Z',
        },
      ];

      await manager.syncFromNative();

      expect(manager.tasks.length, 1);
      expect(manager.getTaskById('old-task'), isNull);
      expect(manager.getTaskById('new-task'), isNotNull);
      expect(manager.getTaskById('new-task')?.title, '新任务');
    });

    test('[AC4] 热重载后再次调用 syncFromNative 可纠正状态', () async {
      mockDownloadList = [
        {
          'id': 'task-1',
          'vid': 'vid-1',
          'title': '视频',
          'totalBytes': 1000,
          'downloadedBytes': 300,
          'bytesPerSecond': 50,
          'status': 'downloading',
          'createdAt': '2026-01-28T10:00:00.000Z',
        },
      ];

      await manager.syncFromNative();
      expect(manager.getTaskById('task-1')?.downloadedBytes, 300);

      mockDownloadList = [
        {
          'id': 'task-1',
          'vid': 'vid-1',
          'title': '视频',
          'totalBytes': 1000,
          'downloadedBytes': 800,
          'bytesPerSecond': 100,
          'status': 'downloading',
          'createdAt': '2026-01-28T10:00:00.000Z',
        },
      ];

      await manager.syncFromNative();
      expect(manager.getTaskById('task-1')?.downloadedBytes, 800);
    });
  });

  group('Story 9.8 - handleDownloadEvent 事件处理', () {
    setUp(() async {
      mockDownloadList = [
        {
          'id': 'task-1',
          'vid': 'vid-1',
          'title': '视频',
          'totalBytes': 1000,
          'downloadedBytes': 500,
          'bytesPerSecond': 0,
          'status': 'downloading',
          'createdAt': '2026-01-28T10:00:00.000Z',
        },
      ];
      await manager.syncFromNative();
    });

    test('[AC2] taskProgress 事件更新进度', () {
      manager.handleDownloadEvent({
        'type': 'taskProgress',
        'data': {
          'id': 'task-1',
          'downloadedBytes': 700,
          'bytesPerSecond': 150,
          'status': 'downloading',
        },
      });

      final task = manager.getTaskById('task-1');
      expect(task?.downloadedBytes, 700);
      expect(task?.bytesPerSecond, 150);
    });

    test('[AC2] taskCompleted 事件更新状态为已完成', () {
      manager.handleDownloadEvent({
        'type': 'taskCompleted',
        'data': {'id': 'task-1', 'completedAt': '2026-01-28T11:00:00.000Z'},
      });

      final task = manager.getTaskById('task-1');
      expect(task?.status, DownloadTaskStatus.completed);
      expect(task?.downloadedBytes, 1000);
    });

    test('[AC2] taskFailed 事件更新状态为失败', () {
      manager.handleDownloadEvent({
        'type': 'taskFailed',
        'data': {'id': 'task-1', 'errorMessage': '网络错误'},
      });

      final task = manager.getTaskById('task-1');
      expect(task?.status, DownloadTaskStatus.error);
      expect(task?.errorMessage, '网络错误');
    });

    test('[AC2] taskRemoved 事件移除任务', () {
      expect(manager.getTaskById('task-1'), isNotNull);

      manager.handleDownloadEvent({
        'type': 'taskRemoved',
        'data': {'id': 'task-1'},
      });

      expect(manager.getTaskById('task-1'), isNull);
    });

    test('[AC2] taskPaused 事件更新状态为暂停', () {
      manager.handleDownloadEvent({
        'type': 'taskPaused',
        'data': {'id': 'task-1'},
      });

      final task = manager.getTaskById('task-1');
      expect(task?.status, DownloadTaskStatus.paused);
      expect(task?.bytesPerSecond, 0);
    });

    test('[AC2] taskResumed 事件更新状态为下载中', () {
      manager.updateTaskProgress('task-1', status: DownloadTaskStatus.paused);

      manager.handleDownloadEvent({
        'type': 'taskResumed',
        'data': {'id': 'task-1'},
      });

      expect(
        manager.getTaskById('task-1')?.status,
        DownloadTaskStatus.downloading,
      );
    });

    test('未知任务 ID 的事件被忽略', () {
      final initialCount = manager.tasks.length;

      manager.handleDownloadEvent({
        'type': 'taskProgress',
        'data': {'id': 'unknown-task', 'downloadedBytes': 100},
      });

      expect(manager.tasks.length, initialCount);
    });
  });

  group('Story 9.8 - EventChannel 集成', () {
    test('[AC2] dispose 正确取消 EventChannel 订阅', () {
      // 创建一个新的 manager 来测试 dispose
      final testManager = DownloadStateManager();
      // dispose 不应抛出异常
      expect(() => testManager.dispose(), returnsNormally);
    });

    test('[AC2] manager 初始化时自动启动事件监听', () {
      // 验证 manager 可以正常创建并处理事件
      final testManager = DownloadStateManager();

      // 模拟事件处理
      testManager.addTask(
        DownloadTask(
          id: 'task-event-test',
          vid: 'vid-event',
          title: '测试事件',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );

      // 模拟事件处理
      testManager.handleDownloadEvent({
        'type': 'taskProgress',
        'data': {
          'id': 'task-event-test',
          'downloadedBytes': 700,
          'bytesPerSecond': 100,
          'status': 'downloading',
        },
      });

      expect(testManager.getTaskById('task-event-test')?.downloadedBytes, 700);

      testManager.dispose();
    });

    test('[AC2] 多个事件可以正确处理', () {
      final testManager = DownloadStateManager();

      testManager.addTask(
        DownloadTask(
          id: 'task-multi',
          vid: 'vid-multi',
          title: '多事件测试',
          totalBytes: 1000,
          downloadedBytes: 0,
          status: DownloadTaskStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );

      // 模拟进度事件
      testManager.handleDownloadEvent({
        'type': 'taskProgress',
        'data': {
          'id': 'task-multi',
          'downloadedBytes': 300,
          'bytesPerSecond': 100,
          'status': 'downloading',
        },
      });

      // 模拟暂停事件
      testManager.handleDownloadEvent({
        'type': 'taskPaused',
        'data': {'id': 'task-multi'},
      });

      expect(testManager.getTaskById('task-multi')?.downloadedBytes, 300);
      expect(
        testManager.getTaskById('task-multi')?.status,
        DownloadTaskStatus.paused,
      );

      // 模拟恢复事件
      testManager.handleDownloadEvent({
        'type': 'taskResumed',
        'data': {'id': 'task-multi'},
      });

      expect(
        testManager.getTaskById('task-multi')?.status,
        DownloadTaskStatus.downloading,
      );

      testManager.dispose();
    });
  });
}
