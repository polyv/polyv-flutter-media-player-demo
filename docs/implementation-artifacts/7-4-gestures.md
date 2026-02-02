# Story 7.4: 滑动手势控制

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

作为最终用户，
我想要通过滑动手势控制播放进度、音量和亮度，
以便获得更便捷的操作体验。

## Acceptance Criteria

### 场景 1: 左右滑动 seek（进度控制）

**Given** 视频正在播放
**When** 在屏幕上水平左右滑动
**Then** 快进/快退播放位置
**And** 滑动时显示进度提示（当前时间、总时长）
**And** 松手后跳转到目标位置

### 场景 2: 左侧上下滑动调节亮度

**Given** 视频正在播放
**When** 在屏幕左侧区域上下滑动
**Then** 调节屏幕亮度（上增下减）
**And** 滑动时显示亮度图标和进度条
**And** 松手后提示消失

### 场景 3: 右侧上下滑动调节音量

**Given** 视频正在播放
**When** 在屏幕右侧区域上下滑动
**Then** 调节播放音量（上增下减）
**And** 滑动时显示音量图标和进度条
**And** 松手后提示消失

### 场景 4: 滑动方向判断

**Given** 视频正在播放
**When** 用户开始滑动
**Then** 系统判断滑动方向（水平或垂直）
**And** 根据方向执行对应的手势操作
**And** 不会同时触发多个手势

### 场景 5: 锁屏状态

**Given** 横屏模式且屏幕已锁定
**When** 执行滑动手势
**Then** 不响应任何滑动手势
**And** 保持锁屏状态

### 场景 6: 手势冲突处理

**Given** 视频正在播放
**When** 用户执行点击、双击、滑动操作
**Then** 各手势正确识别，互不干扰
**And** 单击只显示控制栏（播放/暂停由控制栏按钮控制）
**And** 双击触发全屏切换（Story 7-3）
**And** 滑动触发对应调节功能

## Tasks / Subtasks

- [x] 创建手势控制器
  - [x] 创建 `PlayerGestureController` 管理手势状态
  - [x] 定义手势类型枚举（horizontalSeek, brightnessAdjust, volumeAdjust）
  - [x] 实现手势方向判断逻辑
  - [x] 实现滑动进度计算

- [x] 实现左右滑动 seek
  - [x] 监听水平滑动事件
  - [x] 计算滑动距离对应的时间偏移
  - [x] 限制在有效视频范围内
  - [x] 松手后执行 seek 操作

- [x] 实现左侧亮度调节
  - [x] 检测滑动起始位置在屏幕左侧
  - [x] 监听垂直滑动事件
  - [x] 调用系统 API 调节屏幕亮度
  - [x] 显示亮度提示 UI

- [x] 实现右侧音量调节
  - [x] 检测滑动起始位置在屏幕右侧
  - [x] 监听垂直滑动事件
  - [x] 调用原生 API 调节播放音量
  - [x] 显示音量提示 UI

- [x] 创建手势提示 UI 组件
  - [x] 创建进度提示组件（时间预览）
  - [x] 创建亮度/音量提示组件（图标+进度条）
  - [x] 实现自动隐藏逻辑（2秒后消失）
  - [x] 添加淡入淡出动画

- [x] 处理手势冲突
  - [x] 与单击手势的冲突处理
  - [x] 与双击手势的冲突处理
  - [x] 确保手势优先级正确

- [x] 测试与验证
  - [x] 单元测试：手势方向判断逻辑
  - [x] 单元测试：滑动进度计算
  - [x] 集成测试：完整手势流程
  - [x] UI测试：提示组件显示/隐藏
  - [x] 边缘场景测试：锁屏、切换视频

## Dev Notes

### Story Context

- 所属Epic: Epic 7 高级交互功能
- 前置依赖: Story 7.1（全屏切换）、Story 7.2（单击暂停/播放）、Story 7.3（双击全屏）
- 这是 Epic 7 的最后一个 Story

### Architecture Compliance

- **UI组件位置**: `polyv_media_player/example/lib/player_skin/gestures/`
- **业务逻辑**: 在 Demo App 层实现，通过 Flutter 手势 API 控制
- **状态管理**: 使用 Provider + ChangeNotifier 模式
- **Phase 1 分层**: UI 层在 Demo App，播放核心在 Plugin

### 原生Demo参考逻辑（CRITICAL）

