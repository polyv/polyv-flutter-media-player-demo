---
stepsCompleted: ['step-01-validate-prerequisites', 'step-02-design-epics', 'step-03-create-stories', 'step-04-final-validation']
inputDocuments: ['prd.md', 'architecture.md']
workflowType: 'epics'
project: 'polyv-ios-media-player-flutter-demo'
user_name: 'Nick'
date: '2026-01-19'
status: 'complete'
---

# polyv-ios-media-player-flutter-demo - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for polyv-ios-media-player-flutter-demo, decomposing the requirements from the PRD and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

FR1: 播放控制 - 播放/暂停/停止 (P0)
FR2: 播放控制 - seek拖动进度条 (P0)
FR3: 进度显示 - 当前时间/总时长 (P0)
FR4: 进度显示 - 缓冲进度显示 (P1)
FR5: 清晰度切换 - 切换视频清晰度 (1080p/720p/480p/360p) (P0)
FR6: 倍速播放 - 0.5x/1.0x/1.25x/1.5x/2.0x (P0)
FR7: 音量控制 - 音量调节/静音 (P0)
FR8: 弹幕 - 弹幕显示开关 (P0)
FR9: 弹幕 - 弹幕透明度调节 (P1)
FR10: 弹幕 - 弹幕字号切换 (小/中/大) (P1)
FR11: 弹幕 - 发送弹幕 (P0)
FR12: 字幕 - 字幕开关 (P0)
FR13: 字幕 - 多语言字幕 (P1)
FR14: 播放列表 - 视频列表展示 (P0)
FR15: 播放列表 - 切换视频 (P0)
FR16: 全屏 - 全屏切换 (竖屏/横屏) (P0)
FR17: 手势 - 单击暂停/播放 (P1)
FR18: 手势 - 双击全屏 (P1)
FR19: 手势 - 左右滑动 seek (P1)
FR20: 手势 - 上下滑动音量 (P1)
FR21: 分享 - 社交分享 (P1)
FR22: 首页入口 - 两个入口按钮（长视频、下载中心） (P0)
FR23: 下载中心 - Tab 切换（下载中/已完成） (P0)
FR24: 下载中心 - 下载进度显示 (P0)
FR25: 下载中心 - 暂停/继续下载 (P0)
FR26: 下载中心 - 重试失败下载 (P1)
FR27: 下载中心 - 删除下载任务 (P0)
FR28: 下载中心 - 下载速度显示 (P1)
FR29: 下载中心 - 空状态处理 (P1)
FR30: 触发下载 - 视频列表下载按钮 (P0)

### NonFunctional Requirements

NFR1: 性能 - 视频启动时间 < 3 秒
NFR2: 性能 - 播放控制响应 < 200ms
NFR3: 性能 - UI 流畅度 60fps
NFR4: 兼容性 - iOS 13.0+
NFR5: 兼容性 - Android 5.0+ (待确认)
NFR6: 兼容性 - Flutter 最新稳定版
NFR7: 可维护性 - 遵循 Flutter 官方代码风格指南
NFR8: 可维护性 - 关键类和方法有文档注释
NFR9: 可扩展性 - 支持添加新控制按钮、自定义皮肤主题

### Additional Requirements

**技术架构需求：**
- 使用 Flutter 官方 Plugin 模板初始化项目（Epic 1 Story 1）
- 状态管理使用 Provider ^6.1.0 (ChangeNotifier 模式)
- Platform Channel 使用 MethodChannel + EventChannel 组合
- 错误处理使用 PlatformException 封装
- Phase 1 分层设计：Plugin 只含播放核心能力，Demo App 含完整 UI

**项目结构需求：**
```
Plugin 层:
- lib/core/player_controller.dart - 播放器控制器
- lib/core/player_state.dart - 播放器状态
- lib/platform_channel/ - Platform Channel 封装

Demo App 层:
- player_skin/ - 播放器皮肤
- control_bar/ - 控制栏
- progress_slider/ - 进度条
- danmu/ - 弹幕模块
- subtitle/ - 字幕模块
- gestures/ - 手势处理
```

