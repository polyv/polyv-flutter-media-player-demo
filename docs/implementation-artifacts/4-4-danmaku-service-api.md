# Story 4.4: 弹幕服务后端接入（历史弹幕 API）

Status: done

## Story

作为 Flutter 开发者，
我想要将弹幕服务接入 Polyv 后端 API，
以便在 iOS 和 Android 上统一使用同一套弹幕数据源，并复用同一套业务逻辑。

## Acceptance Criteria

**Given** 已在 Dart 层定义 `Danmaku` 模型和 `DanmakuService / DanmakuRepository` 接口（Story 4.1）  
**When** 调用 `DanmakuService.fetchDanmakus(vid)`  
**Then** 实际通过 Polyv 弹幕 HTTP API（或后续统一封装的 Platform Channel 方法）拉取对应 vid 的历史弹幕列表  
**And** 将返回结果转换为统一的 Dart `Danmaku` 模型（包含 id / text / time / color / type）  
**And** 按需做简单的数据清洗（如时间排序、去重）

**Given** 网络或鉴权异常  
**When** 调用 `DanmakuService.fetchDanmakus(vid)`  
**Then** 抛出可区分的错误类型（如 NetworkError / AuthError / ServerError），便于 UI 层给出不同的提示与重试策略  
**And** 不会导致 Demo App 崩溃，`DanmakuLayer` 在无数据时保持可用（仅不显示弹幕）

**Given** 播放器开始播放某个视频  
**When** `PlayerController` 进入「已加载并准备播放」状态  
**Then** 上层逻辑可以通过 `DanmakuService.fetchDanmakus(vid)` 拉取对应弹幕列表并提供给 `DanmakuLayer`  
**And** iOS / Android 原生层不直接访问弹幕 HTTP 接口或维护弹幕业务状态，所有弹幕数据流以 Flutter(Dart) 层为单一真相来源

## Tasks / Subtasks

- [x] **定义 Polyv 弹幕 HTTP API 接口契约（文档层面）**
  - [x] 在 Dev Notes 中记录当前使用的 Polyv 弹幕 HTTP 接口（URL、必需参数、返回字段）
  - [x] 标注鉴权方式（如 token / sign），并说明本 Demo 中使用的最小实现集

- [x] **创建 PolyvApiClient 基础设施（复用签名、请求等通用方法）**
  - [x] 在 `polyv_media_player/lib/infrastructure/` 下创建 `polyv_api_client.dart`
  - [x] 实现 `PolyvApiClient` 类，封装通用 HTTP 请求方法（GET/POST）
  - [x] 实现统一的签名生成算法（SHA1 + secretKey + 参数排序拼接）
  - [x] 实现时间格式转换（毫秒 ↔ HH:MM:SS）
  - [x] 实现参数编码（URL query string / form-urlencoded）
  - [x] 实现错误解析和语义化错误类型映射
  - [x] 将 `DanmakuSendService` 中的签名、请求方法迁移到 `PolyvApiClient`

- [x] **在 Dart 层实现 `DanmakuService.fetchDanmakus`**
  - [x] 创建 `HttpDanmakuService` 实现 `DanmakuService.fetchDanmakus`
  - [x] 调用 `PolyvApiClient.get('/v2/danmu', params: {vid, limit})` 获取弹幕列表
  - [x] 将 HTTP 响应解析为内部 DTO，再转换为统一的 `Danmaku` 模型
  - [x] 实现时间格式转换（HH:MM:SS → 毫秒）
  - [x] 实现颜色格式转换（0xRRGGBB → Color）
  - [x] 实现显示模式映射（roll/top/bottom → DanmakuType）

- [x] **重构 DanmakuSendService 使用 PolyvApiClient**
  - [x] 将 `HttpDanmakuSendService` 改为使用 `PolyvApiClient.post()`
  - [x] 移除重复的签名、参数编码等方法
  - [x] 保留发送相关的业务逻辑（校验、节流等）

- [x] **与 Demo App / DanmakuLayer 集成**
  - [x] 创建 `DanmakuDemoConfig` 用于配置 API 凭据和服务切换
  - [x] 实现 `DanmakuServiceFactory.createHttp()` 用于创建真实的 HTTP 服务
  - [x] 确保在网络失败或无数据的情况下，`DanmakuLayer` 行为可预测（仅不显示弹幕）

