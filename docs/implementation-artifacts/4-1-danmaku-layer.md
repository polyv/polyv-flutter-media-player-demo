# Story 4.1: 弹幕显示层

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

作为最终用户，
我想要看到其他用户发送的弹幕，
以便获得互动体验。

## Acceptance Criteria

**Given** 弹幕功能已开启  
**When** 有弹幕数据  
**Then** 弹幕从右向左滚动显示  
**And** 弹幕显示在视频上方  
**And** 弹幕不遮挡视频主要内容  
**And** 多条弹幕在不同轨道显示  

**Given** 播放器正在正常播放视频  
**When** Demo App 集成弹幕显示层  
**Then** 弹幕显示的 UI 结构、轨道间距、字体大小、透明度和滚动动画效果与 `/polyv-vod` 中的 `DanmakuLayer.tsx` 原型**保持 1:1 一致**  
**And** 不论在竖屏（半屏）还是横屏（全屏）模式，弹幕始终覆盖在视频区域之上，且安全区域（notch / home indicator）与原型一致  

**Given** 播放进度在变化  
**When** PlayerController 的播放进度（毫秒）更新  
**Then** Flutter 层的弹幕显示层根据当前时间决定哪些弹幕应该进入可见列表  
**And** 不会重复显示已展示过的弹幕  
**And** 弹幕的出现时间窗口与原型一致（例如前后 0.3 秒的时间窗 + 8 秒动画时长）  

**Given** 播放状态在变化（播放 / 暂停 / 拖动）  
**When** 视频被暂停  
**Then** 弹幕滚动动画与原生 SDK 的行为保持一致（可以在 Phase 1 简化为：暂停时冻结、新播放时恢复）  
**When** 用户拖动进度条进行 seek  
**Then** 重新按当前时间计算应显示的弹幕集合，避免显示时间错乱或重复刷屏  

**Given** Flutter Plugin 已通过 Platform Channel 集成 iOS / Android 原生播放器  
**When** 设计弹幕数据获取与显示逻辑  
**Then** 历史弹幕数据由 Flutter 层的 `DanmakuService` / `DanmakuRepository` 统一获取和缓存（通过 Polyv 弹幕 HTTP API 或后续统一封装的 Channel 方法）  
**And** iOS / Android 原生层只提供播放器核心能力（如当前播放时间、播放状态），不直接实现弹幕 HTTP / Repo 业务逻辑  
**And** 弹幕时间驱动与 iOS / Android 原生 Demo 的行为保持一致（以 `player.currentPlaybackTime` / `mediaViewModel.playerState` 为参考），但由 Dart 侧根据 `PlayerState.position` 在 `DanmakuLayer` 内实现时间窗口与轨道分配算法  
**And** 如需复用原生 SDK 自带的弹幕模块（例如 `PLVMediaPlayerDanmuModule`），必须通过单一 Platform Channel 方法在 Dart 层统一封装，而不是在 iOS 和 Android 各自写一套业务逻辑  

## Tasks / Subtasks

- [x] **创建弹幕显示层组件（AC: UI 1:1, Then）**
  - [x] 在 Demo App 层创建目录：`polyv_media_player/example/lib/player_skin/danmaku/`
  - [x] 创建 `danmaku_layer.dart` 文件，定义 `DanmakuLayer` Widget，位置与 Web 原型一致：
    - 作为播放器视频区域上的一层 overlay，放在 `Stack` 最上层
    - 接收属性：`enabled`, `opacity`, `fontSize`, `currentTime`, `danmakus`（列表）
  - [x] 轨道设计：
    - 使用与原型一致的固定轨道数量（例如 8 条）
    - 轨道纵向间距、顶部偏移量与 `DanmakuLayer.tsx` 中的 `top: 12 + track * 32px` 对齐
  - [x] 字体大小：根据 `fontSize` 传入值映射为 `small` / `medium` / `large`，对应 TextStyle 的字号与 Web 原型视觉一致

- [x] **弹幕数据结构与时间驱动（AC: Given, When, Then）**
  - [x] 在 Demo 层定义 Dart 端 `Danmaku` 数据类：包含 `id`, `text`, `time`, `color`, `type`（scroll/top/bottom）
  - [x] 在 `DanmakuLayer` 内部维护 `activeDanmakus` 列表（对应 Web 端的 `activeDanmakus` 状态）
  - [x] 在 Flutter(Dart) 层定义 `DanmakuService` / `DanmakuRepository`（命名示意）：
    - 暴露统一方法 `Future<List<Danmaku>> fetchDanmakus(String vid, {int? limit, int? offset})`
    - 当前 Story 允许使用本地 mock 数据或简单内存实现，但接口形态需满足后续直接接 Polyv 弹幕 HTTP API 的需求
    - 原生端不得直接实现弹幕 HTTP / Repo，所有历史弹幕数据都通过该 Service 间接获得
  - [x] 实现逻辑：
    - 当 `enabled == false` 时，清空 `activeDanmakus`，不渲染任何弹幕
    - 当 `enabled == true` 时，每次 `currentTime`（毫秒）更新：
      - 找到 `time ∈ (currentTime - 300ms, currentTime]` 且尚未展示过的弹幕
      - 将它们分配到最空闲的轨道，并记录 `startTime`（当前系统时间）
      - 将新弹幕加入 `activeDanmakus`，同时移除早于 8 秒展示时长的旧弹幕

