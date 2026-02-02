import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/polyv_media_player.dart';

/// PlayerController 单元测试（简化版）
///
/// 测试播放器控制器的核心功能
void main() {
  // 初始化 Flutter 测试绑定
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerController - 构造和初始化', () {
    test('[P1] 创建控制器时状态为空闲', () {
      // WHEN: 创建 PlayerController
      final controller = PlayerController();

      // THEN: 初始状态应该是空闲
      expect(controller.state.loadingState, PlayerLoadingState.idle);
      expect(controller.state.position, 0);

      controller.dispose();
    });

    test('[P1] 创建控制器时清晰度和字幕列表为空', () {
      // WHEN: 创建 PlayerController
      final controller = PlayerController();

      // THEN: 列表应该为空
      expect(controller.qualities, isEmpty);
      expect(controller.subtitles, isEmpty);
      expect(controller.currentQuality, isNull);
      expect(controller.currentSubtitle, isNull);

      controller.dispose();
    });

    test('[P1] dispose 后可以再次调用', () {
      // GIVEN: 创建控制器
      final controller = PlayerController();

      // WHEN: 调用 dispose
      controller.dispose();

      // THEN: 再次调用 dispose 不应该抛出异常
      expect(() => controller.dispose(), returnsNormally);
    });
  });

  group('PlayerController - 状态属性', () {
    test('[P2] currentQuality 当没有清晰度时返回 null', () {
      // GIVEN: 控制器
      final controller = PlayerController();

      // WHEN: 没有清晰度列表时
      // THEN: currentQuality 应该为 null
      expect(controller.currentQuality, isNull);

      controller.dispose();
    });

    test('[P2] currentSubtitle 当没有字幕时返回 null', () {
      // GIVEN: 控制器
      final controller = PlayerController();

      // WHEN: 没有字幕列表时
      // THEN: currentSubtitle 应该为 null
      expect(controller.currentSubtitle, isNull);

      controller.dispose();
    });
  });

  group('PlayerController - 平台通道方法', () {
    test('[P1] loadVideo 调用平台通道', () async {
      // GIVEN: 控制器
      final controller = PlayerController();
      const testVid = 'test_video_123';

      // WHEN/THEN: loadVideo 应该调用平台通道
      expect(
        () => controller.loadVideo(testVid),
        throwsA(isA<MissingPluginException>()),
      );

      controller.dispose();
    });

    test('[P1] play 调用平台通道', () async {
      // GIVEN: 控制器
      final controller = PlayerController();

      // WHEN/THEN: play 应该调用平台通道
      expect(() => controller.play(), throwsA(isA<MissingPluginException>()));

      controller.dispose();
    });

    test('[P1] pause 调用平台通道', () async {
      // GIVEN: 控制器
      final controller = PlayerController();

      // WHEN/THEN: pause 应该调用平台通道
      expect(() => controller.pause(), throwsA(isA<MissingPluginException>()));

      controller.dispose();
    });

    test('[P1] stop 调用平台通道', () async {
      // GIVEN: 控制器
      final controller = PlayerController();

      // WHEN/THEN: stop 应该调用平台通道
      expect(() => controller.stop(), throwsA(isA<MissingPluginException>()));

      controller.dispose();
    });

    test('[P1] seekTo 调用平台通道', () async {
      // GIVEN: 控制器
      final controller = PlayerController();
      const testPosition = 60000; // 1分钟

      // WHEN/THEN: seekTo 应该调用平台通道
      expect(
        () => controller.seekTo(testPosition),
        throwsA(isA<MissingPluginException>()),
      );

      controller.dispose();
    });

    test('[P1] setPlaybackSpeed 调用平台通道', () async {
      // GIVEN: 控制器
      final controller = PlayerController();
      const testSpeed = 1.5;

      // WHEN/THEN: setPlaybackSpeed 应该调用平台通道
      expect(
        () => controller.setPlaybackSpeed(testSpeed),
        throwsA(isA<MissingPluginException>()),
      );

      controller.dispose();
    });
  });

  group('PlayerController - 清晰度和字幕', () {
    test('[P1] setQuality 验证索引', () {
      // GIVEN: 控制器
      final controller = PlayerController();
      const testIndex = 1;

      // WHEN/THEN: 没有清晰度列表时抛出 PlayerException
      expect(
        () => controller.setQuality(testIndex),
        throwsA(isA<PlayerException>()),
      );

      controller.dispose();
    });

    test('[P1] setSubtitle 验证索引', () {
      // GIVEN: 控制器
      final controller = PlayerController();
      const testIndex = 0;

      // WHEN/THEN: 没有字幕列表时抛出 PlayerException
      expect(
        () => controller.setSubtitle(testIndex),
        throwsA(isA<PlayerException>()),
      );

      controller.dispose();
    });

    test('[P2] setSubtitle 支持 -1（关闭字幕）', () async {
      // GIVEN: 控制器
      final controller = PlayerController();

      // WHEN/THEN: -1 通过验证但会调用平台通道
      expect(
        () => controller.setSubtitle(-1),
        throwsA(isA<MissingPluginException>()),
      );

      controller.dispose();
    });
  });

  group('PlayerController - 异常处理', () {
    test('[P2] 无效清晰度索引抛出异常', () {
      // GIVEN: 控制器
      final controller = PlayerController();
      const invalidIndex = 999;

      // WHEN/THEN: 尝试设置无效清晰度应该抛出异常
      expect(
        () => controller.setQuality(invalidIndex),
        throwsA(isA<PlayerException>()),
      );

      controller.dispose();
    });

    test('[P2] 负数清晰度索引抛出异常', () {
      // GIVEN: 控制器
      final controller = PlayerController();
      const negativeIndex = -1;

      // WHEN/THEN: 尝试设置负数清晰度应该抛出异常
      expect(
        () => controller.setQuality(negativeIndex),
        throwsA(isA<PlayerException>()),
      );

      controller.dispose();
    });

    test('[P2] 超出范围的字幕索引抛出异常', () {
      // GIVEN: 控制器
      final controller = PlayerController();
      const invalidIndex = 999;

      // WHEN/THEN: 尝试设置无效字幕应该抛出异常
      expect(
        () => controller.setSubtitle(invalidIndex),
        throwsA(isA<PlayerException>()),
      );

      controller.dispose();
    });

    test('[P2] 负数字幕索引抛出异常（-1除外）', () {
      // GIVEN: 控制器
      final controller = PlayerController();
      const invalidCloseIndex = -2;

      // WHEN/THEN: -2 应该抛出异常
      expect(
        () => controller.setSubtitle(invalidCloseIndex),
        throwsA(isA<PlayerException>()),
      );

      controller.dispose();
    });
  });

  group('PlayerController - Getter 属性验证', () {
    test('[P2] qualities 返回不可修改的列表', () {
      // GIVEN: 控制器
      final controller = PlayerController();

      // WHEN: 获取清晰度列表
      final qualities = controller.qualities;

      // THEN: 返回的列表应该是不可修改的
      expect(qualities, isA<List>());
      expect(
        () => qualities.add(
          const QualityItem(description: 'test', value: 'test'),
        ),
        throwsUnsupportedError,
      );

      controller.dispose();
    });

    test('[P2] subtitles 返回不可修改的列表', () {
      // GIVEN: 控制器
      final controller = PlayerController();

      // WHEN: 获取字幕列表
      final subtitles = controller.subtitles;

      // THEN: 返回的列表应该是不可修改的
      expect(subtitles, isA<List>());
      expect(
        () => subtitles.add(
          const SubtitleItem(trackKey: 'test', language: 'test', label: 'test'),
        ),
        throwsUnsupportedError,
      );

      controller.dispose();
    });

    test('[P2] 初始状态属性正确', () {
      // GIVEN: 控制器
      final controller = PlayerController();

      // WHEN: 获取初始状态
      final state = controller.state;

      // THEN: 所有属性应该是默认值
      expect(state.loadingState, PlayerLoadingState.idle);
      expect(state.position, 0);
      expect(state.duration, 0);
      expect(state.bufferedPosition, 0);
      expect(state.playbackSpeed, 1.0);
      expect(state.vid, isNull);
      expect(state.errorMessage, isNull);
      expect(state.errorCode, isNull);

      controller.dispose();
    });
  });

  group('PlayerController - 自定义通道名称', () {
    test('[P2] 使用自定义方法通道名称创建控制器', () {
      // GIVEN: 自定义通道名称
      const customMethodChannel = 'custom/method/channel';
      const customEventChannel = 'custom/event/channel';

      // WHEN: 创建控制器
      final controller = PlayerController(
        methodChannelName: customMethodChannel,
        eventChannelName: customEventChannel,
      );

      // THEN: 控制器应该成功创建
      expect(controller, isNotNull);
      expect(controller.state.loadingState, PlayerLoadingState.idle);

      controller.dispose();
    });

    test('[P2] 使用部分自定义通道名称', () {
      // GIVEN: 只自定义方法通道
      const customMethodChannel = 'custom/player';

      // WHEN: 创建控制器
      final controller = PlayerController(
        methodChannelName: customMethodChannel,
      );

      // THEN: 控制器应该成功创建
      expect(controller, isNotNull);

      controller.dispose();
    });
  });
}

// 测试辅助函数
Matcher returnsNormally = const _ReturnsNormallyMatcher();

class _ReturnsNormallyMatcher extends Matcher {
  const _ReturnsNormallyMatcher();

  @override
  bool matches(covariant Function? item, Map matchState) {
    if (item == null) return false;
    try {
      item();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Description describe(Description description) =>
      description.add('returns normally');

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    return mismatchDescription.add('threw an exception');
  }
}
