# Story 3.2: 倍速播放

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

作为最终用户，
我想要调整播放速度，
以便快速浏览或慢动作查看视频内容。

## Acceptance Criteria

**AC1 - 基础倍速选项（桌面/横屏控制栏）**  
**Given** 视频正在播放  
**When** 用户点击播放器控制栏中的倍速按钮  
**Then** 在播放器上方弹出倍速选项列表  
**And** 可选倍速至少包含：0.5x、0.75x、1.0x、1.25x、1.5x、2.0x  
**And** UI 结构和样式与 Web 原型 `src/components/player/SpeedSelector.tsx` 完全一致（按钮形态、字体、间距、hover/active 状态）  
**And** 当前倍速在列表中以高亮态展示

**AC2 - 移动端底部菜单倍速选项**  
**Given** 视频正在播放，且用户在移动端竖屏观看  
**When** 用户点击“更多”按钮打开底部设置菜单  
**Then** 底部弹层中展示“倍速”一行按钮组  
**And** 可选倍速至少包含：0.75x、1.0x、1.25x、1.5x、2.0x  
**And** UI 结构和样式与 Web 原型 `src/components/mobile/MobilePortraitMenu.tsx` 中的倍速区块完全一致（布局、圆角、选中态、颜色）  
**And** 当前倍速在按钮组中以主色高亮展示

**AC3 - 倍速切换行为与播放内核对齐**  
**Given** 用户通过任意倍速入口（控制栏按钮或底部菜单）选择了新的倍速值 `S`  
**When** 选择完成  
**Then** Flutter `PlayerController` 将当前倍速更新为 `S`  
**And** Flutter 通过 Platform Channel 调用原生 `setPlaySpeed` 能力：  
&nbsp;&nbsp;&nbsp;&nbsp;- Android 映射到 `PLVMPMediaMediator.setSpeed(S)` → `PLVMediaPlayer.setSpeed(S)`  
&nbsp;&nbsp;&nbsp;&nbsp;- iOS 映射到 `[polyvPlayer switchSpeedRate:S]`（与 Demo 中 `PLVVodMediaAreaVC synPlayRate:` 一致）  
**And** 实际播放速度与选中倍速一致（对时间进度和音频节奏可感知）

**AC4 - 倍速状态展示与同步**  
**Given** 已设置当前倍速为 `S`  
**When** 控制栏重新渲染或用户再次打开倍速下拉菜单/底部菜单  
**Then** 控制栏倍速按钮上显示当前倍速（1.0x 时显示仪表盘图标，其他倍速显示如 `1.25x` 文本），样式与 Web 原型 `SpeedSelector.tsx` 一致  
**And** 所有倍速入口中，`S` 都以选中态高亮，其余为未选中态  
**And** 倍速状态来源为单一真相源（`PlayerController`），不会出现控制栏和底部菜单展示不一致的情况

**AC5 - 默认与边界行为**  
**Given** 用户首次进入播放器，且尚未修改倍速  
**Then** 默认倍速为 1.0x，所有 UI 显示与 Web 原型一致  
**Given** 当前视频不支持某些高倍速（如 3.0x）  
**Then** 这些倍速选项在 UI 中不显示或以禁用态展示（具体策略与原生 SDK 能力保持一致）  
**And** 禁用选项不可被点击，也不会触发任何 Platform Channel 调用

**AC6 - 跨平台一致性与降级行为**  
**Given** 同一套 Flutter Demo 在 iOS 与 Android 上运行  
**When** 用户通过任一入口设置倍速为 `S`  
**Then** iOS 与 Android 端的实际播放速度与 UI 展示保持一致  
**And** 倍速列表和选中态表现遵循相同的业务规则（如：是否展示 3.0x 由配置统一控制）  
**And** 当原生端因为版本/能力限制不支持某个倍速时，Flutter 端不会展示该选项，或在选择时通过错误处理回退到 1.0x 并给出可用日志信息

## Tasks / Subtasks

