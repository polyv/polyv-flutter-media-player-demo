---
title: '弹幕开关位置状态保持优化'
slug: 'danmaku-toggle-position-persistence'
created: '2026-02-05 14:50:04'
updated: '2026-02-05 16:00:00'
status: 'done'
stepsCompleted: [1, 2, 3, 4, 5, 6, 7]
tech_stack: ['Flutter', 'Dart', 'flutter_test', 'Provider (ChangeNotifier)', 'iOS PolyvMediaPlayerSDK ~> 2.7.2']
files_to_modify: [
  'polyv_media_player/example/lib/player_skin/danmaku/danmaku_layer.dart',
  'polyv_media_player/example/lib/player_skin/danmaku/danmaku_layer_test.dart',
]
code_patterns: [
  'StatefulWidget with SingleTickerProviderStateMixin for animation',
  'AnimationController for danmaku scroll animation',
  'ChangeNotifier pattern for state management (DanmakuSettings)',
  'Widget tests using pump() and pump(Duration) for animation frames',
  'Test files co-located with source files',
]
test_patterns: [
  'Widget tests using flutter_test',
  'testWidgets() for UI testing',
  'pump() and pump(Duration) to trigger animation frames',
  'expect(find.byType(), findsOneWidget/Nothing) for assertions',
  'Group tests with group() and test()/testWidgets()',
]
---

# Tech-Spec: 弹幕开关位置状态保持优化

**Created:** 2026-02-05 14:50:04
**Updated:** 2026-02-05 15:30:00

## Overview

### Problem Statement

弹幕做开关操作之后，弹幕的位置会变成随机位置（实际上是所有弹幕都重叠在同一条轨道上）。

**根本原因分析**：

当前 `DanmakuLayer` 在弹幕关闭时（`enabled = false`）会：
1. 清空 `_activeDanmakus` 活跃弹幕列表
2. 但保留 `_trackEndTime` 轨道占用时间表

当弹幕重新开启时：
1. `_trackEndTime` 中的时间戳已过期且全部相等
2. `indexOf(minEndTime)` 返回第一个匹配索引（轨道 0）
3. 所有新弹幕都被分配到轨道 0，导致重叠

### Solution

对齐原生 iOS SDK (`PLVVodDanmuManager`) 的行为：
- **弹幕关闭时**：只隐藏弹幕（不渲染），暂停动画，但保留 `_activeDanmakus` 和 `_trackEndTime` 状态
- **弹幕开启时**：恢复显示和动画，弹幕继续在原有轨道和位置上显示
- **Seek 操作时**：继续清理状态（保持现有逻辑）
- **关闭期间时间前进后开启**：清空过期弹幕，显示当前时间窗口内的新弹幕

### Scope

**In Scope:**
- 修改 `DanmakuLayer._updateActiveDanmakus()` 方法，改变 `enabled = false` 时的行为
- 在 `_DanmakuItemState` 中添加动画暂停/恢复方法
- 使用 GlobalKey 实现父 Widget 对子 Widget 动画的控制
- 添加/更新测试用例验证弹幕开关行为
- 添加快速切换防抖保护机制

**Out of Scope:**
- 修改弹幕动画效果
- 修改弹幕数据模型
- 修改弹幕开关 UI 组件 (`DanmakuToggle`)

## Context for Development

### Codebase Patterns

**原生 SDK 行为参考** (`PLVVodDanmuManager.m`):

```objc
// 弹幕开关处理
- (void)pause {
    for (PLVVodDanmuViewModel *viewModel in self.currentViewModels) {
        [viewModel pause];  // 只暂停动画
    }
    self.state = PLVVodDanmuStatePause;
    // ⚠️ 不清理 currentViewModels 和轨道状态
}

- (void)resume {
    for (PLVVodDanmuViewModel *viewModel in self.currentViewModels) {
        [viewModel resume];  // 恢复动画
    }
    self.state = PLVVodDanmuStateRunning;
    // ⚠️ 继续使用原有轨道
}

// 清理轨道只在 seek 时调用
- (void)cleanTracks {
    [self stop];
    for (PLVVodDanmuTrack *track in self.tracks) {
        track.occupied = NO;
        track.danmus = nil;
    }
}
```

### Files to Reference

