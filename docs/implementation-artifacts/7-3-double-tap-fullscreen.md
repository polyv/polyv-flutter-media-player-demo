# Story 7.3: 双击全屏手势

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

作为最终用户，
我想要双击视频区域进入全屏模式，
以便快速切换全屏观看。

## Acceptance Criteria

### 场景 1: 竖屏模式下双击进入全屏

**Given** 视频正在竖屏模式播放
**When** 双击视频区域
**Then** 视频进入横屏全屏模式
**And** 控制栏保持显示
**And** 状态平滑过渡

### 场景 2: 横屏模式下双击退出全屏

**Given** 视频正在横屏全屏模式播放
**When** 双击视频区域
**Then** 退出全屏返回竖屏模式
**And** 控制栏保持显示

### 场景 3: 与单击手势的正确区分

**Given** 视频正在播放
**When** 单击视频区域
**Then** 显示/隐藏控制栏（Story 7-2 行为）
**And** 不会触发全屏切换
**When** 双击视频区域（300ms内）
**Then** 触发全屏切换
**And** 不触发单击行为

### 场景 4: 锁屏状态下双击

**Given** 横屏模式且屏幕已锁定
**When** 双击视频区域
**Then** 不响应全屏切换
**And** 保持锁屏状态

### 场景 5: 切换视频期间双击

**Given** 视频正在切换中
**When** 双击视频区域
**Then** 忽略双击（不响应）

### 场景 6: 全屏切换后的状态保持

**Given** 视频正在播放
**When** 双击进入全屏
**Then** 播放状态保持不变
**And** 视频进度保持不变
**And** 其他设置（清晰度、倍速等）保持不变

## Tasks / Subtasks

- [x] 实现双击手势检测器
  - [x] 创建 DoubleTapDetector 组件
  - [x] 实现单击/双击区分逻辑（300ms 延迟）
  - [x] 处理与单击手势的冲突
  - [x] 添加双击视觉反馈动画

- [x] 实现全屏切换逻辑
  - [x] 竖屏 → 横屏全屏切换
  - [x] 横屏全屏 → 竖屏切换
  - [x] 状态保持（播放状态、进度、设置）
  - [x] 与现有全屏按钮逻辑复用

- [x] 集成到控制栏状态机
  - [x] 全屏切换时重置自动隐藏计时器
  - [x] 确保状态转换平滑
  - [x] 处理边缘情况（锁屏、切换中）

- [x] 测试与验证
  - [x] 单元测试：双击检测逻辑
  - [x] 集成测试：全屏切换功能
  - [x] UI测试：双击视觉反馈
  - [x] 边缘场景测试：锁屏、切换中

## Dev Notes

### Story Context

- 所属Epic: Epic 7 高级交互功能
- 前置依赖: Story 7.1（全屏切换）、Story 7.2（单击暂停/播放）
- 后续Story: 7-4 滑动手势

### 当前实现状态

**已实现：**
- ✅ 全屏切换按钮（`_buildFullscreenButton()`）
- ✅ 单击手势检测（`GestureDetector.onTap`）
- ✅ 控制条状态机（`ControlBarStateMachine`）
- ✅ 横竖屏切换逻辑（`_toggleFullscreen()`）

**需要新增：**
- ❌ 双击手势检测器
- ❌ 单击/双击区分逻辑
- ❌ 双击全屏切换行为
- ❌ 双击视觉反馈

### Architecture Compliance

- **UI组件位置**: `polyv_media_player/example/lib/pages/home_page.dart`
- **状态管理**: 使用Provider + ChangeNotifier模式
- **状态机**: 使用现有的`ControlBarStateMachine`
- **业务逻辑归属**: 遵循架构文档中的"Flutter层统一业务逻辑"原则

### UI实现参考（CRITICAL）

**必须先读取原型代码再实现！**

| 组件 | 原型文件路径 |
|------|-------------|
| 播放器（含双击逻辑） | `/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/DemoVideoPlayer.tsx` |

**原型中的双击实现关键点：**
```typescript
// 单击/双击区分逻辑
const lastTapRef = useRef<{ time: number; x: number } | null>(null);

const handleTap = useCallback(
  (e: React.MouseEvent) => {
    if (isLocked) {
      setShowControls(true);
      return;
    }

    const now = Date.now();
    const x = e.clientX;
    const containerWidth = containerRef.current?.clientWidth || 1;

    if (lastTapRef.current && now - lastTapRef.current.time < 300) {
      // 双击逻辑 - 切换全屏
      setIsFullscreen((prev) => !prev);
      lastTapRef.current = null;
    } else {
      lastTapRef.current = { time: now, x };
      setTimeout(() => {
        if (lastTapRef.current?.time === now) {
          // 单击逻辑 - 显示/隐藏控制栏
          setShowControls((prev) => !prev);
        }
      }, 300);
    }
  },
  [isLocked]
);
```

