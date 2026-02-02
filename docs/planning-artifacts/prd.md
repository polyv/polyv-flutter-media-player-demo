---
stepsCompleted: ['step-01-init', 'step-02-discovery', 'step-03-success']
inputDocuments: ['project-context.md', 'architecture.md']
workflowType: 'prd'
generated: '2026-01-19'
project: 'polyv-ios-media-player-flutter-demo'
user_name: 'Nick'
date: '2026-01-19'
classification:
  projectType: mobile_app
  domain: media
  complexity: medium
  projectContext: brownfield
featureModules:
  - PlayerProgress
  - QualitySelector
  - SpeedSelector
  - VolumeControl
  - DanmakuLayer
  - DanmakuToggle
  - DanmakuInput
  - SubtitleToggle
  - Playlist
  - ShareModal
---

# Product Requirements Document - polyv-ios-media-player-flutter-demo

**Author:** Nick
**Date:** 2026-01-19

## 项目分类

- **项目类型：** 移动端应用
- **业务领域：** 媒体/视频播放
- **复杂度：** 中等
- **项目上下文：** Brownfield（已有代码和原型）

---

## Success Criteria

### User Success

**目标用户：** 使用 Flutter 开发移动应用的客户（需要集成保利威播放器）

**成功定义：**
- 客户拿到 demo 后，能够**比他们自己从零写 UI 节省大量时间**
- 客户能够直接复制 demo 的 UI 层代码，快速集成到自己的项目中
- 客户能够理解 demo 的代码结构，方便进行定制化开发

**成功时刻：**
- 客户在短时间内（预计 1-2 小时）完成 demo 集成到自己的项目
- 客户成功播放第一个视频
- 客户根据 demo 代码完成基本的 UI 定制

### Business Success

**目标：** 为 Flutter 开发者提供可复用的播放器 UI 方案

**成功指标：**
- **至少 10 家**使用 Flutter 开发 app 的客户集成使用
- 客户反馈时间节省明显（相比自己写 UI）
- 成为保利威 Flutter 集成方案的标准参考

**时间线：**
- **3 个月：** 完成 iOS + Android 双平台版本，有客户开始使用
- **12 个月：** 至少 10 家客户集成使用，收集反馈并优化

### Technical Success

**平台支持：**
- ✅ iOS（已完成，成功构建）
- ⏳ Android（待集成）

**技术要求：**
- 支持 iOS 和 Android 双平台
- 视频播放流畅、稳定
- 代码结构清晰，易于理解和定制
- 与原生 SDK 的功能对等

**性能指标：**
- 视频启动时间 < 3 秒
- 播放控制响应时间 < 200ms
- 内存占用合理（不影响 app 性能）

### Measurable Outcomes

| 指标 | 目标 | 测量方式 |
|------|------|----------|
| 客户集成数量 | ≥ 10 家 | 跟踪客户集成情况 |
| 客户反馈时间节省 | 节省 > 50% 时间 | 客户问卷/访谈 |
| 双平台支持 | iOS + Android | 平台验证测试 |
| 代码质量 | 清晰、可定制 | 客户反馈 |

## Product Scope

### MVP - Minimum Viable Product

**HTML 原型的所有功能：**

| 模块 | 功能 | 说明 |
|------|------|------|
| 播放控制 | 播放/暂停/seek | 基础播放能力 |
| 进度显示 | 播放进度条、缓冲进度、拖动 seek | 时间显示和交互 |
| 清晰度切换 | 在线切换视频清晰度 | 1080p/720p/480p/360p |
| 倍速播放 | 多种播放速度 | 0.5x/1.0x/1.25x/1.5x/2.0x |
| 音量控制 | 音量调节、静音 | 播放器音量 |
| 弹幕系统 | 显示/发送/透明度/字号 | 完整弹幕功能 |
| 字幕支持 | 字幕开关、多语言字幕 | 中英文等 |
| 播放列表 | 视频列表、切换视频 | 播放列表导航 |
| 全屏切换 | 竖屏/横屏全屏 | 方向适配 |
| 手势交互 | 单击/双击/拖拽 | 播放器手势 |
| 分享功能 | 分享视频 | 社交分享 |

### Growth Features (Post-MVP)

- 播放器皮肤主题系统
- 更多手势操作
- 高级弹幕功能
- 播放数据统计

### Vision (Future)

- 将含完整 UI 的播放器也做成 Flutter Plugin
- 提供更多预制主题
- 提供低代码集成方案

---

## User Journeys

### 用户旅程 1: Flutter 开发者 - 快速集成路径

**人物画像：**
- **姓名：** 小李
- **角色：** 某教育公司 Flutter 开发者
- **技能水平：** 熟悉 Flutter，但不熟悉视频播放器开发
- **当前痛点：** 公司 app 需要集成保利威播放器，但只有原生 SDK，自己写 UI 太耗时

**旅程故事：**

