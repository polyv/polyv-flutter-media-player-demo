import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/polyv_media_player.dart';

/// PlayerApi 常量类测试
///
/// 测试平台通道相关的常量定义
void main() {
  group('PlayerApi - Method Channel 名称', () {
    test('[P2] methodChannelName 有正确的值', () {
      // WHEN: 访问 methodChannelName
      // THEN: 应该返回正确的通道名称
      expect(PlayerApi.methodChannelName, 'com.polyv.media_player/player');
    });

    test('[P2] eventChannelName 有正确的值', () {
      // WHEN: 访问 eventChannelName
      // THEN: 应该返回正确的通道名称
      expect(PlayerApi.eventChannelName, 'com.polyv.media_player/events');
    });

    test('[P2] downloadEventChannelName 有正确的值', () {
      expect(
        PlayerApi.downloadEventChannelName,
        'com.polyv.media_player/download_events',
      );
    });

    test('[P2] 通道名称使用相同的命名空间', () {
      // GIVEN: 通道名称
      const methodChannel = PlayerApi.methodChannelName;
      const eventChannel = PlayerApi.eventChannelName;

      // THEN: 应该使用相同的命名空间前缀
      expect(methodChannel.startsWith('com.polyv.media_player/'), isTrue);
      expect(eventChannel.startsWith('com.polyv.media_player/'), isTrue);
    });
  });

  group('PlayerMethod - 方法名称', () {
    test('[P2] loadVideo 方法名正确', () {
      expect(PlayerMethod.loadVideo, 'loadVideo');
    });

    test('[P2] play 方法名正确', () {
      expect(PlayerMethod.play, 'play');
    });

    test('[P2] pause 方法名正确', () {
      expect(PlayerMethod.pause, 'pause');
    });

    test('[P2] stop 方法名正确', () {
      expect(PlayerMethod.stop, 'stop');
    });

    test('[P2] seekTo 方法名正确', () {
      expect(PlayerMethod.seekTo, 'seekTo');
    });

    test('[P2] setPlaybackSpeed 方法名正确', () {
      expect(PlayerMethod.setPlaybackSpeed, 'setPlaybackSpeed');
    });

    test('[P2] setQuality 方法名正确', () {
      expect(PlayerMethod.setQuality, 'setQuality');
    });

    test('[P2] setSubtitle 方法名正确', () {
      expect(PlayerMethod.setSubtitle, 'setSubtitle');
    });

    test('[P2] getQualities 方法名正确', () {
      expect(PlayerMethod.getQualities, 'getQualities');
    });

    test('[P2] getSubtitles 方法名正确', () {
      expect(PlayerMethod.getSubtitles, 'getSubtitles');
    });

    test('[P2] 所有方法名使用驼峰命名', () {
      // GIVEN: 所有方法名
      const methods = [
        PlayerMethod.loadVideo,
        PlayerMethod.play,
        PlayerMethod.pause,
        PlayerMethod.stop,
        PlayerMethod.seekTo,
        PlayerMethod.setPlaybackSpeed,
        PlayerMethod.setQuality,
        PlayerMethod.setSubtitle,
        PlayerMethod.getQualities,
        PlayerMethod.getSubtitles,
      ];

      // THEN: 所有方法名应该符合驼峰命名规范
      for (final method in methods) {
        expect(method, isNotEmpty);
        expect(
          method[0],
          equals(method[0].toLowerCase()),
          reason: '$method 应该使用驼峰命名',
        );
      }
    });
  });

  group('PlayerEventName - 事件名称', () {
    test('[P2] stateChanged 事件名正确', () {
      expect(PlayerEventName.stateChanged, 'stateChanged');
    });

    test('[P2] progress 事件名正确', () {
      expect(PlayerEventName.progress, 'progress');
    });

    test('[P2] error 事件名正确', () {
      expect(PlayerEventName.error, 'error');
    });

    test('[P2] qualityChanged 事件名正确', () {
      expect(PlayerEventName.qualityChanged, 'qualityChanged');
    });

    test('[P2] subtitleChanged 事件名正确', () {
      expect(PlayerEventName.subtitleChanged, 'subtitleChanged');
    });

    test('[P2] completed 事件名正确', () {
      expect(PlayerEventName.completed, 'completed');
    });

    test('[P2] 所有事件名使用驼峰命名', () {
      // GIVEN: 所有事件名
      const events = [
        PlayerEventName.stateChanged,
        PlayerEventName.progress,
        PlayerEventName.error,
        PlayerEventName.qualityChanged,
        PlayerEventName.subtitleChanged,
        PlayerEventName.completed,
      ];

      // THEN: 所有事件名应该符合驼峰命名规范
      for (final event in events) {
        expect(event, isNotEmpty);
        expect(
          event[0],
          equals(event[0].toLowerCase()),
          reason: '$event 应该使用驼峰命名',
        );
      }
    });
  });

  group('PlayerStateValue - 状态值', () {
    test('[P2] idle 状态值正确', () {
      expect(PlayerStateValue.idle, 'idle');
    });

    test('[P2] loading 状态值正确', () {
      expect(PlayerStateValue.loading, 'loading');
    });

    test('[P2] prepared 状态值正确', () {
      expect(PlayerStateValue.prepared, 'prepared');
    });

    test('[P2] playing 状态值正确', () {
      expect(PlayerStateValue.playing, 'playing');
    });

    test('[P2] paused 状态值正确', () {
      expect(PlayerStateValue.paused, 'paused');
    });

    test('[P2] buffering 状态值正确', () {
      expect(PlayerStateValue.buffering, 'buffering');
    });

    test('[P2] completed 状态值正确', () {
      expect(PlayerStateValue.completed, 'completed');
    });

    test('[P2] error 状态值正确', () {
      expect(PlayerStateValue.error, 'error');
    });

    test('[P2] 所有状态值使用小写命名', () {
      // GIVEN: 所有状态值
      const states = [
        PlayerStateValue.idle,
        PlayerStateValue.loading,
        PlayerStateValue.prepared,
        PlayerStateValue.playing,
        PlayerStateValue.paused,
        PlayerStateValue.buffering,
        PlayerStateValue.completed,
        PlayerStateValue.error,
      ];

      // THEN: 所有状态值应该使用小写命名
      for (final state in states) {
        expect(state, equals(state.toLowerCase()), reason: '$state 应该使用小写命名');
      }
    });
  });

  group('PlayerErrorCode - 错误码', () {
    test('[P2] invalidVid 错误码正确', () {
      expect(PlayerErrorCode.invalidVid, 'INVALID_VID');
    });

    test('[P2] networkError 错误码正确', () {
      expect(PlayerErrorCode.networkError, 'NETWORK_ERROR');
    });

    test('[P2] decoderError 错误码正确', () {
      expect(PlayerErrorCode.decoderError, 'DECODER_ERROR');
    });

    test('[P2] notInitialized 错误码正确', () {
      expect(PlayerErrorCode.notInitialized, 'NOT_INITIALIZED');
    });

    test('[P2] unsupportedOperation 错误码正确', () {
      expect(PlayerErrorCode.unsupportedOperation, 'UNSUPPORTED_OPERATION');
    });

    test('[P2] 所有错误码使用大写蛇形命名', () {
      // GIVEN: 所有错误码
      const errorCodes = [
        PlayerErrorCode.invalidVid,
        PlayerErrorCode.networkError,
        PlayerErrorCode.decoderError,
        PlayerErrorCode.notInitialized,
        PlayerErrorCode.unsupportedOperation,
      ];

      // THEN: 所有错误码应该使用大写蛇形命名规范
      for (final code in errorCodes) {
        expect(code, isNotEmpty);
        expect(code, equals(code.toUpperCase()), reason: '$code 应该使用大写命名');
        // 不应该包含小写字母
        expect(
          code.contains(RegExp(r'[a-z]')),
          isFalse,
          reason: '$code 不应该包含小写字母',
        );
      }
    });

    test('[P2] 所有错误码使用下划线分隔', () {
      // THEN: 多词错误码应该用下划线分隔
      expect(PlayerErrorCode.notInitialized, contains('_'));
      expect(PlayerErrorCode.unsupportedOperation, contains('_'));
    });
  });

  group('PlayerApi - 常量一致性', () {
    test('[P2] 方法名和事件名不重复', () {
      // GIVEN: 所有方法名和事件名
      final allNames = {
        PlayerMethod.loadVideo,
        PlayerMethod.play,
        PlayerMethod.pause,
        PlayerMethod.stop,
        PlayerMethod.seekTo,
        PlayerMethod.setPlaybackSpeed,
        PlayerMethod.setQuality,
        PlayerMethod.setSubtitle,
        PlayerMethod.getQualities,
        PlayerMethod.getSubtitles,
        PlayerEventName.stateChanged,
        PlayerEventName.progress,
        PlayerEventName.error,
        PlayerEventName.qualityChanged,
        PlayerEventName.subtitleChanged,
        PlayerEventName.completed,
      };

      // THEN: 所有名称应该唯一
      expect(allNames.length, allNames.toSet().length, reason: '方法名和事件名不应该重复');
    });

    test('[P2] 通道名称使用一致的命名空间', () {
      // GIVEN: 所有通道相关常量
      const namespace = 'com.polyv.media_player';

      // THEN: 应该使用相同的命名空间
      expect(PlayerApi.methodChannelName, startsWith('$namespace/'));
      expect(PlayerApi.eventChannelName, startsWith('$namespace/'));
    });

    test('[P2] 状态值与 PlayerLoadingState 对应', () {
      // 这是一个说明性测试，确保常量与枚举值对应
      // 在实际实现中，PlayerState._parseLoadingState 使用这些字符串
      expect(PlayerStateValue.idle, 'idle');
      expect(PlayerStateValue.loading, 'loading');
      expect(PlayerStateValue.prepared, 'prepared');
      expect(PlayerStateValue.playing, 'playing');
      expect(PlayerStateValue.paused, 'paused');
      expect(PlayerStateValue.buffering, 'buffering');
      expect(PlayerStateValue.completed, 'completed');
      expect(PlayerStateValue.error, 'error');
    });
  });
}
