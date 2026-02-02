---
project_name: 'polyv-ios-media-player-flutter-demo'
user_name: 'Nick'
date: '2026-01-19'
sections_completed: ['technology_stack', 'critical_rules']
architecture_phase: 'Phase 1'  # Plugin = core only, Demo App = full UI
existing_patterns_found: { number_of_patterns: 15 }
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._


## Architecture Phase: 1

**Plugin (polyv_media_player):** 以播放核心能力为主（PlayerController、PlayerView、Platform Channel），并可在 `lib/infrastructure/` 下托管**可共享的业务服务模块**（例如 Danmaku 相关 Service），但不包含任何 UI。
**Demo App (example/):** 完整 UI 实现（播放器皮肤、控制栏、弹幕、字幕等），通过依赖 Plugin 暴露的核心能力与共享业务服务工作，供客户参考复制

---

## 工作目录

开发 Flutter Plugin 时，**工作目录是 `polyv_media_player/`**：

```
polyv-ios-media-player-flutter-demo/      # Git 仓库根（docs, _bmad）
└── polyv_media_player/                   # ← 开发工作目录（执行 flutter run）
    ├── lib/                              # Plugin 源代码
    ├── example/                          # Demo App
    │   └── lib/
    ├── ios/
    └── android/
```

**重要：** 本文档中所有路径都是相对于 `polyv_media_player/` 目录的。

---

## Technology Stack & Versions

**Framework:**
- Flutter (最新稳定版)
- Dart (与 Flutter SDK 同步)

**Dependencies:**
- `provider: ^6.1.0` - 状态管理

**Native SDKs:**
- iOS: `PolyvMediaPlayerSDK ~> 2.7.2`
- Android: `PolyvMediaPlayerSDK` 对应版本

**Project Type:** Flutter Plugin (封装原生 iOS/Android 播放器 SDK)

## Critical Implementation Rules

### ⚠️ 0. UI 实现强制规则 (CRITICAL - 必读!)

**实现 UI 组件前，必须先读取 React 原型代码！**

这是项目最重要的规则之一。当有 React 原型代码可用时：

1. **第一步**：找到对应的原型文件（参考第 10 节「UI 实现参考」的映射表）
2. **第二步**：使用 `Read` 工具读取原型文件的完整内容
3. **第三步**：分析布局结构、样式细节、颜色、字体、间距
4. **第四步**：然后才开始编写 Flutter 代码

```dart
// ❌ 错误做法：仅凭 Story 中的文字描述猜测 UI
// ❌ 错误做法：凭记忆或经验"假设"原型长什么样

// ✅ 正确做法：
// 1. Read: /Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/XXX.tsx
// 2. 分析原型的精确结构和样式
// 3. 按原型精确还原到 Flutter
```

**为什么这条规则很重要：**
- 原型代码是视觉设计的**唯一真相来源**
- 文字描述无法完整传达颜色、间距、圆角等细节
- 多轮沟通修正浪费大量时间
- 第一次就读取原型代码可以节省 50%+ 的 UI 调整时间

---

### 1. Dart Naming Conventions (STRICT)

| 类型 | 约定 | 示例 | 反例 |
|------|------|------|------|
| Class | PascalCase | `PlayerController` | `playerController` |
| Method/Function | camelCase | `playVideo()`, `seekTo()` | `play_video()` |
| Variable | camelCase | `currentPosition` | `current_position` |
| Private 成员 | 前缀下划线 | `_nativeChannel` | `nativeChannel` (私有) |
| File | snake_case | `player_controller.dart` | `PlayerController.dart` |
| Directory | snake_case | `player_skin/` | `PlayerSkin/` |

### 2. Platform Channel Naming (CRITICAL)

**Channel 名称:** snake_case 格式
```
com.polyv.media_player/player
com.polyv.media_player/events
```

**Method 名称:** camelCase 格式
```
playVideo, setPlaySpeed, seekToPosition
```