- [x] **测试**
  - [x] PolyvApiClient 单元测试：验证签名生成、参数编码、时间转换
  - [x] HttpDanmakuService 单元测试：针对 `DanmakuService.fetchDanmakus` 做 HTTP 成功 / 网络失败 / 鉴权失败 / 非法响应等场景覆盖
  - [x] 集成测试（可选）：在 Demo App 中模拟真实拉取弹幕数据，验证页面加载后能正常显示历史弹幕

## Dev Notes

### Polyv 弹幕获取 API

**接口信息：**
- **URL**: `https://api.polyv.net/v2/danmu`
- **Method**: GET
- **Content-Type**: application/json

**请求参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| vid | String | 是 | 视频 ID |
| limit | Int | 否 | 限制返回数量（默认 200） |
| timestamp | String | 是 | 当前时间戳（毫秒） |
| sign | String | 是 | SHA1 签名（大写） |

**鉴权方式：**
SDK 配置 `userid`、`readtoken`、`secretkey`，请求时自动生成 SHA1 签名。

**签名生成步骤：**
1. 收集所有参数（vid, timestamp, limit 等）
2. 按 key 字母顺序排序参数
3. 拼接参数值：`value1value2value3...`
4. 追加 secretkey：`拼接值 + secretkey`
5. 计算 SHA1 哈希并转为大写

**签名示例：**
```dart
// 参数排序后拼接
final paramString = "vid123456limit200timestamp1769000000000";
// 加上密钥
final plainSign = "$paramString$secretKey";
// SHA1 + 大写
final sign = sha1.convert(plainSign).toUpperCase();
```

**响应格式：**
```json
[
  {
    "msg": "弹幕内容",
    "time": "00:01:23",
    "fontSize": 14,
    "fontColor": "0xFFFFFF",
    "fontMode": "roll"
  }
]
```

**响应字段说明：**

| 字段 | 类型 | 说明 |
|------|------|------|
| msg | String | 弹幕内容 |
| time | String | 弹幕时间，格式 HH:MM:SS，需转换为毫秒 |
| fontSize | Int | 字体大小（12/14/18/24 等） |
| fontColor | String | 颜色，格式 0xRRGGBB |
| fontMode | String | 显示模式：roll（滚动）/top（顶部）/bottom（底部） |

**时间转换：**
```
HH:MM:SS → 毫秒
00:01:23 → (0*3600 + 1*60 + 23) * 1000 = 83000ms
```

### iOS 原生实现参考

**核心文件：**
- `PLVVodDanmuManager.m` - 弹幕管理器
- `PLVVodMediaNetworkUtil.m` - 网络工具（签名生成）

**关键方法：**
```objc
+ (void)requestDanmusWithVid:(NSString *)vid
                     maxCount:(NSInteger)maxCount
                   completion:(void (^)(NSArray *danmus, NSError *error))completion;
```

### 架构设计：PolyvApiClient 复用层

当前 `HttpDanmakuSendService` 中的签名、参数编码等方法需要提取到共享的 `PolyvApiClient`，供所有 Polyv API 调用复用。

**PolyvApiClient 职责：**
- 统一的签名生成算法
- 通用 HTTP 请求方法（GET/POST）
- 参数编码（query string / form-urlencoded）
- 时间格式转换（毫秒 ↔ HH:MM:SS）
- 错误响应解析

**使用方式：**
```dart
// 创建 API 客户端
final apiClient = PolyvApiClient(
  userId: 'xxx',
  readToken: 'xxx',
  secretKey: 'xxx',
);

// 获取弹幕列表
final response = await apiClient.get('/v2/danmu', params: {
  'vid': 'video123',
  'limit': 200,
});

// 发送弹幕
final response = await apiClient.post('/v2/danmu/add', bodyParams: {
  'vid': 'video123',
  'msg': '弹幕内容',
  'time': '00:00:05',
});
```

**重构影响范围：**
- 新增：`PolyvApiClient` 类
- 重构：`HttpDanmakuSendService` - 移除重复方法，使用 `PolyvApiClient.post()`
- 新增：`HttpDanmakuService` - 使用 `PolyvApiClient.get()`

### Story Context

- 本 Story 负责将 Story 4.1 中抽象出来的 `DanmakuService / DanmakuRepository` 接口真正接入 Polyv 后端弹幕 API。  
- UI 和时间驱动逻辑仍由 Story 4.1（弹幕显示层）负责，本 Story 不改动 `DanmakuLayer` 的 UI 和算法，只提供真实数据源。  
- 发送弹幕的 HTTP 接入由 Story 4.3 负责，本 Story 不处理发送逻辑。

### Architecture Compliance

