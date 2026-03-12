import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/infrastructure/video_list/video_list_models.dart';
import 'package:polyv_media_player_example/player_skin/video_list/video_list_item.dart';

void main() {
  group('VideoListItem', () {
    // 测试数据工厂
    VideoItem createTestVideo({
      String? vid,
      String? title,
      int? duration,
      String? thumbnail,
      String? views,
    }) {
      return VideoItem(
        vid: vid ?? 'test_vid_001',
        title: title ?? '测试视频标题',
        duration: duration ?? 125, // 2:05
        thumbnail: thumbnail ?? 'https://example.com/thumb.jpg',
        views: views ?? '1.2万',
      );
    }

    group('非激活状态渲染测试', () {
      testWidgets('[P1] 应该正确渲染非激活状态的视频项', (tester) async {
        // GIVEN: 创建非激活的视频项
        final video = createTestVideo();

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListItem(video: video, isActive: false, onTap: () {}),
            ),
          ),
        );

        // THEN: 组件应该渲染
        expect(find.byType(VideoListItem), findsOneWidget);

        // AND: 应该显示视频标题
        expect(find.text('测试视频标题'), findsOneWidget);

        // AND: 应该显示播放次数
        expect(find.text('1.2万次播放'), findsOneWidget);

        // AND: 应该显示时长
        expect(find.text('02:05'), findsOneWidget);
      });

      testWidgets('[P1] 非激活状态时标题应为白色', (tester) async {
        // GIVEN: 创建非激活的视频项
        final video = createTestVideo();

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListItem(video: video, isActive: false, onTap: () {}),
            ),
          ),
        );

        // THEN: 标题颜色应该是白色
        final titleWidget = tester.widget<Text>(find.text('测试视频标题'));
        expect(titleWidget.style?.color, equals(Colors.white));
      });

      testWidgets('[P2] 非激活状态时不应显示播放指示器', (tester) async {
        // GIVEN: 创建非激活的视频项
        final video = createTestVideo();

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListItem(video: video, isActive: false, onTap: () {}),
            ),
          ),
        );

        // THEN: 不应该找到播放指示器 (DecoratedBox with circle shape)
        final decoratedBoxes = find.byType(DecoratedBox);
        expect(decoratedBoxes, findsWidgets);

        // 验证没有圆形的播放指示器
        for (var element in tester.widgetList<DecoratedBox>(decoratedBoxes)) {
          final decoration = element.decoration as BoxDecoration;
          if (decoration.shape == BoxShape.circle) {
            fail('不应该找到圆形播放指示器');
          }
        }
      });
    });

    group('激活状态渲染测试', () {
      testWidgets('[P1] 应该正确渲染激活状态的视频项', (tester) async {
        // GIVEN: 创建激活的视频项
        final video = createTestVideo();

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListItem(video: video, isActive: true, onTap: () {}),
            ),
          ),
        );

        // THEN: 组件应该渲染
        expect(find.byType(VideoListItem), findsOneWidget);

        // AND: 应该显示视频标题
        expect(find.text('测试视频标题'), findsOneWidget);
      });

      testWidgets('[P1] 激活状态时标题应为 primary 色', (tester) async {
        // GIVEN: 创建激活的视频项
        final video = createTestVideo();

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListItem(video: video, isActive: true, onTap: () {}),
            ),
          ),
        );

        // THEN: 标题颜色应该是 primary 色 (#FFE8704D)
        final titleWidget = tester.widget<Text>(find.text('测试视频标题'));
        expect(titleWidget.style?.color, const Color(0xFFE8704D));
      });

      testWidgets('[P1] 激活状态时不应显示播放指示器', (tester) async {
        // GIVEN: 创建激活的视频项
        final video = createTestVideo();

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListItem(video: video, isActive: true, onTap: () {}),
            ),
          ),
        );

        // THEN: 不应该找到播放图标
        expect(find.byIcon(Icons.play_arrow), findsNothing);
      });

      testWidgets('[P2] 激活状态时通过背景色区分', (tester) async {
        // GIVEN: 创建激活的视频项
        final video = createTestVideo();

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListItem(video: video, isActive: true, onTap: () {}),
            ),
          ),
        );

        // THEN: Container 应该有背景色
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(VideoListItem),
            matching: find.byType(Container).first,
          ),
        );

        final decoration = container.decoration as BoxDecoration;
        // primaryContainer 是 primary.withValues(alpha: 0.1)
        // alpha 值是 0-255 范围，0.1 ≈ 25.5
        expect(decoration.color, isNotNull);
        final color = decoration.color!;
        expect((color.r * 255.0).round() & 0xff, 232);
        expect((color.g * 255.0).round() & 0xff, 112);
        expect((color.b * 255.0).round() & 0xff, 77);
        expect(
          (color.a * 255.0).round() & 0xff,
          closeTo(25, 1),
        ); // 0.1 * 255 ≈ 25.5
      });
    });

    group('点击事件测试', () {
      testWidgets('[P1] 点击视频项应该触发回调', (tester) async {
        // GIVEN: 创建视频项
        final video = createTestVideo();
        var tapped = false;
        VideoItem? tappedVideo;

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListItem(
                video: video,
                isActive: false,
                onTap: () {
                  tapped = true;
                  tappedVideo = video;
                },
              ),
            ),
          ),
        );

        // AND: 点击组件
        await tester.tap(find.byType(VideoListItem));
        await tester.pump();

        // THEN: 回调应该被触发
        expect(tapped, isTrue);
        expect(tappedVideo?.vid, equals('test_vid_001'));
      });

      testWidgets('[P1] 激活状态点击也应该触发回调', (tester) async {
        // GIVEN: 创建激活的视频项
        final video = createTestVideo();
        var tapped = false;

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListItem(
                video: video,
                isActive: true,
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        // AND: 点击组件
        await tester.tap(find.byType(VideoListItem));
        await tester.pump();

        // THEN: 回调应该被触发
        expect(tapped, isTrue);
      });
    });

    group('缩略图测试', () {
      testWidgets('[P1] 应该显示时长徽章', (tester) async {
        // GIVEN: 创建视频项，时长 125 秒
        final video = createTestVideo(duration: 125);

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListItem(video: video, isActive: false, onTap: () {}),
            ),
          ),
        );

        // THEN: 应该显示时长 "02:05"
        expect(find.text('02:05'), findsOneWidget);

        // AND: 时长文字应该是白色
        final durationTexts = find.text('02:05');
        for (var element in tester.widgetList<Text>(durationTexts)) {
          if (element.style?.fontSize == 10) {
            expect(element.style?.color, equals(Colors.white));
          }
        }
      });

      testWidgets('[P1] 应该正确格式化超过 1 小时的时长', (tester) async {
        // GIVEN: 创建视频项，时长 3665 秒 (1:01:05)
        final video = createTestVideo(duration: 3665);

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListItem(video: video, isActive: false, onTap: () {}),
            ),
          ),
        );

        // THEN: 应该显示时长 "01:01:05"
        expect(find.text('01:01:05'), findsOneWidget);
      });

      testWidgets('[P1] 缩略图加载失败时应显示占位图标', (tester) async {
        // GIVEN: 创建视频项，使用无效的缩略图 URL
        final video = createTestVideo(
          thumbnail: 'https://invalid.url/thumb.jpg',
        );

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListItem(video: video, isActive: false, onTap: () {}),
            ),
          ),
        );

        // THEN: 触发图片加载错误
        await tester.pumpAndSettle();

        // AND: 应该显示占位图标 (play_circle_outline)
        expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
      });
    });

    group('播放次数显示测试', () {
      testWidgets('[P1] 应该显示播放次数', (tester) async {
        // GIVEN: 创建视频项，有播放次数
        final video = createTestVideo(views: '1.2万');

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListItem(video: video, isActive: false, onTap: () {}),
            ),
          ),
        );

        // THEN: 应该显示播放次数
        expect(find.text('1.2万次播放'), findsOneWidget);
      });

      testWidgets('[P2] 播放次数为 null 时不显示', (tester) async {
        // GIVEN: 创建视频项，播放次数为 null
        final video = VideoItem(
          vid: 'test_vid',
          title: '测试视频',
          duration: 100,
          thumbnail: 'https://example.com/thumb.jpg',
          views: null,
        );

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListItem(video: video, isActive: false, onTap: () {}),
            ),
          ),
        );

        // THEN: 不应该显示播放次数
        expect(find.textContaining('次播放'), findsNothing);
      });

      testWidgets('[P2] 播放次数文字颜色应为 slate-500', (tester) async {
        // GIVEN: 创建视频项，有播放次数
        final video = createTestVideo(views: '500');

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListItem(video: video, isActive: false, onTap: () {}),
            ),
          ),
        );

        // THEN: 播放次数颜色应该是 slate-500 (#FF64748B)
        final viewsText = tester.widget<Text>(find.text('500次播放'));
        expect(viewsText.style?.color, const Color(0xFF64748B));
      });
    });

    group('视频切换状态测试（Story 6-4）', () {
      testWidgets('[P1] 切换中状态应禁用点击', (tester) async {
        // GIVEN: 创建视频项，isSwitching=true
        final video = createTestVideo();
        var tapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListItem(
                video: video,
                isActive: false,
                isSwitching: true,
                onTap: () => tapped = true,
              ),
            ),
          ),
        );

        // WHEN: 尝试点击
        await tester.tap(find.byType(VideoListItem));
        await tester.pump();

        // THEN: 回调不应被触发（onTap 为 null，InkWell 不响应）
        expect(tapped, isFalse);
      });

      testWidgets('[P1] 切换中且非激活状态应显示半透明', (tester) async {
        // GIVEN: 创建非激活视频项，isSwitching=true
        final video = createTestVideo();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListItem(
                video: video,
                isActive: false,
                isSwitching: true,
                onTap: () {},
              ),
            ),
          ),
        );

        // THEN: 应该有 Opacity widget 设置为 0.5
        final opacityWidgets = find.byType(Opacity);
        var hasHalfOpacity = false;
        for (var element in tester.widgetList<Opacity>(opacityWidgets)) {
          if (element.opacity == 0.5) {
            hasHalfOpacity = true;
            break;
          }
        }
        expect(hasHalfOpacity, isTrue, reason: '切换中且非激活状态应显示 0.5 透明度');
      });

      testWidgets('[P1] 切换中但激活状态不应半透明', (tester) async {
        // GIVEN: 创建激活视频项，isSwitching=true
        final video = createTestVideo();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListItem(
                video: video,
                isActive: true,
                isSwitching: true,
                onTap: () {},
              ),
            ),
          ),
        );

        // THEN: 不应该有 0.5 的 Opacity（激活项保持不透明）
        final opacityWidgets = find.byType(Opacity);
        for (var element in tester.widgetList<Opacity>(opacityWidgets)) {
          expect(element.opacity, isNot(0.5), reason: '激活项即使在切换中也不应半透明');
        }
      });

      testWidgets('[P2] 非切换状态应完全不透明', (tester) async {
        // GIVEN: 创建视频项，isSwitching=false
        final video = createTestVideo();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListItem(
                video: video,
                isActive: false,
                isSwitching: false,
                onTap: () {},
              ),
            ),
          ),
        );

        // THEN: 不应该有半透明效果
        final opacityWidgets = find.byType(Opacity);
        for (var element in tester.widgetList<Opacity>(opacityWidgets)) {
          expect(element.opacity, 1.0, reason: '非切换状态应该完全可见');
        }
      });
    });

    group('边界情况测试', () {
      testWidgets('[P2] 应该处理很长的视频标题', (tester) async {
        // GIVEN: 创建视频项，标题很长
        final longTitle = '这是一个非常非常非常非常非常非常非常非常非常长的视频标题，应该被截断';
        final video = createTestVideo(title: longTitle);

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListItem(video: video, isActive: false, onTap: () {}),
            ),
          ),
        );

        // THEN: 应该显示标题（被截断）
        final titleWidget = tester.widget<Text>(find.text(longTitle));
        expect(titleWidget.maxLines, equals(1));
        expect(titleWidget.overflow, equals(TextOverflow.ellipsis));
      });

      testWidgets('[P2] 应该处理零时长视频', (tester) async {
        // GIVEN: 创建视频项，时长为 0
        final video = createTestVideo(duration: 0);

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListItem(video: video, isActive: false, onTap: () {}),
            ),
          ),
        );

        // THEN: 应该显示 "00:00"
        expect(find.text('00:00'), findsOneWidget);
      });
    });
  });
}
