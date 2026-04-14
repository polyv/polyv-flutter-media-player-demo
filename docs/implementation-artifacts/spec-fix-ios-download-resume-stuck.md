---
title: 'Fix: iOS 下载恢复后进度条卡住'
type: 'bugfix'
created: '2026-04-14'
status: 'done'
baseline_commit: 'e16ed4b'
context:
  - 'docs/project-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** iOS 下载过程中退出 App 后重新打开，在下载中心点击继续下载，进度条卡住不动。Android 相同流程正常。

**Approach:** 修复 iOS 原生层两个问题：(1) `sendDownloadResumedEvent` 发送 `taskProgress` 而非 `taskResumed`，与 Android 不一致；(2) `handleResumeDownload` 调用 `startDownloadTask:` 后不验证下载是否真正恢复——当 App 被杀死时，SDK 可能无法用缓存的 `PLVDownloadInfo` 恢复下载。需要添加状态验证和回退机制。

## Boundaries & Constraints

**Always:**
- 保持与 Android 行为一致（事件类型、状态流转）
- 强一致性原则：原生调用成功才更新 Dart 状态
- 不改变 Dart 层公共 API 签名

**Ask First:**
- 如果验证发现需要修改 iOS SDK 内部行为（非 Flutter Plugin 层面可控）

**Never:**
- 不修改 Android 下载逻辑（已正常工作）
- 不修改 Dart 层 DownloadStateManager 的核心状态机
- 不添加新的 Platform Channel 方法

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| App 杀死后恢复下载 | 任务状态 paused，点击继续 | 下载恢复，进度条正常更新 | — |
| Resume 后 SDK 未实际恢复 | startDownloadTask 返回成功但 state 仍为 Stopped | 回退：删除旧任务并重新创建下载 | 删除失败时回退状态为 paused |
| 正常暂停后恢复（无重启） | 任务状态 paused，点击继续 | 行为不变，正常恢复 | — |
| Resume 事件推送 | Stopped → Running 状态变化 | 发送 taskResumed 事件（与 Android 一致） | — |

</frozen-after-approval>

## Code Map

- `polyv_media_player/ios/Classes/PLVFlutterDownloadMonitor.m` -- 下载状态监控、事件发送；`sendDownloadResumedEvent` (~L230-250) 发错事件类型
- `polyv_media_player/ios/Classes/PolyvMediaPlayerPlugin.m` -- `handleResumeDownload` (~L859-893) 无状态验证；`handleStartDownload` (~L1002-) 可作回退参考
- `polyv_media_player/lib/infrastructure/download/download_event_handler.dart` -- Dart 事件处理器，已有 `taskResumed` 分支处理
- `polyv_media_player/lib/infrastructure/download/download_state_manager.dart` -- `resumeTask` (~L394-415)，强一致性模式

## Tasks & Acceptance

**Execution:**

- [x] `PLVFlutterDownloadMonitor.m` -- 修复 `sendDownloadResumedEvent` 将事件类型从 `taskProgress` 改为 `taskResumed` -- 与 Dart 层 `_handleTaskResumed` 和 Android 行为对齐

- [x] `PolyvMediaPlayerPlugin.m` -- 在 `handleResumeDownload` 中添加延迟验证：调用 `startDownloadTask:` 后 dispatch_after 1.5s 检查 `downloadInfo.state`，若仍为 Stopped 则回退：先删除旧任务再通过 `requestVideoPriorityCacheWithVid:` 重新创建下载 -- 确保被杀死后的中断下载能恢复

- [x] `PolyvMediaPlayerPlugin.m` -- 提取 `verifyDownloadRunningWithFallback:` 辅助方法供 resume 和 retry 复用 -- 避免重复代码

**Acceptance Criteria:**

- Given iOS 下载中途 App 被杀死，when 重新打开后点击继续下载，then 下载恢复且进度条正常更新
- Given iOS Stopped → Running 状态变化，when Monitor 检测到变化，then 发送 `taskResumed` 事件
- Given iOS `startDownloadTask:` 后状态未变为 Running，when 1.5s 验证超时，then 自动回退为重新创建下载任务

## Spec Change Log

## Design Notes

**回退策略：** iOS SDK 的 `startDownloadTask:` 在 App 被杀死后可能无法恢复中断的下载（缓存的 `PLVDownloadInfo` 可能缺少有效的下载凭证）。回退方案：删除旧任务 → 通过 `requestVideoPriorityCacheWithVid:` 获取最新视频信息 → 创建新下载任务。这确保即使恢复失败，用户也不会永久卡住。

**验证时机：** 使用 `dispatch_after` 1.5 秒而非同步检查，给 SDK 足够时间处理状态转换。1.5 秒 > Monitor 的 1 秒轮询间隔，确保至少有一次轮询机会检测到状态变化。

## Verification

**Commands:**
- `cd polyv_media_player && fvm flutter test` -- expected: all tests pass
- `cd polyv_media_player && fvm flutter test example` -- expected: all tests pass

**Manual checks:**
- 在 iOS 真机上：开始下载 → 杀掉 App → 重新打开 → 下载中心点击继续 → 确认进度条正常更新
- 检查 Xcode Console 日志中 `[PolyvPlugin]` 前缀的下载状态变化记录

## Suggested Review Order

**事件类型修复**

- 将 resume 事件类型从 taskProgress 改为 taskResumed，与 Dart/Android 对齐
  [`PLVFlutterDownloadMonitor.m:212`](../../polyv_media_player/ios/Classes/PLVFlutterDownloadMonitor.m#L212)

**延迟验证与回退机制**

- 核心回退方法：1.5s 后验证下载状态，失败则删除并重新创建，含去重和边界检查
  [`PolyvMediaPlayerPlugin.m:1116`](../../polyv_media_player/ios/Classes/PolyvMediaPlayerPlugin.m#L1116)

- 去重属性：防止快速多次点击触发多个并发回退
  [`PolyvMediaPlayerPlugin.m:71`](../../polyv_media_player/ios/Classes/PolyvMediaPlayerPlugin.m#L71)

- resume 调用入口：在 startDownloadTask 成功后触发延迟验证
  [`PolyvMediaPlayerPlugin.m:890`](../../polyv_media_player/ios/Classes/PolyvMediaPlayerPlugin.m#L890)

- retry 调用入口：复用同一验证逻辑
  [`PolyvMediaPlayerPlugin.m:934`](../../polyv_media_player/ios/Classes/PolyvMediaPlayerPlugin.m#L934)

- 回退删除时发送 taskRemoved 事件，确保 Dart 层状态同步
  [`PolyvMediaPlayerPlugin.m:1174`](../../polyv_media_player/ios/Classes/PolyvMediaPlayerPlugin.m#L1174)