**iOS Demo:** `/Users/nick/projects/polyv/ios/polyv-ios-media-player-sdk-demo/PLViOSMediaPlayerDemo/`

**iOS 关键实现文件：**
- `PLVMediaAreaBaseSkinView.m` - 手势处理核心
- `PLVMediaBrightnessView.m` - 亮度提示 UI

**iOS 手势处理关键点：**
```objc
// 手势方向判断
- (void)controlMedia:(UIPanGestureRecognizer *)gestureRecognizer {
    CGPoint velocity = [gestureRecognizer velocityInView:self.view];

    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        // 根据速度方向判断手势类型
        if (fabs(velocity.x) > fabs(velocity.y)) {
            self.panType = PLVBasePlayerSKinViewTyoeAdjusttProgress; // 水平滑动
            self.scrubTime = self.currentPlaybackTime;
        } else {
            CGPoint location = [gestureRecognizer locationInView:self.view];
            if (location.x < self.view.bounds.size.width / 2) {
                self.panType = PLVBasePlayerSKinViewTyoeAdjustBrightness; // 左侧亮度
            } else {
                self.panType = PLVBasePlayerSKinViewTyoeAdjustVolume; // 右侧音量
            }
        }
    }
}

// 进度调节（速度因子控制）
- (void)handleProgressAdjust:(CGFloat)velocityX {
    self.scrubTime += velocityX / 200; // 速度因子
    if (self.scrubTime > self.duration) self.scrubTime = self.duration;
    if (self.scrubTime < 0) self.scrubTime = 0;
    [self setProgressLabelWithCurrentTime:self.scrubTime];
}

// 亮度控制（屏幕高度作为灵敏度基准）
- (CGFloat)valueOfDistance:(CGFloat)distance baseValue:(CGFloat)baseValue {
    CGFloat value = baseValue + distance / 300.0f;
    if (value < 0.0) value = 0.0;
    else if (value > 1.0) value = 1.0;
    return value;
}
```

**Android Demo:** `/Users/nick/projects/polyv/android/polyv-android-media-player-sdk-demo/`

**Android 关键实现文件：**
- `PLVMediaPlayerGestureHandleLayout.kt` - 手势处理核心
- `PLVMediaPlayerBrightnessVolumeHintLayout.kt` - 亮度/音量提示 UI
- `PLVMediaPlayerSeekProgressPreviewLayout.kt` - 进度预览 UI

**Android 手势处理关键点：**
```kotlin
// 水平拖拽处理
private class HorizonDragGestureHandler : GestureDetector.OnGestureListener {
    override fun onScroll(e1: MotionEvent?, e2: MotionEvent, distanceX: Float, distanceY: Float): Boolean {
        if (!isScrolling) {
            isScrolling = true
            isScrollingHorizontal = abs(distanceX) > abs(distanceY)
            saveCurrentProgress()
        }

        if (isScrollingHorizontal) {
            val dx = e2.x - e1.x
            val percent = dx / getScreenWidth()
            val dprogress = percent * 3.minutes().toMillis() // 每屏滑动3分钟
            val targetProgress = (position + dprogress).coerceIn(0f, duration.toFloat())

            // 更新拖拽位置
            viewModel.handleDragSeekBar(DragSeekBarAction.DRAG, targetProgress.toLong())
        }
        return isScrollingHorizontal
    }
}

// 音量/亮度调节（使用累积偏移量避免抖动）
private fun handleOnScrolling(distanceY: Float) {
    val diff = accumulateAdjustDiff + (distanceY / (0.4 * getScreenHeight()) * 100)
    if (abs(diff) < 8) {
        accumulateAdjustDiff = diff // 累积小幅度偏移
        return
    }

    val direction = if (diff > 0) ChangeDirection.UP else ChangeDirection.DOWN
    // 根据起始位置判断是亮度还是音量
    if (startX < parent.width / 2) {
        viewModel.changeBrightness(direction, activity)
    } else {
        viewModel.changeVolume(direction)
    }
    accumulateAdjustDiff = 0.0
}

// 手势冲突处理
fun handleOnTouchEvent(event: MotionEvent): Boolean {
    return when (event.action) {
        MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
            lastGestureHandler = null
            // 执行所有手势处理器
        }
        else -> {
            // 优先执行最后触发的手势处理器
            if (lastGestureHandler != null) {
                lastGestureHandler!!.handle(event)
            } else {
                // 找到第一个可处理的手势
                lastGestureHandler = gestureHandlers.firstOrNull { it.enable && it.handle(event) }
            }
        }
    }
}
```