| File | Purpose |
| ---- | ------- |
| `polyv_media_player/example/lib/player_skin/danmaku/danmaku_layer.dart` | 弹幕显示层，需要修改的核心文件 |
| `polyv_media_player/example/lib/player_skin/danmaku/danmaku_model.dart` | 弹幕数据模型，包含 `Danmaku`、`ActiveDanmaku` 类 |
| `polyv_media_player/example/lib/player_skin/danmaku/danmaku_settings.dart` | 弹幕设置状态管理，`ChangeNotifier` 模式 |
| `polyv_media_player/example/lib/player_skin/danmaku/danmaku_layer_test.dart` | 现有测试文件 |
| `docs/implementation-artifacts/4-2-danmaku-toggle.md` | 弹幕开关功能的技术规范 |
| `docs/project-context.md` | 项目关键规则和模式 |

### Technical Decisions

1. **状态保留策略**：弹幕开关时保留所有内部状态（`_activeDanmakus`、`_trackEndTime`），只控制 UI 渲染和动画暂停/恢复
2. **动画处理**：关闭弹幕时调用 `AnimationController.stop()`（保存当前 value），开启时调用 `forward()` 从当前位置继续
3. **通信机制**：使用 `GlobalKey<_DanmakuItemState>` 让父 Widget 能够调用子 Widget 的动画控制方法
4. **兼容性**：保持 Seek 操作时的状态清理逻辑不变（`isSeekingBackwards` 或 `isSeekingForwards` 时清空状态）
5. **过期弹幕处理**：关闭期间时间前进后，移除已过期的弹幕，显示当前时间窗口内的新弹幕

### Codebase Patterns

**Dart 命名约定：**
- Class: `PascalCase` (如 `DanmakuLayer`, `ActiveDanmaku`)
- Method: `camelCase` (如 `_updateActiveDanmakus`, `didUpdateWidget`)
- Private 成员: 前缀下划线 (如 `_activeDanmakus`, `_trackEndTime`)
- File: `snake_case` (如 `danmaku_layer.dart`)

**Widget 模式：**
- 使用 `StatefulWidget` + `SingleTickerProviderStateMixin` 处理动画
- `didUpdateWidget()` 中检测参数变化
- `build()` 方法中使用 `LayoutBuilder` 获取动态尺寸
- 使用 `GlobalKey` 访问子 Widget 的 State

**测试模式：**
- 使用 `testWidgets()` 进行 Widget 测试
- 使用 `pump()` 和 `pump(Duration)` 触发动画帧
- 使用 `find.byType()`, `find.text()` 查找 Widget
- 测试文件与源文件同目录，命名为 `*_test.dart`
- **私有成员测试**：通过观察外部行为（如弹幕位置）间接验证私有状态

## Implementation Plan

### Tasks

- [x] **Task 1: 在 _DanmakuItemState 中添加动画暂停/恢复方法**
  - File: `polyv_media_player/example/lib/player_skin/danmaku/danmaku_layer.dart`
  - Action:
    1. 在 `_DanmakuItemState` 类中添加公共方法：
       ```dart
       /// 暂停动画（弹幕关闭时调用）
       void pauseAnimation() {
         _controller?.stop();
         // value 被保留，恢复时可从当前位置继续
       }

       /// 恢复动画（弹幕开启时调用）
       void resumeAnimation() {
         if (_controller != null && !_controller!.isAnimating) {
           _controller?.forward();
           // 从当前 value 继续动画
         }
       }
       ```
  - Notes: 这是底层修改，Task 2 将通过 GlobalKey 调用这些方法

- [x] **Task 2: 在 _DanmakuLayerState 中添加动画控制机制**
  - File: `polyv_media_player/example/lib/player_skin/danmaku/danmaku_layer.dart`
  - Action:
    1. 添加 GlobalKey 列表来跟踪子 Widget：
       ```dart
       final List<GlobalKey<_DanmakuItemState>> _danmakuKeys = [];
       ```
    2. 添加动画控制方法：
       ```dart
       void _pauseAllDanmakus() {
         for (final key in _danmakuKeys) {
           key.currentState?.pauseAnimation();
         }
       }

       void _resumeAllDanmakus() {
         for (final key in _danmakuKeys) {
           key.currentState?.resumeAnimation();
         }
       }
       ```
    3. 创建 `_DanmakuItem` 时传入 GlobalKey
  - Notes: GlobalKey 是 Flutter 中父 Widget 调用子 State 方法的标准模式

