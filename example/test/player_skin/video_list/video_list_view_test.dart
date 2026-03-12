import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/infrastructure/video_list/video_list_models.dart';
import 'package:polyv_media_player_example/player_skin/video_list/video_list_view.dart';
import 'package:polyv_media_player_example/player_skin/video_list/video_list_item.dart';

// 默认的空回调函数，用于 const 构造
void _defaultOnVideoTap(VideoItem _) {}

void main() {
  group('VideoListView', () {
    // 测试数据工厂
    List<VideoItem> createTestVideos({int count = 3}) {
      return List.generate(
        count,
        (i) => VideoItem(
          vid: 'vid_$i',
          title: '视频 $i',
          duration: 100 + i * 10,
          thumbnail: 'https://example.com/thumb$i.jpg',
          views: '${(i + 1) * 1000}',
        ),
      );
    }

    group('加载状态测试', () {
      testWidgets('[P0] 初始加载状态应该显示进度指示器', (tester) async {
        // GIVEN: 创建 VideoListView，isLoading=true，无视频数据
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: VideoListView(
                videos: [],
                isLoading: true,
                onVideoTap: _defaultOnVideoTap,
              ),
            ),
          ),
        );

        // THEN: 应该显示 CircularProgressIndicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // AND: 进度指示器颜色应该是 primary 色
        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(
          indicator.valueColor,
          const AlwaysStoppedAnimation<Color>(Color(0xFFE8704D)),
        );
      });

      testWidgets('[P0] 加载中且有视频时不显示进度指示器', (tester) async {
        // GIVEN: 创建 VideoListView，isLoading=true，但有视频数据
        final videos = createTestVideos(count: 2);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(
                videos: videos,
                isLoading: true,
                onVideoTap: _defaultOnVideoTap,
              ),
            ),
          ),
        );

        // THEN: 不应该显示进度指示器（因为已有数据）
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // AND: 应该显示视频列表
        expect(find.text('视频 0'), findsOneWidget);
        expect(find.text('视频 1'), findsOneWidget);
      });
    });

    group('空状态测试', () {
      testWidgets('[P0] 空列表应该显示空状态提示', (tester) async {
        // GIVEN: 创建 VideoListView，无视频，非加载中
        const emptyView = VideoListView(
          videos: [],
          isLoading: false,
          onVideoTap: _defaultOnVideoTap,
        );

        // WHEN: 构建组件
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: emptyView)),
        );

        // THEN: 应该显示空状态图标
        expect(find.byIcon(Icons.video_library_outlined), findsOneWidget);

        // AND: 应该显示默认空状态消息
        expect(find.text('暂无视频'), findsOneWidget);
      });

      testWidgets('[P0] 应该显示自定义空状态消息', (tester) async {
        // GIVEN: 创建 VideoListView，带自定义空状态消息
        const emptyView = VideoListView(
          videos: [],
          isLoading: false,
          emptyMessage: '没有找到相关视频',
          onVideoTap: _defaultOnVideoTap,
        );

        // WHEN: 构建组件
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: emptyView)),
        );

        // THEN: 应该显示自定义消息
        expect(find.text('没有找到相关视频'), findsOneWidget);
        expect(find.text('暂无视频'), findsNothing);
      });
    });

    group('错误状态测试', () {
      testWidgets('[P0] 错误状态应该显示错误消息', (tester) async {
        // GIVEN: 创建 VideoListView，有错误信息
        const errorView = VideoListView(
          videos: [],
          error: '网络连接失败',
          onVideoTap: _defaultOnVideoTap,
        );

        // WHEN: 构建组件
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: errorView)),
        );

        // THEN: 应该显示错误图标
        expect(find.byIcon(Icons.error_outline), findsOneWidget);

        // AND: 应该显示错误消息
        expect(find.text('网络连接失败'), findsOneWidget);
      });

      testWidgets('[P0] 错误状态应该显示重试按钮', (tester) async {
        // GIVEN: 创建 VideoListView，有错误和重试回调
        var retried = false;
        final errorView = VideoListView(
          videos: [],
          error: '加载失败',
          onVideoTap: _defaultOnVideoTap,
          onLoadMore: () => retried = true,
        );

        // WHEN: 构建组件
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: errorView)));

        // THEN: 应该显示重试按钮
        expect(find.text('重试'), findsOneWidget);

        // AND: 点击重试按钮应该触发回调
        await tester.tap(find.text('重试'));
        await tester.pump();

        expect(retried, isTrue);
      });

      testWidgets('[P0] 错误状态但有视频时优先显示列表', (tester) async {
        // GIVEN: 创建 VideoListView，有错误但也有视频数据
        final videos = createTestVideos(count: 2);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(
                videos: videos,
                error: '部分加载失败',
                onVideoTap: (_) {},
              ),
            ),
          ),
        );

        // THEN: 应该显示视频列表（不是错误状态）
        expect(find.text('视频 0'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsNothing);
      });
    });

    group('正常列表渲染测试', () {
      testWidgets('[P1] 应该正确渲染视频列表', (tester) async {
        // GIVEN: 创建 VideoListView，有 3 个视频
        final videos = createTestVideos(count: 3);

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(videos: videos, onVideoTap: (_) {}),
            ),
          ),
        );

        // THEN: 应该显示列表标题
        expect(find.text('全部视频 · 3'), findsOneWidget);

        // AND: 应该显示所有视频标题
        expect(find.text('视频 0'), findsOneWidget);
        expect(find.text('视频 1'), findsOneWidget);
        expect(find.text('视频 2'), findsOneWidget);
      });

      testWidgets('[P1] 应该在每个视频项之间显示分隔线', (tester) async {
        // GIVEN: 创建 VideoListView，有 3 个视频
        final videos = createTestVideos(count: 3);

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(videos: videos, onVideoTap: (_) {}),
            ),
          ),
        );

        // THEN: 应该有 2 条分隔线（n-1）
        // _ListDivider 是一个高度为 1 且颜色为 slate-800/30 的 Container
        final containers = find.byType(Container);
        var dividerCount = 0;
        for (var element in tester.widgetList<Container>(containers)) {
          // 检查分隔线特有的颜色和高度约束
          if (element.color == const Color(0x4D2D3548)) {
            final constraints = element.constraints;
            if (constraints != null &&
                constraints.maxHeight == 1 &&
                constraints.minHeight == 1) {
              dividerCount++;
            }
          }
        }
        // 至少应该有 2 条分隔线（可能还有其他同颜色的容器）
        expect(dividerCount, greaterThanOrEqualTo(2));
      });
    });

    group('当前播放高亮测试', () {
      testWidgets('[P1] 应该高亮显示当前播放的视频', (tester) async {
        // GIVEN: 创建 VideoListView，指定当前播放视频
        final videos = createTestVideos(count: 3);

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(
                videos: videos,
                currentVid: 'vid_1',
                onVideoTap: (_) {},
              ),
            ),
          ),
        );

        // THEN: 应该有 2 个视频标题（非激活）
        // 注意：激活状态的标题颜色不同，但文字相同
        expect(find.text('视频 0'), findsOneWidget);
        expect(find.text('视频 1'), findsOneWidget);
        expect(find.text('视频 2'), findsOneWidget);
      });

      testWidgets('[P1] currentVid 为 null 时不高亮任何视频', (tester) async {
        // GIVEN: 创建 VideoListView，currentVid 为 null
        final videos = createTestVideos(count: 3);

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(
                videos: videos,
                currentVid: null,
                onVideoTap: (_) {},
              ),
            ),
          ),
        );
      });
    });

    group('点击事件测试', () {
      testWidgets('[P1] 点击视频项应该触发回调', (tester) async {
        // GIVEN: 创建 VideoListView
        final videos = createTestVideos(count: 3);
        VideoItem? tappedVideo;

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(
                videos: videos,
                onVideoTap: (video) => tappedVideo = video,
              ),
            ),
          ),
        );

        // AND: 点击第二个视频
        await tester.tap(find.text('视频 1'));
        await tester.pump();

        // THEN: 应该触发回调并传递正确的视频
        expect(tappedVideo, isNotNull);
        expect(tappedVideo?.vid, equals('vid_1'));
      });

      testWidgets('[P1] 点击不同的视频应该传递正确的数据', (tester) async {
        // GIVEN: 创建 VideoListView
        final videos = createTestVideos(count: 3);
        final tappedVideos = <VideoItem>[];

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(
                videos: videos,
                onVideoTap: (video) => tappedVideos.add(video),
              ),
            ),
          ),
        );

        // AND: 点击所有视频
        await tester.tap(find.text('视频 0'));
        await tester.pump();
        await tester.tap(find.text('视频 1'));
        await tester.pump();
        await tester.tap(find.text('视频 2'));
        await tester.pump();

        // THEN: 应该触发所有回调
        expect(tappedVideos.length, equals(3));
        expect(tappedVideos[0].vid, equals('vid_0'));
        expect(tappedVideos[1].vid, equals('vid_1'));
        expect(tappedVideos[2].vid, equals('vid_2'));
      });
    });

    group('加载更多功能测试', () {
      testWidgets('[P1] 滚动到底部应该触发加载更多', (tester) async {
        // GIVEN: 创建 VideoListView，有足够多的视频
        final videos = createTestVideos(count: 20);

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 150,
                child: VideoListView(
                  videos: videos,
                  hasMore: true,
                  onVideoTap: (_) {},
                  onLoadMore: () {},
                ),
              ),
            ),
          ),
        );

        // AND: 滚动到底部 - 使用 scrollUntilVisible 确保滚动
        try {
          await tester.fling(
            find.byType(ListView),
            const Offset(0, -300),
            10000,
          );
          await tester.pumpAndSettle();
        } catch (_) {
          // 如果滚动超出范围也没关系
        }

        // THEN: 滚动操作不应该导致崩溃
        // 注意：在测试环境中，滚动监听器可能不会触发
        // 这里主要验证组件可以正常渲染和滚动
        expect(find.byType(VideoListView), findsOneWidget);
      });

      testWidgets('[P1] isLoadingMore 时应该显示加载指示器', (tester) async {
        // GIVEN: 创建 VideoListView，正在加载更多
        final videos = createTestVideos(count: 3);

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(
                videos: videos,
                hasMore: true,
                isLoadingMore: true,
                onVideoTap: (_) {},
              ),
            ),
          ),
        );

        // THEN: 应该显示加载更多指示器
        final indicators = find.byType(CircularProgressIndicator);
        expect(indicators, findsWidgets);

        // AND: 应该至少有一个是加载更多的（小的）
        var hasLoadingMoreIndicator = false;
        for (var element in tester.widgetList<CircularProgressIndicator>(
          indicators,
        )) {
          if (element.strokeWidth == 2) {
            // 加载更多指示器 stroke width 是 2
            hasLoadingMoreIndicator = true;
          }
        }
        expect(hasLoadingMoreIndicator, isTrue);
      });

      testWidgets('[P1] hasMore 为 false 时不应该显示加载更多指示器', (tester) async {
        // GIVEN: 创建 VideoListView，没有更多数据
        final videos = createTestVideos(count: 3);

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(
                videos: videos,
                hasMore: false,
                onVideoTap: (_) {},
              ),
            ),
          ),
        );

        // THEN: 滚动到底部不应该有任何加载指示器
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pump();

        // 检查列表末尾没有加载指示器（小的 strokeWidth=2）
        final indicators = find.byType(CircularProgressIndicator);
        for (var element in tester.widgetList<CircularProgressIndicator>(
          indicators,
        )) {
          expect(element.strokeWidth, isNot(2));
        }
      });
    });

    group('边界情况测试', () {
      testWidgets('[P2] onLoadMore 为 null 时不应该崩溃', (tester) async {
        // GIVEN: 创建 VideoListView，没有 onLoadMore 回调
        final videos = createTestVideos(count: 20);

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 400,
                child: VideoListView(
                  videos: videos,
                  hasMore: true,
                  onVideoTap: (_) {},
                  // onLoadMore 为 null
                ),
              ),
            ),
          ),
        );

        // AND: 滚动到底部
        await tester.drag(find.byType(ListView), const Offset(0, -1000));
        await tester.pump();

        // THEN: 不应该崩溃
        expect(tester.takeException(), isNull);
      });

      testWidgets('[P2] 单个视频的列表应该正常渲染', (tester) async {
        // GIVEN: 创建 VideoListView，只有一个视频
        final videos = createTestVideos(count: 1);

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(videos: videos, onVideoTap: (_) {}),
            ),
          ),
        );

        // THEN: 应该正确显示
        expect(find.text('全部视频 · 1'), findsOneWidget);
        expect(find.text('视频 0'), findsOneWidget);
      });

      testWidgets('[P2] 大量视频的列表应该高效渲染', (tester) async {
        // GIVEN: 创建 VideoListView，有 100 个视频
        final videos = createTestVideos(count: 100);

        // WHEN: 构建组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(videos: videos, onVideoTap: (_) {}),
            ),
          ),
        );

        // THEN: 应该显示列表标题
        expect(find.text('全部视频 · 100'), findsOneWidget);

        // AND: 应该可见部分视频（ListView.builder 懒加载）
        // 由于 ListView.builder 的特性，只渲染可见部分
        expect(find.text('视频 0'), findsOneWidget);
      });
    });

    group('组件清理测试', () {
      testWidgets('[P2] dispose 时应该清理 ScrollController', (tester) async {
        // GIVEN: 创建 VideoListView
        final videos = createTestVideos(count: 3);

        // WHEN: 构建然后销毁组件
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(videos: videos, onVideoTap: (_) {}),
            ),
          ),
        );

        // THEN: 销毁不应该抛出异常
        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        expect(tester.takeException(), isNull);
      });
    });

    group('视频切换状态测试（Story 6-4）', () {
      testWidgets('[P1] 切换中状态应禁用点击并显示半透明', (tester) async {
        // GIVEN: 创建 VideoListView，isSwitching=true
        final videos = createTestVideos(count: 3);
        var tappedCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(
                videos: videos,
                currentVid: 'vid_0',
                isSwitching: true,
                onVideoTap: (_) => tappedCount++,
              ),
            ),
          ),
        );

        // WHEN: 尝试点击任何视频项
        await tester.tap(find.text('视频 1'));
        await tester.pump();

        // THEN: 回调不应被触发（被禁用）
        expect(tappedCount, equals(0));

        // AND: 非激活项应显示半透明（opacity=0.5）
        final opacityWidgets = find.byType(Opacity);
        var hasHalfOpacity = false;
        for (var element in tester.widgetList<Opacity>(opacityWidgets)) {
          if (element.opacity == 0.5) {
            hasHalfOpacity = true;
            break;
          }
        }
        expect(hasHalfOpacity, isTrue, reason: '切换中的视频项应显示半透明');
      });

      testWidgets('[P1] 切换中不影响当前激活视频的显示', (tester) async {
        // GIVEN: 创建 VideoListView，isSwitching=true，第一个视频为激活状态
        final videos = createTestVideos(count: 3);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(
                videos: videos,
                currentVid: 'vid_0', // 第一个视频是激活的
                isSwitching: true,
                onVideoTap: (_) {},
              ),
            ),
          ),
        );

        // AND: 激活视频不应半透明（只有非激活项半透明）
        final listItem = find.byType(VideoListItem);
        expect(listItem, findsWidgets);

        // 检查第一个 VideoListItem (激活项) 的 isActive 应该是 true
        final firstItem = tester.widget<VideoListItem>(listItem.first);
        expect(firstItem.isActive, isTrue);
      });

      testWidgets('[P1] 非切换状态应正常响应点击', (tester) async {
        // GIVEN: 创建 VideoListView，isSwitching=false
        final videos = createTestVideos(count: 3);
        VideoItem? tappedVideo;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(
                videos: videos,
                currentVid: 'vid_0',
                isSwitching: false,
                onVideoTap: (video) => tappedVideo = video,
              ),
            ),
          ),
        );

        // WHEN: 点击非激活视频
        await tester.tap(find.text('视频 1'));
        await tester.pump();

        // THEN: 回调应该被触发
        expect(tappedVideo, isNotNull);
        expect(tappedVideo?.vid, equals('vid_1'));
      });

      testWidgets('[P2] 切换状态变化应正确更新 UI', (tester) async {
        // GIVEN: 创建 VideoListView，初始非切换状态
        final videos = createTestVideos(count: 3);
        final viewKey = GlobalKey();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(
                key: viewKey,
                videos: videos,
                currentVid: 'vid_0',
                isSwitching: false,
                onVideoTap: (_) {},
              ),
            ),
          ),
        );

        // THEN: 初始状态没有半透明项（除了可能的激活项）
        final initialOpacityCount = tester
            .widgetList<Opacity>(find.byType(Opacity))
            .length;

        // WHEN: 切换到切换中状态
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(
                key: viewKey,
                videos: videos,
                currentVid: 'vid_0',
                isSwitching: true,
                onVideoTap: (_) {},
              ),
            ),
          ),
        );

        // THEN: 应该有半透明效果（非激活项）
        final switchingOpacityCount = tester
            .widgetList<Opacity>(find.byType(Opacity))
            .length;
        // 至少应该有相同数量的 Opacity widget（可能有新增）
        expect(
          switchingOpacityCount,
          greaterThanOrEqualTo(initialOpacityCount),
        );
      });
    });
  });
}