**原生 SDK 集成需求：**
- iOS: PolyvMediaPlayerSDK ~> 2.7.2
- Android: 对应版本 (待确认)

**Platform Channel API 需求：**

方法调用:
- playVideo({vid: String})
- pause()
- seek({position: int}) // 毫秒
- setPlaySpeed({speed: double})
- getQualities()
- setSubtitle({enabled: bool})

事件:
- stateChanged (idle, playing, paused, buffering, completed)
- progress (position, duration, bufferedPosition)
- error (code, message)

### FR Coverage Map

| FR | Epic | 描述 |
|----|------|------|
| FR22 | Epic 0 | 首页入口按钮（长视频、下载中心） |
| FR1 | Epic 1 | 播放/暂停/停止 |
| FR2 | Epic 2 | seek 拖动进度条 |
| FR3 | Epic 2 | 当前时间/总时长 |
| FR4 | Epic 2 | 缓冲进度显示 |
| FR5 | Epic 3 | 清晰度切换 |
| FR6 | Epic 3 | 倍速播放 |
| FR7 | Epic 3 | 音量控制 |
| FR8 | Epic 4 | 弹幕显示开关 |
| FR9 | Epic 4 | 弹幕透明度调节 |
| FR10 | Epic 4 | 弹幕字号切换 |
| FR11 | Epic 4 | 发送弹幕 |
| FR12 | Epic 5 | 字幕开关 |
| FR13 | Epic 5 | 多语言字幕 |
| FR14 | Epic 6 | 视频列表展示 |
| FR15 | Epic 6 | 切换视频 |
| FR30 | Epic 6 | 触发下载任务 |
| FR16 | Epic 7 | 全屏切换 |
| FR17 | Epic 7 | 单击暂停/播放 |
| FR18 | Epic 7 | 双击全屏 |
| FR19 | Epic 7 | 左右滑动 seek |
| FR20 | Epic 7 | 上下滑动音量 |
| FR21 | Epic 8 | 社交分享 |
| FR23-29 | Epic 9 | 下载中心功能（Tab/进度/暂停/重试/删除/速度/空状态） |
| 全部 | Epic 10 | Android 平台实现 |

## Epic List

### Epic 0: 首页与导航框架
**用户价值：** 用户打开 App 后可以看到主要功能入口并快速导航
**FRs 覆盖：** FR22
**技术说明：** 首页 UI、两个入口按钮（长视频、下载中心）、页面路由导航

### Epic 1: 项目初始化与基础播放
**用户价值：** Flutter 开发者能够初始化项目并播放第一个视频
**FRs 覆盖：** FR1
**技术说明：** Plugin 项目初始化、Platform Channel 封装、iOS 原生实现

### Epic 2: 播放进度与时间显示
**用户价值：** 用户可以查看播放进度并拖动跳转
**FRs 覆盖：** FR2, FR3, FR4
**技术说明：** 进度条组件、时间显示、状态同步机制

### Epic 3: 播放增强功能
**用户价值：** 用户可以控制视频清晰度、倍速和音量
**FRs 覆盖：** FR5, FR6, FR7
**技术说明：** 清晰度选择器、倍速选择器、音量控制组件

### Epic 4: 弹幕功能
**用户价值：** 用户可以看到和发送弹幕
**FRs 覆盖：** FR8, FR9, FR10, FR11
**技术说明：** 弹幕层、弹幕输入框、弹幕设置面板

### Epic 5: 字幕功能
**用户价值：** 用户可以开关字幕并切换多语言
**FRs 覆盖：** FR12, FR13
**技术说明：** 字幕显示层、字幕选择器

### Epic 6: 播放列表
**用户价值：** 用户可以浏览视频列表并切换视频
**FRs 覆盖：** FR14, FR15, FR30
**技术说明：** 播放列表组件、视频切换逻辑、下载触发

### Epic 7: 高级交互功能
**用户价值：** 用户可以通过手势和全屏模式获得更好的体验
**FRs 覆盖：** FR16, FR17, FR18, FR19, FR20
**技术说明：** 手势检测、全屏切换、横竖屏适配

