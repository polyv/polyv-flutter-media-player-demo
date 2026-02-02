import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/core/player_state.dart';
import '../support/player_test_helpers.lib.dart';

void main() {
  group('PlayerState - [P0] State Transitions', () {
    late StateTransitionTester tester;

    setUp(() {
      tester = StateTransitionTester();
    });

    group('Idle state transitions', () {
      test('[P0] should transition from idle to loading', () {
        // GIVEN: Initial idle state
        final initialState = TestDataFactory.createPlayerState(
          loadingState: PlayerLoadingState.idle,
        );

        // WHEN: Loading a video
        final loadingState = TestDataFactory.createPlayerState(
          loadingState: PlayerLoadingState.loading,
          vid: 'test_video',
        );

        // THEN: Transition should be valid
        expect(
          tester.isValidTransition(
            PlayerLoadingState.idle,
            PlayerLoadingState.loading,
          ),
          isTrue,
        );
        expect(initialState.loadingState, equals(PlayerLoadingState.idle));
        expect(loadingState.loadingState, equals(PlayerLoadingState.loading));
        expect(loadingState.vid, equals('test_video'));
      });

      test('[P0] should transition from idle to error', () {
        // GIVEN: Initial idle state
        // WHEN: Error occurs
        // THEN: Should transition to error state
        expect(
          tester.isValidTransition(
            PlayerLoadingState.idle,
            PlayerLoadingState.error,
          ),
          isTrue,
        );
      });
    });

    group('Loading state transitions', () {
      test('[P0] should transition from loading to prepared', () {
        // GIVEN: Loading state
        // WHEN: Video is prepared
        // THEN: Should transition to prepared
        expect(
          tester.isValidTransition(
            PlayerLoadingState.loading,
            PlayerLoadingState.prepared,
          ),
          isTrue,
        );
      });

      test('[P0] should transition from loading to playing', () {
        // GIVEN: Loading state with auto-play
        // WHEN: Video starts playing
        // THEN: Should transition directly to playing
        expect(
          tester.isValidTransition(
            PlayerLoadingState.loading,
            PlayerLoadingState.playing,
          ),
          isTrue,
        );
      });

      test('[P0] should transition from loading to paused', () {
        // GIVEN: Loading state without auto-play
        // WHEN: Video is loaded but paused
        // THEN: Should transition to paused
        expect(
          tester.isValidTransition(
            PlayerLoadingState.loading,
            PlayerLoadingState.paused,
          ),
          isTrue,
        );
      });

      test('[P0] should transition from loading to error', () {
        // GIVEN: Loading state
        // WHEN: Loading fails
        // THEN: Should transition to error
        expect(
          tester.isValidTransition(
            PlayerLoadingState.loading,
            PlayerLoadingState.error,
          ),
          isTrue,
        );
      });
    });

    group('Playing state transitions', () {
      test('[P0] should transition from playing to paused', () {
        // GIVEN: Playing state
        final playingState = TestDataFactory.createPlayingState();

        // WHEN: User pauses
        final pausedState = playingState.copyWith(
          loadingState: PlayerLoadingState.paused,
        );

        // THEN: Transition should be valid
        expect(
          tester.isValidTransition(
            PlayerLoadingState.playing,
            PlayerLoadingState.paused,
          ),
          isTrue,
        );
        expect(playingState.isPlaying, isTrue);
        expect(pausedState.isPaused, isTrue);
      });

      test('[P0] should transition from playing to buffering', () {
        // GIVEN: Playing state
        // WHEN: Network buffer runs low
        // THEN: Should transition to buffering
        expect(
          tester.isValidTransition(
            PlayerLoadingState.playing,
            PlayerLoadingState.buffering,
          ),
          isTrue,
        );
      });

      test('[P0] should transition from playing to completed', () {
        // GIVEN: Playing state
        // WHEN: Video reaches end
        // THEN: Should transition to completed
        expect(
          tester.isValidTransition(
            PlayerLoadingState.playing,
            PlayerLoadingState.completed,
          ),
          isTrue,
        );
      });

      test('[P0] should transition from playing to error', () {
        // GIVEN: Playing state
        // WHEN: Playback error occurs
        // THEN: Should transition to error
        expect(
          tester.isValidTransition(
            PlayerLoadingState.playing,
            PlayerLoadingState.error,
          ),
          isTrue,
        );
      });
    });

    group('Paused state transitions', () {
      test('[P0] should transition from paused to playing', () {
        // GIVEN: Paused state
        final pausedState = TestDataFactory.createPausedState();

        // WHEN: User resumes playback
        final playingState = pausedState.copyWith(
          loadingState: PlayerLoadingState.playing,
        );

        // THEN: Transition should be valid
        expect(
          tester.isValidTransition(
            PlayerLoadingState.paused,
            PlayerLoadingState.playing,
          ),
          isTrue,
        );
        expect(pausedState.isPaused, isTrue);
        expect(playingState.isPlaying, isTrue);
      });

      test('[P0] should transition from paused to buffering', () {
        // GIVEN: Paused state
        // WHEN: User seeks and buffering starts
        // THEN: Should transition to buffering
        expect(
          tester.isValidTransition(
            PlayerLoadingState.paused,
            PlayerLoadingState.buffering,
          ),
          isTrue,
        );
      });

      test('[P0] should transition from paused to error', () {
        // GIVEN: Paused state
        // WHEN: Error occurs while paused
        // THEN: Should transition to error
        expect(
          tester.isValidTransition(
            PlayerLoadingState.paused,
            PlayerLoadingState.error,
          ),
          isTrue,
        );
      });
    });

    group('Buffering state transitions', () {
      test('[P1] should transition from buffering to playing', () {
        // GIVEN: Buffering state
        // WHEN: Buffering completes
        // THEN: Should resume playing
        expect(
          tester.isValidTransition(
            PlayerLoadingState.buffering,
            PlayerLoadingState.playing,
          ),
          isTrue,
        );
      });

      test('[P1] should transition from buffering to paused', () {
        // GIVEN: Buffering state
        // WHEN: User pauses while buffering
        // THEN: Should transition to paused
        expect(
          tester.isValidTransition(
            PlayerLoadingState.buffering,
            PlayerLoadingState.paused,
          ),
          isTrue,
        );
      });
    });

    group('Completed state transitions', () {
      test('[P1] should transition from completed to idle', () {
        // GIVEN: Completed state
        // WHEN: User stops playback
        // THEN: Should transition to idle
        expect(
          tester.isValidTransition(
            PlayerLoadingState.completed,
            PlayerLoadingState.idle,
          ),
          isTrue,
        );
      });

      test('[P1] should transition from completed to loading', () {
        // GIVEN: Completed state
        // WHEN: User loads new video
        // THEN: Should transition to loading
        expect(
          tester.isValidTransition(
            PlayerLoadingState.completed,
            PlayerLoadingState.loading,
          ),
          isTrue,
        );
      });
    });

    group('Error state transitions', () {
      test('[P1] should transition from error to idle', () {
        // GIVEN: Error state
        // WHEN: User dismisses error
        // THEN: Should transition to idle
        expect(
          tester.isValidTransition(
            PlayerLoadingState.error,
            PlayerLoadingState.idle,
          ),
          isTrue,
        );
      });

      test('[P1] should transition from error to loading', () {
        // GIVEN: Error state
        // WHEN: User retries loading
        // THEN: Should transition to loading
        expect(
          tester.isValidTransition(
            PlayerLoadingState.error,
            PlayerLoadingState.loading,
          ),
          isTrue,
        );
      });
    });

    group('[P1] Invalid state transitions', () {
      test('should not transition from completed to playing directly', () {
        // GIVEN: Completed state
        // WHEN: Trying to play without loading
        // THEN: Transition should be invalid
        expect(
          tester.isValidTransition(
            PlayerLoadingState.completed,
            PlayerLoadingState.playing,
          ),
          isFalse,
        );
      });

      test('should not transition from error to playing directly', () {
        // GIVEN: Error state
        // WHEN: Trying to play without recovery
        // THEN: Transition should be invalid
        expect(
          tester.isValidTransition(
            PlayerLoadingState.error,
            PlayerLoadingState.playing,
          ),
          isFalse,
        );
      });
    });

    group('[P1] State properties during transitions', () {
      test('should preserve position when pausing', () {
        // GIVEN: Playing at position 5000
        final playingState = TestDataFactory.createPlayingState(
          position: 5000,
          duration: 60000,
        );

        // WHEN: Pausing
        final pausedState = playingState.copyWith(
          loadingState: PlayerLoadingState.paused,
        );

        // THEN: Position should be preserved
        expect(pausedState.position, equals(5000));
        expect(pausedState.duration, equals(60000));
      });

      test('should update playback speed during playback', () {
        // GIVEN: Playing at 1x speed
        final normalSpeedState = TestDataFactory.createPlayingState(
          playbackSpeed: 1.0,
        );

        // WHEN: Changing speed to 2x
        final fastSpeedState = normalSpeedState.copyWith(playbackSpeed: 2.0);

        // THEN: Speed should be updated
        expect(fastSpeedState.playbackSpeed, equals(2.0));
      });

      test('should include error info in error state', () {
        // GIVEN: Any state
        // WHEN: Error occurs
        final errorState = TestDataFactory.createErrorState(
          errorCode: 'NETWORK_ERROR',
          errorMessage: 'Network connection failed',
        );

        // THEN: Error info should be available
        expect(errorState.hasError, isTrue);
        expect(errorState.errorCode, equals('NETWORK_ERROR'));
        expect(errorState.errorMessage, equals('Network connection failed'));
      });
    });

    group('[P2] State equality and immutability', () {
      test('should correctly compare equal states', () {
        // GIVEN: Two identical states
        final state1 = TestDataFactory.createPlayerState(
          loadingState: PlayerLoadingState.playing,
          position: 5000,
          duration: 60000,
        );

        final state2 = TestDataFactory.createPlayerState(
          loadingState: PlayerLoadingState.playing,
          position: 5000,
          duration: 60000,
        );

        // THEN: States should be equal
        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('should correctly differentiate different states', () {
        // GIVEN: Two different states
        final state1 = TestDataFactory.createPlayingState(position: 5000);
        final state2 = TestDataFactory.createPlayingState(position: 10000);

        // THEN: States should not be equal
        expect(state1, isNot(equals(state2)));
      });

      test('should create new instance with copyWith', () {
        // GIVEN: Original state
        final originalState = TestDataFactory.createPlayerState(
          loadingState: PlayerLoadingState.playing,
          position: 5000,
        );

        // WHEN: Creating modified copy
        final modifiedState = originalState.copyWith(position: 10000);

        // THEN: Original should be unchanged
        expect(originalState.position, equals(5000));
        expect(modifiedState.position, equals(10000));
      });
    });

    group('[P2] Computed properties', () {
      test('should calculate progress correctly', () {
        // GIVEN: State with position and duration
        final state = TestDataFactory.createPlayerState(
          loadingState: PlayerLoadingState.playing,
          position: 30000,
          duration: 60000,
        );

        // THEN: Progress should be 0.5
        expect(state.progress, closeTo(0.5, 0.001));
      });

      test('should handle zero duration in progress calculation', () {
        // GIVEN: State with zero duration
        final state = TestDataFactory.createPlayerState(
          loadingState: PlayerLoadingState.playing,
          position: 1000,
          duration: 0,
        );

        // THEN: Progress should be 0.0
        expect(state.progress, equals(0.0));
      });

      test('should calculate buffer progress correctly', () {
        // GIVEN: State with buffered position
        final state = TestDataFactory.createPlayerState(
          loadingState: PlayerLoadingState.playing,
          position: 10000,
          duration: 60000,
          bufferedPosition: 45000,
        );

        // THEN: Buffer progress should be 0.75
        expect(state.bufferProgress, closeTo(0.75, 0.001));
      });

      test('should correctly identify isPlaying', () {
        final playingState = TestDataFactory.createPlayerState(
          loadingState: PlayerLoadingState.playing,
        );
        final pausedState = TestDataFactory.createPlayerState(
          loadingState: PlayerLoadingState.paused,
        );

        expect(playingState.isPlaying, isTrue);
        expect(pausedState.isPlaying, isFalse);
      });

      test('should correctly identify isPrepared', () {
        final preparedState = TestDataFactory.createPlayerState(
          loadingState: PlayerLoadingState.prepared,
        );
        final playingState = TestDataFactory.createPlayerState(
          loadingState: PlayerLoadingState.playing,
        );
        final pausedState = TestDataFactory.createPlayerState(
          loadingState: PlayerLoadingState.paused,
        );
        final loadingState = TestDataFactory.createPlayerState(
          loadingState: PlayerLoadingState.loading,
        );

        expect(preparedState.isPrepared, isTrue);
        expect(playingState.isPrepared, isTrue);
        expect(pausedState.isPrepared, isTrue);
        expect(loadingState.isPrepared, isFalse);
      });
    });
  });
}
