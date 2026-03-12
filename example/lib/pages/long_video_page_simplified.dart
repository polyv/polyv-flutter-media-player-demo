import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:polyv_media_player/polyv_media_player.dart';
import 'package:polyv_media_player/utils/plv_logger.dart';
import 'package:provider/provider.dart';
// Example 独有组件
import '../pages/download_center/download_center_page.dart';
import '../player_skin/video_list/video_list_view.dart' show VideoListView;

/// LongVideoPage - 简化版长视频页面
///
/// 使用 PolyvVideoPlayer 作为核心播放器组件，大幅简化代码。
///
/// 页面职责：
/// - 视频列表管理
/// - 全屏模式处理
/// - 弹幕服务注入
/// - 视频切换逻辑
class LongVideoPage extends StatefulWidget {
  final String? initialVid;
  final bool isOfflineMode;
  final String? initialTitle;
  final String? initialThumbnail;

  const LongVideoPage({
    super.key,
    this.initialVid,
    this.isOfflineMode = false,
    this.initialTitle,
    this.initialThumbnail,
  });

  @override
  State<LongVideoPage> createState() => _LongVideoPageState();
}

class _LongVideoPageState extends State<LongVideoPage> implements DownloadCallbacks {
  // 播放器控制器
  late final PlayerController _controller;

  // 视频列表状态
  VideoListService? _videoListService;
  List<VideoItem> _videos = [];
  VideoItem? _currentVideo;
  bool _isLoadingList = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  String? _listError;

  // 初始加载状态
  bool _isInitialLoading = true;

  // 视频切换状态
  bool _isSwitchingVideo = false;
  DateTime? _lastSwitchTime;
  static const int _debounceMs = 1000;

  // 弹幕服务
  DanmakuService? _danmakuService;
  DanmakuSendService? _danmakuSendService;
  final PolyvConfigService _configService = PolyvConfigService();
  final DanmakuSettings _danmakuSettings = DanmakuSettings();

  // 全屏状态
  bool _isFullscreen = false;

  // 配置服务
  final PolyvConfigService _polyvConfigService = PolyvConfigService();

  // DownloadCallbacks 实现
  @override
  DownloadTask? getTaskByVid(String vid) {
    try {
      return context.read<DownloadStateManager>().getTaskByVid(vid);
    } catch (_) {
      return null;
    }
  }

  @override
  DownloadStateManager get stateManager {
    return context.read<DownloadStateManager>();
  }

  @override
  void openDownloadCenter(int initialTabIndex) {
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.push(
      DownloadCenterPage.route(initialTabIndex: initialTabIndex),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = PlayerController();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      final config = await _configService.getConfig();

      _videoListService = VideoListServiceFactory.createHttp(
        userId: config.userId,
        readToken: config.readToken,
        secretKey: config.secretKey,
      );

      _danmakuSendService = DanmakuSendServiceFactory.createHttp(
        userId: config.userId,
        writeToken: config.writeToken,
        secretKey: config.secretKey,
      );

      _danmakuService = DanmakuServiceFactory.createHttp(
        userId: config.userId,
        readToken: config.readToken,
        secretKey: config.secretKey,
      );

      PlvLogger.d('LongVideoPage: Services initialized');

      if (widget.isOfflineMode && widget.initialVid != null) {
        _loadOfflineVideo(widget.initialVid!);
      } else if (mounted) {
        _loadVideoList();
      }
    } catch (e) {
      PlvLogger.w('LongVideoPage: Failed to load config: $e');
      _videoListService = VideoListServiceFactory.createMock();
      _danmakuService = DanmakuServiceFactory.createMock();

      if (widget.isOfflineMode && widget.initialVid != null) {
        _loadOfflineVideo(widget.initialVid!);
      } else if (mounted) {
        _loadVideoList();
      }
    }
  }

