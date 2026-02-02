# Story 6.5: 触发下载任务

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

作为最终用户，
我想要通过播放器顶栏的更多选项弹窗触发下载，
以便将当前播放的视频下载到本地观看。

## Acceptance Criteria

1. **Given** 用户正在播放视频
**When** 点击播放器顶栏右侧的更多按钮（⋯）
**Then** 显示底部设置菜单弹窗

2. **Given** 设置菜单弹窗已显示
**When** 查看弹窗内容
**Then** 顶部优先显示三个功能按钮（横向排列）：音频模式、字幕设置、下载
**And** 下方显示现有的清晰度和倍速选项
**And** 点击任意按钮后执行对应功能

3. **Given** 设置菜单弹窗已显示
**When** 点击"下载"按钮
**Then** 为当前播放的视频创建新的下载任务
**And** 任务添加到下载中心的"下载中"列表
**And** 弹窗关闭

## Tasks / Subtasks

- [x] 在 SettingsMenu 顶部添加功能按钮行 (AC: 2)
  - [x] 在清晰度区域之前添加功能按钮行
  - [x] 创建 `_buildFunctionButtons()` 方法
  - [x] 使用 Row 布局，三个按钮横向排列
  - [x] 每个按钮包含图标和文字

- [x] 实现三个功能按钮 (AC: 2)
  - [x] 音频模式按钮：图标 + "音频模式" 文字
  - [x] 字幕设置按钮：图标 + "字幕设置" 文字
  - [x] 下载按钮：图标 + "下载" 文字

- [x] 实现下载功能触发 (AC: 3)
  - [x] 点击"下载"时调用 `DownloadStateManager.addTask()`
  - [x] 创建 `DownloadTask` 实例（使用当前视频 vid、标题、缩略图）
  - [x] 添加任务到下载状态管理器
  - [x] 显示下载成功提示（SnackBar）
  - [x] 关闭弹窗

- [x] 实现音频模式功能（可选，后续 Story）
  - [x] 切换音频/视频模式
  - [x] 或显示"暂不支持"提示

- [x] 实现字幕设置功能（可选，后续 Story）
  - [x] 跳转到字幕设置页面
  - [x] 或显示字幕选择弹窗

- [x] 添加单元测试
  - [x] 测试下载任务创建逻辑
  - [x] 测试按钮点击回调

- [x] 添加 Widget 测试
  - [x] 测试功能按钮行显示
  - [x] 测试下载按钮触发

## Dev Notes

### UI 样式参考

**原型代码路径**: `/Users/nick/projects/polyv/iOS/polyv-vod/src/components/mobile/MobileMoreOptions.tsx`

根据 epics.md 技术说明：
- 更多选项弹窗为**列表式布局**（非网格），每行一个功能选项
- **顶部优先显示三个重要功能**：音频模式、字幕设置、下载
- 其余功能：截图、分享、定时关闭、投屏、帮助反馈等（本 Story 只实现前三个）

**功能按钮行样式**:
```dart
// 参考原型 MobilePortraitMenu.tsx 的列表式布局
Row(
  children: [
    _FunctionButton(
      icon: Icons.headphones_outlined,
      label: '音频模式',
      onTap: _handleAudioMode,
    ),
    const SizedBox(width: 12),
    _FunctionButton(
      icon: Icons.subtitles_outlined,
      label: '字幕设置',
      onTap: _handleSubtitle,
    ),
    const SizedBox(width: 12),
    _FunctionButton(
      icon: Icons.download_rounded,
      label: '下载',
      onTap: _handleDownload,
    ),
  ],
)
```

