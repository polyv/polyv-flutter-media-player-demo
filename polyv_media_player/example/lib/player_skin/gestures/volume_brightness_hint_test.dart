import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'volume_brightness_hint.dart';
import 'player_gesture_controller.dart';

void main() {
  group('VolumeBrightnessHint Widget Tests', () {
    // Helper function to create wrapped widget for testing
    Widget makeTestableWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 800,
            child: Stack(children: [child]),
          ),
        ),
      );
    }

    group('P0 - 亮度提示基本渲染', () {
      testWidgets('[P0] 亮度提示应该显示亮度图标', (tester) async {
        // GIVEN: 亮度提示组件，值50%
        // WHEN: 渲染组件
        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.brightnessAdjust,
              value: 0.5,
            ),
          ),
        );

        // THEN: 显示亮度图标
        expect(find.byIcon(Icons.brightness_6_rounded), findsOneWidget);

        // THEN: 显示百分比文本 "50%"
        expect(find.text('50%'), findsOneWidget);

        // THEN: 显示进度条
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('[P0] 亮度提示应该有正确的背景样式', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.brightnessAdjust,
              value: 0.5,
            ),
          ),
        );

        // 检查圆形黑色半透明背景
        final container = tester.widget<Container>(
          find
              .ancestor(
                of: find.byType(Column),
                matching: find.byType(Container),
              )
              .first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, Colors.black.withValues(alpha: 0.7));
        expect(decoration.shape, BoxShape.circle);
      });
    });

    group('P0 - 音量提示基本渲染', () {
      testWidgets('[P0] 音量提示应该显示音量图标', (tester) async {
        // GIVEN: 音量提示组件，值70%
        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.volumeAdjust,
              value: 0.7,
            ),
          ),
        );

        // THEN: 显示音量图标
        expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

        // THEN: 显示百分比文本 "70%"
        expect(find.text('70%'), findsOneWidget);

        // THEN: 显示进度条
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });
    });

    group('P1 - 百分比显示', () {
      testWidgets('[P1] 亮度0%应该显示 "0%"', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.brightnessAdjust,
              value: 0.0,
            ),
          ),
        );

        expect(find.text('0%'), findsOneWidget);
      });

      testWidgets('[P1] 亮度100%应该显示 "100%"', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.brightnessAdjust,
              value: 1.0,
            ),
          ),
        );

        expect(find.text('100%'), findsOneWidget);
      });

      testWidgets('[P1] 音量25%应该显示 "25%"', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.volumeAdjust,
              value: 0.25,
            ),
          ),
        );

        expect(find.text('25%'), findsOneWidget);
      });

      testWidgets('[P1] 音量80%应该显示 "80%"', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.volumeAdjust,
              value: 0.8,
            ),
          ),
        );

        expect(find.text('80%'), findsOneWidget);
      });

      testWidgets('[P1] 超过100的值应该被限制为100%', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.brightnessAdjust,
              value: 1.5,
            ),
          ),
        );

        expect(find.text('100%'), findsOneWidget);
      });

      testWidgets('[P1] 负值应该被限制为0%', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.volumeAdjust,
              value: -0.5,
            ),
          ),
        );

        expect(find.text('0%'), findsOneWidget);
      });
    });

    group('P1 - 进度条显示', () {
      testWidgets('[P1] 亮度进度条应该反映当前值', (tester) async {
        const brightness = 0.6;

        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.brightnessAdjust,
              value: brightness,
            ),
          ),
        );

        final progressBar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progressBar.value, 0.6);
      });

      testWidgets('[P1] 音量进度条应该反映当前值', (tester) async {
        const volume = 0.85;

        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.volumeAdjust,
              value: volume,
            ),
          ),
        );

        final progressBar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progressBar.value, 0.85);
      });
    });

    group('P2 - UI样式细节', () {
      testWidgets('[P2] 图标应该是白色', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.brightnessAdjust,
              value: 0.5,
            ),
          ),
        );

        final icon = tester.widget<Icon>(
          find.byIcon(Icons.brightness_6_rounded),
        );
        expect(icon.color, Colors.white);
      });

      testWidgets('[P2] 图标大小应该是32', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.brightnessAdjust,
              value: 0.5,
            ),
          ),
        );

        final icon = tester.widget<Icon>(
          find.byIcon(Icons.brightness_6_rounded),
        );
        expect(icon.size, 32);
      });

      testWidgets('[P2] 百分比文本应该是白色', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.volumeAdjust,
              value: 0.5,
            ),
          ),
        );

        final text = tester.widget<Text>(find.text('50%'));
        expect(text.style?.color, Colors.white);
      });

      testWidgets('[P2] 百分比文本字体大小应该是12', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.volumeAdjust,
              value: 0.5,
            ),
          ),
        );

        final text = tester.widget<Text>(find.text('50%'));
        expect(text.style?.fontSize, 12);
      });
    });

    group('P2 - 布局和定位', () {
      testWidgets('[P2] 组件应该居中显示', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.brightnessAdjust,
              value: 0.5,
            ),
          ),
        );

        // 检查 Positioned.fill
        expect(find.byType(Positioned), findsOneWidget);

        final positioned = tester.widget<Positioned>(find.byType(Positioned));
        // Positioned.fill creates a Positioned with all edges set to 0
        expect(positioned.left, 0.0);
        expect(positioned.right, 0.0);
        expect(positioned.top, 0.0);
        expect(positioned.bottom, 0.0);

        // 检查 Center 组件（有2个Center，一个在Scaffold，一个在Hint中）
        expect(find.byType(Center), findsWidgets);
      });

      testWidgets('[P2] 内容应该垂直排列', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.brightnessAdjust,
              value: 0.5,
            ),
          ),
        );

        expect(find.byType(Column), findsOneWidget);

        final column = tester.widget<Column>(find.byType(Column));
        expect(column.mainAxisSize, MainAxisSize.min);
      });

      testWidgets('[P2] 进度条应该是垂直的（高度100，宽度4）', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.volumeAdjust,
              value: 0.5,
            ),
          ),
        );

        final sizedBox = tester.widget<SizedBox>(
          find
              .ancestor(
                of: find.byType(LinearProgressIndicator),
                matching: find.byType(SizedBox),
              )
              .first,
        );
        expect(sizedBox.width, 4);
        expect(sizedBox.height, 100);
      });
    });

    group('P2 - 旋转方向', () {
      testWidgets('[P2] 亮度进度条应该水平旋转（quarterTurns: -1）', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.brightnessAdjust,
              value: 0.5,
            ),
          ),
        );

        final rotatedBox = tester.widget<RotatedBox>(
          find
              .ancestor(
                of: find.byType(LinearProgressIndicator),
                matching: find.byType(RotatedBox),
              )
              .first,
        );
        expect(rotatedBox.quarterTurns, -1);
      });

      testWidgets('[P2] 音量进度条不应该旋转（quarterTurns: 0）', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.volumeAdjust,
              value: 0.5,
            ),
          ),
        );

        final rotatedBox = tester.widget<RotatedBox>(
          find
              .ancestor(
                of: find.byType(LinearProgressIndicator),
                matching: find.byType(RotatedBox),
              )
              .first,
        );
        expect(rotatedBox.quarterTurns, 0);
      });
    });

    group('P2 - 边界情况', () {
      testWidgets('[P2] 进度条超过1应该被clamp限制', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.brightnessAdjust,
              value: 2.0,
            ),
          ),
        );

        final progressBar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progressBar.value, 1.0);
      });

      testWidgets('[P2] 进度条为负数应该被clamp限制', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const VolumeBrightnessHint(
              type: GestureType.volumeAdjust,
              value: -1.0,
            ),
          ),
        );

        final progressBar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progressBar.value, 0.0);
      });
    });
  });
}
