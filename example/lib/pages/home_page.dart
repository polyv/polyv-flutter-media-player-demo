import 'package:flutter/material.dart';
import 'download_center/download_center_page.dart';
import 'long_video_page_simplified.dart';

/// HomePage - 首页入口组件
///
/// 精确还原 HTML 原型设计：垂直列表式按钮
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // 颜色常量 - 对应 Tailwind CSS 色值
  static const _slate900 = Color(0xFF0F172A);
  static const _slate800 = Color(0xFF1E293B);
  static const _slate400 = Color(0xFF94A3B8);
  static const _slate500 = Color(0xFF64748B);
  static const _slate600 = Color(0xFF475569);
  static const _primary = Color(0xFF6366F1); // Indigo-500
  static const _emerald400 = Color(0xFF34D399);
  static const _emerald500 = Color(0xFF10B981);
  static const _emerald600 = Color(0xFF059669);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_slate900, _slate800, _slate900],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Main Content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLongVideoButton(context),
                        const SizedBox(height: 16),
                        _buildDownloadCenterButton(context),
                      ],
                    ),
                  ),
                ),
              ),

              // Version Info
              _buildVersionInfo(),
            ],
          ),
        ),
      ),
    );
  }

  /// Header - 标题区域
  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.only(top: 32, bottom: 16),
      child: Column(
        children: [
          Text(
            'POLYV Demo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 4),
          Text('视频云服务演示', style: TextStyle(fontSize: 14, color: _slate400)),
        ],
      ),
    );
  }

  /// 长视频按钮 - 紫色渐变边框
  Widget _buildLongVideoButton(BuildContext context) {
    return Semantics(
      button: true,
      label: '长视频',
      hint: '点击进入长视频播放页面',
      child: _GradientBorderButton(
        gradientColors: const [
          Color(0xFF5A5FDD), // _primary with 0.9 alpha
          _primary,
        ],
        shadowColor: _primary.withValues(alpha: 0.25),
        onTap: () => _navigateToLongVideo(context),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: _primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '长视频',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '点播视频演示',
                    style: TextStyle(fontSize: 14, color: _slate400),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(Icons.chevron_right_rounded, color: _slate500, size: 20),
          ],
        ),
      ),
    );
  }

  /// 下载中心按钮 - 绿色渐变边框
  Widget _buildDownloadCenterButton(BuildContext context) {
    return Semantics(
      button: true,
      label: '下载中心',
      hint: '点击进入下载中心页面',
      child: _GradientBorderButton(
        gradientColors: const [
          Color(0xFF0EA589), // _emerald500 with 0.9 alpha
          _emerald600,
        ],
        shadowColor: _emerald500.withValues(alpha: 0.25),
        onTap: () => _navigateToDownloadCenter(context),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _emerald500.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.download_rounded,
                color: _emerald400,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '下载中心',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '离线视频管理',
                    style: TextStyle(fontSize: 14, color: _slate400),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(Icons.chevron_right_rounded, color: _slate500, size: 20),
          ],
        ),
      ),
    );
  }

  /// Version Info
  Widget _buildVersionInfo() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 24, top: 48),
      child: Text(
        'Version 1.0.0',
        style: TextStyle(fontSize: 12, color: _slate600),
      ),
    );
  }

  /// 导航到长视频页面
  void _navigateToLongVideo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LongVideoPage()),
    );
  }

  /// 导航到下载中心页面
  void _navigateToDownloadCenter(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DownloadCenterPage()),
    );
  }
}

/// 渐变边框按钮组件
///
/// 通过 Container + Decoration 实现渐变边框效果
class _GradientBorderButton extends StatefulWidget {
  final List<Color> gradientColors;
  final Color shadowColor;
  final VoidCallback onTap;
  final Widget child;

  const _GradientBorderButton({
    required this.gradientColors,
    required this.shadowColor,
    required this.onTap,
    required this.child,
  });

  @override
  State<_GradientBorderButton> createState() => _GradientBorderButtonState();
}

class _GradientBorderButtonState extends State<_GradientBorderButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          // 渐变边框效果（通过 Container 嵌套实现）
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.gradientColors,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(1), // 1px 边框
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