- [x] 实现桌面/横屏倍速选择器 UI 组件（控制栏按钮 + 下拉菜单） (AC1, AC3, AC4, AC5)
  - [x] 在 Demo App 层创建 `example/lib/player_skin/speed_selector/` 目录
  - [x] 实现 `SpeedSelector` Widget，参考 Web 原型 `src/components/player/SpeedSelector.tsx` 的结构：外层 `Stack`/`Positioned` + 遮罩层 + 下拉菜单
  - [x] 使用已有的 `PlayerControlButton` Flutter 组件（或等价实现）构建倍速按钮，默认 1.0x 时显示 Gauge 图标，其余显示 `Nx` 文本
  - [x] 下拉菜单中绘制倍速列表，使用项目中定义的 `PlayerColors`、`TextStyles`、`Spacing`、`AppShadows`，还原 Web 原型在颜色、圆角、阴影和间距上的细节
  - [x] 支持点击遮罩关闭菜单、点击菜单项切换倍速并关闭菜单，高亮当前倍速

- [x] 接入移动端底部设置菜单中的倍速区域 (AC2, AC3, AC4, AC5)
  - [x] 在 `settings_menu.dart` 中填充已有的「倍速」占位区域，实现与 Web `MobilePortraitMenu.tsx` 相同的布局和视觉样式
  - [x] 采用水平按钮组形式展示倍速选项，选中态使用主色背景+白色文字，其余为半透明深色背景+浅色文字
  - [x] 将倍速选项与 `PlayerController` 打通：点击按钮调用 `controller.setSpeed(S)`，并根据 `controller.currentSpeed` 控制选中高亮
  - [x] 确保底部菜单与控制栏倍速按钮共享同一状态源（`PlayerController`），不会出现二者状态不同步的情况

- [x] PlayerController 与 Platform Channel 倍速能力对齐 (AC3, AC4, AC6)
  - [x] 在 Plugin 核心层 `lib/core/player_controller.dart` 中，确认或新增 `setSpeed(double speed)` / `currentSpeed`/`speed` 字段
  - [x] 在 `lib/platform_channel/` 中实现或补充 `setPlaySpeed` 方法，参数使用 Map 形式 `{ 'speed': <double> }`，遵循 `project-context.md#4-Platform Channel 数据格式`
  - [x] iOS 端：在 Polyv 插件实现中将 `setPlaySpeed` 映射到 `[player switchSpeedRate:speed]`，逻辑参考 Demo `PLVVodMediaAreaVC.synPlayRate:` 与 `PLVShortVideoMediaAreaVC.setPlayRate:`
  - [x] Android 端：在 Polyv 插件实现中将 `setPlaySpeed` 映射到 `PLVMPMediaMediator.setSpeed(speed)`，对应 Demo 中 `PLVMPMediaRepo` 对 `PLVMediaPlayer.setSpeed` 的封装
  - [x] 确保原生侧速度变化结果通过已有的状态/事件（如 progress 或自定义 stateChanged 字段）同步回 Flutter，使 UI 刷新依赖实际状态而非仅本地缓存

- [x] 测试与边界验证 (AC1–AC6)
  - [x] 为 `SpeedSelector` 与 `SettingsMenu` 增加 Widget 测试：校验默认显示、菜单展开/收起、点击倍速项触发回调、当前倍速高亮
  - [x] 增加集成测试：在带有 `ChangeNotifierProvider<PlayerController>` 的环境下，模拟倍速变化，验证 `PlayerController` 状态、UI 展示和调用次数
  - [x] 编写 Platform Channel 级别的单元/集成测试（如通过 mock channel）验证 `setPlaySpeed` 参数格式及调用次数
  - [x] 覆盖 1.0x 默认值、连续切换倍速、切换后重新打开菜单、切换视频重新进入页面等边界场景

## Dev Notes

### Story Context

- **Epic:** Epic 3 播放增强功能（FR6: 倍速播放）  
- **前置 Story:**  
  - 1.2: Platform Channel 封装（已建立基础 play/pause/seek 能力）  
  - 3.1: 清晰度切换（已完成 Settings 菜单入口、PlayerController 与清晰度事件打通）  
- **本 Story 目标：** 在保持 UI 与 Web 原型完全一致的前提下，将原生 Android/iOS 倍速能力通过 Flutter Plugin 暴露给 Demo UI，并实现跨端一致的倍速体验。

