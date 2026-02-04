import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'download_task.dart';
import 'download_task_status.dart';
import '../../platform_channel/player_api.dart';
import 'download_event_handler.dart';
import 'download_native_repository.dart';
import 'download_task_store.dart';
import '../../utils/plv_logger.dart';

/// 下载状态管理器
///
/// 使用 Provider 的 ChangeNotifier 模式管理所有下载任务的状态。
/// 职责：
/// - 维护任务列表（从 SDK 同步）
/// - 提供任务筛选方法（下载中/已完成）
/// - 通知 UI 状态更新
/// - 调用原生层暂停/继续下载方法
/// - Story 9.8: 监听原生下载事件流
///
/// Story 9.3: 增强 pauseTask/resumeTask 调用 Platform Channel
/// Story 9.7: 强一致性 - 原生调用成功才更新本地状态
/// Story 9.8: 权威同步 - getDownloadList + EventChannel 事件流
///
/// 注意：这是一个内存中的状态管理器，实际应用中需要通过 Platform Channel
/// 与原生 SDK 同步数据，并在必要时持久化到本地存储。
class DownloadStateManager extends ChangeNotifier {
  /// 构造函数
  ///
  /// [channel] 可选的 MethodChannel，用于测试时注入 mock channel
  /// [eventChannel] 可选的 EventChannel，用于测试时注入 mock event channel
  /// [enableEventListener] 是否启用事件监听，默认为 true。设置为 false 可跳过 EventChannel 订阅（用于测试）
  DownloadStateManager({
    MethodChannel? channel,
    EventChannel? eventChannel,
    bool enableEventListener = true,
  }) : _channel = channel ?? _defaultChannel,
       _eventChannel = eventChannel ?? _defaultEventChannel,
       _store = DownloadTaskStore() {
    _nativeRepository = DownloadNativeRepository(channel: _channel);
    _eventHandler = DownloadEventHandler(store: _store);
    if (enableEventListener) {
      _startEventListener();
    }
  }

  /// 默认的 Platform Channel
  static const MethodChannel _defaultChannel = MethodChannel(
    PlayerApi.methodChannelName,
  );

  /// 默认的 Event Channel
  static const EventChannel _defaultEventChannel = EventChannel(
    PlayerApi.downloadEventChannelName,
  );

  /// Platform Channel 用于与原生层通信
  final MethodChannel _channel;

  /// Event Channel 用于接收原生层推送的下载事件
  final EventChannel _eventChannel;

  /// EventChannel 订阅（用于dispose时取消）
  StreamSubscription<dynamic>? _eventSubscription;

  /// 正在删除的任务 ID 集合，用于防止删除过程中的竞态条件
  Set<String> get _deletingTaskIds => _store.deletingTaskIds;

  /// 缓存暂停时的进度，用于恢复时避免显示0%
  /// Key: taskId, Value: downloadedBytes
  Map<String, int> get _cachedProgress => _store.cachedProgress;

  final DownloadTaskStore _store;
  late final DownloadNativeRepository _nativeRepository;
  late final DownloadEventHandler _eventHandler;

