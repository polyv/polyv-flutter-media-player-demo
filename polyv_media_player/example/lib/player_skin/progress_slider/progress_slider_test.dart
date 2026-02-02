import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/polyv_media_player.dart';
import 'progress_slider.dart';
import 'time_label.dart';

void main() {
  group('TimeLabel', () {
    testWidgets('显示格式化的时间', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TimeLabel(milliseconds: 90000), // 1:30
          ),
        ),
      );

      expect(find.text('01:30'), findsOneWidget);
    });

    testWidgets('显示短于1分钟的时间', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TimeLabel(milliseconds: 45000), // 0:45
          ),
        ),
      );

      expect(find.text('00:45'), findsOneWidget);
    });

    testWidgets('显示超过1小时的时间', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TimeLabel(milliseconds: 3661000), // 1:01:01
          ),
        ),
      );

      expect(find.text('1:01:01'), findsOneWidget);
    });

    testWidgets('显示未知时间当showUnknown为true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TimeLabel(milliseconds: 0, showUnknown: true)),
        ),
      );

      expect(find.text('--:--'), findsOneWidget);
    });

    testWidgets('零毫秒显示00:00', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TimeLabel(milliseconds: 0))),
      );

      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('负数毫秒显示00:00', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: TimeLabel(milliseconds: -1000))),
      );

      expect(find.text('00:00'), findsOneWidget);
    });

    testWidgets('1小时边界测试：3599999ms显示为59:59', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TimeLabel(milliseconds: 3599999), // 59分59.999秒
          ),
        ),
      );

      expect(find.text('59:59'), findsOneWidget);
    });

    testWidgets('1小时边界测试：3600000ms显示为1:00:00', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TimeLabel(milliseconds: 3600000), // 正好1小时
          ),
        ),
      );

      expect(find.text('1:00:00'), findsOneWidget);
    });

    testWidgets('超长视频测试：100小时显示为100:00:00', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TimeLabel(milliseconds: 360000000), // 100小时
          ),
        ),
      );

      expect(find.text('100:00:00'), findsOneWidget);
    });
  });

  group('ProgressSlider', () {
    late PlayerController controller;

    setUp(() {
      controller = PlayerController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('显示进度条和当前时间', (tester) async {
      // 模拟播放器状态
      final state = PlayerState(
        loadingState: PlayerLoadingState.playing,
        position: 30000, // 0:30
        duration: 60000, // 1:00
        bufferedPosition: 45000,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                return ProgressSlider(
                  value: state.progress,
                  bufferValue: state.bufferProgress,
                  duration: state.duration,
                  position: state.position,
                  onSeek: (_) {},
                );
              },
            ),
          ),
        ),
      );

      // 检查当前时间显示
      expect(find.text('00:30'), findsOneWidget);
      // 检查总时间显示
      expect(find.text('01:00'), findsOneWidget);
    });

    testWidgets('拖动进度条触发onSeek回调', (tester) async {
      double? seekValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressSlider(
              value: 0.3,
              bufferValue: 0.5,
              duration: 60000,
              position: 18000,
              onSeek: (value) => seekValue = value,
            ),
          ),
        ),
      );

      // 查找 Slider widget
      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      // 模拟拖动操作（通过点击进度条右侧）
      await tester.tapAt(tester.getCenter(sliderFinder) + const Offset(50, 0));
      await tester.pumpAndSettle();

      // 验证 onSeek 被调用
      expect(seekValue, isNotNull);
    });

    testWidgets('隐藏时间标签当showTimeLabels为false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressSlider(
              value: 0.5,
              bufferValue: 0.7,
              duration: 60000,
              position: 30000,
              onSeek: (_) {},
              showTimeLabels: false,
            ),
          ),
        ),
      );

      // 应该没有时间文本显示
      expect(find.text('00:30'), findsNothing);
      expect(find.text('01:00'), findsNothing);
    });

    testWidgets('显示未知总时长当duration为0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressSlider(
              value: 0,
              bufferValue: 0,
              duration: 0,
              position: 0,
              onSeek: (_) {},
            ),
          ),
        ),
      );

      // 右侧时间应显示 --:--
      expect(find.text('--:--'), findsOneWidget);
    });

    testWidgets('进度条正确显示缓冲进度', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressSlider(
              value: 0.3,
              bufferValue: 0.6,
              duration: 60000,
              position: 18000,
              onSeek: (_) {},
            ),
          ),
        ),
      );

      // Slider 应该存在（包含缓冲进度显示）
      expect(find.byType(Slider), findsOneWidget);

      // 验证 Slider 的 secondaryTrackValue 被正确设置
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.secondaryTrackValue, 0.6);
    });

    testWidgets('缓冲进度大于播放进度时正常显示', (tester) async {
      // 正常场景：播放30%，缓冲70%
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressSlider(
              value: 0.3, // 30% 已播放
              bufferValue: 0.7, // 70% 已缓冲
              duration: 60000,
              position: 18000,
              onSeek: (_) {},
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 0.3);
      expect(slider.secondaryTrackValue, 0.7);
    });

    testWidgets('缓冲进度小于播放进度时的边界情况', (tester) async {
      // 边界情况：缓冲30%，播放70%（异常但可能发生）
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressSlider(
              value: 0.7, // 70% 已播放
              bufferValue: 0.3, // 30% 已缓冲
              duration: 60000,
              position: 42000,
              onSeek: (_) {},
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 0.7);
      expect(slider.secondaryTrackValue, 0.3);
    });

    testWidgets('缓冲进度为0时的显示状态', (tester) async {
      // 边界情况：无缓冲
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressSlider(
              value: 0.1,
              bufferValue: 0.0, // 无缓冲
              duration: 60000,
              position: 6000,
              onSeek: (_) {},
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.secondaryTrackValue, 0.0);
      expect(slider.value, 0.1);
    });

    testWidgets('缓冲进度为1.0时完全缓冲的显示状态', (tester) async {
      // 边界情况：完全缓冲
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressSlider(
              value: 0.2,
              bufferValue: 1.0, // 完全缓冲
              duration: 60000,
              position: 12000,
              onSeek: (_) {},
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.secondaryTrackValue, 1.0);
    });

    testWidgets('缓冲进度等于播放进度时', (tester) async {
      // 边界情况：缓冲等于播放（实时播放）
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressSlider(
              value: 0.5,
              bufferValue: 0.5,
              duration: 60000,
              position: 30000,
              onSeek: (_) {},
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 0.5);
      expect(slider.secondaryTrackValue, 0.5);
    });

    testWidgets('缓冲进度值被clamp到0.0-1.0范围', (tester) async {
      // 测试超出范围的值被正确限制
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressSlider(
              value: 0.5,
              bufferValue: 1.5, // 超出范围
              duration: 60000,
              position: 30000,
              onSeek: (_) {},
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      // ProgressSlider 中使用了 bufferValue.clamp(0.0, 1.0)
      expect(slider.secondaryTrackValue, 1.0);
    });
  });
}
