import 'download_task.dart';
import 'download_task_status.dart';
import 'download_task_store.dart';
import '../../utils/plv_logger.dart';

class DownloadEventHandler {
  final DownloadTaskStore _store;

  DownloadEventHandler({required DownloadTaskStore store}) : _store = store;

  bool handleDownloadEvent(Map<String, dynamic> event) {
    final String? type = event['type'] as String?;
    final dynamic rawData = event['data'];
    final Map<String, dynamic>? data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : null;

    if (type == null || data == null) {
      PlvLogger.d(
        '[DownloadStateManager] handleDownloadEvent: invalid event, type=$type, data=$data',
      );
      return false;
    }

    final String? id = data['id'] as String?;
    if (id == null) {
      PlvLogger.d(
        '[DownloadStateManager] handleDownloadEvent: missing id in data',
      );
      return false;
    }

    if (_store.deletingTaskIds.contains(id)) {
      PlvLogger.d(
        '[DownloadStateManager] handleDownloadEvent: ignoring event for deleting task id=$id',
      );
      return false;
    }

    switch (type) {
      case 'taskProgress':
        return _handleTaskProgress(id, data);
      case 'taskCompleted':
        return _handleTaskCompleted(id, data);
      case 'taskFailed':
        return _handleTaskFailed(id, data);
      case 'taskRemoved':
        return _handleTaskRemoved(id);
      case 'taskPaused':
        return _handleTaskPaused(id);
      case 'taskResumed':
        return _handleTaskResumed(id);
      default:
        return false;
    }
  }

  bool _handleTaskProgress(String id, Map<String, dynamic> data) {
    final task = _store.getTaskById(id);
    if (task == null) {
      if (_canCreateTaskFromData(data)) {
        final newTask = DownloadTask.fromJson({
          'id': id,
          ...data,
          'createdAt': DateTime.now().toIso8601String(),
        });
        return _store.addTask(newTask);
      }
      return false;
    }

    final int? eventDownloadedBytes = data['downloadedBytes'] as int?;
    int? effectiveDownloadedBytes = eventDownloadedBytes;

    if (_store.cachedProgress.containsKey(id)) {
      final cachedBytes = _store.cachedProgress[id]!;
      if (eventDownloadedBytes == null || eventDownloadedBytes < cachedBytes) {
        effectiveDownloadedBytes = cachedBytes;
      } else if (eventDownloadedBytes > cachedBytes) {
        _store.cachedProgress.remove(id);
      }
    }

    return _store.updateTaskProgress(
      id,
      downloadedBytes: effectiveDownloadedBytes,
      bytesPerSecond: data['bytesPerSecond'] as int?,
      status: _parseStatusFromString(data['status'] as String?),
    );
  }

  bool _canCreateTaskFromData(Map<String, dynamic> data) {
    return data.containsKey('vid') &&
        data.containsKey('title') &&
        data.containsKey('totalBytes');
  }

  bool _handleTaskCompleted(String id, Map<String, dynamic> data) {
    final task = _store.getTaskById(id);
    if (task == null) return false;

    _store.cachedProgress.remove(id);

    final completedAtStr = data['completedAt'] as String?;
    final completedAt = completedAtStr != null
        ? DateTime.tryParse(completedAtStr)
        : null;

    final updatedTask = task.copyWith(
      status: DownloadTaskStatus.completed,
      downloadedBytes: task.totalBytes,
      bytesPerSecond: 0,
      completedAt: completedAt ?? DateTime.now(),
    );

    return _store.updateTask(id, updatedTask);
  }

  bool _handleTaskFailed(String id, Map<String, dynamic> data) {
    final task = _store.getTaskById(id);
    if (task == null) return false;

    _store.cachedProgress.remove(id);

    final errorMessage = data['errorMessage'] as String?;

    final updatedTask = task.copyWith(
      status: DownloadTaskStatus.error,
      errorMessage: errorMessage,
      bytesPerSecond: 0,
    );

    return _store.updateTask(id, updatedTask);
  }

  bool _handleTaskRemoved(String id) {
    _store.cachedProgress.remove(id);
    return _store.removeTask(id);
  }

  bool _handleTaskPaused(String id) {
    return _store.updateTaskProgress(
      id,
      status: DownloadTaskStatus.paused,
      bytesPerSecond: 0,
    );
  }

  bool _handleTaskResumed(String id) {
    return _store.updateTaskProgress(
      id,
      status: DownloadTaskStatus.downloading,
    );
  }

  DownloadTaskStatus? _parseStatusFromString(String? statusStr) {
    if (statusStr == null) return null;
    for (final status in DownloadTaskStatus.values) {
      if (status.name == statusStr) return status;
    }
    return null;
  }
}
