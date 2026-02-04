import 'package:flutter/services.dart';

import '../../platform_channel/method_channel_handler.dart';

class DownloadNativeRepository {
  final MethodChannel _channel;

  const DownloadNativeRepository({required MethodChannel channel})
    : _channel = channel;

  Future<void> pauseDownload(String vid) {
    return MethodChannelHandler.pauseDownload(_channel, vid);
  }

  Future<void> resumeDownload(String vid) {
    return MethodChannelHandler.resumeDownload(_channel, vid);
  }

  Future<void> retryDownload(String vid) {
    return MethodChannelHandler.retryDownload(_channel, vid);
  }

  Future<void> deleteDownload(String vid) {
    return MethodChannelHandler.deleteDownload(_channel, vid);
  }

  Future<List<Map<String, dynamic>>> getDownloadList() {
    return MethodChannelHandler.getDownloadList(_channel);
  }
}
