# Story 3.1: 清晰度切换

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

作为最终用户，
我想要切换视频清晰度，
以便根据网络状况选择合适的画质。

## Acceptance Criteria

**Given** 视频支持多清晰度
**When** 点击清晰度选择器
**Then** 显示可用清晰度列表（自动/1080p/720p/480p/360p）
**When** 选择某个清晰度
**Then** 视频切换到对应清晰度
**And** 清晰度状态更新到 UI

## Tasks / Subtasks

- [x] 实现清晰度选择器 UI 组件 (AC: Given, When, Then)
  - [x] 创建 `quality_selector/` 目录和文件
  - [x] 实现 `QualitySelector` Widget（按钮 + 下拉菜单）
  - [x] 实现清晰度标签显示（1080P 高清、720P 标清等）
  - [x] 实现"自动"模式显示（Settings2 图标）
  - [x] 添加点击遮罩关闭菜单功能
- [x] 集成清晰度数据流 (AC: When, Then, And)
  - [x] 从 PlayerController 获取 qualities 列表
  - [x] 从 PlayerController 获取 currentQuality
  - [x] 调用 controller.setQuality(index) 切换清晰度
  - [x] 使用 Consumer<PlayerController> 响应状态变化
- [x] 样式实现（参考原型） (AC: Then)
  - [x] 应用 PlayerColors 颜色系统
  - [x] 实现 dropdown 菜单样式（圆角、阴影、背景）
  - [x] 实现当前选中项高亮（active 状态）
  - [x] 实现固定遮罩层（z-40）和菜单层（z-50）
- [x] 测试验证 (AC: Given, When, Then, And)
  - [x] Widget 测试：点击按钮显示菜单
  - [x] Widget 测试：点击遮罩关闭菜单
  - [x] Widget 测试：点击清晰度项调用 setQuality
  - [x] Widget 测试：当前清晰度高亮显示
  - [x] 集成测试：清晰度切换正确传递到 PlayerController

## Dev Notes

### Story Context

**Epic 3: 播放增强功能**
- 这是 Epic 3 的第一个 Story，实现清晰度切换功能
- Epic 3 包含 3 个 Stories：清晰度切换(3.1)、倍速播放(3.2)、音量控制(3.3)
- 本 Story 创建新的 UI 组件，并与现有 PlayerController 集成

**前置依赖：**
- Epic 1 Story 1.2 已完成 - PlayerController 已实现 `setQuality(int index)` 方法
- PlayerController 已有 `qualities` 和 `currentQuality` getter
- PlayerController 已处理 `qualityChanged` 事件

### Architecture Compliance

**组件位置（新建）：**
```
example/lib/player_skin/quality_selector/
├── quality_selector.dart           # 清晰度选择器组件
└── quality_selector_test.dart      # Widget 测试
```

**状态管理模式：**
```dart
// 使用 Consumer<PlayerController> 获取状态
Consumer<PlayerController>(
  builder: (context, controller, child) {
    return QualitySelector(
      qualities: controller.qualities,           // List<QualityItem>
      currentQuality: controller.currentQuality, // QualityItem?
      onQualityChange: (index) {
        controller.setQuality(index);
      },
    );
  },
)
```

**集成到 ControlBar：**
```dart
// control_bar.dart 添加清晰度按钮
Row(
  children: [
    _buildPlayPauseButton(),
    const Spacer(),
    QualitySelector(  // 新增
      controller: controller,
    ),
    _buildStopButton(),
  ],
)
```

### Previous Story Intelligence

**从 Epic 2 学到的经验：**

1. **下拉菜单模式（参考原型）**
   - 使用 Stack + Positioned 实现弹出菜单
   - 使用 GestureDetector 包裹遮罩层（点击关闭）
   - 菜单项使用 active 状态高亮当前选中项

2. **PlayerController 交互模式**
   ```dart
   // 清晰度数据已由 PlayerController 管理
   controller.qualities       // List<QualityItem>
   controller.currentQuality  // QualityItem?
   controller.setQuality(int index)  // 切换清晰度
   ```

