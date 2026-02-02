# Story 9.1: 下载中心页面框架

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

作为最终用户，
我想要进入下载中心查看下载任务，
以便管理离线视频。

## Acceptance Criteria

1. **Given** 用户在首页
**When** 点击下载中心按钮
**Then** 进入下载中心页面
**And** 显示两个 Tab：下载中、已完成
**And** 每个显示当前任务数量

2. **Given** 用户在下载中心页面
**When** 页面加载完成
**Then** 下载中 Tab 显示当前下载中的任务列表
**And** 已完成 Tab 显示已下载完成的任务列表
**And** Tab 切换流畅无卡顿

3. **Given** 下载中没有任务
**When** 查看下载中 Tab
**Then** 显示空状态提示（空状态具体实现在 Story 9.6）

4. **Given** 已完成中没有任务
**When** 查看已完成 Tab
**Then** 显示空状态提示（空状态具体实现在 Story 9.6）

## Tasks / Subtasks

- [x] 创建下载中心页面框架 (AC: 1, 2)
  - [x] 创建 `DownloadCenterPage` 页面组件
  - [x] 实现 TabBar 切换（下载中/已完成）
  - [x] 添加 Tab 标题上的任务数量显示
  - [x] 添加页面标题和返回按钮

- [x] 实现下载状态数据模型 (AC: 2)
  - [x] 创建 `DownloadTask` 数据模型
  - [x] 创建 `DownloadTaskStatus` 枚举（downloading, paused, completed, error）
  - [x] 创建 `DownloadStateManager` 状态管理类

- [x] 创建 Tab 视图组件 (AC: 2, 3, 4)
  - [x] 创建 `DownloadingTabView` 组件
  - [x] 创建 `CompletedTabView` 组件
  - [x] 实现空状态占位 UI（具体实现在 Story 9.6）

- [x] 实现路由导航 (AC: 1)
  - [x] 在首页添加下载中心按钮导航
  - [x] 配置路由路径 `/download-center`

## Dev Notes

### UI 样式参考

**原型代码路径**: `/Users/nick/projects/polyv/iOS/polyv-vod/src/components/demo/DownloadCenterPage.tsx`

**关键 UI 元素**:
- 页面顶部：标题 "下载中心" + 返回按钮
- Tab 切换：使用 `TabBar` 组件，两个 Tab 标签
- Tab 样式：选中状态下划线高亮，显示任务数量徽章
- 背景色：`#F5F5F5` (浅灰色背景)
- 卡片样式：白色背景，圆角 8px，阴影效果

**参考代码片段**:
```typescript
// DownloadCenterPage.tsx 关键结构
<Tabs>
  <TabList>
    <Tab>下载中 ({downloadingCount})</Tab>
    <Tab>已完成 ({completedCount})</Tab>
  </TabList>
  <TabPanel>
    <DownloadingList />
  </TabPanel>
  <TabPanel>
    <CompletedList />
  </TabPanel>
</Tabs>
```

### 原生端逻辑参考

**Android 参考**: `/Users/nick/projects/polyv/android/polyv-android-media-player-sdk-demo/scenes-download-center/`
- 使用 ViewPager + Fragment 实现 Tab 切换
- MVVM 架构，使用 LiveData 管理数据
- 下载状态枚举：`PLVMediaDownloadStatus`

**iOS 参考**: `/Users/nick/projects/polyv/ios/polyv-ios-media-player-sdk-demo/PLViOSMediaPlayerDemo/PolyvVodScenes/Secenes/CacheCenter/`
- 使用 UITab + UITableView 实现
- `PLVDownloadInfo` 类管理下载信息
- 状态枚举：`PLVVodDownloadState`

### 数据模型设计

根据架构文档中的「业务逻辑归属原则」，下载中心的状态管理应在 Flutter(Dart) 层统一实现：