**Event 类型:** camelCase 格式
```
stateChanged, progressUpdate, errorOccurred
```

**Error Code:** UPPER_SNAKE_CASE
```
INVALID_VID, NETWORK_ERROR, UNSUPPORTED_OPERATION
```

### 3. Provider State Management Pattern

**必须使用 ChangeNotifier 模式：**

```dart
class PlayerController extends ChangeNotifier {
  // 状态变更时必须调用 notifyListeners()
  void _updateState(PlayerState newState) {
    _state = newState;
    notifyListeners();
  }
}
```

**Widget 中使用 Consumer 模式：**

```dart
Consumer<PlayerController>(
  builder: (context, controller, child) {
    return Text('${controller.state.position}');
  },
)
```

### 4. Platform Channel 数据格式

**方法调用参数：统一使用 Map**

```dart
await _channel.invokeMethod('playVideo', {
  'vid': 'e8888b0d3',
  'autoPlay': true,
});
```

**事件数据格式：**

```dart
{
  'type': 'stateChanged',
  'data': {
    'state': 'playing',  // idle, playing, paused, buffering, completed
    'position': 30000,   // 毫秒
    'duration': 180000,
  }
}
```

### 5. 错误处理模式 (REQUIRED)

**所有 Platform Channel 调用必须捕获 PlatformException：**

```dart
try {
  await _channel.invokeMethod('playVideo', {'vid': vid});
} on PlatformException catch (e) {
  throw PlayerException(
    code: e.code ?? 'UNKNOWN_ERROR',
    message: e.message ?? 'An error occurred',
  );
}
```

### 6. 文件组织规则 (Phase 1)

**Plugin 结构（只含播放核心能力）：**

```
lib/
├── polyv_media_player.dart   # 主入口，导出公共 API
├── core/                      # 核心层
│   ├── player_controller.dart
│   ├── player_state.dart
│   └── player_events.dart
├── platform_channel/          # Platform Channel 封装
└── utils/                     # 工具类
```

**Demo App 结构（完整 UI 实现）：**

```
example/lib/
├── main.dart                  # 示例应用入口
├── player_skin/               # 播放器皮肤
│   ├── player_skin.dart
│   ├── control_bar.dart
│   ├── progress_slider.dart
│   └── top_bar.dart
├── danmu/                     # 弹幕模块
├── subtitle/                  # 字幕模块
└── gestures/                  # 手势处理
```

**测试文件与源文件同目录：**
```
lib/core/player_controller.dart
lib/core/player_controller_test.dart
```

### 7. 禁止模式 (ANTI-PATTERNS)

❌ **不要直接在 UI Widget 中调用 Platform Channel**
```dart
// 错误示例
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _channel.invokeMethod('play'); // ❌ 不要这样做
  }
}
```

✅ **正确方式：通过 PlayerController**
```dart
Consumer<PlayerController>(
  builder: (context, controller, child) {
    return ElevatedButton(
      onPressed: () => controller.play(),
    );
  },
)
```

❌ **不要混合命名风格**
```dart
class player_controller { ... }  // ❌ 应该用 PascalCase
Future<void> play_video() async { }  // ❌ 应该用 camelCase
```

❌ **不要忽略 PlatformException**
```dart
await _channel.invokeMethod('play');  // ❌ 没有错误处理
```

### 8. 项目结构关键边界 (Phase 1+ 实际实现)

| 边界 | 规则 |
|------|------|
| **Plugin Public API** | 只有 `lib/polyv_media_player.dart` 导出的类和方法对外可见（PlayerController、PlayerView、以及显式导出的业务 Service 等） |
| **Platform Channel** | 只有 `platform_channel/` 目录中的代码可以直接调用 Native |
| **Plugin vs Demo** | Plugin 只含播放核心能力 + 可选共享业务服务模块（无 UI）；Demo App (example/) 包含完整 UI 实现，供客户参考复制 |
| **UI Components** | Demo App 中的 UI 组件通过 PlayerController 获取状态，不直接调用 Platform Channel |

