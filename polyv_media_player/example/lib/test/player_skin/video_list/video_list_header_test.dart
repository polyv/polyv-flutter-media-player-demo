import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../player_skin/video_list/video_list_header.dart';

void main() {
  group('VideoListHeader', () {
    group('组件渲染测试', () {
      testWidgets('[P1] 应该正确渲染组件', (tester) async {
        // GIVEN: 创建 VideoListHeader 组件
        const header = VideoListHeader(videoCount: 10);

        // WHEN: 构建组件
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: header)),
        );

        // THEN: 组件应该渲染
        expect(find.byType(VideoListHeader), findsOneWidget);
      });

      testWidgets('[P1] 应该显示正确的视频数量格式', (tester) async {
        // GIVEN: 创建 VideoListHeader 组件，视频数量为 10
        const header = VideoListHeader(videoCount: 10);

        // WHEN: 构建组件
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: header)),
        );

        // THEN: 应该显示 "全部视频 · 10"
        expect(find.text('全部视频 · 10'), findsOneWidget);
      });

      testWidgets('[P1] 应该正确显示 0 个视频', (tester) async {
        // GIVEN: 创建 VideoListHeader 组件，视频数量为 0
        const header = VideoListHeader(videoCount: 0);

        // WHEN: 构建组件
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: header)),
        );

        // THEN: 应该显示 "全部视频 · 0"
        expect(find.text('全部视频 · 0'), findsOneWidget);
      });

      testWidgets('[P1] 应该正确显示大数量', (tester) async {
        // GIVEN: 创建 VideoListHeader 组件，视频数量为 1000
        const header = VideoListHeader(videoCount: 1000);

        // WHEN: 构建组件
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: header)),
        );

        // THEN: 应该显示 "全部视频 · 1000"
        expect(find.text('全部视频 · 1000'), findsOneWidget);
      });
    });

    group('样式验证测试', () {
      testWidgets('[P2] 应该使用正确的文字颜色 (slate-400)', (tester) async {
        // GIVEN: 创建 VideoListHeader 组件
        const header = VideoListHeader(videoCount: 5);

        // WHEN: 构建组件
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: header)),
        );

        // THEN: 文字颜色应该是 slate-400 (#FF94A3B8)
        final textWidget = tester.widget<Text>(find.text('全部视频 · 5'));
        expect(textWidget.style?.color, const Color(0xFF94A3B8));
      });

      testWidgets('[P2] 应该使用正确的字体大小 (14px)', (tester) async {
        // GIVEN: 创建 VideoListHeader 组件
        const header = VideoListHeader(videoCount: 5);

        // WHEN: 构建组件
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: header)),
        );

        // THEN: 字体大小应该是 14px
        final textWidget = tester.widget<Text>(find.text('全部视频 · 5'));
        expect(textWidget.style?.fontSize, equals(14));
      });

      testWidgets('[P2] 应该使用正确的字体粗细 (medium)', (tester) async {
        // GIVEN: 创建 VideoListHeader 组件
        const header = VideoListHeader(videoCount: 5);

        // WHEN: 构建组件
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: header)),
        );

        // THEN: 字体粗细应该是 medium (w500)
        final textWidget = tester.widget<Text>(find.text('全部视频 · 5'));
        expect(textWidget.style?.fontWeight, equals(FontWeight.w500));
      });

      testWidgets('[P2] 应该使用正确的内边距', (tester) async {
        // GIVEN: 创建 VideoListHeader 组件
        const header = VideoListHeader(videoCount: 5);

        // WHEN: 构建组件
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: header)),
        );

        // THEN: 容器应该有正确的内边距 (horizontal: 16, vertical: 12)
        final containerWidget = tester.widget<Container>(
          find.ancestor(
            of: find.text('全部视频 · 5'),
            matching: find.byType(Container),
          ),
        );
        expect(
          containerWidget.padding,
          equals(const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        );
      });
    });

    group('边界情况测试', () {
      testWidgets('[P2] 应该处理负数视频数量', (tester) async {
        // GIVEN: 创建 VideoListHeader 组件，视频数量为 -1
        const header = VideoListHeader(videoCount: -1);

        // WHEN: 构建组件
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: header)),
        );

        // THEN: 应该显示 "全部视频 · -1" (虽不合理但不崩溃)
        expect(find.text('全部视频 · -1'), findsOneWidget);
      });
    });
  });
}
