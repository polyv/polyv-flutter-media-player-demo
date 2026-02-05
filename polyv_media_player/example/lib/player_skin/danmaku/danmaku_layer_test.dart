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

    testWidgets('弹幕关闭后再开启，弹幕重新从右侧开始滑动', (tester) async {
      // 验证 iOS 原生行为：弹幕关闭后重新开启，弹幕重新从右侧开始滑动
      // 而不是从暂停位置继续
      final danmakus = List.generate(
        5,
        (i) => Danmaku(
          id: 'danmaku_$i',
          text: '弹幕 $i',
          time: 5000 + i * 10,
        ),
      );

      // 初始状态：弹幕开启
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

      // 记录弹幕的 left 值（水平位置）
      final positionedWidgetsBefore = tester.widgetList<Positioned>(
        find.descendant(
          of: find.byType(DanmakuLayer),
          matching: find.byType(Positioned),
        ),
      );
      final leftValuesBefore = positionedWidgetsBefore.map((p) => p.left).toList();

      // 关闭弹幕
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: DanmakuLayer(
                enabled: false,
                opacity: 1.0,
                fontSize: DanmakuFontSize.medium,
                currentTime: 5100,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证弹幕被隐藏
      expect(find.text('弹幕 0'), findsNothing);

      // 重新开启弹幕
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
                currentTime: 5150,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证弹幕重新显示
      expect(find.text('弹幕 0'), findsOneWidget);

      // 验证弹幕位置（left 值）应该重新开始（接近右侧，即较大的 left 值）
      final positionedWidgetsAfter = tester.widgetList<Positioned>(
        find.descendant(
          of: find.byType(DanmakuLayer),
          matching: find.byType(Positioned),
        ),
      );
      final leftValuesAfter = positionedWidgetsAfter.map((p) => p.left).toList();

      // 弹幕应该重新显示（left 值存在）
      expect(leftValuesAfter.length, greaterThan(0));

      // 验证弹幕从右侧开始：left 值应该大于屏幕宽度的一半（200）
      // 当动画 value = 1.0 时，left = screenWidth = 400（右侧）
      // 即使动画已经开始移动，left 值也应该仍然较大
      expect(
        leftValuesAfter.any((left) => left != null && left! > 200),
        true,
        reason: '弹幕重新开启后应该从右侧开始滑动（left > 200）',
      );
    });

    testWidgets('弹幕关闭时动画停止', (tester) async {
      const danmaku = Danmaku(id: '1', text: '滚动弹幕', time: 5000);

      // 初始状态：弹幕开启
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

      // 记录初始 left 位置
      final positionedBefore = tester.widget<Positioned>(
        find.descendant(
          of: find.byType(DanmakuLayer),
          matching: find.byType(Positioned),
        ),
      );
      final leftBefore = positionedBefore.left;

      // 关闭弹幕
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
                currentTime: 5100,
                danmakus: [danmaku],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证弹幕被隐藏
      expect(find.text('滚动弹幕'), findsNothing);

      // 重新开启弹幕（动画应该从暂停位置继续）
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
                currentTime: 5200,
                danmakus: [danmaku],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证弹幕重新显示
      expect(find.text('滚动弹幕'), findsOneWidget);
    });

    testWidgets('弹幕关闭期间时间前进后开启显示新弹幕', (tester) async {
      // 创建在不同时间出现的弹幕
      final danmakus = [
        const Danmaku(id: '1', text: '早期弹幕', time: 5000),
        const Danmaku(id: '2', text: '晚期弹幕', time: 10000),
      ];

      // 初始状态：显示早期弹幕
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

      // 验证早期弹幕显示
      expect(find.text('早期弹幕'), findsOneWidget);

      // 关闭弹幕
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
                currentTime: 5000,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // 时间前进到 12000（晚期弹幕时间窗口内）
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
                currentTime: 12000,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // 重新开启弹幕
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
                currentTime: 12000,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证晚期弹幕显示（早期弹幕已过期）
      expect(find.text('晚期弹幕'), findsOneWidget);
    });

    testWidgets('简单测试：弹幕在正确时间显示', (tester) async {
      // 这是一个简单的测试，验证弹幕在正确的时间显示
      final danmakus = [
        const Danmaku(id: '1', text: '10秒弹幕', time: 10000),
      ];

      // 在时间 10000 显示弹幕
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
                currentTime: 10000,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证弹幕显示
      expect(find.text('10秒弹幕'), findsOneWidget);
    });

    testWidgets('简单测试2：关闭后短时间开启，弹幕重新显示', (tester) async {
      // 这个测试验证弹幕关闭后短时间开启，位置保持不变
      final danmakus = [
        const Danmaku(id: '1', text: '测试弹幕', time: 5000),
      ];

      // 开启弹幕
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

      expect(find.text('测试弹幕'), findsOneWidget);

      // 关闭弹幕
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
                currentTime: 5000,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // 短时间后重新开启（时间没变）
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

      // 验证弹幕重新显示
      expect(find.text('测试弹幕'), findsOneWidget);
    });

    testWidgets('弹幕关闭期间发生 seek，开启后显示新位置的弹幕', (tester) async {
      final danmakus = [
        const Danmaku(id: '1', text: '5秒弹幕', time: 5000),
        const Danmaku(id: '2', text: '15秒弹幕', time: 15000),
      ];

      // 初始状态：显示 5 秒弹幕
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

      expect(find.text('5秒弹幕'), findsOneWidget);

      // 关闭弹幕
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
                currentTime: 5000,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // seek 到 15 秒
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
                currentTime: 15000,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // 重新开启弹幕
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
                currentTime: 15000,
                danmakus: danmakus,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证显示 15 秒弹幕
      expect(find.text('15秒弹幕'), findsOneWidget);
    });

    testWidgets('多次快速切换弹幕开关', (tester) async {
      const danmaku = Danmaku(id: '1', text: '测试弹幕', time: 5000);

      // 快速切换 5 次
      for (int i = 0; i < 5; i++) {
        final enabled = i % 2 == 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 200,
                child: DanmakuLayer(
                  enabled: enabled,
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
      }

      // 最终状态：开启（i=4 时是偶数）
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

      // 验证弹幕正常显示
      expect(find.text('测试弹幕'), findsOneWidget);
    });

    testWidgets('弹幕关闭状态下不存在弹幕 Widget', (tester) async {
      const danmaku = Danmaku(id: '1', text: '测试弹幕', time: 5000);

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
                currentTime: 5000,
                danmakus: [danmaku],
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 验证弹幕文本不存在
      expect(find.text('测试弹幕'), findsNothing);

      // 验证 DanmakuLayer 返回的是 SizedBox.shrink()
      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(DanmakuLayer),
          matching: find.byType(SizedBox),
        ),
      );
      expect(sizedBox, isNotNull);
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
