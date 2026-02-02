# Story 2.1: 进度条组件

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

作为最终用户，
我想要看到播放进度条，
以便了解视频播放进度。

## Acceptance Criteria

**Given** 视频正在播放
**When** 进度更新
**Then** 进度条显示当前播放位置
**And** 已播放部分有视觉区分
**And** 支持拖动进度条
**When** 拖动进度条到某位置
**Then** 视频跳转到对应位置

## Tasks / Subtasks

- [x] 创建进度条组件结构 (AC: Given, When, Then)
  - [x] 创建 `example/lib/player_skin/progress_slider/` 目录
  - [x] 创建 `progress_slider.dart` 主文件
  - [x] 创建 `time_label.dart` 时间显示组件（Story 2.2 用的，提前准备）
  - [x] 使用 Consumer<PlayerController> 获取播放状态
- [x] 实现进度条视觉层 (AC: Then, And)
  - [x] 创建 SliderTheme 配置（参考原型样式）
  - [x] 已播放进度使用 PlayerColors.progress (0xFFE8704D)
  - [x] 缓冲进度使用 PlayerColors.progressBuffer (0xFF3D4560)
  - [x] 背景使用 PlayerColors.controls (0xFF2D3548)
  - [x] 进度条高度：4-6px，hover 时 8px（参考原型）
- [x] 实现进度数据绑定 (AC: When, Then)
  - [x] 从 PlayerState 获取 position, duration, bufferedPosition
  - [x] 计算播放进度：state.progress (0.0 - 1.0)
  - [x] 计算缓冲进度：state.bufferProgress (0.0 - 1.0)
  - [x] 使用 Slider.value 绑定当前播放位置
- [x] 实现 seek 拖动功能 (AC: And, When, Then)
  - [x] 监听 Slider.onChanged 事件
  - [x] 拖动时计算目标位置：value * duration
  - [x] 调用 controller.seekTo(目标位置)
  - [x] 拖动过程中不持续调用（使用 onChangeEnd 或防抖）
- [x] 实现时间显示组件 (AC: Then)
  - [x] 创建 formatTime 方法：毫秒 → MM:SS 或 HH:MM:SS
  - [x] 显示当前时间在进度条左侧
  - [x] 显示总时长在进度条右侧
  - [x] 字体样式：TextStyles.caption (11px, mutedForeground)
- [x] 集成到播放器皮肤 (AC: Given)
  - [x] 在 control_bar.dart 中导入 ProgressSlider
  - [x] 布局位置：播放/暂停按钮下方，横排全宽
  - [x] 时间显示在进度条两侧
- [x] 测试进度条功能 (AC: Given, When, Then)
  - [x] 测试进度条正确显示播放位置
  - [x] 测试拖动进度条触发 seek
  - [x] 测试缓冲进度正确显示
  - [x] 测试时间格式化正确（分:秒）

## Dev Notes

### Story Context

**Epic 2: 播放进度与时间显示**
- 这是 Epic 2 的第一个 Story，实现视频播放进度的可视化
- Epic 2 包含 3 个 Stories：进度条(2.1)、时间显示(2.2)、缓冲进度(2.3)
- 本 Story 将同时实现进度条和时间显示，为后续 Stories 提供基础

**前置依赖：**
- Epic 1 Story 1.3 已完成 - PlayerController 已有完整的进度事件支持
- PlayerState 已包含 position, duration, bufferedPosition 字段
- progress 和 bufferProgress 计算方法已实现

### Architecture Compliance

**组件位置：**
```
example/lib/player_skin/progress_slider/
├── progress_slider.dart    # 进度条组件
└── time_label.dart         # 时间显示组件（Story 2.2 使用）
```

**状态管理模式：**
```dart
// 使用 Consumer<PlayerController> 获取状态
Consumer<PlayerController>(
  builder: (context, controller, child) {
    final state = controller.state;
    return ProgressSlider(
      value: state.progress,          // 0.0 - 1.0
      bufferValue: state.bufferProgress,  // 0.0 - 1.0
      duration: state.duration,       // 总时长（毫秒）
      position: state.position,       // 当前位置（毫秒）
      onSeek: (position) => controller.seekTo(position),
    );
  },
)
```