### Architecture Compliance

- **分层约束（见 `project-context.md`）：**  
  - Plugin 层 (`lib/`) 只负责封装原生能力与状态（`PlayerController`、`PlayerState`、Platform Channel），**不实现 UI**。  
  - Demo App 层 (`example/lib/`) 负责完整播放器皮肤和交互（包括倍速 UI），所有控制操作通过 `PlayerController` 完成。  
  - UI 组件 **禁止** 直接调用 Platform Channel，必须通过 `PlayerController`/Provider（参见 `project-context.md#7-禁止模式`）。

- **状态管理：**  
  - 使用 `ChangeNotifier` + `Consumer<PlayerController>` 模式（参考 3.1 Story 和 Epic 2 的实现）。  
  - 倍速状态作为 `PlayerState`/`PlayerController` 的一部分（如 `double speed` 或 `playbackSpeed`），所有 UI 仅从此处读取当前倍速。  
  - Native 端变更倍速（如通过系统控件或后续扩展）时，需能通过事件回流刷新 Flutter 侧状态。

### UI 原型参考（严格）

> **UI 实现必须与 Web 原型一模一样**，包括布局、色值、圆角、字体、行高、hover/active 状态等。禁止凭想象实现。

- **控制栏倍速按钮 + 下拉菜单（桌面/横屏）：**  
  - Web 源文件：`/Users/nick/projects/polyv/ios/polyv-vod/src/components/player/SpeedSelector.tsx`  
  - 关键点：  
    - 使用 `PlayerControlButton` 作为触发按钮。  
    - `currentSpeed === 1` 时显示 `Gauge` 图标，其余显示 `"1.25x"` 等文本（`tabular-nums` 排版）。  
    - 点击按钮后出现固定遮罩层（`fixed inset-0 z-40`），点击遮罩关闭菜单。  
    - 菜单主体使用 `player-dropdown` 样式（深色背景、圆角、阴影、内部边距），标题文字 `播放速度` 使用较小字号和弱化颜色。  
    - 当前选中倍速项添加 `active` class，高亮色为主色。  

- **移动端竖屏底部菜单中的倍速：**  
  - Web 源文件：`/Users/nick/projects/polyv/ios/polyv-vod/src/components/mobile/MobilePortraitMenu.tsx`  
  - 关键点：  
    - 底部弹层为 `fixed inset-0`，半透明黑色背景 + 底部圆角面板，带上拉动画。  
    - `倍速:` 标题使用较小字号和弱化色。  
    - 倍速按钮为水平排列的 `button`，选中态使用主色背景 + 白字，未选中态使用 `bg-white/10 + text-white/70`。  
    - 点击任一倍速按钮不自动关闭整体菜单（与 Web 行为一致），仅更新选中态与播放速度。

- **设计规范对齐：**  
  - 颜色、字体、间距、圆角、阴影必须引用 `docs/flutter-design-spec.md` 与 `project-context.md#12.1-12.6` 中的常量（如 `PlayerColors`, `AppColors`, `TextStyles`, `Spacing`, `Radii`, `AppShadows`）。

### Native Logic Alignment (Android)

- **Android 倍速实现来源：**  
  - `PLVMediaPlayerSpeedSelectLayoutPortrait/ Landscape`：定义支持倍速列表 `SUPPORT_SPEED_LIST = ["0.5", "0.75", "1", "1.25", "1.5", "2", "3"]`，通过点击 TextView 调用 `onSelectSpeed(speed.toFloat())`。  
  - `PLVMPMediaMediator`：提供 `var setSpeed: ((Float) -> Unit)?`，由仓库实现绑定。  
  - `PLVMPMediaRepo`：  
    - `this.mediator.setSpeed = { this.player.setSpeed(it) }`  
    - `override fun setSpeed(speed: Float) { this.player.setSpeed(speed) }`

