# Story 6.3: 视频列表展示

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

作为最终用户，
我想要查看可播放的视频列表，
以便选择想看的视频。

## Acceptance Criteria

### 场景 1: 视频列表 UI 完全还原 polyv-vod 原型设计

**Given** 已完成 Story 6.2（获取视频列表 API），Flutter 层已有 `VideoListService` 返回视频列表数据
**When** 用户进入长视频页面（LongVideoPage）
**Then** 视频列表区域精确还原 `/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/LongVideoPage.tsx` 的设计
**And** 视频列表项精确还原 `/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/VideoListItem.tsx` 的设计
**And** 包含以下视觉元素：
  - 列表标题："全部视频 · {count}"
  - 视频项左侧边框高亮（当前播放视频）
  - 视频缩略图（28x16 比例）
  - 时长徽章（右下角黑色半透明背景）
  - 播放指示器（当前播放视频时显示）
  - 视频标题和播放次数
  - 分隔线（slate-800/30 透明度）

### 场景 2: 当前播放视频高亮显示

**Given** 视频列表已加载
**When** 某个视频正在播放
**Then** 该视频项显示高亮样式：
  - 左侧 2px primary 色边框
  - 背景色为 primary/10
  - 标题文字为 primary 色
  - 缩略图上显示播放图标覆盖层
**And** 其他视频项保持默认样式

### 场景 3: 列表滚动与分页加载

**Given** 视频列表超过一页（默认 pageSize=20）
**When** 用户滚动到列表底部
**Then** 自动加载下一页数据（通过 `VideoListRequest.nextPage()`）
**And** 显示加载指示器
**And** 无更多数据时显示"已加载全部"提示

### 场景 4: 列表项点击切换视频

**Given** 视频列表已显示
**When** 用户点击某个视频项
**Then** 停止当前视频播放
**And** 开始加载点击的视频
**And** 更新当前播放视频高亮状态
**And** 滚动列表使当前播放项可见

### 场景 5: 空状态处理

**Given** 视频列表为空或加载失败
**When** 显示视频列表区域
**Then** 显示友好的空状态提示：
  - 加载失败：显示错误图标和"加载失败，请重试"消息
  - 空列表：显示空图标和"暂无视频"消息
  - 加载中：显示 CircularProgressIndicator

### 场景 6: 与播放器状态同步

**Given** 视频列表已集成到 LongVideoPage
**When** 播放器状态变化（加载、播放、暂停、错误）
**Then** 视频列表正确响应：
  - 新视频开始加载时显示加载状态
  - 播放开始时更新当前播放项高亮
  - 播放错误时显示错误提示
**And** 列表状态与 `PlayerController.state` 保持同步

## Tasks / Subtasks

- [x] 创建视频列表 UI 组件
  - [x] 创建 `VideoListItem` 组件（还原 VideoListItem.tsx 设计）
  - [x] 创建 `VideoListView` 组件（列表容器）
  - [x] 创建 `VideoListHeader` 组件（列表标题）
  - [x] 实现当前播放高亮状态
- [x] 集成到 LongVideoPage
  - [x] 替换占位的"视频列表区域"为真实组件
  - [x] 连接 VideoListService 获取数据
  - [x] 实现列表项点击切换视频逻辑
  - [x] 与 PlayerController 状态同步
- [x] 实现滚动与分页
  - [x] 添加 ScrollController 监听滚动位置
  - [x] 实现自动加载下一页
  - [x] 添加加载和空状态处理
- [x] UI 样式精确还原
  - [x] 颜色、间距、圆角与原型一致
  - [x] 缩略图比例与原型一致（28x16）
  - [x] 动画效果与原型一致（hover/active 状态）
  - [x] 深色主题适配
- [x] 测试与验证
  - [x] 单元测试：VideoListItem 组件渲染
  - [x] 单元测试：VideoListView 状态管理
  - [x] 集成测试：视频切换流程
  - [x] UI 对比测试：与原型截图对比

## Dev Notes

### Story Context

- 所属 Epic: Epic 6 播放列表
- 前置依赖: Story 6.1（账号配置）、Story 6.2（视频列表 API）
- 后续 Story: Story 6.4（切换视频优化）

### Architecture Compliance

