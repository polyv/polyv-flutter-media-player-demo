/// 播放器账号配置模型
///
/// 用于统一配置 Polyv 播放器的账号信息，包括 userId、readToken、writeToken、secretKey 等字段。
/// 由 Flutter 层通过 Platform Channel 传递到原生层，实现跨端业务逻辑统一。
class PlayerConfig {
  /// 用户 ID
  final String userId;

  /// 读 Token
  final String readToken;

  /// 写 Token
  final String writeToken;

  /// 密钥
  final String secretKey;

  /// 环境标识（预留扩展字段）
  ///
  /// 可选值：'test', 'prod' 等，不在原生层做判断
  final String? env;

  /// 业务线标识（预留扩展字段）
  final String? businessLine;

  /// 其他扩展字段（预留）
  final Map<String, String>? extra;

  const PlayerConfig({
    required this.userId,
    required this.readToken,
    required this.writeToken,
    required this.secretKey,
    this.env,
    this.businessLine,
    this.extra,
  });

  /// 从 JSON 创建 PlayerConfig
  factory PlayerConfig.fromJson(Map<String, dynamic> json) {
    return PlayerConfig(
      userId: json['userId'] as String? ?? '',
      readToken: json['readToken'] as String? ?? '',
      writeToken: json['writeToken'] as String? ?? '',
      secretKey: json['secretKey'] as String? ?? '',
      env: json['env'] as String?,
      businessLine: json['businessLine'] as String?,
      extra: json['extra'] as Map<String, String>?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'userId': userId,
      'readToken': readToken,
      'writeToken': writeToken,
      'secretKey': secretKey,
    };
    if (env != null) {
      json['env'] = env;
    }
    if (businessLine != null) {
      json['businessLine'] = businessLine;
    }
    if (extra != null) {
      json['extra'] = extra;
    }
    return json;
  }

  /// 校验必填字段
  ///
  /// 返回校验错误信息列表，如果列表为空则表示校验通过
  List<String> validate() {
    final errors = <String>[];

    if (userId.isEmpty) {
      errors.add('userId 不能为空');
    }
    if (secretKey.isEmpty) {
      errors.add('secretKey 不能为空');
    }

    return errors;
  }

  /// 是否有效（所有必填字段都不为空）
  bool get isValid => validate().isEmpty;

  /// 复制并修改部分字段
  PlayerConfig copyWith({
    String? userId,
    String? readToken,
    String? writeToken,
    String? secretKey,
    String? env,
    String? businessLine,
    Map<String, String>? extra,
  }) {
    return PlayerConfig(
      userId: userId ?? this.userId,
      readToken: readToken ?? this.readToken,
      writeToken: writeToken ?? this.writeToken,
      secretKey: secretKey ?? this.secretKey,
      env: env ?? this.env,
      businessLine: businessLine ?? this.businessLine,
      extra: extra ?? this.extra,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PlayerConfig &&
        other.userId == userId &&
        other.readToken == readToken &&
        other.writeToken == writeToken &&
        other.secretKey == secretKey &&
        other.env == env &&
        other.businessLine == businessLine;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      readToken,
      writeToken,
      secretKey,
      env,
      businessLine,
    );
  }

  @override
  String toString() {
    final hasReadToken = readToken.isNotEmpty;
    final hasWriteToken = writeToken.isNotEmpty;
    final hasSecretKey = secretKey.isNotEmpty;
    return 'PlayerConfig(userId: $userId, readToken: ***${hasReadToken ? '•••' : ''}, writeToken: ***${hasWriteToken ? '•••' : ''}, secretKey: ***${hasSecretKey ? '•••' : ''}, env: $env, businessLine: $businessLine)';
  }
}