**单个功能按钮样式**:
```dart
class _FunctionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FunctionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: PlayerColors.textMuted,
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

### 原生端逻辑参考

**Android 参考**: `/Users/nick/projects/polyv/android/polyv-android-media-player-sdk-demo/common/src/main/java/net/polyv/android/player/common/ui/component/more/PLVMediaPlayerMoreLayoutDownloadActionView.kt`

**关键逻辑** (第153-164行):
```kotlin
override fun onClick(v: View?) {
    if (downloadStatus is NOT_STARTED
        || downloadStatus is PAUSED
        || downloadStatus is ERROR
    ) {
        // 创建下载任务
        downloadItemViewModel.startDownload()
    } else {
        // 跳转到下载中心
        gotoDownloadCenter()
    }
}
```

### 与下载中心集成

**使用现有 DownloadStateManager**:

```dart
// 在点击下载时创建任务
void _handleDownload() {
  final vid = widget.controller.currentVid;
  if (vid == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('无法获取视频信息')),
    );
    return;
  }

  // 检查是否已下载
  final existingTask = _downloadStateManager.getTaskByVid(vid);
  if (existingTask != null && existingTask.status != DownloadTaskStatus.error) {
    // 已有任务，跳转到下载中心
    Navigator.push(context, DownloadCenterPage.route());
    widget.onClose();
    return;
  }

  // 创建新任务
  final task = DownloadTask(
    id: const Uuid().v4(),
    vid: vid,
    title: _currentVideoTitle ?? '未知视频',
    thumbnail: _currentVideoThumbnail,
    totalBytes: 0,
    downloadedBytes: 0,
    status: DownloadTaskStatus.waiting,
    createdAt: DateTime.now(),
  );

  _downloadStateManager.addTask(task);

  // 显示成功提示
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('已添加到下载队列')),
  );

  // 关闭弹窗
  widget.onClose();
}
```

### Project Structure Notes

**修改文件**:
```
polyv_media_player/example/lib/player_skin/
├── quality_selector/
│   └── settings_menu.dart      # 添加功能按钮行（修改）
```

**新增文件**（如需要）:
```
polyv_media_player/example/lib/player_skin/
├── quality_selector/
│   ├── function_button.dart    # 功能按钮组件（可选）
│   └── settings_menu_test.dart # 测试（可选）
```

### 现有 SettingsMenu 结构

当前 `settings_menu.dart` 的结构：
```dart
Column(
  children: [
    // Handle（拖拽手柄）
    Container(...),

    // Close button（关闭按钮）
    Padding(...),

    // Content（内容区）
    Padding(
      child: Column(
        children: [
          // Quality section（清晰度区域）← 在这之前添加功能按钮行
          _buildQualitySection(...),

          // Speed section（倍速区域）
          _buildSpeedSection(),
        ],
      ),
    ),
  ],
)
```

**需要在清晰度区域之前添加功能按钮行**：
```dart
Padding(
  child: Column(
    children: [
      // 新增：功能按钮行
      _buildFunctionButtons(),

      const SizedBox(height: 16),

      // 现有：清晰度区域
      _buildQualitySection(...),

      // 现有：倍速区域
      _buildSpeedSection(),
    ],
  ),
),
```

### PlayerController 扩展需求

需要添加获取当前视频信息的方法：
```dart
class PlayerController extends ChangeNotifier {
  /// 当前播放的视频 VID
  String? get currentVid => _state.vid;

  /// 当前播放的视频标题（需要从外部设置）
  String? currentVideoTitle;