### Epic 8: 分享功能
**用户价值：** 用户可以分享视频
**FRs 覆盖：** FR21
**技术说明：** 分享面板、社交平台集成

### Epic 9: 下载中心
**用户价值：** 用户可以管理和查看下载中的视频
**FRs 覆盖：** FR23, FR24, FR25, FR26, FR27, FR28, FR29
**技术说明：** 下载管理组件、进度显示、状态管理

### Epic 10: Android 平台支持
**用户价值：** Flutter 开发者可以在 Android 平台使用相同的播放器
**FRs 覆盖：** 所有 FR (Android 实现)
**技术说明：** Android 原生实现，与 iOS 功能对等

---

## Epic 0: 首页与导航框架

**Epic Goal:** 用户打开 App 后可以看到主要功能入口并快速导航到长视频或下载中心

### Story 0.1: 首页入口按钮

作为最终用户，
我想要看到两个清晰的入口按钮（长视频、下载中心），
以便快速访问所需功能。

**验收标准：**

**Given** 用户打开 App
**When** 首页加载完成
**Then** 显示两个带有图标和文字的入口按钮
**And** "长视频"按钮显示播放图标
**And** "下载中心"按钮显示下载图标
**And** 点击按钮可以导航到对应页面

---

## Epic 1: 项目初始化与基础播放

**Epic Goal:** Flutter 开发者能够初始化项目并播放第一个视频

### Story 1.1: Plugin 项目初始化

作为 Flutter 开发者，
我想要使用 Flutter 官方模板初始化 Plugin 项目，
以便开始集成保利威播放器。

**验收标准：**

**Given** 开发环境已安装 Flutter SDK
**When** 执行 `flutter create --template=plugin --platforms=ios,android --org=com.polyv polyv_media_player`
**Then** 创建标准 Plugin 项目结构
**And** 包含 lib/, ios/, android/, example/ 目录
**And** pubspec.yaml 配置正确
**And** iOS 使用 Swift，Android 使用 Kotlin

### Story 1.2: Platform Channel 封装 (iOS)

作为 Flutter 开发者，
我想要封装 iOS 原生播放器的 Platform Channel，
以便 Flutter 层可以调用原生播放能力。

**验收标准：**

**Given** Plugin 项目已初始化
**When** 实现 MethodChannel 和 EventChannel
**Then** 创建 player_api.dart 定义接口
**Then** iOS 端实现 PolyvMediaPlayerPlugin.swift
**And** 支持方法调用：playVideo, pause, seek
**And** 支持事件回调：stateChanged, progress, error
**And** 使用 PlatformException 进行错误处理

### Story 1.3: 基础播放控制

作为最终用户，
我想要播放视频并可以暂停/继续，
以便观看视频内容。

**验收标准：**

**Given** 已加载视频
**When** 点击播放按钮
**Then** 视频开始播放
**And** 播放按钮变为暂停图标
**When** 点击暂停按钮
**Then** 视频暂停播放
**And** 暂停按钮变为播放图标
**And** 播放状态通过 Provider 正确同步到 UI

---

## Epic 2: 播放进度与时间显示

**Epic Goal:** 用户可以查看播放进度并拖动跳转

### Story 2.1: 进度条组件

作为最终用户，
我想要看到播放进度条，
以便了解视频播放进度。

**验收标准：**

**Given** 视频正在播放
**When** 进度更新
**Then** 进度条显示当前播放位置
**And** 已播放部分有视觉区分
**And** 支持拖动进度条
**When** 拖动进度条到某位置
**Then** 视频跳转到对应位置

### Story 2.2: 时间显示组件

作为最终用户，
我想要查看当前播放时间和总时长，
以便了解视频进度。

**验收标准：**

**Given** 视频已加载
**When** 视频播放中
**Then** 显示当前时间（格式：分:秒）
**And** 显示总时长（格式：分:秒）
**And** 时间格式为 "MM:SS" 或 "HH:MM:SS"

### Story 2.3: 缓冲进度显示