- [x] **与 PlayerController 状态集成（AC: 播放器逻辑参考原生）**
  - [x] 在 Demo App 的播放器页面（例如 `long_video_page.dart` 或播放器皮肤根组件）中：
    - 使用 `Consumer<PlayerController>` 或等价方式获取 `state.position`（毫秒）
    - 将 `currentTime = state.position.toDouble()` 传递给 `DanmakuLayer`
  - [x] 对齐 iOS Demo：
    - `setupPlaybackTimer` 每 0.1s 更新 `player.currentPlaybackTime` 并同步给 `danmuManager.currentTime`
    - Flutter 侧用一个 `Ticker` 或基于进度事件的回调模拟这一行为，但优先使用已有的 `progress` 事件（Story 2.x 已实现）

- [x] **UI 样式与布局 1:1 对齐原型（AC: UI 一致）**
  - [x] 颜色：
    - 默认字体颜色为白色，支持 per-danmaku `color`（与 `DanmakuInput.tsx` 使用的颜色相匹配，为后续 4.3 发送 Story 做准备）
    - 背景透明，仅在 CSS/样式上通过 `opacity` 控制整体透明度，不额外绘制底色
  - [x] 布局：
    - Flutter 中使用 `Positioned.fill` + `IgnorePointer` 的组合，确保弹幕不拦截手势（参照"弹幕不遮挡视频主要内容"这一用户感知）
    - 每条弹幕使用 `AnimatedPositioned` 或自定义动画（如 `TweenAnimationBuilder`）实现从右向左滚动，时长 8s，与 Web 端 `animationDuration: 8s` 一致

- [x] **状态与性能（AC: 稳定，不错乱）**
  - [x] 确保在快速 seek 场景下：
    - 能够根据新的 `currentTime` 清理已不在时间窗口内的弹幕
    - 避免重复展示同一条 `id` 的弹幕（可使用 `shownIds` 集合，类似 Web 中的 `shownIdsRef`）
  - [x] 评估 `activeDanmakus` 列表的上限，避免长视频/密集弹幕情况下的性能问题（可以在 Dev Notes 中给出建议）

- [x] **测试（AC: 全部）**
  - [x] Widget 测试：
    - 构造固定的弹幕列表和当前时间，验证在一个时间点只显示符合 `time` 条件且轨道布局正确的弹幕
    - 验证当 `enabled == false` 时不会渲染任何弹幕
    - 验证 `opacity` 和 `fontSize` 属性确实反映到 Widget 样式上
  - [x] 集成测试（可在 Story 4.2/4.3 中进一步扩展）：
    - 与真实播放器页面集成后，启动播放一段时间，观察弹幕与视频时间对齐情况

## Dev Notes

### Story Context

**Epic 4: 弹幕功能**  
- 本 Story 只聚焦于「弹幕显示层」：在播放器之上绘制弹幕，并与播放时间同步  
- 不包括弹幕开关与设置（Story 4.2）以及发送弹幕（Story 4.3）  
- UI 参考来自 Web 原型；逻辑参考 iOS / Android 原生 Demo

### Architecture Compliance

- **分层设计：**  
  - 弹幕显示层实现于 Demo App 层：`polyv_media_player/example/lib/player_skin/danmaku/`  
  - Plugin 层只提供播放核心能力和统一的状态事件（包括当前播放时间、播放状态等），不直接承担弹幕 UI 绘制，也不在原生端实现弹幕 HTTP / Repo 逻辑。  
  - PlayerController 继续作为播放进度和状态的单一真相来源，弹幕显示层仅消费 `position` / `duration` 等只读数据。

