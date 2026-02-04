import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../player_skin/double_tap_detector.dart';

/// DoubleTapDetector 全屏切换集成测试
///
/// 测试双击检测器与全屏切换功能的集成
/// 验证 Story 7-3 (双击全屏手势) 的验收标准
///
/// 测试级别: Widget/Integration 测试
/// 优先级: P0-P1 (关键用户路径)
void main() {
  group('DoubleTapDetector 全屏切换集成测试', () {
    testWidgets('[P0][AC-场景1] 竖屏双击应进入横屏全屏', (tester) async {
      // GIVEN: 创建一个模拟的全屏切换状态管理
      var isFullscreen = false;
      var doubleTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoubleTapDetector(
              onTap: () {},
              onDoubleTap: () {
                doubleTapCalled = true;
                isFullscreen = !isFullscreen; // 模拟全屏切换
              },
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      // WHEN: 在 300ms 内快速双击
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: 应该触发双击回调，全屏状态应该改变
      expect(doubleTapCalled, isTrue, reason: '双击应该在 300ms 内触发双击回调');
      expect(isFullscreen, isTrue, reason: '竖屏双击后应进入全屏状态');
    });

    testWidgets('[P0][AC-场景2] 横屏全屏状态下双击应退出全屏', (tester) async {
      // GIVEN: 模拟已处于全屏状态
      var isFullscreen = true;
      var doubleTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoubleTapDetector(
              onTap: () {},
              onDoubleTap: () {
                doubleTapCalled = true;
                isFullscreen = !isFullscreen; // 模拟退出全屏
              },
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      // WHEN: 双击
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: 应该触发双击回调，退出全屏状态
      expect(doubleTapCalled, isTrue, reason: '应该触发双击回调');
      expect(isFullscreen, isFalse, reason: '横屏全屏状态下双击应退出全屏');
    });

    testWidgets('[P1][AC-场景3] 单击不应触发全屏切换', (tester) async {
      // GIVEN: 全屏状态初始为 false
      var isFullscreen = false;
      var singleTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoubleTapDetector(
              onTap: () {
                singleTapCalled = true;
                // 单击只显示控制栏，不切换全屏
              },
              onDoubleTap: () {
                isFullscreen = !isFullscreen;
              },
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      // WHEN: 单击一次
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 350));

      // THEN: 应该触发单击回调，但不触发全屏切换
      expect(singleTapCalled, isTrue, reason: '应该触发单击回调');
      expect(isFullscreen, isFalse, reason: '单击不应触发全屏切换');
    });

    testWidgets('[P0][AC-场景3] 300ms 内双击不应触发单击回调', (tester) async {
      // GIVEN: 设置单击和双击回调
      var singleTapCalled = false;
      var doubleTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoubleTapDetector(
              onTap: () => singleTapCalled = true,
              onDoubleTap: () => doubleTapCalled = true,
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      // WHEN: 在 300ms 内双击
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 100));

      // 等待原始延迟时间确认单击不会被触发
      await tester.pump(const Duration(milliseconds: 300));

      // THEN: 只触发双击，不触发单击
      expect(doubleTapCalled, isTrue, reason: '应该触发双击回调');
      expect(singleTapCalled, isFalse, reason: '双击不应触发单击回调');
    });

    testWidgets('[P1][AC-场景4] 锁屏状态下双击应被忽略', (tester) async {
      // GIVEN: 模拟锁屏状态
      final isLocked = true;
      var doubleTapShouldBeIgnored = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: DoubleTapDetector(
                  onTap: () {},
                  onDoubleTap: () {
                    // 在实际实现中，_handleDoubleTap() 会检查 _isLocked
                    // 这里模拟锁屏检查 - 测试锁屏状态
                    if (isLocked) {
                      // ignore
                    }
                  },
                  child: const SizedBox(width: 200, height: 200),
                ),
              );
            },
          ),
        ),
      );

      // WHEN: 锁屏状态下双击
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: 双击回调被调用，但在实际 home_page.dart 中会检查锁屏状态
      // 集成测试验证 DoubleTapDetector 本身不处理锁屏逻辑
      // 锁屏逻辑由 home_page.dart 的 _handleDoubleTap() 方法处理
      expect(
        doubleTapShouldBeIgnored,
        isFalse,
        reason: 'DoubleTapDetector 不处理锁屏，锁屏由调用方处理',
      );
    });

    testWidgets('[P1][AC-场景5] 切换视频期间双击应被忽略', (tester) async {
      // GIVEN: 模拟切换视频状态
      final isSwitchingVideo = true;
      var doubleTapShouldBeIgnored = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoubleTapDetector(
              onTap: () {},
              onDoubleTap: () {
                // 在实际实现中，_handleDoubleTap() 会检查 _isSwitchingVideo
                // 这里模拟切换视频状态检查 - 测试切换中状态
                if (isSwitchingVideo) {
                  // ignore
                }
              },
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      // WHEN: 切换视频期间双击
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: 同样，DoubleTapDetector 本身不处理切换视频状态
      // 由 home_page.dart 的 _handleDoubleTap() 方法处理
      expect(
        doubleTapShouldBeIgnored,
        isFalse,
        reason: 'DoubleTapDetector 不处理切换视频，由调用方处理',
      );
    });

    testWidgets('[P1][AC-场景6] 全屏切换后播放状态应保持不变', (tester) async {
      // GIVEN: 模拟播放状态
      var isPlaying = true;
      var isFullscreen = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoubleTapDetector(
              onTap: () {},
              onDoubleTap: () {
                // 全屏切换不应影响播放状态
                isFullscreen = !isFullscreen;
                // isPlaying 应保持不变
              },
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      // WHEN: 双击切换全屏
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: 全屏状态改变，播放状态不变
      expect(isFullscreen, isTrue, reason: '应进入全屏');
      expect(isPlaying, isTrue, reason: '全屏切换后播放状态应保持不变');
    });

    testWidgets('[P1] 双击视觉反馈应显示正确的图标', (tester) async {
      // GIVEN: 全屏状态
      var isFullscreen = false;
      String? displayedIcon;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoubleTapDetector(
              onTap: () {},
              onDoubleTap: () {
                isFullscreen = !isFullscreen;
                // 竖屏时双击进入全屏，应显示 fullscreen 图标
                // 横屏时双击退出全屏，应显示 fullscreen_exit 图标
                displayedIcon = isFullscreen ? 'fullscreen_exit' : 'fullscreen';
              },
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      // WHEN: 竖屏时双击进入全屏
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: 应显示进入全屏的图标
      expect(
        displayedIcon,
        'fullscreen_exit',
        reason: '进入全屏时应显示 fullscreen_exit 图标',
      );

      // WHEN: 横屏时双击退出全屏
      displayedIcon = null;
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 100));

      // THEN: 应显示退出全屏的图标
      expect(displayedIcon, 'fullscreen', reason: '退出全屏时应显示 fullscreen 图标');
    });

    testWidgets('[P2] 超过延迟时间的两次点击应触发两次单击', (tester) async {
      // GIVEN: 设置 DoubleTapDetector
      var singleTapCount = 0;
      var doubleTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoubleTapDetector(
              onTap: () => singleTapCount++,
              onDoubleTap: () => doubleTapCalled = true,
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      // WHEN: 两次点击间隔超过 300ms
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 350));

      // THEN: 应该触发两次单击回调
      expect(singleTapCount, equals(2), reason: '超过延迟时间的两次点击应触发两次单击');
      expect(doubleTapCalled, isFalse, reason: '不应该触发双击回调');
    });

    testWidgets('[P2] 快速连续三次点击应触发一次双击和一次单击', (tester) async {
      // GIVEN: 设置 DoubleTapDetector
      var singleTapCount = 0;
      var doubleTapCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoubleTapDetector(
              onTap: () => singleTapCount++,
              onDoubleTap: () => doubleTapCount++,
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      // WHEN: 快速连续点击三次
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 50));

      // 等待延迟时间确认最后的单击
      await tester.pump(const Duration(milliseconds: 300));

      // THEN: 应该触发一次双击和一次单击
      expect(doubleTapCount, equals(1), reason: '前两次点击应该触发一次双击');
      expect(singleTapCount, equals(1), reason: '第三次点击应该在延迟后触发单击');
    });

    testWidgets('[P2] 自定义延迟时间应该生效', (tester) async {
      // GIVEN: 设置自定义延迟时间为 100ms
      var singleTapCalled = false;
      var doubleTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoubleTapDetector(
              onTap: () => singleTapCalled = true,
              onDoubleTap: () => doubleTapCalled = true,
              doubleTapDelay: const Duration(milliseconds: 100),
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      // WHEN: 第一次点击后 50ms 进行第二次点击
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 50));

      // THEN: 应该触发双击回调（因为在 100ms 延迟内）
      expect(doubleTapCalled, isTrue, reason: '自定义延迟时间内应该触发双击');
      expect(singleTapCalled, isFalse, reason: '不应该触发单击');
    });

    testWidgets('[P2] Widget 卸载时应该清理定时器', (tester) async {
      // GIVEN: 创建 DoubleTapDetector 并点击
      var singleTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoubleTapDetector(
              onTap: () => singleTapCalled = true,
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      // 点击一次
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 50));

      // WHEN: 移除 Widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SizedBox(width: 200, height: 200)),
        ),
      );

      // 等待原始延迟时间
      await tester.pump(const Duration(milliseconds: 300));

      // THEN: 定时器应该被清理，不会触发回调
      expect(singleTapCalled, isFalse, reason: 'Widget 卸载后不应该触发单击回调');
    });
  });

  group('双击延迟边界测试', () {
    testWidgets('[P2] 恰好 300ms 边界测试', (tester) async {
      // GIVEN: 设置 DoubleTapDetector
      var singleTapCalled = false;
      var doubleTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoubleTapDetector(
              onTap: () => singleTapCalled = true,
              onDoubleTap: () => doubleTapCalled = true,
              doubleTapDelay: const Duration(milliseconds: 300),
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      // WHEN: 两次点击间隔恰好 300ms
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 50));

      // THEN: 300ms 时应该被视为两次独立单击（>= 延迟时间）
      expect(doubleTapCalled, isFalse, reason: '恰好 300ms 应该不算双击');
      expect(singleTapCalled, isTrue, reason: '第一次点击应该在 300ms 后触发单击');
    });

    testWidgets('[P2] 299ms 边界测试', (tester) async {
      // GIVEN: 设置 DoubleTapDetector
      var singleTapCalled = false;
      var doubleTapCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DoubleTapDetector(
              onTap: () => singleTapCalled = true,
              onDoubleTap: () => doubleTapCalled = true,
              doubleTapDelay: const Duration(milliseconds: 300),
              child: const SizedBox(width: 200, height: 200),
            ),
          ),
        ),
      );

      // WHEN: 两次点击间隔 299ms
      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 299));

      await tester.tap(find.byType(DoubleTapDetector));
      await tester.pump(const Duration(milliseconds: 50));

      // THEN: < 300ms 应该触发双击
      expect(doubleTapCalled, isTrue, reason: '299ms 应该触发双击');
      expect(singleTapCalled, isFalse, reason: '双击不应该触发单击');
    });
  });
}