作为最终用户，
我想要看到视频缓冲进度，
以便了解视频加载状态。

**验收标准：**

**Given** 视频正在缓冲
**When** 缓冲进度更新
**Then** 进度条上显示缓冲区域
**And** 缓冲区域有视觉区分（浅色背景）
**And** 缓冲进度不干扰已播放进度显示

---

## Epic 3: 播放增强功能

**Epic Goal:** 用户可以控制视频清晰度、倍速和音量

### Story 3.1: 清晰度切换

作为最终用户，
我想要切换视频清晰度，
以便根据网络状况选择合适的画质。

**验收标准：**

**Given** 视频支持多清晰度
**When** 点击清晰度选择器
**Then** 显示可用清晰度列表（自动/1080p/720p/480p/360p）
**When** 选择某个清晰度
**Then** 视频切换到对应清晰度
**And** 清晰度状态更新到 UI

### Story 3.2: 倍速播放

作为最终用户，
我想要调整播放速度，
以便快速浏览或慢动作查看。

**验收标准：**

**Given** 视频正在播放
**When** 点击倍速选择器
**Then** 显示倍速选项（0.5x/1.0x/1.25x/1.5x/2.0x）
**When** 选择某个倍速
**Then** 视频以对应速度播放
**And** 当前倍速在 UI 上显示

### Story 3.3: 音量控制

作为最终用户，
我想要调节播放音量或静音，
以便控制音频输出。

**验收标准：**

**Given** 视频正在播放
**When** 拖动音量滑块
**Then** 播放音量随滑块变化
**And** 显示当前音量百分比
**When** 点击静音按钮
**Then** 视频静音
**And** 静音图标显示
**When** 再次点击静音按钮
**Then** 恢复之前的音量

---

## Epic 4: 弹幕功能

**Epic Goal:** 用户可以看到和发送弹幕

### Story 4.1: 弹幕显示层

作为最终用户，
我想要看到其他用户发送的弹幕，
以便获得互动体验。

**验收标准：**

**Given** 弹幕功能已开启
**When** 有弹幕数据
**Then** 弹幕从右向左滚动显示
**And** 弹幕显示在视频上方
**And** 弹幕不遮挡视频主要内容
**And** 多条弹幕在不同轨道显示

### Story 4.2: 弹幕开关与设置

作为最终用户，
我想要控制弹幕显示和样式，
以便获得舒适的观看体验。

**验收标准：**

**Given** 视频正在播放
**When** 点击弹幕开关
**Then** 弹幕显示/隐藏切换
**When** 进入弹幕设置
**Then** 可以调节弹幕透明度
**And** 可以选择弹幕字号（小/中/大）
**And** 设置实时生效

### Story 4.3: 发送弹幕

作为最终用户，
我想要发送弹幕，
以便与其他观众互动。

**验收标准：**

**Given** 弹幕输入框可见
**When** 输入文字并点击发送
**Then** 弹幕立即显示在屏幕上
**And** 弹幕与其他用户弹幕样式一致
**And** 输入框在发送后清空
**And** 发送弹幕通过 Flutter 层的 `DanmakuService.sendDanmaku` 调用 Polyv 弹幕发送 HTTP API（或后续统一封装的 Platform Channel 方法），不在原生层直接发起 HTTP 请求
**And** 发送失败时在 Flutter 层得到可区分的错误（网络错误、鉴权错误等），UI 可以给出合适的提示或重试机制

### Story 4.4: 弹幕服务后端接入（历史弹幕 API）

作为 Flutter 开发者，
我想要将弹幕服务接入 Polyv 后端 API，
以便在 iOS 和 Android 上统一使用同一套弹幕数据源。

**验收标准：**

**Given** 已实现 `DanmakuService / DanmakuRepository` 接口（Story 4.1）
**When** 调用 `fetchDanmakus(vid)`
**Then** 通过 Polyv 弹幕 HTTP API（或后续统一封装的 Platform Channel 方法）拉取指定 vid 的历史弹幕列表
**And** 返回统一的 Dart `Danmaku` 模型（包含 id / text / time / color / type）
**And** 请求失败时返回清晰的错误类型，便于 UI 层区分网络问题、鉴权失败、参数错误等

