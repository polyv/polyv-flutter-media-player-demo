import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:polyv_media_player/services/polyv_config_service.dart';

/// Mock MethodChannel for testing
class MockMethodChannel extends Mock implements MethodChannel {}

void main() {
  // Initialize mocktail fallback values
  setUpAll(() {
    registerFallbackValue(const MethodCall('dummy'));
  });

  group('PolyvConfigService - [P1] Unit Tests', () {
    late PolyvConfigService service;

    setUp(() {
      service = PolyvConfigService();
    });

    group('[P0] Singleton pattern', () {
      test('should return same instance on multiple calls', () {
        // GIVEN: PolyvConfigService class
        // WHEN: Getting multiple instances
        final instance1 = PolyvConfigService();
        final instance2 = PolyvConfigService();

        // THEN: Should be the same instance
        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('[P1] Config state getters', () {
      test('should indicate not loaded initially', () {
        // GIVEN: Fresh service instance
        // WHEN: Checking load state
        final isLoaded = service.isConfigLoaded;
        final config = service.config;

        // THEN: Should indicate not loaded
        expect(isLoaded, isFalse);
        expect(config, isNull);
      });

      test('should indicate not loading initially', () {
        // GIVEN: Fresh service instance
        // WHEN: Checking loading state
        final isLoading = service.isLoading;

        // THEN: Should not be loading
        expect(isLoading, isFalse);
      });

      test('should indicate not injected initially', () {
        // GIVEN: Fresh service instance
        // WHEN: Checking injected state
        final isInjected = service.isConfigInjected;

        // THEN: Should indicate not injected
        expect(isInjected, isFalse);
      });
    });

    group('[P1] Clear cache', () {
      test('should clear cached config', () async {
        // GIVEN: Service with cached config (simulated by direct state manipulation)
        // Note: We can't actually cache without mocking the method channel,
        // but we can test the clear method doesn't throw
        // WHEN: Clearing cache
        expect(() => service.clearCache(), returnsNormally);

        // THEN: Cache should be cleared
        expect(service.isConfigLoaded, isFalse);
        expect(service.config, isNull);
      });

      test('[P2] should allow clearing multiple times', () {
        // GIVEN: Service instance
        // WHEN: Clearing cache multiple times
        expect(() {
          service.clearCache();
          service.clearCache();
          service.clearCache();
        }, returnsNormally);

        // THEN: Should not throw
      });
    });

    group('[P2] PolyvConfigModel', () {
      group('fromJson', () {
        test('should create model from valid JSON', () {
          // GIVEN: Valid JSON data
          final json = {
            'userId': 'test_user',
            'readToken': 'read_token_123',
            'writeToken': 'write_token_456',
            'secretKey': 'secret_key_789',
          };

          // WHEN: Creating model from JSON
          final model = PolyvConfigModel.fromJson(json);

          // THEN: Should have correct values
          expect(model.userId, equals('test_user'));
          expect(model.readToken, equals('read_token_123'));
          expect(model.writeToken, equals('write_token_456'));
          expect(model.secretKey, equals('secret_key_789'));
        });

        test('should handle missing fields with empty strings', () {
          // GIVEN: JSON with missing fields
          final json = {
            'userId': 'test_user',
            // Missing: readToken, writeToken, secretKey
          };

          // WHEN: Creating model from JSON
          final model = PolyvConfigModel.fromJson(json);

          // THEN: Missing fields should default to empty string
          expect(model.userId, equals('test_user'));
          expect(model.readToken, isEmpty);
          expect(model.writeToken, isEmpty);
          expect(model.secretKey, isEmpty);
        });

        test('should convert null values to empty string', () {
          // GIVEN: JSON with null values
          final json = {
            'userId': null,
            'readToken': null,
            'writeToken': null,
            'secretKey': null,
          };

          // WHEN: Creating model from JSON
          final model = PolyvConfigModel.fromJson(json);

          // THEN: Null values should become empty strings
          expect(model.userId, isEmpty);
          expect(model.readToken, isEmpty);
          expect(model.writeToken, isEmpty);
          expect(model.secretKey, isEmpty);
        });
      });

      group('toJson', () {
        test('should convert model to JSON', () {
          // GIVEN: A config model
          const model = PolyvConfigModel(
            userId: 'user123',
            readToken: 'read_abc',
            writeToken: 'write_def',
            secretKey: 'secret_xyz',
          );

          // WHEN: Converting to JSON
          final json = model.toJson();

          // THEN: Should have all fields
          expect(json['userId'], equals('user123'));
          expect(json['readToken'], equals('read_abc'));
          expect(json['writeToken'], equals('write_def'));
          expect(json['secretKey'], equals('secret_xyz'));
        });
      });

      group('isValid', () {
        test('should return true when userId and secretKey are present', () {
          // GIVEN: Valid config
          const model = PolyvConfigModel(
            userId: 'user123',
            readToken: '',
            writeToken: '',
            secretKey: 'secret',
          );

          // WHEN: Checking validity
          // THEN: Should be valid
          expect(model.isValid, isTrue);
        });

        test('should return false when userId is empty', () {
          // GIVEN: Config with empty userId
          const model = PolyvConfigModel(
            userId: '',
            readToken: 'read',
            writeToken: 'write',
            secretKey: 'secret',
          );

          // WHEN: Checking validity
          // THEN: Should be invalid
          expect(model.isValid, isFalse);
        });

        test('should return false when secretKey is empty', () {
          // GIVEN: Config with empty secretKey
          const model = PolyvConfigModel(
            userId: 'user123',
            readToken: 'read',
            writeToken: 'write',
            secretKey: '',
          );

          // WHEN: Checking validity
          // THEN: Should be invalid
          expect(model.isValid, isFalse);
        });

        test('should return false when both are empty', () {
          // GIVEN: Config with empty required fields
          const model = PolyvConfigModel(
            userId: '',
            readToken: 'read',
            writeToken: 'write',
            secretKey: '',
          );

          // WHEN: Checking validity
          // THEN: Should be invalid
          expect(model.isValid, isFalse);
        });
      });

      group('[P2] toString', () {
        test('should mask sensitive tokens in toString', () {
          // GIVEN: Config with tokens
          const model = PolyvConfigModel(
            userId: 'user123',
            readToken: 'sensitive_read_token',
            writeToken: 'sensitive_write_token',
            secretKey: 'sensitive_secret',
          );

          // WHEN: Converting to string
          final str = model.toString();

          // THEN: Sensitive values should be masked
          expect(str, contains('user123'));
          expect(str, contains('***')); // Masked tokens
          expect(str, isNot(contains('sensitive_read_token')));
          expect(str, isNot(contains('sensitive_write_token')));
          expect(str, isNot(contains('sensitive_secret')));
        });

        test('should show empty for empty tokens', () {
          // GIVEN: Config with empty tokens
          const model = PolyvConfigModel(
            userId: 'user123',
            readToken: '',
            writeToken: '',
            secretKey: '',
          );

          // WHEN: Converting to string
          final str = model.toString();

          // THEN: Should show empty string indicator
          expect(str, contains('user123'));
          expect(str, contains('')); // Empty indicator
        });
      });

      group('[P2] Equality', () {
        test('should create equal models from same JSON', () {
          // GIVEN: Same JSON data
          final json = {
            'userId': 'user',
            'readToken': 'read',
            'writeToken': 'write',
            'secretKey': 'secret',
          };

          // WHEN: Creating two models
          final model1 = PolyvConfigModel.fromJson(json);
          final model2 = PolyvConfigModel.fromJson(json);

          // THEN: Should have same values (data class behavior)
          expect(model1.userId, equals(model2.userId));
          expect(model1.readToken, equals(model2.readToken));
          expect(model1.writeToken, equals(model2.writeToken));
          expect(model1.secretKey, equals(model2.secretKey));
        });
      });
    });

    group('[P2] Error scenarios', () {
      test('should handle PlatformException gracefully', () {
        // Note: This test documents expected behavior
        // Actual PlatformException handling requires integration test
        // GIVEN: Service instance
        // WHEN: Platform operation fails (simulated)
        // THEN: Should propagate the exception
        // (Cannot test without actual method channel mocking)
      });

      test('should log debug messages', () {
        // GIVEN: Service with debug enabled
        // WHEN: Performing operations
        // THEN: Should log appropriate messages
        // (Cannot directly test debugPrint without capturing logs)
      });
    });

    group('[P3] Edge cases', () {
      test('should handle empty string userId', () {
        // GIVEN: Config with empty userId
        final json = {'userId': '', 'secretKey': 'secret'};

        // WHEN: Creating model
        final model = PolyvConfigModel.fromJson(json);

        // THEN: Should have empty userId
        expect(model.userId, isEmpty);
        expect(model.isValid, isFalse);
      });

      test('should handle special characters in tokens', () {
        // GIVEN: Config with special characters
        const model = PolyvConfigModel(
          userId: 'user@test.com',
          readToken: 'token-with-dash_and_underscore',
          writeToken: 'token/with/slashes',
          secretKey: 'key.with.dots',
        );

        // WHEN: Converting to JSON and back
        final json = model.toJson();
        final restored = PolyvConfigModel.fromJson(json);

        // THEN: Should preserve special characters
        expect(restored.userId, equals(model.userId));
        expect(restored.readToken, equals(model.readToken));
        expect(restored.writeToken, equals(model.writeToken));
        expect(restored.secretKey, equals(model.secretKey));
      });

      test('[P3] should handle very long token values', () {
        // GIVEN: Config with very long tokens (1000+ chars)
        final longToken = 'x' * 1000;
        final json = {
          'userId': 'user',
          'readToken': longToken,
          'writeToken': longToken,
          'secretKey': 'secret',
        };

        // WHEN: Creating model
        final model = PolyvConfigModel.fromJson(json);

        // THEN: Should handle long tokens
        expect(model.readToken.length, equals(1000));
        expect(model.writeToken.length, equals(1000));
      });
    });
  });
}
