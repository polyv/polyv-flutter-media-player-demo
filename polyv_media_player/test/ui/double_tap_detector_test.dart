import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/polyv_media_player.dart';

void main() {
  group('DoubleTapDetector', () {
    testWidgets('应该触发单击回调', (WidgetTester tester) async {
      var singleTapCalled = false;
      var doubleTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoubleTapDetector(
              onTap: () => singleTapCalled = true,
              onDoubleTap: () => doubleTapCalled = true,
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      // 点击一次
      await tester.tap(find.byType(DoubleTapDetector));
      // 等待单击延迟 (300ms + 一些缓冲)
      await tester.pump(const Duration(milliseconds: 350));

      expect(singleTapCalled, isTrue, reason: '应该触发单击回调');
      expect(doubleTapCalled, isFalse, reason: '不应该触发双击回调');
    });

    testWidgets('应该触发双击回调而不触发单击', (WidgetTester tester) async {
      var singleTapCalled = false;
      var doubleTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoubleTapDetector(
              onTap: () => singleTapCalled = true,
              onDoubleTap: () => doubleTapCalled = true,
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      // 第一次点击
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 100));

      // 第二次点击 (在 300ms 内)
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 100));

      expect(doubleTapCalled, isTrue, reason: '应该触发双击回调');
      expect(singleTapCalled, isFalse, reason: '不应该触发单击回调');
    });

    testWidgets('超过延迟时间的两次点击应该触发两次单击', (WidgetTester tester) async {
      var singleTapCount = 0;
      var doubleTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoubleTapDetector(
              onTap: () => singleTapCount++,
              onDoubleTap: () => doubleTapCalled = true,
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      // 第一次点击
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 350));

      // 第二次点击 (超过 300ms 延迟)
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 350));

      expect(singleTapCount, equals(2), reason: '应该触发两次单击');
      expect(doubleTapCalled, isFalse, reason: '不应该触发双击回调');
    });

    testWidgets('没有设置回调时不应抛出异常', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DoubleTapDetector(child: SizedBox(width: 100, height: 100)),
          ),
        ),
      );

      // 点击一次 - 不应该抛出异常
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 350));

      // 快速双击 - 不应该抛出异常
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('应该正确清理定时器', (WidgetTester tester) async {
      var singleTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoubleTapDetector(
              onTap: () => singleTapCalled = true,
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      // 点击一次
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 50));

      // 移除 widget (应该清理定时器)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox(width: 100, height: 100)),
        ),
      );

      // 等待原始单击延迟时间
      await tester.pump(const Duration(milliseconds: 300));

      // 定时器应该被清理，不会触发回调
      expect(singleTapCalled, isFalse, reason: 'widget 卸载后不应该触发单击回调');
    });

    testWidgets('自定义延迟时间应该生效', (WidgetTester tester) async {
      var singleTapCalled = false;
      var doubleTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoubleTapDetector(
              onTap: () => singleTapCalled = true,
              onDoubleTap: () => doubleTapCalled = true,
              doubleTapDelay: const Duration(milliseconds: 100),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      // 第一次点击
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 50));

      // 第二次点击 (在 100ms 内)
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 50));

      expect(doubleTapCalled, isTrue, reason: '应该触发双击回调');
      expect(singleTapCalled, isFalse, reason: '不应该触发单击回调');
    });

    testWidgets('单击回调应该在延迟后触发', (WidgetTester tester) async {
      var singleTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoubleTapDetector(
              onTap: () => singleTapCalled = true,
              doubleTapDelay: const Duration(milliseconds: 100),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      // 点击一次
      await tester.tap(find.byType(DoubleTapDetector));

      // 延迟还未到达，不应该触发
      await tester.pump(const Duration(milliseconds: 50));
      expect(singleTapCalled, isFalse, reason: '延迟时间未到，不应该触发单击回调');

      // 延迟到达，应该触发
      await tester.pump(const Duration(milliseconds: 60));
      expect(singleTapCalled, isTrue, reason: '延迟时间到达，应该触发单击回调');
    });
  });
}
