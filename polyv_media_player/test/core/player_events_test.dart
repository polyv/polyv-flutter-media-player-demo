import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/polyv_media_player.dart';

/// PlayerEvents 单元测试
///
/// 测试播放器事件类、QualityItem 和 SubtitleItem
void main() {
  group('PlayerEventType', () {
    test('[P2] 所有事件类型存在', () {
      // GIVEN: PlayerEventType 枚举
      // WHEN: 访问所有枚举值
      // THEN: 所有值都应该存在
      expect(PlayerEventType.stateChanged, isNotNull);
      expect(PlayerEventType.progress, isNotNull);
      expect(PlayerEventType.error, isNotNull);
      expect(PlayerEventType.qualityChanged, isNotNull);
      expect(PlayerEventType.subtitleChanged, isNotNull);
      expect(PlayerEventType.completed, isNotNull);
    });
  });

  group('QualityItem', () {
    test('[P1] 使用基础构造函数创建', () {
      // GIVEN: 清晰度属性
      const description = '超清';
      const value = '1080p';

      // WHEN: 创建 QualityItem
      final quality = QualityItem(description: description, value: value);

      // THEN: 应该包含正确的属性
      expect(quality.description, description);
      expect(quality.value, value);
      expect(quality.isAvailable, isTrue); // 默认值
    });

    test('[P1] 创建不可用的清晰度', () {
      // WHEN: 创建不可用的清晰度
      final quality = QualityItem(
        description: '4K',
        value: '2160p',
        isAvailable: false,
      );

      // THEN: isAvailable 应该为 false
      expect(quality.isAvailable, isFalse);
    });

    test('[P1] 从 JSON 创建 QualityItem', () {
      // GIVEN: JSON 数据
      final json = {'description': '高清', 'value': '720p', 'isAvailable': true};

      // WHEN: 从 JSON 创建
      final quality = QualityItem.fromJson(json);

      // THEN: 应该包含正确的属性
      expect(quality.description, '高清');
      expect(quality.value, '720p');
      expect(quality.isAvailable, isTrue);
    });

    test('[P1] 从 JSON 创建时 isAvailable 默认为 true', () {
      // GIVEN: 没有 isAvailable 字段的 JSON
      final json = {'description': '标清', 'value': '480p'};

      // WHEN: 从 JSON 创建
      final quality = QualityItem.fromJson(json);

      // THEN: isAvailable 应该默认为 true
      expect(quality.isAvailable, isTrue);
    });

    test('[P1] 转换为 JSON', () {
      // GIVEN: QualityItem
      const quality = QualityItem(
        description: '超清',
        value: '1080p',
        isAvailable: true,
      );

      // WHEN: 转换为 JSON
      final json = quality.toJson();

      // THEN: 应该包含所有属性
      expect(json['description'], '超清');
      expect(json['value'], '1080p');
      expect(json['isAvailable'], isTrue);
    });

    test('[P2] toString 返回描述', () {
      // GIVEN: QualityItem
      const quality = QualityItem(description: '高清', value: '720p');

      // WHEN: 调用 toString
      final str = quality.toString();

      // THEN: 应该返回描述
      expect(str, '高清');
    });

    test('[P2] 相同属性的 QualityItem 相等', () {
      // GIVEN: 两个相同的 QualityItem
      const quality1 = QualityItem(
        description: '超清',
        value: '1080p',
        isAvailable: true,
      );
      const quality2 = QualityItem(
        description: '超清',
        value: '1080p',
        isAvailable: true,
      );

      // THEN: 应该相等
      expect(quality1, equals(quality2));
      expect(quality1.hashCode, equals(quality2.hashCode));
    });

    test('[P2] 不同属性的 QualityItem 不相等', () {
      // GIVEN: 两个不同的 QualityItem
      const quality1 = QualityItem(description: '超清', value: '1080p');
      const quality2 = QualityItem(description: '高清', value: '720p');

      // THEN: 不应该相等
      expect(quality1, isNot(equals(quality2)));
    });
  });

  group('SubtitleItem', () {
    test('[P1] 使用基础构造函数创建', () {
      // GIVEN: 字幕属性
      const trackKey = 'zh';
      const language = 'zh';
      const label = '中文';

      // WHEN: 创建 SubtitleItem
      final subtitle = SubtitleItem(
        trackKey: trackKey,
        language: language,
        label: label,
      );

      // THEN: 应该包含正确的属性
      expect(subtitle.trackKey, trackKey);
      expect(subtitle.language, language);
      expect(subtitle.label, label);
      expect(subtitle.url, isNull); // 可选参数
    });

    test('[P1] 创建带 URL 的字幕', () {
      // GIVEN: 带 URL 的字幕
      const url = 'https://example.com/subtitle_zh.vtt';

      // WHEN: 创建 SubtitleItem
      final subtitle = SubtitleItem(
        trackKey: 'zh',
        language: 'zh',
        label: '中文',
        url: url,
      );

      // THEN: 应该包含 URL
      expect(subtitle.url, url);
    });

    test('[P1] 创建双语字幕', () {
      // WHEN: 创建双语 SubtitleItem
      final subtitle = SubtitleItem(
        trackKey: '双语',
        language: 'zh+en',
        label: '中+英',
        isBilingual: true,
        isDefault: true,
      );

      // THEN: 应该包含正确的属性
      expect(subtitle.trackKey, '双语');
      expect(subtitle.language, 'zh+en');
      expect(subtitle.label, '中+英');
      expect(subtitle.isBilingual, true);
      expect(subtitle.isDefault, true);
    });

    test('[P1] 从 JSON 创建 SubtitleItem（新格式）', () {
      // GIVEN: JSON 数据（新格式）
      final json = {
        'trackKey': '中文',
        'language': 'zh',
        'label': '中文',
        'url': 'https://example.com/subtitle_zh.vtt',
      };

      // WHEN: 从 JSON 创建
      final subtitle = SubtitleItem.fromJson(json);

      // THEN: 应该包含正确的属性
      expect(subtitle.trackKey, '中文');
      expect(subtitle.language, 'zh');
      expect(subtitle.label, '中文');
      expect(subtitle.url, 'https://example.com/subtitle_zh.vtt');
    });

    test('[P1] 从 JSON 创建（旧格式兼容）', () {
      // GIVEN: 没有 trackKey 字段的 JSON（旧格式）
      final json = {'language': 'zh', 'label': '中文'};

      // WHEN: 从 JSON 创建
      final subtitle = SubtitleItem.fromJson(json);

      // THEN: trackKey 应该默认为 language，URL 应该为 null
      expect(subtitle.trackKey, 'zh');
      expect(subtitle.url, isNull);
    });

    test('[P1] 转换为 JSON', () {
      // GIVEN: SubtitleItem
      const subtitle = SubtitleItem(
        trackKey: 'en',
        language: 'en',
        label: 'English',
        url: 'https://example.com/subtitle.vtt',
      );

      // WHEN: 转换为 JSON
      final json = subtitle.toJson();

      // THEN: 应该包含所有属性
      expect(json['trackKey'], 'en');
      expect(json['language'], 'en');
      expect(json['label'], 'English');
      expect(json['url'], 'https://example.com/subtitle.vtt');
    });

    test('[P1] 转换为 JSON 时不包含 null URL', () {
      // GIVEN: 没有 URL 的 SubtitleItem
      const subtitle = SubtitleItem(
        trackKey: 'zh',
        language: 'zh',
        label: '中文',
      );

      // WHEN: 转换为 JSON
      final json = subtitle.toJson();

      // THEN: JSON 中不应该包含 URL
      expect(json.containsKey('url'), isFalse);
    });

    test('[P2] toString 返回标签', () {
      // GIVEN: SubtitleItem
      const subtitle = SubtitleItem(
        trackKey: 'zh',
        language: 'zh',
        label: '中文字幕',
      );

      // WHEN: 调用 toString
      final str = subtitle.toString();

      // THEN: 应该返回标签
      expect(str, '中文字幕');
    });

    test('[P2] 相同属性的 SubtitleItem 相等', () {
      // GIVEN: 两个相同的 SubtitleItem
      const subtitle1 = SubtitleItem(
        trackKey: 'zh',
        language: 'zh',
        label: '中文',
        url: 'https://example.com/subtitle.vtt',
      );
      const subtitle2 = SubtitleItem(
        trackKey: 'zh',
        language: 'zh',
        label: '中文',
        url: 'https://example.com/subtitle.vtt',
      );

      // THEN: 应该相等
      expect(subtitle1, equals(subtitle2));
      expect(subtitle1.hashCode, equals(subtitle2.hashCode));
    });

    test('[P2] 不同属性的 SubtitleItem 不相等', () {
      // GIVEN: 两个不同的 SubtitleItem
      const subtitle1 = SubtitleItem(
        trackKey: 'zh',
        language: 'zh',
        label: '中文',
      );
      const subtitle2 = SubtitleItem(
        trackKey: 'en',
        language: 'en',
        label: 'English',
      );

      // THEN: 不应该相等
      expect(subtitle1, isNot(equals(subtitle2)));
    });

    test('[P2] trackKey 不同时不相等', () {
      // GIVEN: trackKey 不同
      const subtitle1 = SubtitleItem(
        trackKey: 'zh',
        language: 'zh',
        label: '中文',
      );
      const subtitle2 = SubtitleItem(
        trackKey: 'zh-alt',
        language: 'zh',
        label: '中文',
      );

      // THEN: 不应该相等
      expect(subtitle1, isNot(equals(subtitle2)));
    });

    test('[P2] isBilingual 不同时不相等', () {
      // GIVEN: 双语标记不同
      const subtitle1 = SubtitleItem(
        trackKey: 'zh',
        language: 'zh',
        label: '中文',
        isBilingual: true,
      );
      const subtitle2 = SubtitleItem(
        trackKey: 'zh',
        language: 'zh',
        label: '中文',
        isBilingual: false,
      );

      // THEN: 不应该相等
      expect(subtitle1, isNot(equals(subtitle2)));
    });

    test('[P2] bilingual 工厂方法', () {
      // WHEN: 使用 bilingual 工厂方法
      final subtitle = SubtitleItem.bilingual(trackKey: '双语', label: '中+英');

      // THEN: 应该创建正确的双语字幕
      expect(subtitle.trackKey, '双语');
      expect(subtitle.language, 'zh+en');
      expect(subtitle.label, '中+英');
      expect(subtitle.isBilingual, true);
      expect(subtitle.isDefault, true);
    });
  });

  group('StateChangedEvent', () {
    test('[P1] 创建状态变化事件', () {
      // GIVEN: 新状态
      const newState = PlayerLoadingState.playing;

      // WHEN: 创建 StateChangedEvent
      final event = StateChangedEvent(newState);

      // THEN: 应该包含正确的类型和状态
      expect(event.type, PlayerEventType.stateChanged);
      expect(event.state, newState);
    });
  });

  group('ProgressEvent', () {
    test('[P1] 创建进度事件', () {
      // GIVEN: 进度数据
      const position = 30000;
      const duration = 300000;
      const bufferedPosition = 60000;

      // WHEN: 创建 ProgressEvent
      final event = ProgressEvent(
        position: position,
        duration: duration,
        bufferedPosition: bufferedPosition,
      );

      // THEN: 应该包含正确的数据
      expect(event.type, PlayerEventType.progress);
      expect(event.position, position);
      expect(event.duration, duration);
      expect(event.bufferedPosition, bufferedPosition);
    });
  });

  group('ErrorEvent', () {
    test('[P1] 创建错误事件', () {
      // GIVEN: 错误数据
      const code = 'NETWORK_ERROR';
      const message = 'Connection failed';

      // WHEN: 创建 ErrorEvent
      final event = ErrorEvent(code: code, message: message);

      // THEN: 应该包含正确的错误信息
      expect(event.type, PlayerEventType.error);
      expect(event.code, code);
      expect(event.message, message);
      expect(event.details, isNull);
    });

    test('[P1] 创建带详情的错误事件', () {
      // GIVEN: 错误数据和详情
      const code = 'PLAYER_ERROR';
      const message = 'Playback failed';
      final details = {'retryable': false};

      // WHEN: 创建带详情的 ErrorEvent
      final event = ErrorEvent(code: code, message: message, details: details);

      // THEN: 应该包含详情
      expect(event.details, details);
    });
  });

  group('QualityChangedEvent', () {
    test('[P1] 创建清晰度变化事件', () {
      // GIVEN: 清晰度列表
      final qualities = [
        const QualityItem(description: '超清', value: '1080p'),
        const QualityItem(description: '高清', value: '720p'),
      ];
      const currentIndex = 0;

      // WHEN: 创建 QualityChangedEvent
      final event = QualityChangedEvent(
        qualities: qualities,
        currentIndex: currentIndex,
      );

      // THEN: 应该包含正确的数据
      expect(event.type, PlayerEventType.qualityChanged);
      expect(event.qualities, qualities);
      expect(event.qualities.length, 2);
      expect(event.currentIndex, currentIndex);
    });
  });

  group('SubtitleChangedEvent', () {
    test('[P1] 创建字幕变化事件', () {
      // GIVEN: 字幕列表
      final subtitles = [
        const SubtitleItem(trackKey: 'zh', language: 'zh', label: '中文'),
        const SubtitleItem(trackKey: 'en', language: 'en', label: 'English'),
      ];
      const currentIndex = 0;

      // WHEN: 创建 SubtitleChangedEvent
      final event = SubtitleChangedEvent(
        subtitles: subtitles,
        currentIndex: currentIndex,
      );

      // THEN: 应该包含正确的数据
      expect(event.type, PlayerEventType.subtitleChanged);
      expect(event.subtitles, subtitles);
      expect(event.subtitles.length, 2);
      expect(event.currentIndex, currentIndex);
    });

    test('[P1] currentIndex 为 -1 表示关闭字幕', () {
      // WHEN: 创建关闭字幕的事件
      final event = SubtitleChangedEvent(subtitles: [], currentIndex: -1);

      // THEN: currentIndex 应该为 -1
      expect(event.currentIndex, -1);
    });

    test('[P1] 双语字幕事件', () {
      // GIVEN: 包含双语字幕的字幕列表
      final subtitles = [
        const SubtitleItem(
          trackKey: '双语',
          language: 'zh+en',
          label: '中+英',
          isBilingual: true,
          isDefault: true,
        ),
        const SubtitleItem(trackKey: 'zh', language: 'zh', label: '中文'),
        const SubtitleItem(trackKey: 'en', language: 'en', label: 'English'),
      ];

      // WHEN: 创建 SubtitleChangedEvent
      final event = SubtitleChangedEvent(subtitles: subtitles, currentIndex: 0);

      // THEN: 应该包含双语字幕
      expect(event.subtitles.length, 3);
      expect(event.subtitles[0].isBilingual, true);
      expect(event.subtitles[0].isDefault, true);
    });
  });

  group('CompletedEvent', () {
    test('[P1] 创建播放完成事件', () {
      // WHEN: 创建 CompletedEvent
      final event = CompletedEvent();

      // THEN: 应该有正确的类型
      expect(event.type, PlayerEventType.completed);
    });
  });
}
