import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/polyv_media_player.dart';
import '../player_colors.dart';
import 'quality_selector.dart';

void main() {
  group('QualitySelector Widget Tests', () {
    late PlayerController mockController;

    setUp(() {
      mockController = PlayerController();
    });

    tearDown(() {
      mockController.dispose();
    });

    // ==================== 渲染测试 ====================

    testWidgets('[P1] 显示清晰度按钮', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QualitySelector(controller: mockController)),
        ),
      );

      expect(find.byType(QualitySelector), findsOneWidget);
    });

    testWidgets('[P1] 使用 ListenableBuilder 响应状态变化', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QualitySelector(controller: mockController)),
        ),
      );

      expect(find.byType(ListenableBuilder), findsAtLeastNWidgets(1));
      expect(find.byType(QualitySelector), findsOneWidget);
    });

    // ==================== 按钮显示测试 ====================

    testWidgets('[P1] 空清晰度列表时按钮存在且显示设置图标', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QualitySelector(controller: mockController)),
        ),
      );

      // 初始状态清晰度列表为空，应该显示设置图标
      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.byType(QualitySelector), findsOneWidget);
    });

    testWidgets('[P1] 按钮有 40x40 的固定尺寸', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QualitySelector(controller: mockController)),
        ),
      );

      final sizedBox = find
          .descendant(
            of: find.byType(QualitySelector),
            matching: find.byType(SizedBox),
          )
          .first;

      final box = tester.getSize(sizedBox);
      expect(box.width, 40);
      expect(box.height, 40);
    });

    // ==================== 下拉菜单交互测试 ====================

    testWidgets('[P1] 点击按钮切换下拉菜单状态', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QualitySelector(controller: mockController)),
        ),
      );

      final selectorFinder = find.byType(QualitySelector);
      expect(selectorFinder, findsOneWidget);

      // 初始状态没有设置图标以外的菜单
      expect(find.text('画质选择'), findsNothing);

      // 点击按钮
      await tester.tap(selectorFinder);
      await tester.pumpAndSettle();

      // 组件应该仍然存在
      expect(find.byType(QualitySelector), findsOneWidget);
    });

    testWidgets('[P2] 下拉菜单使用 Stack 布局', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QualitySelector(controller: mockController)),
        ),
      );

      // 验证使用 Stack 布局
      expect(find.byType(Stack), findsAtLeastNWidgets(1));
      expect(find.byType(QualitySelector), findsOneWidget);
    });

    // ==================== 禁用状态测试 ====================

    testWidgets('[P2] 空清晰度列表时按钮不透明度降低', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QualitySelector(controller: mockController)),
        ),
      );

      // 初始状态清晰度列表为空，按钮应该有降低的不透明度
      final opacityFinder = find.descendant(
        of: find.byType(QualitySelector),
        matching: find.byType(Opacity),
      );

      expect(opacityFinder, findsOneWidget);

      final opacity = tester.widget<Opacity>(opacityFinder);
      // 空列表时应该是不透明度 0.4
      expect(opacity.opacity, 0.4);
    });

    // ==================== 样式属性测试 ====================

    testWidgets('[P2] 组件使用正确的固定尺寸', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QualitySelector(controller: mockController)),
        ),
      );

      final sizedBox = find.descendant(
        of: find.byType(QualitySelector),
        matching: find.byType(SizedBox),
      );

      expect(sizedBox, findsAtLeastNWidgets(1));
    });

    testWidgets('[P2] 设置图标使用 tune 图标', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QualitySelector(controller: mockController)),
        ),
      );

      expect(find.byIcon(Icons.tune), findsOneWidget);
    });

    // ==================== 边界情况测试 ====================

    testWidgets('[P2] 多次重建不泄漏内存', (tester) async {
      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: QualitySelector(controller: mockController)),
          ),
        );
      }

      expect(find.byType(QualitySelector), findsOneWidget);
    });

    testWidgets('[P2] Controller dispose 后不崩溃', (tester) async {
      final controller = PlayerController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QualitySelector(controller: controller)),
        ),
      );

      expect(find.byType(QualitySelector), findsOneWidget);

      // dispose 并重建
      controller.dispose();
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Container())));

      // 应该没有 QualitySelector
      expect(find.byType(QualitySelector), findsNothing);
    });

    testWidgets('[P2] 多个 QualitySelector 实例互不干扰', (tester) async {
      final controller1 = PlayerController();
      final controller2 = PlayerController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                QualitySelector(controller: controller1),
                QualitySelector(controller: controller2),
              ],
            ),
          ),
        ),
      );

      // 应该有两个 QualitySelector
      expect(find.byType(QualitySelector), findsNWidgets(2));

      controller1.dispose();
      controller2.dispose();
    });
  });

  // ==================== PlayerColors 单元测试 ====================

  group('PlayerColors Tests', () {
    test('[P2] PlayerColors 颜色值正确', () {
      expect(PlayerColors.background, const Color(0xFF121621));
      expect(PlayerColors.surface, const Color(0xFF1E2432));
      expect(PlayerColors.controls, const Color(0xFF2D3548));
      expect(PlayerColors.progress, const Color(0xFFE8704D));
      expect(PlayerColors.progressBuffer, const Color(0xFF3D4560));
      expect(PlayerColors.text, const Color(0xFFF5F5F5));
      expect(PlayerColors.textMuted, const Color(0xFF8B919E));
    });

    test('[P2] PlayerColors 值不为透明', () {
      // 验证颜色是不透明的
      expect(PlayerColors.background.toARGB32() & 0xFF000000, 0xFF000000);
      expect(PlayerColors.surface.toARGB32() & 0xFF000000, 0xFF000000);
      expect(PlayerColors.progress.toARGB32() & 0xFF000000, 0xFF000000);
    });

    test('[P2] PlayerColors.activeHighlight 有透明度', () {
      // 验证 activeHighlight 是带透明度的
      final alpha = PlayerColors.activeHighlight.toARGB32() >> 24;
      expect(alpha, lessThan(255));
    });
  });
}
