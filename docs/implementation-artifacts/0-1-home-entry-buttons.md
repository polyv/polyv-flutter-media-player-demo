# Story 0.1: 首页入口按钮

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

作为最终用户，
我想要看到两个清晰的入口按钮（长视频、下载中心），
以便快速访问所需功能。

## Acceptance Criteria

**Given** 用户打开 App
**When** 首页加载完成
**Then** 显示两个带有图标和文字的入口按钮
**And** "长视频"按钮显示播放图标
**And** "下载中心"按钮显示下载图标
**And** 点击按钮可以导航到对应页面

## Tasks / Subtasks

- [x] 创建首页组件 (AC: Given, When, Then)
  - [x] 创建 `example/lib/pages/home_page.dart` 文件
  - [x] 实现 `HomePage` StatelessWidget
  - [x] 设置页面标题为 "保利威播放器"
- [x] 实现入口按钮布局 (AC: Then)
  - [x] 使用 `Column` 垂直布局，按钮居中
  - [x] 使用 `SizedBox` 设置按钮间距
  - [x] 确保按钮在屏幕中间区域显示
- [x] 创建长视频入口按钮 (AC: And, And)
  - [x] 使用 `ElevatedButton` 或 `Card` + `InkWell`
  - [x] 添加 `Icons.play_circle_filled` 图标
  - [x] 添加"长视频"文字标签
  - [x] 设置按钮样式（尺寸、颜色、圆角）
- [x] 创建下载中心入口按钮 (AC: And, And)
  - [x] 使用 `ElevatedButton` 或 `Card` + `InkWell`
  - [x] 添加 `Icons.download` 或 `Icons.file_download` 图标
  - [x] 添加"下载中心"文字标签
  - [x] 设置按钮样式（与长视频按钮保持一致）
- [x] 实现页面路由导航 (AC: And)
  - [x] 为长视频按钮添加 `Navigator.push`
  - [x] 为下载中心按钮添加 `Navigator.push`
  - [x] 创建占位页面：`LongVideoPage` 和 `DownloadCenterPage`
  - [x] 更新 `main.dart` 的 `home` 属性为 `HomePage`

## Dev Notes

### Story Context

**Epic 0: 首页与导航框架**
- 这是项目的第一个用户故事，负责创建应用的主入口界面
- 后续页面（长视频播放器、下载中心）将在独立的故事中实现
- 当前故事只需要创建页面框架，具体功能页面使用占位实现

### Architecture Compliance

**Phase 1 分层设计：**
- 此功能在 **Demo App (example/)** 层实现
- 不涉及 Plugin 层修改

**文件位置：**
```
example/lib/
├── main.dart                      # 更改 home 为 HomePage
├── pages/
│   ├── home_page.dart             # 新建：首页
│   ├── long_video_page.dart       # 新建：长视频占位页面
│   └── download_center_page.dart  # 新建：下载中心占位页面
```

### Project Structure Notes

**目录组织：**
- 创建 `example/lib/pages/` 目录用于存放页面级 Widget
- 每个页面使用独立的文件

**命名约定：**
- 页面类名使用 PascalCase：`HomePage`, `LongVideoPage`, `DownloadCenterPage`
- 文件名使用 snake_case：`home_page.dart`, `long_video_page.dart`

**Material Design 3：**
- 项目已启用 `useMaterial3: true`
- 使用 `ColorScheme.fromSeed(seedColor: Colors.blue)` 主题
- 按钮样式应与 Material 3 设计语言保持一致

### UI Implementation Reference

**HTML 原型参考：**
- 原型路径：`/Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/`
- 参考文件：`LongVideoPage.tsx`, `DownloadCenterPage.tsx`

**视觉设计建议：**
- 按钮尺寸：建议宽度 200-280px，高度 80-100px
- 图标大小：`IconSizes.size48` 或 `size: 48`
- 文字样式：`Theme.of(context).textTheme.titleLarge`
- 圆角：`BorderRadius.circular(12)`
- 间距：按钮之间 `SizedBox(height: 24)`

**参考 HTML 原型的元素：**
- 按钮应使用卡片式设计（Card + InkWell）
- 图标在上，文字在下
- 悬停效果（移动端改为点击波纹效果）

### Technical Implementation Details

