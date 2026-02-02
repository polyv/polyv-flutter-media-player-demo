import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'seek_preview_overlay.dart';

void main() {
  group('SeekPreviewOverlay Widget Tests', () {
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

    group('P0 - 基本渲染和布局', () {
      testWidgets('[P0] 应该正确渲染时间显示和进度条', (tester) async {
        // GIVEN: 进度预览组件，进度50%，位置30秒，总时长60秒
        // WHEN: 渲染组件
        await tester.pumpWidget(
          makeTestableWidget(
            const SeekPreviewOverlay(
              progress: 0.5,
              currentPosition: 30000,
              duration: 60000,
            ),
          ),
        );

        // THEN: 显示正确的时间文本 "0:30 / 1:00"
        expect(find.text('0:30 / 1:00'), findsOneWidget);

        // THEN: 显示进度条
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        // THEN: 容器有圆角背景
        final container = tester.widget<Container>(
          find
              .ancestor(
                of: find.byType(LinearProgressIndicator),
                matching: find.byType(Container),
              )
              .first,
        );
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, Colors.black.withValues(alpha: 0.7));
        expect(decoration.borderRadius, BorderRadius.circular(8));
      });

      testWidgets('[P0] 进度条应该显示正确的进度值', (tester) async {
        // GIVEN: 进度为75%
        const progress = 0.75;

        await tester.pumpWidget(
          makeTestableWidget(
            const SeekPreviewOverlay(
              progress: progress,
              currentPosition: 45000,
              duration: 60000,
            ),
          ),
        );

        // WHEN: 获取进度条组件
        final progressBar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );

        // THEN: 进度值为0.75
        expect(progressBar.value, 0.75);
      });
    });

    group('P1 - 时间格式化', () {
      testWidgets('[P1] 应该正确格式化分钟和秒数 (MM:SS)', (tester) async {
        // GIVEN: 2分30秒
        await tester.pumpWidget(
          makeTestableWidget(
            const SeekPreviewOverlay(
              progress: 0.5,
              currentPosition: 150000, // 2:30
              duration: 300000, // 5:00
            ),
          ),
        );

        // THEN: 显示 "2:30 / 5:00"
        expect(find.text('2:30 / 5:00'), findsOneWidget);
      });

      testWidgets('[P1] 应该正确格式化小时、分钟和秒数 (HH:MM:SS)', (tester) async {
        // GIVEN: 超过60分钟的视频
        await tester.pumpWidget(
          makeTestableWidget(
            const SeekPreviewOverlay(
              progress: 0.5,
              currentPosition: 3661000, // 1:01:01
              duration: 7322000, // 2:02:02
            ),
          ),
        );

        // THEN: 显示 "1:01:01 / 2:02:02"
        expect(find.text('1:01:01 / 2:02:02'), findsOneWidget);
      });

      testWidgets('[P1] 零毫秒应该显示 "00:00"', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const SeekPreviewOverlay(
              progress: 0.0,
              currentPosition: 0,
              duration: 60000,
            ),
          ),
        );

        expect(find.text('00:00 / 1:00'), findsOneWidget);
      });

      testWidgets('[P1] 负值毫秒应该显示 "00:00"', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const SeekPreviewOverlay(
              progress: 0.0,
              currentPosition: -1000,
              duration: 60000,
            ),
          ),
        );

        expect(find.text('00:00 / 1:00'), findsOneWidget);
      });
    });

    group('P1 - 边界情况', () {
      testWidgets('[P1] 进度为0时应该显示在起始位置', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const SeekPreviewOverlay(
              progress: 0.0,
              currentPosition: 0,
              duration: 60000,
            ),
          ),
        );

        final progressBar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progressBar.value, 0.0);
      });

      testWidgets('[P1] 进度为1时应该显示在结束位置', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const SeekPreviewOverlay(
              progress: 1.0,
              currentPosition: 60000,
              duration: 60000,
            ),
          ),
        );

        final progressBar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progressBar.value, 1.0);
      });

      testWidgets('[P1] 超过1的进度应该被限制为1', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const SeekPreviewOverlay(
              progress: 1.5,
              currentPosition: 90000,
              duration: 60000,
            ),
          ),
        );

        final progressBar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        // 组件使用 clamp(0.0, 1.0)
        expect(progressBar.value, 1.0);
      });

      testWidgets('[P1] 负进度应该被限制为0', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const SeekPreviewOverlay(
              progress: -0.5,
              currentPosition: -30000,
              duration: 60000,
            ),
          ),
        );

        final progressBar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        // 组件使用 clamp(0.0, 1.0)
        expect(progressBar.value, 0.0);
      });
    });

    group('P2 - UI样式细节', () {
      testWidgets('[P2] 时间文本应该是白色', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const SeekPreviewOverlay(
              progress: 0.5,
              currentPosition: 30000,
              duration: 60000,
            ),
          ),
        );

        final textWidget = tester.widget<Text>(find.text('0:30 / 1:00'));
        expect(textWidget.style?.color, Colors.white);
      });

      testWidgets('[P2] 时间文本应该有正确的字体大小', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const SeekPreviewOverlay(
              progress: 0.5,
              currentPosition: 30000,
              duration: 60000,
            ),
          ),
        );

        final textWidget = tester.widget<Text>(find.text('0:30 / 1:00'));
        expect(textWidget.style?.fontSize, 16);
      });

      testWidgets('[P2] 进度条应该有正确的宽度', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const SeekPreviewOverlay(
              progress: 0.5,
              currentPosition: 30000,
              duration: 60000,
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
        expect(sizedBox.width, 200);
      });

      testWidgets('[P2] 进度条应该有正确的高度', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const SeekPreviewOverlay(
              progress: 0.5,
              currentPosition: 30000,
              duration: 60000,
            ),
          ),
        );

        final progressBar = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progressBar.minHeight, 4);
      });
    });

    group('P2 - 布局定位', () {
      testWidgets('[P2] 组件应该使用 Positioned.fill 居中显示', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const SeekPreviewOverlay(
              progress: 0.5,
              currentPosition: 30000,
              duration: 60000,
            ),
          ),
        );

        // 检查 Positioned.fill 使组件填充整个父容器
        expect(find.byType(Positioned), findsOneWidget);

        final positioned = tester.widget<Positioned>(find.byType(Positioned));
        // Positioned.fill creates a Positioned with left/right/top/bottom all set
        expect(positioned.left, 0.0);
        expect(positioned.right, 0.0);
        expect(positioned.top, 0.0);
        expect(positioned.bottom, 0.0);
      });

      testWidgets('[P2] 内容应该使用 Column 垂直排列', (tester) async {
        await tester.pumpWidget(
          makeTestableWidget(
            const SeekPreviewOverlay(
              progress: 0.5,
              currentPosition: 30000,
              duration: 60000,
            ),
          ),
        );

        // 应该有一个 Column 组件
        expect(find.byType(Column), findsOneWidget);
      });
    });
  });
}