**Given** 播放器开始播放某个视频
**When** `PlayerController` 进入「已加载并准备播放」状态
**Then** 通过 `DanmakuService.fetchDanmakus(vid)` 拉取对应弹幕列表并提供给 `DanmakuLayer`
**And** iOS / Android 原生层不再直接访问弹幕 HTTP 接口或维护弹幕业务状态，所有弹幕数据流以 Flutter(Dart) 层为单一真相来源

---

## Epic 5: 字幕功能

**Epic Goal:** 用户可以开关字幕并切换多语言

### Story 5.1: 字幕显示与开关

作为最终用户，
我想要显示或隐藏字幕，
以便根据需要查看字幕。

**验收标准：**

**Given** 视频有字幕
**When** 开启字幕
**Then** 字幕显示在视频底部
**And** 字幕清晰可读
**When** 关闭字幕
**Then** 字幕隐藏

### Story 5.2: 多语言字幕切换

作为最终用户，
我想要选择字幕语言，
以便查看不同语言的字幕。

**验收标准：**

**Given** 视频有多种语言字幕
**When** 点击字幕选择器
**Then** 显示可用语言列表（如：中文、English）
**When** 选择某个语言
**Then** 字幕切换到对应语言
**And** 当前语言在 UI 上标识

---

## Epic 6: 播放列表

**Epic Goal:** 用户可以浏览视频列表并切换视频

### Story 6.1: 账号配置管理

作为开发者，
我想要统一配置播放器账号信息，
以便通过账号获取视频列表。

**验收标准：**

**Given** 播放器插件已集成
**When** 初始化播放器时传入账号配置
**Then** 账号信息存储在原生层
**And** 配置支持热重载切换
**And** 同一配置可同时用于 iOS 和 Android

**技术说明：**
- 创建 `PlayerConfig` 类包含 userId, readToken, writeToken, secretKey
- 通过 `initialize()` 方法从 Flutter 传递配置到原生层
- 移除 iOS AppDelegate 和 Android 中的硬编码配置

### Story 6.2: 获取视频列表 API

作为开发者，
我想要通过账号信息从 Polyv API 获取视频列表，
以便动态展示可播放内容。

**验收标准：**

**Given** 播放器已初始化账号配置
**When** 调用 `fetchVideoList()` 方法
**Then** 返回该账号下的视频列表
**And** 每个视频包含：vid, title, duration, thumbnail
**And** 支持分页查询（page, pageSize）

**技术说明：**
- 新增 `fetchVideoList()` Platform Channel 方法
- iOS/Android 原生层调用 Polyv REST API
- API 签名使用 userId + secretKey

### Story 6.3: 视频列表展示

作为最终用户，
我想要查看可播放的视频列表，
以便选择想看的视频。

**验收标准：**

**Given** 已获取视频列表
**When** 进入长视频页面
**Then** 显示视频列表
**And** 每个视频项显示：缩略图、标题、时长
**And** 当前播放的视频有高亮标识
**And** 列表支持滚动浏览

### Story 6.4: 切换视频

作为最终用户，
我想要在列表中选择其他视频，
以便切换播放内容。

**验收标准：**

**Given** 正在播放视频 A
**When** 点击列表中的视频 B
**Then** 停止播放视频 A
**And** 开始加载视频 B
**And** 播放器显示视频 B
**And** 视频列表高亮视频 B

### Story 6.5: 触发下载任务

作为最终用户，
我想要通过播放器顶栏的更多选项弹窗触发下载，
以便将当前播放的视频下载到本地观看。

**验收标准：**

**Given** 用户正在播放视频
**When** 点击播放器顶栏右侧的更多按钮（⋯）
**And** 在弹出的更多选项弹窗中点击"下载"
**Then** 为当前播放的视频创建新的下载任务
**And** 任务添加到下载中心的"下载中"列表
**And** 弹窗关闭