### 原生Demo参考逻辑

**iOS Demo:** `/Users/nick/projects/polyv/ios/polyv-ios-media-player-sdk-demo/PLViOSMediaPlayerDemo/`

**iOS关键发现：**
- iOS Demo 中的双击手势被实现为**播放/暂停切换**，而非全屏切换
- 全屏切换通过专门的**全屏按钮**实现
- 双击手势使用 `UITapGestureRecognizer`，`numberOfTapsRequired = 2`

```objc
// iOS 双击手势（实际是播放/暂停）
- (void)tapGestureAction:(UITapGestureRecognizer *)tapGR {
    if (tapGR.numberOfTapsRequired == 2) {
        // 双击处理 - 播放/暂停切换
        BOOL wannaPlay = !self.playButton.selected;
        [self.baseDelegate plvMediaAreaBaseSkinViewPlayButtonClicked:self wannaPlay:wannaPlay];
    }
}

// 全屏切换（通过按钮，不是双击）
- (void)fullScreenButtonAction:(UIButton *)button {
    [self.baseDelegate plvMediaAreaBaseSkinViewFullScreenOpenButtonClicked:self];
}

// 全屏按钮点击 → 切换屏幕方向
- (void)changeToLandscape {
    [PLVVodMediaOrientationUtil changeUIOrientation:UIDeviceOrientationLandscapeLeft];
}
```

**Android Demo:** `/Users/nick/projects/polyv/android/polyv-android-media-player-sdk-demo/`

**Android关键实现：**
- Android 同样将双击实现为**播放/暂停切换**
- 使用自定义的 `PLVOnDoubleClickListener` 实现单击/双击区分
- 双击检测延迟：`DELAY_DOUBLE_CLICK_CHECK = 200ms`

```kotlin
// Android 自定义双击监听器
private fun setOnClickListener() {
    setOnClickListener(object : PLVOnDoubleClickListener() {
        override fun onSingleClick() {
            // 单击：切换控制栏显示
            val controllerViewModel = dependScope.get(PLVMPMediaControllerViewModel::class.java)
            controllerViewModel.onClickChangeControllerVisible()
        }

        override fun onDoubleClick() {
            // 双击：切换播放/暂停（注意：不是全屏）
            val mediaViewModel = dependScope.get(PLVMPMediaViewModel::class.java)
            val viewState = mediaViewModel.mediaPlayViewState.value ?: return
            if (viewState.isPlaying) {
                mediaViewModel.pause()
            } else {
                mediaViewModel.start()
            }
        }
    })
}
```

### 关键差异说明

| 功能 | 原型(React) | iOS原生 | Android原生 | 当前Flutter | 目标 |
|------|------------|---------|-------------|------------|------|
| 双击行为 | 全屏切换 | 播放/暂停 | 播放/暂停 | 未实现 | 全屏切换 |
| 单击行为 | 控制栏 | 控制栏 | 控制栏 | 播放/暂停+控制栏 | 控制栏 |
| 双击检测延迟 | 300ms | N/A | 200ms | N/A | 300ms |

**重要决策：**
- 本Story按照**Epic 7-3的需求**实现双击全屏切换
- Story 7-2已将单击实现为播放/暂停切换（与原生端不同）
- 保持与原型的一致性，双击用于全屏切换

### 双击手势检测器设计

**方案选择：Flutter GestureDetector vs 自定义延迟逻辑**

由于需要精确控制单击/双击行为，且单击已有Story 7-2定义的行为，使用自定义延迟逻辑：

```dart
class DoubleTapDetector extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final Widget child;
  final Duration doubleTapDelay;

  const DoubleTapDetector({
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.doubleTapDelay = const Duration(milliseconds: 300),
  });

  @override
  State<DoubleTapDetector> createState() => _DoubleTapDetectorState();
}

class _DoubleTapDetectorState extends State<DoubleTapDetector> {
  int? _lastTapTime;
  Timer? _doubleTapTimer;

  void _handleTap() {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (_lastTapTime != null && now - _lastTapTime! < widget.doubleTapDelay.inMilliseconds) {
      // 双击
      _doubleTapTimer?.cancel();
      _lastTapTime = null;
      widget.onDoubleTap?.call();
    } else {
      // 可能是单击，等待延迟确认
      _lastTapTime = now;
      _doubleTapTimer?.cancel();
      _doubleTapTimer = Timer(widget.doubleTapDelay, () {
        if (_lastTapTime == now) {
          widget.onTap?.call();
          _lastTapTime = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}
```

### 全屏切换逻辑复用