  /// 当前播放的视频缩略图（需要从外部设置）
  String? currentVideoThumbnail;
}
```

### 图标映射

| 功能 | Material (Flutter) |
|------|-------------------|
| 音频模式 | Icons.headphones_outlined / Icons.audiotrack_outlined |
| 字幕设置 | Icons.subtitles_outlined / Icons.closed_caption_outlined |
| 下载 | Icons.download_rounded |

### 技术约束

**业务逻辑归属原则** (CRITICAL):

根据 `project-context.md` 第 8 节规则：

> **Flutter (Dart) 层职责**:
> - 维护下载任务状态镜像
> - 创建下载任务的决策逻辑
> - UI 渲染和用户交互
>
> **原生层职责**:
> - 实际下载执行
> - 文件存储和断点续传
> - 通过 EventChannel 推送进度事件

**本 Story 实现重点**:
1. 在现有 `SettingsMenu` 顶部添加功能按钮行
2. Dart 层实现下载任务创建逻辑
3. 原生层暴露开始下载 API（后续 Story 实现）

### 测试标准

**Widget 测试**:
- 测试功能按钮行显示
- 测试三个按钮正确渲染
- 测试下载按钮触发回调

**集成测试**:
- 测试完整下载触发流程
- 测试与下载中心集成

### 实现检查清单

**UI 组件**:
- [ ] 在 `SettingsMenu` 顶部添加功能按钮行
- [ ] 创建 `_buildFunctionButtons()` 方法
- [ ] 实现三个功能按钮（音频模式、字幕设置、下载）

**下载功能**:
- [ ] 点击下载创建任务
- [ ] 跳转到下载中心（已下载情况）
- [ ] 显示成功提示
- [ ] 关闭弹窗

**集成**:
- [ ] 获取当前视频信息
- [ ] 与 `DownloadStateManager` 集成

**测试**:
- [ ] Widget 测试
- [ ] 所有测试通过，无回归

### 参考文件位置

- epics.md 技术说明：列表式布局、顶部三个重要功能
- UI 参考: `/Users/nick/projects/polyv/iOS/polyv-vod/src/components/mobile/MobileMoreOptions.tsx`
- Android 逻辑参考: `/Users/nick/projects/polyv/android/polyv-android-media-player-sdk-demo/common/src/main/java/net/polyv/android/player/common/ui/component/more/PLVMediaPlayerMoreLayoutDownloadActionView.kt`
- 现有组件: `polyv_media_player/example/lib/player_skin/quality_selector/settings_menu.dart`

## Dev Agent Record

### Agent Model Used

claude-opus-4-5-20251101

### Debug Log References

None

### Completion Notes List

1. **功能按钮行实现**: 在 `SettingsMenu` 顶部添加了三个功能按钮（音频模式、字幕设置、下载），使用 `Row` 布局横向排列，每个按钮包含图标和文字。

2. **下载功能触发**: 点击"下载"按钮时，从 `PlayerController.state.vid` 获取当前视频 ID，并通过 `Provider` 获取 `DownloadStateManager`，创建新的 `DownloadTask` 并添加到下载列表。

3. **视频信息传递**: 为了支持下载功能，`SettingsMenu.show()` 方法增加了 `videoTitle` 和 `videoThumbnail` 可选参数，`home_page.dart` 中调用时传递 `_currentVideo` 的信息。

4. **DownloadStateManager 集成**: 在 `main.dart` 中添加了应用级别的 `ChangeNotifierProvider<DownloadStateManager>`，使下载状态在整个应用中可共享。

5. **DownloadCenterPage 适配**: 更新了 `DownloadCenterPage` 使用应用级别的 `DownloadStateManager`，而不是创建自己的实例，并添加了 `route()` 静态方法用于导航。

6. **音频/字幕功能**: 音频模式按钮显示"暂不支持"提示，字幕设置按钮引导用户使用播放器控制栏的字幕切换功能。

7. **测试覆盖**: 添加了 8 个新的 Widget 测试，覆盖功能按钮行显示、按钮位置关系、点击音频/字幕按钮的提示、以及点击下载按钮的行为。

### Code Review Record (2026-01-27)

**Reviewer**: Claude Opus (Code Review Workflow)
**Issues Found**: 5 High, 4 Medium, 3 Low
**Issues Fixed**: All HIGH and MEDIUM issues fixed

**修复内容**:
1. ✅ 修复下载任务 ID 生成逻辑 - 使用微秒级时间戳确保唯一性
2. ✅ 改进下载状态检查逻辑 - 对已完成任务显示友好提示并支持查看
3. ✅ 更新字幕设置按钮文案 - 引导用户使用现有功能
4. ✅ 添加更多测试用例验证下载功能
5. ✅ 更新 File List 包含所有实际修改的文件

### File List

**修改的文件**:
- `polyv_media_player/example/lib/player_skin/quality_selector/settings_menu.dart` - 添加功能按钮行和下载功能
- `polyv_media_player/example/lib/player_skin/quality_selector/settings_menu_test.dart` - 添加新功能的测试
- `polyv_media_player/example/lib/pages/home_page.dart` - 传递视频标题和缩略图到 SettingsMenu
- `polyv_media_player/example/lib/player_skin/player_colors.dart` - 导入的常量文件
- `polyv_media_player/example/lib/pages/download_center/download_center_page.dart` - 添加 route() 方法，使用共享的 DownloadStateManager
- `polyv_media_player/example/lib/pages/download_center/download_center_page_test.dart` - 清理未使用的导入
- `polyv_media_player/example/lib/pages/download_center/downloading_task_item_test.dart` - 清理未使用的导入
- `polyv_media_player/example/lib/main.dart` - 添加应用级别的 DownloadStateManager provider
- `docs/automation-summary.md` - 自动更新
- `docs/planning-artifacts/epics.md` - 自动更新
- `docs/implementation-artifacts/sprint-status.yaml` - 更新 Story 状态
