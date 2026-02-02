# Story 1.3: 基础播放控制

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

作为最终用户，
我想要播放视频并可以暂停/继续，
以便观看视频内容。

## Acceptance Criteria

**Given** 已加载视频
**When** 点击播放按钮
**Then** 视频开始播放
**And** 播放按钮变为暂停图标
**When** 点击暂停按钮
**Then** 视频暂停播放
**And** 暂停按钮变为播放图标
**And** 播放状态通过 Provider 正确同步到 UI

## Tasks / Subtasks

- [x] 实现 loadVideo 方法 (AC: Given)
  - [x] Dart 层调用 invokeMethod('loadVideo', {vid, autoPlay})
  - [x] iOS 端实现 handleLoadVideo
  - [x] 通过 VID 请求视频（PLVVodMediaVideo.requestVideoPriorityCacheWithVid）
  - [x] 初始化 PLVVodMediaPlayer
  - [x] 设置 autoPlay 属性
  - [x] 设置 delegate（PLVMediaPlayerCoreDelegate, PLVVodMediaPlayerDelegate）
  - [x] 发送 stateChanged 事件（loading → prepared）
- [x] 实现播放方法 (AC: When, Then)
  - [x] Dart 层调用 invokeMethod('play')
  - [x] iOS 端实现 handlePlay
  - [x] 调用 [self.player play]
  - [x] 发送 stateChanged 事件（prepared → playing）
- [x] 实现暂停方法 (AC: When, Then)
  - [x] Dart 层调用 invokeMethod('pause')
  - [x] iOS 端实现 handlePause
  - [x] 调用 [self.player pause]
  - [x] 发送 stateChanged 事件（playing → paused）
- [x] 实现停止方法
  - [x] Dart 层调用 invokeMethod('stop')
  - [x] iOS 端实现 handleStop
  - [x] 清理播放器资源
  - [x] 发送 stateChanged 事件（→ idle）
- [x] 实现跳转方法 (AC: And)
  - [x] Dart 层调用 invokeMethod('seekTo', {position})
  -x] iOS 端实现 handleSeekTo
  - [x] 将毫秒转换为秒（position / 1000.0）
  - [x] 调用 [self.player seekToTime:]
- [x] 实现进度事件 (AC: And)
  - [x] iOS 端实现 sendProgressEvent
  - [x] 在 PLVVodMediaPlayerDelegate 播放进度回调中发送
  - [x] 事件数据：position, duration, bufferedPosition（毫秒）
- [x] 实现 Provider 状态同步 (AC: And)
  - [x] PlayerController 继承 ChangeNotifier
  - [x] _updateState 方法调用 notifyListeners()
  - [x] UI 使用 Consumer<PlayerController> 监听状态变化
- [x] 测试播放流程 (AC: Given, When, Then)
  - [x] 验证 loadVideo 加载视频
  - [x] 验证 play/pause 按钮控制播放
  - [x] 验证状态变化事件正确触发

## Dev Notes

### Story Context

**Epic 1: 项目初始化与基础播放**
- 这是第一个面向终端用户的 Story，实现视频播放的核心功能
- 后续 Stories 将在此基础之上添加更多控制功能

### Architecture Compliance

**状态管理：**
```dart
// 使用 Provider 模式
class PlayerController extends ChangeNotifier {
  PlayerState _state;

  void _updateState(PlayerState newState) {
    _state = newState;
    notifyListeners();
  }
}

// UI 中使用
Consumer<PlayerController>(
  builder: (context, controller, child) {
    return Text('${controller.state.loadingState}');
  },
)
```

**播放状态流转：**
```
idle → loading → prepared → playing ↔ paused → completed
                                ↓
                              error
```

### Technical Implementation Details

**iOS 端关键实现：**

1. **视频加载流程**
```objc
// 1. 验证 VID
// 2. 发送 loading 状态事件
// 3. 清理旧播放器
// 4. 请求视频（PLVVodMediaVideo.requestVideoPriorityCacheWithVid）
// 5. 初始化 PLVVodMediaPlayer
// 6. 设置视频
// 7. 返回成功
```

2. **播放控制**
```objc
// 播放
[self.player play];  // 触发 delegate 回调 → 发送 stateChanged 事件

// 暂停
[self.player pause];  // 触发 delegate 回调 → 发送 stateChanged 事件

// 跳转
[self.player seekToTime:time];  // time = position / 1000.0
```

3. **事件发送时机**
```objc
// PLVMediaPlayerCoreDelegate
- mediaPlayerCorePlaybackStateDidChange:toState: → 发送 stateChanged

// PLVVodMediaPlayerDelegate
- playedProgress: → 发送 progress 事件
- loadMainPlayerFailureWithError: → 发送 error 事件
```

### Testing Requirements

**Widget 测试：**
- 测试 loadVideo 加载视频功能
- 测试 play/pause 按钮控制播放
- 测试 seekTo 跳转功能
- 测试状态变化事件

**集成测试：**
```dart
testWidgets('Video playback flow', (tester) async {
  // 1. 加载视频
  await controller.loadVideo('e8888b0d3');
  expect(controller.state.loadingState, PlayerLoadingState.loading);

  // 2. 等待准备完成
  await tester.pumpAndSettle();
  expect(controller.state.loadingState, PlayerLoadingState.prepared);

  // 3. 播放
  await controller.play();
  expect(controller.state.loadingState, PlayerLoadingState.playing);

  // 4. 暂停
  await controller.pause();
  expect(controller.state.loadingState, PlayerLoadingState.paused);
});
```

### References

- [Epic 1: 项目初始化与基础播放](../planning-artifacts/epics.md#epic-1-项目初始化与基础播放) - Epic 级别目标和上下文
- [架构文档 - 状态管理模式](../planning-artifacts/architecture.md#2-platform-channel-api-设计) - Provider 模式
- [项目上下文 - Provider 使用规范](../project-context.md#3-provider-state-management-pattern) - 状态管理约定

## Dev Agent Record

### Agent Model Used

claude-opus-4-5-20251101

### Debug Log References

N/A - No debugging issues encountered

### Completion Notes List

✅ **实现完成**
- 视频加载功能完整（通过 VID 请求，支持自动播放）
- 播放/暂停/停止控制完整实现
- seek 跳转功能完整实现（支持毫秒级定位）
- 播放状态实时同步（idle, loading, prepared, playing, paused, buffering, completed, error）
- 进度事件实时更新（position, duration, bufferedPosition）
- 错误处理完整实现（PlatformException + 事件通知）
- Provider 状态管理正确实现（ChangeNotifier + Consumer）
- 完整的事件流：stateChanged, progress, error, qualityChanged, subtitleChanged, completed

**技术亮点：**
- 使用 PLVVodMediaVideo 请求视频（支持缓存优先）
- 自动播放支持（autoPlay 参数）
- 播放进度实时回调（playedProgress 回调）
- 状态同步机制高效（notifyListeners）
- 错误处理健壮（PlatformException + 事件通知）

### Change Log

- 2026-01-20: Epic 1 Story 1.3 完成
  - 基础播放控制功能全部实现
  - 事件流系统完整运行
  - Provider 状态管理正常工作
  - iOS 原生 SDK 集成成功

### File List

**修改文件:**
- `polyv_media_player/lib/core/player_controller.dart` - 播放器控制器实现
- `polyv_media_player/ios/Classes/PolyvMediaPlayerPlugin.m` - iOS 原生实现补充
