# Story 9.6: 空状态处理

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

作为最终用户，
我想要看到友好的空状态提示，
以便了解当前没有下载任务。

## Acceptance Criteria

1. **Given** 下载中没有任务
**When** 查看下载中 Tab
**Then** 显示空状态图标和提示文字
**And** 图标为下载图标（48x48px，半透明白色）
**And** 提示文字为"暂无下载任务"

2. **Given** 已完成中没有任务
**When** 查看已完成 Tab
**Then** 显示空状态图标和提示文字
**And** 图标为完成图标（48x48px，半透明白色）
**And** 提示文字为"暂无已完成视频"

3. **Given** 空状态显示中
**When** 有新任务添加
**Then** 空状态自动隐藏
**And** 显示任务列表

4. **Given** 有任务显示中
**When** 删除最后一个任务
**Then** 自动显示空状态

## Tasks / Subtasks

- [x] 实现空状态 UI 组件 (AC: 1, 2)
  - [x] 在 `DownloadingTabView` 中添加 `_buildEmptyState()` 方法
  - [x] 在 `CompletedTabView` 中添加 `_buildEmptyState()` 方法
  - [x] 实现图标显示（下载中/已完成使用不同图标）
  - [x] 实现提示文字显示

- [x] 实现空状态条件渲染 (AC: 3, 4)
  - [x] 使用 `Consumer<DownloadStateManager>` 监听任务列表变化
  - [x] 当 `tasks.isEmpty` 时显示空状态
  - [x] 当 `tasks.isNotEmpty` 时显示任务列表

- [x] UI 样式与原型对齐
  - [x] 垂直居中布局
  - [x] 图标尺寸 48x48px
  - [x] 图标颜色透明度 50%
  - [x] 图标与文字间距 12px
  - [x] 文字大小 14px，颜色透明度 70%

## Dev Notes

### UI 样式参考

**原型代码路径**: `/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/DownloadCenterPage.tsx`

**空状态组件结构** (原型第 289-308 行):
```typescript
// 下载中空状态
{activeTab === "downloading" && downloadingItems.length === 0 && (
  <div className="flex flex-col items-center justify-center py-20">
    <Download className="w-12 h-12 text-slate-500 opacity-50" />
    <p className="text-sm text-slate-500 mt-3">暂无下载任务</p>
  </div>
)}

// 已完成空状态
{activeTab === "completed" && completedItems.length === 0 && (
  <div className="flex flex-col items-center justify-center py-20">
    <CheckCircle2 className="w-12 h-12 text-slate-500 opacity-50" />
    <p className="text-sm text-slate-500 mt-3">暂无已完成视频</p>
  </div>
)}
```

**关键样式规范**:
| 元素 | Tailwind 类 | Flutter 对应值 |
|------|------------|---------------|
| 布局 | `flex flex-col items-center justify-center` | `Column`, `mainAxisAlignment: center`, `crossAxisAlignment: center` |
| 内边距 | `py-20` | 无需额外 padding（Center 已自动居中）|
| 图标尺寸 | `w-12 h-12` | `size: 48` |
| 图标颜色 | `text-slate-500 opacity-50` | `Colors.white.withValues(alpha: 0.5)` |
| 图标与文字间距 | `mt-3` | `SizedBox(height: 12)` |
| 文字大小 | `text-sm` | `fontSize: 14` |
| 文字颜色 | `text-slate-500` | `Colors.white.withValues(alpha: 0.7)` |

### 原生端逻辑参考

**iOS 参考**: `/Users/nick/projects/polyv/ios/polyv-ios-media-player-sdk-demo/PLViOSMediaPlayerDemo/PolyvIOSMediaPlayerDemo/PolyvVodScenes/Secenes/CacheCenter/View/PLVDownloadNoDataTipsView.m`

**iOS 实现关键逻辑**:
```objective-c
// 空状态显示条件判断（numberOfRowsInSection 数据源方法）
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger number = self.downloadInfos.count;
    self.tableView.backgroundView = number ? nil : self.tipsView;
    return number;
}
```

**iOS 空状态样式**:
- 图片: `plv_download_nodata`, 60x60
- 文字: @"暂无下载内容", 白色, 12号字体
- 背景色: RGB(12, 38, 65)

**Android 参考**: `/Users/nick/projects/polyv/android/polyv-android-media-player-sdk-demo/common/src/main/java/net/polyv/android/player/common/modules/download/list/PLVMPDownloadListViewModel.kt`

**Android 实现逻辑**:
```kotlin
// 通过 LiveData 观察下载列表，自动处理空状态
val downloadingList = repo.mediator.downloadingList
val downloadedList = repo.mediator.downloadedList
```

### Flutter 实现分析

**当前实现状态**: 空状态 UI 已在 `download_center_page.dart` 中实现

**下载中空状态** (第 225-246 行):
```dart
Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.download_rounded,
          size: 48,
          color: Colors.white.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 12),
        Text(
          '暂无下载任务',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    ),
  );
}
```

**已完成空状态** (第 277-298 行):
```dart
Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          size: 48,
          color: Colors.white.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 12),
        Text(
          '暂无已完成视频',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    ),
  );
}
```

