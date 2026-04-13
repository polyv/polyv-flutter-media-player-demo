---
title: 'Fix: 横屏切换后历史弹幕不显示'
type: 'bugfix'
created: '2026-04-13'
status: 'done'
route: 'one-shot'
---

# Fix: 横屏切换后历史弹幕不显示

## Intent

**Problem:** 横屏全屏模式下看不到视频历史弹幕，只能看到自己新发的弹幕。原因是 `long_video_page.dart` 在全屏切换时创建了新的 `PolyvVideoPlayer` 实例，而 `_loadVideo()` 检测到控制器已有视频后走快速返回路径，跳过了弹幕数据加载（`_danmakus` 始终为空列表）。

**Approach:** 在 `_loadVideo()` 的快速返回路径中，当 `_danmakus.isEmpty` 时补充调用 `_loadDanmakus(service)`。

## Suggested Review Order

- [polyv_video_player.dart](../../polyv_media_player/lib/widgets/polyv_video_player.dart) — 唯一修改文件，第 355-361 行为新增的弹幕补充加载逻辑
- [danmaku_layer.dart](../../polyv_media_player/lib/ui/danmaku/danmaku_layer.dart) — 弹幕层实现，确认 `isInitialUpdate` 路径在弹幕数据到达后能正确触发历史弹幕恢复
- [long_video_page.dart](../../example/lib/pages/long_video_page.dart) — 确认全屏切换逻辑：竖屏与横屏使用独立的 `PolyvVideoPlayer` 实例但共享同一个 `PlayerController`