**1. 发现阶段**
- 小李接到任务：在教育 app 中集成保利威播放器
- 查看保利威文档，发现只有原生 SDK，Flutter 方案需要自己写 UI
- 向技术支持咨询，被告知有 Flutter demo 可以参考
- 小李心想："太好了，不用从零开始写了"

**2. 下载探索**
- 小李从 GitHub 克隆 demo 项目
- 运行 `flutter pub get` 安装依赖
- 运行 demo，看到完整的播放器 UI 展示
- 测试播放、暂停、清晰度切换等功能，感觉"这个能行"

**3. 集成实施**
- 小李创建自己的 Flutter 项目
- 将 demo 中的播放器相关代码复制过去
- 根据自己 app 的主题修改颜色和样式
- 遇到问题：demo 中有播放器状态管理，小李理解后觉得这个设计很好，直接用上了

**4. 定制优化**
- 小李需要隐藏一些不需要的按钮（比如分享）
- 查看代码，注释掉相关组件
- 重新运行，集成成功

**5. 成功时刻**
- 小李的 app 成功播放第一个保利威视频
- 整个集成过程只用了 2 小时
- 小李想："这个 demo 代码质量不错，结构清晰，学到了不少"

**旅程需求：**
- Demo 代码要清晰、易读
- 代码结构要模块化，方便选择性复制
- 关键代码要有注释说明

---

### 用户旅程 2: 技术支持工程师 - 高效响应

**人物画像：**
- **姓名：** 小张
- **角色：** 保利威技术支持工程师
- **工作内容：** 帮助客户集成播放器，解答技术问题

**旅程故事：**

**1. 客户咨询**
- 客户在工单系统中问："Flutter 怎么集成你们的播放器？"
- 小张之前每次都要口头解释 30 分钟，很累
- 现在有了 demo，小张直接回复："我们有个 Flutter demo，您可以直接参考"

**2. 发送资源**
- 小张把 demo 的 GitHub 链接和简单说明发给客户
- 附上 README："克隆项目，运行 example/，就能看到效果"

**3. 跟进确认**
- 第二天，客户反馈："我跑起来了，但是不知道怎么改皮肤"
- 小张查看 demo 的 UI 组件结构
- 找到 PlayerSkin 目录，告诉客户："修改这个文件的颜色属性"

**4. 高级问题**
- 客户问："怎么获取播放进度？"
- 小张查看 demo，找到 PlayerController 中的 progress 事件
- 告诉客户代码示例："监听 PlayerController 的 stream 就能拿到进度"

**5. 完成支持**
- 客户成功集成，感谢小张的帮助
- 小张把这个 demo 链接加入到标准回复模板中
- 以后类似问题减少 50%

**旅程需求：**
- README 要清晰，有快速开始指南
- 代码注释要充分
- 常见问题要有示例

---

### Journey Requirements Summary

**从旅程中提取的关键需求：**

| 需求类别 | 具体需求 |
|---------|----------|
| 代码质量 | 清晰、易读、模块化 |
| 文档 | README + 代码注释 |
| 可定制性 | 组件可独立使用/隐藏 |
| 示例代码 | 常见操作的代码示例 |

---

## Domain Requirements

**领域：** 媒体/视频播放（中等复杂度）

**领域特点：**
- 非高监管行业，无特殊合规要求
- 重点关注用户体验（播放流畅度、响应速度）
- 需要与原生 SDK 保持功能对等

**关键领域需求：**
- **视频播放标准：** 支持常见视频格式（MP4、HLS）
- **播放控制：** 基础播放操作（播放/暂停/seek/停止）
- **状态同步：** Native ↔ Flutter 状态实时同步
- **事件处理：** 播放事件、错误事件的正确传递

---

## Innovation Focus

**创新点：**
- **填补空白：** 保利威首次提供 Flutter UI 层参考方案
- **复用性设计：** Demo 代码结构清晰，客户可轻松复制定制
- **双平台一致：** iOS 和 Android 使用统一的 Flutter 代码

**差异化价值：**
- 相比于原生 SDK demo，Flutter demo 跨平台代码复用
- 相比于客户自己开发，节省 50%+ 时间
- 官方维护，与 SDK 同步更新

---

## Project Type Requirements

**移动端应用（Demo + 代码参考）特性：**

**平台要求：**
- 支持 iOS 13.0+
- 支持 Android 5.0+（待定）

**UI 设计要求：**
- 遵循 Flutter Material Design 或 iOS 风格
- 支持竖屏和横屏方向
- 自适应不同屏幕尺寸

**集成友好：**
- 代码结构模块化，组件可独立使用
- 配置项清晰，易于定制
- 关键 API 有使用示例

---

## Functional Requirements

### 功能模块清单

