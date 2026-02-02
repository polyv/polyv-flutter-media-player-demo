import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/polyv_media_player.dart';
import 'speed_selector.dart';

void main() {
  // 设置方法通道 mock，避免 MissingPluginException
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.polyv.media_player/player');

  group('SpeedSelector Widget Tests', () {
    late PlayerController controller;

    setUp(() {
      // Mock 方法通道
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            if (methodCall.method == 'setPlaybackSpeed') {
              return null;
            }
            if (methodCall.method == 'stop') {
              return null;
            }
            return MissingPluginException();
          });

      controller = PlayerController();
    });

    tearDown(() {
      controller.dispose();
      // 清除 mock
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    testWidgets('should display gauge icon when speed is 1.0x', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => SpeedSelector(controller: controller),
            ),
          ),
        ),
      );

      // 检查是否显示仪表盘图标（speed 图标）
      expect(find.byIcon(Icons.speed), findsOneWidget);
    });

    testWidgets('should display speed text when speed is not 1.0x', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => SpeedSelector(controller: controller),
            ),
          ),
        ),
      );

      // 直接调用 setPlaybackSpeed
      await controller.setPlaybackSpeed(1.5);
      await tester.pump();

      // 按钮应该显示 1.5x 文本
      expect(find.text('1.5x'), findsOneWidget);
      expect(find.byIcon(Icons.speed), findsNothing);
    });

    testWidgets('should show dropdown menu when tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => SpeedSelector(controller: controller),
            ),
          ),
        ),
      );

      // 初始状态下菜单应该是关闭的
      expect(find.text('播放速度'), findsNothing);

      // 点击倍速按钮
      await tester.tap(find.byType(SpeedSelector));
      await tester.pumpAndSettle();

      // 菜单应该显示
      expect(find.text('播放速度'), findsOneWidget);

      // 所有倍速选项应该显示
      expect(find.text('正常'), findsOneWidget);
      expect(find.text('0.5x'), findsOneWidget);
      expect(find.text('0.75x'), findsOneWidget);
    });

    testWidgets('should close menu when tapping overlay', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => SpeedSelector(controller: controller),
            ),
          ),
        ),
      );

      // 点击倍速按钮打开菜单
      await tester.tap(find.byType(SpeedSelector));
      await tester.pumpAndSettle();
      expect(find.text('播放速度'), findsOneWidget);

      // 点击遮罩层（菜单外部）
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // 菜单应该关闭
      expect(find.text('播放速度'), findsNothing);
    });

    testWidgets(
      'should call setPlaybackSpeed and update state when speed changes',
      (tester) async {
        final testController = TestPlayerController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: ListenableBuilder(
                  listenable: testController,
                  builder: (context, _) =>
                      SpeedSelector(controller: testController),
                ),
              ),
            ),
          ),
        );

        // 初始状态：lastSetSpeed 应该是 null
        expect(testController.lastSetSpeed, isNull);

        // 模拟用户选择 1.5x 倍速
        await testController.setPlaybackSpeed(1.5);
        await tester.pump();

        // setPlaybackSpeed 应该被调用
        expect(testController.lastSetSpeed, 1.5);

        // UI 应该反映新的倍速
        expect(find.text('1.5x'), findsOneWidget);

        testController.dispose();
      },
    );

    testWidgets('should highlight current speed in dropdown menu', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => SpeedSelector(controller: controller),
            ),
          ),
        ),
      );

      // 打开菜单
      await tester.tap(find.byType(SpeedSelector));
      await tester.pumpAndSettle();

      // 默认倍速是 1.0x，对应的文本是"正常"
      // 应该有一个勾选图标（当选项激活时）
      expect(find.byIcon(Icons.check), findsOneWidget);
      // 不要在这里 dispose controller，它会被 tearDown() 处理
    });

    testWidgets(
      'should show active highlight on button when speed is not 1.0x',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => SpeedSelector(controller: controller),
              ),
            ),
          ),
        );

        // 直接调用 setPlaybackSpeed 来改变状态为 1.5x
        await controller.setPlaybackSpeed(1.5);
        await tester.pump();

        // 按钮应该显示 "1.5x" 文本（表示激活状态）
        expect(find.text('1.5x'), findsOneWidget);
        expect(find.byIcon(Icons.speed), findsNothing);

        // 验证状态确实被更新
        expect(controller.state.playbackSpeed, equals(1.5));
      },
    );
  });
}

/// 测试用的 PlayerController 子类，用于捕获方法调用
class TestPlayerController extends PlayerController {
  double? lastSetSpeed;

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    lastSetSpeed = speed;
    // 调用父类方法，setPlaybackSpeed 会立即更新状态（乐观更新）
    super.setPlaybackSpeed(speed);
  }
}
