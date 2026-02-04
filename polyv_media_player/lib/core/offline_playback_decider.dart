typedef IsVideoDownloaded = bool Function(String vid);

class OfflinePlaybackDecider {
  final IsVideoDownloaded _isDownloaded;

  const OfflinePlaybackDecider({required IsVideoDownloaded isDownloaded})
    : _isDownloaded = isDownloaded;

  bool shouldUseOfflineMode(String vid) {
    return _isDownloaded(vid);
  }
}