3. **QualityItem 数据结构**
   ```dart
   // player_events.dart 已定义
   class QualityItem {
     final String description;  // "1080P 高清"
     final String value;        // "1080p"
     final bool isAvailable;
   }
   ```

4. **事件流机制**
   - Native 层发送 `qualityChanged` 事件
   - PlayerController._handleQualityChanged() 处理
   - Consumer<PlayerController> 自动更新 UI

**本 Story 重点：**
- 创建新的 QualitySelector 组件
- 与现有 PlayerController 无缝集成
- 遵循原型视觉设计

### UI 原型参考

**原型文件：** `/Users/nick/projects/polyv/ios/polyv-vod/src/components/player/QualitySelector.tsx`
**移动端菜单原型：** `/Users/nick/projects/polyv/ios/polyv-vod/src/components/mobile/MobilePortraitMenu.tsx`

**原型结构分析：**
```tsx
// 外层：relative 容器
<div className="relative">
  {/* 1. 触发按钮 */}
  <PlayerControlButton
    icon={
      <span className="text-xs font-semibold uppercase">
        {/* auto 模式显示 Settings2 图标 */}
        {currentQuality === "auto" ? <Settings2 size={18} /> : currentQuality}
      </span>
    }
    tooltip="画质"
    onClick={() => setIsOpen(!isOpen)}
  />

  {/* 2. 遮罩层 - 点击关闭 */}
  {isOpen && (
    <div
      className="fixed inset-0 z-40"
      onClick={() => setIsOpen(false)}
    />
  )}

  {/* 3. 下拉菜单 */}
  {isOpen && (
    <div className="player-dropdown z-50">
      {/* 标题 */}
      <div className="text-xs text-player-muted px-3 py-1 mb-1">
        画质选择
      </div>

      {/* 清晰度列表 */}
      {qualities.map((quality) => (
        <div
          key={quality}
          className={`player-dropdown-item ${
            quality === currentQuality ? "active" : ""
          }`}
          onClick={() => {
            onQualityChange(quality);
            setIsOpen(false);
          }}
        >
          {getQualityLabel(quality)}
        </div>
      ))}
    </div>
  )}
</div>
```

**清晰度标签映射：**
```tsx
const getQualityLabel = (quality: string) => {
  const labels: Record<string, string> = {
    "4k": "4K 超清",
    "1080p": "1080P 高清",
    "720p": "720P 标清",
    "480p": "480P 流畅",
    "360p": "360P 极速",
    auto: "自动",
  };
  return labels[quality] || quality;
};
```

**Flutter 实现对应：**

```dart
// Stack 实现弹出菜单
Stack(
  children: [
    // 1. 触发按钮
    _buildQualityButton(),

    // 2. 遮罩层
    if (_isOpen)
      Positioned.fill(
        child: GestureDetector(
          onTap: () => setState(() => _isOpen = false),
          child: Container(color: Colors.transparent),
        ),
      ),

    // 3. 下拉菜单
    if (_isOpen)
      _buildDropdownMenu(),
  ],
)

// 按钮显示逻辑
String _getButtonLabel() {
  final quality = widget.currentQuality;
  if (quality == null || quality.value == 'auto') {
    return '';  // 显示 Settings2 图标
  }
  return quality.value.toUpperCase();  // "1080P"
}

// 清晰度标签映射
String _getQualityLabel(QualityItem quality) {
  const labels = {
    '4k': '4K 超清',
    '1080p': '1080P 高清',
    '720p': '720P 标清',
    '480p': '480P 流畅',
    '360p': '360P 极速',
    'auto': '自动',
  };
  return labels[quality.value] ?? quality.description;
}
```

### Technical Requirements

**清晰度标签映射：**