**命名约定：**
- 组件类：PascalCase → `ProgressSlider`, `TimeLabel`
- 方法：camelCase → `formatTime`, `handleSeek`
- 变量：camelCase → `playedPercent`, `bufferedPercent`

### Previous Story Intelligence

**从 Story 1.3 学到的经验：**

1. **PlayerState 已有进度支持**
   - `position` - 当前播放位置（毫秒）
   - `duration` - 总时长（毫秒）
   - `bufferedPosition` - 缓冲位置（毫秒）
   - `progress` - 播放进度 (0.0 - 1.0)
   - `bufferProgress` - 缓冲进度 (0.0 - 1.0)

2. **seekTo 方法已实现**
   ```dart
   // 直接调用即可
   await controller.seekTo(position);  // position 是毫秒
   ```

3. **事件流已配置**
   - progress 事件会自动更新 PlayerState
   - 使用 Consumer<PlayerController> 即可自动刷新 UI

4. **代码模式**
   - 所有 Platform Channel 调用都有 PlatformException 处理
   - 状态更新使用 `_updateState()` + `notifyListeners()`

### UI 原型参考

**原型文件：** `/Users/nick/projects/polyv/ios/polyv-vod/src/components/player/PlayerProgress.tsx`

**关键样式提取：**
```tsx
// 进度条结构
<div className="progress-container">
  {/* 缓冲进度 */}
  <div className="progress-buffer" style={{ width: `${bufferedPercent}%` }} />
  {/* 已播放进度 */}
  <div className="progress-played" style={{ width: `${playedPercent}%` }} />
  {/* 拖动手柄 */}
  <div className="progress-thumb" style={{ left: `calc(${playedPercent}% - 8px)` }} />
</div>
```

**颜色样式（从原型 CSS 提取）：**
- 已播放：`#E8704D` (PlayerColors.progress)
- 缓冲：`#3D4560` (PlayerColors.progressBuffer)
- 背景：`#2D3548` (PlayerColors.controls)
- 悬停提示：`#1E2432` 背景，白色文字

**Flutter 实现对应：**
```dart
// 使用 Slider 组件
SliderTheme(
  data: SliderThemeData(
    activeTrackColor: PlayerColors.progress,
    inactiveTrackColor: PlayerColors.controls,
    secondaryActiveTrackColor: PlayerColors.progressBuffer,  // 缓冲进度
    thumbColor: PlayerColors.progress,
    overlayColor: PlayerColors.progress.withOpacity(0.2),
    trackHeight: 4,
    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
  ),
  child: Slider(
    value: controller.state.progress,
    max: 1.0,
    onChanged: (value) {
      // 拖动结束再 seek，避免频繁调用
      final position = (value * controller.state.duration).toInt();
      controller.seekTo(position);
    },
  ),
)
```

### Technical Requirements

**时间格式化：**
```dart
String formatTime(int milliseconds) {
  final seconds = milliseconds ~/ 1000;
  final mins = seconds ~/ 60;
  final secs = seconds % 60;

  if (mins >= 60) {
    final hours = mins ~/ 60;
    final remainingMins = mins % 60;
    return '${hours}:${remainingMins.toString().padLeft(2, '0')}:${secs.toString().padStart(2, '0')}';
  }
  return '${mins}:${secs.toString().padStart(2, '0')}';
}
```

**拖动优化：**
```dart
// 使用 onChangeEnd 而不是 onChanged，避免频繁 seek
Slider(
  value: _value,
  onChanged: (value) {
    setState(() => _value = value);  // 只更新本地状态
  },
  onChangeEnd: (value) {
    // 拖动结束才调用 seekTo
    final position = (value * controller.state.duration).toInt();
    controller.seekTo(position);
  },
)
```

### Project Structure Notes

**新增文件：**
```
polyv_media_player/example/lib/player_skin/progress_slider/
├── progress_slider.dart    # 进度条组件（本 Story）
└── time_label.dart         # 时间标签组件（本 Story）
```

