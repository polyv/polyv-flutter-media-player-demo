# Story 7.1: 全屏切换

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

作为最终用户，
我想要切换全屏模式，
以便获得沉浸式观看体验。

## Acceptance Criteria

### 场景 1: 全屏按钮触发切换

**Given** 视频正在播放
**When** 点击全屏按钮
**Then** 播放器进入全屏模式
**And** 控制栏在全屏模式下保持可访问
**When** 再次点击全屏按钮（或返回）
**Then** 退出全屏模式
**And** 播放器恢复正常大小

### 场景 2: 竖屏全屏（Portrait Full）

**Given** 视频正在竖屏半屏模式播放
**When** 用户点击全屏按钮
**Then** 视频进入竖屏全屏模式
**And** 状态栏和导航栏隐藏（沉浸式）
**And** 控制栏保持可访问
**And** 弹幕层继续正常显示

### 场景 3: 横屏全屏（Landscape Full）

**Given** 视频正在播放
**When** 用户触发横屏全屏（按钮或设备旋转）
**Then** 屏幕方向切换到横屏
**Then** 视频填满整个屏幕
**And** 系统UI隐藏（状态栏、导航栏）
**And** 控制栏布局适配横屏

### 场景 4: 全屏模式下的控制栏

**Given** 播放器处于全屏模式
**When** 用户单击视频区域
**Then** 控制栏显示/隐藏切换
**And** 控制栏自动隐藏机制正常工作（3.5秒后隐藏）
**And** 横屏模式下显示额外的控制选项（锁屏、弹幕开关、字幕、清晰度、倍速）

### 场景 5: 锁屏功能（横屏）

**Given** 播放器处于横屏全屏模式
**When** 用户点击锁屏按钮
**Then** 锁屏图标变为锁定状态
**And** 控制栏隐藏
**And** 手势操作被禁用（除解锁点击）
**When** 用户点击锁屏区域
**Then** 解锁屏幕
**And** 控制栏恢复可访问

### 场景 6: 退出全屏

**Given** 播放器处于全屏模式
**When** 用户点击退出全屏按钮（或返回按钮）
**Then** 退出全屏模式
**And** 屏幕方向恢复到竖屏
**And** 系统UI恢复显示
**And** 播放状态保持不变
**And** 视频进度保持不变

### 场景 7: 设备旋转响应

**Given** 播放器处于全屏模式
**When** 用户旋转设备
**Then** 播放器自适应新的屏幕方向
**And** 视频保持全屏显示
**And** 控制栏布局适配新方向

### 场景 8: 应用生命周期处理

**Given** 播放器处于全屏模式
**When** 应用进入后台（Home键、锁屏）
**Then** 保持全屏状态记录
**When** 应用返回前台
**Then** 根据记录恢复全屏状态
**Or** 如果配置了自动退出，则退出全屏

## Tasks / Subtasks

- [ ] 实现全屏状态管理
  - [ ] 创建 `FullscreenController` 管理全屏状态
  - [ ] 定义全屏模式枚举（竖屏半屏、竖屏全屏、横屏全屏）
  - [ ] 实现状态切换逻辑
  - [ ] 集成到 `PlayerController` 状态流

- [ ] 实现屏幕方向控制
  - [ ] 使用 `SystemChrome.setPreferredOrientations` 控制方向
  - [ ] 实现横竖屏切换方法
  - [ ] 处理方向变化事件
  - [ ] 支持自动旋转配置

- [ ] 实现系统UI控制
  - [ ] 实现沉浸式模式（隐藏状态栏、导航栏）
  - [ ] 使用 `SystemUiMode` 控制系统UI
  - [ ] 处理系统UI恢复（退出全屏时）

- [ ] 实现全屏UI布局
  - [ ] 创建横屏布局组件
  - [ ] 适配控制栏到横屏模式
  - [ ] 实现横屏特有的控制选项（锁屏、弹幕等）
  - [ ] 实现顶部栏（返回按钮、标题）

