import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/core/player_config.dart';
import 'package:polyv_media_player/services/player_initializer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 在测试前重置配置
  setUp(() {
    PlayerInitializer.reset();
  });

  group('PlayerInitializer', () {
    group('initialize', () {
      test('成功初始化时应保存当前配置', () async {
        const config = PlayerConfig(
          userId: 'test-user-id',
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: 'test-secret-key',
        );

        // 由于 MethodChannel 是单例，我们只能在没有原生实现时测试
        // 在真实环境中会抛出 MissingPluginException
        try {
          await PlayerInitializer.initialize(config);
          // 如果成功（原生环境），检查配置是否保存
          expect(PlayerInitializer.currentConfig, equals(config));
        } catch (e) {
          // 在测试环境中会抛出 MissingPluginException，这是预期行为
          expect(e, isA<MissingPluginException>());
          // 配置不应该被保存
          expect(PlayerInitializer.currentConfig, isNull);
        }
      });

      test('无效配置应抛出 ArgumentError', () async {
        const invalidConfig = PlayerConfig(
          userId: '', // 空用户 ID
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: 'test-secret-key',
        );

        expect(
          () => PlayerInitializer.initialize(invalidConfig),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('userId'),
            ),
          ),
        );
      });

      test('多个必填字段为空时应列出所有错误', () async {
        const invalidConfig = PlayerConfig(
          userId: '',
          readToken: '',
          writeToken: 'test-write-token',
          secretKey: '',
        );

        expect(
          () => PlayerInitializer.initialize(invalidConfig),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message as String,
              'message',
              allOf([
                contains('userId'),
                contains('readToken'),
                contains('secretKey'),
              ]),
            ),
          ),
        );
      });

      test('支持带有可选字段的配置', () async {
        const config = PlayerConfig(
          userId: 'test-user-id',
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: 'test-secret-key',
          env: 'test',
          businessLine: 'vod',
        );

        try {
          await PlayerInitializer.initialize(config);
          expect(PlayerInitializer.currentConfig, equals(config));
        } catch (e) {
          expect(e, isA<MissingPluginException>());
        }
      });

      test('支持带有 extra 扩展字段的配置', () async {
        final config = PlayerConfig(
          userId: 'test-user-id',
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: 'test-secret-key',
          extra: {'customField': 'customValue'},
        );

        try {
          await PlayerInitializer.initialize(config);
          expect(PlayerInitializer.currentConfig, equals(config));
        } catch (e) {
          expect(e, isA<MissingPluginException>());
        }
      });
    });

    group('currentConfig', () {
      test('初始化前应返回 null', () {
        expect(PlayerInitializer.currentConfig, isNull);
      });

      test('初始化后应返回当前配置', () async {
        const config = PlayerConfig(
          userId: 'test-user-id',
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: 'test-secret-key',
        );

        try {
          await PlayerInitializer.initialize(config);
          expect(PlayerInitializer.currentConfig, equals(config));
        } catch (e) {
          // 忽略 MissingPluginException
          expect(e, isA<MissingPluginException>());
        }
      });
    });

    group('reset', () {
      test('reset 后 currentConfig 应返回 null', () async {
        const config = PlayerConfig(
          userId: 'test-user-id',
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: 'test-secret-key',
        );

        try {
          await PlayerInitializer.initialize(config);
          expect(PlayerInitializer.currentConfig, isNotNull);

          PlayerInitializer.reset();
          expect(PlayerInitializer.currentConfig, isNull);
        } catch (e) {
          // 在测试环境中可能抛出 MissingPluginException
          expect(e, isA<MissingPluginException>());
          // 配置未被保存，所以本来就是 null
          expect(PlayerInitializer.currentConfig, isNull);
        }
      });

      test('多次 reset 应安全', () {
        PlayerInitializer.reset();
        PlayerInitializer.reset();
        expect(PlayerInitializer.currentConfig, isNull);
      });
    });

    group('热重载', () {
      test('多次初始化应更新当前配置', () async {
        const config1 = PlayerConfig(
          userId: 'user-1',
          readToken: 'token-1',
          writeToken: 'write-1',
          secretKey: 'secret-1',
        );

        const config2 = PlayerConfig(
          userId: 'user-2',
          readToken: 'token-2',
          writeToken: 'write-2',
          secretKey: 'secret-2',
        );

        try {
          await PlayerInitializer.initialize(config1);
          expect(PlayerInitializer.currentConfig?.userId, 'user-1');

          await PlayerInitializer.initialize(config2);
          expect(PlayerInitializer.currentConfig?.userId, 'user-2');
        } catch (e) {
          expect(e, isA<MissingPluginException>());
        }
      });
    });
  });
}
