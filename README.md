# Polyv Flutter Media Player Demo

保利威 Flutter 视频播放器插件及 Demo 应用。

## 项目结构

```
.
├── polyv_media_player/   # Flutter 播放器插件（集成到你的项目中）
├── example/              # Demo 应用，演示插件的完整用法
└── docs/                 # 开发文档
```

### polyv_media_player

播放器插件本体，包含核心播放器、UI 组件、弹幕系统、下载管理等。集成到你的项目只需 3 步，详见 [polyv_media_player/README.md](polyv_media_player/README.md)。

### example

基于插件的 Demo 应用，演示了播放器的基本用法、弹幕、下载等功能。运行方式：

```bash
cd example
flutter pub get
flutter run
```

## 文档

- [集成指南 & API 参考](polyv_media_player/README.md)
