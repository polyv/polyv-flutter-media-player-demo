# polyv-ios-media-player-flutter-demo
# 中期架构重构实施方案（Flutter 层 vs 原生层职责）

状态：实施中（Phase 1–3 已按本文方案完成首轮落地）  
适用范围：`polyv_ios_media_player_flutter_demo / polyv_media_player` 插件工程

---

## 1. 背景与目标

### 1.1 背景

当前项目已经完成约一半功能，核心架构基于以下既有决策：

- Flutter Plugin 作为 Polyv 播放器 SDK 的封装层
- 原生 iOS/Android 负责：解码、渲染、播放控制等**核心播放器能力**
- Flutter 层（包含 plugin + demo app）负责：
  - 状态管理（`PlayerController` + `PlayerState`）
  - UI 皮肤与交互（example/player_skin）
  - Danmaku / Playlist / 下载中心等**业务逻辑**（Phase 1 以示例为主）
- 架构文档（`docs/planning-artifacts/architecture.md` & `docs/project-context.md`）已经定义了分层原则和命名/通信模式

在实际实现中，整体方向与架构文档基本一致，但也暴露出以下需要优化的点：

- 清晰度切换逻辑在 Dart 与原生层之间存在重复/分裂
- Platform Channel 抽象层尚未完全按架构文档落地
- Danmaku 业务服务目前放在 Demo 目录下，可复用性有限
- 一些边界/职责依赖“约定”，建议通过更明确的文档和代码结构固化

### 1.2 本文档目标

- 汇总当前识别出的架构改进点
- 给出**分阶段、可执行**的重构计划（短期 / 中期 / 长期）
- 明确 Flutter 层 vs 原生层的职责边界落地方式
- 标注与既有架构文档的关系，以及何时需要同步更新文档

---

## 2. 当前架构快照（简要）

### 2.1 Flutter Plugin 层：`polyv_media_player/lib`

- `core/`
  - `player_controller.dart`
    - 通过 `MethodChannelHandler` & `EventChannelHandler` 间接封装 `MethodChannel` & `EventChannel`
    - 维护 `PlayerState`
    - 消费事件：`stateChanged / progress / error / qualityChanged / subtitleChanged / playbackSpeedChanged / completed`
  - `player_state.dart`：状态模型
  - `player_events.dart`：事件类型与 `QualityItem` / `SubtitleItem` 等模型
  - `player_exception.dart`：异常封装
- `platform_channel/`
  - `player_api.dart`：Channel 名称、方法/事件名常量以及玩家状态/错误等枚举常量
  - `method_channel_handler.dart` / `event_channel_handler.dart`：Platform Channel 抽象层，统一封装所有 `invokeMethod` 与事件流解析
- `infrastructure/`
  - `polyv_api_client.dart` 等可复用 HTTP 客户端
  - `danmaku/` 下的弹幕模型与服务（`danmaku_model.dart` / `danmaku_service.dart`），作为插件共享业务层的一部分
- `widgets/`
  - `polyv_video_view.dart`：封装原生 `PlatformView`，负责原生渲染视图挂载

### 2.2 Demo App 层：`polyv_media_player/example/lib`

- `player_skin/`：完整播放器 UI 皮肤与交互
- `player_skin/danmaku/`：
  - 弹幕显示层、输入框、开关等 UI 组件（纯 UI）
  - 通过 `package:polyv_media_player/infrastructure/danmaku/...` 复用插件内的 Danmaku 模型与服务
  - 不再在 Demo 中实现独立的 Danmaku 业务 Service，避免与 Plugin 共享层重复

### 2.3 原生插件层

- **Android** `PolyvMediaPlayerPlugin.kt`
  - 实现：`loadVideo / play / pause / stop / seekTo / setPlaybackSpeed / setQuality` 等方法
  - 通过 `EventChannel` 发送：`stateChanged / progress / error / qualityChanged / completed` 等事件
  - 在清晰度切换中：记录进度与播放状态，切换后恢复，并适配 SDK 的 `PLVMediaBitRate` → 统一 JSON 结构