### 项目结构

```
polyv_media_player/example/lib/
├── player_skin/
│   ├── gestures/
│   │   ├── player_gesture_controller.dart      # 手势控制器
│   │   ├── gesture_detector_wrapper.dart       # 手势检测器封装
│   │   ├── seek_preview_overlay.dart           # 进度预览覆盖层
│   │   └── volume_brightness_hint.dart         # 音量/亮度提示
│   └── ...
└── pages/
    └── home_page.dart                          # 更新：集成手势功能
```

### 手势控制器设计

```dart
// 手势类型枚举
enum GestureType {
  none,
  horizontalSeek,      // 左右滑动 seek
  brightnessAdjust,    // 左侧上下滑动亮度
  volumeAdjust,        // 右侧上下滑动音量
}

// 手势状态
class GestureState {
  final GestureType type;
  final double seekProgress;        // seek 进度 (0-1)
  final double brightness;          // 亮度 (0-1)
  final double volume;              // 音量 (0-1)
  final bool showHint;              // 是否显示提示

  const GestureState({
    this.type = GestureType.none,
    this.seekProgress = 0,
    this.brightness = 0.5,
    this.volume = 0.5,
    this.showHint = false,
  });

  GestureState copyWith({
    GestureType? type,
    double? seekProgress,
    double? brightness,
    double? volume,
    bool? showHint,
  }) {
    return GestureState(
      type: type ?? this.type,
      seekProgress: seekProgress ?? this.seekProgress,
      brightness: brightness ?? this.brightness,
      volume: volume ?? this.volume,
      showHint: showHint ?? this.showHint,
    );
  }
}

// 手势控制器
class PlayerGestureController extends ChangeNotifier {
  GestureState _state = const GestureState();
  Timer? _hintHideTimer;

  GestureState get state => _state;

  /// 处理滑动开始
  void handleDragStart(DragStartDetails details) {
    // 根据起始位置确定手势类型
    // 此时还未确定方向，暂时设为 none
  }

  /// 处理滑动更新
  void handleDragUpdate(DragUpdateDetails details, Size screenSize) {
    final dx = details.delta.dx;
    final dy = details.delta.dy;

    // 判断滑动方向
    if (_state.type == GestureType.none) {
      if (dx.abs() > dy.abs()) {
        // 水平滑动 - seek
        _updateState(_state.copyWith(type: GestureType.horizontalSeek));
      } else {
        // 垂直滑动 - 判断左侧还是右侧
        final isLeftSide = details.globalPosition.dx < screenSize.width / 2;
        _updateState(_state.copyWith(
          type: isLeftSide ? GestureType.brightnessAdjust : GestureType.volumeAdjust,
        ));
      }
    }

    // 根据手势类型执行对应操作
    switch (_state.type) {
      case GestureType.horizontalSeek:
        _handleSeekUpdate(dx, screenSize.width);
        break;
      case GestureType.brightnessAdjust:
        _handleBrightnessUpdate(dy, screenSize.height);
        break;
      case GestureType.volumeAdjust:
        _handleVolumeUpdate(dy, screenSize.height);
        break;
      default:
        break;
    }

    // 显示提示
    _showHint();
  }

  /// 处理滑动结束
  void handleDragEnd(PlayerController playerController) {
    // 如果是 seek 手势，执行实际的 seek 操作
    if (_state.type == GestureType.horizontalSeek) {
      final position = (_state.seekProgress * playerController.duration).toInt();
      playerController.seekTo(position);
    }

    // 重置状态
    _updateState(const GestureState());
  }

  /// 处理 seek 更新
  void _handleSeekUpdate(double dx, double screenWidth) {
    // 每屏滑动 3 分钟（180秒）
    const seekRange = 180; // 秒
    final deltaPercent = dx / screenWidth;
    final currentProgress = _state.seekProgress;
    var newProgress = currentProgress + (deltaPercent * (seekRange / _duration));
    newProgress = newProgress.clamp(0.0, 1.0);

    _updateState(_state.copyWith(seekProgress: newProgress));
  }

  /// 处理亮度更新
  void _handleBrightnessUpdate(double dy, double screenHeight) {
    // 屏幕高度的 0.4 倍作为灵敏度基准
    final delta = dy / (screenHeight * 0.4);
    var newBrightness = _state.brightness - delta;
    newBrightness = newBrightness.clamp(0.0, 1.0);

    // 更新系统亮度
    // 需要通过 Platform Channel 调用原生 API
    _updateBrightness(newBrightness);
    _updateState(_state.copyWith(brightness: newBrightness));
  }

  /// 处理音量更新
  void _handleVolumeUpdate(double dy, double screenHeight) {
    final delta = dy / (screenHeight * 0.4);
    var newVolume = _state.volume - delta;
    newVolume = newVolume.clamp(0.0, 1.0);

    // 更新音量
    // 需要通过 Platform Channel 调用原生 API
    _updateVolume(newVolume);
    _updateState(_state.copyWith(volume: newVolume));
  }

  /// 显示提示（2秒后自动隐藏）
  void _showHint() {
    _updateState(_state.copyWith(showHint: true));
    _hintHideTimer?.cancel();
    _hintHideTimer = Timer(const Duration(seconds: 2), () {
      _updateState(_state.copyWith(showHint: false));
    });
  }

  void _updateState(GestureState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _hintHideTimer?.cancel();
    super.dispose();
  }
}
```