### 条件渲染逻辑

**下载中 Tab** (第 191-196 行):
```dart
final tasks = stateManager.downloadingTasks;

if (tasks.isEmpty) {
  return _buildEmptyState();
}
```

**已完成 Tab** (第 257-262 行):
```dart
final tasks = stateManager.completedTasks;

if (tasks.isEmpty) {
  return _buildEmptyState();
}
```

### Project Structure Notes

**文件位置**:
```
polyv_media_player/example/lib/pages/download_center/
└── download_center_page.dart       # 包含空状态 UI 实现（内联方法）
```

**现有实现说明**:
- 空状态 UI 已作为 Tab 视图的私有方法实现
- `DownloadingTabView._buildEmptyState()` - 下载中空状态
- `CompletedTabView._buildEmptyState()` - 已完成空状态
- 无需额外创建独立组件

### 与现有代码的集成

**状态管理模式**:
- 复用 Story 9.1 创建的 `DownloadStateManager`
- 使用 `Consumer<DownloadStateManager>` 监听状态变化
- 当任务列表为空时自动显示空状态

**图标映射**:
| 功能 | Web (Lucide) | Flutter (Material) |
|------|--------------|-------------------|
| 下载 | `Download` | `Icons.download_rounded` |
| 完成 | `CheckCircle2` | `Icons.check_circle_outline_rounded` |

### 业务逻辑归属原则 (CRITICAL)

根据 `project-context.md` 第 8 节规则：

> **Flutter (Dart) 层职责**:
> - 判断任务列表是否为空
> - 决定显示空状态还是任务列表
>
> **原生层职责**:
> - 提供下载任务列表数据
> - 通过 EventChannel 推送任务变化事件

**本 Story 的空状态判断完全在 Flutter 层实现**，基于 `DownloadStateManager.downloadingTasks.isEmpty` 和 `completedTasks.isEmpty`。

### 已完成实现说明

**实现状态**: ✅ 空状态 UI 已在 Story 9.1 实现时完成

本 Story 的空状态功能已在 `download_center_page.dart` 中实现：
1. ✅ 下载中 Tab 空状态（图标 + 提示文字）
2. ✅ 已完成 Tab 空状态（图标 + 提示文字）
3. ✅ 条件渲染逻辑（基于任务列表是否为空）
4. ✅ UI 样式与原型对齐

**本 Story 主要用于文档化现有实现**，确保：
- UI 实现与原型代码完全一致
- 空状态触发逻辑正确
- 与状态管理器集成正确

### 可选改进（如需进一步优化）

如果需要增强空状态体验，可考虑：
1. 添加淡入动画（使用 `AnimatedOpacity`）
2. 添加引导按钮（如"去浏览视频"）
3. 添加插图替代纯图标

**动画示例**:
```dart
Widget _buildEmptyState() {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: const Duration(milliseconds: 300),
    builder: (context, value, child) {
      return Opacity(
        opacity: value,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.download_rounded,
                size: 48,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                '暂无下载任务',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
```

### References

- [Source: docs/planning-artifacts/epics.md#Epic 9] - Epic 9 完整需求
- [Source: docs/planning-artifacts/epics.md#Story 9.6] - Story 9.6 验收标准
- [Source: docs/project-context.md] - 项目架构规范
- [Source: docs/implementation-artifacts/9-1-download-center.md] - Story 9.1 实现记录
- [Source: docs/implementation-artifacts/9-2-download-progress.md] - Story 9.2 实现记录
- UI 参考: `/Users/nick/projects/polyv/iOS/polyv-vod/src/components/demo/DownloadCenterPage.tsx`
- iOS 空状态参考: `/Users/nick/projects/polyv/ios/polyv-ios-media-player-sdk-demo/PLViOSMediaPlayerDemo/PolyvIOSMediaPlayerDemo/PolyvVodScenes/Secenes/CacheCenter/View/PLVDownloadNoDataTipsView.m`

## Dev Agent Record

### Agent Model Used

claude-opus-4-5-20251101

### Debug Log References

None

### Completion Notes List

- ✅ 空状态 UI 已在 `download_center_page.dart` 中实现
- ✅ 下载中 Tab 空状态：下载图标 + "暂无下载任务"
- ✅ 已完成 Tab 空状态：完成图标 + "暂无已完成视频"
- ✅ UI 样式与原型代码对齐（48x48 图标，50% 透明度，12px 间距）
- ✅ 条件渲染逻辑正确（基于 `tasks.isEmpty`）
- ✅ 与 Provider 状态管理器集成正确
- ✅ 所有 656 个测试通过（无回归）

**实现位置**: `polyv_media_player/example/lib/pages/download_center/download_center_page.dart`
- 第 225-246 行: `DownloadingTabView._buildEmptyState()`
- 第 277-298 行: `CompletedTabView._buildEmptyState()`

### File List

**已存在的实现文件**:
- `polyv_media_player/example/lib/pages/download_center/download_center_page.dart` - 包含空状态 UI 实现（无需修改）

**测试文件**:
- `polyv_media_player/example/lib/pages/download_center/download_center_page_test.dart` - 包含空状态渲染测试

