# Story 6.4: 切换视频

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

作为最终用户，
我想要在列表中选择其他视频，
以便切换播放内容。

## Acceptance Criteria

### 场景 1: 视频切换基础流程

**Given** 正在播放视频 A
**When** 点击列表中的视频 B
**Then** 停止播放视频 A
**And** 开始加载视频 B
**And** 播放器显示视频 B
**And** 视频列表高亮视频 B

### 场景 2: 播放器状态正确恢复

**Given** 视频切换成功
**When** 新视频加载完成
**Then** 播放器进入准备就绪状态
**And** 自动开始播放新视频（根据 autoPlay 配置）
**And** 清晰度、倍速等设置根据新视频可用选项更新

### 场景 3: UI 状态同步

**Given** 视频列表已显示
**When** 切换到新视频
**Then** 当前播放项的高亮状态立即更新
**And** 视频信息区域（标题、播放量、时长）更新为新视频的信息
**And** 列表滚动到新视频项可见位置

### 场景 4: 切换状态反馈

**Given** 用户点击视频项
**When** 视频正在加载
**Then** 显示加载指示器
**And** 列表项显示加载状态
**When** 视频加载成功
**Then** 隐藏加载指示器
**And** 开始播放新视频

### 场景 5: 错误处理

**Given** 用户点击视频项
**When** 视频加载失败
**Then** 显示错误提示
**And** 保持当前视频继续播放（如果之前有视频在播放）
**And** 记录错误日志

### 场景 6: 防抖机制

**Given** 用户快速连续点击多个视频项
**When** 视频切换正在进行中
**Then** 忽略后续点击请求，直到当前切换完成
**And** 防抖时间约 1 秒（参考 iOS 原生实现）

### 场景 7: 播放进度处理

**Given** 用户正在观看视频 A
**When** 切换到视频 B
**Then** 视频 A 的播放进度被保存（可选：支持断点续播）
**And** 视频 B 从头开始播放（或从上次保存的进度继续）

## Tasks / Subtasks

- [x] 实现视频切换核心逻辑
  - [x] 在 `PlayerController` 中添加 `switchVideo(String vid)` 方法
  - [x] 实现切换前的状态检查（防抖）
  - [x] 实现切换流程：暂停当前 → 加载新视频 → 更新状态
  - [x] 处理切换过程中的加载状态

- [x] 实现 UI 状态同步
  - [x] 更新 `VideoListItem` 的激活状态
  - [x] 更新视频信息区域（标题、播放量、时长）
  - [x] 实现列表滚动到当前项可见位置
  - [x] 添加切换中的视觉反馈

- [x] 实现错误处理
  - [x] 捕获视频加载失败错误
  - [x] 显示用户友好的错误提示
  - [x] 记录错误日志用于调试
  - [x] 实现重试机制

- [x] 实现防抖机制
  - [x] 添加 `_isSwitching` 标志位
  - [x] 实现 1 秒防抖时间
  - [x] 在切换完成后重置标志位

- [x] 测试与验证
  - [x] 单元测试：切换流程逻辑
  - [x] 集成测试：切换后的播放器状态
  - [x] UI 测试：高亮状态更新
  - [x] 错误场景测试：网络错误、无效 vid

## Dev Notes

### Story Context

- 所属 Epic: Epic 6 播放列表
- 前置依赖: Story 6.1（账号配置）、Story 6.2（视频列表 API）、Story 6.3（视频列表展示）
- 后续 Story: 无（Epic 6 最后一个 Story）

### Architecture Compliance

- **UI 组件位置**: `polyv_media_player/example/lib/player_skin/video_list/`
- **业务逻辑**: 在 Demo App 层实现，通过 `PlayerController` 调用原生播放能力
- **状态管理**: 使用 Provider + ChangeNotifier 模式
- **Phase 1 分层**: UI 层在 Demo App，播放核心在 Plugin

### UI 实现参考（CRITICAL）

**必须先读取原型代码再实现！**

| 组件 | 原型文件路径 |
|------|-------------|
| 长视频页面 | `/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/LongVideoPage.tsx` |
| 视频列表项 | `/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/VideoListItem.tsx` |

