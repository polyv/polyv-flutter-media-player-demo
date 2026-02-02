import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/polyv_media_player.dart';

/// QualityItem 单元测试
///
/// 测试清晰度数据模型的序列化、反序列化和相等性比较
void main() {
  group('QualityItem Tests', () {
    test('[P2] QualityItem fromJson 正确解析', () {
      final json = {
        'description': '1080P 高清',
        'value': '1080p',
        'isAvailable': true,
      };

      final item = QualityItem.fromJson(json);

      expect(item.description, '1080P 高清');
      expect(item.value, '1080p');
      expect(item.isAvailable, true);
    });

    test('[P2] QualityItem fromJson 处理缺失 isAvailable', () {
      final json = {'description': '720P 标清', 'value': '720p'};

      final item = QualityItem.fromJson(json);

      expect(item.description, '720P 标清');
      expect(item.value, '720p');
      expect(item.isAvailable, true); // 默认值
    });

    test('[P2] QualityItem fromJson 处理不可用清晰度', () {
      final json = {
        'description': '4K 超清',
        'value': '4k',
        'isAvailable': false,
      };

      final item = QualityItem.fromJson(json);

      expect(item.description, '4K 超清');
      expect(item.value, '4k');
      expect(item.isAvailable, false);
    });

    test('[P2] QualityItem toJson 正确序列化', () {
      const item = QualityItem(
        description: '4K 超清',
        value: '4k',
        isAvailable: true,
      );

      final json = item.toJson();

      expect(json['description'], '4K 超清');
      expect(json['value'], '4k');
      expect(json['isAvailable'], true);
    });

    test('[P2] QualityItem 相等性比较', () {
      const item1 = QualityItem(
        description: '1080P 高清',
        value: '1080p',
        isAvailable: true,
      );

      const item2 = QualityItem(
        description: '1080P 高清',
        value: '1080p',
        isAvailable: true,
      );

      const item3 = QualityItem(
        description: '720P 标清',
        value: '720p',
        isAvailable: true,
      );

      expect(item1, equals(item2));
      expect(item1, isNot(equals(item3)));
    });

    test('[P2] QualityItem 不相等的各种情况', () {
      const base = QualityItem(
        description: '1080P 高清',
        value: '1080p',
        isAvailable: true,
      );

      const differentDescription = QualityItem(
        description: '720P 标清',
        value: '1080p',
        isAvailable: true,
      );

      const differentValue = QualityItem(
        description: '1080P 高清',
        value: '720p',
        isAvailable: true,
      );

      const differentAvailability = QualityItem(
        description: '1080P 高清',
        value: '1080p',
        isAvailable: false,
      );

      expect(base, isNot(equals(differentDescription)));
      expect(base, isNot(equals(differentValue)));
      expect(base, isNot(equals(differentAvailability)));
    });

    test('[P2] QualityItem toString 返回 description', () {
      const item = QualityItem(description: '1080P 高清', value: '1080p');

      expect(item.toString(), '1080P 高清');
    });

    test('[P2] QualityItem hashCode 一致性', () {
      const item1 = QualityItem(
        description: '1080P 高清',
        value: '1080p',
        isAvailable: true,
      );

      const item2 = QualityItem(
        description: '1080P 高清',
        value: '1080p',
        isAvailable: true,
      );

      expect(item1.hashCode, equals(item2.hashCode));
    });

    test('[P2] QualityItem 所有清晰度标签', () {
      final qualities = [
        {'description': '4K 超清', 'value': '4k'},
        {'description': '1080P 高清', 'value': '1080p'},
        {'description': '720P 标清', 'value': '720p'},
        {'description': '480P 流畅', 'value': '480p'},
        {'description': '360P 极速', 'value': '360p'},
        {'description': '自动', 'value': 'auto'},
      ];

      for (final q in qualities) {
        final item = QualityItem.fromJson(q);
        expect(item.description, q['description']);
        expect(item.value, q['value']);
      }
    });

    test('[P2] 不可用清晰度的视觉反馈', () {
      const available = QualityItem(
        description: '1080P 高清',
        value: '1080p',
        isAvailable: true,
      );

      const unavailable = QualityItem(
        description: '4K 超清',
        value: '4k',
        isAvailable: false,
      );

      expect(available.isAvailable, true);
      expect(unavailable.isAvailable, false);
    });
  });
}
