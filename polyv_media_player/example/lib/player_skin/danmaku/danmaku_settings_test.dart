import 'package:flutter_test/flutter_test.dart';
import 'danmaku_settings.dart';
import 'package:polyv_media_player/infrastructure/danmaku/danmaku_model.dart';

void main() {
  group('DanmakuSettings - [P2] Unit Tests', () {
    group('[P0] Default values', () {
      test('should have enabled true by default', () {
        // GIVEN: Default DanmakuSettings
        // WHEN: Creating with default constructor
        final settings = DanmakuSettings();

        // THEN: Should be enabled by default
        expect(settings.enabled, isTrue);
      });

      test('should have opacity 1.0 by default', () {
        // GIVEN: Default DanmakuSettings
        // WHEN: Creating with default constructor
        final settings = DanmakuSettings();

        // THEN: Should have full opacity
        expect(settings.opacity, equals(1.0));
      });

      test('should have medium fontSize by default', () {
        // GIVEN: Default DanmakuSettings
        // WHEN: Creating with default constructor
        final settings = DanmakuSettings();

        // THEN: Should have medium font size
        expect(settings.fontSize, equals(DanmakuFontSize.medium));
      });
    });

    group('[P1] Toggle enabled', () {
      test('should toggle from true to false', () {
        // GIVEN: Settings with enabled = true
        final settings = DanmakuSettings(enabled: true);

        // WHEN: Toggling
        settings.toggle();

        // THEN: Should be disabled
        expect(settings.enabled, isFalse);
      });

      test('should toggle from false to true', () {
        // GIVEN: Settings with enabled = false
        final settings = DanmakuSettings(enabled: false);

        // WHEN: Toggling
        settings.toggle();

        // THEN: Should be enabled
        expect(settings.enabled, isTrue);
      });

      test('should notify listeners when toggling', () {
        // GIVEN: Settings and listener tracking
        final settings = DanmakuSettings(enabled: true);
        var notified = false;
        settings.addListener(() => notified = true);

        // WHEN: Toggling
        settings.toggle();

        // THEN: Listener should be notified
        expect(notified, isTrue);
      });
    });

    group('[P1] Set enabled', () {
      test('should set enabled to true when disabled', () {
        // GIVEN: Disabled settings
        final settings = DanmakuSettings(enabled: false);

        // WHEN: Enabling
        settings.setEnabled(true);

        // THEN: Should be enabled
        expect(settings.enabled, isTrue);
      });

      test('should set enabled to false when enabled', () {
        // GIVEN: Enabled settings
        final settings = DanmakuSettings(enabled: true);

        // WHEN: Disabling
        settings.setEnabled(false);

        // THEN: Should be disabled
        expect(settings.enabled, isFalse);
      });

      test('[P1] should not notify when setting same value', () {
        // GIVEN: Settings and listener tracking
        final settings = DanmakuSettings(enabled: true);
        var notified = false;
        settings.addListener(() => notified = true);

        // WHEN: Setting to same value
        settings.setEnabled(true);

        // THEN: Listener should not be notified
        expect(notified, isFalse);
      });

      test('[P1] should notify when changing to different value', () {
        // GIVEN: Settings and listener tracking
        final settings = DanmakuSettings(enabled: true);
        var notified = false;
        settings.addListener(() => notified = true);

        // WHEN: Setting to different value
        settings.setEnabled(false);

        // THEN: Listener should be notified
        expect(notified, isTrue);
      });
    });

    group('[P1] Set opacity', () {
      test('should set opacity within range', () {
        // GIVEN: Default settings
        final settings = DanmakuSettings();

        // WHEN: Setting opacity to 0.5
        settings.setOpacity(0.5);

        // THEN: Opacity should be updated
        expect(settings.opacity, equals(0.5));
      });

      test('should clamp opacity to 0.0 when below minimum', () {
        // GIVEN: Default settings
        final settings = DanmakuSettings();

        // WHEN: Setting opacity to negative value
        settings.setOpacity(-0.5);

        // THEN: Should be clamped to 0.0
        expect(settings.opacity, equals(0.0));
      });

      test('should clamp opacity to 1.0 when above maximum', () {
        // GIVEN: Default settings
        final settings = DanmakuSettings();

        // WHEN: Setting opacity above 1.0
        settings.setOpacity(1.5);

        // THEN: Should be clamped to 1.0
        expect(settings.opacity, equals(1.0));
      });

      test('should accept 0.0 as minimum opacity', () {
        // GIVEN: Default settings
        final settings = DanmakuSettings();

        // WHEN: Setting opacity to 0.0
        settings.setOpacity(0.0);

        // THEN: Opacity should be 0.0
        expect(settings.opacity, equals(0.0));
      });

      test('should accept 1.0 as maximum opacity', () {
        // GIVEN: Default settings
        final settings = DanmakuSettings();

        // WHEN: Setting opacity to 1.0
        settings.setOpacity(1.0);

        // THEN: Opacity should be 1.0
        expect(settings.opacity, equals(1.0));
      });

      test('[P1] should not notify when opacity change is negligible', () {
        // GIVEN: Settings with opacity 1.0
        final settings = DanmakuSettings(opacity: 1.0);
        var notified = false;
        settings.addListener(() => notified = true);

        // WHEN: Setting to nearly same value (within 0.001 tolerance)
        settings.setOpacity(1.0005);

        // THEN: Listener should not be notified
        expect(notified, isFalse);
      });

      test('[P1] should notify when opacity changes significantly', () {
        // GIVEN: Settings and listener tracking
        final settings = DanmakuSettings(opacity: 1.0);
        var notified = false;
        settings.addListener(() => notified = true);

        // WHEN: Changing opacity significantly
        settings.setOpacity(0.5);

        // THEN: Listener should be notified
        expect(notified, isTrue);
      });
    });

    group('[P1] Set font size', () {
      test('should set font size to small', () {
        // GIVEN: Settings with medium font
        final settings = DanmakuSettings(fontSize: DanmakuFontSize.medium);

        // WHEN: Setting to small
        settings.setFontSize(DanmakuFontSize.small);

        // THEN: Should be small
        expect(settings.fontSize, equals(DanmakuFontSize.small));
      });

      test('should set font size to large', () {
        // GIVEN: Settings with medium font
        final settings = DanmakuSettings(fontSize: DanmakuFontSize.medium);

        // WHEN: Setting to large
        settings.setFontSize(DanmakuFontSize.large);

        // THEN: Should be large
        expect(settings.fontSize, equals(DanmakuFontSize.large));
      });

      test('[P1] should not notify when setting same font size', () {
        // GIVEN: Settings with medium font
        final settings = DanmakuSettings(fontSize: DanmakuFontSize.medium);
        var notified = false;
        settings.addListener(() => notified = true);

        // WHEN: Setting to same value
        settings.setFontSize(DanmakuFontSize.medium);

        // THEN: Listener should not be notified
        expect(notified, isFalse);
      });

      test('[P1] should notify when changing font size', () {
        // GIVEN: Settings and listener tracking
        final settings = DanmakuSettings(fontSize: DanmakuFontSize.medium);
        var notified = false;
        settings.addListener(() => notified = true);

        // WHEN: Changing font size
        settings.setFontSize(DanmakuFontSize.small);

        // THEN: Listener should be notified
        expect(notified, isTrue);
      });
    });

    group('[P2] copyWith', () {
      test('should copy with new enabled value', () {
        // GIVEN: Original settings
        final original = DanmakuSettings(enabled: true, opacity: 1.0);

        // WHEN: Copying with new enabled value
        final copy = original.copyWith(enabled: false);

        // THEN: Should have new enabled but other values unchanged
        expect(copy.enabled, isFalse);
        expect(copy.opacity, equals(original.opacity));
        expect(copy.fontSize, equals(original.fontSize));
      });

      test('should copy with new opacity value', () {
        // GIVEN: Original settings
        final original = DanmakuSettings(enabled: true, opacity: 1.0);

        // WHEN: Copying with new opacity value
        final copy = original.copyWith(opacity: 0.5);

        // THEN: Should have new opacity but other values unchanged
        expect(copy.enabled, equals(original.enabled));
        expect(copy.opacity, equals(0.5));
        expect(copy.fontSize, equals(original.fontSize));
      });

      test('should copy with new fontSize value', () {
        // GIVEN: Original settings
        final original = DanmakuSettings(fontSize: DanmakuFontSize.medium);

        // WHEN: Copying with new font size
        final copy = original.copyWith(fontSize: DanmakuFontSize.large);

        // THEN: Should have new font size but other values unchanged
        expect(copy.enabled, equals(original.enabled));
        expect(copy.opacity, equals(original.opacity));
        expect(copy.fontSize, equals(DanmakuFontSize.large));
      });

      test('should copy with multiple new values', () {
        // GIVEN: Original settings
        final original = DanmakuSettings();

        // WHEN: Copying with multiple new values
        final copy = original.copyWith(
          enabled: false,
          opacity: 0.3,
          fontSize: DanmakuFontSize.small,
        );

        // THEN: Should have all new values
        expect(copy.enabled, isFalse);
        expect(copy.opacity, equals(0.3));
        expect(copy.fontSize, equals(DanmakuFontSize.small));
      });

      test('should copy when no values provided', () {
        // GIVEN: Original settings
        final original = DanmakuSettings(
          enabled: true,
          opacity: 0.7,
          fontSize: DanmakuFontSize.large,
        );

        // WHEN: Copying without parameters
        final copy = original.copyWith();

        // THEN: Should have same values as original
        expect(copy.enabled, equals(original.enabled));
        expect(copy.opacity, equals(original.opacity));
        expect(copy.fontSize, equals(original.fontSize));
      });
    });

    group('[P2] JSON serialization', () {
      test('should serialize to JSON correctly', () {
        // GIVEN: Settings with specific values
        final settings = DanmakuSettings(
          enabled: false,
          opacity: 0.5,
          fontSize: DanmakuFontSize.large,
        );

        // WHEN: Converting to JSON
        final json = settings.toJson();

        // THEN: Should have correct structure
        expect(json['enabled'], isFalse);
        expect(json['opacity'], equals(0.5));
        expect(json['fontSize'], equals('large'));
      });

      test('should deserialize from JSON correctly', () {
        // GIVEN: JSON data
        final json = {'enabled': false, 'opacity': 0.5, 'fontSize': 'large'};

        // WHEN: Creating from JSON
        final settings = DanmakuSettings.fromJson(json);

        // THEN: Should have correct values
        expect(settings.enabled, isFalse);
        expect(settings.opacity, equals(0.5));
        expect(settings.fontSize, equals(DanmakuFontSize.large));
      });

      test('should use defaults when JSON fields missing', () {
        // GIVEN: Incomplete JSON
        final json = <String, dynamic>{};

        // WHEN: Creating from JSON
        final settings = DanmakuSettings.fromJson(json);

        // THEN: Should use default values
        expect(settings.enabled, isTrue);
        expect(settings.opacity, equals(1.0));
        expect(settings.fontSize, equals(DanmakuFontSize.medium));
      });

      test('[P2] should round-trip through JSON', () {
        // GIVEN: Original settings
        final original = DanmakuSettings(
          enabled: true,
          opacity: 0.75,
          fontSize: DanmakuFontSize.small,
        );

        // WHEN: Serializing and deserializing
        final json = original.toJson();
        final restored = DanmakuSettings.fromJson(json);

        // THEN: Should have same values
        expect(restored.enabled, equals(original.enabled));
        expect(restored.opacity, equals(original.opacity));
        expect(restored.fontSize, equals(original.fontSize));
      });

      test('[P2] should handle invalid fontSize gracefully', () {
        // GIVEN: JSON with invalid fontSize
        final json = {
          'enabled': true,
          'opacity': 1.0,
          'fontSize': 'invalid_size',
        };

        // WHEN: Creating from JSON
        final settings = DanmakuSettings.fromJson(json);

        // THEN: Should default to medium
        expect(settings.fontSize, equals(DanmakuFontSize.medium));
      });
    });

    group('[P2] Equality', () {
      test('should be equal when all properties match', () {
        // GIVEN: Two settings with same values
        final settings1 = DanmakuSettings(
          enabled: true,
          opacity: 0.5,
          fontSize: DanmakuFontSize.small,
        );
        final settings2 = DanmakuSettings(
          enabled: true,
          opacity: 0.5,
          fontSize: DanmakuFontSize.small,
        );

        // THEN: Should be equal
        expect(settings1, equals(settings2));
        expect(settings1.hashCode, equals(settings2.hashCode));
      });

      test('should not be equal when enabled differs', () {
        // GIVEN: Two settings with different enabled
        final settings1 = DanmakuSettings(enabled: true);
        final settings2 = DanmakuSettings(enabled: false);

        // THEN: Should not be equal
        expect(settings1, isNot(equals(settings2)));
      });

      test('should not be equal when opacity differs', () {
        // GIVEN: Two settings with different opacity
        final settings1 = DanmakuSettings(opacity: 1.0);
        final settings2 = DanmakuSettings(opacity: 0.5);

        // THEN: Should not be equal
        expect(settings1, isNot(equals(settings2)));
      });

      test('should not be equal when fontSize differs', () {
        // GIVEN: Two settings with different font size
        final settings1 = DanmakuSettings(fontSize: DanmakuFontSize.small);
        final settings2 = DanmakuSettings(fontSize: DanmakuFontSize.large);

        // THEN: Should not be equal
        expect(settings1, isNot(equals(settings2)));
      });
    });

    group('[P3] Edge cases', () {
      test('should handle extreme opacity values', () {
        // GIVEN: Settings
        final settings = DanmakuSettings();

        // WHEN: Setting extreme values
        settings.setOpacity(-999.0);
        expect(settings.opacity, equals(0.0));

        settings.setOpacity(999.0);
        expect(settings.opacity, equals(1.0));
      });

      test('should handle very small opacity changes', () {
        // GIVEN: Settings
        final settings = DanmakuSettings(opacity: 0.5);

        // WHEN: Making tiny changes within tolerance
        final originalOpacity = settings.opacity;
        settings.setOpacity(0.5005); // Within 0.001 tolerance

        // THEN: Should not update
        expect(settings.opacity, equals(originalOpacity));
      });

      test('toString should format correctly', () {
        // GIVEN: Settings
        final settings = DanmakuSettings(
          enabled: true,
          opacity: 0.75,
          fontSize: DanmakuFontSize.large,
        );

        // WHEN: Converting to string
        final str = settings.toString();

        // THEN: Should contain all values
        expect(str, contains('true'));
        expect(str, contains('0.75'));
        expect(str, contains('DanmakuFontSize.large'));
      });
    });
  });
}
