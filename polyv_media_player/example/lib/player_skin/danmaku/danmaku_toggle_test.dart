import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/infrastructure/danmaku/danmaku_model.dart';
import 'danmaku_settings.dart';
import 'danmaku_toggle.dart';

void main() {
  group('DanmakuSettings', () {
    test('应该创建默认设置', () {
      final settings = DanmakuSettings();

      expect(settings.enabled, isTrue);
      expect(settings.opacity, equals(1.0));
      expect(settings.fontSize, equals(DanmakuFontSize.medium));
    });

    test('应该使用自定义值创建设置', () {
      final settings = DanmakuSettings(
        enabled: false,
        opacity: 0.5,
        fontSize: DanmakuFontSize.large,
      );

      expect(settings.enabled, isFalse);
      expect(settings.opacity, equals(0.5));
      expect(settings.fontSize, equals(DanmakuFontSize.large));
    });

    test('toggle() 应该切换 enabled 状态', () {
      final settings = DanmakuSettings();
      expect(settings.enabled, isTrue);

      settings.toggle();
      expect(settings.enabled, isFalse);

      settings.toggle();
      expect(settings.enabled, isTrue);
    });

    test('setEnabled() 应该更新 enabled 状态', () {
      final settings = DanmakuSettings();

      settings.setEnabled(false);
      expect(settings.enabled, isFalse);

      settings.setEnabled(true);
      expect(settings.enabled, isTrue);
    });

    test('setOpacity() 应该更新 opacity 状态', () {
      final settings = DanmakuSettings();
      expect(settings.opacity, equals(1.0));

      settings.setOpacity(0.5);
      expect(settings.opacity, equals(0.5));
    });

    test('setOpacity() 应该限制在 0.0 - 1.0 范围内', () {
      final settings = DanmakuSettings();

      settings.setOpacity(-0.5);
      expect(settings.opacity, equals(0.0));

      settings.setOpacity(1.5);
      expect(settings.opacity, equals(1.0));
    });

    test('setFontSize() 应该更新 fontSize 状态', () {
      final settings = DanmakuSettings();
      expect(settings.fontSize, equals(DanmakuFontSize.medium));

      settings.setFontSize(DanmakuFontSize.small);
      expect(settings.fontSize, equals(DanmakuFontSize.small));

      settings.setFontSize(DanmakuFontSize.large);
      expect(settings.fontSize, equals(DanmakuFontSize.large));
    });

    test('状态变更时应该通知监听者', () async {
      final settings = DanmakuSettings();
      var notified = false;

      settings.addListener(() {
        notified = true;
      });

      settings.toggle();
      expect(notified, isTrue);

      notified = false;
      settings.setOpacity(0.5);
      expect(notified, isTrue);

      notified = false;
      settings.setFontSize(DanmakuFontSize.large);
      expect(notified, isTrue);
    });

    test('相同值不应该触发通知', () async {
      final settings = DanmakuSettings();
      var notifiedCount = 0;

      settings.addListener(() {
        notifiedCount++;
      });

      settings.setEnabled(true); // 已经是 true
      expect(notifiedCount, equals(0));

      settings.setOpacity(1.0); // 已经是 1.0
      expect(notifiedCount, equals(0));

      settings.setFontSize(DanmakuFontSize.medium); // 已经是 medium
      expect(notifiedCount, equals(0));
    });

    test('copyWith() 应该创建带有新值的副本', () {
      final settings = DanmakuSettings();

      final copy = settings.copyWith(
        enabled: false,
        opacity: 0.7,
        fontSize: DanmakuFontSize.small,
      );

      expect(copy.enabled, isFalse);
      expect(copy.opacity, equals(0.7));
      expect(copy.fontSize, equals(DanmakuFontSize.small));

      // 原对象不应改变
      expect(settings.enabled, isTrue);
      expect(settings.opacity, equals(1.0));
      expect(settings.fontSize, equals(DanmakuFontSize.medium));
    });

    test('toJson() 和 fromJson() 应该正确序列化', () {
      final settings = DanmakuSettings(
        enabled: false,
        opacity: 0.6,
        fontSize: DanmakuFontSize.large,
      );

      final json = settings.toJson();
      expect(json['enabled'], isFalse);
      expect(json['opacity'], equals(0.6));
      expect(json['fontSize'], equals('large'));

      final restored = DanmakuSettings.fromJson(json);
      expect(restored.enabled, isFalse);
      expect(restored.opacity, equals(0.6));
      expect(restored.fontSize, equals(DanmakuFontSize.large));
    });

    test('equality 应该基于所有属性', () {
      final settings1 = DanmakuSettings();
      final settings2 = DanmakuSettings();
      final settings3 = DanmakuSettings(enabled: false);

      expect(settings1, equals(settings2));
      expect(settings1, isNot(equals(settings3)));
    });

    test('hashCode 应该基于所有属性', () {
      final settings1 = DanmakuSettings();
      final settings2 = DanmakuSettings();

      expect(settings1.hashCode, equals(settings2.hashCode));
    });
  });

  group('DanmakuToggle', () {
    late DanmakuSettings settings;

    setUp(() {
      settings = DanmakuSettings();
    });

    testWidgets('应该渲染弹幕开关按钮', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DanmakuToggle(settings: settings)),
        ),
      );

      // 验证开关按钮存在
      expect(find.byIcon(Icons.chat_bubble), findsOneWidget);
    });

    testWidgets('enabled=false 时应该显示空心图标', (tester) async {
      settings.setEnabled(false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DanmakuToggle(settings: settings)),
        ),
      );

      // 验证显示空心图标
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble), findsNothing);
    });

    testWidgets('enabled=true 时应该显示实心图标', (tester) async {
      settings.setEnabled(true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DanmakuToggle(settings: settings)),
        ),
      );

      // 验证显示实心图标
      expect(find.byIcon(Icons.chat_bubble), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
    });

    testWidgets('点击开关按钮应该切换状态', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DanmakuToggle(settings: settings)),
        ),
      );

      // 初始状态：enabled
      expect(settings.enabled, isTrue);

      // 点击开关按钮
      await tester.tap(find.byType(DanmakuToggle));
      await tester.pump();

      // 状态应该切换
      expect(settings.enabled, isFalse);
    });

    testWidgets('透明度设置应该支持直接修改', (tester) async {
      expect(settings.opacity, equals(1.0));

      settings.setOpacity(0.5);
      expect(settings.opacity, equals(0.5));
    });

    testWidgets('字号设置应该支持直接修改', (tester) async {
      expect(settings.fontSize, equals(DanmakuFontSize.medium));

      settings.setFontSize(DanmakuFontSize.small);
      expect(settings.fontSize, equals(DanmakuFontSize.small));
    });
  });

  group('DanmakuSettings Integration', () {
    testWidgets('DanmakuSettings 变更应该通知 DanmakuToggle 重建', (tester) async {
      final settings = DanmakuSettings();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: settings,
              builder: (context, _) {
                return DanmakuToggle(settings: settings);
              },
            ),
          ),
        ),
      );

      // 初始显示实心图标
      expect(find.byIcon(Icons.chat_bubble), findsOneWidget);

      // 切换状态
      settings.toggle();
      await tester.pump();

      // 应该显示空心图标
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    });
  });
}
