import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'danmaku.dart';

void main() {
  group('DanmakuLayer Widget Tests', () {
    testWidgets('enabled == false 时不渲染任何弹幕', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DanmakuLayer(
              enabled: false,
              opacity: 1.0,
              fontSize: DanmakuFontSize.medium,
              currentTime: 5000,
              danmakus: [const Danmaku(id: '1', text: '测试弹幕', time: 5000)],
            ),
          ),
        ),
      );

      // 验证弹幕层不渲染任何内容
      expect(find.byType(DanmakuLayer), findsOneWidget);
      expect(find.text('测试弹幕'), findsNothing);
    });

    testWidgets('enabled == true 时渲染符合时间条件的弹幕', (tester) async {
      final danmakus = List.generate(
        10,
        (i) => Danmaku(
          id: 'danmaku_$i',
          text: '弹幕 $i',
          time: i * 1000, // 0, 1, 2, ..., 9 秒
        ),
      );

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
                currentTime: 5000, // 当前时间在 5 秒
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      // 触发动画帧并等待 post frame callback
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证弹幕层存在
      expect(find.byType(DanmakuLayer), findsOneWidget);

      // 时间窗口是 300ms，所以应该显示 time 在 (4700, 5000] 范围内的弹幕
      // danmakus[5] 的 time = 5000 (在范围内)
      expect(find.text('弹幕 5'), findsOneWidget);
    });

    testWidgets('不同 fontSize 正确应用', (tester) async {
      const danmaku = Danmaku(id: '1', text: '测试弹幕', time: 5000);

      for (final fontSize in DanmakuFontSize.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 200,
                child: DanmakuLayer(
                  enabled: true,
                  opacity: 1.0,
                  fontSize: fontSize,
                  currentTime: 5000,
                  danmakus: [danmaku],
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // 验证弹幕文本存在
        expect(find.text('测试弹幕'), findsOneWidget);

        // 获取文本的 TextStyle
        final textWidget = tester.widget<Text>(find.text('测试弹幕'));
        final expectedFontSize = {
          DanmakuFontSize.small: 12.0,
          DanmakuFontSize.medium: 14.0,
          DanmakuFontSize.large: 16.0,
        }[fontSize];

        expect(textWidget.style?.fontSize, expectedFontSize);
      }
    });

    testWidgets('opacity 正确应用', (tester) async {
      const danmaku = Danmaku(id: '1', text: '测试弹幕', time: 5000);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 200,
              child: DanmakuLayer(
                enabled: true,
                opacity: 0.5,
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

      // 验证 Opacity widget 存在且值正确
      final opacityWidgets = tester.widgetList<Opacity>(
        find.ancestor(of: find.text('测试弹幕'), matching: find.byType(Opacity)),
      );

      // 应该找到一个 Opacity widget，值为 0.5
      expect(opacityWidgets.any((w) => w.opacity == 0.5), true);
    });

    testWidgets('弹幕滚动动画存在', (tester) async {
      const danmaku = Danmaku(id: '1', text: '滚动弹幕', time: 5000);

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
                danmakus: [danmaku],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证弹幕文本存在
      expect(find.text('滚动弹幕'), findsOneWidget);

      // 验证 AnimationController 和 AnimatedBuilder 存在
      // (间接验证：弹幕应该在屏幕右侧开始)
      final positionedWidgets = tester.widgetList<Positioned>(
        find.ancestor(of: find.text('滚动弹幕'), matching: find.byType(Positioned)),
      );

      // 初始位置应该在右侧（left > width / 2）
      expect(
        positionedWidgets.any((w) => w.left != null && w.left! > 150),
        true,
      );
    });

    testWidgets('多条弹幕在不同轨道显示', (tester) async {
      // 创建多条时间相近的弹幕
      final danmakus = List.generate(
        5,
        (i) => Danmaku(
          id: 'danmaku_$i',
          text: '弹幕 $i',
          time: 5000 + i * 10, // 时间非常接近，会分配到不同轨道
        ),
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
                currentTime: 5050, // 让所有弹幕都在时间窗口内
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证所有弹幕都被显示
      for (int i = 0; i < 5; i++) {
        expect(find.text('弹幕 $i'), findsOneWidget);
      }

      // 验证弹幕在不同轨道（top 值不同）
      final positionedWidgets = tester.widgetList<Positioned>(
        find.descendant(
          of: find.byType(DanmakuLayer),
          matching: find.byType(Positioned),
        ),
      );

      final topValues = positionedWidgets.map((p) => p.top).toSet();

      // 所有弹幕应该有不同的 top 值（不同轨道）
      expect(topValues.length, greaterThan(1));
    });

    testWidgets('弹幕不拦截手势事件', (tester) async {
      const danmaku = Danmaku(id: '1', text: '测试弹幕', time: 5000);

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
                danmakus: [danmaku],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证 IgnorePointer widget 存在
      expect(find.byType(IgnorePointer), findsWidgets);
    });
  });

  group('Danmaku Model Tests', () {
    test('Danmaku equality works correctly', () {
      const danmaku1 = Danmaku(id: '1', text: '测试', time: 1000);

      const danmaku2 = Danmaku(id: '1', text: '测试', time: 1000);

      const danmaku3 = Danmaku(id: '2', text: '测试', time: 1000);

      expect(danmaku1, equals(danmaku2));
      expect(danmaku1, isNot(equals(danmaku3)));
    });

    test('Danmaku copyWith works correctly', () {
      const danmaku = Danmaku(
        id: '1',
        text: '测试',
        time: 1000,
        type: DanmakuType.scroll,
      );

      final copied = danmaku.copyWith(text: '修改后', type: DanmakuType.top);

      expect(copied.id, danmaku.id);
      expect(copied.text, '修改后');
      expect(copied.time, danmaku.time);
      expect(copied.type, DanmakuType.top);
    });

    test('Danmaku fromJson works correctly', () {
      final json = {
        'id': '1',
        'text': '测试',
        'time': 1000,
        'color': '#FFFF0000',
        'type': 'top',
      };

      final danmaku = Danmaku.fromJson(json);

      expect(danmaku.id, '1');
      expect(danmaku.text, '测试');
      expect(danmaku.time, 1000);
      expect(danmaku.type, DanmakuType.top);
      expect(danmaku.color, isNotNull);
    });

    test('ActiveDanmaku.fromDanmaku works correctly', () {
      const danmaku = Danmaku(id: '1', text: '测试', time: 1000);

      final activeDanmaku = ActiveDanmaku.fromDanmaku(
        danmaku,
        track: 3,
        startTime: 5000,
      );

      expect(activeDanmaku.id, danmaku.id);
      expect(activeDanmaku.text, danmaku.text);
      expect(activeDanmaku.time, danmaku.time);
      expect(activeDanmaku.track, 3);
      expect(activeDanmaku.startTime, 5000);
    });

    test('ActiveDanmaku.isExpired works correctly', () {
      const activeDanmaku = ActiveDanmaku(
        id: '1',
        text: '测试',
        time: 1000,
        track: 0,
        startTime: 0,
      );

      // 9999ms 后还没过期 (animationDuration is 10000ms)
      expect(activeDanmaku.isExpired(9999), false);

      // 10000ms 后过期
      expect(activeDanmaku.isExpired(10000), true);

      // 10001ms 后已过期
      expect(activeDanmaku.isExpired(10001), true);
    });
  });

  group('DanmakuFontSize Enum Tests', () {
    test('所有 DanmakuFontSize 值存在', () {
      expect(DanmakuFontSize.values.length, 3);
      expect(DanmakuFontSize.values, contains(DanmakuFontSize.small));
      expect(DanmakuFontSize.values, contains(DanmakuFontSize.medium));
      expect(DanmakuFontSize.values, contains(DanmakuFontSize.large));
    });
  });

  group('DanmakuType Enum Tests', () {
    test('所有 DanmakuType 值存在', () {
      expect(DanmakuType.values.length, 3);
      expect(DanmakuType.values, contains(DanmakuType.scroll));
      expect(DanmakuType.values, contains(DanmakuType.top));
      expect(DanmakuType.values, contains(DanmakuType.bottom));
    });
  });
}