- [ ] 实现锁屏功能
  - [ ] 创建锁屏状态管理
  - [ ] 实现锁屏按钮UI
  - [ ] 禁用锁屏后的手势操作
  - [ ] 实现解锁交互

- [ ] 实现控制栏自动隐藏
  - [ ] 在全屏模式下启用3.5秒自动隐藏
  - [ ] 用户交互时重置计时器
  - [ ] 锁屏模式下禁用自动隐藏

- [ ] 实现应用生命周期集成
  - [ ] 监听应用前后台切换
  - [ ] 保存和恢复全屏状态
  - [ ] 处理从画中画返回的情况

- [ ] 测试与验证
  - [ ] 单元测试：全屏状态转换
  - [ ] 集成测试：横竖屏切换流程
  - [ ] UI测试：控制栏适配
  - [ ] 手势测试：锁屏后手势禁用
  - [ ] 生命周期测试：前后台切换

## Dev Notes

### Story Context

- 所属Epic: Epic 7 高级交互功能
- 前置依赖: Epic 1-6（播放器核心功能已完成）
- 后续Story: 7-2 单击暂停/播放、7-3 双击全屏、7-4 滑动手势
- 这是Epic 7的第一个Story，建立全屏基础架构

### Architecture Compliance

- **UI组件位置**: `polyv_media_player/example/lib/player_skin/fullscreen/`
- **业务逻辑**: 在Demo App层实现，通过Flutter系统API控制全屏
- **状态管理**: 使用Provider + ChangeNotifier模式
- **Phase 1分层**: UI层在Demo App，播放核心在Plugin

### UI实现参考（CRITICAL）

**必须先读取原型代码再实现！**

| 组件 | 原型文件路径 |
|------|-------------|
| 播放器全屏 | `/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/DemoVideoPlayer.tsx` |

**原型中的全屏实现关键点：**
```typescript
// 全屏状态
const [isFullscreen, setIsFullscreen] = useState(false);
const [showControls, setShowControls] = useState(true);
const [isLocked, setIsLocked] = useState(false);

// 全屏切换
const toggleFullscreen = () => {
  setIsFullscreen(!isFullscreen);
};

// 自动隐藏控制栏
useEffect(() => {
  if (isPlaying && showControls && !isLocked) {
    const timer = setTimeout(() => setShowControls(false), 3500);
    return () => clearTimeout(timer);
  }
}, [isPlaying, showControls, isLocked]);

// 锁屏
{isLocked && (
  <button onClick={() => setIsLocked(false)}>
    <Lock className="w-6 h-6" />
  </button>
)}
```

**横屏布局CSS：**
```css
/* 横屏时旋转容器 */
.landscape-fullscreen {
  transform: rotate(90deg);
  transform-origin: center center;
  width: 100vh;
  height: 100vw;
}
```

### 原生Demo参考逻辑

**iOS Demo:** `/Users/nick/projects/polyv/ios/polyv-ios-media-player-sdk-demo/PLViOSMediaPlayerDemo/`

**iOS全屏实现关键点：**
```objc
// 全屏类型定义
typedef NS_ENUM(NSUInteger, PLVMediaAreaBaseSkinViewType) {
    PLVMediaAreaBaseSkinViewType_Portrait_Full = 1,   // 竖向-全屏
    PLVMediaAreaBaseSkinViewType_Portrait_Half = 2,  // 竖向-半屏
    PLVMediaAreaBaseSkinViewType_Landscape_Full = 3   // 横向-全屏
};

// 全屏切换
- (void)changeToLandscape {
    [PLVVodMediaOrientationUtil changeUIOrientation:UIDeviceOrientationLandscapeLeft];
}

- (void)changeToProtrait {
    [PLVVodMediaOrientationUtil changeUIOrientation:UIDeviceOrientationPortrait];
}

// iOS 16+ API
if (@available(iOS 16.0, *)) {
    UIWindowScene *windowScene = (UIWindowScene *)[UIApplication sharedApplication].connectedScenes.anyObject;
    UIWindowSceneGeometryPreferencesIOS *preferences = [[UIWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations:orientationMask];
    [windowScene requestGeometryUpdateWithPreferences:preferences errorHandler:nil];
} else {
    [[UIDevice currentDevice] setValue:@(orientation) forKey:@"orientation"];
    [UIViewController attemptRotationToDeviceOrientation];
}

// 锁屏状态管理
@property (nonatomic, assign) BOOL isLocking;

- (void)mediaPlayerSkinLockScreenView_unlockScreenEvent:(PLVMediaPlayerSkinLockScreenView *)lockScreenView {
    self.mediaPlayerState.isLocking = NO;
    [self.lockScreenView removeFromSuperview];
}
```