```dart
/// 下载任务状态
enum DownloadTaskStatus {
  /// 准备中
  preparing,
  /// 等待下载
  waiting,
  /// 下载中
  downloading,
  /// 已暂停
  paused,
  /// 已完成
  completed,
  /// 失败
  error,
}

/// 下载任务数据模型
class DownloadTask {
  /// 任务唯一标识
  final String id;

  /// 视频 VID
  final String vid;

  /// 视频标题
  final String title;

  /// 视频缩略图
  final String? thumbnail;

  /// 文件总大小（字节）
  final int totalBytes;

  /// 已下载大小（字节）
  final int downloadedBytes;

  /// 下载进度 0.0-1.0
  double get progress => totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;

  /// 当前下载速度（字节/秒）
  final int bytesPerSecond;

  /// 任务状态
  final DownloadTaskStatus status;

  /// 错误信息（如果有）
  final String? errorMessage;

  /// 创建时间
  final DateTime createdAt;

  /// 完成时间（如果有）
  final DateTime? completedAt;
}

/// 下载状态管理器
class DownloadStateManager extends ChangeNotifier {
  /// 所有下载任务
  List<DownloadTask> _tasks = [];

  /// 获取下载中的任务
  List<DownloadTask> get downloadingTasks => _tasks
      .where((t) => t.status == DownloadTaskStatus.downloading ||
                   t.status == DownloadTaskStatus.preparing ||
                   t.status == DownloadTaskStatus.waiting)
      .toList();

  /// 获取已完成的任务
  List<DownloadTask> get completedTasks => _tasks
      .where((t) => t.status == DownloadTaskStatus.completed)
      .toList();

  /// 添加任务
  void addTask(DownloadTask task) {
    _tasks.add(task);
    notifyListeners();
  }

  /// 更新任务状态
  void updateTask(String id, DownloadTask updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index >= 0) {
      _tasks[index] = updatedTask;
      notifyListeners();
    }
  }

  /// 删除任务
  void removeTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  /// 获取任务数量
  int get downloadingCount => downloadingTasks.length;
  int get completedCount => completedTasks.length;
}
```

### Project Structure Notes

**文件位置**:
```
polyv_media_player/
├── lib/
│   ├── infrastructure/
│   │   └── download/              # 下载中心基础设施层（可跨 App 复用）
│   │       ├── download_task.dart
│   │       ├── download_task_status.dart
│   │       └── download_state_manager.dart
│
└── example/lib/
    ├── pages/
    │   └── download_center/       # 下载中心页面（Demo App UI）
    │       ├── download_center_page.dart
    │       ├── downloading_tab_view.dart
    │       ├── completed_tab_view.dart
    │       └── download_task_item.dart  # 任务卡片组件（后续 Story 使用）
```

**分层说明**:
- **Plugin 层** (`infrastructure/download/`): 数据模型和状态管理，不含 UI
- **Demo App 层** (`pages/download_center/`): 完整 UI 实现，供客户参考复制

### 与现有代码的集成

**状态管理模式**:
- 使用 Provider 的 `ChangeNotifier` 模式（与现有播放器状态管理一致）
- 通过 `ChangeNotifierProvider<DownloadStateManager>` 提供状态

**导航集成**:
- 在 `main.dart` 中添加下载中心路由
- 在首页入口按钮中添加导航逻辑

**颜色主题**:
- 复用 `PlayerColors` 中的颜色定义（如果适用）
- 或创建独立的 `DownloadColors` 类

### 技术约束

**架构设计：混合方案**

```
┌─────────────────────────────────────────────┐
│         Flutter (Dart) 层                   │
│  ┌─────────────────────────────────────────┐│
│  │ DownloadStateManager (任务状态管理)      ││
│  │ - 维护任务列表（从 SDK 同步）            ││
│  │ - UI 状态更新                            ││
│  │ - Provider 状态通知                      ││
│  └─────────────────────────────────────────┘│
└─────────────────────────────────────────────┘
                    ↕ Platform Channel
┌─────────────────────────────────────────────┐
│         Native SDK 层                       │
│  ┌─────────────────────────────────────────┐│
│  │ PLVMediaDownloaderManager (Android)     ││
│  │ PLVDownloadMediaManager (iOS)           ││
│  │ - 实际下载执行                           ││
│  │ - 文件存储 & 断点续传                    ││
│  │ - 任务持久化（应用重启自动恢复）          ││
│  └─────────────────────────────────────────┘│
└─────────────────────────────────────────────┘
```

**职责划分**:

| 层级 | 职责 | 说明 |
|------|------|------|
| **Flutter (Dart)** | 任务状态管理 | `DownloadStateManager` 维护任务列表副本，响应 UI 状态变化 |
| **Flutter (Dart)** | UI 渲染 | Tab 切换、任务卡片、进度显示等 |
| **Native SDK** | 下载执行 | 实际的文件下载、网络请求、断点续传 |
| **Native SDK** | 任务持久化 | SDK 内部存储，应用重启后自动恢复 |

**Platform Channel API 设计**:

```dart
// MethodChannel 方法
MethodChannel('com.polyv.media_player/download')

// 获取下载列表
await _channel.invokeMethod('getDownloadList')
// 返回: {'downloading': [...], 'completed': [...]}

// 添加下载任务
await _channel.invokeMethod('addDownloadTask', {
  'vid': 'e8888b0d3',
  'title': '视频标题',
  'quality': '720p',
})

// 暂停下载
await _channel.invokeMethod('pauseDownload', {'taskId': 'xxx'})

// 继续下载
await _channel.invokeMethod('resumeDownload', {'taskId': 'xxx'})

// 删除下载
await _channel.invokeMethod('deleteDownload', {'taskId': 'xxx'})

// EventChannel 事件流
EventChannel('com.polyv.media_player/download_events')
// 事件类型: taskAdded, taskProgress, taskCompleted, taskFailed, taskRemoved
```