- **数据流（按新规）：**  
  - Flutter 层：
    - `DanmakuService` / `DanmakuRepository`（命名示意）负责调用 Polyv 弹幕 HTTP API（或后续统一封装的 Platform Channel 方法）按 `vid` 拉取并缓存 `Danmaku` 列表，向 UI 暴露只读数据流。  
    - `PlayerController` 通过进度事件维护 `PlayerState.position`（毫秒），对齐原生播放器的 `currentPlaybackTime` 语义。  
    - `DanmakuLayer` 同时消费 `position` 与弹幕列表，在 Widget 内部根据时间窗口与轨道分配算法计算 `activeDanmakus`，实现与 Web 原型相同的展示效果。  
  - 原生层：  
    - 只提供播放器核心能力（解码、渲染、播放控制、当前播放时间、播放状态等），不在该层发起 Polyv 弹幕 HTTP 请求，也不在该层维护弹幕业务状态。

### UI 原型参考（严格 1:1）

- **主参考文件：**  
  - `/Users/nick/projects/polyv/iOS/polyv-vod/src/components/player/DanmakuLayer.tsx`

- **关键点：**  
  - 轨道数量与间距：8 条轨道，`top = 12px + trackIndex * 32px`  
  - 展示窗口：`d.time <= currentTime && d.time > currentTime - 0.3`  
  - 展示时长：每条弹幕 8 秒（`tracksRef` 中保存每条轨道的占用截止时间）  
  - 字体大小：`small` / `medium` / `large` 映射到 `text-xs` / `text-sm` / `text-base`  
  - 透明度：通过外层容器 `style={{ opacity }}` 控制整体透明度

### Native SDK Reference & Alignment

- **iOS - `PLVVodMediaAreaVC`（行为参考）：**  
  - `initDanmu`：
    - 原生 Demo 的做法是使用 `PLVMediaPlayerDanmuModule requestDanmusWithVid:self.vid` 从服务端拉取弹幕列表，并交给 `PLVVodDanmuManager` 在 `mediaSkinContainer` 上管理与展示。  
    - 根据皮肤中的 `enableDanmu` 状态决定是否 `resume` 或 `stop`。  
  - `setupPlaybackTimer`：
    - 每 0.1 秒更新：
      - 网络加载速度  
      - 字幕位置和内容  
      - **同步显示弹幕：**
        ```objc
        if (enableDanmu && danmuManager && player.playing) {
            danmuManager.currentTime = player.currentPlaybackTime;
            [danmuManager synchronouslyShowDanmu];
        }
        ```  
  - Flutter 对齐方式：
    - 本项目不会在 iOS Plugin 中直接调用 `PLVMediaPlayerDanmuModule`，而是在 Dart 层通过 `DanmakuService` + Polyv 弹幕 HTTP API 重建相同的数据流，只借鉴上述“以 `currentPlaybackTime` 为时间基准驱动弹幕展示”的行为模式。  
    - `PlayerController` 已有 progress 事件和 `state.position`（毫秒），`DanmakuLayer` 把 `currentTime = state.position`（毫秒）映射为秒或直接使用毫秒，在内部按相同时间窗/轨道策略计算应展示的弹幕。  

- **Android - danmu 模块（行为参考）：**  
  - `common/ui/component/danmu/PLVMediaPlayerDanmuLayout.kt`：负责在视频上绘制弹幕。  
  - `common/modules/danmu/viewmodel/PLVMPDanmuViewModel.kt`：管理弹幕数据、样式和开关，内部与 SDK 的 `danmuManager` 协同工作。  
  - `PLVMediaPlayerDanmuInputActivity.kt`：负责输入与发送（对应后续 Story 4.3）。  
  - Flutter 对齐方式：
    - 在 Dart 层同样将「布局组件」(`DanmakuLayer` Widget) 与「数据/状态」(`DanmakuController` / `DanmakuService` / `PlayerController`) 分离，避免在原生端维护业务状态。  
    - 不直接依赖 `addonBusinessManager().danmu` 作为 Flutter 端的唯一数据源，而是以其行为为对标，在 Dart 层实现等价的 ViewModel / Service，统一服务 iOS 与 Android。

### Testing Requirements

- **Widget 测试：**  
  - 验证 `enabled == false` 时不渲染任何弹幕节点  
  - 固定 `currentTime`，构造多条不同 `time` 的弹幕，验证只有满足时间条件的弹幕出现在 Widget 树中  
  - 验证不同 `fontSize` 和 `opacity` 对视觉效果的影响（可通过 TextStyle 和 Opacity 组件断言）

- **集成测试（后续可在 Story 4.2/4.3 扩展）：**  
  - 在真实播放器页面上集成 `DanmakuLayer`，播放固定视频片段：
    - 观察弹幕是否按时间精准出现并沿轨道滚动  
    - 快速 seek 前后弹幕是否正确重算，不重复显示  

### References

