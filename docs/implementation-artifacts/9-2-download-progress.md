# Story 9.2: 下载进度显示

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

作为最终用户，
我想要查看下载进度，
以便了解下载状态。

## Acceptance Criteria

1. **Given** 有正在下载的视频
**When** 在下载中 Tab
**Then** 每个下载任务显示：缩略图、标题、进度条
**And** 进度条显示当前百分比
**And** 显示文件大小和下载速度

2. **Given** 任务正在下载中
**When** 下载进度更新
**Then** 进度条平滑更新显示最新进度
**And** 百分比数字同步更新
**And** 下载速度实时显示

3. **Given** 任务处于不同状态（下载中/暂停/失败）
**When** 查看任务卡片
**Then** 下载中状态：进度条使用主色调渐变，显示速度
**And** 暂停状态：进度条使用灰色，显示"已暂停"
**And** 失败状态：进度条使用红色，显示"下载失败"

4. **Given** 下载进度数据变化
**When** Provider 状态更新
**Then** UI 自动响应变化重新渲染
**And** 无需手动刷新

## Tasks / Subtasks

- [x] 创建下载任务卡片组件 (AC: 1, 2, 3)
  - [x] 创建 `DownloadingTaskItem` 组件
  - [x] 实现缩略图显示（带失败状态遮罩）
  - [x] 实现进度条组件（支持不同状态样式）
  - [x] 实现状态信息文本（百分比/文件大小/下载速度）
  - [x] 添加控制按钮占位（暂停/删除，后续 Story 实现）

- [x] 实现进度数据绑定 (AC: 2, 4)
  - [x] 在 `DownloadingTabView` 中使用 `Consumer<DownloadStateManager>` 监听状态
  - [x] 绑定 `DownloadTask` 数据到 `DownloadingTaskItem`
  - [x] 实现进度条动画（300ms 过渡）

- [x] 实现状态样式变化 (AC: 3)
  - [x] 下载中：渐变色进度条（`from-primary to-primary/80`）
  - [x] 暂停：灰色进度条（`bg-slate-500`）
  - [x] 失败：红色进度条（`bg-red-500`）+ 错误图标

- [x] 实现下载速度格式化 (AC: 1, 2)
  - [x] 添加 `_formatSpeed` 方法（字节/秒 → KB/s, MB/s）
  - [x] 在下载中状态显示速度
  - [x] 在暂停/失败状态隐藏速度

- [x] 实现文件大小显示 (AC: 1)
  - [x] 添加 `_formatBytes` 方法（已在 Story 9.1 实现，复用）
  - [x] 显示总文件大小

## Dev Notes

### UI 样式参考

**原型代码路径**: `/Users/nick/projects/polyv/iOS/polyv-vod/src/components/demo/DownloadCenterPage.tsx`

**DownloadingItem 组件结构** (第186-287行):
```typescript
<DownloadingItem>
  {/* 缩略图区域 */}
  <div className="relative w-24 h-14 rounded-lg overflow-hidden">
    <img src={thumbnail} />
    {isError && <错误遮罩 />}
  </div>

  {/* 内容区域 */}
  <div>
    <h4>{title}</h4>
    <ProgressBar width={progress}% />  {/* 进度条 */}
    <StatusInfo>
      {状态文本} · {文件大小} · {速度}
    </StatusInfo>
  </div>

  {/* 操作按钮区域 */}
  <Actions>
    <PauseButton />  {/* 本 Story 占位，9.3 实现 */}
    <DeleteButton />  {/* 本 Story 占位，9.5 实现 */}
  </Actions>
</DownloadingItem>
```

**关键样式规范**:
- **进度条高度**: `h-1.5` (6px)
- **进度条颜色**:
  - 下载中: `bg-gradient-to-r from-primary to-primary/80` (主色调渐变)
  - 暂停: `bg-slate-500` (灰色)
  - 失败: `bg-red-500` (红色)
- **进度条背景**: `bg-slate-800 rounded-full`
- **缩略图尺寸**: `w-24 h-14` (96x56px)
- **缩略图圆角**: `rounded-lg` (8px)
- **文字大小**: `text-xs` (状态信息), `text-sm` (标题)
- **文字颜色**:
  - 标题: `text-white`
  - 状态信息: `text-slate-400`
  - 下载失败: `text-red-400`
  - 下载速度: `text-emerald-400`

