import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/polyv_media_player.dart';

void main() {
  // 初始化 Flutter Test Binding
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerGestureController', () {
    late PlayerGestureController controller;

    setUp(() {
      controller = PlayerGestureController();
    });

    tearDown(() {
      controller.dispose();
    });

    group('构造和初始化', () {
      test('创建控制器时初始状态为 none', () {
        expect(controller.state.type, GestureType.none);
        expect(controller.state.showHint, isFalse);
      });

      test('创建控制器时 seekProgress 初始值为 0', () {
        expect(controller.state.seekProgress, 0.0);
      });

      test('创建控制器时 showHint 初始值为 false', () {
        expect(controller.state.showHint, isFalse);
      });
    });

    group('手势方向判断', () {
      final screenSize = const Size(390, 844);

      test('水平滑动应该识别为 horizontalSeek', () async {
        controller.setDuration(60000); // 1分钟视频

        // 模拟向右滑动
        final startDetails = DragStartDetails(
          globalPosition: const Offset(100, 400),
        );

        controller.handleDragStart(startDetails);

        // 水平滑动超过阈值
        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(150, 400),
          delta: const Offset(50, 0),
        );

        // 多次更新以确保方向锁定
        for (var i = 0; i < 5; i++) {
          controller.handleDragUpdate(updateDetails, screenSize);
        }

        expect(controller.state.type, GestureType.horizontalSeek);
        expect(controller.state.showHint, isTrue);
      });

      test('垂直滑动不应该识别任何手势', () async {
        controller.setDuration(60000);

        // 模拟左侧向下滑动
        final startDetails = DragStartDetails(
          globalPosition: const Offset(100, 400), // 左侧
        );

        controller.handleDragStart(startDetails);

        // 垂直滑动超过阈值
        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(100, 450),
          delta: const Offset(0, 50),
        );

        for (var i = 0; i < 5; i++) {
          controller.handleDragUpdate(updateDetails, screenSize);
        }

        // 垂直滑动应该被忽略，不识别为任何手势
        expect(controller.state.type, GestureType.none);
      });

      test('滑动距离未达到阈值时不应该识别手势', () async {
        controller.setDuration(60000);

        final startDetails = DragStartDetails(
          globalPosition: const Offset(100, 400),
        );

        controller.handleDragStart(startDetails);

        // 小幅度滑动
        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(105, 400),
          delta: const Offset(5, 0),
        );

        controller.handleDragUpdate(updateDetails, screenSize);

        // 方向未锁定，手势类型仍为 none
        expect(controller.state.type, GestureType.none);
      });
    });

    group('seek 进度计算', () {
      final screenSize = const Size(390, 844);

      test('向右滑动应该增加 seek 进度', () async {
        const duration = 60000; // 1分钟
        controller.setDuration(duration);

        final startDetails = DragStartDetails(
          globalPosition: const Offset(100, 400),
        );

        controller.handleDragStart(startDetails);

        // 向右滑动半个屏幕
        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(295, 400), // 向右195像素
          delta: const Offset(195, 0),
        );

        for (var i = 0; i < 10; i++) {
          controller.handleDragUpdate(updateDetails, screenSize);
        }

        // 进度应该增加（每屏3分钟，视频1分钟）
        expect(controller.state.seekProgress, greaterThan(0.0));
      });

      test('向左滑动应该减少 seek 进度', () async {
        // 先设置一个初始进度
        controller.updateSeekProgress(0.5);
        controller.setDuration(60000);

        final startDetails = DragStartDetails(
          globalPosition: const Offset(300, 400),
        );

        controller.handleDragStart(startDetails);

        // 向左滑动
        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(200, 400),
          delta: const Offset(-100, 0),
        );

        for (var i = 0; i < 10; i++) {
          controller.handleDragUpdate(updateDetails, screenSize);
        }

        expect(controller.state.seekProgress, lessThan(0.5));
      });

      test('seek 进度应该限制在 0-1 范围内', () async {
        controller.setDuration(60000);

        final startDetails = DragStartDetails(
          globalPosition: const Offset(100, 400),
        );

        controller.handleDragStart(startDetails);

        // 向右大幅度滑动（超过1个屏幕）
        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(500, 400),
          delta: const Offset(400, 0),
        );

        for (var i = 0; i < 20; i++) {
          controller.handleDragUpdate(updateDetails, screenSize);
        }

        expect(controller.state.seekProgress, lessThanOrEqualTo(1.0));
        expect(controller.state.seekProgress, greaterThanOrEqualTo(0.0));
      });

      test('handleDragEnd 在 horizontalSeek 时返回 seek 位置', () async {
        const duration = 60000;
        controller.setDuration(duration);
        controller.updateSeekProgress(0.3);

        final startDetails = DragStartDetails(
          globalPosition: const Offset(100, 400),
        );

        controller.handleDragStart(startDetails);

        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(150, 400),
          delta: const Offset(50, 0),
        );

        for (var i = 0; i < 10; i++) {
          controller.handleDragUpdate(updateDetails, screenSize);
        }

        final seekPosition = controller.handleDragEnd();

        expect(seekPosition, isNotNull);
        expect(seekPosition!, greaterThanOrEqualTo(0));
        expect(seekPosition, lessThanOrEqualTo(duration));
      });

      test('handleDragEnd 在非 horizontalSeek 时返回 null', () async {
        const duration = 60000;
        controller.setDuration(duration);

        final startDetails = DragStartDetails(
          globalPosition: const Offset(100, 400), // 左侧
        );

        controller.handleDragStart(startDetails);

        // 垂直滑动（不触发任何手势）
        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(100, 450),
          delta: const Offset(0, 50),
        );

        for (var i = 0; i < 10; i++) {
          controller.handleDragUpdate(updateDetails, screenSize);
        }

        final seekPosition = controller.handleDragEnd();

        expect(seekPosition, isNull);
      });
    });

    group('手势取消', () {
      test('handleDragCancel 应该重置状态', () async {
        controller.setDuration(60000);

        final startDetails = DragStartDetails(
          globalPosition: const Offset(100, 400),
        );

        controller.handleDragStart(startDetails);

        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(150, 400),
          delta: const Offset(50, 0),
        );

        for (var i = 0; i < 10; i++) {
          controller.handleDragUpdate(updateDetails, const Size(390, 844));
        }

        expect(controller.state.type, isNot(GestureType.none));

        controller.handleDragCancel();

        expect(controller.state.type, GestureType.none);
        expect(controller.state.showHint, isFalse);
      });
    });

    group('状态管理', () {
      test('updateSeekProgress 应该更新 seek 进度', () {
        controller.updateSeekProgress(0.5);

        expect(controller.state.seekProgress, 0.5);
      });

      test('setDuration 应该正确保存视频时长', () {
        const duration = 120000;
        const screenSize = Size(390, 844);

        controller.setDuration(duration);

        // 通过验证 seek 计算来确认时长设置正确
        controller.updateSeekProgress(0.5);
        controller.handleDragStart(
          DragStartDetails(globalPosition: const Offset(100, 400)),
        );

        // 水平滑动触发 seek
        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(150, 400),
          delta: const Offset(50, 0),
        );

        // 需要多次滑动以确保方向锁定
        for (var i = 0; i < 5; i++) {
          controller.handleDragUpdate(updateDetails, screenSize);
        }

        final seekPosition = controller.handleDragEnd();

        // 应该返回一个基于时长计算的值
        expect(seekPosition, isNotNull);
        expect(seekPosition!, greaterThan(0));
        expect(seekPosition, lessThanOrEqualTo(duration));
      });

      test('dispose 后不应该抛出异常', () {
        // 创建一个独立的 controller 来测试 dispose
        final testController = PlayerGestureController();
        testController.setDuration(60000);

        // dispose 应该正常执行而不抛出异常
        expect(() => testController.dispose(), returnsNormally);
      });
    });

    group('GestureState', () {
      test('copyWith 应该只修改指定字段', () {
        const state = GestureState(
          type: GestureType.horizontalSeek,
          seekProgress: 0.5,
          showHint: true,
        );

        final newState = state.copyWith(seekProgress: 0.8);

        expect(newState.type, GestureType.horizontalSeek);
        expect(newState.seekProgress, 0.8);
        expect(newState.showHint, true);
      });

      test('相等性判断应该正确工作', () {
        const state1 = GestureState(
          type: GestureType.horizontalSeek,
          seekProgress: 0.5,
        );

        const state2 = GestureState(
          type: GestureType.horizontalSeek,
          seekProgress: 0.5,
        );

        const state3 = GestureState(
          type: GestureType.none,
          seekProgress: 0.5,
        );

        expect(state1, equals(state2));
        expect(state1, isNot(equals(state3)));
      });
    });

    group('提示自动隐藏', () {
      test('提示应该在结束手势后保持显示（由定时器控制隐藏）', () {
        controller.setDuration(60000);

        final startDetails = DragStartDetails(
          globalPosition: const Offset(100, 400),
        );

        controller.handleDragStart(startDetails);

        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(150, 400),
          delta: const Offset(50, 0),
        );

        // 触发手势显示提示
        for (var i = 0; i < 10; i++) {
          controller.handleDragUpdate(updateDetails, const Size(390, 844));
        }

        expect(controller.state.showHint, isTrue);

        // 结束手势后，提示应该仍然显示（由2秒定时器控制隐藏）
        controller.handleDragEnd();

        expect(controller.state.type, GestureType.none);
        expect(controller.state.showHint, isTrue); // 提示保持显示
      });

      test('取消手势应该重置状态', () {
        controller.setDuration(60000);

        final startDetails = DragStartDetails(
          globalPosition: const Offset(100, 400),
        );

        controller.handleDragStart(startDetails);

        final updateDetails = DragUpdateDetails(
          globalPosition: const Offset(150, 400),
          delta: const Offset(50, 0),
        );

        // 触发手势显示提示
        for (var i = 0; i < 10; i++) {
          controller.handleDragUpdate(updateDetails, const Size(390, 844));
        }

        expect(controller.state.showHint, isTrue);

        // 取消手势
        controller.handleDragCancel();

        expect(controller.state.type, GestureType.none);
        expect(controller.state.showHint, isFalse);
      });
    });
  });
}