- 所有与弹幕相关的业务 HTTP 调用统一集中在 Flutter(Dart) 层的 Service / Repository 中：  
  - 原生 iOS / Android 层不直接发起弹幕 HTTP 请求，也不维护弹幕业务状态。  
  - 如需通过 Platform Channel 复用 SDK 自带的弹幕模块，也必须通过单一 Channel 方法在 Dart 层统一封装，保持 Dart 层为唯一业务入口。  
- `DanmakuService` 作为跨端共享业务能力，为未来在其他 Flutter App 中复用提供基础。

### References

- `docs/planning-artifacts/epics.md#story-4.4-弹幕服务后端接入（历史弹幕-api）`
- `docs/implementation-artifacts/4-1-danmaku-layer.md`（弹幕显示层与时间驱动）
- Polyv 弹幕 HTTP API 文档（待补充链接）

## File List

### 新增文件
- `polyv_media_player/lib/infrastructure/polyv_api_client.dart` - Polyv API 客户端基础设施
- `polyv_media_player/test/infrastructure/polyv_api_client_test.dart` - PolyvApiClient 单元测试
- `polyv_media_player/test/infrastructure/polyv_api_client_post_test.dart` - PolyvApiClient POST 方法单元测试
- `polyv_media_player/test/support/api_test_helpers.dart` - API 测试辅助工具
- `polyv_media_player/example/lib/player_skin/danmaku/danmaku_demo_config.dart` - Demo 配置文件
- `polyv_media_player/example/lib/player_skin/danmaku/danmaku_send_service_test.dart` - 弹幕发送服务 Mock 实现单元测试
- `polyv_media_player/example/lib/player_skin/danmaku/danmaku_send_service_http_test.dart` - 弹幕发送服务 HTTP 实现单元测试
- `docs/test-automation-summary.md` - 测试自动化总结文档

### 修改文件
- `polyv_media_player/pubspec.yaml` - 添加 http 和 crypto 依赖
- `polyv_media_player/example/lib/player_skin/danmaku/danmaku_service.dart` - 添加 HttpDanmakuService 和 DanmakuServiceFactory，重构 HttpDanmakuSendService 使用 PolyvApiClient
- `polyv_media_player/example/lib/player_skin/danmaku/danmaku_service_test.dart` - 添加 HttpDanmakuService 和 DanmakuServiceFactory 测试
- `docs/implementation-artifacts/sprint-status.yaml` - 更新 Story 4.4 状态

## Change Log

### 2026-01-22
- **新增**: `PolyvApiClient` 类，提供统一的 Polyv API 调用基础设施
  - GET/POST 请求方法
  - SHA1 签名生成算法
  - 时间格式转换（毫秒 ↔ HH:MM:SS）
  - 颜色格式转换（0xRRGGBB ↔ int）
  - 语义化错误类型（Network/Auth/Server/Validation/Unknown）
  - 修复：`_mapErrorType` 现在支持数值型和字符串型错误码
- **新增**: `HttpDanmakuService` 类，实现 `DanmakuService.fetchDanmakus` 接口
  - 调用 Polyv `/v2/danmu` API 获取历史弹幕
  - 将 API 响应转换为统一的 `Danmaku` 模型
  - 支持缓存和分页
  - 语义化错误处理（DanmakuFetchException）
  - 修复：实现数据清洗逻辑（去重 + 时间排序）
- **重构**: `HttpDanmakuSendService` 使用 `PolyvApiClient.post()`
  - 移除重复的签名、参数编码等方法
  - 保留业务逻辑（校验、节流等）
- **新增**: `DanmakuServiceFactory.createHttp()` 工厂方法
- **新增**: `DanmakuDemoConfig` 配置文件，支持 Mock/HTTP 服务切换
- **新增**: 单元测试覆盖 PolyvApiClient、HttpDanmakuService、DanmakuServiceFactory
  - `polyv_api_client_test.dart` - GET 方法测试
  - `polyv_api_client_post_test.dart` - POST 方法测试
  - `api_test_helpers.dart` - 测试辅助工具
  - `danmaku_send_service_test.dart` - Mock 发送服务测试
  - `danmaku_send_service_http_test.dart` - HTTP 发送服务测试

### 2026-01-22 (Code Review Fixes)
- **修复**: File List 补充完整，添加所有新增的测试文件
- **修复**: HttpDanmakuService 实现数据清洗去重逻辑
- **修复**: PolyvApiClient._mapErrorType 支持数值型和字符串型错误码
- **修复**: 测试代码移除无效的 stub 实现