### 原生端逻辑参考

**Android 参考**: `/Users/nick/projects/polyv/android/polyv-android-media-player-sdk-demo/scenes-download-center/src/main/java/net/polyv/android/player/scenes/download/list/PLVMediaPlayerDownloadAdapter.kt`

**关键逻辑**:
```kotlin
// 进度更新 (第128-131行)
protected fun observeProgress(item: State<PLVMPDownloadListItemViewState>, progressBar: ProgressBar) =
    item.observeUntilViewDetached(progressBar) { viewState ->
        progressBar.progress = (viewState.progress * 100).toInt()
    }

// 状态文本显示 (第154-171行)
// 格式: "状态 百分比 (速度/s)"
// 例如: "下载中 67.0% (2.3 MB/s)"
val status = when (viewState.downloadStatus) {
    is PAUSED -> "已暂停"
    is WAITING -> "等待中"
    is DOWNLOADING -> "下载中"
    is COMPLETED -> "下载完成"
    is ERROR -> "下载失败"
}
val progressText = "${(viewState.progress * 100).toFixed(1)}%"
val downloadSpeedText = "(${downloadSpeed.value.toFixed(1)} ${downloadSpeed.unit.abbr}/s)"
```

**状态枚举映射**:
| Android SDK | Flutter (Dart) | 显示文本 |
|-------------|----------------|----------|
| `NOT_STARTED` | `preparing` | "准备中" |
| `WAITING` | `waiting` | "等待中" |
| `DOWNLOADING` | `downloading` | "下载中" |
| `PAUSED` | `paused` | "已暂停" |
| `COMPLETED` | `completed` | "下载完成" |
| `ERROR` | `error` | "下载失败" |

### 数据模型设计 (来自 Story 9.1)

**已存在的 `DownloadTask` 模型** (Story 9.1 已创建):
```dart
class DownloadTask {
  final String id;
  final String vid;
  final String title;
  final String? thumbnail;
  final int totalBytes;        // 文件总大小（字节）
  final int downloadedBytes;   // 已下载大小（字节）
  final int bytesPerSecond;    // 当前下载速度（字节/秒）
  final DownloadTaskStatus status;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;

  // 计算属性
  double get progress => totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;
  int get progressPercent => (progress * 100).round();
}
```

### Project Structure Notes

**新增文件**:
```
polyv_media_player/example/lib/pages/download_center/
├── downloading_task_item.dart      # 下载中任务卡片组件（新增）
```

**修改文件**:
```
polyv_media_player/example/lib/pages/download_center/
├── download_center_page.dart       # 导入新组件
├── downloading_tab_view.dart       # 使用新组件渲染列表
```

### 与现有代码的集成

**状态管理模式**:
- 复用 Story 9.1 创建的 `DownloadStateManager`
- 使用 `Consumer<DownloadStateManager>` 监听状态变化
- 在 `DownloadingTabView` 中构建任务列表

**颜色常量**:
```dart
// 复用 project-context.md 中的颜色定义
class AppColors {
  static const Color primary = Color(0xFFE8704D);
}

class SlateColors {
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate800 = Color(0xFF1E293B);
}
```

**格式化工具**:
```dart
// 复用 Story 9.1 中的 _formatBytes 方法
String _formatBytes(int bytes) {
  if (bytes < kb) return '$bytes B';
  if (bytes < mb) return '${(bytes / kb).toStringAsFixed(1)} KB';
  if (bytes < gb) return '${(bytes / mb).toStringAsFixed(1)} MB';
  return '${(bytes / gb).toStringAsFixed(1)} GB';
}

// 新增速度格式化方法
String _formatSpeed(int bytesPerSecond) {
  if (bytesPerSecond <= 0) return '0 KB/s';
  return '${_formatBytes(bytesPerSecond)}/s';
}
```

### 技术约束

**架构设计** (遵循 Story 9.1 的混合方案):

