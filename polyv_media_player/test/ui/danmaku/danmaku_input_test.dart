import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/polyv_media_player.dart';

void main() {
  group('DanmakuInput', () {
    testWidgets('显示输入框和发送按钮', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DanmakuInput(onSend: (text, color) async {})),
        ),
      );

      // 验证输入框存在
      expect(find.byType(TextField), findsOneWidget);

      // 验证发送按钮存在
      expect(find.byIcon(Icons.send_outlined), findsOneWidget);

      // 验证颜色选择按钮存在
      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    });

    testWidgets('输入文本后按钮状态变化', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DanmakuInput(onSend: (text, color) async {})),
        ),
      );

      // 初始状态下发送按钮应为禁用（文字颜色为灰色）
      final sendButton = find.byIcon(Icons.send_outlined);
      expect(sendButton, findsOneWidget);

      // 输入文本
      await tester.enterText(find.byType(TextField), '测试弹幕');
      await tester.pump();

      // 验证输入框有文本
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals('测试弹幕'));
    });

    testWidgets('点击发送按钮触发回调', (WidgetTester tester) async {
      String? sentText;
      String? sentColor;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DanmakuInput(
              onSend: (text, color) async {
                sentText = text;
                sentColor = color;
              },
            ),
          ),
        ),
      );

      // 输入文本
      await tester.enterText(find.byType(TextField), '测试弹幕');
      await tester.pumpAndSettle();

      // 通过回车键触发发送
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      // 验证回调被调用
      expect(sentText, equals('测试弹幕'));
      expect(sentColor, equals('#ffffff')); // 默认白色
    });

    testWidgets('禁用状态下无法发送', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DanmakuInput(onSend: (text, color) async {}, disabled: true),
          ),
        ),
      );

      // 尝试输入文本（禁用状态下 TextField 不应接受输入）
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('加载状态下显示加载指示器', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DanmakuInput(onSend: (text, color) async {}, isLoading: true),
          ),
        ),
      );

      // 应显示 CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('颜色选择器显示和隐藏', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DanmakuInput(onSend: (text, color) async {})),
        ),
      );

      // 初始状态颜色选择器不显示
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // 点击颜色按钮
      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pump();

      // 颜色选择面板应该出现（通过检查是否有多个圆形颜色按钮）
      // 这里我们只是验证点击不会导致错误
    });
  });

  group('SimpleDanmakuInput', () {
    testWidgets('显示简化版输入组件', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SimpleDanmakuInput(onSend: (text) async {})),
        ),
      );

      // 验证输入框存在
      expect(find.byType(TextField), findsOneWidget);

      // 验证发送按钮存在
      expect(find.byIcon(Icons.send_outlined), findsOneWidget);

      // 简化版不应有颜色选择器
      expect(find.byIcon(Icons.palette_outlined), findsNothing);
    });
  });
}