**技术说明：**
- 更多选项弹窗为**列表式布局**（非网格），每行一个功能选项
- **顶部优先显示三个重要功能**：音频模式、字幕设置、下载
- 其余功能：截图、分享、定时关闭、投屏、帮助反馈等
- 弹窗样式参考原型 /Users/nick/projects/polyv/iOS/polyv-vod/src/components/mobile/MobileMoreOptions.tsx
- 下载任务关联当前播放的视频 vid
- 下载服务层维护下载任务队列

---

## Epic 7: 高级交互功能

**Epic Goal:** 用户可以通过手势和全屏模式获得更好的体验

### Story 7.1: 全屏切换

作为最终用户，
我想要切换全屏模式，
以便获得沉浸式观看体验。

**验收标准：**

**Given** 视频正在播放
**When** 点击全屏按钮
**Then** 播放器进入全屏模式
**And** 控制栏在全屏模式下保持可访问
**When** 再次点击全屏按钮（或返回）
**Then** 退出全屏模式
**And** 播放器恢复正常大小

### Story 7.2: 单击暂停/播放

作为最终用户，
我想要单击视频区域来暂停/播放，
以便快速控制播放。

**验收标准：**

**Given** 视频正在播放
**When** 单击视频中心区域
**Then** 视频暂停
**And** 显示播放按钮覆盖层
**When** 再次单击
**Then** 视频继续播放
**And** 播放按钮覆盖层消失

### Story 7.3: 双击全屏

作为最终用户，
我想要双击视频区域进入全屏，
以便快速切换全屏模式。

**验收标准：**

**Given** 视频正在播放
**When** 双击视频区域
**Then** 进入/退出全屏模式
**And** 切换流畅无卡顿

### Story 7.4: 滑动手势

作为最终用户，
我想要通过滑动手势控制播放和音量，
以便获得更便捷的操作体验。

**验收标准：**

**Given** 视频正在播放
**When** 在屏幕左侧上下滑动
**Then** 调节音量（上增下减）
**When** 在屏幕右侧上下滑动
**Then** 调节亮度（上增下减）
**When** 在屏幕左右滑动
**Then** 快进/快退播放位置
**And** 滑动时显示进度提示

---

## Epic 8: 分享功能

**Epic Goal:** 用户可以分享视频

### Story 8.1: 社交分享面板

作为最终用户，
我想要分享视频给朋友，
以便推荐视频内容。

**验收标准：**

**Given** 视频正在播放
**When** 点击分享按钮
**Then** 显示分享面板
**And** 显示常用社交平台选项
**When** 选择某个平台
**Then** 打开对应平台的分享界面
**And** 包含视频链接和标题信息

---

## Epic 9: 下载中心

**Epic Goal:** 用户可以管理和查看下载中的视频

### Story 9.1: 下载中心页面框架

作为最终用户，
我想要进入下载中心查看下载任务，
以便管理离线视频。

**验收标准：**

**Given** 用户在首页
**When** 点击下载中心按钮
**Then** 进入下载中心页面
**And** 显示两个 Tab：下载中、已完成
**And** 每个显示当前任务数量

### Story 9.2: 下载进度显示

作为最终用户，
我想要查看下载进度，
以便了解下载状态。

**验收标准：**

**Given** 有正在下载的视频
**When** 在下载中 Tab
**Then** 每个下载任务显示：缩略图、标题、进度条
**And** 进度条显示当前百分比
**And** 显示文件大小和下载速度

### Story 9.3: 暂停/继续下载

作为最终用户，
我想要控制下载任务的暂停和继续，
以便管理下载时间。

**验收标准：**

**Given** 有正在下载的任务
**When** 点击暂停按钮
**Then** 任务状态变为"已暂停"
**And** 进度不再更新
**When** 点击继续按钮
**Then** 任务恢复下载
**And** 进度继续更新

### Story 9.4: 重试失败下载

作为最终用户，
我想要重试失败的下载，
以便完成下载任务。

**验收标准：**

**Given** 有下载失败的任务
**When** 任务显示失败状态
**Then** 显示错误图标和"下载失败"提示
**When** 点击重试按钮
**Then** 任务重新开始下载
**And** 状态更新为"下载中"

