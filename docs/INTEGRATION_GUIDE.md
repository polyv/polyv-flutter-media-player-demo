# Polyv Media Player 集成指南

本文档介绍 Polyv Media Player 的集成方式。经过优化，现在只需 **3 步** 即可完成基础集成！

---

## 快速开始（3 步集成）

### 步骤 1: 复制 polyv_media_player 目录

将 `polyv_media_player` 目录复制到你的项目中（与你的 `lib/` 目录平级）：

```
你的项目/
├── polyv_media_player/   ← 复制到这里
├── lib/
│   └── main.dart
└── pubspec.yaml
```

或使用 git submodule（推荐，便于获取更新）：

```bash
git submodule add <仓库地址> polyv_media_player
```

### 步骤 2: 添加依赖

修改 `pubspec.yaml`：

```yaml
dependencies:
  flutter:
    sdk: flutter

  polyv_media_player:
    path: polyv_media_player
```

然后执行：

```bash
flutter pub get
```

### 步骤 3: 初始化 SDK

修改 `main.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:polyv_media_player/services/polyv_config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Polyv SDK 账号配置
  await PolyvConfigService().setAccountConfig(
    userId: 'your_user_id',
    secretKey: 'your_secret_key',
    readToken: 'your_read_token',   // 可选
    writeToken: 'your_write_token', // 可选
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: VideoPage(),
    );
  }
}
```

**完成！** 现在你可以使用播放器了。

---

## 使用 PolyvVideoPlayer 组件

### 基础用法（一行代码）

```dart
import 'package:flutter/material.dart';
import 'package:polyv_media_player/polyv_media_player.dart';

class VideoPage extends StatelessWidget {
  const VideoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: PolyvVideoPlayer(
          vid: '475b6884a71c9d41d320071c161ebd9c_4',
          autoPlay: true,
        ),
      ),
    );
  }
}
```

### 完整配置示例

```dart
PolyvVideoPlayer(
  vid: 'your_video_id',
  autoPlay: true,
  showControls: true,              // 显示控制栏
  enableDanmaku: true,             // 启用弹幕
  enableGestures: true,            // 启用手势（滑动 seek）
  enableDoubleTapFullscreen: true, // 启用双击全屏
  isFullscreen: false,             // 是否全屏模式
  showLockButton: false,           // 全屏时显示锁屏按钮
  showDanmakuSend: false,          // 全屏时显示弹幕发送
  showTopBar: false,               // 全屏时显示顶部栏
  videoTitle: '视频标题',           // 全屏顶部栏标题
  aspectRatio: 16 / 9,             // 视频宽高比
  backgroundColor: Colors.black,    // 背景色
  autoHideDuration: const Duration(seconds: 3), // 控制栏自动隐藏时长
  onPlayingChanged: (isPlaying) {
    print('播放状态: $isPlaying');
  },
  onFullscreenChanged: (isFullscreen) {
    print('全屏状态: $isFullscreen');
  },
  onLoaded: () {
    print('视频加载完成');
  },
  onCompleted: () {
    print('播放完成');
  },
  onError: (error) {
    print('播放错误: $error');
  },
)
```

### 使用外部控制器

如果需要外部控制播放器（如播放/暂停、seek 等），可以传入自己的 `PlayerController`：

```dart
class VideoPage extends StatefulWidget {
  const VideoPage({super.key});

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late final PlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PlayerController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PolyvVideoPlayer(
        vid: 'your_video_id',
        controller: _controller, // 外部控制器
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _controller.effectiveIsPlaying
              ? _controller.pause()
              : _controller.play();
        },
        child: Icon(_controller.effectiveIsPlaying
            ? Icons.pause
            : Icons.play_arrow),
      ),
    );
  }
}
```

### 使用弹幕

```dart
PolyvVideoPlayer(
  vid: 'your_video_id',
  enableDanmaku: true,
  danmakuService: myDanmakuService,      // 弹幕数据服务
  danmakuSendService: mySendService,     // 弹幕发送服务（可选）
  onDanmakuSend: (text, color) async {   // 弹幕发送回调（可选）
    // 将弹幕发送到服务器
  },
)
```