- [x] **Task 3: 修改 _updateActiveDanmakus() 改变开关行为**
  - File: `polyv_media_player/example/lib/player_skin/danmaku/danmaku_layer.dart`
  - Action:
    1. 移除 `enabled = false` 时清空 `_activeDanmakus` 的逻辑
    2. 改为：当 `enabled == false` 时调用 `_pauseAllDanmakus()`
    3. 当 `enabled == true` 时调用 `_resumeAllDanmakus()`
  - Notes:
    - 保持 Seek 操作时的状态清理逻辑不变
    - 确保 `build()` 方法中 `enabled == false` 时返回 `SizedBox.shrink()`

- [x] **Task 4: 处理弹幕关闭期间时间前进的场景**
  - File: `polyv_media_player/example/lib/player_skin/danmaku/danmaku_layer.dart`
  - Action:
    1. 添加 `_removeExpiredDanmakus()` 方法，移除动画完成或超出时间窗口的弹幕
    2. 在 `didUpdateWidget()` 中，当 `enabled` 从 `false` 变为 `true` 时：
       - 先调用 `_removeExpiredDanmakus()` 清理过期弹幕
       - 再调用 `_updateActiveDanmakus()` 添加当前时间窗口内的新弹幕
  - Notes: 这确保关闭期间时间前进后显示的是新弹幕

- [x] **Task 5: 添加快速切换防抖保护**
  - File: `polyv_media_player/example/lib/player_skin/danmaku/danmaku_layer.dart`
  - Action:
    1. 添加状态标志防止快速切换时的竞态：
       ```dart
       bool _isEnabledChanging = false;

       void _setEnabled(bool value) {
         if (_isEnabledChanging) return;
         _isEnabledChanging = true;
         // 执行状态变更...
         Future.delayed(const Duration(milliseconds: 50), () {
           _isEnabledChanging = false;
         });
       }
       ```
  - Notes: 简单的防抖，避免快速连续切换导致动画状态混乱

- [x] **Task 6: 添加弹幕开关行为测试**
  - File: `polyv_media_player/example/lib/player_skin/danmaku/danmaku_layer_test.dart`
  - Action: 添加以下测试用例：
    1. `testWidgets('弹幕关闭后再开启，弹幕位置保持不变')`
       - 验证：关闭前记录弹幕 top 值，开启后弹幕 top 值相同
    2. `testWidgets('弹幕关闭时动画停止')`
       - 验证：关闭后弹幕 left 位置不再变化
    3. `testWidgets('弹幕关闭期间时间前进后开启显示新弹幕')`
       - 验证：时间前进后开启显示的是新弹幕（不同 text 内容）
  - Notes: 通过外部行为间接验证内部状态

- [x] **Task 7: 添加边界情况测试**
  - File: `polyv_media_player/example/lib/player_skin/danmaku/danmaku_layer_test.dart`
  - Action: 添加以下测试用例：
    1. `testWidgets('弹幕关闭期间发生 seek，开启后显示新位置的弹幕')`
    2. `testWidgets('多次快速切换弹幕开关')`
    3. `testWidgets('弹幕关闭状态下不存在弹幕 Widget')`

### Acceptance Criteria

- [x] **AC 1: 弹幕开关后位置保持**
  - **Given** 视频正在播放，屏幕上有多条弹幕在不同轨道上滚动
  - **When** 用户点击弹幕开关关闭弹幕，等待 1 秒后再次点击开关开启弹幕
  - **Then** 弹幕应该在原有轨道上继续显示，位置与关闭前保持一致（通过 top 值验证）

- [x] **AC 2: Seek 操作后状态正确**
  - **Given** 视频正在播放，弹幕已开启，屏幕上有弹幕在滚动
  - **When** 用户执行 seek 操作（快进或回退）
  - **Then** 弹幕状态应该被清空，重新根据当前时间分配弹幕到不同轨道

- [x] **AC 3: 关闭期间时间前进后开启显示新弹幕**
  - **Given** 弹幕开关处于关闭状态，播放器正在播放
  - **When** 播放时间前进 5 秒，然后开启弹幕
  - **Then** 关闭前显示的弹幕已不在屏幕上，显示的是当前时间窗口内的新弹幕，且正确分配到不同轨道

