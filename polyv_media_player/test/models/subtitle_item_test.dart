import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/polyv_media_player.dart';

/// SubtitleItem 单元测试
///
/// 测试字幕数据模型的序列化、反序列化和相等性比较
void main() {
  group('SubtitleItem Tests', () {
    test('[P2] SubtitleItem fromJson 正确解析', () {
      final json = {'language': 'zh', 'label': '中文', 'url': null};

      final item = SubtitleItem.fromJson(json);

      expect(item.trackKey, 'zh'); // 旧格式兼容：trackKey = language
      expect(item.language, 'zh');
      expect(item.label, '中文');
      expect(item.url, isNull);
    });

    test('[P2] SubtitleItem fromJson 带 URL', () {
      final json = {
        'language': 'en',
        'label': 'English',
        'url': 'https://example.com/subtitle.vtt',
      };

      final item = SubtitleItem.fromJson(json);

      expect(item.trackKey, 'en'); // 旧格式兼容：trackKey = language
      expect(item.language, 'en');
      expect(item.label, 'English');
      expect(item.url, 'https://example.com/subtitle.vtt');
    });

    test('[P2] SubtitleItem fromJson 新格式包含 trackKey', () {
      final json = {
        'trackKey': '中文',
        'language': 'zh',
        'label': '中文',
        'isBilingual': false,
        'isDefault': true,
      };

      final item = SubtitleItem.fromJson(json);

      expect(item.trackKey, '中文');
      expect(item.language, 'zh');
      expect(item.label, '中文');
      expect(item.isBilingual, false);
      expect(item.isDefault, true);
    });

    test('[P2] SubtitleItem fromJson 双语字幕', () {
      final json = {
        'trackKey': '双语',
        'language': 'zh+en',
        'label': '中+英',
        'isBilingual': true,
        'isDefault': true,
      };

      final item = SubtitleItem.fromJson(json);

      expect(item.trackKey, '双语');
      expect(item.language, 'zh+en');
      expect(item.label, '中+英');
      expect(item.isBilingual, true);
      expect(item.isDefault, true);
    });

    test('[P2] SubtitleItem fromJson 处理缺失 url 字段', () {
      final json = {'language': 'zh', 'label': '中文'};

      final item = SubtitleItem.fromJson(json);

      expect(item.trackKey, 'zh'); // 旧格式兼容
      expect(item.language, 'zh');
      expect(item.label, '中文');
      expect(item.url, isNull);
    });

    test('[P2] SubtitleItem toJson 正确序列化', () {
      const item = SubtitleItem(
        trackKey: 'zh',
        language: 'zh',
        label: '中文',
        url: null,
      );

      final json = item.toJson();

      expect(json['trackKey'], 'zh');
      expect(json['language'], 'zh');
      expect(json['label'], '中文');
      expect(json['url'], isNull);
    });

    test('[P2] SubtitleItem toJson 带 URL', () {
      const item = SubtitleItem(
        trackKey: 'en',
        language: 'en',
        label: 'English',
        url: 'https://example.com/subtitle.vtt',
      );

      final json = item.toJson();

      expect(json['trackKey'], 'en');
      expect(json['language'], 'en');
      expect(json['label'], 'English');
      expect(json['url'], 'https://example.com/subtitle.vtt');
    });

    test('[P2] SubtitleItem toJson 包含双语标记', () {
      const item = SubtitleItem(
        trackKey: '双语',
        language: 'zh+en',
        label: '中+英',
        isBilingual: true,
        isDefault: true,
      );

      final json = item.toJson();

      expect(json['trackKey'], '双语');
      expect(json['language'], 'zh+en');
      expect(json['label'], '中+英');
      expect(json['isBilingual'], true);
      expect(json['isDefault'], true);
    });

    test('[P2] SubtitleItem 相等性比较', () {
      const item1 = SubtitleItem(
        trackKey: 'zh',
        language: 'zh',
        label: '中文',
        url: null,
      );

      const item2 = SubtitleItem(
        trackKey: 'zh',
        language: 'zh',
        label: '中文',
        url: null,
      );

      const item3 = SubtitleItem(
        trackKey: 'en',
        language: 'en',
        label: 'English',
        url: null,
      );

      expect(item1, equals(item2));
      expect(item1, isNot(equals(item3)));
    });

    test('[P2] SubtitleItem toString 返回 label', () {
      const item = SubtitleItem(trackKey: 'zh', language: 'zh', label: '中文');

      expect(item.toString(), '中文');
    });

    test('[P2] SubtitleItem hashCode 一致性', () {
      const item1 = SubtitleItem(
        trackKey: 'zh',
        language: 'zh',
        label: '中文',
        url: null,
      );

      const item2 = SubtitleItem(
        trackKey: 'zh',
        language: 'zh',
        label: '中文',
        url: null,
      );

      expect(item1.hashCode, equals(item2.hashCode));
    });

    test('[P2] SubtitleItem 不相等的各种情况', () {
      const base = SubtitleItem(
        trackKey: 'zh',
        language: 'zh',
        label: '中文',
        url: null,
      );

      const differentTrackKey = SubtitleItem(
        trackKey: 'zh-alt',
        language: 'zh',
        label: '中文',
        url: null,
      );

      const differentLanguage = SubtitleItem(
        trackKey: 'en',
        language: 'en',
        label: '中文',
        url: null,
      );

      const differentLabel = SubtitleItem(
        trackKey: 'zh',
        language: 'zh',
        label: 'English',
        url: null,
      );

      const differentUrl = SubtitleItem(
        trackKey: 'zh',
        language: 'zh',
        label: '中文',
        url: 'https://example.com',
      );

      const differentBilingual = SubtitleItem(
        trackKey: 'zh',
        language: 'zh',
        label: '中文',
        url: null,
        isBilingual: true,
      );

      expect(base, isNot(equals(differentTrackKey)));
      expect(base, isNot(equals(differentLanguage)));
      expect(base, isNot(equals(differentLabel)));
      expect(base, isNot(equals(differentUrl)));
      expect(base, isNot(equals(differentBilingual)));
    });

    test('[P2] 多个字幕项列表', () {
      final jsonList = [
        {'language': 'zh', 'label': '中文', 'url': null},
        {'language': 'en', 'label': 'English', 'url': null},
        {'language': 'ja', 'label': '日本語', 'url': null},
      ];

      final items = jsonList
          .map((json) => SubtitleItem.fromJson(json))
          .toList();

      expect(items.length, 3);
      expect(items[0].label, '中文');
      expect(items[1].label, 'English');
      expect(items[2].label, '日本語');
    });

    test('[P2] SubtitleItem.bilingual 工厂方法', () {
      final item = SubtitleItem.bilingual(trackKey: '双语', label: '中+英');

      expect(item.trackKey, '双语');
      expect(item.language, 'zh+en');
      expect(item.label, '中+英');
      expect(item.isBilingual, true);
      expect(item.isDefault, true);
    });
  });
}
