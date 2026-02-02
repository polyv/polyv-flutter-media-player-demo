import 'package:flutter_test/flutter_test.dart';
import 'package:polyv_media_player/infrastructure/download/download_task_status.dart';

/// DownloadTaskStatus 单元测试
///
/// Story 9.1: 下载中心页面框架
///
/// 测试下载任务状态枚举及其扩展方法的正确性
void main() {
  group('DownloadTaskStatus 枚举测试', () {
    test('[P1] 所有状态值存在且唯一', () {
      // 验证所有状态值
      const statuses = [
        DownloadTaskStatus.preparing,
        DownloadTaskStatus.waiting,
        DownloadTaskStatus.downloading,
        DownloadTaskStatus.paused,
        DownloadTaskStatus.completed,
        DownloadTaskStatus.error,
      ];

      expect(statuses.length, equals(6));
      expect(statuses.toSet().length, equals(6)); // 确保无重复
    });

    test('[P2] 状态名称正确', () {
      expect(DownloadTaskStatus.preparing.name, 'preparing');
      expect(DownloadTaskStatus.waiting.name, 'waiting');
      expect(DownloadTaskStatus.downloading.name, 'downloading');
      expect(DownloadTaskStatus.paused.name, 'paused');
      expect(DownloadTaskStatus.completed.name, 'completed');
      expect(DownloadTaskStatus.error.name, 'error');
    });
  });

  group('DownloadTaskStatusExtension - isActive 测试', () {
    test('[P1] 活跃状态返回 true', () {
      // preparing, waiting, downloading 是活跃状态
      expect(DownloadTaskStatus.preparing.isActive, isTrue);
      expect(DownloadTaskStatus.waiting.isActive, isTrue);
      expect(DownloadTaskStatus.downloading.isActive, isTrue);
    });

    test('[P1] 非活跃状态返回 false', () {
      // paused, completed, error 不是活跃状态
      expect(DownloadTaskStatus.paused.isActive, isFalse);
      expect(DownloadTaskStatus.completed.isActive, isFalse);
      expect(DownloadTaskStatus.error.isActive, isFalse);
    });
  });

  group('DownloadTaskStatusExtension - isInProgress 测试', () {
    test('[P1] 未完成状态返回 true', () {
      // preparing, waiting, downloading, paused, error 在下载中 Tab
      expect(DownloadTaskStatus.preparing.isInProgress, isTrue);
      expect(DownloadTaskStatus.waiting.isInProgress, isTrue);
      expect(DownloadTaskStatus.downloading.isInProgress, isTrue);
      expect(DownloadTaskStatus.paused.isInProgress, isTrue);
      expect(DownloadTaskStatus.error.isInProgress, isTrue);
    });

    test('[P1] 已完成状态返回 false', () {
      // completed 不在下载中 Tab
      expect(DownloadTaskStatus.completed.isInProgress, isFalse);
    });
  });

  group('DownloadTaskStatusExtension - isTerminal 测试', () {
    test('[P1] 终端状态返回 true', () {
      // completed 和 error 是终端状态
      expect(DownloadTaskStatus.completed.isTerminal, isTrue);
      expect(DownloadTaskStatus.error.isTerminal, isTrue);
    });

    test('[P1] 非终端状态返回 false', () {
      // preparing, waiting, downloading, paused 不是终端状态
      expect(DownloadTaskStatus.preparing.isTerminal, isFalse);
      expect(DownloadTaskStatus.waiting.isTerminal, isFalse);
      expect(DownloadTaskStatus.downloading.isTerminal, isFalse);
      expect(DownloadTaskStatus.paused.isTerminal, isFalse);
    });
  });

  group('DownloadTaskStatusExtension - displayLabel 测试', () {
    test('[P1] 所有状态标签正确显示', () {
      expect(DownloadTaskStatus.preparing.displayLabel, '准备中');
      expect(DownloadTaskStatus.waiting.displayLabel, '等待中');
      expect(DownloadTaskStatus.downloading.displayLabel, '下载中');
      expect(DownloadTaskStatus.paused.displayLabel, '已暂停');
      expect(DownloadTaskStatus.completed.displayLabel, '已完成');
      expect(DownloadTaskStatus.error.displayLabel, '下载失败');
    });

    test('[P2] 标签不为空', () {
      for (final status in DownloadTaskStatus.values) {
        expect(status.displayLabel.isNotEmpty, isTrue);
        expect(status.displayLabel, isNotNull);
      }
    });
  });

  group('状态分类逻辑验证', () {
    test('[P1] 下载中 Tab 包含所有未完成的任务', () {
      // 验证 isInProgress 的语义
      final inProgressStatuses = DownloadTaskStatus.values
          .where((s) => s.isInProgress)
          .toList();

      expect(
        inProgressStatuses,
        containsAll([
          DownloadTaskStatus.preparing,
          DownloadTaskStatus.waiting,
          DownloadTaskStatus.downloading,
          DownloadTaskStatus.paused,
          DownloadTaskStatus.error,
        ]),
      );
      expect(inProgressStatuses, isNot(contains(DownloadTaskStatus.completed)));
    });

    test('[P1] 已完成 Tab 只包含完成状态', () {
      // 验证已完成任务的筛选逻辑
      final completedStatuses = DownloadTaskStatus.values
          .where((s) => !s.isInProgress && s == DownloadTaskStatus.completed)
          .toList();

      expect(completedStatuses, equals([DownloadTaskStatus.completed]));
    });

    test('[P1] 活跃下载用于统计正在进行的任务', () {
      // 验证 isActive 用于统计活跃任务
      final activeStatuses = DownloadTaskStatus.values
          .where((s) => s.isActive)
          .toList();

      expect(
        activeStatuses,
        containsAll([
          DownloadTaskStatus.preparing,
          DownloadTaskStatus.waiting,
          DownloadTaskStatus.downloading,
        ]),
      );
      expect(activeStatuses, isNot(contains(DownloadTaskStatus.paused)));
    });

    test('[P1] 终端状态用于判断任务结束', () {
      // 验证 isTerminal 用于判断任务是否结束
      final terminalStatuses = DownloadTaskStatus.values
          .where((s) => s.isTerminal)
          .toList();

      expect(
        terminalStatuses,
        equals([DownloadTaskStatus.completed, DownloadTaskStatus.error]),
      );
    });
  });

  group('状态转换场景验证', () {
    test('[场景1][P1] preparing -> downloading 状态转换', () {
      // 场景：任务从准备中转为下载中
      final preparing = DownloadTaskStatus.preparing;
      final downloading = DownloadTaskStatus.downloading;

      expect(preparing.isActive, isTrue);
      expect(preparing.isInProgress, isTrue);
      expect(downloading.isActive, isTrue);
      expect(downloading.isInProgress, isTrue);
    });

    test('[场景2][P1] downloading -> paused 状态转换', () {
      // 场景：用户暂停下载
      final downloading = DownloadTaskStatus.downloading;
      final paused = DownloadTaskStatus.paused;

      expect(downloading.isActive, isTrue);
      expect(paused.isActive, isFalse); // 暂停后不再活跃
      expect(paused.isInProgress, isTrue); // 但仍在下载中 Tab
    });

    test('[场景3][P1] paused -> downloading 状态恢复', () {
      // 场景：用户恢复下载
      final paused = DownloadTaskStatus.paused;
      final downloading = DownloadTaskStatus.downloading;

      expect(paused.isActive, isFalse);
      expect(downloading.isActive, isTrue);
    });

    test('[场景4][P1] downloading -> completed 状态完成', () {
      // 场景：下载成功完成
      final downloading = DownloadTaskStatus.downloading;
      final completed = DownloadTaskStatus.completed;

      expect(downloading.isInProgress, isTrue);
      expect(completed.isInProgress, isFalse); // 不在下载中 Tab
      expect(completed.isTerminal, isTrue);
    });

    test('[场景5][P1] downloading -> error 状态失败', () {
      // 场景：下载失败
      final downloading = DownloadTaskStatus.downloading;
      final error = DownloadTaskStatus.error;

      expect(downloading.isInProgress, isTrue);
      expect(error.isInProgress, isTrue); // 失败仍在下载��� Tab
      expect(error.isTerminal, isTrue);
    });

    test('[场景6][P1] error -> downloading 状态重试', () {
      // 场景：重试失败的任务
      final error = DownloadTaskStatus.error;
      final downloading = DownloadTaskStatus.downloading;

      expect(error.isTerminal, isTrue);
      expect(downloading.isTerminal, isFalse);
      expect(downloading.isActive, isTrue);
    });
  });

  group('边缘情况', () {
    test('[P2] 所有状态都有对应的显示标签', () {
      for (final status in DownloadTaskStatus.values) {
        final label = status.displayLabel;
        expect(label, isNotNull);
        expect(label, isNotEmpty);
        expect(label.length, greaterThan(0));
      }
    });

    test('[P2] 状态枚举完整性检查', () {
      // 确保枚举值数量符合预期
      expect(DownloadTaskStatus.values.length, equals(6));

      // 确保包含所有预期状态
      expect(
        DownloadTaskStatus.values,
        containsAll([
          DownloadTaskStatus.preparing,
          DownloadTaskStatus.waiting,
          DownloadTaskStatus.downloading,
          DownloadTaskStatus.paused,
          DownloadTaskStatus.completed,
          DownloadTaskStatus.error,
        ]),
      );
    });

    test('[P2] isActive 和 isInProgress 的关系', () {
      // isActive 应该是 isInProgress 的子集
      for (final status in DownloadTaskStatus.values) {
        if (status.isActive) {
          expect(
            status.isInProgress,
            isTrue,
            reason: '$status 是活跃的，应该在下载中 Tab',
          );
        }
      }
    });
  });
}