- [x] **AC 4: 多次快速切换开关**
  - **Given** 视频正在播放
  - **When** 用户快速连续点击弹幕开关 5 次
  - **Then** 最终弹幕状态应该与最后一次开关状态一致，无内存泄漏或动画异常

- [x] **AC 5: 弹幕关闭时不渲染**
  - **Given** 屏幕上有弹幕在滚动
  - **When** 用户关闭弹幕
  - **Then** 弹幕应该立即从屏幕上消失（`SizedBox.shrink()`），不拦截手势事件

- [x] **AC 6: 现有测试不中断**
  - **Given** 现有的 `danmaku_layer_test.dart` 测试套件
  - **When** 执行修改后的代码
  - **Then** 所有现有测试用例应该继续通过

## Additional Context

### Dependencies

- 无新增依赖
- 依赖现有代码：`DanmakuSettings` (ChangeNotifier)、`ActiveDanmaku` 模型

### Testing Strategy

1. **Widget 测试** (`danmaku_layer_test.dart`):
   - 使用 `testWidgets()` 测试弹幕开关行为
   - 使用 `pump()` 和 `pump(Duration)` 触发动画帧
   - 验证 `enabled` 状态切换前后弹幕的显示/隐藏状态
   - **私有成员测试**：通过验证弹幕的 `top`/`left` 位置来间接验证 `_activeDanmakus` 状态保留

2. **手工验证步骤**:
   - 播放视频，观察多条弹幕在不同轨道上滚动
   - 关闭弹幕，等待 1-2 秒后重新开启
   - 验证弹幕是否在原有轨道和位置上继续显示
   - 执行 seek 操作，验证弹幕状态正确重置

### Risk Mitigation

| 风险 | 缓解措施 |
| ---- | -------- |
| 动画暂停/恢复导致状态不一致 | Task 1 保存 AnimationController.value，Task 2 使用 GlobalKey 调用恢复方法 |
| 内存泄漏（活跃弹幕未清理） | 确保动画完成的弹幕仍被正确移除（现有逻辑保持不变） |
| 横竖屏切换时的状态处理 | 现有的 `isInitialUpdate` 逻辑应继续工作 |
| 多次快速切换开关导致异常 | Task 5 添加防抖机制（`_isEnabledChanging` 标志） |
| 关闭期间时间前进导致过期弹幕 | Task 4 添加 `_removeExpiredDanmakus()` 方法 |
| GlobalKey 使用不当导致性能问题 | 只在需要时创建，及时清理 |

### Notes

**代码位置说明**：
- 以下行号基于创建此规范时的代码，实施前请搜索方法名确认位置
- `_updateActiveDanmakus()` 方法 - 弹幕更新逻辑（需修改）
- `_DanmakuItemState` 类 - 弹幕项 State（需添加 pause/resume 方法）
- `didUpdateWidget()` 方法 - Widget 更新检测（需添加 enabled 变化处理）
- `build()` 方法中 `enabled == false` 分支 - 弹幕关闭时不渲染（保持不变）

**实现后的行为**：
| 操作 | 当前行为 | 修改后行为 |
| ---- | -------- | ---------- |
| 关闭弹幕 | 清空 `_activeDanmakus`，清空屏幕 | 保留 `_activeDanmakus`，隐藏屏幕，停止动画（保存 value） |
| 短暂开启 | 重新分配弹幕（可能重叠） | 恢复显示和动画，从保存的 value 继续滚动 |
| 关闭期间时间前进后开启 | 重新分配弹幕 | 移除过期弹幕，显示新弹幕 |
| Seek 操作 | 清空状态，重新分配 | 清空状态，重新分配（不变） |

**原生 SDK 参考路径**（开发者本地路径，仅供参考）：
- iOS Demo: `PLViOSMediaPlayerDemo/PolyvVodScenes/Secenes/VodScene/MediaArea/PLVVodMediaAreaVC.m`
- iOS SDK: `Pods/PLVVodDanmu/PLVVodDanmu/PLVVodDanmuManager.m`
- 参考方法: `pause()`, `resume()`, `cleanTracks()`
