# Story 2.2: 时间显示组件

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

作为最终用户，
我想要查看当前播放时间和总时长，
以便了解视频进度。

## Acceptance Criteria

**Given** 视频已加载
**When** 视频播放中
**Then** 显示当前时间（格式：分:秒）
**And** 显示总时长（格式：分:秒）
**And** 时间格式为 "MM:SS" 或 "HH:MM:SS"

## Tasks / Subtasks

- [x] 实现时间格式化工具函数 (AC: Then, And)
  - [x] 创建 `formatTime()` 方法支持毫秒转换
  - [x] 短视频（< 1小时）显示为 "MM:SS"
  - [x] 长视频（>= 1小时）显示为 "HH:MM:SS"
  - [x] 确保分钟和秒数补零（如 01:05，不显示 1:5）
- [x] 创建时间显示组件位置 (AC: Given, When, Then)
  - [x] 确认 TimeLabel 组件已在 Story 2.1 创建
  - [x] 验证 `example/lib/player_skin/progress_slider/time_label.dart` 存在
  - [x] 确认组件支持传入 position 和 duration 参数
- [x] 集成时间显示到进度条组件 (AC: Given, Then)
  - [x] 在 ProgressSlider 中使用两个 TimeLabel
  - [x] 左侧显示当前播放时间（传入 state.position）
  - [x] 右侧显示总时长（传入 state.duration）
  - [x] 布局使用 Row 包裹，中间是 Slider，两侧是 TimeLabel
- [x] 样式符合设计规范 (AC: Then, And)
  - [x] 字体大小使用 TextStyles.caption (11px)
  - [x] 字体颜色使用 PlayerColors.textMuted (0xFF8B919E)
  - [x] 确保时间文字与进度条垂直居中对齐
  - [x] 时间与进度条之间有适当间距（12px）
- [x] 测试时间显示功能 (AC: Given, When, Then)
  - [x] 测试短视频时间格式（如 05:30）
  - [x] 测试长视频时间格式（如 1:25:30）
  - [x] 测试时间随播放实时更新
  - [x] 测试边界情况（0:00、未加载时显示 "--:--"）

## Dev Notes

### Story Context

**Epic 2: 播放进度与时间显示**
- 这是 Epic 2 的第二个 Story，专注于时间显示的格式化和展示
- Epic 2 包含 3 个 Stories：进度条(2.1)、时间显示(2.2)、缓冲进度(2.3)
- Story 2.1 已经创建了 TimeLabel 组件，本 Story 需要验证和完善时间显示功能

**前置依赖：**
- Epic 1 Story 1.3 已完成 - PlayerController 已支持进度事件
- Story 2.1 已完成 - 进度条组件已实现，TimeLabel 组件已创建
- PlayerState 已包含 position, duration 字段（毫秒单位）

### Architecture Compliance

**组件位置（已在 Story 2.1 创建）：**
```
example/lib/player_skin/progress_slider/
└── time_label.dart         # 时间显示组件（Story 2.1 创建，本 Story 验证和完善）
```

**状态管理模式：**
```dart
// 使用 Consumer<PlayerController> 获取状态
Consumer<PlayerController>(
  builder: (context, controller, child) {
    final state = controller.state;
    return Row(
      children: [
        TimeLabel(time: state.position),    // 当前时间
        Expanded(child: ProgressSlider(...)),
        TimeLabel(time: state.duration),    // 总时长
      ],
    );
  },
)
```

**命名约定：**
- 方法：camelCase → `formatTime`, `formatDuration`
- 变量：camelCase → `currentTime`, `totalDuration`

### Previous Story Intelligence

**从 Story 2.1 学到的经验：**

1. **TimeLabel 组件已创建**
   - 文件位置：`example/lib/player_skin/progress_slider/time_label.dart`
   - 已实现 `formatTime()` 静态方法
   - 支持毫秒到时间格式的转换

2. **时间格式化逻辑已实现**
   ```dart
   // TimeLabel 中已有的格式化方法
   static String formatTime(int milliseconds) {
     final seconds = milliseconds ~/ 1000;
     final mins = seconds ~/ 60;
     final secs = seconds % 60;

     if (mins >= 60) {
       final hours = mins ~/ 60;
       final remainingMins = mins % 60;
       return '${hours}:${remainingMins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
     }
     return '${mins}:${secs.toString().padLeft(2, '0')}';
   }
   ```

3. **进度条布局已建立**
   - ProgressSlider 已集成到 ControlBar
   - 布局结构：`Row([TimeLabel(position), Expanded(Slider), TimeLabel(duration)])`

4. **样式规范已应用**
   - 使用 TextStyles.caption (11px)
   - 使用 DarkTheme.mutedForeground (0xFF7C8591)
   - 布局间距使用 Spacing.sm (8.0)

5. **Widget 测试模式**
   - Story 2.1 创建了完整的 Widget 测试
   - 测试覆盖了时间格式化的各种情况

