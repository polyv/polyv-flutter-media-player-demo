import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/polyv_media_player.dart';

void main() {
  group('Danmaku Model Edge Case Tests', () {
    group('Danmaku color parsing edge cases', () {
      test('[P1] fromJson parses #RRGGBB format color correctly', () {
        // GIVEN: JSON with #RRGGBB color format
        final json = {
          'id': '1',
          'text': 'Test',
          'time': 1000,
          'color': '#FF0000', // Red
        };

        // WHEN: Creating Danmaku from JSON
        final danmaku = Danmaku.fromJson(json);

        // THEN: Color should be parsed correctly
        expect(danmaku.color, isNotNull);
        expect(danmaku.color, 0xFFFF0000);
      });

      test('[P1] fromJson handles missing color field', () {
        // GIVEN: JSON without color field
        final json = {'id': '1', 'text': 'Test', 'time': 1000};

        // WHEN: Creating Danmaku from JSON
        final danmaku = Danmaku.fromJson(json);

        // THEN: Color should be null (default white)
        expect(danmaku.color, isNull);
      });

      test('[P1] fromJson handles null color field', () {
        // GIVEN: JSON with null color
        final json = {'id': '1', 'text': 'Test', 'time': 1000, 'color': null};

        // WHEN: Creating Danmaku from JSON
        final danmaku = Danmaku.fromJson(json);

        // THEN: Color should be null
        expect(danmaku.color, isNull);
      });

      test('[P2] fromJson handles invalid color string gracefully', () {
        // GIVEN: JSON with invalid color format
        final json = {
          'id': '1',
          'text': 'Test',
          'time': 1000,
          'color': 'invalid-color',
        };

        // WHEN: Creating Danmaku from JSON
        final danmaku = Danmaku.fromJson(json);

        // THEN: Color should be null (fallback to default)
        expect(danmaku.color, isNull);
      });

      test('[P2] fromJson handles empty color string', () {
        // GIVEN: JSON with empty color string
        final json = {'id': '1', 'text': 'Test', 'time': 1000, 'color': ''};

        // WHEN: Creating Danmaku from JSON
        final danmaku = Danmaku.fromJson(json);

        // THEN: Color should be null
        expect(danmaku.color, isNull);
      });

      test('[P2] fromJson handles malformed hex color', () {
        // GIVEN: JSON with malformed hex color (too short)
        final json = {
          'id': '1',
          'text': 'Test',
          'time': 1000,
          'color': '#FF0', // Too short
        };

        // WHEN: Creating Danmaku from JSON
        final danmaku = Danmaku.fromJson(json);

        // THEN: Should handle gracefully (either parsed or null)
        expect(danmaku, isNotNull);
      });

      test('[P2] fromJson parses various common colors', () {
        // GIVEN: JSON with different hex colors
        final colors = {
          '#FFFFFF': Colors.white,
          '#000000': Colors.black,
          '#FF0000': const Color(0xFFFF0000), // Red
          '#00FF00': const Color(0xFF00FF00), // Green
          '#0000FF': const Color(0xFF0000FF), // Blue
        };

        for (final entry in colors.entries) {
          final json = {
            'id': '1',
            'text': 'Test',
            'time': 1000,
            'color': entry.key,
          };

          // WHEN: Creating Danmaku from JSON
          final danmaku = Danmaku.fromJson(json);

          // THEN: Color should match expected value
          final actualColor = danmaku.color != null
              ? danmaku.color! & 0xFFFFFF
              : null;
          final expectedColor = entry.value.toARGB32() & 0xFFFFFF;
          expect(
            actualColor,
            expectedColor,
            reason: 'Color ${entry.key} should match',
          );
        }
      });
    });

    group('Danmaku type parsing edge cases', () {
      test('[P1] fromJson defaults to scroll type when missing', () {
        // GIVEN: JSON without type field
        final json = {'id': '1', 'text': 'Test', 'time': 1000};

        // WHEN: Creating Danmaku from JSON
        final danmaku = Danmaku.fromJson(json);

        // THEN: Type should default to scroll
        expect(danmaku.type, DanmakuType.scroll);
      });

      test('[P1] fromJson handles null type field', () {
        // GIVEN: JSON with null type
        final json = {'id': '1', 'text': 'Test', 'time': 1000, 'type': null};

        // WHEN: Creating Danmaku from JSON
        final danmaku = Danmaku.fromJson(json);

        // THEN: Type should default to scroll
        expect(danmaku.type, DanmakuType.scroll);
      });

      test('[P2] fromJson handles all valid type strings', () {
        // GIVEN: JSON with different type strings
        final types = {
          'scroll': DanmakuType.scroll,
          'top': DanmakuType.top,
          'bottom': DanmakuType.bottom,
          'SCROLL': DanmakuType.scroll, // Case insensitive
          'TOP': DanmakuType.top,
          'BOTTOM': DanmakuType.bottom,
          'ScRoLl': DanmakuType.scroll, // Mixed case
        };

        for (final entry in types.entries) {
          final json = {
            'id': '1',
            'text': 'Test',
            'time': 1000,
            'type': entry.key,
          };

          // WHEN: Creating Danmaku from JSON
          final danmaku = Danmaku.fromJson(json);

          // THEN: Type should match expected value
          expect(danmaku.type, entry.value, reason: 'Type ${entry.key}');
        }
      });

      test('[P2] fromJson handles invalid type string gracefully', () {
        // GIVEN: JSON with invalid type
        final json = {
          'id': '1',
          'text': 'Test',
          'time': 1000,
          'type': 'invalid_type',
        };

        // WHEN: Creating Danmaku from JSON
        final danmaku = Danmaku.fromJson(json);

        // THEN: Type should default to scroll
        expect(danmaku.type, DanmakuType.scroll);
      });
    });

    group('Danmaku toJson edge cases', () {
      test('[P1] toJson includes all required fields', () {
        // GIVEN: A Danmaku with all fields
        const danmaku = Danmaku(
          id: '123',
          text: 'Test text',
          time: 5000,
          color: 0xFFFF0000,
          type: DanmakuType.top,
        );

        // WHEN: Converting to JSON
        final json = danmaku.toJson();

        // THEN: All fields should be present
        expect(json['id'], '123');
        expect(json['text'], 'Test text');
        expect(json['time'], 5000);
        expect(json['color'], isNotNull);
        expect(json['type'], 'top');
      });

      test('[P1] toJson omits color when null', () {
        // GIVEN: A Danmaku without color
        const danmaku = Danmaku(id: '123', text: 'Test text', time: 5000);

        // WHEN: Converting to JSON
        final json = danmaku.toJson();

        // THEN: Color key should not be present
        expect(json.containsKey('color'), false);
      });

      test('[P1] toJson includes type as string', () {
        // GIVEN: Danmakus with different types
        for (final type in DanmakuType.values) {
          const danmaku = Danmaku(
            id: '123',
            text: 'Test',
            time: 5000,
            type: DanmakuType.top,
          );

          final withType = danmaku.copyWith(type: type);
          final json = withType.toJson();

          // THEN: Type should be serialized as string
          expect(json['type'], type.name);
        }
      });
    });

    group('Danmaku copyWith edge cases', () {
      test('[P1] copyWith with no parameters returns identical object', () {
        // GIVEN: A Danmaku
        const danmaku = Danmaku(
          id: '123',
          text: 'Test',
          time: 5000,
          color: 0xFFFF0000,
        );

        // WHEN: Copying without any changes
        final copied = danmaku.copyWith();

        // THEN: Should be equal but not same instance
        expect(copied, equals(danmaku));
        expect(identical(copied, danmaku), false);
      });

      test('[P1] copyWith preserves unchanged fields', () {
        // GIVEN: A Danmaku
        const danmaku = Danmaku(
          id: '123',
          text: 'Test',
          time: 5000,
          type: DanmakuType.scroll,
        );

        // WHEN: Copying with only text changed
        final copied = danmaku.copyWith(text: 'Modified');

        // THEN: Other fields should be preserved
        expect(copied.id, danmaku.id);
        expect(copied.time, danmaku.time);
        expect(copied.type, danmaku.type);
        expect(copied.text, 'Modified');
      });

      test('[P2] copyWith can modify all fields independently', () {
        // GIVEN: A Danmaku
        const danmaku = Danmaku(
          id: 'original',
          text: 'Original',
          time: 1000,
          color: 0xFFFF0000,
          type: DanmakuType.scroll,
        );

        // WHEN: Modifying each field
        final idModified = danmaku.copyWith(id: 'new_id');
        final textModified = danmaku.copyWith(text: 'New text');
        final timeModified = danmaku.copyWith(time: 9999);
        final colorModified = danmaku.copyWith(color: 0xFF00FF00);
        final typeModified = danmaku.copyWith(type: DanmakuType.top);

        // THEN: Each modification should only affect the specified field
        expect(idModified.id, 'new_id');
        expect(idModified.text, danmaku.text);

        expect(textModified.text, 'New text');
        expect(textModified.id, danmaku.id);

        expect(timeModified.time, 9999);
        expect(timeModified.id, danmaku.id);

        expect(colorModified.color, 0xFF00FF00);
        expect(colorModified.id, danmaku.id);

        expect(typeModified.type, DanmakuType.top);
        expect(typeModified.id, danmaku.id);
      });
    });

    group('Danmaku equality edge cases', () {
      test('[P1] identical danmakus are equal', () {
        // GIVEN: Two identical Danmakus
        const danmaku1 = Danmaku(
          id: '1',
          text: 'Test',
          time: 1000,
          color: 0xFFFF0000,
        );
        const danmaku2 = Danmaku(
          id: '1',
          text: 'Test',
          time: 1000,
          color: 0xFFFF0000,
        );

        // THEN: Should be equal
        expect(danmaku1, equals(danmaku2));
        expect(danmaku1.hashCode, equals(danmaku2.hashCode));
      });

      test('[P1] danmakus with different ids are not equal', () {
        // GIVEN: Two danmakus with different ids
        const danmaku1 = Danmaku(id: '1', text: 'Test', time: 1000);
        const danmaku2 = Danmaku(id: '2', text: 'Test', time: 1000);

        // THEN: Should not be equal
        expect(danmaku1, isNot(equals(danmaku2)));
      });

      test('[P2] danmaku equals itself', () {
        // GIVEN: A Danmaku
        const danmaku = Danmaku(id: '1', text: 'Test', time: 1000);

        // THEN: Should equal itself
        expect(danmaku, equals(danmaku));
        expect(identical(danmaku, danmaku), true);
      });
    });

    group('ActiveDanmaku edge cases', () {
      test('[P1] fromDanmaku creates valid ActiveDanmaku', () {
        // GIVEN: A regular Danmaku
        const danmaku = Danmaku(
          id: '1',
          text: 'Test',
          time: 1000,
          color: 0xFFFF0000,
          type: DanmakuType.top,
        );

        // WHEN: Creating ActiveDanmaku
        final activeDanmaku = ActiveDanmaku.fromDanmaku(
          danmaku,
          track: 5,
          startTime: 50000,
        );

        // THEN: All original fields should be preserved
        expect(activeDanmaku.id, danmaku.id);
        expect(activeDanmaku.text, danmaku.text);
        expect(activeDanmaku.time, danmaku.time);
        expect(activeDanmaku.color, danmaku.color);
        expect(activeDanmaku.type, danmaku.type);
        expect(activeDanmaku.track, 5);
        expect(activeDanmaku.startTime, 50000);
      });

      test('[P1] isExpired returns correct values at boundaries', () {
        // GIVEN: An ActiveDanmaku with startTime = 1000
        const activeDanmaku = ActiveDanmaku(
          id: '1',
          text: 'Test',
          time: 0,
          track: 0,
          startTime: 1000,
        );

        // THEN: Should check expiration correctly
        // Animation duration is 10000ms (from main package)
        expect(activeDanmaku.isExpired(10999), false); // Still active
        expect(activeDanmaku.isExpired(11000), true); // Just expired
        expect(activeDanmaku.isExpired(11001), true); // Expired
      });

      test('[P2] ActiveDanmaku equality includes track and startTime', () {
        // GIVEN: Two ActiveDanmakus from same base
        const base = Danmaku(id: '1', text: 'Test', time: 1000);

        final active1 = ActiveDanmaku.fromDanmaku(
          base,
          track: 0,
          startTime: 5000,
        );
        final active2 = ActiveDanmaku.fromDanmaku(
          base,
          track: 1,
          startTime: 5000,
        );
        final active3 = ActiveDanmaku.fromDanmaku(
          base,
          track: 0,
          startTime: 6000,
        );

        // THEN: Should not be equal due to different track/startTime
        expect(active1, isNot(equals(active2)));
        expect(active1, isNot(equals(active3)));
      });

      test('[P2] ActiveDanmaku copyWith includes new fields', () {
        // GIVEN: An ActiveDanmaku
        const activeDanmaku = ActiveDanmaku(
          id: '1',
          text: 'Test',
          time: 1000,
          track: 0,
          startTime: 5000,
        );

        // WHEN: Copying with new track and startTime
        final copied = activeDanmaku.copyWith(track: 5, startTime: 10000);

        // THEN: New fields should be updated
        expect(copied is ActiveDanmaku, true);
        final activeCopied = copied as ActiveDanmaku;
        expect(activeCopied.track, 5);
        expect(activeCopied.startTime, 10000);
        expect(activeCopied.id, activeDanmaku.id);
        expect(activeCopied.text, activeDanmaku.text);
      });
    });

    group('Danmaku toString edge cases', () {
      test('[P2] toString returns informative string', () {
        // GIVEN: A Danmaku
        const danmaku = Danmaku(
          id: 'test_id',
          text: 'Hello World',
          time: 12345,
          type: DanmakuType.scroll,
        );

        // WHEN: Getting string representation
        final str = danmaku.toString();

        // THEN: Should contain key information
        expect(str, contains('test_id'));
        expect(str, contains('Hello World'));
        expect(str, contains('12345'));
        expect(str, contains('scroll'));
      });

      test('[P2] ActiveDanmaku toString includes track info', () {
        // GIVEN: An ActiveDanmaku
        const activeDanmaku = ActiveDanmaku(
          id: '1',
          text: 'Test',
          time: 1000,
          track: 3,
          startTime: 5000,
        );

        // WHEN: Getting string representation
        final str = activeDanmaku.toString();

        // THEN: Should include track number
        expect(str, contains('track: 3'));
        expect(str, contains('startTime: 5000'));
      });
    });
  });
}