- **UI 组件位置**: `polyv_media_player/example/lib/player_skin/video_list/`
- **业务逻辑复用**: 使用 Plugin 的 `VideoListService` 获取数据
- **状态管理**: 通过 `PlayerController` 与播放器状态同步
- **Phase 1 分层**: UI 层在 Demo App，业务逻辑在 Plugin infrastructure/

### UI 实现参考（CRITICAL）

**必须先读取原型代码再实现 UI！**

| 组件 | 原型文件路径 |
|------|-------------|
| 长视频页面 | `/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/LongVideoPage.tsx` |
| 视频列表项 | `/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/VideoListItem.tsx` |

**VideoListItem.tsx 关键样式提取：**
```tsx
// 容器
className="w-full flex gap-3 p-4 text-left transition-colors"
// 当前播放：bg-primary/10 border-l-2 border-primary
// 其他：hover:bg-slate-800/50 border-l-2 border-transparent

// 缩略图容器
w-28 h-16 rounded-lg overflow-hidden flex-shrink-0 bg-slate-800

// 时长徽章
absolute bottom-1 right-1 bg-black/80 px-1.5 py-0.5 rounded text-[10px] text-white font-medium

// 播放指示器
absolute inset-0 bg-black/40 flex items-center justify-center
w-8 h-8 rounded-full bg-primary/90 flex items-center justify-center
Play 图标 w-4 h-4 text-white ml-0.5

// 标题
text-sm font-medium truncate
当前播放：text-primary
其他：text-white

// 播放次数
text-xs text-slate-500 mt-1
```

**LongVideoPage.tsx 列表区域样式：**
```tsx
// 列表容器
flex-1 overflow-auto pb-safe-bottom

// 列表标题
px-4 py-3
text-sm font-medium text-slate-400 mb-3
"全部视频 · {videoList.length}"

// 分隔线
divide-y divide-slate-800/30
```

### 原生 Demo 参考逻辑

**iOS Demo:** `/Users/nick/projects/polyv/ios/polyv-ios-media-player-sdk-demo/PLViOSMediaPlayerDemo/`
- 参考 `PolyvVodScenes` 中的 FeedScene 列表实现
- 列表与播放器的交互模式

**Android Demo:** `/Users/nick/projects/polyv/android/polyv-android-media-player-sdk-demo/`
- 参考 `PLVMockMediaResourceData` 数据结构
- 列表加载和状态管理

### 业务逻辑统一原则（IMPORTANT）

**本 Story 的业务逻辑应统一在 Flutter 层实现：**
- 视频列表的分页加载算法在 Flutter 层
- 当前播放项的高亮状态由 Flutter 层 `PlayerController` 驱动
- 视频切换逻辑由 Flutter 层调用 `PlayerController.loadVideo()` 实现
- 原生层仅负责播放器核心能力（播放、暂停、seek 等）

### 颜色系统（来自 project-context.md）

```dart
// 主色调
class AppColors {
  static const Color primary = Color(0xFFE8704D);
  static const Color primaryForeground = Color(0xFFFFFFFF);
}

// 深色主题
class DarkTheme {
  static const Color background = Color(0xFF0A0A0F);  // 视频列表区域背景
  static const Color card = Color(0xFF1A1F2E);
  static const Color border = Color(0xFF2D3548);      // slate-800/30
  static const Color muted = Color(0xFF252B3D);
  static const Color mutedForeground = Color(0xFF7C8591);  // slate-500
}

// 播放器专用色
class PlayerColors {
  static const Color background = Color(0xFF121621);
  static const Color surface = Color(0xFF1E2432);
  static const Color controls = Color(0xFF2D3548);
  static const Color text = Color(0xFFF5F5F5);
  static const Color textMuted = Color(0xFF8B919E);  // slate-400/500
}
```

### 项目结构

```
polyv_media_player/example/lib/
├── player_skin/
│   └── video_list/                    # 新增：视频列表 UI 组件
│       ├── video_list_item.dart       # 视频列表项组件
│       ├── video_list_view.dart       # 视频列表容器组件
│       └── video_list_header.dart     # 列表标题组件
└── pages/
    └── home_page.dart                  # 更新：集成视频列表
```

### 状态管理设计

