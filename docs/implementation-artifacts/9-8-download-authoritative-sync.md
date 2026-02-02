# Story 9.8: 下载任务权威同步（getDownloadList + EventChannel）

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

作为最终用户，
我想要下载中心展示的任务列表/进度/完成/失败状态与原生下载 SDK 保持一致，
并在页面进入、下载状态变化、应用前后台/重启后仍可正确恢复，
以确保下载中心是可靠的管理入口。

## Acceptance Criteria

1. **Given** 用户进入下载中心页面
**When** 页面初始化
**Then** Flutter 调用 `getDownloadList` 拉取原生 SDK 的权威任务列表
**And** 列表与 Tab 徽章数量基于该列表渲染

2. **Given** 原生侧任务状态发生变化（进度/完成/失败/删除/暂停/继续）
**When** 事件发生
**Then** 原生通过 EventChannel 推送事件到 Flutter
**And** Flutter 更新任务镜像状态并驱动 UI 刷新

3. **Given** 同步/事件接收失败
**When** Flutter 侧发生异常
**Then** UI 使用 SnackBar 提示错误
**And** Flutter 不生成与原生不一致的“猜测状态”

4. **Given** Flutter 侧发生临时不一致（例如热重载/重进页面）
**When** 再次调用 `getDownloadList`
**Then** 下载中心状态可被权威列表纠正

## Tasks / Subtasks

- [x] Platform Channel：新增/实现 `getDownloadList` 方法
  - [x] 返回原生 SDK 的任务列表（至少区分 downloading/completed 或携带 status 字段）
  - [x] 字段需可映射到 `DownloadTask`（id/vid/title/thumbnail/totalBytes/downloadedBytes/bytesPerSecond/status/errorMessage/createdAt/completedAt）

- [x] EventChannel：新增/完善下载事件流
  - [x] `taskProgress`（id, downloadedBytes, totalBytes, bytesPerSecond, status）
  - [x] `taskCompleted`（id, completedAt）
  - [x] `taskFailed`（id, errorMessage）
  - [x] `taskRemoved`（id）
  - [x] （建议）`taskPaused` / `taskResumed`

- [x] Dart：下载中心页面初始化时触发同步
  - [x] `DownloadCenterPage` initState 调用 `syncFromNative()`
  - [x] 同步失败时 SnackBar 提示

- [x] Dart：`DownloadStateManager` 支持从权威列表替换/合并任务
  - [x] `replaceAll()` 或等效方法作为权威覆盖
  - [x] 事件流仅更新对应任务字段并 `notifyListeners()`

- [x] iOS：实现 `getDownloadList` + 事件推送
  - [x] 从 iOS 下载 SDK 获取当前任务列表
  - [x] 监听 SDK 下载回调并通过 EventChannel 推送

- [x] Android：实现 `getDownloadList` + 事件推送
  - [x] 从 Android 下载 SDK 获取当前任务列表
  - [x] 监听 SDK 下载回调并通过 EventChannel 推送

- [x] 测试：覆盖权威同步
  - [x] 初始化拉取后渲染正确
  - [x] progress/completed/failed/removed 事件驱动 UI 更新

## Dev Notes

### 事件数据规范建议

- Event payload 建议采用：`{ "type": "taskProgress", "data": { ... } }`
- Flutter 侧统一入口解析 type，再映射到 `DownloadStateManager.updateTaskProgress()` 等

### 业务逻辑归属原则

- Flutter 层：状态镜像与 UI（消费权威数据）
- 原生层：提供权威列表与事件流（SDK 状态源）

### References

- [Source: docs/planning-artifacts/epics.md#Story 9.8] - Story 9.8 验收标准
- [Source: docs/implementation-artifacts/9-1-download-center.md] - 下载中心架构与同步策略（需落地 getDownloadList + EventChannel）

## Dev Agent Record

### Agent Model Used

Cascade

### Debug Log References

None

### Completion Notes List

- 实现了 `getDownloadList` Platform Channel 方法，支持从原生 SDK 获取权威任务列表
- 在 `DownloadStateManager` 中添加了 `syncFromNative()` 方法和 `handleDownloadEvent()` 事件处理方法
- 下载中心页面 `initState` 时自动调用 `syncFromNative()` 同步权威列表
- 同步失败时通过 SnackBar 提示用户错误信息
- iOS 原生层实现了 `handleGetDownloadList` 方法，从 `PLVDownloadMediaManager` 获取任务列表
- Android 原生层实现了 `handleGetDownloadList` 方法，从 `PLVMediaDownloaderManager` 获取任务列表
- 事件处理支持：taskProgress、taskCompleted、taskFailed、taskRemoved、taskPaused、taskResumed
- 添加了 10 个单元测试覆盖权威同步和事件处理功能

### File List

- polyv_media_player/lib/platform_channel/player_api.dart (modified)
- polyv_media_player/lib/platform_channel/method_channel_handler.dart (modified)
- polyv_media_player/lib/infrastructure/download/download_state_manager.dart (modified)
- polyv_media_player/lib/infrastructure/download/download_state_manager_sync_test.dart (new)
- polyv_media_player/example/lib/pages/download_center/download_center_page.dart (modified)
- polyv_media_player/example/lib/pages/download_center/download_center_page_test.dart (modified)
- polyv_media_player/ios/Classes/PolyvMediaPlayerPlugin.m (modified)
- polyv_media_player/android/src/main/kotlin/com/polyv/polyv_media_player/PolyvMediaPlayerPlugin.kt (modified)

## Change Log

- 2026-01-28: Story 9.8 实现完成 - 下载任务权威同步（getDownloadList + EventChannel）