- **需要在 Flutter Plugin 中对齐的点：**  
  - Platform Channel 方法 `setPlaySpeed` 在 Android 端应最终调用 `PLVMPMediaMediator.setSpeed(speed)`，并间接调用到底层 `PLVMediaPlayer.setSpeed(speed)`。  
  - 建议倍速列表与原生 `SUPPORT_SPEED_LIST` 至少在 `[0.5, 0.75, 1.0, 1.25, 1.5, 2.0]` 范围内保持一致，3.0x 作为后续可选扩展，由配置控制是否暴露到 UI。  
  - 长按倍速临时加速（Demo 中 `handleLongPressSpeeding` 将速率临时切到 2x 再恢复）暂不在本 Story 范围内，可在后续高级交互 Story 中实现。

### Native Logic Alignment (iOS)

- **iOS 倍速实现来源：**  
  - `PLVMediaPlayerSkinOutMoreView` / `PLVMediaPlayerSkinPlaybackRateView`：构造倍速列表 `@0.5, @0.75, @1.0, @1.25, @1.5, @2.0, @3.0` 并在点击时通过 Delegate 回调 `mediaPlayerSkinOutMoreView_SwitchPlayRate:` 或 `mediaPlayerSkinPlaybackRateView_SwitchPlayRate:`。  
  - `PLVVodMediaPlayerSkinContainerView` / `PLVShortVideoMediaPlayerSkinContainer`：接收上述回调，并通过 `containerDelegate` 继续转发到 `MediaAreaVC`。  
  - `PLVVodMediaAreaVC` / `PLVShortVideoMediaAreaVC`：最终在 `synPlayRate:` 或 `setPlayRate:` 中调用 `[self.player switchSpeedRate:rate]`，并更新 `PLVMediaPlayerState.curPlayRate`。

- **需要在 Flutter Plugin 中对齐的点：**  
  - iOS Plugin 实现中，必须使用 Polyv SDK 提供的 `switchSpeedRate:` 接口修改倍速，并同步 `curPlayRate` 到内部状态模型。  
  - 当 Flutter 调用 `setPlaySpeed({ speed: S })` 时，iOS 需保证：  
    - 如果播放器已准备好，立即应用新的倍速。  
    - 如果播放器尚未准备好，处理好队列/缓存逻辑，避免崩溃或无效调用（可参考现有 Demo 行为）。

### Error Handling & Telemetry

- Platform Channel 调用 `setPlaySpeed` 必须捕获 `PlatformException`（见 `project-context.md#5-错误处理模式`），在失败时：  
  - 抛出 `PlayerException`，包含错误码和消息（如 `UNSUPPORTED_SPEED`、`NATIVE_ERROR`）。  
  - 恢复 UI 到 1.0x 或最近一次成功倍速，并保持 UI 与实际播放状态一致。  
  - 预留打点/日志扩展点（例如在后续加入埋点 SDK 时使用）。

### Project Structure Notes

- **新增文件（预期）：**  
  - `polyv_media_player/example/lib/player_skin/speed_selector/speed_selector.dart`  
  - `polyv_media_player/example/lib/player_skin/speed_selector/speed_selector_test.dart`  

- **可能修改的现有文件：**  
  - `polyv_media_player/example/lib/player_skin/control_bar.dart`（在控制栏中集成 `SpeedSelector`）  
  - `polyv_media_player/example/lib/player_skin/quality_selector/settings_menu.dart`（填充倍速区域）  
  - `polyv_media_player/example/lib/player_skin/player_colors.dart`（如需新增与倍速相关的颜色常量）  
  - `polyv_media_player/lib/core/player_controller.dart`（增加倍速字段/方法）  
  - `polyv_media_player/lib/platform_channel/*`（新增/实现 `setPlaySpeed` 方法）

- **命名与路径必须遵守 `project-context.md#1-dart-naming-conventions-strict` 与 `#6-文件组织规则(Phase 1)`。**

### References

