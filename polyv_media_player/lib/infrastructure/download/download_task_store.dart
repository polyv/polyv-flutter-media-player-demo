import 'download_task.dart';
import 'download_task_status.dart';

class DownloadTaskStore {
  List<DownloadTask> _tasks = [];

  final Set<String> deletingTaskIds = {};
  final Map<String, int> cachedProgress = {};

  List<DownloadTask> get tasks => List.unmodifiable(_tasks);

  List<DownloadTask> get downloadingTasks {
    return _tasks.where((t) => t.status.isInProgress).toList();
  }

  List<DownloadTask> get completedTasks {
    return _tasks.where((t) => t.status == DownloadTaskStatus.completed).toList();
  }

  List<DownloadTask> get activeTasks {
    return _tasks.where((t) => t.status.isActive).toList();
  }

  int get downloadingCount => downloadingTasks.length;
  int get completedCount => completedTasks.length;
  int get totalCount => _tasks.length;

  DownloadTask? getTaskById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  DownloadTask? getTaskByVid(String vid) {
    try {
      return _tasks.firstWhere((t) => t.vid == vid);
    } catch (_) {
      return null;
    }
  }

  bool addTask(DownloadTask task) {
    final existingIndex = _tasks.indexWhere((t) => t.id == task.id);
    if (existingIndex >= 0) {
      if (_tasks[existingIndex] == task) return false;
      _tasks[existingIndex] = task;
      return true;
    }

    _tasks.add(task);
    return true;
  }

  bool addTasks(List<DownloadTask> tasks) {
    var changed = false;
    for (final task in tasks) {
      changed = addTask(task) || changed;
    }
    return changed;
  }

  bool updateTask(String id, DownloadTask updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index < 0) return false;

    if (_tasks[index] == updatedTask) return false;
    _tasks[index] = updatedTask;
    return true;
  }

  bool updateTaskProgress(
    String id, {
    int? downloadedBytes,
    int? bytesPerSecond,
    DownloadTaskStatus? status,
    String? errorMessage,
  }) {
    final task = getTaskById(id);
    if (task == null) return false;

    final updatedTask = task.copyWith(
      downloadedBytes: downloadedBytes,
      bytesPerSecond: bytesPerSecond,
      status: status,
      errorMessage: errorMessage,
      completedAt:
          status == DownloadTaskStatus.completed ? DateTime.now() : task.completedAt,
    );

    return updateTask(id, updatedTask);
  }

  bool removeTask(String id) {
    final before = _tasks.length;
    _tasks.removeWhere((t) => t.id == id);
    return _tasks.length != before;
  }

  bool removeTasks(List<String> ids) {
    final before = _tasks.length;
    _tasks.removeWhere((t) => ids.contains(t.id));
    return _tasks.length != before;
  }

  bool clearAll() {
    if (_tasks.isEmpty) return false;
    _tasks.clear();
    return true;
  }

  bool clearCompleted() {
    final before = _tasks.length;
    _tasks.removeWhere((t) => t.status == DownloadTaskStatus.completed);
    return _tasks.length != before;
  }

  bool replaceAll(List<DownloadTask> tasks) {
    _tasks = List.from(tasks);
    return true;
  }
}
