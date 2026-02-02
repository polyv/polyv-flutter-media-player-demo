# PolyvMediaPlayer Flutter Plugin - 测试文档

## 概述

本项目使用 Flutter 的 `flutter_test` 框架进行单元测试和组件测试。测试覆盖了播放器的核心功能、状态管理、异常处理和 UI 组件。

## 测试目录结构

```
polyv_media_player/
├── test/
│   ├── core/                          # 核心功能单元测试
│   │   ├── player_state_test.dart     # 播放器状态测试
│   │   ├── player_exception_test.dart # 播放器异常测试
│   │   ├── player_events_test.dart    # 播放器事件测试
│   │   ├── player_controller_test.dart     # 控制器测试
│   │   └── player_controller_mocked_test.dart # 控制器 Mock 测试
│   ├── widgets/                       # Widget 组件测试
│   │   └── polyv_video_view_test.dart # 视频视图组件测试
│   ├── platform_channel/              # 平台通道常量测试
│   │   └── player_api_test.dart       # API 常量测试
│   └── support/                       # 测试辅助工具
│       ├── mocks.dart                 # Mock 类
│       └── test_data.dart             # 测试数据生成器
│
polyv_media_player/example/
├── test/
│   ├── widget_test.dart               # 基础组件测试
│   ├── pages/
│   │   └── home_page_test.dart        # 主页测试
│   ├── player_skin/
│   │   ├── progress_slider/
│   │   │   └── progress_slider_test.dart  # 进度条测试
│   │   └── control_bar_test.dart     # 控制栏测试
│   └── integration/
│       └── player_skin_integration_test.dart # 集成测试
```

## 运行测试

### 运行所有测试

```bash
# 在 plugin 目录
cd polyv_media_player
flutter test

# 在 example 目录
cd example
flutter test
```

### 运行特定测试文件

```bash
# 运行单个测试文件
flutter test test/core/player_state_test.dart

# 运行特定目录的测试
flutter test test/core/
```

### 按优先级运行测试

测试使用优先级标签 `[P0]`, `[P1]`, `[P2]`, `[P3]`：

```bash
# 运行 P0 测试（关键路径）
flutter test --name="\\[P0\\]"

# 运行 P0 和 P1 测试
flutter test --name="\\[P[01]\\]"
```

### 运行测试并生成覆盖率报告

```bash
# 生成覆盖率报告
flutter test --coverage

# 在 macOS 上查看覆盖率
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 调试模式运行测试

```bash
# 交互式调试
flutter test --no-sound-null-safety

# 显示详细输出
flutter test --verbose

# 在特定平台运行
flutter test -d chrome    # 在 Chrome 上运行 Web 测试
flutter test -d macos     # 在 macOS 上运行
```

## 测试编写规范

### Given-When-Then 格式

所有测试遵循 Given-When-Then 格式：

```dart
test('[P1] 测试名称', () {
  // GIVEN: 准备测试数据和条件
  final controller = PlayerController();

  // WHEN: 执行被测试的操作
  final state = controller.state;

  // THEN: 验证结果
  expect(state.loadingState, PlayerLoadingState.idle);

  controller.dispose();
});
```

### 优先级标签

- **[P0]**: 关键路径测试，每次提交必须运行
  - 核心播放控制（播放、暂停、停止）
  - 关键状态转换
  - 安全相关的功能

- **[P1]**: 高优先级测试，合并前必须运行
  - 重要功能模块
  - 集成点测试
  - 常见错误处理

- **[P2]**: 中等优先级测试，夜间运行
  - 边界情况
  - UI 交互细节
  - 性能相关测试

- **[P3]**: 低优先级测试，按需运行
  - 可选功能
  - 探索性测试
  - 文档性测试

### Widget 测试规范

```dart
testWidgets('[P1] 测试 Widget 行为', (tester) async {
  // GIVEN: 准备测试数据和 Widget
  final controller = PlayerController();

  // WHEN: 构建 Widget
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ControlBar(controller: controller),
      ),
    ),
  );

  // THEN: 验证 Widget 渲染和行为
  expect(find.byType(ControlBar), findsOneWidget);
  expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

  controller.dispose();
});
```

## 测试辅助工具

### MockMethodChannel

模拟平台通道方法调用：

```dart
final mockChannel = MockMethodChannel('com.polyv.media_player/player');
mockChannel.mockResult('loadVideo', {'success': true});

