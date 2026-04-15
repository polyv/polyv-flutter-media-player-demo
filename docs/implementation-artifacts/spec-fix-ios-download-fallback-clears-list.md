---
title: 'Fix: iOS 下载恢复回退机制导致列表清空和进度丢失'
type: 'bugfix'
created: '2026-04-15'
status: 'done'
baseline_commit: '4265951'
context:
  - 'docs/project-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates scope">

## Intent

**Problem:** iOS 下载过程中退出 App 后重新打开，在下载中心点击继续下载，下载列表清空。退出重进后记录恢复，但下载进度从 0% 开始重新下载。Android 相同流程正常。

**Approach:** 修改 iOS 原生层 `verifyDownloadRunningWithFallback` 方法的回退逻辑：(1) 不再发送 `taskRemoved` 事件，避免 Dart 层任务被移除导致列表清空；(2) 改为发送 `taskProgress` 事件（status=preparing），让任务始终可见且状态连续。

</frozen-after-approval>

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
| App 杀死后恢复下载（回退触发） | 任务 paused，点击继续，1.5s 后回退触发 | 任务状态变为 preparing，列表不空，然后从 0% 重新下载 | — |
| 回退创建新任务失败 | 网络错误或视频信息获取失败 | 任务保持 preparing 状态，不影响其他任务 | 日志记录，不 crash |
| 正常暂停后恢复（无重启，回退不触发） | 任务 paused，点击继续 | 行为不变，正常恢复，Monitor 发送 taskResumed | — |
| 快速多次点击继续 | 同一 vid 多次 resume 调用 | 去重机制（pendingFallbackVids）防止并发回退 | — |

## Code Map

- `polyv_media_player/ios/Classes/PolyvMediaPlayerPlugin.m` -- `verifyDownloadRunningWithFallback` (~L1116-1219) 中发送 taskRemoved 事件导致列表清空；需改为发送 taskProgress(preparing)
- `polyv_media_player/lib/infrastructure/download/download_event_handler.dart` -- `_handleTaskProgress` 已支持从事件数据创建/更新任务，无需修改
- `polyv_media_player/lib/infrastructure/download/download_state_manager.dart` -- `resumeTask` (~L394-415)，强一致性模式，无需修改

## Tasks & Acceptance

**Execution:**

- [x] `PolyvMediaPlayerPlugin.m` -- 在 `verifyDownloadRunningWithFallback` 中，将 `taskRemoved` 事件替换为 `taskProgress` 事件（status=preparing, downloadedBytes=0, totalBytes=当前任务filesize）-- 任务在 Dart 层保持可见，状态连续过渡为 preparing

- [x] `PolyvMediaPlayerPlugin.m` -- 在 `handleInitialize` 中调用 `setAccountID:` 后，调用异步版 `getUnfinishedDownloadList:` 恢复下载器和下载任务 -- 根因：同步版 `getUnfinishedDownloadList` 只返回任务列表但不创建下载器，导致 `startDownloadTask:` 无法恢复下载（与 Android 对比发现）

**Acceptance Criteria:**

- Given iOS 下载中途 App 被杀死，when 重新打开后点击继续下载，then 下载列表不空，任务状态显示 preparing 后开始重新下载
- Given iOS 回退机制触发，when 删除旧任务并重建，then Dart 层不收到 taskRemoved 事件，任务始终可见
- Given iOS 正常暂停后恢复（回退未触发），when 点击继续下载，then 行为与修改前一致
- Given iOS App 重启后 `handleInitialize` 被调用，when 异步 `getUnfinishedDownloadList:` 完成回调，then 下载器已创建、下载任务已恢复，后续 `startDownloadTask:` 能正常续传

## Spec Change Log

## Design Notes

**回退事件策略变更：** 原实现在回退时发送 `taskRemoved` 事件，Dart 层收到后从 store 中移除任务，导致下载列表瞬间清空。改为发送 `taskProgress` 事件（status=preparing），Dart 层会更新已有任务的状态和进度，任务始终可见。等新下载任务创建完成后，Monitor 的定时器会检测到新任务并发送正常的进度事件，覆盖 preparing 状态。

**下载续传的根因分析与修复：** 通过对比 Android 实现发现关键差异：Android SDK 的 `PLVMediaDownloaderManager.getDownloader()` 返回已有 downloader 并保持进度，`startDownloader()` 直接续传。iOS SDK 则有两个 `getUnfinishedDownloadList` 方法——同步版只返回任务列表、**不创建下载器**；异步版（带 completion block）**会创建下载器并恢复下载任务**。原代码只调用了同步版，导致 App 重启后 `PLVDownloadInfo` 虽然存在但没有对应的下载器，`startDownloadTask:` 自然无法启动下载。修复方案：在 `handleInitialize` 中 `setAccountID:` 之后，调用异步版 `getUnfinishedDownloadList:` 恢复下载器。这样后续 `startDownloadTask:` 可以正常续传。

## Verification

**Commands:**
- `cd polyv_media_player && fvm flutter test` -- expected: all tests pass
- `cd polyv_media_player && fvm flutter test example` -- expected: all tests pass

**Manual checks:**
- 在 iOS 真机上：开始下载 → 杀掉 App → 重新打开 → 下载中心点击继续 → 确认列表不空，任务状态从 paused → preparing → downloading
- 检查 Xcode Console 日志中 `[PolyvPlugin]` 前缀的下载状态变化记录

## Suggested Review Order

**回退事件修复**

- 将回退中的 taskRemoved 事件替换为 taskProgress(preparing) 事件
  [`PolyvMediaPlayerPlugin.m:1174`](../../polyv_media_player/ios/Classes/PolyvMediaPlayerPlugin.m#L1174)