**原型中的切换逻辑：**
```typescript
// LongVideoPage.tsx
const [currentVideo, setCurrentVideo] = useState(videoList[0]);

// 点击切换视频
<VideoListItem
  key={video.id}
  video={video}
  isActive={currentVideo.id === video.id}
  onClick={() => setCurrentVideo(video)}  // ← 切换逻辑
/>
```

### 原生 Demo 参考逻辑

**iOS Demo:** `/Users/nick/projects/polyv/ios/polyv-ios-media-player-sdk-demo/PLViOSMediaPlayerDemo/`

**关键实现要点：**
```objc
// iOS 原生的视频切换流程
- (void)playWithVid:(NSString *)vid {
    self.vid = vid;
    if ([PLVVodMediaVideo isVideoCached:self.vid]) {
        // 离线缓存优先
        [PLVVodMediaVideo requestVideoPriorityCacheWithVid:self.vid completion:...];
    } else {
        // 在线请求
        [PLVVodMediaVideo requestVideoWithVid:vid completion:...];
    }
}

// 防抖机制
@property (nonatomic, assign) BOOL isSwitchingVideo;  // 防抖标记

- (void)switchToVideo:(NSString *)vid {
    if (self.isSwitchingVideo) return;  // 防抖
    self.isSwitchingVideo = YES;
    // ... 执行切换
    // 1秒后重置防抖标记
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), ...);
}
```

**Android Demo:** `/Users/nick/projects/polyv/android/polyv-android-media-player-sdk-demo/`

**状态机模式参考：**
```kotlin
// Android 使用状态机管理播放器状态
private abstract inner class VideoState {
    open fun onEnter() {}
    open fun nextState(): VideoState = this
    open fun onLeave() {}
}

// 切换视频时重置状态
fun setMediaResource(mediaResource: PLVMediaResource?) {
    if (this.mediaResource === mediaResource) return
    this.mediaResource = mediaResource
    changeToVideoState(InitializedState())
    updateVideoState()
}
```

### 业务逻辑统一原则（IMPORTANT）

**本 Story 的业务逻辑应统一在 Flutter 层实现：**
- 视频切换的决策逻辑在 Flutter 层
- 防抖机制在 Flutter 层实现
- UI 状态同步（高亮、滚动）由 Flutter 层管理
- 原生层仅负责播放器核心能力（加载视频、播放、暂停）

### 颜色系统（来自 project-context.md）

```dart
// 主色调
class AppColors {
  static const Color primary = Color(0xFFE8704D);
  static const Color primaryForeground = Color(0xFFFFFFFF);
}

// 深色主题
class DarkTheme {
  static const Color background = Color(0xFF0A0A0F);
  static const Color card = Color(0xFF1A1F2E);
  static const Color border = Color(0xFF2D3548);
  static const Color mutedForeground = Color(0xFF7C8591);
}

// 播放器专用色
class PlayerColors {
  static const Color background = Color(0xFF121621);
  static const Color surface = Color(0xFF1E2432);
  static const Color controls = Color(0xFF2D3548);
  static const Color text = Color(0xFFF5F5F5);
  static const Color textMuted = Color(0xFF8B919E);
}
```

### 项目结构

```
polyv_media_player/example/lib/
├── player_skin/
│   └── video_list/
│       ├── video_list_item.dart       # 更新：添加切换回调
│       ├── video_list_view.dart       # 更新：处理切换逻辑
│       └── video_list_header.dart     # 无需修改
└── pages/
    └── home_page.dart                 # 更新：集成视频切换
```

### 状态管理设计