**业务逻辑归属规则（IMPORTANT）：**

- **原生层（ios/、android/）只负责播放器 SDK 封装，不负责业务 HTTP / Repo：**
  - 不要在 `ios/Classes/` 或 `android/src/main/` 中新增与账号绑定的视频列表、历史弹幕、下载任务等业务数据获取逻辑；这些逻辑应统一在 Dart 层实现。
  - 原生可以暴露“底层能力”（如当前播放时间、下载任务状态回调），但不得在原生层直接调 Polyv 业务 HTTP 接口并在那一层做业务决策。
- **跨端共享的业务逻辑必须在 Flutter(Dart) 层统一实现：**
  - 历史弹幕获取：由 Dart 层的 `DanmakuService` / `DanmakuRepository`（命名示意）通过 Polyv 弹幕 API 拉取，并转换为统一的 `Danmaku` 模型供 UI 使用。
  - 播放列表：由 Dart 层的 `PlaylistService` 通过账号配置拉取视频列表，再驱动 Demo App / 客户 App 的 UI；原生只暴露播放器播放某个 vid 的能力。
  - 下载中心：由 Dart 层维护下载任务列表和业务状态（排队、暂停、失败、重试等），原生只负责具体下载执行和进度回调。
- **如果确需复用原生 SDK 提供的业务模块（例如 iOS 的 `PLVMediaPlayerDanmuModule requestDanmusWithVid`）：**
  - 必须通过单一的 Platform Channel 方法在 Dart 层统一封装（如 `fetchDanmakusFromSdk(vid)`），而不是在 iOS 和 Android 各自写一套业务逻辑。
  - 每增加一条此类“原生业务能力”的依赖，必须同步更新 `architecture.md` 和本文件，说明设计意图和跨端等价策略。

**清晰度切换职责边界（QUALITY SWITCHING RESPONSIBILITY）：**

- 清晰度切换后的**进度与播放状态恢复逻辑只能在原生层实现**，属于播放器 SDK 能力的一部分：
  - Android/iOS 负责：在 `handleSetQuality` 中记录当前播放位置和是否正在播放，完成清晰度切换后负责 `seek` 与 `play` 的恢复。
  - Dart 层 `PlayerController.setQuality` 只负责：
    - 校验清晰度索引；
    - 通过 `MethodChannelHandler.setQuality` 触发原生方法；
    - 消费 `qualityChanged` 事件并更新本地状态。
- 禁止在 Dart 层再次实现“清晰度切换后恢复进度/播放状态”的逻辑，以避免与原生实现产生冲突或双重 seek/play。

**Danmaku 业务服务使用规则（DANMAKU BUSINESS SERVICES）：**

- 插件已经在 `lib/infrastructure/danmaku/` 下提供了统一的：
  - `Danmaku`/`ActiveDanmaku` 等模型；
  - `DanmakuService` / `DanmakuSendService` 接口；
  - `MockDanmakuService` / `HttpDanmakuService`、`MockDanmakuSendService` / `HttpDanmakuSendService` 等实现。
- Demo App 不应再在 `example/lib/player_skin/danmaku/` 下实现另一套 Danmaku 业务逻辑，而应通过：
  - `package:polyv_media_player/infrastructure/danmaku/danmaku_model.dart`
  - `package:polyv_media_player/infrastructure/danmaku/danmaku_service.dart`
  导入并复用插件提供的 Service，仅在 Demo 侧实现 UI（弹幕层、输入框、开关等）。
- 未来如新增 Playlist / 下载业务 Service，优先放置在 Plugin 的 `infrastructure/` 或专门的 `business/` 目录，并遵循同样的“Plugin 提供共享 Service，Demo 只负责 UI”的模式。

### 9. 原生依赖配置