// 验证方法调用
expect(mockChannel.wasMethodCalled('loadVideo'), isTrue);
expect(mockChannel.getCallCount('loadVideo'), 1);
```

### MockEventChannel

模拟平台通道事件流：

```dart
final mockEventChannel = MockEventChannel('com.polyv.media_player/events');

// 发送模拟事件
mockEventChannel.sendEvent({
  'type': 'progress',
  'data': {'position': 30000, 'duration': 60000}
});
```

### TestData 和 MockDataGenerator

生成测试数据：

```dart
// 使用常量
final vid = TestData.defaultVid;

// 生成随机数据
final randomVid = MockDataGenerator.generateVid();
final randomPosition = MockDataGenerator.generatePosition();
```

## 常见测试模式

### 状态监听测试

```dart
test('[P1] 状态变化通知监听者', () {
  final controller = PlayerController();
  var notified = false;

  controller.addListener(() {
    notified = true;
  });

  // 触发状态变化
  controller.loadVideo('test_vid');

  expect(notified, isTrue);
  controller.dispose();
});
```

### 异常处理测试

```dart
test('[P1] 无效参数抛出异常', () {
  final controller = PlayerController();

  expect(
    () => controller.setQuality(-1),
    throwsA(isA<PlayerException>()),
  );

  controller.dispose();
});
```

### Widget 交互测试

```dart
testWidgets('[P1] 点击按钮触发回调', (tester) async {
  var clicked = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: IconButton(
          icon: Icon(Icons.play_arrow),
          onPressed: () => clicked = true,
        ),
      ),
    ),
  );

  await tester.tap(find.byIcon(Icons.play_arrow));
  await tester.pump();

  expect(clicked, isTrue);
});
```

## 测试质量检查清单

在提交代码前，确保：

- [ ] 所有新代码都有对应的测试
- [ ] 测试覆盖了正常路径和错误路径
- [ ] 使用了 Given-When-Then 格式
- [ ] 包含了适当的优先级标签
- [ ] Widget 测试验证了 UI 渲染和交互
- [ ] 测试使用 Mock 隔离外部依赖
- [ ] 测试运行速度快（< 1 秒每个）
- [ ] 测试之间相互独立，可以单独运行
- [ ] 测试清理资源（dispose、close 等）

## CI/CD 集成

测试在 CI/CD 流程中运行：

```yaml
# .github/workflows/test.yml
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v2
    - uses: subosito/flutter-action@v2
    - run: flutter pub get
    - run: flutter test --coverage
    - run: flutter test --name="\\[P0\\]"  # 关键测试
```

## 常见问题

### 测试超时

如果测试超时，检查：
- 是否有未等待的异步操作
- 是否有未取消的 Timer 或 Stream 订阅
- 是否正确调用了 `tester.pump()` 或 `tester.pumpAndSettle()`

### 平台通道 Mock 失败

确保：
- 测试前正确设置了 Mock 处理器
- 测试后清理了 Mock 处理器
- 使用了正确的通道名称

### Widget 测试找不到元素

确保：
- 调用了 `tester.pump()` 或 `tester.pumpAndSettle()`
- 使用了正确的 Finder（`byType`, `byKey`, `byIcon`）
- Widget 在 Widget 树中可见

## 参考资源

- [Flutter 测试文档](https://docs.flutter.dev/cookbook/testing)
- [Widget 测试指南](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [单元测试指南](https://docs.flutter.dev/cookbook/testing/unit/introduction)
- [Mockito 包文档](https://pub.dev/packages/mockito)