### Story 9.5: 删除下载任务

作为最终用户，
我想要删除不需要的下载任务，
以便保持列表整洁。

**验收标准：**

**Given** 有下载任务
**When** 点击删除按钮
**Then** 任务从列表中移除
**And** 已下载的文件同时删除

### Story 9.6: 空状态处理

作为最终用户，
我想要看到友好的空状态提示，
以便了解当前没有下载任务。

**验收标准：**

**Given** 下载中没有任务
**When** 查看下载中 Tab
**Then** 显示空状态图标和提示文字
**Given** 已完成中没有任务
**When** 查看已完成 Tab
**Then** 显示空状态图标和提示文字

### Story 9.7: 下载控制强一致化（原生能力接入）

作为最终用户，
我想要对下载任务执行暂停/继续/重试/删除，
并且 UI 状态与原生下载 SDK 的执行结果严格一致，
以避免“UI 看起来成功但实际未生效”。

**验收标准：**

**Given** 用户点击暂停/继续/重试/删除
**When** 原生层调用成功
**Then** Flutter 层才更新任务状态/列表
**And** UI 状态与原生执行结果一致

**Given** 用户点击暂停/继续/重试/删除
**When** 原生层调用失败（未实现/参数错误/找不到任务/SDK 错误）
**Then** Flutter 层不更新任务状态/列表
**And** UI 展示错误提示（默认 SnackBar；删除失败使用 Dialog 或等效强提示）

**Given** 原生侧方法未实现或执行失败
**When** Flutter 调用 MethodChannel
**Then** 原生层返回明确 PlatformException（包含 code/message）

### Story 9.8: 下载任务权威同步（getDownloadList + EventChannel）

作为最终用户，
我想要下载中心展示的任务列表/进度/完成/失败状态与原生下载 SDK 保持一致，
以确保下载中心是可靠的管理入口。

**验收标准：**

**Given** 用户进入下载中心
**When** 页面初始化
**Then** Flutter 调用 getDownloadList 拉取原生 SDK 的权威任务列表
**And** 列表与 Tab 徽章数量基于该列表渲染

**Given** 原生侧任务状态发生变化（进度/完成/失败/删除/暂停/继续）
**When** 事件发生
**Then** 原生通过 EventChannel 推送事件到 Flutter
**And** Flutter 更新任务镜像状态并驱动 UI 刷新

**Given** 同步/事件接收失败
**When** Flutter 侧发生异常
**Then** UI 提示错误（SnackBar）
**And** 不生成与原生不一致的“猜测状态”

---

## Epic 10: Android 平台支持

**Epic Goal:** Flutter 开发者可以在 Android 平台使用相同的播放器

### Story 10.1: Android Platform Channel 实现

作为 Flutter 开发者，
我想要 Android 端实现与 iOS 相同的 Platform Channel，
以便实现跨平台统一 API。

**验收标准：**

**Given** iOS Platform Channel 已实现
**When** 实现 Android 端
**Then** 创建对应的 MethodChannel 和 EventChannel
**And** 实现相同的方法调用：playVideo, pause, seek
**And** 实现相同的事件回调：stateChanged, progress, error
**And** API 命名和参数格式与 iOS 一致

### Story 10.2: Android 原生 SDK 集成

作为 Flutter 开发者，
我想要集成保利威 Android SDK，
以便在 Android 平台播放视频。

**验收标准：**

**Given** Android 项目已配置
**When** 添加 PolyvMediaPlayerSDK 依赖
**Then** build.gradle 配置正确
**And** SDK 版本与 iOS 功能对等
**And** 视频播放功能正常工作

### Story 10.3: Android 功能验证

作为 QA 工程师，
我想要验证 Android 端所有功能与 iOS 一致，
以便确保双平台体验一致。

**验收标准：**

**Given** iOS 端所有功能已实现
**When** 测试 Android 端
**Then** 所有播放控制功能正常
**And** 弹幕、字幕、清晰度切换等功能正常
**And** 手势交互正常工作
**And** 全屏切换正常