| value | 显示标签 |
|-------|----------|
| `4k` | 4K 超清 |
| `1080p` | 1080P 高清 |
| `720p` | 720P 标清 |
| `480p` | 480P 流畅 |
| `360p` | 360P 极速 |
| `auto` | 自动（显示 Settings2 图标） |

**颜色规范：**
```dart
// 按钮颜色
static const Color _iconColor = Color(0xFFF5F5F5);    // PlayerColors.text
static const Color _iconDisabled = Color(0xFF8B919E); // PlayerColors.textMuted

// 下拉菜单
static const Color _menuBackground = Color(0xFF2D3548); // PlayerColors.controls
static const Color _itemHover = Color(0xFF3D4560);      // PlayerColors.progressBuffer
static const Color _itemActive = Color(0xFFE8704D);      // PlayerColors.progress
static const Color _textMuted = Color(0xFF8B919E);       // PlayerColors.textMuted
static const Color _textNormal = Color(0xFFF5F5F5);      // PlayerColors.text

// 阴影
static const List<BoxShadow> _menuShadow = [
  BoxShadow(
    color: Color(0x33000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  ),
];
```

**样式常量：**
```dart
class Spacing {
  static const double menuPadding = 12.0;
  static const double itemPadding = 8.0;
  static const double itemHeight = 36.0;
  static const double borderRadius = 8.0;
}

class TextStyles {
  static const TextStyle title = TextStyle(
    fontSize: 11,
    color: Color(0xFF8B919E),  // textMuted
  );
  static const TextStyle item = TextStyle(
    fontSize: 14,
    color: Color(0xFFF5F5F5),   // textNormal
  );
}
```

**Widget 测试框架：**
```dart
testWidgets('QualitySelector shows dropdown on tap', (tester) async {
  // 1. 构建 Widget
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<PlayerController>(
          create: (_) => mockController,
          child: Consumer<PlayerController>(
            builder: (context, controller, _) {
              return QualitySelector(
                qualities: mockQualities,
                currentQuality: mockQualities[1],
                onQualityChange: (_) {},
              );
            },
          ),
        ),
      ),
    ),
  );

  // 2. 验证初始状态
  expect(find.text('1080P'), findsOneWidget);
  expect(find.byType(DropdownMenu), findsNothing);

  // 3. 点击按钮
  await tester.tap(find.byType(QualitySelector));
  await tester.pumpAndSettle();

  // 4. 验证菜单显示
  expect(find.byType(DropdownMenu), findsOneWidget);
  expect(find.text('画质选择'), findsOneWidget);
  expect(find.text('1080P 高清'), findsOneWidget);
});

testWidgets('QualitySelector calls onQualityChange', (tester) async {
  int? selected;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: QualitySelector(
          qualities: mockQualities,
          currentQuality: mockQualities[0],
          onQualityChange: (index) => selected = index,
        ),
      ),
    ),
  );

  // 打开菜单
  await tester.tap(find.byType(QualitySelector));
  await tester.pumpAndSettle();

  // 点击清晰度项
  await tester.tap(find.text('720P 标清'));
  await tester.pump();

  // 验证回调
  expect(selected, 1);
});
```

### Project Structure Notes

**新建文件：**
```
polyv_media_player/example/lib/player_skin/quality_selector/
├── quality_selector.dart           # 主组件
└── quality_selector_test.dart      # Widget 测试
```

**修改文件：**
```
polyv_media_player/example/lib/player_skin/
├── control_bar.dart                # 添加 QualitySelector 按钮
└── control_bar_test.dart           # 添加相关测试
```

**核心文件（Plugin 层，无需修改）：**
```
polyv_media_player/lib/core/
├── player_controller.dart          # setQuality() 已实现
├── player_events.dart              # QualityItem 已定义
└── player_state.dart               # 状态基类
```