---

## 高级用法：自定义 UI 组件

如果需要完全自定义 UI，可以使用 package 内置的 UI 组件：

### 使用内置控制栏

```dart
import 'package:flutter/material.dart';
import 'package:polyv_media_player/polyv_media_player.dart';

class CustomVideoPage extends StatefulWidget {
  const CustomVideoPage({super.key});

  @override
  State<CustomVideoPage> createState() => _CustomVideoPageState();
}

class _CustomVideoPageState extends State<CustomVideoPage> {
  late final PlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PlayerController();
    _controller.loadVideo('your_video_id');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 原生视频视图
          const PolyvVideoView(),

          // 内置控制栏
          Align(
            alignment: Alignment.bottomCenter,
            child: ControlBar(controller: _controller),
          ),
        ],
      ),
    );
  }
}
```

### 可用的内置 UI 组件

| 组件 | 说明 |
|------|------|
| `ControlBar` | 完整控制栏（进度条 + 播放按钮 + 倍速 + 清晰度） |
| `ProgressSlider` | 进度条组件 |
| `QualitySelector` | 清晰度选择器 |
| `SpeedSelector` | 倍速选择器 |
| `SubtitleToggle` | 字幕开关 |
| `DanmakuToggle` | 弹幕开关 |
| `DanmakuLayer` | 弹幕渲染层 |
| `DanmakuInputOverlay` | 弹幕发送输入框 |
| `DanmakuSettings` | 弹幕设置面板 |
| `SettingsMenu` | 设置菜单（清晰度 + 倍速 + 弹幕） |
| `PlayerColors` | 播放器颜色常量 |

### 导入 UI 组件

```dart
// 导入所有（包含 PolyvVideoPlayer、PlayerController、PolyvVideoView）
import 'package:polyv_media_player/polyv_media_player.dart';

// 或单独导入 UI 组件
import 'package:polyv_media_player/ui/control_bar.dart';
import 'package:polyv_media_player/ui/progress_slider/progress_slider.dart';
import 'package:polyv_media_player/ui/quality_selector/quality_selector.dart';
import 'package:polyv_media_player/ui/speed_selector/speed_selector.dart';
import 'package:polyv_media_player/ui/subtitle_toggle.dart';
import 'package:polyv_media_player/ui/player_colors.dart';
import 'package:polyv_media_player/ui/danmaku/danmaku.dart';
import 'package:polyv_media_player/ui/danmaku/danmaku_settings.dart';
import 'package:polyv_media_player/ui/danmaku/danmaku_toggle.dart';
import 'package:polyv_media_player/ui/settings_menu/settings_menu.dart';
```

---

## 项目结构

```
你的项目/
├── polyv_media_player/           ← 与 lib/ 平级
│   ├── lib/
│   │   ├── core/                    # 核心播放器
│   │   │   ├── player_controller.dart
│   │   │   ├── player_state.dart
│   │   │   ├── player_config.dart
│   │   │   └── player_events.dart
│   │   ├── services/                # 服务层
│   │   │   ├── polyv_config_service.dart
│   │   │   ├── player_initializer.dart
│   │   │   ├── video_progress_service.dart
│   │   │   └── subtitle_preference_service.dart
│   │   ├── infrastructure/          # 基础设施
│   │   │   ├── danmaku/              # 弹幕系统
│   │   │   ├── download/             # 下载管理
│   │   │   └── video_list/           # 视频列表
│   │   ├── widgets/                  # 播放器 Widget
│   │   │   ├── polyv_video_player.dart  # 全功能播放器
│   │   │   └── polyv_video_view.dart   # 原生视频视图
│   │   ├── ui/                        # 内置 UI 组件
│   │   │   ├── control_bar.dart
│   │   │   ├── control_bar_state_machine.dart
│   │   │   ├── player_colors.dart
│   │   │   ├── gestures/              # 手势系统
│   │   │   ├── progress_slider/
│   │   │   ├── quality_selector/
│   │   │   ├── speed_selector/
│   │   │   ├── subtitle_toggle.dart
│   │   │   ├── danmaku/               # 弹幕 UI 组件
│   │   │   └── settings_menu/
│   │   └── polyv_media_player.dart    # 主入口
│   ├── android/
│   ├── ios/
│   └── test/
├── lib/
│   └── main.dart
└── pubspec.yaml
```