### 手势检测器封装

```dart
class PlayerGestureDetector extends StatelessWidget {
  final Widget child;
  final PlayerGestureController gestureController;
  final PlayerController playerController;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const PlayerGestureDetector({
    required this.child,
    required this.gestureController,
    required this.playerController,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return GestureDetector(
          // 单击
          onTap: onTap,
          // 双击
          onDoubleTap: onDoubleTap,
          // 滑动开始
          onPanStart: (details) {
            gestureController.handleDragStart(details);
          },
          // 滑动更新
          onPanUpdate: (details) {
            // 检查锁屏状态
            if (playerController.isLocked) return;
            gestureController.handleDragUpdate(details, screenSize);
          },
          // 滑动结束
          onPanEnd: (details) {
            if (playerController.isLocked) return;
            gestureController.handleDragEnd(playerController);
          },
          // 滑动取消
          onPanCancel: () {
            gestureController.handleDragEnd(playerController);
          },
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              child,
              // 进度预览覆盖层
              Consumer<PlayerGestureController>(
                builder: (context, gesture, child) {
                  if (!gesture.state.showHint) return const SizedBox.shrink();

                  switch (gesture.state.type) {
                    case GestureType.horizontalSeek:
                      return SeekPreviewOverlay(
                        progress: gesture.state.seekProgress,
                        currentPosition: (gesture.state.seekProgress * playerController.duration).toInt(),
                        duration: playerController.duration.toInt(),
                      );
                    case GestureType.brightnessAdjust:
                    case GestureType.volumeAdjust:
                      return VolumeBrightnessHint(
                        type: gesture.state.type,
                        value: gesture.state.type == GestureType.brightnessAdjust
                            ? gesture.state.brightness
                            : gesture.state.volume,
                      );
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### 进度预览覆盖层

```dart
class SeekPreviewOverlay extends StatelessWidget {
  final double progress;
  final int currentPosition;
  final int duration;