```dart
// 在 LongVideoPageState 中添加视频切换状态
class _LongVideoPageState extends State<LongVideoPage> {
  // 现有的播放器状态...
  late final PlayerController _controller;

  // 现有的视频列表状态...
  List<VideoItem> _videos = [];
  VideoItem? _currentVideo;

  // 新增：视频切换状态
  bool _isSwitching = false;           // 防抖标志
  DateTime? _lastSwitchTime;           // 上次切换时间

  /// 切换到指定视频
  Future<void> _switchToVideo(VideoItem video) async {
    // 防抖检查
    if (_isSwitching) {
      debugPrint('Video switch in progress, ignoring request');
      return;
    }

    // 防抖时间检查（1秒）
    if (_lastSwitchTime != null) {
      final elapsed = DateTime.now().difference(_lastSwitchTime!);
      if (elapsed.inMilliseconds < 1000) {
        debugPrint('Debouncing video switch request');
        return;
      }
    }

    // 检查是否是同一个视频
    if (_currentVideo?.vid == video.vid) {
      debugPrint('Already playing video ${video.vid}');
      return;
    }

    setState(() {
      _isSwitching = true;
      _lastSwitchTime = DateTime.now();
    });

    try {
      // 1. 停止当前视频
      await _controller.pause();

      // 2. 加载新视频
      await _controller.loadVideo(video.vid, autoPlay: true);

      // 3. 更新当前视频
      setState(() {
        _currentVideo = video;
      });

      // 4. 滚动列表到新视频项
      _scrollToVideo(video);

      debugPrint('Switched to video: ${video.title}');
    } catch (e) {
      debugPrint('Failed to switch video: $e');
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('视频切换失败：$e')),
        );
      }
    } finally {
      setState(() {
        _isSwitching = false;
      });
    }
  }

  /// 滚动列表到指定视频项
  void _scrollToVideo(VideoItem video) {
    final index = _videos.indexWhere((v) => v.vid == video.vid);
    if (index >= 0) {
      // 滚动到该位置并动画显示
      // _scrollController.animateToItem(...);
    }
  }
}
```

### PlayerController 扩展

```dart
// PlayerController 中可能需要添加的方法
class PlayerController extends ChangeNotifier {
  /// 加载视频
  Future<void> loadVideo(String vid, {bool autoPlay = true}) async {
    try {
      await _methodChannel.invokeMethod('loadVideo', {
        'vid': vid,
        'autoPlay': autoPlay,
      });
    } on PlatformException catch (e) {
      throw PlayerException.fromPlatformException(e);
    }
  }

  /// 暂停播放
  Future<void> pause() async {
    try {
      await _methodChannel.invokeMethod('pause');
    } on PlatformException catch (e) {
      throw PlayerException.fromPlatformException(e);
    }
  }
}
```

### VideoListItem 更新

```dart
// video_list_item.dart 更新
class VideoListItem extends StatelessWidget {
  final VideoItem video;
  final bool isActive;
  final VoidCallback? onTap;          // 新增：点击回调
  final bool isSwitching;             // 新增：切换状态

  const VideoListItem({
    super.key,
    required this.video,
    required this.isActive,
    this.onTap,
    this.isSwitching = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isSwitching ? null : onTap,  // 切换中禁用点击
      child: Container(
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.1)
              : isSwitching
                  ? Colors.transparent
                  : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Opacity(
          opacity: isSwitching && !isActive ? 0.5 : 1.0,  // 切换中半透明
          child: // ... 原有内容
        ),
      ),
    );
  }
}
```

### 关键技术决策

| 决策项 | 选择 | 理由 |
|--------|------|------|
| 防抖实现 | 标志位 + 时间戳 | 参考 iOS 原生实现，简单可靠 |
| 切换状态 | PlayerState 扩展 | 统一状态管理 |
| UI 反馈 | 半透明 + 禁用点击 | 符合 Material Design 规范 |
| 错误处理 | SnackBar 提示 | Flutter 标准方式 |

### 已有基础设施复用

- `PlayerController` - 播放器控制
- `VideoListService` - 视频列表数据服务
- `VideoItem`、`VideoListResponse` - 数据模型
- `VideoListItem`、`VideoListView` - UI 组件
- `PlayerColors` - 颜色常量

### 迁移策略