**Android Demo:** `/Users/nick/projects/polyv/android/polyv-android-media-player-sdk-demo/`

**Android全屏实现关键点：**
```kotlin
// 方向管理器
PLVActivityOrientationManager.on(this)
    .setFollowSystemAutoRotate(true)
    .requestOrientation(false)  // false = 横屏

// 状态栏和导航栏控制
private fun updateWindowInsets() {
    if (isPortrait()) {
        showStatusBar(this)
        showNavigationBar(this)
    } else {
        hideStatusBar(this)
        hideNavigationBar(this)
    }
}

// 横屏锁定
fun onBackPressed(): Boolean {
    if (isLandscape()) {
        PLVActivityOrientationManager.on((context as AppCompatActivity))
            .requestOrientation(true)  // 返回竖屏
            .setLockOrientation(false)
        return true
    }
    return false
}

// 控制栏自动隐藏
fun showControllerForDuration(duration: Duration) {
    showControllerForDurationJob?.cancel()
    viewState = viewState.copy(controllerVisible = true)
    showControllerForDurationJob = PLVMediaPlayerGlobalCoroutineScope.launch(Dispatchers.Main) {
        delay(duration.toMillis())
        viewState = viewState.copy(controllerVisible = false)
    }
}
```

### 颜色系统（来自project-context.md）

```dart
// 播放器专用色
class PlayerColors {
  static const Color background = Color(0xFF121621);       // 最深层
  static const Color surface = Color(0xFF1E2432);          // 面板/弹窗
  static const Color controls = Color(0xFF2D3548);         // 控件背景
  static const Color progress = Color(0xFFE8704D);         // 已播放
  static const Color text = Color(0xFFF5F5F5);             // 主文字
  static const Color textMuted = Color(0xFF8B919E);        // 次要文字
}
```

### 项目结构

```
polyv_media_player/example/lib/
├── player_skin/
│   ├── fullscreen/
│   │   ├── fullscreen_controller.dart     # 全屏状态控制器
│   │   ├── fullscreen_overlay.dart        # 全屏覆盖层
│   │   ├── landscape_controls.dart        # 横屏控制栏
│   │   ├── lock_button.dart               # 锁屏按钮
│   │   └── top_bar.dart                   # 顶部栏（返回+标题）
│   ├── control_bar/
│   │   └── control_bar_state_machine.dart  # 已有：状态机
│   └── ...
└── pages/
    └── home_page.dart                      # 更新：集成全屏功能
```

### 全屏状态管理设计

