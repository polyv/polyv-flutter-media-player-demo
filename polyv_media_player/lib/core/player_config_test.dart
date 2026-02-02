import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/core/player_config.dart';

void main() {
  group('PlayerConfig', () {
    group('构造和基础属性', () {
      test('应正确创建包含所有必填字段的配置', () {
        const config = PlayerConfig(
          userId: 'test-user-id',
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: 'test-secret-key',
        );

        expect(config.userId, 'test-user-id');
        expect(config.readToken, 'test-read-token');
        expect(config.writeToken, 'test-write-token');
        expect(config.secretKey, 'test-secret-key');
      });

      test('应支持可选字段 env 和 businessLine', () {
        const config = PlayerConfig(
          userId: 'test-user-id',
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: 'test-secret-key',
          env: 'test',
          businessLine: 'vod',
        );

        expect(config.env, 'test');
        expect(config.businessLine, 'vod');
      });

      test('应支持 extra 扩展字段', () {
        final config = PlayerConfig(
          userId: 'test-user-id',
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: 'test-secret-key',
          extra: {'customField': 'customValue'},
        );

        expect(config.extra, {'customField': 'customValue'});
      });
    });

    group('JSON 序列化', () {
      test('toJson 应正确序列化所有字段', () {
        const config = PlayerConfig(
          userId: 'test-user-id',
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: 'test-secret-key',
          env: 'test',
          businessLine: 'vod',
        );

        final json = config.toJson();

        expect(json['userId'], 'test-user-id');
        expect(json['readToken'], 'test-read-token');
        expect(json['writeToken'], 'test-write-token');
        expect(json['secretKey'], 'test-secret-key');
        expect(json['env'], 'test');
        expect(json['businessLine'], 'vod');
      });

      test('fromJson 应正确反序列化所有字段', () {
        final json = {
          'userId': 'test-user-id',
          'readToken': 'test-read-token',
          'writeToken': 'test-write-token',
          'secretKey': 'test-secret-key',
          'env': 'test',
          'businessLine': 'vod',
        };

        final config = PlayerConfig.fromJson(json);

        expect(config.userId, 'test-user-id');
        expect(config.readToken, 'test-read-token');
        expect(config.writeToken, 'test-write-token');
        expect(config.secretKey, 'test-secret-key');
        expect(config.env, 'test');
        expect(config.businessLine, 'vod');
      });

      test('序列化和反序列化应保持数据一致性', () {
        const original = PlayerConfig(
          userId: 'test-user-id',
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: 'test-secret-key',
          env: 'test',
          businessLine: 'vod',
        );

        final json = original.toJson();
        final restored = PlayerConfig.fromJson(json);

        expect(restored, equals(original));
      });

      test('fromJson 应使用默认值处理缺失字段', () {
        final json = {
          'userId': 'test-user-id',
          'readToken': 'test-read-token',
          'writeToken': 'test-write-token',
          'secretKey': 'test-secret-key',
        };

        final config = PlayerConfig.fromJson(json);

        expect(config.env, isNull);
        expect(config.businessLine, isNull);
        expect(config.extra, isNull);
      });
    });

    group('校验', () {
      test(
        'isValid 当 userId 和 secretKey 有值时应返回 true（即使 read/write token 为空）',
        () {
          const config = PlayerConfig(
            userId: 'test-user-id',
            readToken: '',
            writeToken: '',
            secretKey: 'test-secret-key',
          );

          expect(config.isValid, isTrue);
        },
      );

      test('isValid 当 userId 或 secretKey 为空时应返回 false', () {
        const config1 = PlayerConfig(
          userId: '',
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: 'test-secret-key',
        );

        const config2 = PlayerConfig(
          userId: 'test-user-id',
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: '',
        );

        expect(config1.isValid, isFalse);
        expect(config2.isValid, isFalse);
      });

      test('validate 应只返回 userId 和 secretKey 的错误信息', () {
        const config = PlayerConfig(
          userId: '',
          readToken: '',
          writeToken: '',
          secretKey: '',
        );

        final errors = config.validate();

        expect(errors, contains('userId 不能为空'));
        expect(errors, contains('secretKey 不能为空'));
        expect(errors.length, 2);
      });

      test('validate 当配置有效时应返回空列表', () {
        const config = PlayerConfig(
          userId: 'test-user-id',
          readToken: '',
          writeToken: '',
          secretKey: 'test-secret-key',
        );

        final errors = config.validate();

        expect(errors, isEmpty);
      });
    });

    group('copyWith', () {
      test('应正确复制并修改指定字段', () {
        const original = PlayerConfig(
          userId: 'test-user-id',
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: 'test-secret-key',
        );

        final copy = original.copyWith(userId: 'new-user-id', env: 'prod');

        expect(copy.userId, 'new-user-id');
        expect(copy.readToken, original.readToken);
        expect(copy.writeToken, original.writeToken);
        expect(copy.secretKey, original.secretKey);
        expect(copy.env, 'prod');
      });

      test('不传参数时应保持原值', () {
        const original = PlayerConfig(
          userId: 'test-user-id',
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: 'test-secret-key',
        );

        final copy = original.copyWith();

        expect(copy, equals(original));
      });
    });

    group('相等性和哈希', () {
      test('相同配置的对象应相等', () {
        const config1 = PlayerConfig(
          userId: 'test-user-id',
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: 'test-secret-key',
        );

        const config2 = PlayerConfig(
          userId: 'test-user-id',
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: 'test-secret-key',
        );

        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('不同配置的对象不应相等', () {
        const config1 = PlayerConfig(
          userId: 'test-user-id',
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: 'test-secret-key',
        );

        const config2 = PlayerConfig(
          userId: 'other-user-id',
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: 'test-secret-key',
        );

        expect(config1, isNot(equals(config2)));
      });

      test('可选字段不同应导致对象不相等', () {
        const config1 = PlayerConfig(
          userId: 'test-user-id',
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: 'test-secret-key',
          env: 'test',
        );

        const config2 = PlayerConfig(
          userId: 'test-user-id',
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: 'test-secret-key',
        );

        expect(config1, isNot(equals(config2)));
      });
    });

    group('toString', () {
      test('应隐藏敏感信息', () {
        const config = PlayerConfig(
          userId: 'test-user-id',
          readToken: 'test-read-token',
          writeToken: 'test-write-token',
          secretKey: 'test-secret-key',
          env: 'test',
        );

        final str = config.toString();

        expect(str, contains('test-user-id'));
        expect(str, contains('test'));
        expect(str, contains('•••')); // 敏感信息被隐藏
        expect(str, isNot(contains('test-read-token')));
        expect(str, isNot(contains('test-write-token')));
        expect(str, isNot(contains('test-secret-key')));
      });

      test('空敏感信息时应显示为空而非隐藏标记', () {
        const config = PlayerConfig(
          userId: 'test-user-id',
          readToken: '',
          writeToken: '',
          secretKey: '',
        );

        final str = config.toString();

        expect(str, isNot(contains('•••')));
      });
    });
  });
}