**iOS (polyv_media_player.podspec):**
```ruby
s.dependency 'PolyvMediaPlayerSDK', '~> 2.7.2'
```

**Android (build.gradle):**
```groovy
implementation 'com.polyv:polyv-media-player-sdk:x.y.z'
```

### 10. UI 实现参考 (CRITICAL)

**HTML 原型是 UI 实现的标准参考：**

| 项目 | 路径 |
|------|------|
| **HTML 原型** | `/Users/nick/projects/polyv/ios/polyv-vod/` |

**实现 UI 组件时必须参考原型的：**
- **视觉设计：** 颜色（primary、背景色）、字体大小、间距、圆角
- **布局结构：** 组件位置、层级关系、响应式布局
- **交互状态：** 播放/暂停按钮切换、弹幕开关、全屏状态等
- **动画效果：** 进度条动画、弹幕滚动、页面过渡

**关键参考文件：**
```
/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/
├── LongVideoPage.tsx       # 长视频页面布局
├── DownloadCenterPage.tsx  # 下载中心页面
└── VideoPlayer.tsx         # 播放器组件（所有控件）

/Users/nick/projects/polyv/ios/polyv-vod/src/components/player/
├── PlayerProgress.tsx      # 进度条组件
├── QualitySelector.tsx     # 清晰度选择器
├── SpeedSelector.tsx       # 倍速选择器
├── VolumeControl.tsx       # 音量控制
├── DanmakuLayer.tsx        # 弹幕层
├── DanmakuToggle.tsx       # 弹幕开关
├── SubtitleToggle.tsx      # 字幕开关
└── Playlist.tsx            # 播放列表
```

**移动端适配注意事项：**
- 原型是 Web 版，移动端需要适配手势（单击、双击、滑动）
- 移动端无键盘快捷键功能
- 横竖屏切换需要特殊处理

### 11. 开发工具使用规范

**写代码 vs 使用 MCP 工具：**

| 任务类型 | 使用的工具 | 说明 |
|---------|-----------|------|
| **写代码** | `Read` / `Edit` / `Write` | 直接文件操作，不需要 MCP |
| **运行测试** | `mcp__dart__run_tests` | MCP（优于 `flutter test`） |
| **代码分析** | `mcp__dart__analyze_files` | MCP（优于 `flutter analyze`） |
| **格式化** | `mcp__dart__dart_format` | MCP（优于 `dart format .`） |
| **依赖管理** | `mcp__dart__pub` | MCP（get/add/remove/upgrade） |
| **Hot Reload** | `mcp__dart__hot_reload` | MCP（需先连接 DTD） |
| **获取运行时错误** | `mcp__dart__get_runtime_errors` | MCP（调试用） |
| **获取 Widget 树** | `mcp__dart__get_widget_tree` | MCP（调试用） |
| **LSP 查询** | `mcp__dart__hover` / `mcp__dart__signature_help` | MCP（获取类型/签名信息） |

**MCP 工具分类：**

1. **执行类任务**（替代 bash 命令）
   - `run_tests` - 运行测试，提供 agent-centric UX
   - `analyze_files` - 分析整个项目错误
   - `dart_format` - 格式化代码
   - `dart_fix` - 应用自动修复
   - `pub` - 依赖管理

2. **调试类任务**（需先连接 DTD）
   - `hot_reload` - 热重载
   - `get_runtime_errors` - 获取运行时错误
   - `get_widget_tree` - 获取 Flutter widget 树
   - `get_selected_widget` - 获取选中的 widget

3. **LSP 查询**（代码理解）
   - `hover` - 获取类型/文档信息
   - `signature_help` - 获取函数签名
   - `resolve_workspace_symbol` - 搜索符号定义

**使用 MCP 的原因：**
- 提供更好的错误解析和输出格式
- 与 LLM 上下文深度集成，结果可直接用于代码生成
- agent-centric UX，更适合 AI 协作开发

### 12. UI 开发流程 (CRITICAL)