```dart
// 全屏模式枚举
enum FullscreenMode {
  portraitHalf,    // 竖屏半屏（默认）
  portraitFull,    // 竖屏全屏
  landscapeFull,   // 横屏全屏
}

// 全屏状态
class FullscreenState {
  final FullscreenMode mode;
  final bool isLocked;
  final bool showControls;

  const FullscreenState({
    this.mode = FullscreenMode.portraitHalf,
    this.isLocked = false,
    this.showControls = true,
  });

  FullscreenState copyWith({
    FullscreenMode? mode,
    bool? isLocked,
    bool? showControls,
  }) {
    return FullscreenState(
      mode: mode ?? this.mode,
      isLocked: isLocked ?? this.isLocked,
      showControls: showControls ?? this.showControls,
    );
  }
}

// 全屏控制器
class FullscreenController extends ChangeNotifier {
  FullscreenState _state = const FullscreenState();

  FullscreenState get state => _state;

  /// 进入竖屏全屏
  Future<void> enterPortraitFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _updateState(_state.copyWith(mode: FullscreenMode.portraitFull));
  }

  /// 进入横屏全屏
  Future<void> enterLandscapeFullscreen() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _updateState(_state.copyWith(mode: FullscreenMode.landscapeFull));
  }

  /// 退出全屏
  Future<void> exitFullscreen() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _updateState(const FullscreenState());
  }

  /// 切换全屏
  Future<void> toggleFullscreen() async {
    if (_state.mode == FullscreenMode.portraitHalf) {
      await enterPortraitFullscreen();
    } else {
      await exitFullscreen();
    }
  }

  /// 锁定/解锁屏幕
  void toggleLock() {
    _updateState(_state.copyWith(isLocked: !_state.isLocked));
  }

  /// 显示/隐藏控制栏
  void toggleControls() {
    if (!_state.isLocked) {
      _updateState(_state.copyWith(showControls: !_state.showControls));
    }
  }

  /// 自动隐藏控制栏
  void startAutoHideTimer() {
    if (_state.isLocked) return;
    // 延迟3.5秒后隐藏
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (_state.showControls && !_state.isLocked) {
        _updateState(_state.copyWith(showControls: false));
      }
    });
  }

  void _updateState(FullscreenState newState) {
    _state = newState;
    notifyListeners();
  }
}
```

### LongVideoPage集成

```dart
class _LongVideoPageState extends State<LongVideoPage> with WidgetsBindingObserver {
  late final PlayerController _playerController;
  late final FullscreenController _fullscreenController;

  @override
  void initState() {
    super.initState();
    _playerController = context.read<PlayerController>();
    _fullscreenController = FullscreenController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fullscreenController.dispose();
    super.dispose();
  }

  // 应用生命周期监听
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // 应用返回前台，恢复全屏状态
        if (_fullscreenController.state.mode != FullscreenMode.portraitHalf) {
          _fullscreenController.enterLandscapeFullscreen();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // 应用进入后台，保持状态
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _fullscreenController,
      child: Consumer<FullscreenController>(
        builder: (context, fullscreen, child) {
          return fullscreen.state.mode == FullscreenMode.portraitHalf
              ? _buildPortraitPlayer()
              : _buildFullscreenPlayer();
        },
      ),
    );
  }

  Widget _buildPortraitPlayer() {
    // 竖屏半屏播放器（现有实现）
    return ...
  }

  Widget _buildFullscreenPlayer() {
    // 全屏播放器
    return FullscreenOverlay(
      playerController: _playerController,
      fullscreenController: _fullscreenController,
    );
  }
}
```

### 全屏覆盖层组件

