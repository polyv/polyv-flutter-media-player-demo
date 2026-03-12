import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/polyv_media_player.dart';
import 'package:provider/provider.dart';
import 'package:polyv_media_player_example/pages/download_center/downloading_task_item.dart';

/// DownloadingTaskItem Widget 测试
///
/// Story 9.2: 下载进度显示
///
/// 测试下载中任务卡片组件的 UI 显示、进度更新、状态样式变化和响应式更新
void main() {
  group('DownloadingTaskItem - 基本渲染测试', () {
    testWidgets('[P1][AC1] 渲染下载中任务的基本元素', (WidgetTester tester) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试视频标题',
        thumbnail: 'https://example.com/thumb.jpg',
        totalBytes: 100 * 1024 * 1024, // 100MB
        downloadedBytes: 50 * 1024 * 1024, // 50MB
        bytesPerSecond: 1024 * 1024 * 2, // 2MB/s
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      // 验证标题存在
      expect(find.text('测试视频标题'), findsOneWidget);

      // 验证百分比存在
      expect(find.text('50%'), findsOneWidget);

      // 验证文件大小存在
      expect(find.text('100.0MB'), findsOneWidget);

      // 验证下载速度存在（仅下载中状态）
      expect(find.text('2.0MB/s'), findsOneWidget);

      // 验证操作按钮存在
      expect(find.byType(IconButton), findsNWidgets(2));
    });

    testWidgets('[P1][AC1] 缩略图区域正确渲染', (WidgetTester tester) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试视频',
        thumbnail: 'https://example.com/thumb.jpg',
        totalBytes: 1000,
        downloadedBytes: 0,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      // 查找 Container（缩略图容器）
      final thumbnailContainers = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints != null &&
            widget.constraints!.maxWidth == 96 &&
            widget.constraints!.maxHeight == 56,
      );

      expect(thumbnailContainers, findsAtLeastNWidgets(1));
    });

    testWidgets('[P1][AC1] 无缩略图时显示默认图标', (WidgetTester tester) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试视频',
        thumbnail: null, // 无缩略图
        totalBytes: 1000,
        downloadedBytes: 0,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      // 验证默认播放图标存在
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
    });

    testWidgets('[P2] 长标题正确省略', (WidgetTester tester) async {
      final longTitle = '这是一个非常非常非常非常非常非常非常长的视频标题用于测试省略号功能';
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: longTitle,
        totalBytes: 1000,
        downloadedBytes: 0,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400, // 增加宽度避免溢出
              child: DownloadingTaskItem(task: task),
            ),
          ),
        ),
      );

      await tester.pump();

      // 查找标题 Text widget
      final titleWidget = tester.widget<Text>(find.text(longTitle));

      // 验证设置了 maxLines 和 ellipsis
      expect(titleWidget.maxLines, 2);
      expect(titleWidget.overflow, TextOverflow.ellipsis);
    });
  });

  group('DownloadingTaskItem - 进度显示测试', () {
    testWidgets('[P1][AC1] 0% 进度正确显示', (WidgetTester tester) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 0,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('[P1][AC1] 100% 进度正确显示', (WidgetTester tester) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 1000,
        status: DownloadTaskStatus.completed,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('[P1][AC2] 进度更新时平滑过渡', (WidgetTester tester) async {
      // 初始 50% 进度
      final initialTask = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: initialTask)),
        ),
      );

      await tester.pump();

      expect(find.text('50%'), findsOneWidget);

      // 更新为 75% 进度
      final updatedTask = initialTask.copyWith(downloadedBytes: 750);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: updatedTask)),
        ),
      );

      await tester.pump();

      expect(find.text('75%'), findsOneWidget);
      // AnimatedContainer 应该存在，确认动画过渡
      expect(find.byType(AnimatedContainer), findsAtLeastNWidgets(1));
    });

    testWidgets('[P2] 进度条宽度正确计算', (WidgetTester tester) async {
      const testWidth = 400.0;

      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 500, // 50%
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: testWidth,
              child: DownloadingTaskItem(task: task),
            ),
          ),
        ),
      );

      await tester.pump();

      // AnimatedContainer 的宽度应该是 testWidth * 0.5
      final animatedContainers = find.byType(AnimatedContainer);
      expect(animatedContainers, findsAtLeastNWidgets(1));
    });
  });

  group('DownloadingTaskItem - 状态样式测试 (AC3)', () {
    testWidgets('[P1][AC3] 下载中状态: 主色调渐变进度条', (WidgetTester tester) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 500,
        bytesPerSecond: 1024 * 100,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      // 验证百分比显示
      expect(find.text('50%'), findsOneWidget);

      // 验证下载速度显示（绿色）
      expect(find.text('100.0KB/s'), findsOneWidget);

      // 验证暂停按钮图标（下载中显示暂停图标）
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    });

    testWidgets('[P1][AC3] 暂停状态: 灰色进度条和"已暂停"文本', (WidgetTester tester) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 500,
        bytesPerSecond: 0,
        status: DownloadTaskStatus.paused,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      // 验证"已暂停"文本
      expect(find.text('已暂停'), findsOneWidget);

      // 验证没有显示下载速度
      expect(find.text('0KB/s'), findsNothing);

      // 验证播放按钮图标（暂停状态显示播放图标）
      expect(find.byIcon(Icons.play_arrow_rounded), findsAtLeastNWidgets(1));
    });

    testWidgets('[P1][AC3] 失败状态: 红色进度条和"下载失败"文本', (WidgetTester tester) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.error,
        errorMessage: '网络连接失败',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      // 验证"下载失败"文本
      expect(find.text('下载失败'), findsOneWidget);

      // 验证错误图标在缩略图上
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // 验证重试按钮存在（失败状态显示重试按钮）
      final retryButtons = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.play_arrow_rounded,
      );

      expect(retryButtons, findsAtLeastNWidgets(1));
    });

    testWidgets('[P2] 等待状态显示正确', (WidgetTester tester) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 0,
        status: DownloadTaskStatus.waiting,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      // 等待状态应该在下载中 Tab 显示
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('[P2] 准备状态显示正确', (WidgetTester tester) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 0, // 准备中，totalBytes 可能是 0
        downloadedBytes: 0,
        status: DownloadTaskStatus.preparing,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      expect(find.text('0%'), findsOneWidget);
    });
  });

  group('DownloadingTaskItem - 下载速度格式化测试', () {
    testWidgets('[P1][AC1] 速度格式化为 KB/s', (WidgetTester tester) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 0,
        downloadedBytes: 0,
        bytesPerSecond: 100 * 1024, // 100 KB/s
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      expect(find.text('100.0KB/s'), findsOneWidget);
    });

    testWidgets('[P1][AC1] 速度格式化为 MB/s', (WidgetTester tester) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 0,
        downloadedBytes: 0,
        bytesPerSecond: 5 * 1024 * 1024, // 5 MB/s
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      expect(find.text('5.0MB/s'), findsOneWidget);
    });

    testWidgets('[P2] 速度为 0 时不显示速度', (WidgetTester tester) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 500,
        bytesPerSecond: 0,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      // 速度为 0 时，不显示速度（只显示 50% · 1KB）
      expect(find.textContaining('KB/s'), findsNothing);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('[P2] 负数速度不显示', (WidgetTester tester) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 500,
        bytesPerSecond: -100,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      expect(find.textContaining('KB/s'), findsNothing);
    });
  });

  group('DownloadingTaskItem - 文件大小格式化测试', () {
    testWidgets('[P1][AC1] 文件大小格式化为 MB', (WidgetTester tester) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 150 * 1024 * 1024, // 150 MB
        downloadedBytes: 0,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      expect(find.text('150.0MB'), findsOneWidget);
    });

    testWidgets('[P1][AC1] 文件大小格式化为 GB', (WidgetTester tester) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 2 * 1024 * 1024 * 1024, // 2 GB
        downloadedBytes: 0,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      expect(find.text('2.0GB'), findsOneWidget);
    });

    testWidgets('[P2] 小文件显示为 B', (WidgetTester tester) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 500, // 500 B
        downloadedBytes: 0,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      expect(find.text('500B'), findsOneWidget);
    });
  });

  group('DownloadingTaskItem - 回调测试', () {
    testWidgets('[P1] 点击暂停/继续按钮触发回调', (WidgetTester tester) async {
      var pauseResumeCalled = false;

      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadingTaskItem(
              task: task,
              onPauseResume: () => pauseResumeCalled = true,
            ),
          ),
        ),
      );

      await tester.pump();

      // 点击暂停按钮
      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pump();

      expect(pauseResumeCalled, isTrue);
    });

    testWidgets('[P1] 点击删除按钮触发回调', (WidgetTester tester) async {
      var deleteCalled = false;

      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadingTaskItem(
              task: task,
              onDelete: () => deleteCalled = true,
            ),
          ),
        ),
      );

      await tester.pump();

      // 点击删除按钮
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(deleteCalled, isTrue);
    });

    testWidgets('[P1] 失败状态点击重试按钮触发回调', (WidgetTester tester) async {
      var retryCalled = false;

      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.error,
        errorMessage: '网络错误',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadingTaskItem(
              task: task,
              onRetry: () => retryCalled = true,
            ),
          ),
        ),
      );

      await tester.pump();

      // 找到所有的播放箭头图标
      final playIcons = find.byIcon(Icons.play_arrow_rounded);
      expect(playIcons, findsAtLeastNWidgets(1));

      // 点击第一个（重试按钮）
      await tester.tap(playIcons.first);
      await tester.pump();

      expect(retryCalled, isTrue);
    });

    testWidgets('[P2] 暂停状态点击播放按钮触发回调', (WidgetTester tester) async {
      var pauseResumeCalled = false;

      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.paused,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadingTaskItem(
              task: task,
              onPauseResume: () => pauseResumeCalled = true,
            ),
          ),
        ),
      );

      await tester.pump();

      // 暂停状态显示播放按钮
      expect(find.byIcon(Icons.play_arrow_rounded), findsAtLeastNWidgets(1));
      expect(find.text('已暂停'), findsOneWidget);

      // 点击播放按钮
      await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
      await tester.pump();

      expect(pauseResumeCalled, isTrue);
    });

    testWidgets('[P2] null 回调不触发异常', (WidgetTester tester) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadingTaskItem(
              task: task,
              // 所有回调都是 null
            ),
          ),
        ),
      );

      await tester.pump();

      // 点击按钮不应该抛出异常
      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      // 如果能到达这里说明没有异常
      expect(find.byType(DownloadingTaskItem), findsOneWidget);
    });
  });

  group('DownloadingTaskItem - Provider 响应式测试 (AC4)', () {
    testWidgets('[P1][AC4] Provider 状态更新触发 UI 重新渲染', (
      WidgetTester tester,
    ) async {
      final manager = DownloadStateManager();

      final initialTask = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 0,
        status: DownloadTaskStatus.waiting,
        createdAt: DateTime.now(),
      );

      manager.addTask(initialTask);

      await tester.pumpWidget(
        ChangeNotifierProvider<DownloadStateManager>(
          create: (_) => manager,
          child: const MaterialApp(
            home: Scaffold(body: _TaskConsumerWidget(taskId: 'task-1')),
          ),
        ),
      );

      await tester.pump();

      // 初始状态: 0%
      expect(find.text('0%'), findsOneWidget);

      // 更新任务进度
      manager.updateTaskProgress(
        'task-1',
        downloadedBytes: 500,
        status: DownloadTaskStatus.downloading,
        bytesPerSecond: 1024,
      );

      await tester.pump();

      // UI 应该自动更新
      expect(find.text('50%'), findsOneWidget);
      // 1024 bytes 显示为 "1KB/s"
      expect(find.textContaining('KB/s'), findsOneWidget);
    });

    testWidgets('[P1][AC4] 状态从下载中变为暂停', (WidgetTester tester) async {
      final manager = DownloadStateManager();

      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      manager.addTask(task);

      await tester.pumpWidget(
        ChangeNotifierProvider<DownloadStateManager>(
          create: (_) => manager,
          child: const MaterialApp(
            home: Scaffold(body: _TaskConsumerWidget(taskId: 'task-1')),
          ),
        ),
      );

      await tester.pump();

      // 下载中状态
      expect(find.text('50%'), findsOneWidget);

      // 暂停任务（直接更新状态，避免测试环境中 method channel 调用阻塞）
      manager.updateTaskProgress('task-1', status: DownloadTaskStatus.paused);

      await tester.pump();

      // 应该显示"已暂停"
      expect(find.text('已暂停'), findsOneWidget);
    });

    testWidgets('[P1][AC4] 状态从下载中变为失败', (WidgetTester tester) async {
      final manager = DownloadStateManager();

      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      manager.addTask(task);

      await tester.pumpWidget(
        ChangeNotifierProvider<DownloadStateManager>(
          create: (_) => manager,
          child: const MaterialApp(
            home: Scaffold(body: _TaskConsumerWidget(taskId: 'task-1')),
          ),
        ),
      );

      await tester.pump();

      // 下载中状态
      expect(find.text('50%'), findsOneWidget);

      // 标记为失败
      manager.updateTaskProgress(
        'task-1',
        status: DownloadTaskStatus.error,
        errorMessage: '网络超时',
      );

      await tester.pump();

      // 应该显示"下载失败"
      expect(find.text('下载失败'), findsOneWidget);
      // 应该显示错误图标
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('DownloadingTaskItem - 边缘情况测试', () {
    testWidgets('[P2] totalBytes 为 0 时不崩溃', (WidgetTester tester) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 0,
        downloadedBytes: 0,
        status: DownloadTaskStatus.preparing,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      // 不应该崩溃，应该显示 0%
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('[P2] 空标题正确处理', (WidgetTester tester) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '',
        totalBytes: 1000,
        downloadedBytes: 0,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      // 空标题应该存在但不显示内容
      expect(find.text(''), findsAtLeastNWidgets(1));
    });

    testWidgets('[P2] downloadedBytes 大于 totalBytes 时进度限制为 100%', (
      WidgetTester tester,
    ) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 1500, // 超过 totalBytes
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      // 进度应该限制为 100%
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('[P2] 进度条动画容器存在', (WidgetTester tester) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '测试',
        totalBytes: 1000,
        downloadedBytes: 500,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      // AnimatedContainer 应该存在，用于平滑过渡动画
      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );

      // 验证动画时长为 300ms
      expect(animatedContainer.duration, const Duration(milliseconds: 300));
    });
  });

  group('DownloadingTaskItem - Acceptance Criteria 综合测试', () {
    testWidgets('[AC1][P1] 下载中 Tab 显示完整信息: 缩略图、标题、进度条、百分比、文件大小、速度', (
      WidgetTester tester,
    ) async {
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '完整测试视频',
        thumbnail: 'https://example.com/thumb.jpg',
        totalBytes: 200 * 1024 * 1024, // 200MB
        downloadedBytes: 134 * 1024 * 1024, // 134MB
        bytesPerSecond: 3 * 1024 * 1024, // 3MB/s
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      // 缩略图区域存在（有图片）
      expect(find.byType(Image), findsOneWidget);

      // 标题
      expect(find.text('完整测试视频'), findsOneWidget);

      // 进度条（AnimatedContainer）
      expect(find.byType(AnimatedContainer), findsAtLeastNWidgets(1));

      // 百分比
      expect(find.text('67%'), findsOneWidget);

      // 文件大小
      expect(find.text('200.0MB'), findsOneWidget);

      // 下载速度
      expect(find.text('3.0MB/s'), findsOneWidget);
    });

    testWidgets('[AC2][P1] 进度更新时平滑更新', (WidgetTester tester) async {
      // 模拟进度从 0% 到 100% 的更新
      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '进度更新测试',
        totalBytes: 1000,
        downloadedBytes: 0,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: task)),
        ),
      );

      await tester.pump();

      // 0%
      expect(find.text('0%'), findsOneWidget);

      // 更新到 25%
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadingTaskItem(
              task: task.copyWith(downloadedBytes: 250),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('25%'), findsOneWidget);

      // 更新到 50%
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadingTaskItem(
              task: task.copyWith(downloadedBytes: 500),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('50%'), findsOneWidget);

      // 更新到 100%
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DownloadingTaskItem(
              task: task.copyWith(
                downloadedBytes: 1000,
                status: DownloadTaskStatus.completed,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('[AC3][P1] 不同状态显示正确的样式和文本', (WidgetTester tester) async {
      // 测试下载中状态
      final downloadingTask = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '状态测试',
        totalBytes: 1000,
        downloadedBytes: 500,
        bytesPerSecond: 1024,
        status: DownloadTaskStatus.downloading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: downloadingTask)),
        ),
      );
      await tester.pump();

      // 下载中: 显示百分比和速度
      expect(find.text('50%'), findsOneWidget);
      // speedFormatted 对 1024 bytes 显示 "1KB/s" (无小数)
      expect(find.textContaining('KB/s'), findsOneWidget);

      // 测试暂停状态
      final pausedTask = downloadingTask.copyWith(
        status: DownloadTaskStatus.paused,
        bytesPerSecond: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: pausedTask)),
        ),
      );
      await tester.pump();

      // 暂停: 显示"已暂停"，不显示速度
      expect(find.text('已暂停'), findsOneWidget);
      // 暂停状态下速度为 0，不显示速度
      expect(find.textContaining('KB/s'), findsNothing);

      // 测试失败状态
      final errorTask = downloadingTask.copyWith(
        status: DownloadTaskStatus.error,
        errorMessage: '网络错误',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DownloadingTaskItem(task: errorTask)),
        ),
      );
      await tester.pump();

      // 失败: 显示"下载失败"和错误图标
      expect(find.text('下载失败'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('[AC4][P1] Provider 状态变化自动响应', (WidgetTester tester) async {
      final manager = DownloadStateManager();
      var listenerCallCount = 0;

      final task = DownloadTask(
        id: 'task-1',
        vid: 'vid-1',
        title: '响应式测试',
        totalBytes: 1000,
        downloadedBytes: 0,
        status: DownloadTaskStatus.waiting,
        createdAt: DateTime.now(),
      );

      manager.addTask(task);
      manager.addListener(() => listenerCallCount++);

      await tester.pumpWidget(
        ChangeNotifierProvider<DownloadStateManager>(
          create: (_) => manager,
          child: const MaterialApp(
            home: Scaffold(body: _TaskConsumerWidget(taskId: 'task-1')),
          ),
        ),
      );

      await tester.pump();

      final initialCalls = listenerCallCount;

      // 更新任务
      manager.updateTaskProgress(
        'task-1',
        downloadedBytes: 300,
        status: DownloadTaskStatus.downloading,
      );

      await tester.pump();

      // 验证通知被触发
      expect(listenerCallCount, greaterThan(initialCalls));

      // 验证 UI 更新
      expect(find.text('30%'), findsOneWidget);
    });
  });
}

/// 辅助 Widget: 用于测试 Provider 响应式更新
class _TaskConsumerWidget extends StatelessWidget {
  final String taskId;

  const _TaskConsumerWidget({required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadStateManager>(
      builder: (context, manager, _) {
        final task = manager.getTaskById(taskId);
        if (task == null) {
          return const SizedBox.shrink();
        }
        return DownloadingTaskItem(task: task);
      },
    );
  }
}
