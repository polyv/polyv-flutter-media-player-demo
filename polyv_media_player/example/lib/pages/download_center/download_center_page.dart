import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:polyv_media_player/polyv_media_player.dart';
import 'downloading_task_item.dart';
import '../home_page.dart' show LongVideoPage;

/// 下载中心页面
///
/// 精确还原 HTML 原型设计：
/// - Header: 返回按钮 + 标题 "下载中心" + 更多按钮
/// - Tabs: 下载中、已完成（带任务数量徽章）
/// - Content: 根据选中的 Tab 显示对应内容
///
/// 参考: /Users/nick/projects/polyv/ios/polyv-vod/src/components/demo/DownloadCenterPage.tsx
class DownloadCenterPage extends StatefulWidget {
  // 颜色常量 (对应 Tailwind 颜色规范)
  static const Color _slate900 = Color(0xFF0F172A);
  static const Color _slate800 = Color(0xFF1E293B);
  static const Color _slate500 = Color(0xFF64748B);
  static const Color _slate400 = Color(0xFF94A3B8);
  static const Color _primary = Color(0xFFE8704D);
  static const Color _dividerColor = Color(
    0x4D2D3548,
  ); // slate-800 with opacity

  final int initialTabIndex;

  const DownloadCenterPage({super.key, this.initialTabIndex = 0});

  /// 导航路由方法
  static Route<void> route({int initialTabIndex = 0}) {
    return MaterialPageRoute<void>(
      builder: (context) =>
          DownloadCenterPage(initialTabIndex: initialTabIndex),
    );
  }

  @override
  State<DownloadCenterPage> createState() => _DownloadCenterPageState();
}

class _DownloadCenterPageState extends State<DownloadCenterPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTabIndex.clamp(0, 1).toInt();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex,
    );
    // Story 9.8: 页面初始化时从原生 SDK 同步权威任务列表
    _syncFromNative();
  }

  /// Story 9.8: 从原生 SDK 同步下载任务列表
  Future<void> _syncFromNative() async {
    final stateManager = context.read<DownloadStateManager>();
    final error = await stateManager.syncFromNative();
    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DownloadCenterPage._slate900,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [CompletedTabView(), DownloadingTabView()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: DownloadCenterPage._slate900.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: DownloadCenterPage._slate800.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: DownloadCenterPage._slate400,
                  size: 24,
                ),
                label: Text(
                  '返回',
                  style: TextStyle(
                    color: DownloadCenterPage._slate400,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 40),
                ),
              ),
              const Text(
                '下载中心',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: DownloadCenterPage._slate400.withValues(alpha: 0.8),
                  size: 20,
                ),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Consumer<DownloadStateManager>(
      builder: (context, stateManager, _) {
        final downloadingCount = stateManager.downloadingCount;
        final completedCount = stateManager.completedCount;

        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: DownloadCenterPage._slate800.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: DownloadCenterPage._primary,
            unselectedLabelColor: DownloadCenterPage._slate500,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            indicatorSize: TabBarIndicatorSize.label,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                color: DownloadCenterPage._primary,
                width: 2,
              ),
              insets: const EdgeInsets.symmetric(horizontal: 16),
            ),
            tabs: [
              Tab(child: Text('已完成 ($completedCount)')),
              Tab(child: Text('下载中 ($downloadingCount)')),
            ],
          ),
        );
      },
    );
  }
}

/// 下载中 Tab 视图
///
/// 显示正在下载、已暂停、下载失败的任务
class DownloadingTabView extends StatelessWidget {
  const DownloadingTabView({super.key});

  void _showSnackBarError(BuildContext context, Object error) {
    final message = error is Exception ? error.toString() : '$error';
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showDeleteFailedDialog(
    BuildContext context, {
    required String taskId,
  }) async {
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('删除失败'),
          content: const Text('删除任务失败，请重试'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await context.read<DownloadStateManager>().deleteTask(taskId);
                } catch (e) {
                  if (!context.mounted) return;
                  _showSnackBarError(context, e);
                }
              },
              child: const Text('重试'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadStateManager>(
      builder: (context, stateManager, _) {
        final tasks = stateManager.downloadingTasks;

        if (tasks.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: tasks.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: DownloadCenterPage._dividerColor),
          itemBuilder: (context, index) {
            final task = tasks[index];
            return DownloadingTaskItem(
              task: task,
              onPauseResume: () async {
                try {
                  if (task.status == DownloadTaskStatus.paused) {
                    await stateManager.resumeTask(task.id);
                  } else {
                    await stateManager.pauseTask(task.id);
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  _showSnackBarError(context, e);
                }
              },
              onDelete: () async {
                try {
                  await stateManager.deleteTask(task.id);
                } catch (e) {
                  if (!context.mounted) return;
                  await _showDeleteFailedDialog(context, taskId: task.id);
                }
              },
              onRetry: () async {
                try {
                  await stateManager.retryTask(task.id);
                } catch (e) {
                  if (!context.mounted) return;
                  _showSnackBarError(context, e);
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_rounded,
            size: 48,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            '暂无下载任务',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// 已完成 Tab 视图
///
/// 显示下载完成的任务
class CompletedTabView extends StatelessWidget {
  const CompletedTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadStateManager>(
      builder: (context, stateManager, _) {
        final tasks = stateManager.completedTasks;

        if (tasks.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: tasks.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: DownloadCenterPage._dividerColor),
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _CompletedTaskItem(
              task: task,
              onTap: () => _playDownloadedVideo(context, task.vid),
            );
          },
        );
      },
    );
  }

  /// 播放已下载的视频
  void _playDownloadedVideo(BuildContext context, String vid) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LongVideoPage(initialVid: vid)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 48,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            '暂无已完成视频',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// 已完成任务卡片组件
///
/// 显示：缩略图、标题、完成状态、删除按钮
class _CompletedTaskItem extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback? onTap;

  const _CompletedTaskItem({required this.task, this.onTap});

  Widget _thumbnailPlaceholder() {
    return const Icon(
      Icons.play_circle_outline,
      color: Color(0xFF475569),
      size: 24,
    );
  }

  Widget _buildThumbnail() {
    final thumbnail = task.thumbnail;
    if (thumbnail == null || thumbnail.isEmpty) {
      return _thumbnailPlaceholder();
    }

    final uri = Uri.tryParse(thumbnail);
    final scheme = uri?.scheme;
    if (scheme == 'file') {
      return Image.file(
        File.fromUri(uri!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _thumbnailPlaceholder(),
      );
    }

    if (scheme == 'http' || scheme == 'https') {
      return Image.network(
        thumbnail,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _thumbnailPlaceholder(),
      );
    }

    if (thumbnail.startsWith('/')) {
      return Image.file(
        File(thumbnail),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _thumbnailPlaceholder(),
      );
    }

    return Image.network(
      thumbnail,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _thumbnailPlaceholder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 96,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildThumbnail(),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        task.totalSizeFormatted,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '下载完成',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Consumer<DownloadStateManager>(
              builder: (context, stateManager, _) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: const Color(0xFF64748B),
                  onPressed: () async {
                    try {
                      await stateManager.deleteTask(task.id);
                    } catch (_) {
                      if (!context.mounted) return;
                      await showDialog<void>(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: const Text('删除失败'),
                            content: const Text('删除任务失败，请重试'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.of(dialogContext).pop();
                                  try {
                                    await context
                                        .read<DownloadStateManager>()
                                        .deleteTask(task.id);
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                },
                                child: const Text('重试'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