**修改文件：**
```
polyv_media_player/example/lib/player_skin/
├── control_bar.dart        # 集成进度条
└── player_skin.dart        # 可能需要调整布局
```

### Testing Requirements

**Widget 测试：**
```dart
testWidgets('ProgressSlider displays correct progress', (tester) async {
  // 测试进度显示
  expect(find.text('01:30'), findsOneWidget);
});

testWidgets('ProgressSlider seek on drag', (tester) async {
  // 测试拖动功能
  await tester.drag(find.byType(Slider), Offset(100, 0));
  verify(() => controller.seekTo(any)).called(1);
});
```

**集成测试要点：**
- 进度条随播放实时更新
- 拖动后视频正确跳转
- 缓冲进度正确显示
- 时间格式化正确（短视频用 MM:SS，长视频用 HH:MM:SS）

### References

- [Epic 2: 播放进度与时间显示](../planning-artifacts/epics.md#epic-2-播放进度与时间显示) - Epic 级别目标
- [Story 2.1 详细需求](../planning-artifacts/epics.md#story-21-进度条组件) - 本 Story 详细定义
- [架构文档 - Widget 组件化策略](../planning-artifacts/architecture.md#widget-组件化策略) - 组件结构规范
- [项目上下文 - 颜色系统](../project-context.md#121-颜色系统) - 进度条颜色定义
- [项目上下文 - UI 原型参考](../project-context.md#10-ui-实现参考-critical) - 原型文件路径
- [UI 原型 - PlayerProgress](/Users/nick/projects/polyv/ios/polyv-vod/src/components/player/PlayerProgress.tsx) - 进度条原型

## Dev Agent Record

### Agent Model Used

claude-opus-4-5-20251101

### Debug Log References

N/A - 实现过程顺利，无需要调试的问题

### Completion Notes List

**Story 创建完成 - 2026-01-20**

**Story 实现完成 - 2026-01-20**

**实现内容：**
1. 创建 `ProgressSlider` 组件 - 支持播放进度、缓冲进度显示和拖动 seek
2. 创建 `TimeLabel` 组件 - 时间格式化显示（MM:SS / HH:MM:SS）
3. 创建 `ControlBar` 组件 - 集成进度条和播放控制按钮
4. 更新 `LongVideoPage` - 使用新的 ControlBar 组件
5. 编写 11 个 Widget 测试 - 全部通过

**技术实现：**
- 使用 `Slider` 组件配合 `SliderTheme` 实现自定义样式
- 使用 `onChangeEnd` 优化 seek 调用，避免频繁操作
- 拖动状态管理确保 UI 不会在拖动时闪烁
- 时间格式化支持短视频（MM:SS）和长视频（HH:MM:SS）

**进度条性能优化完成 - 2026-01-20**

**优化内容：**
1. 将 `home_page.dart` 中的 `_VideoProgressBar` 从 `StatelessWidget` 改为 `StatefulWidget`
2. 添加本地拖动状态管理 (`_dragValue`, `_isDragging`)
3. 添加 `RepaintBoundary` 隔离重绘区域，减少不必要的重绘
4. 分离拖动逻辑：`onChangeStart` → `onChanged` → `onChangeEnd`
5. 修复进度条颜色，与 `progress_slider.dart` 保持一致（使用 PlayerColors 定义）

**优化效果：**
- 拖动时使用本地值，避免与播放器进度更新冲突
- 拖动更加流畅，无卡顿感

### File List

**新增文件：**
- `docs/implementation-artifacts/2-1-progress-bar.md` - 本 Story 文档
- `polyv_media_player/example/lib/player_skin/progress_slider/progress_slider.dart` - 进度条组件
- `polyv_media_player/example/lib/player_skin/progress_slider/time_label.dart` - 时间标签组件
- `polyv_media_player/example/lib/player_skin/control_bar.dart` - 播放器控制栏
- `polyv_media_player/example/lib/player_skin/progress_slider/progress_slider_test.dart` - 进度条组件测试

**修改文件：**
- `polyv_media_player/example/lib/pages/home_page.dart` - 更新 LongVideoPage 使用 ControlBar
