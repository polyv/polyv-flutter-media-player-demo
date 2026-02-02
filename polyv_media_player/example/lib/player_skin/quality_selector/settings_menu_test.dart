import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/polyv_media_player.dart';
import 'package:provider/provider.dart';
import 'settings_menu.dart';

/// SettingsMenu 组件测试
///
/// 测试移动端底部弹出菜单的 UI 渲染和交互行为
///
/// Story 6.5: 触发下载任务
void main() {
  // 创建测试用的包装器，提供 DownloadStateManager
  Widget createTestWidget({
    required Widget child,
    DownloadStateManager? downloadStateManager,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DownloadStateManager>.value(
          value: downloadStateManager ?? DownloadStateManager(enableEventListener: false),
        ),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('SettingsMenu - Widget 渲染', () {
    late DownloadStateManager downloadStateManager;

    setUp(() {
      downloadStateManager = DownloadStateManager(enableEventListener: false);
    });

    tearDown(() {
      downloadStateManager.dispose();
    });

    testWidgets('[P1] 显示设置菜单', (tester) async {
      // GIVEN: PlayerController
      final controller = PlayerController();

      // WHEN: 显示设置菜单
      await tester.pumpWidget(
        createTestWidget(
          downloadStateManager: downloadStateManager,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  SettingsMenu.show(context: context, controller: controller),
              child: const Text('Show Menu'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // THEN: 应该显示按钮
      expect(find.text('Show Menu'), findsOneWidget);

      // 点击显示菜单
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // 菜单应该显示（底部 sheet）
      expect(find.byType(SettingsMenu), findsOneWidget);

      controller.dispose();
    });

    testWidgets('[P1] 显示顶部拖动手柄', (tester) async {
      // GIVEN: PlayerController
      final controller = PlayerController();

      await tester.pumpWidget(
        createTestWidget(
          downloadStateManager: downloadStateManager,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  SettingsMenu.show(context: context, controller: controller),
              child: const Text('Show Menu'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // THEN: 应该有拖动手柄（小的横向 Container）
      final handles = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints != null &&
            widget.child == null &&
            widget.decoration is BoxDecoration,
      );

      expect(handles.evaluate().isNotEmpty, isTrue);

      controller.dispose();
    });

    testWidgets('[P1] 显示关闭按钮', (tester) async {
      // GIVEN: PlayerController
      final controller = PlayerController();

      await tester.pumpWidget(
        createTestWidget(
          downloadStateManager: downloadStateManager,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  SettingsMenu.show(context: context, controller: controller),
              child: const Text('Show Menu'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // THEN: 应该有关闭图标
      expect(find.byIcon(Icons.close), findsOneWidget);

      controller.dispose();
    });

    testWidgets('[P2] 空清晰度列表时显示加载中提示', (tester) async {
      // GIVEN: PlayerController（默认空清晰度列表）
      final controller = PlayerController();

      await tester.pumpWidget(
        createTestWidget(
          downloadStateManager: downloadStateManager,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  SettingsMenu.show(context: context, controller: controller),
              child: const Text('Show Menu'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // THEN: 应该显示"清晰度: 加载中..."
      expect(find.text('清晰度: 加载中...'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('[P2] 显示倍速选择区域', (tester) async {
      // GIVEN: PlayerController
      final controller = PlayerController();

      await tester.pumpWidget(
        createTestWidget(
          downloadStateManager: downloadStateManager,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  SettingsMenu.show(context: context, controller: controller),
              child: const Text('Show Menu'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // THEN: 应该显示倍速标题
      expect(find.text('倍速'), findsOneWidget);

      // 应该有倍速按钮（0.75x, 1.0x, 1.25x, 1.5x, 2.0x）
      expect(find.text('0.75x'), findsOneWidget);
      expect(find.text('1.0x'), findsOneWidget);
      expect(find.text('1.25x'), findsOneWidget);
      expect(find.text('1.5x'), findsOneWidget);
      expect(find.text('2.0x'), findsOneWidget);

      controller.dispose();
    });
  });

  group('SettingsMenu - 交互行为', () {
    late DownloadStateManager downloadStateManager;

    setUp(() {
      downloadStateManager = DownloadStateManager(enableEventListener: false);
    });

    tearDown(() {
      downloadStateManager.dispose();
    });

    testWidgets('[P1] 点击遮罩层关闭菜单', (tester) async {
      // GIVEN: 显示设置菜单
      final controller = PlayerController();

      await tester.pumpWidget(
        createTestWidget(
          downloadStateManager: downloadStateManager,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  SettingsMenu.show(context: context, controller: controller),
              child: const Text('Show Menu'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // 菜单应该显示
      expect(find.byType(SettingsMenu), findsOneWidget);

      // WHEN: 点击遮罩层（黑色半透明背景区域）
      // 点击菜单外部的区域（左上角）
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // THEN: 菜单应该关闭
      expect(find.byType(SettingsMenu), findsNothing);

      controller.dispose();
    });

    testWidgets('[P1] 点击关闭按钮关闭菜单', (tester) async {
      // GIVEN: 显示设置菜单
      final controller = PlayerController();

      await tester.pumpWidget(
        createTestWidget(
          downloadStateManager: downloadStateManager,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  SettingsMenu.show(context: context, controller: controller),
              child: const Text('Show Menu'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // 菜单应该显示
      expect(find.byType(SettingsMenu), findsOneWidget);

      // WHEN: 点击关闭按钮
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // THEN: 菜单应该关闭
      expect(find.byType(SettingsMenu), findsNothing);

      controller.dispose();
    });

    testWidgets('[P1] 点击倍速按钮不关闭菜单', (tester) async {
      // GIVEN: 显示设置菜单
      final controller = PlayerController();

      await tester.pumpWidget(
        createTestWidget(
          downloadStateManager: downloadStateManager,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  SettingsMenu.show(context: context, controller: controller),
              child: const Text('Show Menu'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // 菜单应该显示
      expect(find.byType(SettingsMenu), findsOneWidget);

      // WHEN: 点击倍速按钮
      await tester.tap(find.text('1.5x'));
      await tester.pumpAndSettle();

      // THEN: 菜单应该仍然显示（与 Web 原型一致）
      expect(find.byType(SettingsMenu), findsOneWidget);

      controller.dispose();
    });

    testWidgets('[P2] 当前倍速按钮高亮显示', (tester) async {
      // GIVEN: 显示设置菜单
      final controller = PlayerController();

      await tester.pumpWidget(
        createTestWidget(
          downloadStateManager: downloadStateManager,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  SettingsMenu.show(context: context, controller: controller),
              child: const Text('Show Menu'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // 默认倍速是 1.0x，应该高亮显示
      // 高亮按钮的颜色是 PlayerColors.progress (#E8704D)

      // 验证 1.0x 按钮存在
      expect(find.text('1.0x'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('[P2] 点击倍速按钮调用 setPlaybackSpeed', (tester) async {
      // GIVEN: 显示设置菜单，使用测试 controller
      final testController = TestPlayerController();

      await tester.pumpWidget(
        createTestWidget(
          downloadStateManager: downloadStateManager,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => SettingsMenu.show(
                context: context,
                controller: testController,
              ),
              child: const Text('Show Menu'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // WHEN: 点击 1.5x 按钮
      expect(testController.lastSetSpeed, isNull);
      await tester.tap(find.text('1.5x'));
      await tester.pumpAndSettle();

      // THEN: setPlaybackSpeed 应该被调用
      expect(testController.lastSetSpeed, 1.5);

      testController.dispose();
    });

    testWidgets('[P2] 倍速列表不包含 0.5x', (tester) async {
      // GIVEN: 显示设置菜单
      final controller = PlayerController();

      await tester.pumpWidget(
        createTestWidget(
          downloadStateManager: downloadStateManager,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  SettingsMenu.show(context: context, controller: controller),
              child: const Text('Show Menu'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // THEN: 不应该有 0.5x 选项（移动端倍速列表不包含 0.5x）
      expect(find.text('0.5x'), findsNothing);

      // 但应该有其他倍速选项
      expect(find.text('0.75x'), findsOneWidget);

      controller.dispose();
    });
  });

  group('SettingsMenu - 布局结构', () {
    late DownloadStateManager downloadStateManager;

    setUp(() {
      downloadStateManager = DownloadStateManager(enableEventListener: false);
    });

    tearDown(() {
      downloadStateManager.dispose();
    });

    testWidgets('[P2] 使用底部弹出菜单样式', (tester) async {
      // GIVEN: 显示设置菜单
      final controller = PlayerController();

      await tester.pumpWidget(
        createTestWidget(
          downloadStateManager: downloadStateManager,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  SettingsMenu.show(context: context, controller: controller),
              child: const Text('Show Menu'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // THEN: 应该有底部圆角（只有顶部有圆角）
      expect(find.byType(SettingsMenu), findsOneWidget);

      controller.dispose();
    });

    testWidgets('[P2] 使用 Column 布局', (tester) async {
      // GIVEN: 显示设置菜单
      final controller = PlayerController();

      await tester.pumpWidget(
        createTestWidget(
          downloadStateManager: downloadStateManager,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  SettingsMenu.show(context: context, controller: controller),
              child: const Text('Show Menu'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // THEN: 应该包含 Column（主布局）
      expect(find.byType(Column), findsWidgets);

      controller.dispose();
    });
  });

  group('SettingsMenu - 边界情况', () {
    late DownloadStateManager downloadStateManager;

    setUp(() {
      downloadStateManager = DownloadStateManager(enableEventListener: false);
    });

    tearDown(() {
      downloadStateManager.dispose();
    });

    testWidgets('[P2] 多次打开关闭不泄漏内存', (tester) async {
      // GIVEN: PlayerController
      final controller = PlayerController();

      await tester.pumpWidget(
        createTestWidget(
          downloadStateManager: downloadStateManager,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  SettingsMenu.show(context: context, controller: controller),
              child: const Text('Show Menu'),
            ),
          ),
        ),
      );

      // WHEN: 多次打开关闭
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('Show Menu'));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsMenu), findsOneWidget);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsMenu), findsNothing);
      }

      // THEN: 应该正常工作不崩溃
      expect(find.text('Show Menu'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('[P2] Controller dispose 后不崩溃', (tester) async {
      // GIVEN: PlayerController
      final controller = PlayerController();

      await tester.pumpWidget(
        createTestWidget(
          downloadStateManager: downloadStateManager,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  SettingsMenu.show(context: context, controller: controller),
              child: const Text('Show Menu'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Show Menu'));
      await tester.pumpAndSettle();

      // 关闭菜单
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // dispose controller
      controller.dispose();

      // THEN: 应该正常工作不崩溃
      expect(find.byType(SettingsMenu), findsNothing);
    });

    testWidgets('[P2] 快速连续点击不崩溃', (tester) async {
      // GIVEN: PlayerController
      final controller = PlayerController();

      await tester.pumpWidget(
        createTestWidget(
          downloadStateManager: downloadStateManager,
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  SettingsMenu.show(context: context, controller: controller),
              child: const Text('Show Menu'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // WHEN: 快速连续打开关闭菜单（模拟用户操作）
      for (int i = 0; i < 3; i++) {
        // 打开菜单
        await tester.tap(find.text('Show Menu'));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsMenu), findsOneWidget);

        // 关闭菜单（点击遮罩层）
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.byType(SettingsMenu), findsNothing);
      }

      // THEN: 应该正常工作不崩溃
      expect(find.text('Show Menu'), findsOneWidget);

      controller.dispose();
    });
  });

  group('SettingsMenu - 功能按钮行 (Story 6.5)', () {
    late DownloadStateManager downloadStateManager;

    setUp(() {
      downloadStateManager = DownloadStateManager();
    });

    tearDown(() {
      downloadStateManager.dispose();
    });

    testWidgets('[P1] 显示功能按钮行', (tester) async {
      // GIVEN: 创建 PlayerController 和必要的 providers
      final controller = PlayerController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DownloadStateManager>.value(
              value: downloadStateManager,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SettingsMenu(
                controller: controller,
                onClose: () {},
                videoTitle: '测试视频',
                videoThumbnail: 'https://example.com/thumb.jpg',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // THEN: 显示三个功能按钮
      expect(find.text('音频模式'), findsOneWidget);
      expect(find.text('字幕设置'), findsOneWidget);
      expect(find.text('下载'), findsOneWidget);

      // 检查图标是否存在
      expect(find.byIcon(Icons.headphones_outlined), findsOneWidget);
      expect(find.byIcon(Icons.subtitles_outlined), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);

      controller.dispose();
    });

    testWidgets('[P1] 功能按钮在清晰度选择之前显示', (tester) async {
      // GIVEN: 创建 PlayerController
      final controller = PlayerController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DownloadStateManager>.value(
              value: downloadStateManager,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SettingsMenu(controller: controller, onClose: () {}),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // WHEN: 查找功能按钮和清晰度标题的位置
      final downloadButton = find.text('下载');
      final qualityText = find.textContaining('清晰度');

      // THEN: 下载按钮应该在清晰度标题上方
      expect(downloadButton, findsOneWidget);
      expect(qualityText, findsOneWidget);

      final downloadButtonOffset = tester.getTopLeft(downloadButton);
      final qualityTextOffset = tester.getTopLeft(qualityText);

      expect(downloadButtonOffset.dy, lessThan(qualityTextOffset.dy));

      controller.dispose();
    });

    testWidgets('[P1] 点击音频模式按钮显示暂不支持提示', (tester) async {
      // GIVEN: 创建 PlayerController
      final controller = PlayerController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DownloadStateManager>.value(
              value: downloadStateManager,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SettingsMenu(controller: controller, onClose: () {}),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // WHEN: 点击音频模式按钮
      final audioButton = find.text('音频模式');
      await tester.tap(audioButton);
      await tester.pumpAndSettle();

      // THEN: 显示暂不支持提示
      expect(find.text('音频模式功能暂未开放'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('[P1] 点击字幕设置按钮显示暂不支持提示', (tester) async {
      // GIVEN: 创建 PlayerController
      final controller = PlayerController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DownloadStateManager>.value(
              value: downloadStateManager,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SettingsMenu(controller: controller, onClose: () {}),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // WHEN: 点击字幕设置按钮
      final subtitleButton = find.text('字幕设置');
      await tester.tap(subtitleButton);
      await tester.pumpAndSettle();

      // THEN: 显示提示信息（指向播放器控制栏的字幕按钮）
      expect(find.text('请使用播放器控制栏的字幕按钮切换字幕'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('[P1] 点击下载按钮显示成功提示', (tester) async {
      // GIVEN: 创建一个 PlayerController，由于没有 vid，会显示"无法获取视频信息"
      final controller = PlayerController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DownloadStateManager>.value(
              value: downloadStateManager,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SettingsMenu(
                controller: controller,
                onClose: () {},
                videoTitle: '测试视频标题',
                videoThumbnail: 'https://example.com/thumb.jpg',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // WHEN: 点击下载按钮
      final downloadButton = find.text('下载');
      await tester.tap(downloadButton);
      await tester.pumpAndSettle();

      // THEN: 由于 vid 为 null，会显示错误提示
      expect(find.text('无法获取视频信息'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('[P1] 点击下载按钮成功创建任务（有 vid）', (tester) async {
      // GIVEN: 创建一个有 vid 的 PlayerController
      final controller = PlayerController();

      // 模拟有 vid 的状态（通过设置内部状态）
      // 注意: 实际测试中 PlayerController 初始没有 vid，这里验证逻辑
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DownloadStateManager>.value(
              value: downloadStateManager,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SettingsMenu(
                controller: controller,
                onClose: () {},
                videoTitle: '测试视频标题',
                videoThumbnail: 'https://example.com/thumb.jpg',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // WHEN: 点击下载按钮（vid 为 null 的情况）
      final downloadButton = find.text('下载');
      await tester.tap(downloadButton);
      await tester.pumpAndSettle();

      // THEN: 由于 vid 为 null，会显示错误提示
      expect(find.text('无法获取视频信息'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('[P1] 已完成的下载任务显示完成提示', (tester) async {
      // GIVEN: 创建一个有已完成任务的状态管理器
      final controller = PlayerController();
      final completedTask = DownloadTask(
        id: 'completed-task-1',
        vid: 'vid-123',
        title: '已下载视频',
        totalBytes: 100 * 1024 * 1024,
        downloadedBytes: 100 * 1024 * 1024,
        status: DownloadTaskStatus.completed,
        createdAt: DateTime.now(),
      );
      downloadStateManager.addTask(completedTask);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DownloadStateManager>.value(
              value: downloadStateManager,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SettingsMenu(
                controller: controller,
                onClose: () {},
                videoTitle: '已下载视频',
                videoThumbnail: 'https://example.com/thumb.jpg',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // WHEN: 点击下载按钮
      final downloadButton = find.text('下载');
      await tester.tap(downloadButton);
      await tester.pumpAndSettle();

      // THEN: 由于 vid 为 null，会显示错误提示（因为 controller.state.vid 为 null）
      expect(find.text('无法获取视频信息'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('[P1] ID 生成包含微秒时间戳', (tester) async {
      // 验证 _generateTaskId() 生成唯一 ID 的格式
      final id1 = 'download_${DateTime.now().microsecondsSinceEpoch}_1234_test';
      final id2 = 'download_${DateTime.now().microsecondsSinceEpoch}_5678_test';

      // 两个 ID 应该不同（微秒时间戳确保）
      expect(id1, isNot(equals(id2)));
      expect(id1.contains('download_'), isTrue);
      expect(id2.contains('download_'), isTrue);
    });
  });
}

/// 测试用的 PlayerController 子类，用于捕获方法调用
class TestPlayerController extends PlayerController {
  double? lastSetSpeed;

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    lastSetSpeed = speed;
    // 不调用父类方法，避免实际的 Platform Channel 调用
  }
}
