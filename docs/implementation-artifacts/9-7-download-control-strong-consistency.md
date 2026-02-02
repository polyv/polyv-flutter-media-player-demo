# Story 9.7: 下载控制强一致化（原生能力接入）

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

作为最终用户，
我想要对下载任务执行暂停/继续/重试/删除，
并且 UI 状态与原生下载 SDK 的执行结果严格一致（强一致），
以避免“UI 看起来成功但实际未生效”。

## Acceptance Criteria

1. **Given** 用户点击暂停/继续/重试/删除
**When** 原生层调用成功
**Then** Flutter 层才更新任务状态/列表
**And** UI 状态与原生执行结果一致

2. **Given** 用户点击暂停/继续/重试/删除
**When** 原生层调用失败（未实现/参数错误/找不到任务/SDK 错误）
**Then** Flutter 层不更新任务状态/列表（UI 保持不变）
**And** UI 展示错误提示
**And** 默认使用 SnackBar 展示错误信息
**And** 删除失败使用 Dialog 或等效强提示（可包含“重试/取消”）

3. **Given** 原生侧方法未实现或执行失败
**When** Flutter 调用 MethodChannel
**Then** 原生层返回明确 PlatformException（包含 code/message）

4. **Given** Flutter 层需要执行状态转换验证
**When** 任务处于不支持的状态（例如失败不可暂停、完成不可继续）
**Then** 状态规则由 Flutter 层决策
**And** 原生层不下沉业务规则，仅负责能力执行与错误返回

## Tasks / Subtasks

- [x] Dart：将 `DownloadStateManager` 的 `pauseTask/resumeTask/retryTask/deleteTask` 改为“原生成功才更新状态”，失败向上抛出/回传（移除当前容错式本地更新）
- [x] Dart：为下载中心页面的操作回调增加错误处理
  - [x] 暂停/继续/重试失败：SnackBar
  - [x] 删除失败：Dialog（提供重试/取消）
- [x] Platform Channel：确保下载相关方法的参数格式一致（id/taskId 字段名对齐）

- [x] iOS：实现下载控制方法（真实调用 SDK）
  - [x] `pauseDownload`：调用 iOS 下载 SDK 的暂停接口
  - [x] `resumeDownload`：调用 iOS 下载 SDK 的继续接口
  - [x] `retryDownload`：调用 iOS 下载 SDK 的重试/重新开始接口
  - [x] `deleteDownload`：调用 iOS 下载 SDK 删除任务与清理文件接口
  - [x] 失败时返回 `FlutterError`（code/message），不得返回成功

- [x] Android：实现下载控制方法（真实调用 SDK）
  - [x] `pauseDownload` / `resumeDownload` / `retryDownload` / `deleteDownload`
  - [x] 失败时 `result.error(code, message, details)`，不得返回成功

- [x] 原生侧：补齐 taskId -> SDK 下载对象的查找机制
  - [x] 找不到任务时返回 `not_found`

- [x] 测试：补齐强一致相关测试
  - [x] 单元测试：原生调用失败时 `DownloadStateManager` 不更新本地状态
  - [x] Widget 测试：失败时展示错误提示

## Dev Notes

### 错误码建议

- `unimplemented`: 方法未实现
- `invalid_args`: 参数缺失或格式错误
- `not_found`: 找不到对应 taskId
- `sdk_error`: SDK 执行失败（附 message）

### 业务逻辑归属原则

- Flutter 层：状态镜像、业务规则、UI
- 原生层：下载 SDK 能力封装与事件/错误回传

### References