```dart
// 复用现有的 _toggleFullscreen() 方法
void _handleDoubleTap() {
  // 锁屏状态下不响应
  if (_isLocked) return;

  // 切换视频期间不响应
  if (_isSwitchingVideo) return;

  // 切换全屏
  _toggleFullscreen();

  // 显示控制栏并重置自动隐藏计时器
  _controlBarStateMachine.enterActive(
    autoHideTimeout: const Duration(seconds: 3),
  );
}
```

### 双击视觉反馈

参考原型和原生实现，添加双击时的视觉反馈：

```dart
// 双击时显示的缩放动画
Widget _buildDoubleTapFeedback() {
  if (!_showDoubleTapFeedback) return const SizedBox.shrink();

  return Positioned.fill(
    child: Center(
      child: AnimatedScale(
        scale: _showDoubleTapFeedback ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Icon(
          _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
          color: Colors.white.withValues(alpha: 0.8),
          size: 64,
        ),
      ),
    ),
  );
}
```

### 颜色系统（来自project-context.md）

```dart
// 播放器专用色
class PlayerColors {
  static const Color background = Color(0xFF121621);       // 最深层
  static const Color surface = Color(0xFF1E2432);          // 面板/弹窗
  static const Color controls = Color(0xFF2D3548);         // 控件背景
  static const Color text = Color(0xFFF5F5F5);             // 主文字
  static const Color textMuted = Color(0xFF8B919E);        // 次要文字
}
```

### 项目结构

```
polyv_media_player/example/lib/
├── pages/
│   └── home_page.dart                      # 更新：双击全屏逻辑
└── player_skin/
    ├── control_bar_state_machine.dart      # 已有：状态机
    ├── double_tap_detector.dart            # 新增：双击检测器组件
    └── control_bar_manager.dart            # 已有：控制栏管理器
```

### 已有基础设施复用

- `_toggleFullscreen()` - 全屏切换方法（Story 7.1）
- `ControlBarStateMachine` - 控制栏状态机
- `PlayerColors` - 颜色常量
- `_isFullscreen` - 全屏状态变量
- `_isLocked` - 锁屏状态变量

### 迁移策略

1. **第一步**：创建 `DoubleTapDetector` 组件
2. **第二步**：在视频区域替换现有的 `GestureDetector`
3. **第三步**：实现双击全屏切换逻辑
4. **第四步**：添加双击视觉反馈动画
5. **第五步**：处理边缘情况（锁屏、切换中）
6. **第六步**：测试各种场景

### 测试场景

| 场景 | 预期行为 |
|------|----------|
| 竖屏双击 | 进入横屏全屏，控制栏显示 |
| 横屏双击 | 退出全屏返回竖屏 |
| 单击 | 显示/隐藏控制栏，不切换全屏 |
| 快速双击（300ms内） | 触发双击，不触发单击 |
| 慢速两次单击（>300ms） | 两次单独的单击事件 |
| 锁屏时双击 | 不响应全屏切换 |
| 切换视频时双击 | 忽略双击 |
| 全屏切换后状态 | 播放状态、进度、设置保持不变 |

### 边界情况处理

1. **快速连续双击**：防止状态混乱，使用防抖机制
2. **单击/双击冲突**：使用300ms延迟区分
3. **锁屏状态**：禁用双击全屏功能
4. **切换视频期间**：忽略双击事件
5. **播放结束状态**：双击仍然可以切换全屏

### 与Story 7-2的交互

- Story 7-2实现了单击切换播放/暂停
- 本Story需要区分单击和双击行为
- 使用相同的300ms延迟机制区分

### 性能考虑

1. **Timer管理**：确保Timer正确清理，避免内存泄漏
2. **状态更新频率**：避免频繁setState
3. **动画性能**：使用`AnimatedScale`而非手动动画

### 关键技术决策

| 决策项 | 选择 | 理由 |
|--------|------|------|
| 双击行为 | 全屏切换 | 符合Epic 7-3需求 |
| 单/双击区分 | 300ms延迟 | 与原型保持一致 |
| 检测器实现 | 自定义DoubleTapDetector | 精确控制行为 |
| 视觉反馈 | 缩放动画+图标 | 与原型一致 |
| 全屏切换 | 复用_toggleFullscreen | 复用已有逻辑 |

## References

- `docs/planning-artifacts/epics.md#epic-7-高级交互功能` - Epic 7上下文
- `docs/planning-artifacts/architecture.md#项目结构--边界` - 架构边界
- `docs/planning-artifacts/architecture.md#业务逻辑归属原则` - Flutter层业务逻辑统一原则
- `docs/implementation-artifacts/7-2-tap-play-pause.md` - 前置Story
- `/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/DemoVideoPlayer.tsx` - 播放器原型
- `/Users/nick/projects/polyv/ios/polyv-ios-media-player-sdk-demo/PLViOSMediaPlayerDemo/` - iOS原生Demo
- `/Users/nick/projects/polyv/android/polyv-android-media-player-sdk-demo/` - Android原生Demo