**本 Story 重点：**
- 验证 TimeLabel 组件功能完整性
- 确保时间正确显示在进度条两侧
- 测试边界情况（未加载、0秒、长视频格式）

### UI 原型参考

**原型文件：** `/Users/nick/projects/polyv/ios/polyv-vod/src/components/player/PlayerProgress.tsx`

**时间显示相关代码：**
```tsx
// 从原型中提取的格式化逻辑
const formatTime = (seconds: number) => {
  const mins = Math.floor(seconds / 60);
  const secs = Math.floor(seconds % 60);
  return `${mins}:${secs.toString().padStart(2, "0")}`;
};
```

**注意：** 原型只支持 MM:SS 格式（秒级输入），Flutter 实现需要支持：
1. 毫秒输入（来自 Native SDK）
2. HH:MM:SS 格式（长视频支持）

### Technical Requirements

**时间格式化完整实现：**
```dart
class TimeLabel extends StatelessWidget {
  final int time;  // 毫秒

  const TimeLabel({
    super.key,
    required this.time,
  });

  // 格式化时间：毫秒 -> MM:SS 或 HH:MM:SS
  static String formatTime(int milliseconds) {
    if (milliseconds <= 0) return '00:00';

    final seconds = milliseconds ~/ 1000;
    final mins = seconds ~/ 60;
    final secs = seconds % 60;

    // 小于1小时：显示 MM:SS
    if (mins < 60) {
      return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }

    // 大于等于1小时：显示 HH:MM:SS
    final hours = mins ~/ 60;
    final remainingMins = mins % 60;
    return '${hours}:${remainingMins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      formatTime(time),
      style: TextStyles.caption.copyWith(
        color: DarkTheme.mutedForeground,
      ),
    );
  }
}
```

**布局集成（在 ProgressSlider 或 ControlBar 中）：**
```dart
Row(
  children: [
    // 当前时间
    TimeLabel(time: state.position),
    SizedBox(width: Spacing.sm),
    // 进度条
    Expanded(child: Slider(...)),
    SizedBox(width: Spacing.sm),
    // 总时长
    TimeLabel(time: state.duration),
  ],
)
```

### Project Structure Notes

**已有文件（Story 2.1 创建）：**
```
polyv_media_player/example/lib/player_skin/progress_slider/
├── progress_slider.dart    # 进度条组件
└── time_label.dart         # 时间标签组件
```

**本 Story 验证点：**
- `time_label.dart` 功能完整性
- `progress_slider.dart` 中的时间显示集成
- 样式符合设计规范

**可能需要修改的文件：**
```
polyv_media_player/example/lib/player_skin/
├── progress_slider/progress_slider.dart  # 确认时间显示布局
└── control_bar.dart                     # 确认 ControlBar 使用 ProgressSlider
```

### Testing Requirements

**Widget 测试：**
```dart
// 验证时间格式化
testWidgets('TimeLabel formats short duration correctly', (tester) async {
  await tester.pumpWidget(TimeLabel(time: 90000));  // 1分30秒
  expect(find.text('01:30'), findsOneWidget);
});

testWidgets('TimeLabel formats long duration correctly', (tester) async {
  await tester.pumpWidget(TimeLabel(time: 3661000));  // 1小时1分1秒
  expect(find.text('1:01:01'), findsOneWidget);
});

testWidgets('TimeLabel handles zero duration', (tester) async {
  await tester.pumpWidget(TimeLabel(time: 0));
  expect(find.text('00:00'), findsOneWidget);
});

testWidgets('TimeLabel handles negative duration', (tester) async {
  await tester.pumpWidget(TimeLabel(time: -1));
  expect(find.text('00:00'), findsOneWidget);
});
```

**集成测试要点：**
- 播放视频时当前时间实时更新
- 总时长在视频加载后正确显示
- 时间格式与进度条位置对齐
- 长视频（>1小时）使用 HH:MM:SS 格式

### Git Intelligence Summary

**最近提交（2025-01-19 至 2025-01-20）：**
- `104d7ec` - Fix: Correct progress bar colors and document performance optimization
- `8b6e627` - Feat: Enhance video player UI with auto-hide controls and replay screen
- `946a925` - Fix: iOS build errors and implement video player UI improvements

**相关代码模式：**
1. 使用 `RepaintBoundary` 隔离重绘区域（性能优化）
2. 使用 `StatefulWidget` + 本地状态管理拖动逻辑
3. 使用 `PlayerColors` 和 `DarkTheme` 统一样式

**本 Story 注意事项：**
- TimeLabel 是轻量组件，使用 `StatelessWidget` 即可
- 确保时间更新不会触发整个播放器重绘（Consumer 应精确到必要范围）

### Latest Tech Information

**Flutter 时间格式化最佳实践：**
- 使用整数运算（`~/ 1000`）而非 double 转换
- 使用 `padLeft(2, '0')` 确保补零
- 避免使用 `intl` 包的 DateFormat（性能开销）

**Dart 语言特性：**
```dart
// 推荐：整数运算
final seconds = milliseconds ~/ 1000;

// 避免：double 转换
final seconds = (milliseconds / 1000).toInt();
```

