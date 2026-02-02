import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/polyv_media_player.dart';

/// PlayerController 单元测试
///
/// 测试播放器控制器的各种操作和状态管理
void main() {
  // 初始化 Flutter 测试绑定，用于 MethodChannel 和 EventChannel
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerController - 构造和初始化', () {
    test('[P1] 创建控制器时状态为空闲', () {
      // WHEN: 创建 PlayerController
      final controller = PlayerController();

      // THEN: 初始状态应该是空闲
      expect(controller.state.loadingState, PlayerLoadingState.idle);
      expect(controller.state.position, 0);
      expect(controller.state.duration, 0);

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

  group('PlayerController - loadVideo', () {
    test('[P1] loadVideo 方法调用平台通道', () async {
      // GIVEN: 控制器
      final controller = PlayerController();
      const testVid = 'test_video_123';

      // WHEN/THEN: loadVideo 应该调用平台通道
      // 由于没有原生代码，预期 MissingPluginException
      expect(
        () => controller.loadVideo(testVid),
        throwsA(isA<MissingPluginException>()),
        reason:
            'loadVideo calls platform channel (no native code in unit tests)',
      );

      controller.dispose();
    });

    test('[P1] loadVideo 支持不自动播放参数', () async {
      // GIVEN: 控制器
      final controller = PlayerController();
      const testVid = 'test_video_456';

      // WHEN/THEN: loadVideo 应该传递 autoPlay 参数
      expect(
        () => controller.loadVideo(testVid, autoPlay: false),
        throwsA(isA<MissingPluginException>()),
        reason:
            'loadVideo calls platform channel (no native code in unit tests)',
      );

      controller.dispose();
    });
  });

  group('PlayerController - 播放控制方法', () {
    test('[P1] play 方法调用平台通道', () async {
      // GIVEN: 控制器
      final controller = PlayerController();

      // WHEN/THEN: play 应该调用平台通道
      expect(
        () => controller.play(),
        throwsA(isA<MissingPluginException>()),
        reason: 'play calls platform channel (no native code in unit tests)',
      );

      controller.dispose();
    });

    test('[P1] pause 方法调用平台通道', () async {
      // GIVEN: 控制器
      final controller = PlayerController();

      // WHEN/THEN: pause 应该调用平台通道
      expect(
        () => controller.pause(),
        throwsA(isA<MissingPluginException>()),
        reason: 'pause calls platform channel (no native code in unit tests)',
      );

      controller.dispose();
    });

    test('[P1] stop 方法调用平台通道', () async {
      // GIVEN: 控制器
      final controller = PlayerController();

      // WHEN/THEN: stop 应该调用平台通道
      expect(
        () => controller.stop(),
        throwsA(isA<MissingPluginException>()),
        reason: 'stop calls platform channel (no native code in unit tests)',
      );

      controller.dispose();
    });

    test('[P1] seekTo 方法调用平台通道', () async {
      // GIVEN: 控制器
      final controller = PlayerController();
      const testPosition = 60000; // 1分钟

      // WHEN/THEN: seekTo 应该调用平台通道
      expect(
        () => controller.seekTo(testPosition),
        throwsA(isA<MissingPluginException>()),
        reason: 'seekTo calls platform channel (no native code in unit tests)',
      );

      controller.dispose();
    });
  });

  group('PlayerController - 播放设置', () {
    test('[P1] setPlaybackSpeed 方法调用平台通道', () async {
      // GIVEN: 控制器
      final controller = PlayerController();
      const testSpeed = 1.5;

      // WHEN/THEN: setPlaybackSpeed 应该调用平台通道
      expect(
        () => controller.setPlaybackSpeed(testSpeed),
        throwsA(isA<MissingPluginException>()),
        reason:
            'setPlaybackSpeed calls platform channel (no native code in unit tests)',
      );

      controller.dispose();
    });

    test('[P2] setPlaybackSpeed 支持不同速度值', () {
      // GIVEN: 控制器
      final controller = PlayerController();

      // THEN: 各种速度值都应该被接受
      // 注意：没有原生代码会抛出异常，但我们验证方法可以接受这些参数
      for (final speed in [0.5, 1.0, 1.5, 2.0]) {
        expect(
          () => controller.setPlaybackSpeed(speed),
          throwsA(isA<MissingPluginException>()),
        );
      }

      controller.dispose();
    });
  });

  group('PlayerController - 清晰度和字幕', () {
    test('[P1] setQuality 方法存在', () {
      // GIVEN: 控制器
      final controller = PlayerController();
      const testIndex = 1;

      // WHEN/THEN: setQuality 方法应该存在（索引验证先于平台通道调用）
      // 由于没有清晰度列表，会先抛出 PlayerException
      expect(
        () => controller.setQuality(testIndex),
        throwsA(isA<PlayerException>()),
        reason: 'setQuality validates index before platform call',
      );

      controller.dispose();
    });

    test('[P1] setSubtitle 方法存在', () {
      // GIVEN: 控制器
      final controller = PlayerController();
      const testIndex = 0;

      // WHEN/THEN: setSubtitle 方法应该存在（索引验证先于平台通道调用）
      // 由于没有字幕列表，会先抛出 PlayerException
      expect(
        () => controller.setSubtitle(testIndex),
        throwsA(isA<PlayerException>()),
        reason: 'setSubtitle validates index before platform call',
      );

      controller.dispose();
    });

    test('[P2] setSubtitle 支持关闭字幕（-1）', () {
      // GIVEN: 控制器
      final controller = PlayerController();

      // WHEN/THEN: -1 会通过索引验证，但会抛出平台异常
      expect(
        () => controller.setSubtitle(-1),
        throwsA(isA<MissingPluginException>()),
        reason: 'setSubtitle(-1) passes validation but calls platform',
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
  });

  group('PlayerController - getter 属性验证', () {
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
        reason: 'qualities list should be unmodifiable',
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
        reason: 'subtitles list should be unmodifiable',
      );

      controller.dispose();
    });
  });

  group('PlayerController - 方法通道名称', () {
    test('[P2] 使用默认方法通道名称', () {
      // WHEN: 创建控制器时不指定通道名称
      final controller = PlayerController();

      // THEN: 控制器应该成功创建
      expect(controller, isNotNull);
      expect(controller.state.loadingState, PlayerLoadingState.idle);

      controller.dispose();
    });

    test('[P2] 支持自定义方法通道名称', () {
      // WHEN: 创建控制器时指定通道名称
      const customMethodChannel = 'custom/player';
      const customEventChannel = 'custom/events';
      final controller = PlayerController(
        methodChannelName: customMethodChannel,
        eventChannelName: customEventChannel,
      );

      // THEN: 控制器应该成功创建
      expect(controller, isNotNull);
      expect(controller.state.loadingState, PlayerLoadingState.idle);

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
