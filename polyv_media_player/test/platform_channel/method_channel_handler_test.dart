import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:polyv_media_player/platform_channel/method_channel_handler.dart';
import 'package:polyv_media_player/platform_channel/player_api.dart';

// Mock MethodChannel for testing
class MockMethodChannel extends Mock implements MethodChannel {}

void main() {
  // Register fallback values for Mocktail
  registerFallbackValue(const MethodCall('test'));

  group('MethodChannelHandler - [P1] Unit Tests', () {
    late MockMethodChannel mockMethodChannel;

    setUp(() {
      mockMethodChannel = MockMethodChannel();
    });

    group('[P0] loadVideo', () {
      test('should invoke loadVideo method with correct parameters', () async {
        // GIVEN: Mock channel and video parameters
        const vid = 'test_video_123';
        const autoPlay = true;
        when(
          () => mockMethodChannel.invokeMethod<void>(
            PlayerMethod.loadVideo,
            any(),
          ),
        ).thenAnswer((_) async {});

        // WHEN: Calling loadVideo via handler
        await MethodChannelHandler.loadVideo(
          mockMethodChannel,
          vid,
          autoPlay: autoPlay,
        );

        // THEN: Method should be invoked with correct arguments
        final captured =
            verify(
                  () => mockMethodChannel.invokeMethod<void>(
                    PlayerMethod.loadVideo,
                    captureAny(),
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured['vid'], equals(vid));
        expect(captured['autoPlay'], equals(autoPlay));
      });

      test('[P1] should pass autoPlay=false when specified', () async {
        // GIVEN: Mock channel with autoPlay disabled
        const vid = 'test_video_456';
        const autoPlay = false;
        when(
          () => mockMethodChannel.invokeMethod<void>(
            PlayerMethod.loadVideo,
            any(),
          ),
        ).thenAnswer((_) async {});

        // WHEN: Calling loadVideo with autoPlay=false
        await MethodChannelHandler.loadVideo(
          mockMethodChannel,
          vid,
          autoPlay: autoPlay,
        );

        // THEN: Should pass autoPlay=false correctly
        final captured =
            verify(
                  () => mockMethodChannel.invokeMethod<void>(
                    PlayerMethod.loadVideo,
                    captureAny(),
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured['autoPlay'], isFalse);
      });

      test('[P1] should default autoPlay to true when not specified', () async {
        // GIVEN: Mock channel
        const vid = 'test_video_default';
        when(
          () => mockMethodChannel.invokeMethod<void>(
            PlayerMethod.loadVideo,
            any(),
          ),
        ).thenAnswer((_) async {});

        // WHEN: Calling loadVideo without autoPlay parameter
        await MethodChannelHandler.loadVideo(mockMethodChannel, vid);

        // THEN: Should default to true
        final captured =
            verify(
                  () => mockMethodChannel.invokeMethod<void>(
                    PlayerMethod.loadVideo,
                    captureAny(),
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured['autoPlay'], isTrue);
      });
    });

    group('[P0] play', () {
      test('should invoke play method', () async {
        // GIVEN: Mock channel
        when(
          () => mockMethodChannel.invokeMethod<void>(PlayerMethod.play, null),
        ).thenAnswer((_) async {});

        // WHEN: Calling play via handler
        await MethodChannelHandler.play(mockMethodChannel);

        // THEN: Method should be invoked
        verify(
          () => mockMethodChannel.invokeMethod<void>(PlayerMethod.play, null),
        ).called(1);
      });
    });

    group('[P0] pause', () {
      test('should invoke pause method', () async {
        // GIVEN: Mock channel
        when(
          () => mockMethodChannel.invokeMethod<void>(PlayerMethod.pause, null),
        ).thenAnswer((_) async {});

        // WHEN: Calling pause via handler
        await MethodChannelHandler.pause(mockMethodChannel);

        // THEN: Method should be invoked
        verify(
          () => mockMethodChannel.invokeMethod<void>(PlayerMethod.pause, null),
        ).called(1);
      });
    });

    group('[P0] stop', () {
      test('should invoke stop method', () async {
        // GIVEN: Mock channel
        when(
          () => mockMethodChannel.invokeMethod<void>(PlayerMethod.stop, null),
        ).thenAnswer((_) async {});

        // WHEN: Calling stop via handler
        await MethodChannelHandler.stop(mockMethodChannel);

        // THEN: Method should be invoked
        verify(
          () => mockMethodChannel.invokeMethod<void>(PlayerMethod.stop, null),
        ).called(1);
      });
    });

    group('[P0] seekTo', () {
      test('should invoke seekTo with position parameter', () async {
        // GIVEN: Mock channel and position
        const position = 30000; // 30 seconds
        when(
          () =>
              mockMethodChannel.invokeMethod<void>(PlayerMethod.seekTo, any()),
        ).thenAnswer((_) async {});

        // WHEN: Calling seekTo via handler
        await MethodChannelHandler.seekTo(mockMethodChannel, position);

        // THEN: Method should be invoked with position
        final captured =
            verify(
                  () => mockMethodChannel.invokeMethod<void>(
                    PlayerMethod.seekTo,
                    captureAny(),
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured['position'], equals(position));
      });

      test('[P1] should handle zero position (seek to beginning)', () async {
        // GIVEN: Mock channel with position 0
        const position = 0;
        when(
          () =>
              mockMethodChannel.invokeMethod<void>(PlayerMethod.seekTo, any()),
        ).thenAnswer((_) async {});

        // WHEN: Seeking to beginning
        await MethodChannelHandler.seekTo(mockMethodChannel, position);

        // THEN: Should pass position 0 correctly
        final captured =
            verify(
                  () => mockMethodChannel.invokeMethod<void>(
                    PlayerMethod.seekTo,
                    captureAny(),
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured['position'], equals(0));
      });

      test('[P2] should handle large position values', () async {
        // GIVEN: Mock channel with large position (2 hours)
        const position = 7200000; // 2 hours in milliseconds
        when(
          () =>
              mockMethodChannel.invokeMethod<void>(PlayerMethod.seekTo, any()),
        ).thenAnswer((_) async {});

        // WHEN: Seeking to large position
        await MethodChannelHandler.seekTo(mockMethodChannel, position);

        // THEN: Should pass large value correctly
        final captured =
            verify(
                  () => mockMethodChannel.invokeMethod<void>(
                    PlayerMethod.seekTo,
                    captureAny(),
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured['position'], equals(7200000));
      });
    });

    group('[P0] setPlaybackSpeed', () {
      test('should invoke setPlaybackSpeed with speed parameter', () async {
        // GIVEN: Mock channel and speed
        const speed = 1.5;
        when(
          () => mockMethodChannel.invokeMethod<void>(
            PlayerMethod.setPlaybackSpeed,
            any(),
          ),
        ).thenAnswer((_) async {});

        // WHEN: Setting playback speed via handler
        await MethodChannelHandler.setPlaybackSpeed(mockMethodChannel, speed);

        // THEN: Method should be invoked with speed
        final captured =
            verify(
                  () => mockMethodChannel.invokeMethod<void>(
                    PlayerMethod.setPlaybackSpeed,
                    captureAny(),
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured['speed'], equals(speed));
      });

      test('[P1] should handle minimum speed (0.5)', () async {
        // GIVEN: Mock channel with minimum speed
        const speed = 0.5;
        when(
          () => mockMethodChannel.invokeMethod<void>(
            PlayerMethod.setPlaybackSpeed,
            any(),
          ),
        ).thenAnswer((_) async {});

        // WHEN: Setting minimum speed
        await MethodChannelHandler.setPlaybackSpeed(mockMethodChannel, speed);

        // THEN: Should pass speed correctly
        final captured =
            verify(
                  () => mockMethodChannel.invokeMethod<void>(
                    PlayerMethod.setPlaybackSpeed,
                    captureAny(),
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured['speed'], equals(0.5));
      });

      test('[P1] should handle maximum speed (2.0)', () async {
        // GIVEN: Mock channel with maximum speed
        const speed = 2.0;
        when(
          () => mockMethodChannel.invokeMethod<void>(
            PlayerMethod.setPlaybackSpeed,
            any(),
          ),
        ).thenAnswer((_) async {});

        // WHEN: Setting maximum speed
        await MethodChannelHandler.setPlaybackSpeed(mockMethodChannel, speed);

        // THEN: Should pass speed correctly
        final captured =
            verify(
                  () => mockMethodChannel.invokeMethod<void>(
                    PlayerMethod.setPlaybackSpeed,
                    captureAny(),
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured['speed'], equals(2.0));
      });

      test('[P2] should handle normal speed (1.0)', () async {
        // GIVEN: Mock channel with normal speed
        const speed = 1.0;
        when(
          () => mockMethodChannel.invokeMethod<void>(
            PlayerMethod.setPlaybackSpeed,
            any(),
          ),
        ).thenAnswer((_) async {});

        // WHEN: Setting normal speed
        await MethodChannelHandler.setPlaybackSpeed(mockMethodChannel, speed);

        // THEN: Should pass speed correctly
        final captured =
            verify(
                  () => mockMethodChannel.invokeMethod<void>(
                    PlayerMethod.setPlaybackSpeed,
                    captureAny(),
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured['speed'], equals(1.0));
      });
    });

    group('[P0] setQuality', () {
      test('should invoke setQuality with index parameter', () async {
        // GIVEN: Mock channel and quality index
        const index = 1; // 720p
        when(
          () => mockMethodChannel.invokeMethod<void>(
            PlayerMethod.setQuality,
            any(),
          ),
        ).thenAnswer((_) async {});

        // WHEN: Setting quality via handler
        await MethodChannelHandler.setQuality(mockMethodChannel, index);

        // THEN: Method should be invoked with index
        final captured =
            verify(
                  () => mockMethodChannel.invokeMethod<void>(
                    PlayerMethod.setQuality,
                    captureAny(),
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured['index'], equals(index));
      });

      test('[P1] should handle first quality index (0)', () async {
        // GIVEN: Mock channel with index 0
        const index = 0;
        when(
          () => mockMethodChannel.invokeMethod<void>(
            PlayerMethod.setQuality,
            any(),
          ),
        ).thenAnswer((_) async {});

        // WHEN: Setting to first quality
        await MethodChannelHandler.setQuality(mockMethodChannel, index);

        // THEN: Should pass index 0
        final captured =
            verify(
                  () => mockMethodChannel.invokeMethod<void>(
                    PlayerMethod.setQuality,
                    captureAny(),
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured['index'], equals(0));
      });
    });

    group('[P0] setSubtitle', () {
      test('should invoke setSubtitle with index parameter', () async {
        // GIVEN: Mock channel and subtitle index
        const index = 1; // English
        when(
          () => mockMethodChannel.invokeMethod<void>(
            PlayerMethod.setSubtitle,
            any(),
          ),
        ).thenAnswer((_) async {});

        // WHEN: Setting subtitle via handler
        await MethodChannelHandler.setSubtitle(mockMethodChannel, index);

        // THEN: Method should be invoked with index
        final captured =
            verify(
                  () => mockMethodChannel.invokeMethod<void>(
                    PlayerMethod.setSubtitle,
                    captureAny(),
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured['index'], equals(index));
      });

      test('[P1] should handle index -1 (subtitle disabled)', () async {
        // GIVEN: Mock channel with index -1
        const index = -1;
        when(
          () => mockMethodChannel.invokeMethod<void>(
            PlayerMethod.setSubtitle,
            any(),
          ),
        ).thenAnswer((_) async {});

        // WHEN: Disabling subtitle
        await MethodChannelHandler.setSubtitle(mockMethodChannel, index);

        // THEN: Should pass -1 correctly
        final captured =
            verify(
                  () => mockMethodChannel.invokeMethod<void>(
                    PlayerMethod.setSubtitle,
                    captureAny(),
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured['index'], equals(-1));
      });
    });

    group('[P1] setSubtitleWithKey', () {
      test('should invoke setSubtitle with enabled and trackKey', () async {
        // GIVEN: Mock channel and subtitle parameters
        const enabled = true;
        const trackKey = '中文';
        when(
          () => mockMethodChannel.invokeMethod<void>(
            PlayerMethod.setSubtitle,
            any(),
          ),
        ).thenAnswer((_) async {});

        // WHEN: Setting subtitle with key via handler
        await MethodChannelHandler.setSubtitleWithKey(
          mockMethodChannel,
          enabled: enabled,
          trackKey: trackKey,
        );

        // THEN: Method should be invoked with both parameters
        final captured =
            verify(
                  () => mockMethodChannel.invokeMethod<void>(
                    PlayerMethod.setSubtitle,
                    captureAny(),
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured['enabled'], isTrue);
        expect(captured['trackKey'], equals(trackKey));
      });

      test(
        '[P1] should invoke setSubtitle with enabled=false and null trackKey',
        () async {
          // GIVEN: Mock channel with disabled subtitle
          const enabled = false;
          const trackKey = null;
          when(
            () => mockMethodChannel.invokeMethod<void>(
              PlayerMethod.setSubtitle,
              any(),
            ),
          ).thenAnswer((_) async {});

          // WHEN: Disabling subtitle
          await MethodChannelHandler.setSubtitleWithKey(
            mockMethodChannel,
            enabled: enabled,
            trackKey: trackKey,
          );

          // THEN: Method should be invoked with disabled state
          final captured =
              verify(
                    () => mockMethodChannel.invokeMethod<void>(
                      PlayerMethod.setSubtitle,
                      captureAny(),
                    ),
                  ).captured.single
                  as Map<String, dynamic>;

          expect(captured['enabled'], isFalse);
          expect(captured['trackKey'], isNull);
        },
      );

      test('[P2] should handle bilingual subtitle track key', () async {
        // GIVEN: Mock channel with bilingual subtitle
        const enabled = true;
        const trackKey = '双语';
        when(
          () => mockMethodChannel.invokeMethod<void>(
            PlayerMethod.setSubtitle,
            any(),
          ),
        ).thenAnswer((_) async {});

        // WHEN: Setting bilingual subtitle
        await MethodChannelHandler.setSubtitleWithKey(
          mockMethodChannel,
          enabled: enabled,
          trackKey: trackKey,
        );

        // THEN: Should pass bilingual key
        final captured =
            verify(
                  () => mockMethodChannel.invokeMethod<void>(
                    PlayerMethod.setSubtitle,
                    captureAny(),
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured['trackKey'], equals('双语'));
        expect(captured['enabled'], isTrue);
      });

      test('[P2] should handle English subtitle track key', () async {
        // GIVEN: Mock channel with English subtitle
        const enabled = true;
        const trackKey = 'English';
        when(
          () => mockMethodChannel.invokeMethod<void>(
            PlayerMethod.setSubtitle,
            any(),
          ),
        ).thenAnswer((_) async {});

        // WHEN: Setting English subtitle
        await MethodChannelHandler.setSubtitleWithKey(
          mockMethodChannel,
          enabled: enabled,
          trackKey: trackKey,
        );

        // THEN: Should pass English key
        final captured =
            verify(
                  () => mockMethodChannel.invokeMethod<void>(
                    PlayerMethod.setSubtitle,
                    captureAny(),
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured['trackKey'], equals('English'));
      });
    });

    group('[P2] Method invocation consistency', () {
      test('should use consistent method names across all calls', () async {
        // GIVEN: Mock channel
        when(
          () => mockMethodChannel.invokeMethod<void>(any(), any()),
        ).thenAnswer((_) async {});

        // WHEN: Calling all methods
        await MethodChannelHandler.loadVideo(mockMethodChannel, 'test');
        await MethodChannelHandler.play(mockMethodChannel);
        await MethodChannelHandler.pause(mockMethodChannel);
        await MethodChannelHandler.stop(mockMethodChannel);
        await MethodChannelHandler.seekTo(mockMethodChannel, 0);
        await MethodChannelHandler.setPlaybackSpeed(mockMethodChannel, 1.0);
        await MethodChannelHandler.setQuality(mockMethodChannel, 0);
        await MethodChannelHandler.setSubtitle(mockMethodChannel, 0);

        // THEN: All methods should be invoked
        verify(
          () => mockMethodChannel.invokeMethod<void>(
            PlayerMethod.loadVideo,
            any(),
          ),
        ).called(1);
        verify(
          () => mockMethodChannel.invokeMethod<void>(PlayerMethod.play, any()),
        ).called(1);
        verify(
          () => mockMethodChannel.invokeMethod<void>(PlayerMethod.pause, any()),
        ).called(1);
        verify(
          () => mockMethodChannel.invokeMethod<void>(PlayerMethod.stop, any()),
        ).called(1);
        verify(
          () =>
              mockMethodChannel.invokeMethod<void>(PlayerMethod.seekTo, any()),
        ).called(1);
        verify(
          () => mockMethodChannel.invokeMethod<void>(
            PlayerMethod.setPlaybackSpeed,
            any(),
          ),
        ).called(1);
        verify(
          () => mockMethodChannel.invokeMethod<void>(
            PlayerMethod.setQuality,
            any(),
          ),
        ).called(1);
        verify(
          () => mockMethodChannel.invokeMethod<void>(
            PlayerMethod.setSubtitle,
            any(),
          ),
        ).called(1);
      });
    });
  });
}