**QualitySelector 组件结构：**
```dart
class QualitySelector extends StatefulWidget {
  final PlayerController controller;
  // 或者使用显式参数：
  // final List<QualityItem> qualities;
  // final QualityItem? currentQuality;
  // final ValueChanged<int> onQualityChange;
}

class _QualitySelectorState extends State<QualitySelector> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildButton(),
        if (_isOpen) _buildOverlay(),
        if (_isOpen) _buildDropdown(),
      ],
    );
  }
}
```

### Testing Requirements

**Widget 测试要点：**
1. **按钮显示**
   - auto 模式显示 Settings2 图标
   - 其他清晰度显示大写标签（1080P、720P）

2. **菜单交互**
   - 点击按钮打开/关闭菜单
   - 点击遮罩关闭菜单
   - 点击菜单项触发回调并关闭菜单

3. **高亮状态**
   - 当前清晰度显示 active 样式
   - 其他清晰度显示普通样式

4. **边界情况**
   - qualities 列表为空
   - currentQuality 为 null
   - 只有一个清晰度选项

**集成测试要点：**
```dart
testWidgets('QualitySelector integrates with PlayerController', (tester) async {
  final controller = PlayerController();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<PlayerController>(
          create: (_) => controller,
          child: Consumer<PlayerController>(
            builder: (context, controller, _) {
              return QualitySelector(controller: controller);
            },
          ),
        ),
      ),
    ),
  );

  // 模拟清晰度列表
  controller._handleQualityChanged({
    'qualities': [
      {'description': '自动', 'value': 'auto', 'isAvailable': true},
      {'description': '1080P 高清', 'value': '1080p', 'isAvailable': true},
    ],
    'currentIndex': 0,
  });
  await tester.pump();

  // 验证显示
  expect(find.byIcon(Icons.settings), findsOneWidget);
});
```

### Previous Story Intelligence (Epic 2)

**从 Epic 2 学到的关键经验：**

1. **Widget 测试最佳实践**
   - 使用 `pumpAndSettle()` 等待动画完成
   - 使用 `find.text()` / `find.byType()` 精确定位元素
   - 测试回调函数被正确调用

2. **Consumer 模式**
   ```dart
   // 正确模式：在 Widget 树中使用 Consumer
   Consumer<PlayerController>(
     builder: (context, controller, child) {
       return QualitySelector(
         qualities: controller.qualities,
         currentQuality: controller.currentQuality,
         onQualityChange: (index) => controller.setQuality(index),
       );
     },
   )
   ```

3. **状态管理**
   - 使用 StatefulWidget 管理组件内部状态（_isOpen）
   - 使用 Provider 管理全局状态（清晰度列表）

4. **性能优化**
   - 使用 RepaintBoundary 隔离频繁重绘的组件
   - Consumer 应尽可能靠近使用的组件

### Git Intelligence Summary

**最近提交（Epic 2）：**
- `bf3c8d7` - Feat: Complete Story 2.3 - 缓冲进度显示验证
- `2e9d937` - Fix: Prevent slider jump during seek with time-based hold logic
- `cf2b12e` - Fix: Add 2-frame cooldown after drag end to prevent slider jump

**关键模式：**
- Story 2.1 建立了进度条组件模式（Slider + Consumer）
- Story 2.2 建立了时间显示组件模式
- Story 2.3 验证了数据流完整性

**本 Story 应用：**
- 使用类似的 Consumer 模式获取清晰度数据
- 使用类似的测试结构验证功能
- 参考 ControlBar 组件的按钮样式

### Latest Tech Information

**Flutter Dropdown 最佳实践：**
- 使用 Stack + Positioned 实现自定义下拉菜单
- 使用 GestureDetector 包裹遮罩层捕获点击事件
- 菜单应使用 Positioned(top/left) 相对于父组件定位

**Icon 映射：**
```dart
// auto 模式使用 Settings2 图标
// Material 对应：Icons.settings 或 Icons.tune
const Icon _autoIcon = Icon(
  Icons.tune,
  size: 18,
  color: Color(0xFFF5F5F5),
);
```