- **iOS** `PolyvMediaPlayerPlugin.m`
  - 同样实现上述方法
  - `handleLoadVideo` 使用 `PLVVodMediaVideo requestVideoPriorityCacheWithVid` 加载视频（核心播放器能力）
  - `sendQualityDataForVideo` 构建 `qualitiesList` 并发送 `qualityChanged` 事件
  - `handleSetQuality` 记录当前 `currentPlaybackTime` 与 `wasPlaying`，切换后恢复

结论：

- 原生层当前基本只承担**播放器 SDK 调用和事件桥接**，没有实现 Danmaku/Playlist/下载中心等业务模块，符合“业务在 Flutter 层”的总体原则。
- Flutter 层已经承载了 Danmaku 业务逻辑，但位置偏 Demo，平台通道抽象尚不充分。

---

## 3. 重构方向总览

### 3.1 方向 A：统一清晰度切换职责边界（高优先级）

目标：

- 清晰度切换后的**进度与播放状态恢复逻辑**只在原生层实现
- Flutter `PlayerController` 只负责：
  - 校验清晰度索引
  - 调用 `setQuality(index)`
  - 消费 `qualityChanged` 事件并更新本地状态

当前问题：

- Android：恢复逻辑完全在原生层，Dart 只调一次 `setQuality`（合理）
- iOS：
  - 原生 `handleSetQuality` 已经实现了“记住 currentPosition & wasPlaying → 切换后延时 seek + play”
  - Dart `PlayerController.setQuality` 在非 Android 平台上也会在 Dart 侧再做一遍“记住位置 → 切换 → seek → play”
- 结果：iOS 上存在“清晰度切换恢复逻辑在 Dart 和原生重复/分裂”的风险，职责边界不清晰。

### 3.2 方向 B：落实 Platform Channel 抽象（中优先级）

目标：

- 将与 `MethodChannel` / `EventChannel` 相关的**通信细节**集中在 `lib/platform_channel/`，实现架构文档中已有的结构设计：
  - `MethodChannelHandler`：封装所有 `invokeMethod` 调用
  - `EventChannelHandler`：封装事件流解析，输出 `PlayerEvent` 模型
- `PlayerController` 只依赖这些 handler：
  - 发起高层操作（`loadVideo / play / pause / setQuality / setSubtitle` 等）
  - 消费事件并维护 `PlayerState`

当前问题：

- `PlayerController` 直接 new `MethodChannel` / `EventChannel`，并在内部解析事件 Map
- `platform_channel/player_api.dart` 只定义了常量，未形成完整抽象层
- 随着后续扩展（下载中心、播放列表等），`PlayerController` 容易变得过重、难以测试

### 3.3 方向 C：业务服务从 Demo 抽取到 Plugin 共享层（中优先级）

目标：

- 将可跨 App 复用的业务逻辑（Danmaku / Playlist / 下载服务接口和实现）放入 Plugin 的 `lib/` 下（如 `infrastructure/` 或 `business/`），形成**跨端共享业务层**
- Demo 只保留 UI 和交互逻辑，消费这些 service

当前问题（以及已完成的整改）：

- 早期版本中，Danmaku 业务逻辑（HTTP 调用、限流、校验等）位于 `example/lib/player_skin/danmaku/`，目前已抽取到 `lib/infrastructure/danmaku/` 并作为插件共享业务层的一部分对外提供。
- Demo 现在只作为 UI 与交互示例，通过依赖插件内的 `DanmakuService / DanmakuSendService` 来工作。
- 后续同类问题将主要出现在 Playlist / 下载中心等新业务上，需要直接落在 Plugin 的共享业务层，而不是 Demo 目录。

### 3.4 方向 D：常量/命名/边界规则的补充（低优先级）

目标：

- 用少量重构巩固既有约定，降低今后引入不一致的风险：
  - 使用 `PlayerMethod` / `PlayerEventName` 常量替代硬编码字符串
  - 明确“不得在 UI Widget 中直接使用 Platform Channel”的边界（文档已有，需要在实现上强化）
  - 明确“清晰度切换后恢复由原生实现，Dart 不应重复”的规则