```dart
// 在 LongVideoPageState 中添加视频列表状态
class _LongVideoPageState extends State<LongVideoPage> {
  // 现有的播放器状态...
  late final PlayerController _controller;

  // 新增：视频列表状态
  final VideoListService _videoListService = MockVideoListService();
  List<VideoItem> _videos = [];
  VideoItem? _currentVideo;
  bool _isLoadingList = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    // 现有初始化...
    _loadVideoList();
  }

  Future<void> _loadVideoList({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }
    // 使用 VideoListService 获取数据
    final response = await _videoListService.fetchVideoList(
      VideoListRequest(page: _currentPage, pageSize: _pageSize),
    );
    setState(() {
      if (refresh) {
        _videos = response.videos;
      } else {
        _videos = [..._videos, ...response.videos];
      }
      _hasMore = response.hasNextPage;
      _isLoadingList = false;
      _isLoadingMore = false;
    });
  }
}
```

### 关键技术决策

| 决策项 | 选择 | 理由 |
|--------|------|------|
| 列表组件 | ListView.builder | 性能优化，支持大量数据 |
| 图片加载 | cached_network_image | 支持缓存和占位符 |
| 分页模式 | 滚动到底部自动加载 | 用户体验更好 |
| 状态同步 | AnimatedBuilder 监听 PlayerController | 自动响应播放器状态变化 |

### 依赖包

```yaml
# 在 polyv_media_player/example/pubspec.yaml 中添加
dependencies:
  cached_network_image: ^3.3.0  # 图片缓存
```

### 已有基础设施复用

- `VideoListService` - 从 Plugin 导入
- `VideoItem`、`VideoListResponse`、`VideoListRequest` - 从 Plugin 导入
- `PlayerController` - 播放器状态管理
- `PlayerColors` - 颜色常量

### 迁移策略

1. 先实现独立的 `VideoListItem` 组件，确保样式正确
2. 实现 `VideoListView` 容器组件，集成滚动和分页
3. 在 `LongVideoPage` 中替换占位区域
4. 连接真实数据源（VideoListService）
5. 实现视频切换逻辑
6. 添加加载状态和错误处理

## References

- `docs/planning-artifacts/epics.md#epic-6-播放列表` - Epic 6 上下文
- `docs/implementation-artifacts/6-2-fetch-video-list.md` - Story 6.2（前置依赖）
- `docs/planning-artifacts/architecture.md#业务逻辑归属原则` - 架构原则
- `docs/project-context.md#12-UI-开发流程-critical` - UI 开发流程
- `/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/LongVideoPage.tsx` - 长视频页面原型
- `/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/VideoListItem.tsx` - 视频列表项原型
- `/Users/nick/projects/polyv/ios/polyv-ios-media-player-sdk-demo/PLViOSMediaPlayerDemo/` - iOS 原生 Demo
- `/Users/nick/projects/polyv/android/polyv-android-media-player-sdk-demo/` - Android 原生 Demo

## Dev Agent Record

### Agent Model Used

opus-4.5-20251101

### Completion Notes List

- 2025-01-19: 初版 Story 文档创建
- 2025-01-24: 实现视频列表 UI 组件开发
  - 创建 VideoListItem 组件，精确还原原型设计（边框高亮、缩略图、播放指示器）
  - 创建 VideoListView 组件，实现滚动列表、分页加载、空状态处理
  - 创建 VideoListHeader 组件，显示"全部视频 · {count}"
  - 集成到 LongVideoPage，添加视频信息区域
  - 实现视频切换逻辑，与 PlayerController 状态同步
  - 所有验收场景已实现

### File List

- `docs/implementation-artifacts/6-3-video-list-display.md` – 本故事文档
- `polyv_media_player/example/lib/player_skin/video_list/video_list_item.dart` – 视频列表项组件
- `polyv_media_player/example/lib/player_skin/video_list/video_list_view.dart` – 视频列表容器组件
- `polyv_media_player/example/lib/player_skin/video_list/video_list_header.dart` – 列表标题组件
- `polyv_media_player/example/lib/pages/home_page.dart` – 集成视频列表（更新 LongVideoPage）

### Story 6.3 验收状态

| 场景 | 状态 |
|------|------|
| 场景 1: UI 完全还原原型 | ✅ 已实现 |
| 场景 2: 当前播放高亮 | ✅ 已实现 |
| 场景 3: 滚动与分页 | ✅ 已实现 |
| 场景 4: 点击切换视频 | ✅ 已实现 |
| 场景 5: 空状态处理 | ✅ 已实现 |
| 场景 6: 播放器状态同步 | ✅ 已实现 |

**Story 6.3 状态: ✅ Review**