```dart
class FullscreenOverlay extends StatelessWidget {
  final PlayerController playerController;
  final FullscreenController fullscreenController;

  const FullscreenOverlay({
    Key? key,
    required this.playerController,
    required this.fullscreenController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<FullscreenController>(
      builder: (context, fullscreen, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: fullscreen.toggleControls,
            child: Stack(
              children: [
                // 视频渲染层
                PolyvVideoView(controller: playerController),

                // 弹幕层
                if (playerController.danmakuEnabled)
                  DanmakuLayer(...),

                // 控制栏覆盖层
                if (fullscreen.state.showControls)
                  fullscreen.state.mode == FullscreenMode.landscapeFull
                      ? LandscapeControls(...)
                      : PortraitFullscreenControls(...),

                // 锁屏按钮（横屏时始终显示）
                if (fullscreen.state.isLocked)
                  Positioned(
                    left: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: LockButton(
                        isLocked: true,
                        onTap: fullscreen.toggleLock,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

### 关键技术决策

| 决策项 | 选择 | 理由 |
|--------|------|------|
| 全屏模式 | 竖屏半屏/竖屏全屏/横屏全屏 | 与iOS原生实现保持一致 |
| 方向控制 | SystemChrome.setPreferredOrientations | Flutter标准API |
| 系统UI控制 | SystemUiMode.immersiveSticky | 沉浸式体验 |
| 状态管理 | 独立FullscreenController | 职责分离，便于复用 |
| 生命周期 | WidgetsBindingObserver | 标准生命周期监听 |
| 自动隐藏 | 延迟3.5秒 | 与原型保持一致 |

### 已有基础设施复用

- `PlayerController` - 播放器控制
- `ControlBarStateMachine` - 控制栏状态机
- `DanmakuLayer` - 弹幕显示层
- `PlayerColors` - 颜色常量
- `PolyvVideoView` - 视频渲染组件

### 迁移策略

1. **第一步**：创建`FullscreenController`和状态模型
2. **第二步**：实现基础的竖屏全屏切换
3. **第三步**：实现横屏全屏和方向控制
4. **第四步**：实现横屏控制栏布局
5. **第五步**：实现锁屏功能
6. **第六步**：集成应用生命周期处理
7. **第七步**：完善测试和边界情况处理

### 测试场景

| 场景 | 预期行为 |
|------|----------|
| 点击全屏按钮 | 进入竖屏全屏模式 |
| 点击退出全屏 | 恢复竖屏半屏模式 |
| 横屏时点击锁定 | 控制栏隐藏，手势禁用 |
| 锁定后点击锁屏按钮 | 解锁，控制栏恢复 |
| 播放时3.5秒无操作 | 控制栏自动隐藏 |
| 单击视频区域 | 控制栏显示/隐藏切换 |
| 应用后台后恢复 | 保持全屏状态 |
| 旋转设备 | 自适应新方向 |

### 边界情况处理

1. **视频切换时**：如果处于全屏模式，保持全屏状态
2. **播放结束时**：不自动退出全屏（用户可手动退出）
3. **错误发生时**：保持全屏状态，显示错误提示
4. **画中画进入**：考虑是否退出全屏（可选配置）
5. **设备旋转锁定**：检测系统旋转锁定，提供用户提示

### 平台差异处理

| 功能 | iOS | Android | Flutter统一处理 |
|------|-----|---------|----------------|
| 方向控制 | UIDevice orientation | Activity orientation | SystemChrome.setPreferredOrientations |
| 系统UI | prefersStatusBarHidden | WindowInsetsController | SystemUiMode |
| 全屏手势 | 系统默认 | 系统默认 | 使用GestureDetector |

### 性能考虑

1. **方向切换**：使用动画平滑过渡
2. **控制栏渲染**：使用`Opacity`而非`Visibility`提升性能
3. **状态更新**：使用`notifyListeners()`的防抖
4. **生命周期**：及时dispose避免内存泄漏

### 可访问性

1. 为全屏按钮添加Semantics标签
2. 支持系统辅助功能的全屏操作
3. 横屏模式下的语音提示优化

## References

- `docs/planning-artifacts/epics.md#epic-7-高级交互功能` - Epic 7上下文
- `docs/planning-artifacts/architecture.md#project-structure--boundaries` - 架构边界
- `docs/project-context.md#ui-实现参考-critical` - UI开发流程
- `/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/DemoVideoPlayer.tsx` - 播放器原型
- `/Users/nick/projects/polyv/ios/polyv-ios-media-player-sdk-demo/PLViOSMediaPlayerDemo/` - iOS原生Demo
- `/Users/nick/projects/polyv/android/polyv-android-media-player-sdk-demo/` - Android原生Demo

## Dev Agent Record

### Agent Model Used

opus-4.5-20251101

### Debug Log References

### Completion Notes List

### File List