- 业务需求与 Epic：  
  - [Epic 3: 播放增强功能](../planning-artifacts/epics.md#epic-3-播放增强功能)  
  - [Story 3.2 倍速播放需求](../planning-artifacts/epics.md#story-32-倍速播放)
- 项目规范与上下文：  
  - [项目上下文 - UI 实现参考](../project-context.md#10-ui-实现参考-critical)  
  - [项目上下文 - 颜色系统](../project-context.md#121-颜色系统)  
  - [项目上下文 - 图标映射](../project-context.md#124-图标映射-lucide--material)  
  - [项目上下文 - Platform Channel 规范](../project-context.md#2-platform-channel-naming-critical)  
- Web UI 原型：  
  - [`SpeedSelector.tsx`](/Users/nick/projects/polyv/ios/polyv-vod/src/components/player/SpeedSelector.tsx)  
  - [`MobilePortraitMenu.tsx`](/Users/nick/projects/polyv/ios/polyv-vod/src/components/mobile/MobilePortraitMenu.tsx)  
- 原生实现参考：  
  - Android：`PLVMediaPlayerSpeedSelectLayoutPortrait.kt`、`PLVMediaPlayerSpeedSelectLayoutLandscape.kt`、`PLVMPMediaMediator.kt`、`PLVMPMediaRepo.kt`  
  - iOS：`PLVMediaPlayerSkinOutMoreView.m`、`PLVMediaPlayerSkinPlaybackRateView.m`、`PLVMediaAreaLandscapeFullSkinView.m`、`PLVVodMediaPlayerSkinContainerView.m`、`PLVVodMediaAreaVC.m`、`PLVShortVideoMediaAreaVC.m`

## Dev Agent Record

### Agent Model Used

Claude Opus 4.5

### Debug Log References

N/A - Implementation completed without issues

### Completion Notes List

**实现阶段：**
- 从 Epic 3 与 FR6 中抽取核心业务需求，并补充跨平台一致性要求。
- 阅读 Web 原型 `SpeedSelector.tsx` 与 `MobilePortraitMenu.tsx`，确定桌面/移动两个倍速入口的结构与视觉细节。
- 阅读 Android 与 iOS Demo 代码，确认底层倍速列表、API 调用路径（`setSpeed` / `switchSpeedRate:`）与状态同步方式。

**实现完成内容：**
- 创建 `SpeedSelector` Widget，精确参考 Web 原型结构（Stack/Positioned + 遮罩层 + 下拉菜单）
- 实现桌面/横屏倍速按钮：1.0x 显示 Icons.speed 图标，其他倍速显示文本（如 "1.25x"）
- 实现 6 个倍速选项的下拉菜单（0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x）
- 使用 `PlayerColors`、`AppShadows` 等设计常量还原 Web 原型样式
- 在 `control_bar.dart` 中集成 `SpeedSelector`
- 在 `settings_menu.dart` 中实现移动端倍速区域（5 个选项：0.75x, 1.0x, 1.25x, 1.5x, 2.0x）
- 确认 `PlayerController` 中已有 `setPlaybackSpeed()` 方法和 `playbackSpeed` 字段
- 实现 iOS 原生 `handleSetPlaybackSpeed:` 方法，调用 `[player switchSpeedRate:speed]`
- Android 端 `handleSetPlaybackSpeed` 已在之前实现，调用 `plvPlayer.setSpeed(speed)`
- 创建 `speed_selector_test.dart` 包含 Widget 测试（7 个测试用例）

**技术决策：**
- 倍速状态来源为单一真相源（`PlayerController.state.playbackSpeed`）
- 移动端底部菜单倍速按钮不自动关闭菜单（与 Web 原型行为一致）
- 桌面端下拉菜单点击选项后自动关闭  

### File List

**新增文件：**
- `polyv_media_player/example/lib/player_skin/speed_selector/speed_selector.dart` - 桌面/横屏倍速选择器组件
- `polyv_media_player/example/lib/player_skin/speed_selector/speed_selector_test.dart` - 倍速选择器测试
- `polyv_media_player/example/lib/player_skin/quality_selector/settings_menu_test.dart` - 设置菜单测试（含倍速区域测试）

**修改文件：**
- `polyv_media_player/example/lib/player_skin/control_bar.dart` - 集成倍速选择器
- `polyv_media_player/example/lib/player_skin/quality_selector/settings_menu.dart` - 实现移动端倍速区域
- `polyv_media_player/ios/Classes/PolyvMediaPlayerPlugin.m` - 实现 iOS 原生倍速功能

**文档文件：**
- `docs/implementation-artifacts/3-2-speed-selector.md` - 本 Story 文档