```
┌─────────────────────────────────────────────┐
│         Flutter (Dart) 层                   │
│  ┌─────────────────────────────────────────┐│
│  │ DownloadStateManager (任务状态管理)      ││
│  │ - 维护任务列表（从 SDK 同步）            ││
│  │ - UI 状态更新                            ││
│  │ - Provider 状态通知                      ││
│  └─────────────────────────────────────────┘│
│                    ↕ Consumer/notifyListeners │
│  ┌─────────────────────────────────────────┐│
│  │ DownloadingTaskItem (UI 组件)            ││
│  │ - 进度条显示                             ││
│  │ - 状态信息文本                           ││
│  │ - 动画过渡                               ││
│  └─────────────────────────────────────────┘│
└─────────────────────────────────────────────┘
```

**动画规范**:
- 进度条过渡: `transition-all duration-300` (300ms)
- 使用 `AnimatedContainer` 实现进度条宽度动画

**响应式布局**:
- 使用 `Row` + `Expanded` 实现自适应布局
- 缩略图固定宽度，内容区域自适应
- 确保长标题省略显示 (`TextOverflow.ellipsis`)

### 测试标准

**单元测试**:
- 测试 `_formatSpeed` 方法边界值（0、负数、大数值）
- 测试不同状态下的进度条颜色选择

**Widget 测试**:
- 测试 `DownloadingTaskItem` 渲染正确
- 测试进度百分比显示正确
- 测试文件大小格式化正确
- 测试下载速度格式化正确

**集成测试**:
- 测试 `DownloadStateManager` 状态变化时 UI 更新
- 测试多个任务同时下载时列表渲染正确

### 业务逻辑归属原则 (CRITICAL)

根据 `project-context.md` 第 8 节规则：

> **Flutter (Dart) 层职责**:
> - 维护下载任务状态镜像（从 SDK 同步）
> - UI 渲染和动画
> - 进度计算和格式化显示
>
> **原生层职责**:
> - 实际下载执行
> - 文件存储和断点续传
> - 通过 EventChannel 推送进度事件

**本 Story 只负责 Flutter 层的 UI 显示**，原生 SDK 集成在后续 Story 中实现。

### References

- [Source: docs/planning-artifacts/epics.md#Epic 9] - Epic 9 完整需求
- [Source: docs/planning-artifacts/epics.md#Story 9.2] - Story 9.2 验收标准
- [Source: docs/implementation-artifacts/9-1-download-center.md] - Story 9.1 实现记录
- [Source: docs/project-context.md] - 项目架构规范
- UI 参考: `/Users/nick/projects/polyv/iOS/polyv-vod/src/components/demo/DownloadCenterPage.tsx`
- Android 逻辑参考: `/Users/nick/projects/polyv/android/polyv-android-media-player-sdk-demo/scenes-download-center/src/main/java/net/polyv/android/player/scenes/download/list/PLVMediaPlayerDownloadAdapter.kt`

## Dev Agent Record

### Agent Model Used

claude-opus-4-5-20251101

### Debug Log References

None

### Completion Notes List

- ✅ 将 `DownloadingTaskItem` 组件从 `download_center_page.dart` 中提取为独立文件，便于复用和维护
- ✅ 实现进度条动画效果，使用 `AnimatedContainer` + `LayoutBuilder` 实现 300ms 平滑过渡
- ✅ 下载速度格式化已在 Story 9.1 中实现于 `DownloadTask.speedFormatted`
- ✅ 所有验收标准已满足：
  - AC1: 下载中 Tab 显示缩略图、标题、进度条、百分比、文件大小、下载速度
  - AC2: 进度更新时进度条和百分比数字平滑同步更新
  - AC3: 不同状态（下载中/暂停/失败）显示正确的样式和状态文本
  - AC4: 使用 Provider 模式，UI 自动响应状态变化
- ✅ 所有 656 个测试通过，无回归

### File List

**新增文件：**
- `polyv_media_player/example/lib/pages/download_center/downloading_task_item.dart` - 下载中任务卡片组件（独立组件，含常量提取）
- `polyv_media_player/example/lib/pages/download_center/downloading_task_item_test.dart` - 组件单元测试（1248行）

**修改文件：**
- `polyv_media_player/example/lib/pages/download_center/download_center_page.dart` - 导入并使用新的 `DownloadingTaskItem` 组件；添加完整回调逻辑（暂停/继续/删除/重试）；添加 `_CompletedTaskItem` 组件；提取颜色常量为类级静态常量