  /// Story 9.8: 启动 EventChannel 事件监听
  void _startEventListener() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is Map) {
          handleDownloadEvent(Map<String, dynamic>.from(event));
        }
      },
      onError: (dynamic error) {
        PlvLogger.w('DownloadStateManager: EventChannel error - $error');
      },
    );
  }

  /// 所有下载任务
  List<DownloadTask> get _tasks => _store.tasks;

  /// 获取所有任务（不可变副本）
  List<DownloadTask> get tasks => _store.tasks;

  /// 获取下载中的任务
  ///
  /// 包含：准备中、等待中、下载中、已暂停、失败的任务
  List<DownloadTask> get downloadingTasks {
    return _store.downloadingTasks;
  }

  /// 获取已完成的任务
  List<DownloadTask> get completedTasks {
    return _store.completedTasks;
  }

  /// 获取活跃下载任务（正在下载，不包括暂停和失败）
  List<DownloadTask> get activeTasks {
    return _store.activeTasks;
  }

  /// 获取任务数量
  int get downloadingCount => _store.downloadingCount;
  int get completedCount => _store.completedCount;
  int get totalCount => _store.totalCount;

  /// 根据 ID 查找任务
  DownloadTask? getTaskById(String id) {
    return _store.getTaskById(id);
  }

  /// 根据 VID 查找任务
  DownloadTask? getTaskByVid(String vid) {
    return _store.getTaskByVid(vid);
  }

  /// 添加新任务
  void addTask(DownloadTask task) {
    // 检查是否已存在相同任务（通过 id/vid 检查）
    final existingIndex = _tasks.indexWhere((t) => t.id == task.id);
    if (existingIndex >= 0) {
      // 更新现有任务
      PlvLogger.d(
        '[DownloadStateManager] addTask: updating existing task id=${task.id}, vid=${task.vid}',
      );
      _store.updateTask(task.id, task);
    } else {
      // 添加新任务
      PlvLogger.d(
        '[DownloadStateManager] addTask: adding new task id=${task.id}, vid=${task.vid}',
      );
      PlvLogger.d(
        '[DownloadStateManager] addTask: current tasks count=${_tasks.length}',
      );
      _store.addTask(task);
    }
    notifyListeners();
  }

  /// 批量添加任务
  void addTasks(List<DownloadTask> tasks) {
    for (final task in tasks) {
      final existingIndex = _tasks.indexWhere((t) => t.id == task.id);
      if (existingIndex >= 0) {
        _store.updateTask(task.id, task);
      } else {
        _store.addTask(task);
      }
    }
    notifyListeners();
  }

  /// 更新任务状态
  void updateTask(String id, DownloadTask updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index >= 0) {
      _store.updateTask(id, updatedTask);
      PlvLogger.d(
        '[DownloadStateManager] updateTask: notifying listeners for id=$id, progress=${updatedTask.progressPercent}%',
      );
      notifyListeners();
    } else {
      PlvLogger.d(
        '[DownloadStateManager] updateTask: task not found for id=$id',
      );
    }
  }

  /// 更新任务的部分属性
  void updateTaskProgress(
    String id, {
    int? downloadedBytes,
    int? bytesPerSecond,
    DownloadTaskStatus? status,
    String? errorMessage,
  }) {
    final task = getTaskById(id);
    if (task == null) {
      PlvLogger.d(
        '[DownloadStateManager] updateTaskProgress: task not found for id=$id',
      );
      return;
    }

    final updated = _store.updateTaskProgress(
      id,
      downloadedBytes: downloadedBytes,
      bytesPerSecond: bytesPerSecond,
      status: status,
      errorMessage: errorMessage,
    );

    if (!updated) {
      return;
    }

    final updatedTask = getTaskById(id);
    if (updatedTask == null) return;

    PlvLogger.d(
      '[DownloadStateManager] updateTaskProgress: id=$id, '
      'progress=${updatedTask.progressPercent}%, '
      'downloadedBytes=${updatedTask.downloadedBytes}, '
      'totalBytes=${updatedTask.totalBytes}',
    );
    notifyListeners();
  }

  /// 删除任务
  void removeTask(String id) {
    _store.removeTask(id);
    notifyListeners();
  }

  /// 删除下载任务
  ///
  /// Story 9.5: 调用原生层删除方法，清理本地状态
  /// Story 9.7: 强一致性 - 原生调用成功才更新本地状态
  ///
  /// 行为说明：
  /// - 状态验证：任务不存在时静默忽略
  /// - 调用原生层删除方法
  /// - **强一致性**：只有原生层调用成功才更新本地状态
  /// - 原生层失败时抛出 PlatformException，本地状态保持不变
  /// - **竞态条件防护**：删除过程中忽略该任务的所有事件
  Future<void> deleteTask(String id) async {
    final task = getTaskById(id);
    if (task == null) return;

    // 标记为正在删除，防止事件处理中的竞态条件
    _deletingTaskIds.add(id);
    try {
      // 强一致：原生调用成功才更新本地状态
      // 如果原生层调用失败，MethodChannelHandler.deleteDownload 会抛出 PlatformException
      // 异常会中断执行，本地状态不会被修改
      await _nativeRepository.deleteDownload(task.vid);

      removeTask(id);
    } finally {
      // 无论成功失败，都清除删除标记
      _deletingTaskIds.remove(id);
    }
  }

  /// 批量删除任务
  void removeTasks(List<String> ids) {
    _store.removeTasks(ids);
    notifyListeners();
  }

  /// 清空所有任务
  void clearAll() {
    _store.clearAll();
    notifyListeners();
  }

  /// 清空已完成的任务
  void clearCompleted() {
    _store.clearCompleted();
    notifyListeners();
  }

  /// 替换所有任务（用于从 SDK 同步完整列表）
  void replaceAll(List<DownloadTask> tasks) {
    _store.replaceAll(tasks);
    notifyListeners();
  }

  /// Story 9.8: 从原生 SDK 同步权威任务列表
  ///
  /// 调用原生层 getDownloadList 方法获取当前所有下载任务，
  /// 并用权威列表完全替换本地状态。
  ///
  /// 返回值：
  /// - 成功时返回 null
  /// - 失败时返回错误信息字符串
  ///
  /// 使用场景：
  /// - 下载中心页面初始化时调用
  /// - 应用从后台恢复时调用
  /// - 热重载后恢复状态
  Future<String?> syncFromNative() async {
    try {
      PlvLogger.d(
        '[DownloadStateManager] syncFromNative: calling getDownloadList...',
      );
      final List<Map<String, dynamic>> rawList = await _nativeRepository
          .getDownloadList();

      PlvLogger.d(
        '[DownloadStateManager] syncFromNative: received ${rawList.length} tasks from native',
      );

      final List<DownloadTask> tasks = rawList
          .map((json) => DownloadTask.fromJson(json))
          .toList();

      // 打印每个任务的 vid 和状态
      for (final task in tasks) {
        PlvLogger.d(
          '[DownloadStateManager] syncFromNative: task vid=${task.vid}, id=${task.id}, status=${task.status.name}',
        );
      }

      replaceAll(tasks);
      return null;
    } on PlatformException catch (e) {
      PlvLogger.w(
        '[DownloadStateManager] syncFromNative: PlatformException - ${e.message}',
      );
      return e.message ?? '同步下载列表失败';
    } catch (e) {
      PlvLogger.w('[DownloadStateManager] syncFromNative: Exception - $e');
      return '同步下载列表失败: $e';
    }
  }

  /// Story 9.8: 处理原生层推送的下载事件
  ///
  /// 根据事件类型更新对应任务的状态。
  /// 事件格式：{ "type": "taskProgress|taskCompleted|taskFailed|taskRemoved|taskPaused|taskResumed", "data": { ... } }
  void handleDownloadEvent(Map<String, dynamic> event) {
    final updated = _eventHandler.handleDownloadEvent(event);
    if (updated) {
      notifyListeners();
    }
  }

  /// 暂停任务
  ///
  /// Story 9.3: 增强的暂停逻辑
  /// Story 9.7: 强一致性 - 原生调用成功才更新本地状态
  ///
  /// 行为说明：
  /// - 不能暂停已完成的任务（静默忽略）
  /// - 不能暂停已暂停的任务（静默忽略）
  /// - 不能暂停失败状态的任务（应该使用 retry）
  /// - 可以暂停活跃任务（准备中、等待中、下载中）
  /// - **强一致性**：只有原生层调用成功才更新本地状态
  /// - 原生层失败时抛出 PlatformException，本地状态保持不变
  Future<void> pauseTask(String id) async {
    final task = getTaskById(id);
    if (task == null) return;

    // 状态转换验证：不能暂停已完成、已暂停或失败的任务
    if (task.status == DownloadTaskStatus.completed ||
        task.status == DownloadTaskStatus.paused) {
      // 静默忽略 - 符合 AC 规范
      return;
    }

    if (task.status == DownloadTaskStatus.error) {
      // 失败状态应该使用重试，不支持暂停
      return;
    }

    // 缓存当前下载字节数，用于恢复时避免显示0%
    _cachedProgress[id] = task.downloadedBytes;
    PlvLogger.d(
      '[DownloadStateManager] pauseTask: cached progress for id=$id, bytes=${task.downloadedBytes}',
    );

    // 强一致：原生调用成功才更新本地状态
    // 如果原生层调用失败，MethodChannelHandler.pauseDownload 会抛出 PlatformException
    // 异常会中断执行，本地状态不会被修改
    await _nativeRepository.pauseDownload(task.vid);

    updateTaskProgress(id, status: DownloadTaskStatus.paused);
  }

  /// 恢复任务
  ///
  /// Story 9.3: 增强的恢复逻辑
  /// Story 9.7: 强一致性 - 原生调用成功才更新本地状态
  ///
  /// 行为说明：
  /// - 只能恢复已暂停的任务
  /// - 不能恢复已完成或正在下载的任务（静默忽略）
  /// - **强一致性**：只有原生层调用成功才更新本地状态
  /// - 原生层失败时抛出 PlatformException，本地状态保持不变
  Future<void> resumeTask(String id) async {
    final task = getTaskById(id);
    if (task == null) return;

    // 状态转换验证：不能恢复已完成或正在下载的任务
    if (task.status == DownloadTaskStatus.completed) {
      // 静默忽略 - 符合 AC 规范
      return;
    }

    if (task.status == DownloadTaskStatus.downloading) {
      // 已经在下载中，无需重复操作
      return;
    }

    // 强一致：原生调用成功才更新本地状态
    // 如果原生层调用失败，MethodChannelHandler.resumeDownload 会抛出 PlatformException
    // 异常会中断执行，本地状态不会被修改
    await _nativeRepository.resumeDownload(task.vid);

    updateTaskProgress(id, status: DownloadTaskStatus.downloading);
  }

  /// 重试失败任务
  ///
  /// Story 9.3: 增强的重试逻辑
  /// Story 9.7: 强一致性 - 原生调用成功才更新本地状态
  ///
  /// 行为说明：
  /// - 失败任务才允许重试
  /// - 清除错误信息
  /// - 调用原生层重试方法
  /// - 重置下载速度
  /// - **强一致性**：只有原生层调用成功才更新本地状态
  /// - 原生层失败时抛出 PlatformException，本地状态保持不变
  Future<void> retryTask(String id) async {
    final task = getTaskById(id);
    if (task == null) return;

    // 失败任务才允许重试
    if (task.status != DownloadTaskStatus.error) {
      return;
    }

    // 强一致：原生调用成功才更新本地状态
    // 如果原生层调用失败，MethodChannelHandler.retryDownload 会抛出 PlatformException
    // 异常会中断执行，本地状态不会被修改
    await _nativeRepository.retryDownload(task.vid);

    final updatedTask = task.copyWith(
      status: DownloadTaskStatus.downloading,
      errorMessage: DownloadTask.clearValue, // 清除错误信息
      bytesPerSecond: 0,
    );

    updateTask(id, updatedTask);
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  // ========== 单例模式支持 ==========

  /// 单例实例，用于方便访问下载状态管理器
  ///
  /// 使用场景：
  /// - PlayerController 需要检测视频是否已下载以决定播放模式
  /// - 其他需要全局访问下载状态的组件
  static DownloadStateManager? _instance;

  /// 获取单例实例
  ///
  /// 如果实例不存在，会创建一个新的实例。
  /// 注意：使用单例时需要确保调用了 enableEventListener=false 的构造函数，
  /// 因为单例不应该重复创建 EventChannel 订阅。
  static DownloadStateManager get instance {
    _instance ??= DownloadStateManager(enableEventListener: false);
    return _instance!;
  }

  /// 重置单例实例
  ///
  /// 使用场景：
  /// - 测试时需要重置状态
  /// - 应用退出时清理资源
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }
}

/// 下载状态管理器扩展 - 用于 Provider 的便捷方法
extension DownloadStateManagerExtension on DownloadStateManager {
  /// 检查是否有指定 VID 的任务
  bool hasTaskWithVid(String vid) {
    return getTaskByVid(vid) != null;
  }

  /// 获取指定 VID 的任务状态
  DownloadTaskStatus? getStatusForVid(String vid) {
    return getTaskByVid(vid)?.status;
  }

  /// 检查指定 VID 是否已完成下载
  bool isCompleted(String vid) {
    return getTaskByVid(vid)?.status == DownloadTaskStatus.completed;
  }
}