- `docs/planning-artifacts/epics.md#epic-4-弹幕功能`  
- `/Users/nick/projects/polyv/iOS/polyv-vod/src/components/player/DanmakuLayer.tsx`  
- `/Users/nick/projects/polyv/iOS/polyv-ios-media-player-sdk-demo/PLViOSMediaPlayerDemo/PolyvIOSMediaPlayerDemo/PolyvVodScenes/Secenes/VodScene/MediaArea/PLVVodMediaAreaVC.m`  
- `/Users/nick/projects/polyv/android/polyv-android-media-player-sdk-demo/common/src/main/java/net/polyv/android/player/common/ui/component/danmu/`

## Dev Agent Record

### Agent Model Used

- Cascade (实现阶段)
- Opus 4.5 (测试与验证阶段)

### Debug Log References

- 无重大问题，实现顺利

### Completion Notes List

- 2026-01-21: Story 4.1 文档创建完成（status: backlog）
- 2026-01-21: 弹幕显示层组件实现完成
  - 创建 `DanmakuLayer` Widget，精确 1:1 还原 Web 原型 UI
  - 实现 8 轨道弹幕显示，轨道间距 32px，顶部偏移 12px
  - 实现从右向左的滚动动画，时长 8 秒
  - 支持透明度、字体大小（small/medium/large）配置
  - 使用 `IgnorePointer` 确保弹幕不拦截视频手势
- 2026-01-21: 弹幕数据模型与服务实现完成
  - 创建 `Danmaku` 数据模型，支持 id/text/time/color/type 属性
  - 创建 `ActiveDanmaku` 扩展模型，增加 track 和 startTime
  - 实现 `DanmakuService` 接口和 `MockDanmakuService` 测试实现
  - 弹幕数据统一在 Dart 层获取，原生层不参与弹幕业务逻辑
- 2026-01-21: PlayerController 状态集成完成
  - 在 `LongVideoPage` 中集成 `DanmakuLayer`
  - 使用 `AnimatedBuilder` 监听 `state.position` 驱动弹幕时间窗口
  - 实现 `_loadDanmakus` 方法加载弹幕数据
- 2026-01-21: Widget 测试编写完成，14 个测试全部通过
  - 验证 `enabled == false` 时不渲染弹幕
  - 验证时间窗口条件过滤（300ms 窗口 + 8s 动画时长）
  - 验证 fontSize 和 opacity 正确应用
  - 验证多条弹幕分配到不同轨道
  - 验证数据模型 equality/copyWith/fromJson/isExpired 等方法
- 2026-01-21: Code Review 修复完成
  - 修复 seek 向后拖动时弹幕不重新显示的问题（添加 `_lastCurrentTime` 检测）
  - 修复 top/bottom 类型弹幕不支持显示的问题（添加固定位置渲染逻辑）
  - 改进轨道分配算法（top 使用轨道 0-3，bottom 使用轨道 4-7）
  - 更新 File List 文档，补充缺失的测试文件和 home_page.dart 修改说明

### File List

#### 新建文件
- `polyv_media_player/example/lib/player_skin/danmaku/danmaku_model.dart` - 弹幕数据模型（Danmaku、ActiveDanmaku、DanmakuType、DanmakuFontSize）
- `polyv_media_player/example/lib/player_skin/danmaku/danmaku_service.dart` - 弹幕服务接口与 Mock 实现
- `polyv_media_player/example/lib/player_skin/danmaku/danmaku_layer.dart` - 弹幕显示层 Widget
- `polyv_media_player/example/lib/player_skin/danmaku/danmaku.dart` - 弹幕模块导出文件
- `polyv_media_player/example/lib/player_skin/danmaku/danmaku_layer_test.dart` - Widget 测试
- `polyv_media_player/example/lib/player_skin/danmaku/danmaku_model_edge_cases_test.dart` - 模型边界情况测试
- `polyv_media_player/example/lib/player_skin/danmaku/danmaku_service_test.dart` - 服务测试
- `polyv_media_player/example/lib/player_skin/danmaku/danmaku_layer_edge_cases_test.dart` - 弹幕层边界情况测试

#### 修改文件
- `polyv_media_player/example/lib/pages/home_page.dart` - 集成 DanmakuLayer 到 LongVideoPage（添加弹幕状态管理、_loadDanmakus 方法、_buildDanmakuLayer 组件）

### Change Log

- 2026-01-21: 实现 Story 4.1 弹幕显示层
  - 新增弹幕显示层组件，支持从右向左滚动动画
  - 新增弹幕数据模型与服务接口
  - 集成到长视频播放页面，与 PlayerController 状态同步
  - 编写完整的 Widget 测试覆盖

### Status

- 实现: 完成
- 测试: 通过（14/14 tests passed）
- 验收标准: 全部满足