---

## 4. 分阶段实施计划

### Phase 1（短期，建议优先完成）：统一清晰度切换职责

**目标：解决职责边界不清晰的问题，避免 iOS 上双重 seek/play 风险。**

**实施状态（2026-01-22）**：已完成。`PlayerController.setQuality` 现已统一为仅依赖 `MethodChannelHandler.setQuality` 触发原生调用，清晰度切换后的进度与播放状态恢复完全由 Android/iOS 的 `handleSetQuality` 原生实现负责。

#### P1-T1：收敛 `setQuality` 逻辑到原生层

- 代码范围：
  - `lib/core/player_controller.dart`
  - `android/src/main/.../PolyvMediaPlayerPlugin.kt`（仅确认，无需大改）
  - `ios/Classes/PolyvMediaPlayerPlugin.m`（仅确认现有逻辑即可）

- 实施要点：
  1. 在 `PlayerController.setQuality(int index)` 中：
     - 保留索引范围校验（`index < 0 || index >= _qualities.length` 抛 `PlayerException.unsupportedOperation`）
     - 移除 Dart 端在非 Android 平台上的“记住 `wasPlaying` / `position`，调用 `setQuality` 后再 `seekTo` + `play`”逻辑
     - 所有平台统一改为：只执行 `await _methodChannel.invokeMethod('setQuality', {'index': index});`
  2. 确认原生层逻辑：
     - Android：`handleSetQuality` 已完整处理 `pendingSeekPositionAfterQualityChange` / `pendingAutoPlayAfterQualityChange`，维持现状即可
     - iOS：`handleSetQuality` 已记录 `currentPlaybackTime` 和 `wasPlaying`，并在切换后延迟恢复，维持现状即可

- 回归测试建议：
  - Android/iOS 各执行以下场景：
    - 播放中 → 切换清晰度，检查：
      - 进度是否基本保持不变（允许轻微误差）
      - 播放状态是否按照切换前状态恢复
    - 暂停状态 → 切换清晰度，检查：
      - 切换后仍保持暂停
      - 进度条不发生明显跳变

#### P1-T2：在文档中增加一条“清晰度职责边界”约束（可选）

- 位置建议：
  - `docs/planning-artifacts/architecture.md` 中“业务逻辑归属原则（Danmaku / 播放列表 / 下载中心）”附近
  - 或 `docs/project-context.md` 中“项目结构关键边界 (Phase 1)”小节
- 内容原则：
  - 声明“清晰度切换后进度与播放状态的恢复逻辑属于原生播放器能力的一部分，Flutter 层仅负责触发 `setQuality` 并消费结果事件”

> 注：此任务可以在代码重构完成后再补文档，对实现无硬依赖。

---

### Phase 2（中期）：落实 Platform Channel 抽象

**目标：将 Platform Channel 通信细节从 `PlayerController` 中剥离，降低耦合，方便扩展与测试。**

**实施状态（2026-01-22）**：已完成。`lib/platform_channel/method_channel_handler.dart` 与 `event_channel_handler.dart` 已落地，`PlayerController` 通过注入的 handler 访问 Platform Channel，并统一使用 `PlayerMethod` / `PlayerEventName` / `PlayerStateValue` 常量替代硬编码字符串。

#### P2-T1：实现 `MethodChannelHandler` 与 `EventChannelHandler`

- 代码范围：
  - 新增：`lib/platform_channel/method_channel_handler.dart`
  - 新增：`lib/platform_channel/event_channel_handler.dart`
  - 适配：`lib/core/player_controller.dart`

