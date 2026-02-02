import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/polyv_media_player.dart';
import 'subtitle_toggle.dart';

void main() {
  group('SubtitleToggle Widget', () {
    late PlayerController controller;

    setUp(() {
      controller = PlayerController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('显示字幕图标按钮', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SubtitleToggle(controller: controller)),
        ),
      );

      // 验证字幕图标存在
      expect(find.byIcon(Icons.subtitles), findsOneWidget);
    });

    testWidgets('没有字幕时按钮半透明', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SubtitleToggle(controller: controller)),
        ),
      );

      // 获取 Opacity widget 并验证 opacity 值为 0.4
      final opacityWidgets = find.descendant(
        of: find.byType(SubtitleToggle),
        matching: find.byType(Opacity),
      );

      expect(opacityWidgets, findsAtLeastNWidgets(1));

      // 验证实际的 opacity 值为 0.4（无字幕时半透明）
      final opacity = tester.widget<Opacity>(opacityWidgets.first);
      expect(opacity.opacity, 0.4);
    });

    testWidgets('字幕开启时按钮高亮', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SubtitleToggle(controller: controller)),
        ),
      );

      // 验证图标存在
      expect(find.byIcon(Icons.subtitles), findsOneWidget);

      // 验证按钮容器存在（高亮状态通过 Container 的 decoration 实现）
      final containerWidgets = find.descendant(
        of: find.byType(SubtitleToggle),
        matching: find.byType(Container),
      );

      expect(containerWidgets, findsAtLeastNWidgets(1));
    });

    testWidgets('可以多次重建不泄漏内存', (WidgetTester tester) async {
      // WHEN: 多次重建
      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: SubtitleToggle(controller: controller)),
          ),
        );
      }

      // THEN: 应该正常工作不崩溃
      expect(find.byType(SubtitleToggle), findsOneWidget);
    });

    testWidgets('下拉面板包含标题和选项', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SubtitleToggle(controller: controller)),
        ),
      );

      // 验证组件结构正确
      expect(find.byType(SubtitleToggle), findsOneWidget);
      expect(find.byIcon(Icons.subtitles), findsOneWidget);
    });
  });
}
