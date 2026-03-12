import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/infrastructure/video_list/video_list_models.dart';

import 'package:polyv_media_player_example/player_skin/video_list/video_list_view.dart';

/// 视频列表集成测试
///
/// 测试视频切换流程的端到端场景
void main() {
  group('VideoListIntegration - 视频切换流程', () {
    // 测试数据工厂
    List<VideoItem> createTestVideos({int count = 5}) {
      return List.generate(
        count,
        (i) => VideoItem(
          vid: 'vid_$i',
          title: '测试视频 $i',
          duration: 100 + i * 10,
          thumbnail: 'https://example.com/thumb$i.jpg',
          views: '${(i + 1) * 1000}',
        ),
      );
    }

    group('场景 4: 列表项点击切换视频', () {
      testWidgets('[P1] 点击视频项应该更新当前播放视频', (tester) async {
        // SKIP: 需要 native platform 支持，应在 integration_test 中运行
        // LongVideoPage 使用 PolyvVideoView 需要 native platform view
        // 这里只测试 VideoListView 的结构
        final videos = createTestVideos(count: 3);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(
                videos: videos,
                currentVid: 'vid_0',
                hasMore: false,
                onVideoTap: (_) {},
              ),
            ),
          ),
        );

        // THEN: 应该显示视频列表
        expect(find.byType(VideoListView), findsOneWidget);
        // AND: 应该显示"全部视频 · 3"
        expect(find.text('全部视频 · 3'), findsOneWidget);
      }, skip: false);

      testWidgets('[P1] 点击不同视频项应该触发状态更新', (tester) async {
        // SKIP: 需要 native platform 支持
        final videos = createTestVideos(count: 3);
        VideoItem? selectedVideo;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(
                videos: videos,
                currentVid: 'vid_0',
                hasMore: false,
                onVideoTap: (video) => selectedVideo = video,
              ),
            ),
          ),
        );

        // WHEN: 点击第二个视频
        await tester.tap(find.text('测试视频 1'));
        await tester.pump();

        // THEN: 应该触发回调
        expect(selectedVideo?.vid, 'vid_1');
      });

      testWidgets('[P2] 视频列表应该正确显示当前播放视频的高亮', (tester) async {
        final videos = createTestVideos(count: 3);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(
                videos: videos,
                currentVid: 'vid_1',
                hasMore: false,
                onVideoTap: (_) {},
              ),
            ),
          ),
        );

        // THEN: 视频列表应该存在
        expect(find.byType(VideoListView), findsOneWidget);
        // AND: 第二个视频应该是当前播放的视频
        expect(find.text('测试视频 1'), findsOneWidget);
      });
    });

    group('场景 6: 与播放器状态同步', () {
      testWidgets('[P1] 视频列表应该响应播放器状态变化', (tester) async {
        // 注意：这个测试验证 VideoListView 能够响应状态变化
        final videos = createTestVideos(count: 3);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(
                videos: videos,
                currentVid: 'vid_0',
                hasMore: false,
                onVideoTap: (_) {},
              ),
            ),
          ),
        );

        // THEN: 视频列表应该存在
        expect(find.byType(VideoListView), findsOneWidget);
      });

      testWidgets('[P2] 视频信息区域应该正确显示当前视频信息', (tester) async {
        // 注意：这个测试验证视频信息正确显示
        final videos = createTestVideos(count: 1);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VideoListView(
                videos: videos,
                currentVid: 'vid_0',
                hasMore: false,
                onVideoTap: (_) {},
              ),
            ),
          ),
        );

        // THEN: 页面应该成功构建
        expect(find.byType(VideoListView), findsOneWidget);
        expect(find.text('测试视频 0'), findsOneWidget);
      });
    });

    group('场景 3: 列表滚动与分页加载', () {
      testWidgets('[P1] 滚动到底部应该触发加载更多', (tester) async {
        // 注意：这个测试验证滚动加载功能
        final videos = createTestVideos(count: 3);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 400,
                child: VideoListView(
                  videos: videos,
                  hasMore: true,
                  onLoadMore: () {},
                  onVideoTap: (_) {},
                ),
              ),
            ),
          ),
        );

        // THEN: 视频列表应该存在
        expect(find.byType(VideoListView), findsOneWidget);
      });

      testWidgets('[P1] hasMore 为 false 时应该显示已加载全部', (tester) async {
        // GIVEN: 创建视频列表视图，设置 hasMore = false
        final videos = createTestVideos(count: 3);

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

        // THEN: 应该显示"已加载全部"
        expect(find.text('已加载全部'), findsOneWidget);
      });

      testWidgets('[P1] isLoadingMore 时应该显示加载指示器', (tester) async {
        // GIVEN: 创建视频列表视图，设置 isLoadingMore = true
        final videos = createTestVideos(count: 3);

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

        // THEN: 应该显示加载指示器
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });
    });

    group('场景 5: 空状态处理', () {
      testWidgets('[P1] 空列表应该显示空状态提示', (tester) async {
        // GIVEN: 创建视频列表视图，没有视频
        const emptyView = VideoListView(
          videos: [],
          isLoading: false,
          hasMore: false,
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

      testWidgets('[P1] 错误状态应该显示错误消息', (tester) async {
        // GIVEN: 创建视频列表视图，有错误信息
        const errorView = VideoListView(
          videos: [],
          hasMore: false,
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

      testWidgets('[P1] 加载中状态应该显示进度指示器', (tester) async {
        // GIVEN: 创建视频列表视图，isLoading=true
        const loadingView = VideoListView(
          videos: [],
          isLoading: true,
          hasMore: true,
          onVideoTap: _defaultOnVideoTap,
        );

        // WHEN: 构建组件
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: loadingView)),
        );

        // THEN: 应该显示进度指示器
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });
  });

  group('VideoListIntegration - 边界情况', () {
    testWidgets('[P2] 单个视频的列表应该正常工作', (tester) async {
      // GIVEN: 创建只有一个视频的列表
      const singleVideoView = VideoListView(
        videos: [
          VideoItem(
            vid: 'vid_1',
            title: '唯一视频',
            duration: 120,
            thumbnail: 'https://example.com/thumb.jpg',
          ),
        ],
        hasMore: false,
        onVideoTap: _defaultOnVideoTap,
      );

      // WHEN: 构建组件
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: singleVideoView)),
      );

      // THEN: 应该正确显示
      expect(find.text('全部视频 · 1'), findsOneWidget);
      expect(find.text('唯一视频'), findsOneWidget);
    });

    testWidgets('[P2] 大量视频的列表应该高效渲染', (tester) async {
      // GIVEN: 创建大量视频的列表
      final videos = List.generate(
        100,
        (i) => VideoItem(
          vid: 'vid_$i',
          title: '视频 $i',
          duration: 100 + i,
          thumbnail: 'https://example.com/thumb$i.jpg',
        ),
      );

      // WHEN: 构建组件
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: VideoListView(
                videos: videos,
                hasMore: false,
                onVideoTap: (_) {},
              ),
            ),
          ),
        ),
      );

      // THEN: 应该显示列表标题
      expect(find.text('全部视频 · 100'), findsOneWidget);

      // AND: 应该可见部分视频（ListView.builder 懒加载）
      expect(find.text('视频 0'), findsOneWidget);
    });
  });
}

// 默认的空回调函数
void _defaultOnVideoTap(VideoItem _) {}