**数据同步策略**:

1. **初始化同步**: 页面加载时调用 `getDownloadList` 获取所有任务
2. **事件监听**: 通过 EventChannel 监听 SDK 任务状态变化，实时更新 `DownloadStateManager`
3. **本地维护**: `DownloadStateManager` 作为 SDK 状态的镜像，供 UI 消费

**业务逻辑归属原则** (参考 architecture.md):
- 下载任务状态管理在 Flutter(Dart) 层统一实现（作为 SDK 状态的镜像）
- 原生层只提供底层下载能力（通过 Platform Channel 封装 SDK）
- 不在 iOS/Android 各自实现业务逻辑

**后续 Story 依赖**:
- Story 9.2: 下载进度显示 - 需要在 `DownloadingTabView` 中显示任务列表
- Story 9.3: 暂停/继续下载 - 需要添加控制按钮
- Story 9.4: 重试失败下载 - 需要处理错误状态
- Story 9.5: 删除下载任务 - 需要添加删除功能
- Story 9.6: 空状态处理 - 完善空状态 UI

### References

- [Source: docs/planning-artifacts/prd.md#Functional Requirements] - FR23-29 下载中心功能需求
- [Source: docs/planning-artifacts/architecture.md#Business Logic Ownership] - 业务逻辑归属原则
- [Source: docs/planning-artifacts/epics.md#Epic 9] - Epic 9 完整需求
- [Source: docs/implementation-artifacts/sprint-status.yaml] - Sprint 状态跟踪
- UI 参考: `/Users/nick/projects/polyv/iOS/polyv-vod/src/components/demo/DownloadCenterPage.tsx`
- Android 逻辑参考: `/Users/nick/projects/polyv/android/polyv-android-media-player-sdk-demo/scenes-download-center/`
- iOS 逻辑参考: `/Users/nick/projects/polyv/ios/polyv-ios-media-player-sdk-demo/PLViOSMediaPlayerDemo/PolyvVodScenes/Secenes/CacheCenter/`

## Dev Agent Record

### Agent Model Used

claude-opus-4-5-20251101

### Debug Log References

### Completion Notes List

- ✅ 实现了下载中心页面框架，包含 TabBar 切换和任务数量显示
- ✅ 创建了 `DownloadTaskStatus` 枚举，包含 6 种状态：preparing, waiting, downloading, paused, completed, error
- ✅ 创建了 `DownloadTask` 数据模型，支持进度计算、文件大小格式化等
- ✅ 创建了 `DownloadStateManager` 状态管理类，使用 Provider ChangeNotifier 模式
- ✅ 实现了 `DownloadingTabView` 和 `CompletedTabView` 组件
- ✅ 实现了空状态占位 UI（基础版本，将在 Story 9.6 完善）
- ✅ 首页下载中心按钮导航已集成
- ✅ 所有测试通过（656 tests passed）
- ✅ 代码符合项目规范，遵循 UI 原型设计

### Code Review Fixes (2026-01-26)

**修复的问题：**

1. ✅ 修复 `DownloadTask.copyWith()` - 添加 `clearValue` 常量，支持清除可选字段（thumbnail, errorMessage）
2. ✅ 修复 `DownloadTask.progress` - 添加边界保护，确保返回值在 [0.0, 1.0] 范围内
3. ✅ 修复 `DownloadStateManager.retryTask()` - 使用 `clearValue` 清除错误信息
4. ✅ 优化 `DownloadCenterPage` Provider 创建 - 将 `DownloadStateManager` 移至 State 中，避免每次 build 重建
5. ✅ 清理 `_formatBytes` 魔法数字 - 定义常量 `kb`, `mb`, `gb`
6. ✅ 移除 `home_page.dart` 误导性注释

**影响测试：**
- 更新 `download_task_test.dart` 中关于 copyWith 清除字段的测试
- 更新 `download_state_manager_test.dart` 中关于 retryTask 的测试
- 更新 progress 边界保护的测试预期

### File List

**新增文件：**
- `polyv_media_player/lib/infrastructure/download/download_task_status.dart` - 下载任务状态枚举及扩展方法
- `polyv_media_player/lib/infrastructure/download/download_task.dart` - 下载任务数据模型
- `polyv_media_player/lib/infrastructure/download/download_state_manager.dart` - 下载状态管理器
- `polyv_media_player/example/lib/pages/download_center/download_center_page.dart` - 下载中心页面（含 TabBar 和 Tab 视图组件）

**修改文件：**
- `polyv_media_player/lib/polyv_media_player.dart` - 添加 download 模块导出
- `polyv_media_player/example/lib/pages/home_page.dart` - 移除占位 DownloadCenterPage，添加正确导入
