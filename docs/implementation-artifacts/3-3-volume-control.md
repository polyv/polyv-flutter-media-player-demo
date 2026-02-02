# Story 3.3: 音量控制

Status: waived

<!-- WAIVED REASON:
移动端用户习惯使用物理音量键调节音量，应用内音量控制优先级较低。
如未来需要桌面端支持或有特殊场景需求，可重新评估。
-->

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

作为最终用户，
我想要调节播放音量或静音，
以便在观看视频时获得合适的音频体验。

## Acceptance Criteria

**AC1 - 音量控制组件 UI (桌面/横屏)**
**Given** 视频正在播放
**When** 用户将鼠标悬停在控制栏的音量图标上（或点击）
**Then** 向右展开音量滑块
**And** 滑块样式与 Web 原型 `src/components/player/VolumeControl.tsx` 一致（动画、颜色、圆角）
**And** 图标根据音量状态变化：
  - 静音或音量为 0：显示 `VolumeX` 图标
  - 音量 < 0.5：显示 `Volume1` 图标
  - 音量 >= 0.5：显示 `Volume2` 图标
**And** 鼠标移出后滑块自动收起

**AC2 - 静音切换交互**
**Given** 视频正在播放且有声音
**When** 点击音量图标
**Then** 切换为静音状态
**And** 图标变为 `VolumeX`
**And** 滑块进度归零
**When** 再次点击音量图标
**Then** 恢复静音前的音量值
**And** 图标恢复对应状态

**AC3 - 音量调节逻辑**
**Given** 音量滑块可见
**When** 拖动或点击滑块
**Then** 播放器音量实时更新
**And** 音量值在 0.0 到 1.0 之间变化
**And** 状态通过 `PlayerController` 同步

**AC4 - 原生能力对接 (Android)**
**Given** Flutter 端调用 `setVolume(double value)`
**When** 传递到 Android 原生端
**Then** Android 端将 0.0-1.0 的浮点数映射为 0-100 的整数
**And** 调用 `PLVMPMediaRepo.setVolume(int volume)`
**And** 最终调用底层 `player.setVolume(volume)`

**AC5 - 原生能力对接 (iOS)**
**Given** Flutter 端调用 `setVolume(double value)`
**When** 传递到 iOS 原生端
**Then** iOS 端接收 0.0-1.0 的浮点数
**And** 调用 `[player setPlaybackVolume:volume]` (参考 `PLVIJKMediaPlayback` 协议)
**And** 确保音量变化生效

**AC6 - 移动端 UI 适配**
**Given** 在移动端（竖屏/横屏）
**Then** 同样显示音量控制组件（参考 Web `MobileVideoPlayer.tsx`，虽然移动端通常用手势，但 Web 原型中保留了控制栏音量按钮）
**And** 交互方式适配触摸（点击展开/收起，而非 Hover）

## Tasks / Subtasks

- [ ] 实现音量控制 UI 组件 `VolumeControl` (AC1, AC2, AC3, AC6)
  - [ ] 参考 `VolumeControl.tsx` 实现 Flutter Widget
  - [ ] 实现展开/收起动画 (`AnimatedContainer` 或 similar)
  - [ ] 集成 `PlayerControlButton` 和 `Slider` (或自定义 Slider 样式以匹配原型)
  - [ ] 处理图标状态变化逻辑

- [ ] 更新 `PlayerController` 与状态模型 (AC3)
  - [ ] 在 `PlayerController` 中添加 `setVolume(double)` 和 `toggleMute()` 方法
  - [ ] 在 `PlayerState` 中添加 `volume` (double) 和 `muted` (bool) 字段
  - [ ] 确保 `setVolume(0)` 自动触发 `muted=true`，非 0 触发 `muted=false`
  - [ ] 实现静音前音量记忆逻辑 (`_lastVolume`)

- [ ] 实现 Platform Channel 音量接口 (AC4, AC5)
  - [ ] 定义 `setVolume` 方法通道调用
  - [ ] iOS 端：在 `PolyvMediaPlayerPlugin.m` 中实现 `setVolume`，调用 `player.playbackVolume`
  - [ ] Android 端：在 `PolyvMediaPlayerPlugin.kt` 中实现 `setVolume`，转换范围后调用 `mediator.setVolume`

- [ ] 集成测试与验证
  - [ ] 验证 UI 交互（点击静音、拖动滑块）
  - [ ] 验证原生调用（通过日志或实际听感）
  - [ ] 验证跨平台一致性（Android 0-100 vs iOS 0.0-1.0 的映射准确性）

## Dev Notes

### Story Context
- **Epic:** Epic 3 播放增强功能
- **参考代码:**
  - Web: `src/components/player/VolumeControl.tsx`
  - Android: `net/polyv/android/player/common/modules/media/model/PLVMPMediaRepo.kt`
  - iOS: `PLVIJKMediaPlayback.h` (IJKPlayer 属性)

### Architecture Compliance
- **状态管理:** 所有的音量状态必须由 `PlayerController` 管理，UI 仅作为 `Consumer`。
- **UI 规范:** 严格遵守 Web 原型的视觉风格（颜色、图标、动画曲线）。
- **原生接口:** 必须使用 `player.setVolume` (Android) 和 `playbackVolume` (iOS)，**不** 控制系统物理音量（系统音量留给 Epic 7 的手势控制）。

### Native Logic Alignment
- **Android:**
  - `PLVMPMediaRepo` 封装了 `setVolume(int)`。Flutter 传来的 double (0.0-1.0) 需要乘以 100 转为 int。
- **iOS:**
  - `PLVIJKMediaPlayback` 协议定义了 `@property(nonatomic) float playbackVolume;`。
  - 需要在 Plugin 中通过 KVC 或直接 setter 设置该属性。注意 iOS 端可能没有直接暴露 `setVolume:` 方法，而是通过属性赋值。

### Error Handling
- 调用 Platform Channel 需捕获 `PlatformException`，如调用失败应回滚 Flutter 侧的音量状态显示。
