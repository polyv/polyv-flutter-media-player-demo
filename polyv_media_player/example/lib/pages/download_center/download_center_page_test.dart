import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/polyv_media_player.dart';
import 'package:provider/provider.dart';
import 'download_center_page.dart';

/// DownloadCenterPage Widget 测试
///
/// Story 9.1: 下载中心页面框架
///
/// 测试下载中心页面的 UI 组件、Tab 切换和状态显示
///
/// 注意: 由于 DownloadCenterPage 在 build 方法中使用了 `Consumer<DownloadStateManager>`，
/// Widget 测试主要关注 UI 结构和交互，
/// 状态管理的详细测试在 download_state_manager_test.dart 中
void main() {
  // 初始化测试绑定
  TestWidgetsFlutterBinding.ensureInitialized();

  // 设置 mock MethodChannel 以避免 MissingPluginException
  final channel = MethodChannel(PlayerApi.methodChannelName);

  // Story 9.8: Mock 下载任务列表数据
  List<Map<String, dynamic>> mockDownloadList = [];

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        // Story 9.8: Mock getDownloadList 方法
        if (methodCall.method == 'getDownloadList') {
          return mockDownloadList;
        }
        // Mock 所有其他平台调用返回成功
        return null;
      });

  // 创建一个测试用的包装器函数，提供 DownloadStateManager
  // 通过设置 enableEventListener: false 跳过 EventChannel 订阅（避免测试中的 MissingPluginException）
  Widget createTestWidget({Widget? child}) {
    return ChangeNotifierProvider(
      create: (_) => DownloadStateManager(
        channel: channel,
        enableEventListener: false, // 测试中禁用事件监听
      ),
      child: MaterialApp(home: child ?? const DownloadCenterPage()),
    );
  }

  group('DownloadCenterPage - 页面结构测试', () {
    testWidgets('[P1] 页面包含基本元素', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      // 验证页面标题存在
      expect(find.text('下载中心'), findsOneWidget);

      // 验证 Tab 标题存在（初始状态数量为0）
      expect(find.text('下载中 (0)'), findsOneWidget);
      expect(find.text('已完成 (0)'), findsOneWidget);

      // 验证 TabBar 存在
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('[P1] TabController 正确初始化', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      // TabBarView 应该存在
      expect(find.byType(TabBarView), findsOneWidget);

      // 验证两个 Tab
      expect(find.byType(Tab), findsNWidgets(2));
    });

    testWidgets('[P1] 返回按钮存在', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      // 验证返回文本存在
      expect(find.text('返回'), findsOneWidget);

      // 验证更多按钮存在（使用 IconButton 类型）
      expect(find.byType(IconButton), findsAtLeastNWidgets(1));
    });
  });

  group('DownloadCenterPage - Tab 显示测试', () {
    testWidgets('[P1] 已完成 Tab 显示空状态（默认第一个）', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      // Tab 顺序改为：已完成、下载中
      // 默认显示第一个 Tab（已完成）的空状态提示
      expect(find.text('暂无已完成视频'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    });

    testWidgets('[P1] 切换到下载中 Tab 显示空状态', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      // 点击第二个 Tab（下载中）
      await tester.tap(find.text('下载中 (0)'));
      await tester.pumpAndSettle();

      // 验证空状态提示
      expect(find.text('暂无下载任务'), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    });

    testWidgets('[P1] Tab 切换不卡顿', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      // 快速切换 Tab 多次
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('下载中 (0)'));
        await tester.pump(Duration(milliseconds: 50));

        await tester.tap(find.text('已完成 (0)'));
        await tester.pump(Duration(milliseconds: 50));
      }

      // 应该仍然正常工作
      expect(find.byType(TabBar), findsOneWidget);
    });
  });

  group('DownloadCenterPage - UI 组件细节测试', () {
    testWidgets('[P1] TabBar 样式正确', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      // 验证 TabBar 存在
      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar, isNotNull);
      expect(tabBar.indicatorSize, TabBarIndicatorSize.label);
    });

    testWidgets('[P1] TabBarView 包含两个子页面', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      final tabBarView = tester.widget<TabBarView>(find.byType(TabBarView));
      expect(tabBarView, isNotNull);
      expect(tabBarView.children.length, 2);
    });

    testWidgets('[P1] 背景颜色设置正确', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF0F172A)); // slate900
    });
  });

  group('DownloadCenterPage - 空状态 UI 测试', () {
    testWidgets('[P1] 已完成空状态显示图标和文字（默认第一个）', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      // Tab 顺序改为：已完成、下载中
      // 默认显示第一个 Tab（已完成）的空状态
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
      expect(find.text('暂无已完成视频'), findsOneWidget);
    });

    testWidgets('[P1] 下载中空状态显示图标和文字', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      // 切换到下载中 Tab
      await tester.tap(find.text('下载中 (0)'));
      await tester.pumpAndSettle();

      // 查找 Center widget 包含图标和文字
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
      expect(find.text('暂无下载任务'), findsOneWidget);

      // 验证图标颜色
      final icon = tester.widget<Icon>(find.byIcon(Icons.download_rounded));
      expect(
        icon.color?.withAlpha(255),
        Colors.white.withAlpha(127).withAlpha(255),
      );
    });
  });

  group('DownloadCenterPage - 交互测试', () {
    testWidgets('[P1] 点击返回按钮弹出 Navigator', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => DownloadStateManager(),
          child: MaterialApp(
            home: const DownloadCenterPage(),
            onGenerateRoute: (settings) {
              if (settings.name == '/') {
                return MaterialPageRoute(
                  builder: (context) => const DownloadCenterPage(),
                );
              }
              return null;
            },
          ),
        ),
      );

      await tester.pump();

      // 点击返回按钮
      await tester.tap(find.text('返回'));
      await tester.pumpAndSettle();

      // Navigator.pop 应该成功执行（没有抛出异常即表示成功）
    });

    testWidgets('[P1] 更多按钮存在', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      // 验证有 more_horiz 图标存在
      expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);

      // 验证返回按钮图标也存在
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
    });
  });

  group('DownloadCenterPage - Acceptance Criteria 验证', () {
    testWidgets('[AC1][P1] 显示两个 Tab: 已完成、下载中', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      expect(find.text('已完成 (0)'), findsOneWidget);
      expect(find.text('下载中 (0)'), findsOneWidget);
    });

    testWidgets('[AC1][P1] 每个 Tab 显示当前任务数量', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      // 初始状态数量为 0
      expect(find.text('已完成 (0)'), findsOneWidget);
      expect(find.text('下载中 (0)'), findsOneWidget);
    });

    testWidgets('[AC2][P1] Tab 切换流畅无卡顿', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      // 切换到下载中
      await tester.tap(find.text('下载中 (0)'));
      await tester.pump();

      // 切换回已完成
      await tester.tap(find.text('已完成 (0)'));
      await tester.pump();

      // 验证页面仍然正常
      expect(find.byType(DownloadCenterPage), findsOneWidget);
    });

    testWidgets('[AC3][P1] 已完成 Tab 显示空状态提示（默认第一个）', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      // Tab 顺序改为：已完成、下载中
      // 默认显示第一个 Tab（已完成）的空状态
      expect(find.text('暂无已完成视频'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
    });

    testWidgets('[AC4][P1] 下载中 Tab 显示空状态提示', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      // 切换到下载中 Tab
      await tester.tap(find.text('下载中 (0)'));
      await tester.pumpAndSettle();

      expect(find.text('暂无下载任务'), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    });
  });

  group('DownloadCenterPage - 边缘情况测试', () {
    testWidgets('[P1] 页面多次重建不崩溃', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      // 多次重建
      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
      }

      // 页面应该仍然正常
      expect(find.byType(DownloadCenterPage), findsOneWidget);
    });

    testWidgets('[P2] 标题文字样式正确', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.pump();

      final title = tester.widget<Text>(find.text('下载中心'));
      expect(title.style?.fontSize, 16);
      expect(title.style?.fontWeight, FontWeight.w600);
      expect(title.style?.color, Colors.white);
    });
  });

  group('DownloadCenterPage - Story 9.4 重试失败下载集成测试', () {
    testWidgets('[Story 9.4][AC1][P1] 失败任务显示错误图标和提示', (
      WidgetTester tester,
    ) async {
      final manager = DownloadStateManager(enableEventListener: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<DownloadStateManager>.value(
          value: manager,
          child: const MaterialApp(home: DownloadCenterPage()),
        ),
      );

      await tester.pump();

      // DownloadCenterPage initState 会调用 syncFromNative() 清空任务列表
      // 所以需要在 pumpWidget 之后添加任务
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

      await tester.pumpAndSettle();

      // Tab 顺序改为：已完成、下载中
      // 失败任务显示在下载中 Tab，需要切换过去
      await tester.tap(find.text('下载中 (1)'));
      await tester.pumpAndSettle();

      // 验证任务显示在下载中 Tab
      expect(find.text('失败的视频'), findsOneWidget);

      // 验证错误状态提示
      expect(find.text('下载失败'), findsOneWidget);
      expect(find.text('1000B'), findsOneWidget); // totalSizeFormatted
    });

    testWidgets('[Story 9.4][AC1][P1] 失败任务显示重试按钮', (WidgetTester tester) async {
      final manager = DownloadStateManager(enableEventListener: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<DownloadStateManager>.value(
          value: manager,
          child: const MaterialApp(home: DownloadCenterPage()),
        ),
      );

      await tester.pump();

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

      await tester.pumpAndSettle();

      // Tab 顺序改为：已完成、下载中
      // 失败任务显示在下载中 Tab，需要切换过去
      await tester.tap(find.text('下载中 (1)'));
      await tester.pumpAndSettle();

      // 查找重试按钮（播放图标）
      expect(find.byIcon(Icons.play_arrow_rounded), findsAtLeastNWidgets(1));

      // 验证重试按钮是主色调
      final retryButtons = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.play_arrow_rounded,
      );

      expect(retryButtons, findsAtLeastNWidgets(1));
    });

    testWidgets('[Story 9.4][AC2][P1] 点击重试按钮后状态更新为下载中', (
      WidgetTester tester,
    ) async {
      final manager = DownloadStateManager(enableEventListener: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<DownloadStateManager>.value(
          value: manager,
          child: const MaterialApp(home: DownloadCenterPage()),
        ),
      );

      await tester.pump();

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

      await tester.pumpAndSettle();

      // Tab 顺序改为：已完成、下载中
      // 失败任务显示在下载中 Tab，需要切换过去
      await tester.tap(find.text('下载中 (1)'));
      await tester.pumpAndSettle();

      // 初始状态：显示"下载失败"
      expect(find.text('下载失败'), findsOneWidget);

      // 点击重试按钮 - 使用更精确的 predicate
      final retryButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.play_arrow_rounded &&
            widget.color == const Color(0xFFE8704D), // primary color for retry
      );
      await tester.tap(retryButton);

      // 使用 runAsync 确保异步操作完成
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      // 状态应更新为下载中
      expect(
        manager.getTaskById('task-1')?.status,
        DownloadTaskStatus.downloading,
      );
      // 错误信息应被清除
      expect(manager.getTaskById('task-1')?.errorMessage, isNull);
    });

    testWidgets('[Story 9.4][AC2][P1] 重试后错误提示消失', (WidgetTester tester) async {
      final manager = DownloadStateManager(enableEventListener: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<DownloadStateManager>.value(
          value: manager,
          child: const MaterialApp(home: DownloadCenterPage()),
        ),
      );

      await tester.pump();

      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '视频',
          totalBytes: 1000,
          downloadedBytes: 500,
          status: DownloadTaskStatus.error,
          errorMessage: '下载失败',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpAndSettle();

      // Tab 顺序改为：已完成、下载中
      // 失败任务显示在下载中 Tab，需要切换过去
      await tester.tap(find.text('下载中 (1)'));
      await tester.pumpAndSettle();

      // 初始状态：显示"下载失败"
      expect(find.text('下载失败'), findsOneWidget);

      // 点击重试
      final retryButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.play_arrow_rounded &&
            widget.color == const Color(0xFFE8704D), // primary color for retry
      );
      await tester.tap(retryButton);

      // 使用 runAsync 确保异步操作完成
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      // "下载失败"提示应消失（因为没有错误信息了）
      // 现在应该显示进度百分比或其他状态
      expect(find.text('下载失败'), findsNothing);
    });

    testWidgets('[Story 9.4][AC3][P1] UI 立即响应重试状态变化', (
      WidgetTester tester,
    ) async {
      final manager = DownloadStateManager(enableEventListener: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<DownloadStateManager>.value(
          value: manager,
          child: const MaterialApp(home: DownloadCenterPage()),
        ),
      );

      await tester.pump();

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

      await tester.pumpAndSettle();

      // Tab 顺序改为：已完成、下载中
      // 失败任务显示在下载中 Tab，需要切换过去
      await tester.tap(find.text('下载中 (1)'));
      await tester.pumpAndSettle();

      // 点击重试按钮
      final retryButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.play_arrow_rounded &&
            widget.color == const Color(0xFFE8704D), // primary color for retry
      );
      await tester.tap(retryButton);

      // 使用 runAsync 确保异步操作完成
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      // 重试后应显示暂停按钮（而非重试按钮）
      // 状态变为下载中，按钮变为暂停图标
      final pauseButtons = find.byIcon(Icons.pause_rounded);

      expect(pauseButtons, findsAtLeastNWidgets(1));
    });

    testWidgets('[Story 9.4][AC4][P1] 重试后再次失败显示新错误', (
      WidgetTester tester,
    ) async {
      final manager = DownloadStateManager(enableEventListener: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<DownloadStateManager>.value(
          value: manager,
          child: const MaterialApp(home: DownloadCenterPage()),
        ),
      );

      await tester.pump();

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

      await tester.pumpAndSettle();

      // Tab 顺序改为：已完成、下载中
      // 失败任务显示在下载中 Tab，需要切换过去
      await tester.tap(find.text('下载中 (1)'));
      await tester.pumpAndSettle();

      // 第一次重试
      final retryButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.play_arrow_rounded &&
            widget.color == const Color(0xFFE8704D), // primary color for retry
      );
      await tester.tap(retryButton);

      // 使用 runAsync 确保异步操作完成
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

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
      await tester.pumpAndSettle();

      // 验证 UI 更新 - UI 显示通用的"下载失败"消息，而不是具体的错误信息
      expect(find.text('下载失败'), findsOneWidget);

      // 重试按钮应再次出现
      expect(find.byIcon(Icons.play_arrow_rounded), findsAtLeastNWidgets(1));
    });

    testWidgets('[Story 9.4][AC4][P2] 多次重试场景 UI 正确更新', (
      WidgetTester tester,
    ) async {
      final manager = DownloadStateManager(enableEventListener: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<DownloadStateManager>.value(
          value: manager,
          child: const MaterialApp(home: DownloadCenterPage()),
        ),
      );

      await tester.pump();

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

      await tester.pumpAndSettle();

      // Tab 顺序改为：已完成、下载中
      // 失败任务显示在下载中 Tab，需要切换过去
      await tester.tap(find.text('下载中 (1)'));
      await tester.pumpAndSettle();

      // 第一次重试 - 使用完整的 widget predicate 查找重试按钮
      final retryButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.play_arrow_rounded &&
            widget.color == const Color(0xFFE8704D), // primary color for retry
      );
      expect(retryButton, findsOneWidget);
      await tester.tap(retryButton);

      // 使用 runAsync 确保异步操作完成
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      expect(
        manager.getTaskById('task-1')?.status,
        DownloadTaskStatus.downloading,
      );

      // 模拟失败
      manager.updateTaskProgress(
        'task-1',
        status: DownloadTaskStatus.error,
        errorMessage: '第2次失败',
      );
      await tester.pumpAndSettle();

      // 第二次重试 - 重新查找重试按钮
      final retryButton2 = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.icon is Icon &&
            (widget.icon as Icon).icon == Icons.play_arrow_rounded &&
            widget.color == const Color(0xFFE8704D),
      );
      await tester.tap(retryButton2);

      // 使用 runAsync 确保异步操作完成
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      expect(
        manager.getTaskById('task-1')?.status,
        DownloadTaskStatus.downloading,
      );

      // 最终状态验证
      expect(manager.getTaskById('task-1')?.errorMessage, isNull);
      // 进度保持不变
      expect(manager.getTaskById('task-1')?.downloadedBytes, 300);
    });

    testWidgets('[Story 9.4][P1] 重试保持下载进度（断点续传）', (WidgetTester tester) async {
      final manager = DownloadStateManager(enableEventListener: false);

      await tester.pumpWidget(
        ChangeNotifierProvider<DownloadStateManager>.value(
          value: manager,
          child: const MaterialApp(home: DownloadCenterPage()),
        ),
      );

      await tester.pump();

      manager.addTask(
        DownloadTask(
          id: 'task-1',
          vid: 'vid-1',
          title: '大视频',
          totalBytes: 10000,
          downloadedBytes: 5000, // 50% 已下载
          status: DownloadTaskStatus.error,
          errorMessage: '网络中断',
          createdAt: DateTime.now(),
        ),
      );

      await tester.pumpAndSettle();

      // Tab 顺序改为：已完成、下载中
      // 失败任务显示在下载中 Tab，需要切换过去
      await tester.tap(find.text('下载中 (1)'));
      await tester.pumpAndSettle();

      // 重试前检查进度
      expect(manager.getTaskById('task-1')?.progress, 0.5);

      // 点击重试 - 使用更精确的 predicate 来定位重试按钮
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              widget.icon is Icon &&
              (widget.icon as Icon).icon == Icons.play_arrow_rounded &&
              widget.color == const Color(0xFFE8704D), // primary color for retry button
        ),
      );
      await tester.pump();

      // 验证进度被保留（断点续传）
      expect(manager.getTaskById('task-1')?.downloadedBytes, 5000);
      expect(manager.getTaskById('task-1')?.progress, 0.5);
    });
  });
}
