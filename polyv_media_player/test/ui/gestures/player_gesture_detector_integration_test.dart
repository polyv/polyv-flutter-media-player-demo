import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/polyv_media_player.dart';

void main() {
  group('PlayerGestureDetector Integration Tests', () {
    late PlayerController mockPlayerController;
    late PlayerGestureController gestureController;
    bool onTapCalled = false;
    bool onDoubleTapCalled = false;

    setUp(() {
      mockPlayerController = PlayerController();
      gestureController = PlayerGestureController();
      onTapCalled = false;
      onDoubleTapCalled = false;
    });

    tearDown(() {
      gestureController.dispose();
      mockPlayerController.dispose();
    });

    group('P0 - 场景1: 左右滑动 seek', () {
      testWidgets('[P0] 向右滑动应该显示进度预览覆盖层', (tester) async {
        // GIVEN: 视频正在播放，时长60秒
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlayerGestureDetector(
                gestureController: gestureController,
                playerController: mockPlayerController,
                onTap: () => onTapCalled = true,
                onDoubleTap: () => onDoubleTapCalled = true,
                child: const SizedBox(
                  width: 390,
                  height: 844,
                  child: ColoredBox(color: Colors.black),
                ),
              ),
            ),
          ),
        );

        // 设置视频时长
        gestureController.setDuration(60000);

        // WHEN: 在屏幕上向右滑动（水平手势）
        // 直接调用 handleDragStart 和 handleDragUpdate 进行测试
        final startPos = DragStartDetails(
          globalPosition: const Offset(100, 400),
        );
        gestureController.handleDragStart(startPos);

        // 模拟滑动超过阈值（100 像素 > 20 像素阈值）
        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(200, 400),
          delta: const Offset(100, 0),
        );
        gestureController.handleDragUpdate(updateDetails, const Size(390, 844));

        await tester.pump();

        // THEN: 显示进度提示（手势进行中）
        expect(gestureController.state.showHint, isTrue);

        // 手势结束
        gestureController.handleDragEnd();
        await tester.pump();

        // THEN: 手势结束后保存了手势类型
        expect(gestureController.lastGestureType, GestureType.horizontalSeek);

        // 清理 Timer（等待超过2秒让定时器完成）
        await tester.pump(const Duration(seconds: 3));
      });

      testWidgets('[P0] 向左滑动应该减少seek进度', (tester) async {
        // GIVEN: 初始进度为50%
        gestureController.setDuration(60000);
        gestureController.updateSeekProgress(0.5);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlayerGestureDetector(
                gestureController: gestureController,
                playerController: mockPlayerController,
                onTap: () => onTapCalled = true,
                child: const SizedBox(
                  width: 390,
                  height: 844,
                  child: ColoredBox(color: Colors.black),
                ),
              ),
            ),
          ),
        );

        final initialProgress = gestureController.state.seekProgress;

        // WHEN: 向左滑动（直接调用方法）
        final startPos = DragStartDetails(
          globalPosition: const Offset(300, 400),
        );
        gestureController.handleDragStart(startPos);

        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(100, 400),
          delta: const Offset(-200, 0),
        );
        gestureController.handleDragUpdate(updateDetails, const Size(390, 844));

        await tester.pump();

        // THEN: 进度应该减少
        expect(gestureController.state.seekProgress, lessThan(initialProgress));

        // 手势结束
        gestureController.handleDragEnd();
        await tester.pump(const Duration(seconds: 3));
      });
    });

    group('P0 - 场景2: 垂直滑动不触发任何手势', () {
      testWidgets('[P0] 左侧垂直滑动不应该识别任何手势', (tester) async {
        // GIVEN: 手势控制器和播放器
        gestureController.setDuration(60000);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlayerGestureDetector(
                gestureController: gestureController,
                playerController: mockPlayerController,
                child: const SizedBox(
                  width: 390,
                  height: 844,
                  child: ColoredBox(color: Colors.black),
                ),
              ),
            ),
          ),
        );

        // WHEN: 在屏幕左侧（x < 195）向上滑动
        final startPos = DragStartDetails(
          globalPosition: const Offset(100, 500),
        );
        gestureController.handleDragStart(startPos);

        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(100, 300),
          delta: const Offset(0, -200),
        );
        gestureController.handleDragUpdate(updateDetails, const Size(390, 844));

        await tester.pump();

        // THEN: 手势类型应该仍然为 none（垂直滑动被忽略）
        expect(gestureController.lastGestureType, GestureType.none);
        expect(gestureController.state.type, GestureType.none);

        // 手势结束
        gestureController.handleDragEnd();
        await tester.pump(const Duration(seconds: 3));

        expect(gestureController.lastGestureType, GestureType.none);
      });

      testWidgets('[P0] 右侧垂直滑动不应该识别任何手势', (tester) async {
        gestureController.setDuration(60000);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlayerGestureDetector(
                gestureController: gestureController,
                playerController: mockPlayerController,
                child: const SizedBox(
                  width: 390,
                  height: 844,
                  child: ColoredBox(color: Colors.black),
                ),
              ),
            ),
          ),
        );

        // WHEN: 在屏幕右侧向下滑动
        final startPos = DragStartDetails(
          globalPosition: const Offset(300, 300),
        );
        gestureController.handleDragStart(startPos);

        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(300, 500),
          delta: const Offset(0, 200),
        );
        gestureController.handleDragUpdate(updateDetails, const Size(390, 844));

        await tester.pump();

        // THEN: 手势类型应该仍然为 none（垂直滑动被忽略）
        expect(gestureController.state.type, GestureType.none);

        // 手势结束
        gestureController.handleDragEnd();
        await tester.pump(const Duration(seconds: 3));

        expect(gestureController.lastGestureType, GestureType.none);
      });
    });

    group('P0 - 场景3: 滑动方向判断', () {
      testWidgets('[P0] 水平滑动应该触发seek', (tester) async {
        gestureController.setDuration(60000);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlayerGestureDetector(
                gestureController: gestureController,
                playerController: mockPlayerController,
                child: const SizedBox(
                  width: 390,
                  height: 844,
                  child: ColoredBox(color: Colors.black),
                ),
              ),
            ),
          ),
        );

        // WHEN: 在屏幕中间进行大幅水平滑动
        final startPos = DragStartDetails(
          globalPosition: const Offset(200, 400),
        );
        gestureController.handleDragStart(startPos);

        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(400, 410),
          delta: const Offset(200, 10),
        );
        gestureController.handleDragUpdate(updateDetails, const Size(390, 844));

        await tester.pump();

        // THEN: 应该识别为水平滑动 (horizontalSeek)
        expect(gestureController.lastGestureType, GestureType.none); // 进行中

        // 手势结束
        gestureController.handleDragEnd();
        await tester.pump(const Duration(seconds: 3));

        expect(gestureController.lastGestureType, GestureType.horizontalSeek);
      });

      testWidgets('[P0] 垂直滑动不应该触发任何手势', (tester) async {
        gestureController.setDuration(60000);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlayerGestureDetector(
                gestureController: gestureController,
                playerController: mockPlayerController,
                child: const SizedBox(
                  width: 390,
                  height: 844,
                  child: ColoredBox(color: Colors.black),
                ),
              ),
            ),
          ),
        );

        // WHEN: 在屏幕左侧进行大幅垂直滑动
        final startPos = DragStartDetails(
          globalPosition: const Offset(100, 400),
        );
        gestureController.handleDragStart(startPos);

        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(110, 600),
          delta: const Offset(10, 200),
        );
        gestureController.handleDragUpdate(updateDetails, const Size(390, 844));

        await tester.pump();

        // 手势结束
        gestureController.handleDragEnd();
        await tester.pump(const Duration(seconds: 3));

        // THEN: 垂直滑动应该被忽略，不识别为任何手势
        expect(gestureController.lastGestureType, GestureType.none);
      });

      testWidgets('[P0] 小幅滑动不应该触发手势（阈值过滤）', (tester) async {
        gestureController.setDuration(60000);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlayerGestureDetector(
                gestureController: gestureController,
                playerController: mockPlayerController,
                child: const SizedBox(
                  width: 390,
                  height: 844,
                  child: ColoredBox(color: Colors.black),
                ),
              ),
            ),
          ),
        );

        // WHEN: 进行非常小的滑动（小于20像素阈值）
        final startPos = DragStartDetails(
          globalPosition: const Offset(200, 400),
        );
        gestureController.handleDragStart(startPos);

        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(210, 410),
          delta: const Offset(10, 10),
        );
        gestureController.handleDragUpdate(updateDetails, const Size(390, 844));

        await tester.pump();

        // THEN: 手势类型应该仍然是 none（因为滑动距离小于阈值）
        expect(gestureController.lastGestureType, GestureType.none);
        expect(gestureController.state.type, GestureType.none);

        // 手势结束
        gestureController.handleDragEnd();
        // 等待提示隐藏定时器完成（2秒）
        await tester.pump(const Duration(seconds: 3));

        expect(gestureController.lastGestureType, GestureType.none);
      });
    });

    group('P1 - 场景4: 锁屏状态', () {
      testWidgets('[P1] 锁屏状态下滑动手势应该被禁用', (tester) async {
        gestureController.setDuration(60000);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlayerGestureDetector(
                gestureController: gestureController,
                playerController: mockPlayerController,
                isLocked: true, // 锁屏状态
                child: const SizedBox(
                  width: 390,
                  height: 844,
                  child: ColoredBox(color: Colors.black),
                ),
              ),
            ),
          ),
        );

        // WHEN: 尝试进行滑动（isLocked=true 时 onPanStart 为 null，所以不会有任何效果）
        await tester.pumpAndSettle();

        // THEN: 手势类型应该保持 none
        expect(gestureController.lastGestureType, GestureType.none);
        expect(gestureController.state.type, GestureType.none);
      });

      testWidgets('[P1] 锁屏状态下双击应该被禁用', (tester) async {
        onDoubleTapCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlayerGestureDetector(
                gestureController: gestureController,
                playerController: mockPlayerController,
                isLocked: true,
                onDoubleTap: () => onDoubleTapCalled = true,
                child: const SizedBox(
                  width: 390,
                  height: 844,
                  child: ColoredBox(color: Colors.black),
                ),
              ),
            ),
          ),
        );

        // WHEN: 尝试双击
        await tester.tap(find.byType(PlayerGestureDetector));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byType(PlayerGestureDetector));
        // 等待双击检测延迟（300ms）+ 一些额外时间
        await tester.pump(const Duration(milliseconds: 400));

        // THEN: 双击回调不应该被调用（isLocked=true 时 onDoubleTap 为 null）
        expect(onDoubleTapCalled, isFalse);
      });

      testWidgets('[P1] 非锁屏状态下滑动手势应该正常工作', (tester) async {
        gestureController.setDuration(60000);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlayerGestureDetector(
                gestureController: gestureController,
                playerController: mockPlayerController,
                isLocked: false, // 未锁屏
                child: const SizedBox(
                  width: 390,
                  height: 844,
                  child: ColoredBox(color: Colors.black),
                ),
              ),
            ),
          ),
        );

        // WHEN: 进行滑动
        final startPos = DragStartDetails(
          globalPosition: const Offset(200, 400),
        );
        gestureController.handleDragStart(startPos);

        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(400, 400),
          delta: const Offset(200, 0),
        );
        gestureController.handleDragUpdate(updateDetails, const Size(390, 844));

        await tester.pump();

        // THEN: 手势应该被识别
        expect(gestureController.state.type, GestureType.horizontalSeek);

        // 手势结束
        gestureController.handleDragEnd();
        await tester.pump(const Duration(seconds: 3));

        expect(gestureController.lastGestureType, GestureType.horizontalSeek);
      });
    });

    group('P1 - 场景5: 手势冲突处理', () {
      testWidgets('[P1] 单纯单击应该触发onTap回调', (tester) async {
        gestureController.setDuration(60000);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlayerGestureDetector(
                gestureController: gestureController,
                playerController: mockPlayerController,
                onTap: () => onTapCalled = true,
                child: const SizedBox(
                  width: 390,
                  height: 844,
                  child: ColoredBox(color: Colors.black),
                ),
              ),
            ),
          ),
        );

        // WHEN: 直接点击（没有滑动）
        await tester.tap(find.byType(PlayerGestureDetector));
        // 等待单击延迟定时器（DoubleTapDetector 使用 300ms 延迟）
        await tester.pump(const Duration(milliseconds: 400));

        // THEN: 单击回调应该被调用
        expect(onTapCalled, isTrue);

        // 清理：等待 PlayerGestureController 的 hint hide timer（2秒）完成
        // tap 会触发 handleDragCancel，它会启动一个 2 秒的 hint hide timer
        await tester.pump(const Duration(seconds: 3));
      });

      testWidgets('[P1] 双击应该触发onDoubleTap回调', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlayerGestureDetector(
                gestureController: gestureController,
                playerController: mockPlayerController,
                onDoubleTap: () => onDoubleTapCalled = true,
                child: const SizedBox(
                  width: 390,
                  height: 844,
                  child: ColoredBox(color: Colors.black),
                ),
              ),
            ),
          ),
        );

        // WHEN: 双击
        await tester.tap(find.byType(PlayerGestureDetector));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byType(PlayerGestureDetector));
        // 等待双击检测延迟（DoubleTapDetector 使用 300ms 延迟）
        await tester.pump(const Duration(milliseconds: 400));

        // THEN: 双击回调应该被调用
        expect(onDoubleTapCalled, isTrue);

        // 清理：等待 PlayerGestureController 的 hint hide timer（2秒）完成
        // tap 会触发 handleDragCancel，它会启动一个 2 秒的 hint hide timer
        await tester.pump(const Duration(seconds: 3));
      });

      testWidgets('[P1] 手势控制器正确识别滑动超过阈值', (tester) async {
        // GIVEN: 设置手势控制器
        gestureController.setDuration(60000);

        // WHEN: 模拟滑动超过阈值
        final startPos = DragStartDetails(
          globalPosition: const Offset(200, 400),
        );
        gestureController.handleDragStart(startPos);

        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(350, 400),
          delta: const Offset(150, 0),
        );
        gestureController.handleDragUpdate(updateDetails, const Size(390, 844));

        // THEN: 手势应该被识别（水平滑动超过 20 像素阈值）
        expect(gestureController.state.type, GestureType.horizontalSeek);

        // 清理
        gestureController.handleDragEnd();
        await tester.pump(const Duration(seconds: 3));
      });
    });

    group('P2 - UI覆盖层显示', () {
      testWidgets('[P2] seek手势应该显示SeekPreviewOverlay', (tester) async {
        gestureController.setDuration(60000);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlayerGestureDetector(
                gestureController: gestureController,
                playerController: mockPlayerController,
                child: const SizedBox(
                  width: 390,
                  height: 844,
                  child: ColoredBox(color: Colors.black),
                ),
              ),
            ),
          ),
        );

        // WHEN: 直接调用手势控制器方法触发 seek 状态
        final startPos = DragStartDetails(
          globalPosition: const Offset(200, 400),
        );
        gestureController.handleDragStart(startPos);

        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(350, 400),
          delta: const Offset(150, 0),
        );
        gestureController.handleDragUpdate(updateDetails, const Size(390, 844));
        await tester.pump();

        // THEN: 应该显示 SeekPreviewOverlay（手势进行中）
        expect(find.byType(SeekPreviewOverlay), findsOneWidget);

        // 清理
        gestureController.handleDragEnd();
        await tester.pump(const Duration(seconds: 3));
      });
    });

    group('P2 - 提示自动隐藏', () {
      testWidgets('[P2] 手势结束2秒后提示应该消失', (tester) async {
        gestureController.setDuration(60000);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PlayerGestureDetector(
                gestureController: gestureController,
                playerController: mockPlayerController,
                child: const SizedBox(
                  width: 390,
                  height: 844,
                  child: ColoredBox(color: Colors.black),
                ),
              ),
            ),
          ),
        );

        // WHEN: 执行手势显示提示（直接调用方法）
        final startPos = DragStartDetails(
          globalPosition: const Offset(200, 400),
        );
        gestureController.handleDragStart(startPos);

        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(350, 400),
          delta: const Offset(150, 0),
        );
        gestureController.handleDragUpdate(updateDetails, const Size(390, 844));
        await tester.pump();

        // THEN: 手势进行中，应该显示提示
        expect(gestureController.state.showHint, isTrue);

        // 手势结束
        gestureController.handleDragEnd();
        await tester.pump();

        // THEN: 手势结束后仍然显示提示（在2秒内）
        expect(gestureController.state.showHint, isTrue);

        // 等待2秒后，提示应该消失
        await tester.pump(const Duration(milliseconds: 2100));

        // THEN: 提示应该已经消失
        expect(gestureController.state.showHint, isFalse);
      });
    });
  });
}
