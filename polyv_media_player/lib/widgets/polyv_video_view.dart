import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

/// Polyv 视频视图组件
///
/// 在 iOS 上使用原生 PLVVodVideoView 渲染视频
class PolyvVideoView extends StatefulWidget {
  const PolyvVideoView({super.key, this.keySeed});
  final Object? keySeed;

  @override
  State<PolyvVideoView> createState() => _PolyvVideoViewState();
}

class _PolyvVideoViewState extends State<PolyvVideoView> {
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        key: widget.keySeed == null ? null : ValueKey(widget.keySeed),
        viewType: 'com.polyv.media_player/video_view',
        creationParams: null,
        creationParamsCodec: StandardMessageCodec(),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        key: widget.keySeed == null ? null : ValueKey(widget.keySeed),
        viewType: 'com.polyv.media_player/video_view',
        creationParams: null,
        creationParamsCodec: StandardMessageCodec(),
      );
    }
    return const Center(
      child: Text('Video view not implemented for this platform'),
    );
  }
}