| 功能模块 | 功能点 | 优先级 |
|---------|--------|--------|
| **播放控制** | 播放/暂停/停止 | P0 |
| **播放控制** | seek（拖动进度条） | P0 |
| **进度显示** | 当前时间/总时长 | P0 |
| **进度显示** | 缓冲进度显示 | P1 |
| **清晰度切换** | 切换视频清晰度 | P0 |
| **倍速播放** | 0.5x ~ 2.0x | P0 |
| **音量控制** | 音量调节/静音 | P0 |
| **弹幕** | 弹幕显示开关 | P0 |
| **弹幕** | 弹幕透明度调节 | P1 |
| **弹幕** | 弹幕字号切换 | P1 |
| **弹幕** | 发送弹幕 | P0 |
| **字幕** | 字幕开关 | P0 |
| **字幕** | 多语言字幕 | P1 |
| **播放列表** | 视频列表展示 | P0 |
| **播放列表** | 切换视频 | P0 |
| **全屏** | 全屏切换 | P0 |
| **手势** | 单击暂停/播放 | P1 |
| **手势** | 双击全屏 | P1 |
| **手势** | 左右滑动 seek | P1 |
| **手势** | 上下滑动音量 | P1 |
| **分享** | 社交分享 | P1 |

### Platform Channel API

**方法调用（Flutter → Native）：**
| 方法 | 参数 | 说明 |
|------|------|------|
| loadVideo | vid, autoPlay | 加载视频 |
| play | - | 播放 |
| pause | - | 暂停 |
| stop | - | 停止 |
| seekTo | position (ms) | 跳转到指定位置 |
| setPlaybackSpeed | speed | 设置播放速度 |
| setQuality | quality | 设置清晰度 |
| setSubtitle | enabled | 开关字幕 |

**事件（Native → Flutter）：**
| 事件 | 数据 | 说明 |
|------|------|------|
| stateChanged | state | 播放状态变化 |
| progress | position, duration, bufferedPosition | 播放进度更新 |
| error | code, message | 错误事件 |

---

## Non-Functional Requirements

### 性能

| 指标 | 目标 | 说明 |
|------|------|------|
| 视频启动时间 | < 3 秒 | 从调用 loadVideo 到首帧显示 |
| 播放控制响应 | < 200ms | 播放/暂停/seek 操作的响应时间 |
| UI 流畅度 | 60fps | 播放器 UI 动画流畅 |

### 兼容性

- **iOS：** 13.0+
- **Android：** 5.0+（待确认）
- **Flutter：** 最新稳定版

### 可维护性

- 代码遵循 Flutter 官方风格指南
- 关键类和方法有文档注释
- 组件低耦合，易于修改

### 可扩展性

- 支持添加新的控制按钮
- 支持自定义皮肤主题
- 支持扩展事件类型

---

## Constraints & Assumptions

### 约束

- **依赖约束：** 必须使用保利威原生 SDK
- **平台约束：** 功能受限于原生 SDK 的能力
- **时间约束：** Android 集成需要在 iOS 完成后开始

### 假设

- 客户具备基本的 Flutter 开发能力
- 客户有保利威播放账号和合法视频内容
- 客户的开发环境可以访问 Google/CocoaPods

---

## Open Questions

**当前开放问题：**

1. **Android 原生 SDK 版本：** 需要确认对应的 Android SDK 版本
2. **弹幕数据来源：** demo 中是模拟数据，实际需要从 SDK 获取
3. **字幕数据来源：** demo 中是模拟数据，实际需要从 SDK 获取

**后续解决方式：**
- 问题 1：与保利威 SDK 团队确认 Android SDK 版本
- 问题 2/3：参考原生 demo，从 SDK 获取真实数据

---

## Dependencies

### 外部依赖

| 依赖项 | 版本 | 用途 |
|--------|------|------|
| Flutter SDK | 最新稳定版 | Flutter 框架 |
| PolyvMediaPlayerSDK (iOS) | ~> 2.7.2 | iOS 原生播放器 |
| PolyvMediaPlayerSDK (Android) | 待确认 | Android 原生播放器 |
| provider | ^6.1.0 | 状态管理 |

### 内部依赖

- 架构文档：`docs/planning-artifacts/architecture.md`
- 项目上下文：`docs/project-context.md`
- HTML 原型：`/Users/nick/projects/polyv/ios/polyv-vod/`（功能参考）

---

## Document Status

**状态：** ✅ 完成
**完成日期：** 2026-01-19
**版本：** 1.0

**已完成步骤：**
- ✅ Step 1: 初始化
- ✅ Step 2: 项目发现
- ✅ Step 3: 成功标准
- ✅ Step 4: 用户旅程
- ✅ Step 5: 领域需求
- ✅ Step 6: 创新焦点
- ✅ Step 7: 项目类型需求
- ✅ Step 8: 范围定义
- ✅ Step 9: 功能需求
- ✅ Step 10: 非功能需求
- ✅ Step 11: 润色
- ✅ Step 12: 完成

---

## Next Steps

PRD 已完成！建议下一步：

**1. 验证 PRD** - 运行 PRD 验证确保文档完整
**2. 创建 Epics & Stories** - 将 PRD 拆分成可执行的开发任务
**3. 创建 Sprint Status** - 跟踪开发进度

你想先做哪个？

