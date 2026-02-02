import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:polyv_media_player/services/subtitle_preference_service.dart';
import 'package:polyv_media_player/core/player_events.dart';

void main() {
  group('SubtitlePreferenceService - [P1] Unit Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      // 确保每次测试前 SharedPreferences 已初始化
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    tearDown(() async {
      // 每次测试后清理所有偏好
      await prefs.clear();
    });

    group('[P0] savePreference', () {
      test('should save enabled preference', () async {
        // GIVEN: Valid video ID and track key
        const vid = 'test_video_123';
        const trackKey = '中文';
        const enabled = true;

        // WHEN: Saving preference
        await SubtitlePreferenceService.savePreference(
          vid: vid,
          trackKey: trackKey,
          enabled: enabled,
        );

        // THEN: Should be retrievable
        final result = await SubtitlePreferenceService.loadPreference(vid);
        expect(result, isNotNull);
        expect(result!.vid, equals(vid));
        expect(result.enabled, isTrue);
        expect(result.trackKey, equals(trackKey));
      });

      test(
        '[P1] should save disabled preference and clear track key',
        () async {
          // GIVEN: Valid video ID with disabled state
          const vid = 'test_video_456';
          const trackKey = null;
          const enabled = false;

          // WHEN: Saving disabled preference
          await SubtitlePreferenceService.savePreference(
            vid: vid,
            trackKey: trackKey,
            enabled: enabled,
          );

          // THEN: Should save enabled as false and remove track key
          final result = await SubtitlePreferenceService.loadPreference(vid);
          expect(result, isNotNull);
          expect(result!.enabled, isFalse);
          expect(result.trackKey, isNull);
        },
      );

      test('[P1] should update existing preference', () async {
        // GIVEN: Existing preference
        const vid = 'test_video_789';
        await SubtitlePreferenceService.savePreference(
          vid: vid,
          trackKey: '中文',
          enabled: true,
        );

        // WHEN: Updating to different subtitle
        await SubtitlePreferenceService.savePreference(
          vid: vid,
          trackKey: 'English',
          enabled: true,
        );

        // THEN: Should have new values
        final result = await SubtitlePreferenceService.loadPreference(vid);
        expect(result!.trackKey, equals('English'));
        expect(result.enabled, isTrue);
      });

      test('[P2] should save timestamp', () async {
        // GIVEN: Valid preference
        const vid = 'test_video_timestamp';
        final beforeSave = DateTime.now().millisecondsSinceEpoch;

        // WHEN: Saving preference
        await SubtitlePreferenceService.savePreference(
          vid: vid,
          trackKey: 'zh',
          enabled: true,
        );

        // THEN: Should have timestamp
        final result = await SubtitlePreferenceService.loadPreference(vid);
        expect(result, isNotNull);
        expect(result!.timestamp, isNotNull);
        expect(result.timestamp!, greaterThanOrEqualTo(beforeSave));
      });
    });

    group('[P0] loadPreference', () {
      test('should return null for non-existent preference', () async {
        // GIVEN: Non-existent video ID
        const vid = 'non_existent_video';

        // WHEN: Loading preference
        final result = await SubtitlePreferenceService.loadPreference(vid);

        // THEN: Should return null
        expect(result, isNull);
      });

      test('[P1] should load saved preference correctly', () async {
        // GIVEN: Saved preference
        const vid = 'test_load_123';
        await SubtitlePreferenceService.savePreference(
          vid: vid,
          trackKey: 'en',
          enabled: true,
        );

        // WHEN: Loading preference
        final result = await SubtitlePreferenceService.loadPreference(vid);

        // THEN: Should match saved values
        expect(result, isNotNull);
        expect(result!.vid, equals(vid));
        expect(result.enabled, isTrue);
        expect(result.trackKey, equals('en'));
      });

      test('[P2] should handle empty string track key', () async {
        // GIVEN: Preference with empty track key
        const vid = 'test_empty_key';
        await SubtitlePreferenceService.savePreference(
          vid: vid,
          trackKey: '',
          enabled: true,
        );

        // WHEN: Loading preference
        final result = await SubtitlePreferenceService.loadPreference(vid);

        // THEN: Should load with empty track key
        expect(result, isNotNull);
        expect(result!.trackKey, equals(''));
      });
    });

    group('[P1] clearPreference', () {
      test('should remove specific preference', () async {
        // GIVEN: Existing preference
        const vid = 'test_clear_123';
        await SubtitlePreferenceService.savePreference(
          vid: vid,
          trackKey: 'zh',
          enabled: true,
        );

        // Verify it exists
        var result = await SubtitlePreferenceService.loadPreference(vid);
        expect(result, isNotNull);

        // WHEN: Clearing preference
        await SubtitlePreferenceService.clearPreference(vid);

        // THEN: Should be removed
        result = await SubtitlePreferenceService.loadPreference(vid);
        expect(result, isNull);
      });

      test('[P2] should not affect other preferences', () async {
        // GIVEN: Multiple preferences
        const vid1 = 'test_clear_vid1';
        const vid2 = 'test_clear_vid2';
        await SubtitlePreferenceService.savePreference(
          vid: vid1,
          trackKey: 'zh',
          enabled: true,
        );
        await SubtitlePreferenceService.savePreference(
          vid: vid2,
          trackKey: 'en',
          enabled: true,
        );

        // WHEN: Clearing one preference
        await SubtitlePreferenceService.clearPreference(vid1);

        // THEN: Other should still exist
        final result1 = await SubtitlePreferenceService.loadPreference(vid1);
        final result2 = await SubtitlePreferenceService.loadPreference(vid2);
        expect(result1, isNull);
        expect(result2, isNotNull);
      });
    });

    group('[P2] clearAll', () {
      test('should remove all subtitle preferences', () async {
        // GIVEN: Multiple preferences
        const vids = ['vid1', 'vid2', 'vid3'];
        for (final vid in vids) {
          await SubtitlePreferenceService.savePreference(
            vid: vid,
            trackKey: 'zh',
            enabled: true,
          );
        }

        // Verify all exist
        for (final vid in vids) {
          final result = await SubtitlePreferenceService.loadPreference(vid);
          expect(result, isNotNull);
        }

        // WHEN: Clearing all
        await SubtitlePreferenceService.clearAll();

        // THEN: All should be removed
        for (final vid in vids) {
          final result = await SubtitlePreferenceService.loadPreference(vid);
          expect(result, isNull);
        }
      });

      test('[P2] should not affect non-prefixed keys', () async {
        // GIVEN: Mixed preferences
        await SubtitlePreferenceService.savePreference(
          vid: 'test_vid',
          trackKey: 'zh',
          enabled: true,
        );
        await prefs.setString('other_key', 'other_value');

        // WHEN: Clearing all subtitle preferences
        await SubtitlePreferenceService.clearAll();

        // THEN: Non-prefixed keys should remain
        final subtitlePref = await SubtitlePreferenceService.loadPreference(
          'test_vid',
        );
        final otherValue = prefs.getString('other_key');
        expect(subtitlePref, isNull);
        expect(otherValue, equals('other_value'));
      });
    });

    group('[P2] Global default language', () {
      test('should save and retrieve global default language', () async {
        // GIVEN: A language code
        const language = 'en';

        // WHEN: Setting global default
        await SubtitlePreferenceService.setGlobalDefaultLanguage(language);

        // THEN: Should be retrievable
        final result =
            await SubtitlePreferenceService.getGlobalDefaultLanguage();
        expect(result, equals(language));
      });

      test('[P2] should return null when no global default set', () async {
        // GIVEN: No global default set
        // WHEN: Getting global default
        final result =
            await SubtitlePreferenceService.getGlobalDefaultLanguage();

        // THEN: Should return null
        expect(result, isNull);
      });

      test('[P2] should update global default language', () async {
        // GIVEN: Existing global default
        await SubtitlePreferenceService.setGlobalDefaultLanguage('zh');

        // WHEN: Updating to new language
        await SubtitlePreferenceService.setGlobalDefaultLanguage('en');

        // THEN: Should have new value
        final result =
            await SubtitlePreferenceService.getGlobalDefaultLanguage();
        expect(result, equals('en'));
      });

      test('[P2] should clear global default when setting null', () async {
        // GIVEN: Existing global default
        await SubtitlePreferenceService.setGlobalDefaultLanguage('zh');

        // WHEN: Setting to null
        await SubtitlePreferenceService.setGlobalDefaultLanguage(null);

        // THEN: Should be cleared
        final result =
            await SubtitlePreferenceService.getGlobalDefaultLanguage();
        expect(result, isNull);
      });
    });

    group('[P2] SubtitlePreference model', () {
      test('should create from SubtitleItem', () {
        // GIVEN: A subtitle item
        const vid = 'test_video';
        const item = SubtitleItem(
          trackKey: 'en',
          language: 'en',
          label: 'English',
          isDefault: false,
          isBilingual: false,
        );

        // WHEN: Creating preference from item
        final preference = SubtitlePreference.fromItem(
          vid: vid,
          item: item,
          enabled: true,
        );

        // THEN: Should have correct values
        expect(preference.vid, equals(vid));
        expect(preference.enabled, isTrue);
        expect(preference.trackKey, equals(item.trackKey));
        expect(preference.timestamp, isNotNull);
      });

      test('should create preference with null item', () {
        // GIVEN: Null subtitle item
        const vid = 'test_video';

        // WHEN: Creating preference from null item
        final preference = SubtitlePreference.fromItem(
          vid: vid,
          item: null,
          enabled: false,
        );

        // THEN: Should have disabled state and null track key
        expect(preference.vid, equals(vid));
        expect(preference.enabled, isFalse);
        expect(preference.trackKey, isNull);
      });

      test('[P2] toString should format correctly', () {
        // GIVEN: A preference
        const preference = SubtitlePreference(
          vid: 'test_vid',
          enabled: true,
          trackKey: 'zh',
        );

        // WHEN: Converting to string
        final str = preference.toString();

        // THEN: Should contain all values
        expect(str, contains('test_vid'));
        expect(str, contains('true'));
        expect(str, contains('zh'));
      });
    });

    group('[P2] Error handling', () {
      test('should handle save error gracefully', () async {
        // GIVEN: Preference service
        // WHEN: Saving normally
        // THEN: Should not throw even if prefs fails
        expect(
          () => SubtitlePreferenceService.savePreference(
            vid: 'test',
            trackKey: 'zh',
            enabled: true,
          ),
          returnsNormally,
        );
      });

      test('should handle load error gracefully', () async {
        // GIVEN: Preference service
        // WHEN: Loading with potentially invalid data
        final result = await SubtitlePreferenceService.loadPreference(
          'nonexistent',
        );

        // THEN: Should return null on error
        expect(result, isNull);
      });
    });
  });
}