## Latest Technical Information

### Flutter GestureDetector (2025)

根据最新的Flutter文档（2025年10月更新），Flutter的`GestureDetector`提供了以下手势处理能力：

**基本双击实现：**
```dart
GestureDetector(
  onDoubleTap: () {
    // 双击处理
  },
  onDoubleTapDown: (details) {
    // 第二次点击按下时触发
  },
  child: YourWidget(),
)
```

**注意事项：**
- 存在一个已知的[GitHub issue](https://github.com/flutter/flutter/issues/146061)关于Android上`onDoubleTap`的问题（2024年4月报告）
- 对于复杂的单击/双击区分，建议使用自定义延迟逻辑而非直接使用`onDoubleTap`

**Sources:**
- [Flutter官方手势文档](https://docs.flutter.dev/ui/interactivity/gestures)
- [GestureDetector API文档](https://api.flutter.dev/flutter/widgets/GestureDetector-class.html)
- [DoubleTapGestureRecognizer API](https://api.flutter.dev/flutter/gestures/DoubleTapGestureRecognizer-class.html)

## Dev Agent Record

### Agent Model Used

opus-4.5-20251101

### Debug Log References

### Completion Notes List

**实现日期:** 2026-01-25

**实现概述:**
1. 创建了 `DoubleTapDetector` 组件，实现了精确的单击/双击区分逻辑（300ms 延迟）
2. 在 `home_page.dart` 中集成双击检测器，替换了原有的 `GestureDetector`
3. 实现了 `_handleDoubleTap()` 方法处理双击全屏切换
4. 添加了 `_buildDoubleTapFeedback()` 方法提供视觉反馈（缩放动画+全屏图标）
5. 全屏切换复用了现有的 `_toggleFullscreen()` 方法
6. 处理了锁屏状态和切换视频期间的边缘情况
7. 编写了 7 个单元测试，全部通过

**技术要点:**
- 使用自定义延迟逻辑而非 Flutter 的 `onDoubleTap`，以精确控制行为
- Timer 正确清理，避免内存泄漏
- 双击视觉反馈使用 `AnimatedScale` 实现平滑动画
- 单击行为（播放/暂停切换）与双击行为（全屏切换）完全分离

### File List

**新增文件:**
- `polyv_media_player/example/lib/player_skin/double_tap_detector.dart` - 双击手势检测器组件
- `polyv_media_player/example/lib/test/player_skin/double_tap_detector_test.dart` - 双击检测器单元测试
- `polyv_media_player/example/lib/test/player_skin/double_tap_fullscreen_integration_test.dart` - 全屏切换集成测试

**修改文件:**
- `polyv_media_player/example/lib/pages/home_page.dart` - 集成双击检测器和全屏切换逻辑

### Change Log

- 2026-01-25: 实现双击全屏切换功能
- 2026-01-25: 代码审查修复 - 更新 Story File List、重构集成测试、统一双击延迟配置

## Senior Developer Review (AI)

### Review Date
2026-01-25

### Review Summary
对 Story 7-3 进行了 ADVERSARIAL 代码审查，发现并修复了以下问题：

#### 🔴 HIGH Issues (已修复)

1. **Story File List 缺少新增的集成测试文件** - `double_tap_fullscreen_integration_test.dart` 未记录
   - **修复**: 更新 File List 包含集成测试文件

2. **集成测试与单元测试高度重复** - 原集成测试只测试了 `DoubleTapDetector` 组件本身
   - **修复**: 重构集成测试，添加真正的全屏切换场景测试（AC 场景 1-6）
   - **新增测试**: 14 个测试用例覆盖所有 AC 场景和边界情况

#### 🟡 MEDIUM Issues (已修复)

3. **双击视觉反馈动画时间与双击延迟不同步** - 两处硬编码 300ms
   - **修复**: 在 `DoubleTapDetector` 添加 `defaultDoubleTapDelay` 常量，`home_page.dart` 使用该常量

4. **集成测试文件中未使用的导入** - `import 'package:flutter/services.dart';` 和 `import 'package:polyv_media_player/polyv_media_player.dart';` 未使用
   - **修复**: 移除未使用的导入

### Test Results
- 单元测试: 7 个测试全部通过 ✅
- 集成测试: 14 个测试全部通过 ✅
- 代码分析: 无警告 ✅

### Review Outcome
✅ **APPROVED** - 所有问题已修复，代码质量符合要求，所有验收场景已覆盖。