  const SeekPreviewOverlay({
    required this.progress,
    required this.currentPosition,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 时间显示
              Text(
                '${_formatTime(currentPosition)} / ${_formatTime(duration)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              // 进度条
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(PlayerColors.progress),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}
```

### 音量/亮度提示

```dart
class VolumeBrightnessHint extends StatelessWidget {
  final GestureType type;
  final double value;

  const VolumeBrightnessHint({
    required this.type,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final icon = type == GestureType.brightnessAdjust
        ? Icons.brightness_6
        : Icons.volume_up;

    return Positioned.fill(
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 4,
                height: 100,
                child: RotatedBox(
                  quarterTurns: type == GestureType.brightnessAdjust ? -1 : 0,
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(PlayerColors.progress),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(value * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Platform Channel 扩展（音量和亮度）

需要在原生端添加以下方法：

**iOS 端:**
```objc
// 设置屏幕亮度
- (void)setScreenBrightness:(CGFloat)brightness {
    [UIScreen mainScreen].brightness = brightness;
}

// 获取屏幕亮度
- (CGFloat)getScreenBrightness {
    return [UIScreen mainScreen].brightness;
}

// 设置音量（通过 MPVolumeView）
- (void)setVolume:(CGFloat)volume {
    // 使用 MPVolumeView 的滑块控件
}
```

**Android 端:**
```kotlin
// 设置屏幕亮度
fun setScreenBrightness(brightness: Float) {
    val window = activity?.window ?: return
    val layoutParams = window.attributes
    layoutParams.screenBrightness = brightness.coerceIn(0f, 1f)
    window.attributes = layoutParams
}

// 设置音量
fun setVolume(volume: Float) {
    val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
    audioManager.setStreamVolume(
        AudioManager.STREAM_MUSIC,
        (volume * maxVolume).toInt().coerceIn(0, maxVolume),
        0
    )
}
```

### 颜色系统

```dart
// 播放器专用色
class PlayerColors {
  static const Color background = Color(0xFF121621);
  static const Color surface = Color(0xFF1E2432);
  static const Color controls = Color(0xFF2D3548);
  static const Color progress = Color(0xFFE8704D);
  static const Color text = Color(0xFFF5F5F5);
  static const Color textMuted = Color(0xFF8B919E);
}
```

### 已有基础设施复用

- `PlayerController` - 播放器控制（seekTo 方法）
- `ControlBarStateMachine` - 控制栏状态机
- `PlayerColors` - 颜色常量
- `_isFullscreen` - 全屏状态变量
- `_isLocked` - 锁屏状态变量
- `DoubleTapDetector` - 双击检测器（Story 7.3）

### 迁移策略

1. **第一步**：创建 `PlayerGestureController` 和手势状态模型
2. **第二步**：实现基础的滑动检测和方向判断
3. **第三步**：实现水平 seek 功能
4. **第四步**：实现亮度调节功能
5. **第五步**：实现音量调节功能
6. **第六步**：创建提示 UI 组件
7. **第七步**：集成到现有的视频播放区域
8. **第八步**：处理手势冲突和边缘情况
9. **第九步**：完善测试

### 关键技术决策

| 决策项 | 选择 | 理由 |
|--------|------|------|
| 手势检测 | GestureDetector.onPanUpdate | Flutter 标准方案 |
| 方向判断 | 水平/垂直速度比较 | 与原生端一致 |
| seek 灵敏度 | 每屏 3 分钟 | 参考原型和 Android 实现 |
| 亮度/音量灵敏度 | 屏幕高度 0.4 倍 | 参考原型和 Android 实现 |
| 提示显示时长 | 2 秒 | 与原型一致 |
| Platform Channel | 扩展音量/亮度方法 | 原生能力调用 |

### 与前置 Story 的交互

| Story | 交互方式 |
|-------|----------|
| 7-1 全屏切换 | 全屏模式下手势正常工作，锁屏时禁用 |
| 7-2 单击播放/暂停 | GestureDetector.onTap 处理单击 |
| 7-3 双击全屏 | GestureDetector.onDoubleTap 处理双击 |
| 7-4 滑动手势 | GestureDetector.onPan 处理滑动 |

### 手势优先级处理

```dart
// 确保手势正确识别，使用 RawGestureDetector 处理复杂手势
RawGestureDetector(
  gestures: {
    _SingleTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<_SingleTapGestureRecognizer>(
      () => _SingleTapGestureRecognizer(),
      (_SingleTapGestureRecognizer instance) {
        instance.onTap = onTap;
      },
    ),
    _DoubleTapGestureRecognizer: GestureRecognizerFactoryWithHandlers<_DoubleTapGestureRecognizer>(
      () => _DoubleTapGestureRecognizer(),
      (_DoubleTapGestureRecognizer instance) {
        instance.onDoubleTap = onDoubleTap;
      },
    ),
    _PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<_PanGestureRecognizer>(
      () => _PanGestureRecognizer(),
      (_PanGestureRecognizer instance) {
        instance.onPanStart = onPanStart;
        instance.onPanUpdate = onPanUpdate;
        instance.onPanEnd = onPanEnd;
      },
    ),
  },
  child: child,
)
```

### 测试场景

| 场景 | 预期行为 |
|------|----------|
| 左滑（水平） | 快退，显示进度提示 |
| 右滑（水平） | 快进，显示进度提示 |
| 左侧上滑 | 增加亮度，显示亮度提示 |
| 左侧下滑 | 降低亮度，显示亮度提示 |
| 右侧上滑 | 增加音量，显示音量提示 |
| 右侧下滑 | 降低音量，显示音量提示 |
| 松手后 | seek 执行，提示消失 |
| 锁屏时滑动 | 不响应 |
| 快速短滑动 | 灵敏度阈值过滤 |

### 边界情况处理

1. **滑动到边界**：seek 限制在 0-duration，亮度/音量限制在 0-1
2. **快速短距离滑动**：使用累积偏移量避免抖动
3. **手势冲突**：通过 RawGestureDetector 正确识别
4. **锁屏状态**：禁用所有滑动手势
5. **切换视频期间**：忽略滑动手势

### 性能考虑

1. **手势更新频率**：使用防抖避免过度更新
2. **动画性能**：使用 AnimatedOpacity 实现平滑过渡
3. **Platform Channel 调用**：音量/亮度调节使用节流

### 可访问性

1. 为手势区域添加 Semantics 标签
2. 提供替代的按钮控制方式
3. 支持系统辅助功能

## References

- `docs/planning-artifacts/epics.md#epic-7-高级交互功能` - Epic 7上下文
- `docs/planning-artifacts/architecture.md#project-structure--boundaries` - 架构边界
- `docs/planning-artifacts/architecture.md#业务逻辑归属原则` - Flutter层业务逻辑统一原则
- `docs/project-context.md#ui-实现参考-critical` - UI开发流程
- `docs/implementation-artifacts/7-1-fullscreen.md` - 全屏切换 Story
- `docs/implementation-artifacts/7-2-tap-play-pause.md` - 单击播放/暂停 Story
- `docs/implementation-artifacts/7-3-double-tap-fullscreen.md` - 双击全屏 Story
- `/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/DemoVideoPlayer.tsx` - 播放器原型
- `/Users/nick/projects/polyv/ios/polyv-ios-media-player-sdk-demo/PLViOSMediaPlayerDemo/` - iOS原生Demo
- `/Users/nick/projects/polyv/android/polyv-android-media-player-sdk-demo/` - Android原生Demo

## Dev Agent Record

### Agent Model Used

opus-4.5-20251101

### Debug Log References

None - implementation completed without issues.

### Completion Notes List

- 创建了 `PlayerGestureController` 手势控制器，支持水平 seek、左侧亮度调节、右侧音量调节
- 实现了手势方向判断逻辑，使用 20 像素阈值确定手势方向（优化后）
- 创建了 `SeekPreviewOverlay` 进度预览覆盖层组件
- 创建了 `VolumeBrightnessHint` 音量/亮度提示组件
- 创建了 `PlayerGestureDetector` 统一处理单击、双击、滑动手势
- 实现了亮度和音量调节的 Platform Channel 方法（`setScreenBrightness`, `setVolume`）
- 集成到 `home_page.dart` 的播放页面
- 添加了完整的单元测试覆盖
- 代码审查后修复：改进手势冲突处理、增加阈值减少误触发、锁屏状态正确处理

### File List

新增文件：
- `polyv_media_player/example/lib/player_skin/gestures/player_gesture_controller.dart`
- `polyv_media_player/example/lib/player_skin/gestures/player_gesture_detector.dart`
- `polyv_media_player/example/lib/player_skin/gestures/seek_preview_overlay.dart`
- `polyv_media_player/example/lib/player_skin/gestures/volume_brightness_hint.dart`
- `polyv_media_player/example/lib/player_skin/gestures/player_gesture_controller_test.dart`
- `polyv_media_player/example/lib/player_skin/gestures/seek_preview_overlay_test.dart`
- `polyv_media_player/example/lib/player_skin/gestures/volume_brightness_hint_test.dart`

修改文件：
- `polyv_media_player/lib/platform_channel/player_api.dart` - 添加了亮度/音量方法常量
- `polyv_media_player/lib/platform_channel/method_channel_handler.dart` - 添加了 `setScreenBrightness`, `getScreenBrightness`, `setVolume` 方法
- `polyv_media_player/example/lib/pages/home_page.dart` - 集成手势功能，优化交互体验（点击只显示控制栏）
- `polyv_media_player/android/build.gradle` - 配置阿里云镜像
- `polyv_media_player/example/android/build.gradle.kts` - 配置阿里云镜像
- `polyv_media_player/example/android/settings.gradle.kts` - 配置阿里云镜像
- `docs/implementation-artifacts/sprint-status.yaml`
- `docs/implementation-artifacts/7-4-gestures.md`
