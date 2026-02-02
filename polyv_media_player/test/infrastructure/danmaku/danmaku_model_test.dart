import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/infrastructure/danmaku/danmaku_model.dart';

/// [P1] Danmaku Model 单元测试
///
/// 测试弹幕数据模型的核心功能
void main() {
  group('DanmakuType', () {
    test('[P1] should have correct enum values', () {
      // GIVEN: DanmakuType 枚举
      // THEN: 包含所有预期的类型
      expect(DanmakuType.scroll, isNotNull);
      expect(DanmakuType.top, isNotNull);
      expect(DanmakuType.bottom, isNotNull);
    });

    test('[P1] should convert enum to string correctly', () {
      // GIVEN: DanmakuType 枚举值
      // WHEN: 获取 name 属性
      // THEN: 返回正确的字符串值
      expect(DanmakuType.scroll.name, 'scroll');
      expect(DanmakuType.top.name, 'top');
      expect(DanmakuType.bottom.name, 'bottom');
    });
  });

  group('DanmakuFontSize', () {
    test('[P1] should have correct enum values', () {
      // GIVEN: DanmakuFontSize 枚举
      // THEN: 包含所有预期的字号
      expect(DanmakuFontSize.small, isNotNull);
      expect(DanmakuFontSize.medium, isNotNull);
      expect(DanmakuFontSize.large, isNotNull);
    });
  });

  group('Danmaku', () {
    test('[P0] should create Danmaku with required parameters', () {
      // GIVEN: 创建弹幕所需的参数
      const id = 'test_danmaku_1';
      const text = 'Test danmaku';
      const time = 1000;

      // WHEN: 创建 Danmaku 实例
      const danmaku = Danmaku(id: id, text: text, time: time);

      // THEN: 弹幕属性正确设置
      expect(danmaku.id, id);
      expect(danmaku.text, text);
      expect(danmaku.time, time);
      expect(danmaku.type, DanmakuType.scroll); // 默认滚动
      expect(danmaku.color, isNull); // 默认无颜色
    });

    test('[P1] should create Danmaku with optional parameters', () {
      // GIVEN: 创建弹幕所需的全部参数
      const id = 'test_danmaku_2';
      const text = 'Colored danmaku';
      const time = 2000;
      const color = Color(0xFFFF0000);
      const type = DanmakuType.top;

      // WHEN: 创建包含可选参数的 Danmaku 实例
      const danmaku = Danmaku(
        id: id,
        text: text,
        time: time,
        color: color,
        type: type,
      );

      // THEN: 所有属性正确设置
      expect(danmaku.id, id);
      expect(danmaku.text, text);
      expect(danmaku.time, time);
      expect(danmaku.color, color);
      expect(danmaku.type, type);
    });

    test('[P1] should deserialize from JSON correctly', () {
      // GIVEN: JSON 格式的弹幕数据
      final json = {
        'id': 'json_danmaku_1',
        'text': 'JSON danmaku',
        'time': 5000,
        'color': '0xFF00FF',
        'type': 'top',
      };

      // WHEN: 从 JSON 创建 Danmaku
      final danmaku = Danmaku.fromJson(json);

      // THEN: 正确解析所有字段
      expect(danmaku.id, 'json_danmaku_1');
      expect(danmaku.text, 'JSON danmaku');
      expect(danmaku.time, 5000);
      expect(
        danmaku.color,
        const Color(0xFFFF00FF),
      ); // 0xFFFF00FF = magenta (alpha=FF, red=00, green=FF, blue=FF)
      expect(danmaku.type, DanmakuType.top);
    });

    test('[P1] should deserialize from JSON with default values', () {
      // GIVEN: 不包含可选字段的 JSON
      final json = {'id': 'minimal_danmaku', 'text': 'Minimal', 'time': 1000};

      // WHEN: 从 JSON 创建 Danmaku
      final danmaku = Danmaku.fromJson(json);

      // THEN: 使用默认值
      expect(danmaku.id, 'minimal_danmaku');
      expect(danmaku.text, 'Minimal');
      expect(danmaku.time, 1000);
      expect(danmaku.color, isNull);
      expect(danmaku.type, DanmakuType.scroll);
    });

    test('[P1] should serialize to JSON correctly', () {
      // GIVEN: 一个 Danmaku 实例
      const danmaku = Danmaku(
        id: 'serialize_test',
        text: 'Serialize me',
        time: 3000,
        color: Color(0xFFFF0000),
        type: DanmakuType.bottom,
      );

      // WHEN: 转换为 JSON
      final json = danmaku.toJson();

      // THEN: JSON 包含所有字段
      expect(json['id'], 'serialize_test');
      expect(json['text'], 'Serialize me');
      expect(json['time'], 3000);
      expect(json['color'], isNotNull); // ARGB32 转十六进制
      expect(json['type'], 'bottom');
    });

    test('[P1] should copy with modified properties', () {
      // GIVEN: 原始 Danmaku
      const original = Danmaku(
        id: 'original',
        text: 'Original text',
        time: 1000,
      );

      // WHEN: 使用 copyWith 修改部分属性
      final modified = original.copyWith(
        text: 'Modified text',
        type: DanmakuType.top,
      );

      // THEN: 新实例包含修改后的值，未修改的值保持不变
      expect(modified.id, 'original'); // 未修改
      expect(modified.text, 'Modified text'); // 已修改
      expect(modified.time, 1000); // 未修改
      expect(modified.type, DanmakuType.top); // 已修改
    });

    test('[P1] should compare equality correctly', () {
      // GIVEN: 两个属性相同的 Danmaku
      const danmaku1 = Danmaku(
        id: 'same',
        text: 'Same text',
        time: 1000,
        color: Color(0xFFFF0000),
        type: DanmakuType.scroll,
      );

      const danmaku2 = Danmaku(
        id: 'same',
        text: 'Same text',
        time: 1000,
        color: Color(0xFFFF0000),
        type: DanmakuType.scroll,
      );

      // THEN: 两个实例相等
      expect(danmaku1, equals(danmaku2));
      expect(danmaku1.hashCode, equals(danmaku2.hashCode));
    });

    test('[P1] should not be equal when properties differ', () {
      // GIVEN: 两个属性不同的 Danmaku
      const danmaku1 = Danmaku(id: '1', text: 'Text 1', time: 1000);

      const danmaku2 = Danmaku(id: '2', text: 'Text 2', time: 2000);

      // THEN: 两个实例不相等
      expect(danmaku1, isNot(equals(danmaku2)));
    });

    test('[P2] should parse color with # prefix', () {
      // GIVEN: 带 # 前缀的颜色字符串
      const json = {
        'id': 'color_test',
        'text': 'Test',
        'time': 1000,
        'color': '#FF00FF',
      };

      // WHEN: 从 JSON 创建
      final danmaku = Danmaku.fromJson(json);

      // THEN: 颜色正确解析
      expect(danmaku.color, const Color(0xFF000000 | 0xFF00FF));
    });

    test('[P2] should handle invalid color gracefully', () {
      // GIVEN: 无效的颜色字符串
      const json = {
        'id': 'invalid_color',
        'text': 'Test',
        'time': 1000,
        'color': 'invalid',
      };

      // WHEN: 从 JSON 创建
      final danmaku = Danmaku.fromJson(json);

      // THEN: 颜色为 null（使用默认）
      expect(danmaku.color, isNull);
    });

    test('[P2] should handle invalid type gracefully', () {
      // GIVEN: 无效的类型字符串
      const json = {
        'id': 'invalid_type',
        'text': 'Test',
        'time': 1000,
        'type': 'invalid_type',
      };

      // WHEN: 从 JSON 创建
      final danmaku = Danmaku.fromJson(json);

      // THEN: 使用默认类型（scroll）
      expect(danmaku.type, DanmakuType.scroll);
    });

    test('[P1] should convert to string correctly', () {
      // GIVEN: 一个 Danmaku 实例
      const danmaku = Danmaku(
        id: 'to_string',
        text: 'String test',
        time: 5000,
        type: DanmakuType.top,
      );

      // WHEN: 调用 toString
      final str = danmaku.toString();

      // THEN: 字符串包含关键信息
      expect(str, contains('to_string'));
      expect(str, contains('String test'));
      expect(str, contains('5000'));
      expect(str, contains('top'));
    });
  });

  group('ActiveDanmaku', () {
    test('[P0] should create ActiveDanmaku with required parameters', () {
      // GIVEN: 创建活跃弹幕所需的参数
      const id = 'active_1';
      const text = 'Active danmaku';
      const time = 1000;
      const track = 2;
      const startTime = 50000;

      // WHEN: 创建 ActiveDanmaku 实例
      const activeDanmaku = ActiveDanmaku(
        id: id,
        text: text,
        time: time,
        track: track,
        startTime: startTime,
      );

      // THEN: 属性正确设置
      expect(activeDanmaku.id, id);
      expect(activeDanmaku.text, text);
      expect(activeDanmaku.time, time);
      expect(activeDanmaku.track, track);
      expect(activeDanmaku.startTime, startTime);
      expect(activeDanmaku.type, DanmakuType.scroll); // 继承默认值
    });

    test('[P1] should create from Danmaku', () {
      // GIVEN: 一个普通 Danmaku
      const danmaku = Danmaku(
        id: 'base_danmaku',
        text: 'Base text',
        time: 3000,
        color: Color(0xFF00FF00),
        type: DanmakuType.bottom,
      );
      const track = 5;
      const startTime = 60000;

      // WHEN: 从 Danmaku 创建 ActiveDanmaku
      final activeDanmaku = ActiveDanmaku.fromDanmaku(
        danmaku,
        track: track,
        startTime: startTime,
      );

      // THEN: 继承所有属性并添加活跃状态属性
      expect(activeDanmaku.id, 'base_danmaku');
      expect(activeDanmaku.text, 'Base text');
      expect(activeDanmaku.time, 3000);
      expect(activeDanmaku.color, const Color(0xFF00FF00));
      expect(activeDanmaku.type, DanmakuType.bottom);
      expect(activeDanmaku.track, track);
      expect(activeDanmaku.startTime, startTime);
    });

    test('[P1] should check expiration correctly', () {
      // GIVEN: 一个 ActiveDanmaku
      const activeDanmaku = ActiveDanmaku(
        id: 'expire_test',
        text: 'Test',
        time: 1000,
        track: 0,
        startTime: 10000,
      );

      // WHEN: 检查不同时间点的过期状态
      // THEN: 正确判断是否过期（animationDuration = 10000ms）
      // 未过期（过 9000ms）
      expect(activeDanmaku.isExpired(19000), isFalse);
      // 刚过期（过 10000ms）
      expect(activeDanmaku.isExpired(20000), isTrue);
      // 已过期（过 11000ms）
      expect(activeDanmaku.isExpired(21000), isTrue);
    });

    test('[P1] should compare equality correctly', () {
      // GIVEN: 两个属性相同的 ActiveDanmaku
      const active1 = ActiveDanmaku(
        id: 'same_active',
        text: 'Same',
        time: 1000,
        track: 1,
        startTime: 10000,
      );

      const active2 = ActiveDanmaku(
        id: 'same_active',
        text: 'Same',
        time: 1000,
        track: 1,
        startTime: 10000,
      );

      // THEN: 相等
      expect(active1, equals(active2));
      expect(active1.hashCode, equals(active2.hashCode));
    });

    test('[P1] should not be equal when active properties differ', () {
      // GIVEN: track 不同的两个 ActiveDanmaku
      const active1 = ActiveDanmaku(
        id: 'same',
        text: 'Same',
        time: 1000,
        track: 1,
        startTime: 10000,
      );

      const active2 = ActiveDanmaku(
        id: 'same',
        text: 'Same',
        time: 1000,
        track: 2,
        startTime: 10000,
      );

      // THEN: 不相等
      expect(active1, isNot(equals(active2)));
    });

    test('[P1] should copy with all properties', () {
      // GIVEN: 原始 ActiveDanmaku
      const original = ActiveDanmaku(
        id: 'original',
        text: 'Original',
        time: 1000,
        track: 0,
        startTime: 10000,
      );

      // WHEN: 使用 copyWith 修改 track
      final modified = original.copyWith(track: 3) as ActiveDanmaku;

      // THEN: track 被修改，其他保持不变
      expect(modified.id, 'original');
      expect(modified.text, 'Original');
      expect(modified.track, 3);
      expect(modified.startTime, 10000);
    });

    test('[P1] should have correct animation duration constant', () {
      // GIVEN: ActiveDanmaku 类
      // THEN: 动画时长常量为 10000ms
      expect(ActiveDanmaku.animationDuration, 10000);
    });

    test('[P1] should have correct time window constant', () {
      // GIVEN: ActiveDanmaku 类
      // THEN: 时间窗口常量为 300ms
      expect(ActiveDanmaku.timeWindow, 300);
    });
  });

  group('DanmakuSendException', () {
    test('[P1] should create exception with required parameters', () {
      // GIVEN: 错误类型和消息
      const type = DanmakuSendErrorType.network;
      const message = 'Network connection failed';

      // WHEN: 创建异常
      const exception = DanmakuSendException(type: type, message: message);

      // THEN: 属性正确设置
      expect(exception.type, type);
      expect(exception.message, message);
      expect(exception.originalError, isNull);
    });

    test('[P1] should create exception with original error', () {
      // GIVEN: 原始错误对象
      final originalError = Exception('Original socket error');

      // WHEN: 创建包含原始错误的异常
      final exception = DanmakuSendException(
        type: DanmakuSendErrorType.network,
        message: 'Network failed',
        originalError: originalError,
      );

      // THEN: 原始错误被保存
      expect(exception.originalError, originalError);
    });

    test('[P1] should convert error to friendly string', () {
      // GIVEN: 一个异常
      const exception = DanmakuSendException(
        type: DanmakuSendErrorType.auth,
        message: 'Authentication failed',
      );

      // WHEN: 转换为字符串
      final str = exception.toString();

      // THEN: 包含类型和消息
      expect(str, contains('auth'));
      expect(str, contains('Authentication failed'));
    });

    test('[P1] should classify network errors correctly', () {
      // GIVEN: 包含 network 关键字的错误
      const error = 'Network connection timeout';

      // WHEN: 从错误创建异常
      final exception = DanmakuSendException.fromError(error);

      // THEN: 分类为网络错误
      expect(exception.type, DanmakuSendErrorType.network);
      expect(exception.message, contains('网络'));
    });

    test('[P1] should classify auth errors correctly', () {
      // GIVEN: 包含 auth 关键字的错误
      const error = 'Unauthorized access: token expired';

      // WHEN: 从错误创建异常
      final exception = DanmakuSendException.fromError(error);

      // THEN: 分类为认证错误
      expect(exception.type, DanmakuSendErrorType.auth);
      expect(exception.message, contains('登录'));
    });

    test('[P1] should classify throttled errors correctly', () {
      // GIVEN: 包含 throttle 关键字的错误
      const error = 'Rate limit exceeded: too many requests';

      // WHEN: 从错误创建异常
      final exception = DanmakuSendException.fromError(error);

      // THEN: 分类为节流错误
      expect(exception.type, DanmakuSendErrorType.throttled);
      expect(exception.message, contains('频繁'));
    });

    test('[P2] should return itself if already DanmakuSendException', () {
      // GIVEN: 一个 DanmakuSendException
      const original = DanmakuSendException(
        type: DanmakuSendErrorType.validation,
        message: 'Invalid input',
      );

      // WHEN: 调用 fromError
      final result = DanmakuSendException.fromError(original);

      // THEN: 返回同一个实例
      expect(identical(result, original), isTrue);
    });

    test('[P2] should classify server errors correctly', () {
      // GIVEN: 包含 500 的错误
      const error = 'Server error 500: internal error';

      // WHEN: 从错误创建异常
      final exception = DanmakuSendException.fromError(error);

      // THEN: 分类为服务器错误
      expect(exception.type, DanmakuSendErrorType.server);
      expect(exception.message, contains('服务器'));
    });
  });

  group('DanmakuSendRequest', () {
    test('[P0] should create request with required parameters', () {
      // GIVEN: 必需参数
      const vid = 'test_video_123';
      const text = 'Test danmaku';
      const time = 5000;

      // WHEN: 创建请求
      const request = DanmakuSendRequest(vid: vid, text: text, time: time);

      // THEN: 属性正确设置
      expect(request.vid, vid);
      expect(request.text, text);
      expect(request.time, time);
      expect(request.color, isNull);
      expect(request.type, isNull);
      expect(request.fontSize, isNull);
    });

    test('[P1] should create request with all parameters', () {
      // GIVEN: 所有参数
      const vid = 'test_video_456';
      const text = 'Full request';
      const time = 10000;
      const color = '#ffffff';
      const type = DanmakuType.top;
      const fontSize = DanmakuFontSize.large;

      // WHEN: 创建完整请求
      final request = DanmakuSendRequest(
        vid: vid,
        text: text,
        time: time,
        color: color,
        type: type,
        fontSize: fontSize,
      );

      // THEN: 所有属性正确设置
      expect(request.vid, vid);
      expect(request.text, text);
      expect(request.time, time);
      expect(request.color, color);
      expect(request.type, type);
      expect(request.fontSize, fontSize);
    });

    test('[P1] should convert to JSON correctly', () {
      // GIVEN: 一个请求
      final request = DanmakuSendRequest(
        vid: 'video_1',
        text: 'JSON test',
        time: 3000,
        color: '#ff0000',
        type: DanmakuType.bottom,
        fontSize: DanmakuFontSize.medium,
      );

      // WHEN: 转换为 JSON
      final json = request.toJson();

      // THEN: JSON 包含所有字段
      expect(json['vid'], 'video_1');
      expect(json['text'], 'JSON test');
      expect(json['time'], 3000);
      expect(json['color'], '#ff0000');
      expect(json['type'], 'bottom');
      expect(json['fontSize'], 'medium');
    });

    test('[P1] should convert to JSON with only required fields', () {
      // GIVEN: 只有必需字段的请求
      const request = DanmakuSendRequest(
        vid: 'video_2',
        text: 'Minimal',
        time: 1000,
      );

      // WHEN: 转换为 JSON
      final json = request.toJson();

      // THEN: 只包含必需字段
      expect(json.keys, contains('vid'));
      expect(json.keys, contains('text'));
      expect(json.keys, contains('time'));
      expect(json.keys, isNot(contains('color')));
    });

    test('[P1] should copy with modified properties', () {
      // GIVEN: 原始请求
      const original = DanmakuSendRequest(
        vid: 'video_1',
        text: 'Original',
        time: 1000,
      );

      // WHEN: 复制并修改
      final modified = original.copyWith(text: 'Modified', color: '#ffffff');

      // THEN: 新值已设置，旧值保持
      expect(modified.vid, 'video_1');
      expect(modified.text, 'Modified');
      expect(modified.time, 1000);
      expect(modified.color, '#ffffff');
    });

    test('[P1] should convert to string correctly', () {
      // GIVEN: 一个请求
      const request = DanmakuSendRequest(
        vid: 'video_str',
        text: 'String test',
        time: 5000,
      );

      // WHEN: 转换为字符串
      final str = request.toString();

      // THEN: 包含关键信息
      expect(str, contains('video_str'));
      expect(str, contains('String test'));
      expect(str, contains('5000'));
    });
  });

  group('DanmakuSendResponse', () {
    test('[P0] should create success response', () {
      // GIVEN: 成功响应的数据
      const danmakuId = 'danmaku_123';
      const serverTime = 1234567890;

      // WHEN: 创建成功响应
      final response = DanmakuSendResponse.success(
        danmakuId: danmakuId,
        serverTime: serverTime,
      );

      // THEN: 属性正确设置
      expect(response.success, isTrue);
      expect(response.danmakuId, danmakuId);
      expect(response.serverTime, serverTime);
      expect(response.error, isNull);
    });

    test('[P1] should create failure response', () {
      // GIVEN: 错误消息
      const errorMessage = 'Send failed: server error';

      // WHEN: 创建失败响应
      final response = DanmakuSendResponse.failure(errorMessage);

      // THEN: 属性正确设置
      expect(response.success, isFalse);
      expect(response.error, errorMessage);
      expect(response.danmakuId, isNull);
      expect(response.serverTime, isNull);
    });

    test('[P1] should deserialize from JSON successfully', () {
      // GIVEN: 成功的 JSON 响应
      final json = {
        'success': true,
        'danmakuId': 'json_id_456',
        'serverTime': 9876543210,
      };

      // WHEN: 从 JSON 创建响应
      final response = DanmakuSendResponse.fromJson(json);

      // THEN: 正确解析所有字段
      expect(response.success, isTrue);
      expect(response.danmakuId, 'json_id_456');
      expect(response.serverTime, 9876543210);
      expect(response.error, isNull);
    });

    test('[P1] should deserialize from JSON with failure', () {
      // GIVEN: 失败的 JSON 响应
      final json = {
        'success': false,
        'error': 'Validation error: text too long',
      };

      // WHEN: 从 JSON 创建响应
      final response = DanmakuSendResponse.fromJson(json);

      // THEN: 正确解析失败状态
      expect(response.success, isFalse);
      expect(response.error, 'Validation error: text too long');
      expect(response.danmakuId, isNull);
    });

    test('[P2] should handle missing success field as false', () {
      // GIVEN: 缺少 success 字段的 JSON
      final json = {'danmakuId': 'some_id'};

      // WHEN: 从 JSON 创建响应
      final response = DanmakuSendResponse.fromJson(json);

      // THEN: success 默认为 false
      expect(response.success, isFalse);
    });

    test('[P1] should convert to string correctly', () {
      // GIVEN: 一个响应
      final response = DanmakuSendResponse.success(
        danmakuId: 'string_id',
        serverTime: 111111,
      );

      // WHEN: 转换为字符串
      final str = response.toString();

      // THEN: 包含关键信息
      expect(str, contains('true'));
      expect(str, contains('string_id'));
    });
  });
}