- [Source: docs/planning-artifacts/epics.md#Story 9.7] - Story 9.7 验收标准
- [Source: docs/implementation-artifacts/9-3-pause-resume.md] - 暂停/继续现有实现记录（需强一致化）
- [Source: docs/implementation-artifacts/9-4-retry-failed.md] - 重试现有实现记录（需强一致化）
- [Source: docs/implementation-artifacts/9-5-delete-download.md] - 删除现有实现记录（需强一致化）

## Dev Agent Record

### Agent Model Used

Cascade

### Debug Log References

None

### Completion Notes List

- Dart 层 `DownloadStateManager` 已改为强一致性：原生调用成功才更新本地状态，失败时抛出 `PlatformException`
- UI 层已添加错误处理：暂停/继续/重试失败显示 SnackBar，删除失败显示带重试按钮的 Dialog
- iOS 原生层已实现 `pauseDownload`/`resumeDownload`/`retryDownload`/`deleteDownload`，调用 `PLVDownloadMediaManager` SDK
  - **Code Review 修复**：添加 @try-@catch 错误处理，确保 SDK 失败时返回 `FlutterError` 而非静默成功
  - **Code Review 修复**：参数名从 `args[@"id"]` 改为 `args[@"vid"]` 以匹配 Dart 层传递的参数
  - **Code Review 修复**：`deleteDownload` 找不到任务时返回 `NOT_FOUND` 错误而非视为成功
  - **Code Review 修复**：使用 `BOOL success` 检查 `removeDownloadTask:error:` 返回值
- Android 原生层已实现相同方法，调用 `PLVMediaDownloaderManager` SDK
  - **Code Review 修复**：参数键名从 `args["id"]` 改为 `args["vid"]` 修复了致命 bug（原代码永远获取不到 vid）
  - **Code Review 修复**：`deleteDownload` 找不到任务时返回 `NOT_FOUND` 错误而非视为成功
- 原生层通过 vid 查找下载任务，找不到时返回 `NOT_FOUND` 错误
- 测试已更新，添加 Story 9.7 强一致性测试组，验证原生失败时不更新本地状态
- **Code Review 修复**：更新 Dart 注释，准确描述强一致性行为（PlatformException 中断执行）
- **Code Review 修复**：UI 层参数命名从 `vid` 改为 `taskId` 提高可读性

## Senior Developer Review (AI)

### Review Date
2026-01-28

### Review Summary

执行对抗性代码审查，发现并修复 **12 个问题**：
- 🔴 9 CRITICAL（必须修复）
- 🟡 3 MEDIUM（建议修复）
- 🟢 2 LOW（可选修复）

### Issues Fixed

#### CRITICAL Issues (9)

1. **Android 参数键名错误** (`PolyvMediaPlayerPlugin.kt`)
   - 问题：使用 `args["id"]` 而非 `args["vid"]`，导致所有下载操作失败
   - 修复：将所有下载方法参数从 `"id"` 改为 `"vid"`

2. **iOS pauseDownload 无错误处理** (`PolyvMediaPlayerPlugin.m`)
   - 问题：SDK 调用失败时仍然返回 `result(nil)`，违反强一致性
   - 修复：添加 `@try-@catch` 块，失败时返回 `FlutterError`

3. **iOS resumeDownload 无错误处理** (`PolyvMediaPlayerPlugin.m`)
   - 问题：同上
   - 修复：添加 `@try-@catch` 块

4. **iOS retryDownload 无错误处理** (`PolyvMediaPlayerPlugin.m`)
   - 问题：同上
   - 修复：添加 `@try-@catch` 块

5. **iOS deleteDownload 逻辑错误** (`PolyvMediaPlayerPlugin.m`)
   - 问题：找不到任务时返回成功而非 `NOT_FOUND` 错误
   - 修复：返回 `NOT_FOUND` FlutterError

6. **iOS deleteDownload 未检查返回值** (`PolyvMediaPlayerPlugin.m`)
   - 问题：未检查 `removeDownloadTask:error:` 的 BOOL 返回值
   - 修复：使用 `BOOL success` 检查并验证 error

7. **Android deleteDownload 逻辑错误** (`PolyvMediaPlayerPlugin.kt`)
   - 问题：找不到任务时返回成功而非 `NOT_FOUND` 错误
   - 修复：返回 `NOT_FOUND` error

8. **Android 参数键名错误 (deleteDownload)** (`PolyvMediaPlayerPlugin.kt`)
   - 问题：使用 `args["id"]` 而非 `args["vid"]`
   - 修复：改为 `args["vid"]`

9. **Android 参数键名错误 (pause/resume/retry)** (`PolyvMediaPlayerPlugin.kt`)
   - 问题：同上
   - 修复：全部改为 `args["vid"]`

#### MEDIUM Issues (3)

10. **Dart 注释不清晰** (`download_state_manager.dart`)
    - 问题：注释说"原生成功才更新"但实现依赖异常传播
    - 修复：更新注释，明确说明 PlatformException 中断执行的机制

11. **UI 层参数命名混淆** (`download_center_page.dart`)
    - 问题：变量名 `vid` 但实际传递的是 `task.id`
    - 修复：参数名从 `vid` 改为 `taskId`

12. **iOS 参数名不一致** (`PolyvMediaPlayerPlugin.m`)
    - 问题：使用 `args[@"id"]` 而非 `args[@"vid"]`
    - 修复：改为 `args[@"vid"]`

#### LOW Issues (2)

13. **pauseTask 注释不精确** (`download_state_manager.dart`)
    - 修复：更新注释说明强一致性机制

14. **resumeTask 注释不精确** (`download_state_manager.dart`)
    - 修复：更新注释说明强一致性机制

### Files Modified

- `polyv_media_player/lib/infrastructure/download/download_state_manager.dart` - 更新注释
- `polyv_media_player/example/lib/pages/download_center/download_center_page.dart` - 修复参数命名
- `polyv_media_player/ios/Classes/PolyvMediaPlayerPlugin.m` - 添加错误处理，修复参数名
- `polyv_media_player/android/src/main/kotlin/com/polyv/polyv_media_player/PolyvMediaPlayerPlugin.kt` - 修复参数键名

### Test Results

✅ 所有单元测试通过（exit code: 0）
- 包括 Story 9.7 强一致性测试组
- 验证原生失败时不更新本地状态

### Recommendation

**✅ APPROVED** - 所有关键和中等问题已修复，代码符合 Story 9.7 强一致性要求。

### File List

- `polyv_media_player/lib/infrastructure/download/download_state_manager.dart` - 强一致性实现，支持注入 channel
- `polyv_media_player/example/lib/pages/download_center/download_center_page.dart` - UI 错误处理
- `polyv_media_player/ios/Classes/PolyvMediaPlayerPlugin.m` - iOS 原生下载控制方法
- `polyv_media_player/android/src/main/kotlin/com/polyv/polyv_media_player/PolyvMediaPlayerPlugin.kt` - Android 原生下载控制方法
- `polyv_media_player/test/infrastructure/download/download_state_manager_test.dart` - 强一致性测试
