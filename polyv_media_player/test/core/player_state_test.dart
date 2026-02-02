import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/polyv_media_player.dart';

/// PlayerState 单元测试
///
/// 测试播放器状态类的各种状态转换和属性
void main() {
  group('PlayerLoadingState', () {
    test('[P2] 所有枚举值存在', () {
      // GIVEN: PlayerLoadingState 枚举
      // WHEN: 访问所有枚举值
      // THEN: 所有值都应该存在
      expect(PlayerLoadingState.idle, isNotNull);
      expect(PlayerLoadingState.loading, isNotNull);
      expect(PlayerLoadingState.prepared, isNotNull);
      expect(PlayerLoadingState.playing, isNotNull);
      expect(PlayerLoadingState.paused, isNotNull);
      expect(PlayerLoadingState.buffering, isNotNull);
      expect(PlayerLoadingState.completed, isNotNull);
      expect(PlayerLoadingState.error, isNotNull);
    });
  });

  group('PlayerState - 工厂构造函数', () {
    test('[P1] idle() 创建空闲状态', () {
      // GIVEN: 调用 PlayerState.idle()
      final state = PlayerState.idle();

      // THEN: 应该返回空闲状态
      expect(state.loadingState, PlayerLoadingState.idle);
      expect(state.position, 0);
      expect(state.duration, 0);
    });

    test('[P1] loading() 创建加载状态', () {
      // GIVEN: 测试 VID
      const testVid = 'test_video_123';

      // WHEN: 调用 PlayerState.loading()
      final state = PlayerState.loading(testVid);

      // THEN: 应该返回加载状态，并包含 VID
      expect(state.loadingState, PlayerLoadingState.loading);
      expect(state.vid, testVid);
    });

    test('[P1] error() 创建错误状态', () {
      // GIVEN: 错误码和错误信息
      const errorCode = 'NETWORK_ERROR';
      const errorMessage = 'Network connection failed';

      // WHEN: 调用 PlayerState.error()
      final state = PlayerState.error(errorCode, errorMessage);

      // THEN: 应该返回错误状态，并包含错误信息
      expect(state.loadingState, PlayerLoadingState.error);
      expect(state.errorCode, errorCode);
      expect(state.errorMessage, errorMessage);
      expect(state.hasError, isTrue);
    });
  });

  group('PlayerState - Getter 属性', () {
    test('[P2] isPlaying 当状态为 playing 时返回 true', () {
      // GIVEN: 播放中的状态
      final state = PlayerState(loadingState: PlayerLoadingState.playing);

      // THEN: isPlaying 应该为 true
      expect(state.isPlaying, isTrue);
      expect(state.isPaused, isFalse);
    });

    test('[P2] isPaused 当状态为 paused 时返回 true', () {
      // GIVEN: 暂停状态
      final state = PlayerState(loadingState: PlayerLoadingState.paused);

      // THEN: isPaused 应该为 true
      expect(state.isPaused, isTrue);
      expect(state.isPlaying, isFalse);
    });

    test('[P2] isPrepared 当状态为 prepared/playing/paused 时返回 true', () {
      // GIVEN: 各种准备完成的状态
      final preparedState = PlayerState(
        loadingState: PlayerLoadingState.prepared,
      );
      final playingState = PlayerState(
        loadingState: PlayerLoadingState.playing,
      );
      final pausedState = PlayerState(loadingState: PlayerLoadingState.paused);

      // THEN: isPrepared 都应该为 true
      expect(preparedState.isPrepared, isTrue);
      expect(playingState.isPrepared, isTrue);
      expect(pausedState.isPrepared, isTrue);

      // 其他状态应该返回 false
      final loadingState = PlayerState(
        loadingState: PlayerLoadingState.loading,
      );
      expect(loadingState.isPrepared, isFalse);
    });

    test('[P2] progress 正确计算播放进度', () {
      // GIVEN: 30秒位置，5分钟总时长
      final state = PlayerState(
        loadingState: PlayerLoadingState.playing,
        position: 30000,
        duration: 300000,
      );

      // THEN: progress 应该是 0.1 (30/300)
      expect(state.progress, closeTo(0.1, 0.001));
    });

    test('[P2] progress 当时长为0时返回0', () {
      // GIVEN: 时长为0的状态
      final state = PlayerState(
        loadingState: PlayerLoadingState.idle,
        position: 0,
        duration: 0,
      );

      // THEN: progress 应该是 0
      expect(state.progress, 0.0);
    });

    test('[P2] bufferProgress 正确计算缓冲进度', () {
      // GIVEN: 1分钟缓冲，5分钟总时长
      final state = PlayerState(
        loadingState: PlayerLoadingState.playing,
        bufferedPosition: 60000,
        duration: 300000,
      );

      // THEN: bufferProgress 应该是 0.2 (60/300)
      expect(state.bufferProgress, closeTo(0.2, 0.001));
    });
  });

  group('PlayerState - copyWith', () {
    test('[P2] copyWith 只修改指定属性', () {
      // GIVEN: 原始状态
      final original = PlayerState(
        loadingState: PlayerLoadingState.playing,
        position: 30000,
        duration: 300000,
        playbackSpeed: 1.0,
        vid: 'video1',
      );

      // WHEN: 只修改位置
      final modified = original.copyWith(position: 60000);

      // THEN: 只有位置改变，其他属性保持不变
      expect(modified.position, 60000);
      expect(modified.duration, 300000);
      expect(modified.playbackSpeed, 1.0);
      expect(modified.vid, 'video1');
      expect(modified.loadingState, PlayerLoadingState.playing);
    });

    test('[P2] copyWith 修改多个属性', () {
      // GIVEN: 原始状态
      final original = PlayerState(
        loadingState: PlayerLoadingState.playing,
        position: 30000,
        duration: 300000,
        playbackSpeed: 1.0,
      );

      // WHEN: 修改多个属性
      final modified = original.copyWith(
        position: 60000,
        playbackSpeed: 1.5,
        loadingState: PlayerLoadingState.paused,
      );

      // THEN: 所有指定属性都被修改
      expect(modified.position, 60000);
      expect(modified.playbackSpeed, 1.5);
      expect(modified.loadingState, PlayerLoadingState.paused);
      expect(modified.duration, 300000); // 未修改的属性
    });

    test('[P2] copyWith 修改错误信息', () {
      // GIVEN: 正常状态
      final original = PlayerState(loadingState: PlayerLoadingState.playing);

      // WHEN: 添加错误信息
      final errorState = original.copyWith(
        loadingState: PlayerLoadingState.error,
        errorCode: 'TEST_ERROR',
        errorMessage: 'Test error',
      );

      // THEN: 状态变为错误状态
      expect(errorState.loadingState, PlayerLoadingState.error);
      expect(errorState.errorCode, 'TEST_ERROR');
      expect(errorState.errorMessage, 'Test error');
      expect(errorState.hasError, isTrue);
    });
  });

  group('PlayerState - 相等性测试', () {
    test('[P2] 相同属性的状态相等', () {
      // GIVEN: 两个相同的状态
      final state1 = PlayerState(
        loadingState: PlayerLoadingState.playing,
        position: 30000,
        duration: 300000,
        playbackSpeed: 1.0,
        vid: 'video1',
      );
      final state2 = PlayerState(
        loadingState: PlayerLoadingState.playing,
        position: 30000,
        duration: 300000,
        playbackSpeed: 1.0,
        vid: 'video1',
      );

      // THEN: 两个状态应该相等
      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('[P2] 不同属性的状态不相等', () {
      // GIVEN: 两个不同的状态
      final state1 = PlayerState(
        loadingState: PlayerLoadingState.playing,
        position: 30000,
      );
      final state2 = PlayerState(
        loadingState: PlayerLoadingState.playing,
        position: 60000,
      );

      // THEN: 两个状态不应该相等
      expect(state1, isNot(equals(state2)));
    });

    test('[P2] 不同加载状态的状态不相等', () {
      // GIVEN: 不同加载状态
      final playing = PlayerState(loadingState: PlayerLoadingState.playing);
      final paused = PlayerState(loadingState: PlayerLoadingState.paused);

      // THEN: 不应该相等
      expect(playing, isNot(equals(paused)));
    });
  });

  group('PlayerState - toString', () {
    test('[P3] toString 包含状态信息', () {
      // GIVEN: 一个状态
      final state = PlayerState(
        loadingState: PlayerLoadingState.playing,
        position: 30000,
        duration: 300000,
      );

      // WHEN: 调用 toString
      final str = state.toString();

      // THEN: 应该包含状态、位置和时长信息
      expect(str, contains('playing'));
      expect(str, contains('30000'));
      expect(str, contains('300000'));
    });
  });
}
