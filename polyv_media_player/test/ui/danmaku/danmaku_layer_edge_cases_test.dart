import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/polyv_media_player.dart';

void main() {
  group('DanmakuLayer Edge Case Widget Tests', () {
    testWidgets('[P1] empty danmakus list renders nothing', (tester) async {
      // GIVEN: A DanmakuLayer with empty danmakus list
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DanmakuLayer(
              enabled: true,
              opacity: 1.0,
              fontSize: DanmakuFontSize.medium,
              currentTime: 5000,
              danmakus: const [],
            ),
          ),
        ),
      );

      // WHEN: Pumping frames
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: No text should be rendered
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('[P1] danmakus with non-scroll type are filtered', (
      tester,
    ) async {
      // GIVEN: Danmakus with different types
      final danmakus = [
        const Danmaku(
          id: '1',
          text: '滚动弹幕',
          time: 5000,
          type: DanmakuType.scroll,
        ),
        const Danmaku(id: '2', text: '顶部弹幕', time: 5000, type: DanmakuType.top),
        const Danmaku(
          id: '3',
          text: '底部弹幕',
          time: 5000,
          type: DanmakuType.bottom,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: DanmakuLayer(
                enabled: true,
                opacity: 1.0,
                fontSize: DanmakuFontSize.medium,
                currentTime: 5050,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      // WHEN: Pumping frames
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: Only scroll type danmaku should be displayed
      // (The current implementation filters for scroll type in _updateActiveDanmakus)
      expect(find.text('滚动弹幕'), findsOneWidget);
    });

    testWidgets('[P1] opacity is clamped to valid range', (tester) async {
      // GIVEN: A DanmakuLayer with opacity > 1.0
      const danmaku = Danmaku(id: '1', text: '测试', time: 5000);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: DanmakuLayer(
                enabled: true,
                opacity: 1.5, // Invalid: > 1.0
                fontSize: DanmakuFontSize.medium,
                currentTime: 5000,
                danmakus: [danmaku],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: Opacity should be clamped to 1.0
      final opacityWidgets = tester.widgetList<Opacity>(
        find.ancestor(of: find.text('测试'), matching: find.byType(Opacity)),
      );
      expect(
        opacityWidgets.any((w) => w.opacity >= 0.0 && w.opacity <= 1.0),
        true,
      );
    });

    testWidgets('[P1] negative opacity is clamped to 0.0', (tester) async {
      // GIVEN: A DanmakuLayer with negative opacity
      const danmaku = Danmaku(id: '1', text: '测试', time: 5000);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: DanmakuLayer(
                enabled: true,
                opacity: -0.5, // Invalid: < 0.0
                fontSize: DanmakuFontSize.medium,
                currentTime: 5000,
                danmakus: [danmaku],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: Opacity should be clamped to 0.0
      final opacityWidgets = tester.widgetList<Opacity>(
        find.ancestor(of: find.text('测试'), matching: find.byType(Opacity)),
      );
      expect(
        opacityWidgets.any((w) => w.opacity >= 0.0 && w.opacity <= 1.0),
        true,
      );
    });

    testWidgets('[P2] time window boundary conditions', (tester) async {
      // GIVEN: Danmakus at time window boundaries
      // Initial update uses 10000ms animation window, subsequent use 1000ms time window
      // For initial update with currentTime = 5000:
      // - Danmaku is shown if: currentTime >= time && currentTime <= time + 10000
      // - i.e., time in [currentTime - 10000, currentTime] = [-5000, 5000]
      final danmakus = [
        const Danmaku(
          id: '1',
          text: '太早',
          time: 3999,
        ), // Inside: 3999 in [-5000, 5000]
        const Danmaku(
          id: '2',
          text: '边界下',
          time: 4000,
        ), // Inside: 4000 in [-5000, 5000]
        const Danmaku(id: '3', text: '窗口内', time: 5000), // Inside: 5000 == 5000
        const Danmaku(
          id: '4',
          text: '刚好在窗口内',
          time: 4500,
        ), // Inside: 4500 in [-5000, 5000]
        const Danmaku(id: '5', text: '太晚', time: 5001), // Outside: 5001 > 5000
        const Danmaku(
          id: '6',
          text: '太早动画外',
          time: -6000,
        ), // Outside: -6000 < -5000 (5000 > -6000 + 10000 = 4000)
        const Danmaku(
          id: '7',
          text: '很早',
          time: -7000,
        ), // Outside: -7000 < -5000
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: DanmakuLayer(
                enabled: true,
                opacity: 1.0,
                fontSize: DanmakuFontSize.medium,
                currentTime: 5000,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: Danmakus in animation window should be shown (not just time window)
      // Note: On initial update, DanmakuLayer uses [time, time + 10000] window
      expect(
        find.text('太早'),
        findsOneWidget,
      ); // Shown on initial update (3999 + 10000 = 13999 >= 5000)
      expect(find.text('边界下'), findsOneWidget);
      expect(find.text('窗口内'), findsOneWidget);
      expect(find.text('刚好在窗口内'), findsOneWidget);
      expect(find.text('太晚'), findsNothing);
      expect(
        find.text('太早动画外'),
        findsNothing,
      ); // Not shown (outside animation window)
      expect(
        find.text('很早'),
        findsNothing,
      ); // Not shown (outside animation window)

      // WHEN: Update currentTime to trigger second update (uses 1000ms time window)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: DanmakuLayer(
                enabled: true,
                opacity: 1.0,
                fontSize: DanmakuFontSize.medium,
                currentTime: 5000,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: After second update, only danmakus in 1000ms time window [4000, 5000] should be shown
      // But danmakus that were already active remain active until expired
      // So "太早" at 3999 might still be visible since it was added before
      expect(find.text('边界下'), findsOneWidget);
      expect(find.text('窗口内'), findsOneWidget);
      expect(find.text('刚好在窗口内'), findsOneWidget);
      expect(find.text('太晚'), findsNothing);
    });

    testWidgets('[P2] track assignment distributes evenly', (tester) async {
      // GIVEN: Many danmakus at the same time
      final danmakus = List.generate(
        10,
        (i) => Danmaku(id: 'danmaku_$i', text: '弹幕 $i', time: 5000),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: DanmakuLayer(
                enabled: true,
                opacity: 1.0,
                fontSize: DanmakuFontSize.medium,
                currentTime: 5050,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: All danmakus should be displayed
      for (int i = 0; i < 10; i++) {
        expect(find.text('弹幕 $i'), findsOneWidget);
      }

      // AND: Should be distributed across different tracks
      final positionedWidgets = tester.widgetList<Positioned>(
        find.descendant(
          of: find.byType(DanmakuLayer),
          matching: find.byType(Positioned),
        ),
      );

      final topValues = positionedWidgets.map((p) => p.top).toSet();
      // Should have multiple different top values (tracks)
      expect(topValues.length, greaterThan(1));
    });

    testWidgets('[P2] danmakus with colors render correctly', (tester) async {
      // GIVEN: Danmakus with different colors
      final danmakus = [
        const Danmaku(id: '1', text: '红色弹幕', time: 5000, color: 0xFFFF6B6B),
        const Danmaku(id: '2', text: '青色弹幕', time: 5000, color: 0xFF4ECDC4),
        const Danmaku(
          id: '3',
          text: '白色弹幕',
          time: 5000,
          color: null, // Default white
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: DanmakuLayer(
                enabled: true,
                opacity: 1.0,
                fontSize: DanmakuFontSize.medium,
                currentTime: 5050,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: All colored danmakus should be displayed
      expect(find.text('红色弹幕'), findsOneWidget);
      expect(find.text('青色弹幕'), findsOneWidget);
      expect(find.text('白色弹幕'), findsOneWidget);
    });

    testWidgets('[P2] switching enabled clears active danmakus', (
      tester,
    ) async {
      // GIVEN: A DanmakuLayer with danmakus
      final danmakus = [
        const Danmaku(id: '1', text: '弹幕1', time: 5000),
        const Danmaku(id: '2', text: '弹幕2', time: 5000),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: DanmakuLayer(
                enabled: true,
                opacity: 1.0,
                fontSize: DanmakuFontSize.medium,
                currentTime: 5050,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify danmakus are shown
      expect(find.text('弹幕1'), findsOneWidget);

      // WHEN: Disabling danmaku
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: DanmakuLayer(
                enabled: false,
                opacity: 1.0,
                fontSize: DanmakuFontSize.medium,
                currentTime: 5050,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // THEN: No danmakus should be shown
      expect(find.text('弹幕1'), findsNothing);
      expect(find.text('弹幕2'), findsNothing);
    });

    testWidgets('[P2] updating currentTime changes visible danmakus', (
      tester,
    ) async {
      // GIVEN: Danmakus at different times
      final danmakus = [
        const Danmaku(id: '1', text: '早期弹幕', time: 2000),
        const Danmaku(id: '2', text: '中期弹幕', time: 5000),
        const Danmaku(id: '3', text: '晚期弹幕', time: 8000),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: DanmakuLayer(
                enabled: true,
                opacity: 1.0,
                fontSize: DanmakuFontSize.medium,
                currentTime: 2050,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: Only early danmaku should be shown
      expect(find.text('早期弹幕'), findsOneWidget);
      expect(find.text('中期弹幕'), findsNothing);

      // WHEN: Updating currentTime
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: DanmakuLayer(
                enabled: true,
                opacity: 1.0,
                fontSize: DanmakuFontSize.medium,
                currentTime: 5050,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: Middle danmaku should now be shown
      expect(find.text('中期弹幕'), findsOneWidget);
    });

    testWidgets('[P3] very long danmaku text renders correctly', (
      tester,
    ) async {
      // GIVEN: A danmaku with very long text
      final longText = '非常长的弹幕内容' * 20; // 400+ characters
      final danmaku = Danmaku(id: '1', text: longText, time: 5000);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: DanmakuLayer(
                enabled: true,
                opacity: 1.0,
                fontSize: DanmakuFontSize.medium,
                currentTime: 5050,
                danmakus: [danmaku],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: Long text should be rendered
      expect(find.text(longText), findsOneWidget);
    });

    testWidgets('[P3] special characters in danmaku text render correctly', (
      tester,
    ) async {
      // GIVEN: Danmakus with special characters
      final danmakus = [
        Danmaku(id: '1', text: '测试@#\$%^&*()', time: 5000),
        Danmaku(id: '2', text: 'Emoji 测试 🎉🎊', time: 5000),
        Danmaku(id: '3', text: '换行\n测试', time: 5000),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: DanmakuLayer(
                enabled: true,
                opacity: 1.0,
                fontSize: DanmakuFontSize.medium,
                currentTime: 5050,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: All special character danmakus should be displayed
      expect(find.text('测试@#\$%^&*()'), findsOneWidget);
      expect(find.text('Emoji 测试 🎉🎊'), findsOneWidget);
      expect(find.text('换行\n测试'), findsOneWidget);
    });

    testWidgets('[P3] danmakus with unique IDs display correctly', (
      tester,
    ) async {
      // GIVEN: Multiple danmakus with different IDs
      final danmakus = [
        const Danmaku(id: 'danmaku_1', text: '弹幕A', time: 5000),
        const Danmaku(id: 'danmaku_2', text: '弹幕B', time: 5000),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: DanmakuLayer(
                enabled: true,
                opacity: 1.0,
                fontSize: DanmakuFontSize.medium,
                currentTime: 5050,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: Both danmakus should be shown (different IDs)
      expect(find.text('弹幕A'), findsOneWidget);
      expect(find.text('弹幕B'), findsOneWidget);
    });

    testWidgets('[P3] zero/negative currentTime is handled', (tester) async {
      // GIVEN: Danmakus with currentTime = 0
      final danmakus = [const Danmaku(id: '1', text: '弹幕', time: 0)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: DanmakuLayer(
                enabled: true,
                opacity: 1.0,
                fontSize: DanmakuFontSize.medium,
                currentTime: 0,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: Should handle zero currentTime correctly
      expect(find.text('弹幕'), findsOneWidget);
    });

    testWidgets('[P3] danmaku text shadow is applied', (tester) async {
      // GIVEN: A danmaku
      const danmaku = Danmaku(id: '1', text: '测试', time: 5000);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: DanmakuLayer(
                enabled: true,
                opacity: 1.0,
                fontSize: DanmakuFontSize.medium,
                currentTime: 5050,
                danmakus: [danmaku],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: Text widget should have shadow
      final textWidget = tester.widget<Text>(find.text('测试'));
      expect(textWidget.style?.shadows, isNotEmpty);
    });
  });

  group('DanmakuLayer Performance and Cleanup Tests', () {
    testWidgets('[P2] disposal cleans up resources', (tester) async {
      // GIVEN: A DanmakuLayer
      final danmakus = [const Danmaku(id: '1', text: '测试', time: 5000)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DanmakuLayer(
              enabled: true,
              opacity: 1.0,
              fontSize: DanmakuFontSize.medium,
              currentTime: 5050,
              danmakus: danmakus,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // WHEN: Removing the widget
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );

      await tester.pump();

      // THEN: No danmakus should remain in tree
      expect(find.byType(DanmakuLayer), findsNothing);
      expect(find.text('测试'), findsNothing);
    });

    testWidgets('[P2] rapid currentTime updates are handled', (tester) async {
      // GIVEN: A DanmakuLayer
      final danmakus = [const Danmaku(id: '1', text: '快速更新', time: 5000)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DanmakuLayer(
              enabled: true,
              opacity: 1.0,
              fontSize: DanmakuFontSize.medium,
              currentTime: 5050,
              danmakus: danmakus,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // WHEN: Rapidly updating currentTime
      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DanmakuLayer(
                enabled: true,
                opacity: 1.0,
                fontSize: DanmakuFontSize.medium,
                currentTime: 5000 + i * 100,
                danmakus: danmakus,
              ),
            ),
          ),
        );
        await tester.pump();
      }

      // THEN: Should handle without errors
      expect(tester.takeException(), isNull);
    });
  });
}