1. **第一步**：在 `LongVideoPage` 中添加 `_switchToVideo` 方法
2. **第二步**：更新 `VideoListItem` 添加 `onTap` 回调
3. **第三步**：实现防抖机制和加载状态
4. **第四步**：添加错误处理和用户反馈
5. **第五步**：测试各种场景（正常切换、快速点击、错误情况）

### 测试场景

| 场景 | 预期行为 |
|------|----------|
| 正常切换视频 | 停止当前视频 → 加载新视频 → 自动播放 |
| 快速连续点击 | 忽略后续请求，直到当前切换完成 |
| 切换到当前视频 | 不执行任何操作，继续播放 |
| 网络错误 | 显示错误提示，保持当前视频播放 |
| 无效 vid | 显示错误提示，保持当前视频播放 |

### 追踪进度保存（可选功能）

如果需要实现断点续播功能：

```dart
// 使用 SharedPreferences 保存播放进度
class VideoProgressStorage {
  static const String _keyPrefix = 'video_progress_';

  Future<void> saveProgress(String vid, int position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_keyPrefix$vid', position);
  }

  Future<int?> getProgress(String vid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_keyPrefix$vid');
  }
}
```

## References

- `docs/planning-artifacts/epics.md#epic-6-播放列表` - Epic 6 上下文
- `docs/implementation-artifacts/6-2-fetch-video-list.md` - Story 6.2（前置依赖）
- `docs/implementation-artifacts/6-3-video-list-display.md` - Story 6.3（前置依赖）
- `docs/planning-artifacts/architecture.md#业务逻辑归属原则` - 架构原则
- `docs/project-context.md#0-ui-实现强制规则-critical` - UI 开发流程
- `/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/LongVideoPage.tsx` - 长视频页面原型
- `/Users/nick/projects/polyv/ios/polyv-ios-media-player-sdk-demo/PLViOSMediaPlayerDemo/` - iOS 原生 Demo
- `/Users/nick/projects/polyv/android/polyv-android-media-player-sdk-demo/` - Android 原生 Demo

## Dev Agent Record

### Agent Model Used

opus-4.5-20251101

### Completion Notes List

**实现日期**: 2026-01-24

**完成内容**:
1. 视频切换核心逻辑：增强了 `_onVideoTap` 方法，添加防抖检查、错误恢复和状态管理
2. UI 状态同步：添加 `isSwitching` 状态到 `VideoListView` 和 `VideoListItem`，实现切换中的视觉反馈（半透明 + 禁用点击）
3. 错误处理：切换失败时恢复之前的视频并显示 SnackBar 提示
4. 防抖机制：使用 `_isSwitchingVideo` 标志位和 `_lastSwitchTime` 时间戳实现 1 秒防抖

**关键实现文件**:
- `polyv_media_player/example/lib/pages/home_page.dart` - 添加视频切换状态和防抖逻辑
- `polyv_media_player/example/lib/player_skin/video_list/video_list_view.dart` - 添加 `isSwitching` 参数
- `polyv_media_player/example/lib/player_skin/video_list/video_list_item.dart` - 添加切换状态视觉反馈

**测试结果**:
- 添加视频切换状态测试（4 个新测试用例）
- 所有现有测试通过

### File List

**修改的文件**:
- `polyv_media_player/example/lib/pages/home_page.dart` - 添加视频切换状态和防抖逻辑
- `polyv_media_player/example/lib/player_skin/video_list/video_list_view.dart` - 添加 `isSwitching` 参数，暴露 `VideoListViewState` 公共 API
- `polyv_media_player/example/lib/player_skin/video_list/video_list_item.dart` - 添加切换状态视觉反馈

**修改的测试文件**:
- `polyv_media_player/example/test/player_skin/video_list/video_list_view_test.dart` - 添加视频切换状态测试组
- `polyv_media_player/example/test/player_skin/video_list/video_list_item_test.dart` - 添加切换状态禁用点击和半透明测试

**代码审查修复**（2026-01-24）:
1. 添加防抖机制的单元测试覆盖
2. 修复错误恢复逻辑：切换失败时重新加载原视频
3. 修复列表滚动实现：使用类型安全的 `VideoListViewState` 公共 API
4. 统一注释语言为中文
