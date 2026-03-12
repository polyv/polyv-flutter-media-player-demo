# Polyv Media Player 集成指南

本文档介绍 Polyv Media Player 的集成方式。经过优化，现在只需 **3 步** 即可完成基础集成！

---

## 快速开始（3 步集成）

### 步骤 1: 复制 polyv_media_player 目录

```bash
# 在你的项目根目录执行
mkdir -p packages
cp -r <开源仓库路径>/polyv_media_player packages/polyv_media_player
```

或使用 git submodule（推荐，便于获取更新）：

```bash
git submodule add <仓库地址> packages/polyv_media_player
```

### 步骤 2: 添加依赖

修改 `pubspec.yaml`：

```yaml
dependencies:
  flutter:
    sdk: flutter

  polyv_media_player:
    path: packages/polyv_media_player
```

然后执行：

```bash
flutter pub get
```

### 步骤 3: 初始化 SDK

修改 `main.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:polyv_media_player/polyv_media_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PolyvMediaPlayer.initialize(
    userId: 'your_user_id',
    secretKey: 'your_secret_key',
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
  showControls: true,           // 显示控制栏
  showQualitySelector: true,    // 显示清晰度选择器
  showSpeedSelector: true,      // 显示倍速选择器
  aspectRatio: 16 / 9,          // 视频宽高比
  backgroundColor: Colors.black, // 背景色
  onLoaded: () {
    print('视频加载完成');
  },
  onPlayingChanged: (isPlaying) {
    print('播放状态: $isPlaying');
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
          // 外部控制
          _controller.isPlaying ? _controller.pause() : _controller.play();
        },
        child: Icon(_controller.isPlaying ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}
```

---

## 高级用法：自定义 UI 组件

如果需要完全自定义 UI，可以使用 package 内置的 UI 组件：

### 使用内置控制栏

```dart
import 'package:flutter/material.dart';
import 'package:polyv_media_player/polyv_media_player.dart';
import 'package:polyv_media_player/ui/control_bar.dart';

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
| `PlayerColors` | 播放器颜色常量 |

### 导入 UI 组件

```dart
// 导入所有 UI 组件
import 'package:polyv_media_player/polyv_media_player.dart';

// 或单独导入
import 'package:polyv_media_player/ui/control_bar.dart';
import 'package:polyv_media_player/ui/progress_slider/progress_slider.dart';
import 'package:polyv_media_player/ui/quality_selector/quality_selector.dart';
import 'package:polyv_media_player/ui/speed_selector/speed_selector.dart';
import 'package:polyv_media_player/ui/subtitle_toggle.dart';
import 'package:polyv_media_player/ui/player_colors.dart';
```

---

## 项目结构

```
你的项目/
├── packages/
│   └── polyv_media_player/
│       ├── lib/
│       │   ├── core/                    # 核心播放器
│       │   ├── services/                # 服务层
│       │   ├── infrastructure/          # 基础设施（弹幕、下载等）
│       │   ├── widgets/                 # 播放器 Widget
│       │   │   ├── polyv_video_view.dart
│       │   │   └── polyv_video_player.dart
│       │   ├── ui/                      # 内置 UI 组件 ✨
│       │   │   ├── control_bar.dart
│       │   │   ├── player_colors.dart
│       │   │   ├── progress_slider/
│       │   │   ├── quality_selector/
│       │   │   ├── speed_selector/
│       │   │   └── subtitle_toggle.dart
│       │   └── polyv_media_player.dart
│       ├── android/
│       ├── ios/
│       └── example/                     # 完整示例 App
├── lib/
│   └── main.dart
└── pubspec.yaml
```

---

## API 参考

### PolyvMediaPlayer

| 方法 | 说明 |
|------|------|
| `initialize(userId, secretKey)` | 初始化 SDK（必须在 main() 中调用） |
| `isInitialized` | 检查 SDK 是否已初始化 |
| `userId` | 获取当前配置的用户 ID |

### PolyvVideoPlayer

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `vid` | `String` | 必填 | 视频 ID |
| `autoPlay` | `bool` | `true` | 是否自动播放 |
| `showControls` | `bool` | `true` | 是否显示控制栏 |
| `showQualitySelector` | `bool` | `true` | 是否显示清晰度选择器 |
| `showSpeedSelector` | `bool` | `true` | 是否显示倍速选择器 |
| `aspectRatio` | `double` | `16/9` | 视频宽高比 |
| `backgroundColor` | `Color` | `Colors.black` | 背景色 |
| `controller` | `PlayerController?` | `null` | 外部控制器 |
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

### Q4: 如何更新到最新版本？

```bash
# 使用 git submodule 的项目
git submodule update --remote packages/polyv_media_player

# 直接复制的项目
rm -rf packages/polyv_media_player
cp -r <新版本路径>/polyv_media_player packages/
```

---

## 从旧版本迁移

如果你的项目使用旧的集成方式（需要手动复制 UI 代码），现在可以简化：

### 迁移步骤

1. 更新 `polyv_media_player` 到最新版本
2. 删除项目中手动复制的 `player_skin/` 目录
3. 将导入路径从本地改为 package 内置：

```dart
// 旧代码
import 'player_skin/control_bar.dart';

// 新代码
import 'package:polyv_media_player/ui/control_bar.dart';
```

4. 或直接使用 `PolyvVideoPlayer` 组件替代手动组装

---

## 获取帮助

- GitHub Issues: https://github.com/polyv/polyv-flutter-media-player/issues
- 文档: https://polyv.github.io/polyv-flutter-media-player