  Future<void> _loadVideoList({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _listError = null;
    }

    final service = _videoListService;
    if (service == null) return;

    try {
      final response = await service.fetchVideoList(
        VideoListRequest(page: _currentPage, pageSize: _pageSize),
      );

      if (!mounted) return;

      setState(() {
        if (refresh) {
          _videos = response.videos;
        } else {
          _videos = [..._videos, ...response.videos];
        }
        _hasMore = response.hasNextPage;
        _isLoadingList = false;
        _isLoadingMore = false;
        _listError = null;
      });

      if (_isInitialLoading && _videos.isNotEmpty) {
        final firstVideo = widget.initialVid != null
            ? _videos.firstWhere(
                (v) => v.vid == widget.initialVid,
                orElse: () => _videos.first,
              )
            : _videos.first;

        setState(() {
          _currentVideo = firstVideo;
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      PlvLogger.w('加载视频列表失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingList = false;
          _isLoadingMore = false;
          _isInitialLoading = false;
          _listError = '加载失败，请重试';
        });
      }
    }
  }

  Future<void> _loadMoreVideos() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    await _loadVideoList();
  }

  Future<void> _loadOfflineVideo(String vid) async {
    final tempVideo = VideoItem(
      vid: vid,
      title: widget.initialTitle ?? 'Video_$vid',
      duration: 0,
      thumbnail: widget.initialThumbnail ?? '',
    );

    setState(() {
      _currentVideo = tempVideo;
      _videos = [tempVideo];
      _isLoadingList = false;
      _isInitialLoading = false;
    });
  }

  Future<void> _onVideoTap(VideoItem video) async {
    if (_isSwitchingVideo) return;
    if (_lastSwitchTime != null &&
        DateTime.now().difference(_lastSwitchTime!).inMilliseconds < _debounceMs) {
      return;
    }
    if (_currentVideo?.vid == video.vid) return;

    setState(() {
      _isSwitchingVideo = true;
      _lastSwitchTime = DateTime.now();
      _currentVideo = video;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isSwitchingVideo = false);
    }
  }

  Future<void> _toggleFullscreen() async {
    setState(() => _isFullscreen = !_isFullscreen);

    if (_isFullscreen) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> _exitFullscreen() async {
    if (!_isFullscreen) return;
    await _toggleFullscreen();
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _controller.dispose();
    _danmakuSettings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF6366F1)),
              const SizedBox(height: 16),
              Text('加载中...', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    // 全屏模式
    if (_isFullscreen) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) await _exitFullscreen();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: _buildPlayerWithOverlay(),
        ),
      );
    }

    // 竖屏模式
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          _buildTopBar(),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildPlayerWithOverlay(),
          ),
          _buildVideoInfo(),
          Expanded(child: _buildVideoList()),
        ],
      ),
    );
  }

  Widget _buildPlayerWithOverlay() {
    return Stack(
      children: [
        // 核心播放器 - 使用 PolyvVideoPlayer
        PolyvVideoPlayer(
          vid: _currentVideo?.vid ?? '',
          controller: _controller,
          autoPlay: true,
          enableDanmaku: true,
          enableGestures: true,
          enableDoubleTapFullscreen: false, // 由页面处理全屏
          danmakuService: _danmakuService,
          danmakuSettings: _danmakuSettings,
          onFullscreenChanged: (isFullscreen) {
            if (isFullscreen && !_isFullscreen) {
              _toggleFullscreen();
            }
          },
        ),

        // 设置按钮（example 特有）
        Positioned(
          right: 8,
          top: 8,
          child: IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _currentVideo != null
                ? () => SettingsMenu.show(
                    context: context,
                    controller: _controller,
                    videoTitle: _currentVideo!.title,
                    downloadCallbacks: this,
                  )
                : null,
          ),
        ),

        // 视频切换遮罩
        if (_isSwitchingVideo)
          Positioned.fill(child: Container(color: Colors.black)),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: const Color(0xFF0F172A),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            children: [
              const Center(
                child: Text(
                  '长视频',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded),
                    color: Colors.white,
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded),
                    color: Colors.white,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentVideo?.title ?? '选择一个视频',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currentVideo?.duration != null
                ? '时长: ${Duration(milliseconds: _currentVideo!.duration).inMinutes} 分钟'
                : '',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoList() {
    return Container(
      color: const Color(0xFF0A0A0F),
      child: VideoListView(
        videos: _videos,
        currentVid: _currentVideo?.vid,
        onVideoTap: _onVideoTap,
        isLoading: _isLoadingList,
        isLoadingMore: _isLoadingMore,
        hasMore: _hasMore,
        onLoadMore: _loadMoreVideos,
        error: _listError,
        isSwitching: _isSwitchingVideo,
      ),
    );
  }
}