**开发 UI 组件时，必须按以下步骤执行：**

**Step 1: 读取 HTML 原型代码**

在开始编写 Flutter 代码前，先读取对应的 HTML/TSX 原型文件：

```dart
// 1. 确定要实现的页面/组件
// 2. 找到对应的原型文件路径（见下方映射表）
// 3. 使用 Read 工具读取原型文件
// 4. 分析：布局结构、元素列表、样式细节
```

**Step 2: 分析原型结构**

从原型代码中提取：
- **布局结构**：Row/Column/Stack 的嵌套关系
- **元素列表**：所有子组件（图标、文字、按钮等）
- **位置信息**：padding、margin、alignment
- **样式细节**：颜色、字体大小、圆角、阴影

**Step 3: 使用设计规范**

使用第 12.1-12.6 节中的颜色、字体、间距、图标常量

**Step 4: 编写 Flutter 代码**

按原型结构精确还原

---

**页面 → 原型文件映射表：**

| Flutter 页面 | HTML 原型文件 | 路径 |
|-------------|--------------|------|
| `HomePage` | `Index.tsx` | `/Users/nick/projects/polyv/ios/polyv-vod/src/pages/Index.tsx` |
| `LongVideoPage` | `LongVideoPage.tsx` | `/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/LongVideoPage.tsx` |
| `DownloadCenterPage` | `DownloadCenterPage.tsx` | `/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/DownloadCenterPage.tsx` |
| `VideoPlayer` | `DemoVideoPlayer.tsx` | `/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/DemoVideoPlayer.tsx` |
| `PlayerProgress` | `PlayerProgress.tsx` | `/Users/nick/projects/polyv/ios/polyv-vod/src/components/player/PlayerProgress.tsx` |
| `QualitySelector` | `QualitySelector.tsx` | `/Users/nick/projects/polyv/ios/polyv-vod/src/components/player/QualitySelector.tsx` |
| `SpeedSelector` | `SpeedSelector.tsx` | `/Users/nick/projects/polyv/ios/polyv-vod/src/components/player/SpeedSelector.tsx` |
| `DanmakuLayer` | `DanmakuLayer.tsx` | `/Users/nick/projects/polyv/ios/polyv-vod/src/components/player/DanmakuLayer.tsx` |
| `SubtitleToggle` | `SubtitleToggle.tsx` | `/Users/nick/projects/polyv/ios/polyv-vod/src/components/player/SubtitleToggle.tsx` |

**开发示例：**

```dart
// 任务：实现 LongVideoPage

// 1. 先读取原型
Read: /Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/LongVideoPage.tsx

// 2. 分析结构
// - 外层：div (min-h-screen, flex, column) → Column
// - Header：返回按钮 + 标题 + 分享按钮 → Row
// - Player：视频播放器区域 → AspectRatio(16:9)
// - VideoInfo：标题 + 播放次数 + 时长 → Row/Column
// - VideoList：视频列表 → ListView.builder

// 3. 使用设计规范中的颜色/字体/间距

// 4. 编写代码...
```

---

### 12.1 UI 设计规范

**设计规范文档位置：**
```
/Users/nick/projects/polyv/ios/polyv-vod/docs/flutter-design-spec.md
/Users/nick/projects/polyv/ios/polyv-vod/docs/flutter-assets-guide.md
```

**12.1 颜色系统**