### Project Context Reference

**相关规范：**
- [命名约定 - project-context.md#1-dart-naming-conventions-strict](../project-context.md)
- [状态管理 - project-context.md#3-provider-state-management-pattern](../project-context.md)
- [颜色系统 - project-context.md#121-颜色系统](../project-context.md#121-颜色系统)
- [字体排版 - project-context.md#122-字体排版](../project-context.md#122-字体排版)
- [UI 原型参考 - project-context.md#10-ui-实现参考-critical](../project-context.md#10-ui-实现参考-critical)

**架构相关：**
- [Widget 组件化策略 - architecture.md#widget-组件化策略](../planning-artifacts/architecture.md#widget-组件化策略)
- [数据格式 - architecture.md#format-patterns](../planning-artifacts/architecture.md#format-patterns)

### References

- [Epic 2: 播放进度与时间显示](../planning-artifacts/epics.md#epic-2-播放进度与时间显示) - Epic 级别目标
- [Story 2.2 详细需求](../planning-artifacts/epics.md#story-22-时间显示组件) - 本 Story 详细定义
- [Story 2.1 实现文档](2-1-progress-bar.md) - 前置 Story，包含 TimeLabel 创建详情
- [架构文档 - Widget 组件化策略](../planning-artifacts/architecture.md#widget-组件化策略) - 组件结构规范
- [项目上下文 - 字体排版](../project-context.md#122-字体排版) - 时间显示字体定义
- [项目上下文 - UI 原型参考](../project-context.md#10-ui-实现参考-critical) - 原型文件路径
- [UI 原型 - PlayerProgress](/Users/nick/projects/polyv/ios/polyv-vod/src/components/player/PlayerProgress.tsx) - 进度条原型

## Dev Agent Record

### Agent Model Used

claude-opus-4-5-20251101

### Debug Log References

N/A - Story 创建阶段

### Completion Notes List

**Story 创建完成 - 2025-01-20**

**创建摘要：**
- 确认 Story 2.1 已创建 TimeLabel 组件
- 本 Story 重点是验证和完善时间显示功能
- 提供完整的时间格式化参考实现
- 明确边界情况处理（0秒、负数、长视频）

**开发重点：**
1. 验证 `time_label.dart` 的 `formatTime()` 方法支持 HH:MM:SS 格式
2. 确认 ProgressSlider 或 ControlBar 正确集成两个 TimeLabel
3. 测试时间显示与进度条的布局对齐
4. 确保 Widget 测试覆盖各种时间格式

**Story 实现完成 - 2026-01-20**

**实现摘要：**
- 修复 TimeLabel 组件分钟补零问题（M:SS → MM:SS）
  - 修改前：`'$mins:${secs.toString().padLeft(2, '0')}'`
  - 修改后：`'${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}'`
- 验证 TimeLabel 组件完整功能：
  - 毫秒转 MM:SS 格式（短视频）
  - 毫秒转 HH:MM:SS 格式（长视频）
  - 零值/负值边界处理
  - showUnknown 参数支持显示 "--:--"
- 验证 ProgressSlider 正确集成时间显示：
  - 左侧显示当前播放时间
  - 右侧显示总时长（支持未知状态）
  - 布局使用 Row 包裹，间距 12px
- 样式符合设计规范：
  - 字体大小 11px
  - 字体颜色 0xFF8B919E
- 更新所有 Widget 测试以匹配新的 MM:SS 格式
- 所有 106 个测试通过

**修改的文件：**
1. `polyv_media_player/example/lib/player_skin/progress_slider/time_label.dart` - 修复分钟补零
2. `polyv_media_player/example/lib/player_skin/progress_slider/progress_slider_test.dart` - 更新测试断言

**验证结果：**
- ✅ 所有接受标准满足
- ✅ 所有任务/子任务完成
- ✅ 所有测试通过（106/106）
- ✅ 无回归问题

### File List

**新增文件：**
- `docs/implementation-artifacts/2-2-time-display.md` - 本 Story 文档

**修改文件：**
- `polyv_media_player/example/lib/player_skin/progress_slider/time_label.dart` - 修复分钟补零问题
- `polyv_media_player/example/lib/player_skin/progress_slider/progress_slider_test.dart` - 更新测试断言
- `polyv_media_player/example/test/pages/home_page_test.dart` - 修复导航测试断言（自动化修复）
- `docs/automation-summary.md` - 更新测试统计信息（自动化）
- `docs/implementation-artifacts/sprint-status.yaml` - 更新 Story 状态为 review

**参考文件（未修改）：**
- `polyv_media_player/example/lib/player_skin/progress_slider/progress_slider.dart` - 确认时间显示集成
- `docs/implementation-artifacts/2-1-progress-bar.md` - 前置 Story 文档

## Change Log

**2026-01-20 - Story 2.2 实现完成**
- 修复 TimeLabel 分钟补零格式（M:SS → MM:SS）
- 更新所有相关 Widget 测试
- 验证时间显示功能完整性