- 建议职责划分：

  - `MethodChannelHandler`（示意接口）：
    - `Future<void> loadVideo(String vid, {bool autoPlay})`
    - `Future<void> play()` / `pause()` / `stop()` / `seekTo(int position)`
    - `Future<void> setPlaybackSpeed(double speed)`
    - `Future<void> setQuality(int index)`
    - `Future<void> setSubtitle(int index)`
    - 内部使用 `PlayerMethod` 常量组装 `invokeMethod` 调用
    - 捕获 `PlatformException`，并抛出给上层（由 `PlayerController` 转为 `PlayerException`）

  - `EventChannelHandler`（示意接口）：
    - 暴露一个 `Stream<PlayerEvent>`（或 `Stream<Map>`，由 `PlayerController` 转换）
    - 内部负责：
      - `EventChannel.receiveBroadcastStream()`
      - 解析原始 Map：`type` + `data` → `PlayerEvent` 子类 (`StateChangedEvent` / `ProgressEvent` / `ErrorEvent` / `QualityChangedEvent` / `SubtitleChangedEvent` ...)

#### P2-T2：重构 `PlayerController` 依赖注入 Handler

- 构造函数调整：
  - 从直接持有 `MethodChannel` / `EventChannel` 改为持有抽象 handler
  - 保留默认实现（内部 new handler），同时支持在测试中注入 mock/stub
- 事件处理：
  - 从 `_eventChannel.receiveBroadcastStream().listen(...)` 改为：
    - 订阅 `EventChannelHandler` 暴露的 `Stream<PlayerEvent>`
    - 根据事件类型更新 `PlayerState`、清晰度列表、字幕列表

#### P2-T3：统一使用 `PlayerMethod` / `PlayerEventName` 常量

- 替换所有硬编码字符串：
  - `invokeMethod('loadVideo', ...)` → `invokeMethod(PlayerMethod.loadVideo, ...)`
  - 事件类型比较 `type == 'stateChanged'` → `type == PlayerEventName.stateChanged`

#### P2-T4：回归与测试

- 基本播放流程回归：加载、播放、暂停、停止、seek、倍速、清晰度切换、字幕开关
- 考虑补若干单元测试：
  - 使用 mock 的 `MethodChannelHandler` 与 `EventChannelHandler` 验证 `PlayerController` 状态变更逻辑

---

### Phase 3（中/长期）：业务服务抽取与扩展

**目标：把可共享业务逻辑（特别是 Danmaku）从 Demo 中抽取到 Plugin 层，为后续 Playlist/下载中心等能力提供模板。**

**实施状态（2026-01-22）**：已完成第一阶段。`Danmaku` 模型与 `DanmakuService / DanmakuSendService` 相关实现已迁移到 `lib/infrastructure/danmaku/`，Demo 通过 `package:polyv_media_player/...` 复用这些 Service，不再维护独立的业务实现。Playlist/下载中心仍按本节规划保留为后续扩展方向。

#### P3-T1：抽取 Danmaku Service 到 Plugin 共享层

- 建议新结构：

  - 在 `lib/` 下新增业务层目录（任选其一，二选一即可）：
    - `lib/infrastructure/danmaku/`
    - 或 `lib/business/danmaku/`
  - 移动以下内容：
    - `Danmaku` 模型及相关枚举
    - `DanmakuService / DanmakuSendService` 接口
    - `HttpDanmakuService` / `MockDanmakuService` / `MockDanmakuSendService` 等与 UI 无关的逻辑
  - Demo (`example/lib/player_skin/danmaku`) 中保留：
    - Danmaku UI 组件（弹幕层、输入框等）
    - 依赖抽取后的 service 进行渲染与发送

- 对外 API 决策：
  - 是否通过 `polyv_media_player.dart` 导出 Danmaku 相关 service：
    - 若导出：客户 App 可直接使用 Plugin 提供的 Danmaku 能力
    - 若暂不导出：作为内部实现模块，主要服务 Demo，后续再开放

#### P3-T2：为 Playlist / 下载中心预留业务层骨架

- 在同一业务层目录中（如 `lib/infrastructure/` 或 `lib/business/`）：
  - 定义接口但可暂不实现：
    - `PlaylistService`（获取账号下视频列表、分页等）
    - `DownloadService`（队列管理、状态同步、失败重试策略等）
  - 在架构文档中标注：这类业务能力将始终在 Dart 层（Plugin 业务层）实现，原生只提供“具体执行 + 状态回调”能力