```dart
// 主色调 - 珊瑚橙
class AppColors {
  static const Color primary = Color(0xFFE8704D);
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFF4DB3A8);          // 青绿色
  static const Color destructive = Color(0xFFEF4444);      // 错误色
}

// 播放器专用色
class PlayerColors {
  static const Color background = Color(0xFF121621);       // 最深层
  static const Color surface = Color(0xFF1E2432);          // 面板/弹窗
  static const Color controls = Color(0xFF2D3548);         // 控件背景
  static const Color progress = Color(0xFFE8704D);         // 已播放
  static const Color progressBuffer = Color(0xFF3D4560);   // 缓冲
  static const Color text = Color(0xFFF5F5F5);             // 主文字
  static const Color textMuted = Color(0xFF8B919E);        // 次要文字
}

// 深色主题
class DarkTheme {
  static const Color background = Color(0xFF121621);
  static const Color foreground = Color(0xFFF5F5F5);
  static const Color card = Color(0xFF1A1F2E);
  static const Color border = Color(0xFF2D3548);
  static const Color muted = Color(0xFF252B3D);
  static const Color mutedForeground = Color(0xFF7C8591);
}

// Tailwind Slate 色值（首页使用）
class SlateColors {
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate600 = Color(0xFF475569);
}
```

**12.2 字体排版**

```dart
class TextStyles {
  static const TextStyle h1 = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3);
  static const TextStyle h2 = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.35);
  static const TextStyle h3 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);
  static const TextStyle bodyLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static const TextStyle body = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static const TextStyle bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4);
  static const TextStyle caption = TextStyle(fontSize: 11, fontWeight: FontWeight.w400, height: 1.3);
}
```

**12.3 间距系统**

```dart
class Spacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

class Radii {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 20.0;
  static const double full = 9999.0;
}
```

**12.4 图标映射 (Lucide → Material)**

| 功能 | Web (Lucide) | Flutter (Material) |
|------|--------------|-------------------|
| 播放 | `Play` | `Icons.play_arrow_rounded` |
| 暂停 | `Pause` | `Icons.pause_rounded` |
| 全屏 | `Maximize2` | `Icons.fullscreen` |
| 退出全屏 | `Minimize2` | `Icons.fullscreen_exit` |
| 返回 | `ChevronLeft` | `Icons.chevron_left` / `Icons.arrow_back` |
| 更多 | `MoreVertical` | `Icons.more_vert` |
| 锁定 | `Lock` | `Icons.lock` |
| 解锁 | `Unlock` | `Icons.lock_open` |
| 弹幕 | `MessageSquare` | `Icons.chat_bubble_outline` |
| 字幕 | `Subtitles` | `Icons.subtitles` |
| 快退10s | `RotateCcw` | `Icons.replay_10` |
| 快进10s | `RotateCw` | `Icons.forward_10` |
| 音量 | `Volume2` | `Icons.volume_up` |
| 静音 | `VolumeX` | `Icons.volume_off` |
| 亮度 | `Sun` | `Icons.brightness_6` |
| 分享 | `Share2` | `Icons.share` |
| 下载 | `Download` | `Icons.download_rounded` |
| 勾选 | `Check` | `Icons.check` |
| 右箭头 | `ChevronRight` | `Icons.chevron_right_rounded` |

**12.5 动画规范**

```dart
class AnimCurves {
  static const Curve standard = Curves.easeOutCubic;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
}

class AnimDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
}
```

**12.6 阴影规范**

```dart
class AppShadows {
  static const BoxShadow sm = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );
  static const BoxShadow md = BoxShadow(
    color: Color(0x26000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );
  static const BoxShadow lg = BoxShadow(
    color: Color(0x33000000),
    blurRadius: 20,
    offset: Offset(0, 10),
  );
}
```

**12.7 推荐依赖包**

```yaml
dependencies:
  # UI 相关
  google_fonts: ^6.1.0
  lucide_icons: ^0.257.0
  flutter_svg: ^2.0.9

  # 弹幕功能
  flutter_danmaku: ^0.1.0

  # 手势和动画
  flutter_animate: ^4.3.0
```

### 13. 代码规范

**代码分析：**
- 使用 MCP `mcp__dart__analyze_files` 确保无警告
- 使用 MCP `mcp__dart__dart_format` 格式化代码

**导入顺序：**
1. Dart SDK
2. Flutter SDK
3. Package 依赖
4. 项目内部文件 (使用相对路径)