**Navigator.push 示例：**
```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LongVideoPage()),
    );
  },
  child: const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.play_circle_filled, size: 48),
      SizedBox(height: 8),
      Text('长视频', style: TextStyle(fontSize: 16)),
    ],
  ),
)
```

**占位页面实现：**
```dart
class LongVideoPage extends StatelessWidget {
  const LongVideoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('长视频'),
      ),
      body: const Center(
        child: Text('长视频页面 - 待实现'),
      ),
    );
  }
}
```

**HomePage 布局建议：**
```dart
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('保利威播放器'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildEntryButton(
              context,
              icon: Icons.play_circle_filled,
              label: '长视频',
              onTap: () => _navigateToLongVideo(context),
            ),
            const SizedBox(height: 24),
            _buildEntryButton(
              context,
              icon: Icons.file_download,
              label: '下载中心',
              onTap: () => _navigateToDownloadCenter(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    // 实现按钮样式
  }
}
```

### Testing Requirements

**Widget 测试：**
- 创建 `example/test/pages/home_page_test.dart`
- 测试按钮是否正确渲染
- 测试导航是否正确触发

**测试示例：**
```dart
testWidgets('HomePage displays two entry buttons', (tester) async {
  await tester.pumpWidget(const MyApp());
  expect(find.text('长视频'), findsOneWidget);
  expect(find.text('下载中心'), findsOneWidget);
});

testWidgets('Tapping long video button navigates', (tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.tap(find.text('长视频'));
  await tester.pumpAndSettle();
  expect(find.text('长视频页面 - 待实现'), findsOneWidget);
});
```

### References

- [Epic 0: 首页与导航框架](../planning-artifacts/epics.md#epic-0-首页与导航框架) - Epic 级别的目标和上下文
- [Story 0.1 验收标准](../planning-artifacts/epics.md#story-01-首页入口按钮) - 完整的 BDD 验收标准
- [架构文档 - Widget 组件化策略](../planning-artifacts/architecture.md#widget-组件化策略) - Demo App 组件结构说明
- [项目上下文 - 文件组织规则](../project-context.md#6-文件组织规则-phase-1) - 命名约定和目录结构
- [项目上下文 - UI 实现参考](../project-context.md#10-ui-实现参考-critical) - HTML 原型路径说明

## Dev Agent Record

### Agent Model Used

claude-opus-4-5-20251101

### Debug Log References

N/A - No debugging issues encountered

### Completion Notes List

✅ **实现完成**
- 创建了 `HomePage` 组件，包含两个入口按钮（长视频、下载中心）
- 使用 Card + InkWell 实现卡片式按钮设计，符合 Material 3 设计语言
- 按钮尺寸：240x100，圆角 12px，图标大小 48px
- 实现了页面导航功能，点击按钮可跳转到对应占位页面
- 创建了 `LongVideoPage` 和 `DownloadCenterPage` 占位页面
- 更新了 `main.dart` 将首页设置为 `HomePage`
- 编写了 6 个 Widget 测试，全部通过
- 代码已通过 `dart format` 格式化

### Change Log

- 2026-01-20: 实现首页入口按钮功能
  - 新建 `polyv_media_player/example/lib/pages/home_page.dart`
  - 新建 `polyv_media_player/example/test/pages/home_page_test.dart`
  - 修改 `polyv_media_player/example/lib/main.dart` (更新 home 属性和 import)

### File List

**新建文件:**
- `polyv_media_player/example/lib/pages/home_page.dart` - 首页组件（含 HomePage, LongVideoPage, DownloadCenterPage）
- `polyv_media_player/example/test/pages/home_page_test.dart` - Widget 测试文件

**修改文件:**
- `polyv_media_player/example/lib/main.dart` - 添加 import，将 home 改为 HomePage
- `polyv_media_player/example/pubspec.yaml` - 添加 version 字段
- `polyv_media_player/example/pubspec.lock` - 依赖版本更新
- `docs/implementation-artifacts/sprint-status.yaml` - Sprint 状态追踪初始化
- `docs/project-context.md` - 添加 UI 开发工作流程和设计规范

### Review Follow-ups (AI)

- [x] [AI-Review][HIGH] 更新 Story File List 以匹配实际 git 变更 - 2026-01-20
- [x] [AI-Review][MEDIUM] 修复导航测试断言，使用更具体的验证 - 2026-01-20
- [x] [AI-Review][MEDIUM] 添加无障碍支持 (Semantics) - 2026-01-20