---

## API 参考

### SDK 初始化

```dart
import 'package:polyv_media_player/services/polyv_config_service.dart';

await PolyvConfigService().setAccountConfig(
  userId: 'your_user_id',
  secretKey: 'your_secret_key',
  readToken: 'your_read_token',   // 可选
  writeToken: 'your_write_token', // 可选
);
```

### PlayerController

| 方法 / 属性 | 说明 |
|------|------|
| `loadVideo(vid, {autoPlay})` | 加载视频 |
| `play()` | 播放 |
| `pause()` | 暂停 |
| `stop()` | 停止 |
| `replay()` | 重播 |
| `seekTo(position)` | 跳转到指定位置（毫秒） |
| `setPlaybackSpeed(speed)` | 设置倍速（0.5 - 2.0） |
| `setQuality(index)` | 切换清晰度 |
| `setSubtitle(index)` | 设置字幕（-1 关闭） |
| `toggleSubtitle()` | 切换字幕开关 |
| `dispose()` | 释放资源 |
| `state` | 当前播放状态 |
| `qualities` | 可用清晰度列表 |
| `availableSubtitles` | 可用字幕列表 |
| `effectiveIsPlaying` | 播放状态（推荐用于 UI） |

### PolyvVideoPlayer

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `vid` | `String` | 必填 | 视频 ID |
| `autoPlay` | `bool` | `true` | 是否自动播放 |
| `showControls` | `bool` | `true` | 是否显示控制栏 |
| `enableDanmaku` | `bool` | `true` | 是否启用弹幕 |
| `enableGestures` | `bool` | `true` | 是否启用手势 |
| `enableDoubleTapFullscreen` | `bool` | `true` | 是否启用双击全屏 |
| `isFullscreen` | `bool` | `false` | 是否全屏模式 |
| `showLockButton` | `bool` | `false` | 全屏时显示锁屏按钮 |
| `showDanmakuSend` | `bool` | `false` | 全屏时显示弹幕发送 |
| `showTopBar` | `bool` | `false` | 全屏时显示顶部栏 |
| `videoTitle` | `String?` | `null` | 全屏顶部栏标题 |
| `aspectRatio` | `double` | `16/9` | 视频宽高比 |
| `backgroundColor` | `Color` | `Colors.black` | 背景色 |
| `autoHideDuration` | `Duration` | `3s` | 控制栏自动隐藏时长 |
| `controller` | `PlayerController?` | `null` | 外部控制器 |
| `danmakuService` | `DanmakuService?` | `null` | 弹幕数据服务 |
| `danmakuSettings` | `DanmakuSettings?` | `null` | 弹幕设置 |
| `danmakuSendService` | `DanmakuSendService?` | `null` | 弹幕发送服务 |
| `onDanmakuSend` | `Function?` | `null` | 弹幕发送回调 |
| `onFullscreenChanged` | `ValueChanged<bool>?` | `null` | 全屏切换回调 |
| `onBack` | `VoidCallback?` | `null` | 返回按钮回调 |
| `onMoreTap` | `VoidCallback?` | `null` | 更多按钮回调 |
| `onLoaded` | `VoidCallback?` | `null` | 加载完成回调 |
| `onPlayingChanged` | `ValueChanged<bool>?` | `null` | 播放状态变化回调 |
| `onCompleted` | `VoidCallback?` | `null` | 播放完成回调 |
| `onError` | `ValueChanged<String>?` | `null` | 错误回调 |

---

## 常见问题

### Q1: Android 编译失败？

确保项目的 Android SDK 版本 >= 21（已在插件中配置）。

### Q2: iOS 编译失败？

1. 确保运行 `pod install`
2. 检查 iOS 最低版本 >= 12.0

### Q3: 视频无法播放？

1. 检查 `userId` 和 `secretKey` 是否正确
2. 确认视频 VID 有效
3. 查看控制台日志

---