#### P3-T3：文档与对外说明

- 在 `architecture.md` / `project-context.md` 中：
  - 补充一节“共享业务层（Business Layer in Plugin）”
  - 说明：
    - Plugin 不再仅限于“纯播放核心能力”，还可以托管**跨端共享业务逻辑模块**（Danmaku/Playlist/Download 等）
    - Demo App 只负责 UI 与交互，是业务层的一个示例消费者

---

## 5. 风险评估与回归计划

### 5.1 风险点

- P1：清晰度切换职责调整
  - 风险：若 Dart 端逻辑移除不当，可能依赖原生实现暴露的行为差异
  - 缓解：
    - 先在 Android/iOS 上验证原生 `setQuality` 的行为
    - 调整 Dart 逻辑时仅删除冗余的恢复逻辑，不改动其他 API

- P2：Platform Channel 抽象重构
  - 风险：
    - 重构过程中若事件解析/方法调用有遗漏，可能影响所有播放流程
  - 缓解：
    - 坚持“小步重构”：先引入 handler 并让 `PlayerController` 使用，但保留原有事件处理逻辑一段时间做对比
    - 引入基础单元测试

- P3：业务服务抽取
  - 风险：
    - 路径调整可能影响 Demo 中的导入
  - 缓解：
    - 先在插件层复制一份 Danmaku 相关代码，Demo 切到新路径稳定后再删旧代码

### 5.2 回归测试建议清单

- **基础播放流程**（Android/iOS）：加载、播放、暂停、停止、seek、倍速
- **清晰度切换**：
  - 播放中/暂停状态下切换多次，验证进度和状态恢复
- **字幕功能**（结合 Story 5.1：字幕显示与开关）：
  - 在字幕开启/关闭时，验证 `PlayerState` 中与字幕相关字段（未来引入后）是否与 UI 同步
- **Danmaku 功能**（在 P3 完成后）：
  - 弹幕获取、发送、节流、错误处理

---

## 6. 与现有架构文档的关系

### 6.1 已有决策 vs 本次重构

- **完全对齐/实现已有决策的部分**：
  - 清晰度切换职责边界收敛到原生（属于“核心播放器能力”范围）
  - Platform Channel 抽象下沉到 `platform_channel` 层
  - 业务逻辑统一在 Flutter(Dart) 层实现，不在原生层写 HTTP/Repo

- **需要在完成后考虑更新文档的部分**（建议在 Phase 2/3 后进行）：
  - 若将 Danmaku/Playlist/Download 等业务 service 放入 Plugin 共享层：
    - 需要在 `architecture.md` 中补充“Plugin 业务层”一节，说明 Plugin 不再**严格意义上**仅包含“播放核心能力”，而是“核心能力 + 可选共享业务模块”
  - 在 `project-context.md` 的边界规则中：
    - 建议加一句“清晰度切换后的进度/播放恢复逻辑只能在原生层实现，Dart 层不得重复实现”，以免未来再次引入重复逻辑

### 6.2 建议的文档更新时间点

- 完成 **Phase 1 & Phase 2** 后：
  - 更新 `project-context.md` 的边界与约束（强化清晰度职责与 Channel 抽象）
- 完成 **Phase 3** 中 Danmaku 抽取后：
  - 更新 `architecture.md` 的“项目结构 & 业务逻辑归属原则”部分，加入 Plugin 业务层说明

---

## 7. 总结

- 当前架构与最初设计高度一致：
  - 原生层负责核心播放器能力
  - Flutter 层负责状态和业务逻辑
- 本重构方案的主要价值：
  - 收紧清晰度切换等“体验敏感逻辑”的职责边界，避免 Dart / 原生重复
  - 落实 Platform Channel 抽象，为后续扩展能力（下载中心、播放列表等）打基础
  - 为 Danmaku 等跨端业务能力提供一个可共享的 Plugin 业务层位置，减少未来重复实现
- 建议按照 Phase 1 → Phase 2 → Phase 3 的顺序渐进实施，并在关键阶段同步更新 `architecture.md` 与 `project-context.md`。