**Material 常用 Icon：**
```dart
Icons.tune               // 替代 Settings2
Icons.hd                 // 可选用于清晰度
Icons.settings           // 设置图标
Icons.check              // 选中标记
```

### Project Context Reference

**相关规范：**
- [命名约定 - project-context.md#1-dart-naming-conventions-strict](../project-context.md)
- [状态管理 - project-context.md#3-provider-state-management-pattern](../project-context.md)
- [颜色系统 - project-context.md#121-颜色系统](../project-context.md#121-颜色系统)
- [UI 原型参考 - project-context.md#10-ui-实现参考-critical](../project-context.md#10-ui-实现参考-critical)
- [图标映射 - project-context.md#124-图标映射-lucide--material](../project-context.md#124-图标映射-lucide--material)

**架构相关：**
- [Widget 组件化策略 - architecture.md#widget-组件化策略](../planning-artifacts/architecture.md#widget-组件化策略)
- [数据格式 - architecture.md#format-patterns](../planning-artifacts/architecture.md#format-patterns)

**Epic 相关：**
- [Epic 3: 播放增强功能](../planning-artifacts/epics.md#epic-3-播放增强功能) - Epic 级别目标
- [Story 3.1 详细需求](../planning-artifacts/epics.md#story-31-清晰度切换) - 本 Story 详细定义

### References

- [Epic 3: 播放增强功能](../planning-artifacts/epics.md#epic-3-播放增强功能)
- [Story 3.1 详细需求](../planning-artifacts/epics.md#story-31-清晰度切换)
- [架构文档 - Widget 组件化策略](../planning-artifacts/architecture.md#widget-组件化策略)
- [项目上下文 - 颜色系统](../project-context.md#121-颜色系统)
- [项目上下文 - 图标映射](../project-context.md#124-图标映射-lucide--material)
- [UI 原型 - QualitySelector](/Users/nick/projects/polyv/ios/polyv-vod/src/components/player/QualitySelector.tsx)
- [UI 原型 - PlayerControlButton](/Users/nick/projects/polyv/ios/polyv-vod/src/components/player/PlayerControlButton.tsx)
- [前置 Story - ControlBar](2-1-progress-bar.md) - 参考 ControlBar 组件结构
- [前置 Story - ProgressSlider](2-1-progress-bar.md) - 参考测试模式

## Dev Agent Record

### Agent Model Used

claude-opus-4-5-20251101

### Debug Log References

N/A - Story 创建阶段

### Completion Notes List

**Story 创建完成 - 2026-01-20**

**创建摘要：**
- 分析 Epic 3 上下文和 Story 3.1 详细需求
- 读取 HTML 原型参考 (QualitySelector.tsx)
- 分析现有代码库中的相关模式
- 创建完整的 Story 3.1 文档

**关键发现：**
1. **PlayerController 已支持清晰度功能**
   - `setQuality(int index)` 方法已实现
   - `qualities` 和 `currentQuality` getter 已存在
   - `qualityChanged` 事件处理器已实现
   - QualityItem 数据结构已定义

2. **原型分析完成**
   - QualitySelector 使用按钮 + 下拉菜单模式
   - auto 模式显示 Settings2 图标（Flutter: Icons.tune）
   - 清晰度标签映射：4k → "4K 超清", 1080p → "1080P 高清" 等
   - 菜单包含标题、清晰度列表、active 高亮

3. **组件设计确定**
   - 新建 `quality_selector/` 目录
   - 使用 StatefulWidget 管理 _isOpen 状态
   - 使用 Stack + Positioned 实现下拉菜单
   - 使用 GestureDetector 实现遮罩点击关闭

4. **开发重点**
   - 创建 QualitySelector Widget
   - 集成到 ControlBar
   - 编写 Widget 测试
   - 遵循原型视觉设计

**下一步行动：**
1. 创建 quality_selector.dart 组件文件
2. 实现按钮和下拉菜单 UI
3. 集成到 ControlBar
4. 编写测试验证功能

### File List

**新增文件：**
- `docs/implementation-artifacts/3-1-quality-selector.md` - 本 Story 文档
- `polyv_media_player/example/lib/player_skin/player_colors.dart` - 播放器颜色常量（共享）
- `polyv_media_player/example/lib/player_skin/quality_selector/quality_selector.dart` - 清晰度选择器组件（独立按钮模式）
- `polyv_media_player/example/lib/player_skin/quality_selector/settings_menu.dart` - 设置菜单组件（底部弹出模式）
- `polyv_media_player/example/lib/player_skin/quality_selector/quality_selector_test.dart` - Widget 测试
- `polyv_media_player/test/models/quality_item_test.dart` - QualityItem 单元测试
- `polyv_media_player/test/models/subtitle_item_test.dart` - SubtitleItem 单元测试

**修改文件：**
- `polyv_media_player/example/lib/player_skin/control_bar.dart` - 使用共享 PlayerColors
- `polyv_media_player/example/lib/player_skin/control_bar_test.dart` - 添加集成测试
- `polyv_media_player/example/lib/pages/home_page.dart` - "更多"按钮打开 SettingsMenu
- `polyv_media_player/test/support/test_data.dart` - 添加 QualityTestData 和 SubtitleTestData 工厂
- `docs/implementation-artifacts/sprint-status.yaml` - 更新状态为 in-progress

**参考文件（无需修改）：**
- `polyv_media_player/lib/core/player_controller.dart` - setQuality() 已实现
- `polyv_media_player/lib/core/player_events.dart` - QualityItem 已定义
- `/Users/nick/projects/polyv/ios/polyv-vod/src/components/player/QualitySelector.tsx` - UI 原型

## Change Log

**2026-01-20 - Story 实现完成**

**新增功能：**
- 创建 QualitySelector 组件，支持清晰度切换
- 实现按钮 + 下拉菜单 UI 模式
- 支持自动模式（显示 Icons.tune 图标）
- 清晰度标签映射：4k → "4K 超清", 1080p → "1080P 高清", 720p → "720P 标清", 480p → "480P 流畅", 360p → "360P 极速"
- 点击遮罩关闭菜单功能
- 当前选中项高亮显示

**集成变更：**
- 将 QualitySelector 集成到 ControlBar
- 使用 ListenableBuilder 响应 PlayerController 状态变化
- 调用 controller.setQuality(index) 切换清晰度

**测试：**
- 添加 QualitySelector Widget 测试
- 添加 QualityItem 单元测试
- 添加 ControlBar QualitySelector 集成测试
- 所有 185 个测试通过

**2026-01-20 - 底部菜单实现（参考原型 MobilePortraitMenu.tsx）**

**新增功能：**
- 创建 SettingsMenu 底部弹出组件，精确参考原型 MobilePortraitMenu.tsx 设计
- 点击 "更多" 按钮（Icons.more_horiz_rounded）打开设置菜单
- 清晰度选择以底部弹出菜单形式展示
- 不可用清晰度显示锁定图标和禁用状态
- 添加倍速选择占位实现（待后续 Story 完成）

**新增文件：**
- `polyv_media_player/example/lib/player_skin/quality_selector/settings_menu.dart` - 底部弹出菜单组件

**2026-01-20 - 代码审查修复**

**代码质量改进：**
- 创建共享的 PlayerColors 类，消除颜色定义重复
- 添加禁用状态视觉反馈（Opacity 0.4）
- 将 QualityItem 和 SubtitleItem 单元测试移至独立的 test/models/ 目录
- 改进 Widget 测试质量，添加不透明度验证、尺寸验证等

**新增文件：**
- `polyv_media_player/example/lib/player_skin/player_colors.dart` - 播放器颜色常量
- `polyv_media_player/test/models/quality_item_test.dart` - QualityItem 单元测试
- `polyv_media_player/test/models/subtitle_item_test.dart` - SubtitleItem 单元测试
