/*
---------------------------------------------------------------
File name:          progress_manager.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.32.4
Description:        进度管理器 (Progress manager for CLI operations)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - CLI操作进度反馈系统;
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:ming_status_cli/src/utils/logger.dart';

/// 任务状态枚举
enum TaskStatus {
  /// 待执行状态
  pending, // 待执行
  /// 执行中状态
  running, // 执行中
  /// 已完成状态
  completed, // 已完成
  /// 失败状态
  failed, // 失败
  /// 跳过状态
  skipped, // 跳过
}

/// 进度任务
class ProgressTask {
  /// 创建进度任务实例
  ProgressTask({
    required this.id,
    required this.name,
    required this.description,
    this.status = TaskStatus.pending,
    this.errorMessage,
    this.startTime,
    this.endTime,
  });
  
  /// 任务唯一标识符
  final String id;
  /// 任务名称
  final String name;
  /// 任务描述
  final String description;
  /// 任务状态
  TaskStatus status;
  /// 错误信息（任务失败时）
  String? errorMessage;
  /// 任务开始时间
  DateTime? startTime;
  /// 任务结束时间
  DateTime? endTime;

  /// 任务执行时长
  Duration? get duration {
    if (startTime == null) return null;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!);
  }

  /// 任务状态图标
  String get statusIcon {
    switch (status) {
      case TaskStatus.pending:
        return '⏳';
      case TaskStatus.running:
        return '🔄';
      case TaskStatus.completed:
        return '✅';
      case TaskStatus.failed:
        return '❌';
      case TaskStatus.skipped:
        return '⏭️ ';
    }
  }

  /// 任务状态描述
  String get statusText {
    switch (status) {
      case TaskStatus.pending:
        return '待执行';
      case TaskStatus.running:
        return '执行中';
      case TaskStatus.completed:
        return '已完成';
      case TaskStatus.failed:
        return '失败';
      case TaskStatus.skipped:
        return '已跳过';
    }
  }
}

/// 进度管理器
/// 提供CLI操作的进度跟踪和反馈
class ProgressManager {
  /// 创建进度管理器实例
  ProgressManager({
    bool showProgressBar = true,
    bool showTaskDetails = true,
    bool showTimestamp = false,
  })  : _showProgressBar = showProgressBar,
        _showTaskDetails = showTaskDetails,
        _showTimestamp = showTimestamp;
  final List<ProgressTask> _tasks = [];
  final bool _showProgressBar;
  final bool _showTaskDetails;
  final bool _showTimestamp;

  int _currentTaskIndex = -1;
  DateTime? _startTime;
  DateTime? _endTime;

  /// 添加任务
  void addTask(String id, String name, String description) {
    _tasks.add(
      ProgressTask(
        id: id,
        name: name,
        description: description,
      ),
    );
  }

  /// 批量添加任务
  void addTasks(List<Map<String, String>> tasks) {
    for (final task in tasks) {
      addTask(
        task['id']!,
        task['name']!,
        task['description']!,
      );
    }
  }

  /// 开始进度跟踪
  void start({String? title}) {
    if (title != null) {
      Logger.title(title);
    }

    _startTime = DateTime.now();
    Logger.info('开始执行 ${_tasks.length} 个任务...');

    if (_showProgressBar) {
      _showInitialProgress();
    }

    Logger.newLine();
  }

  /// 执行下一个任务
  Future<T> executeTask<T>(
    Future<T> Function() taskFunction, {
    bool canFail = false,
  }) async {
    _currentTaskIndex++;

    if (_currentTaskIndex >= _tasks.length) {
      throw StateError('没有更多任务可执行');
    }

    final task = _tasks[_currentTaskIndex]

      // 开始任务
      ..status = TaskStatus.running
      ..startTime = DateTime.now();

    if (_showTaskDetails) {
      _showTaskStart(task);
    }

    try {
      // 执行任务
      final result = await taskFunction();

      // 任务成功
      task
        ..status = TaskStatus.completed
        ..endTime = DateTime.now();

      if (_showTaskDetails) {
        _showTaskCompleted(task);
      }

      if (_showProgressBar) {
        _updateProgressBar();
      }

      return result;
    } catch (e) {
      // 任务失败
      task
        ..status = TaskStatus.failed
        ..endTime = DateTime.now()
        ..errorMessage = e.toString();

      if (_showTaskDetails) {
        _showTaskFailed(task, e);
      }

      if (_showProgressBar) {
        _updateProgressBar();
      }

      if (!canFail) {
        rethrow;
      } else {
        // 允许失败时返回默认值
        return null as T;
      }
    }
  }

  /// 跳过任务
  void skipTask(String reason) {
    if (_currentTaskIndex + 1 >= _tasks.length) {
      return;
    }

    _currentTaskIndex++;
    final task = _tasks[_currentTaskIndex]
      ..status = TaskStatus.skipped
      ..errorMessage = reason;

    if (_showTaskDetails) {
      Logger.warning('⏭️  跳过任务: ${task.name} - $reason');
    }

    if (_showProgressBar) {
      _updateProgressBar();
    }
  }

  /// 完成所有任务
  void complete({String? summary}) {
    _endTime = DateTime.now();

    Logger.newLine();
    _showFinalSummary(summary);
  }

  /// 显示初始进度
  void _showInitialProgress() {
    final progressBar = _buildProgressBar(0, _tasks.length);
    stdout.write('\r$progressBar');
  }

  /// 显示任务开始
  void _showTaskStart(ProgressTask task) {
    final timestamp = _showTimestamp ? '[${_formatTime(DateTime.now())}] ' : '';
    Logger.progress('$timestamp🔄 ${task.name}', newLine: false);
  }

  /// 显示任务完成
  void _showTaskCompleted(ProgressTask task) {
    final timestamp = _showTimestamp ? '[${_formatTime(DateTime.now())}] ' : '';
    final duration =
        task.duration != null ? ' (${_formatDuration(task.duration!)})' : '';
    stdout.write('\r$timestamp✅ ${task.name}$duration\n');
  }

  /// 显示任务失败
  void _showTaskFailed(ProgressTask task, Object error) {
    final timestamp = _showTimestamp ? '[${_formatTime(DateTime.now())}] ' : '';
    stdout.write('\r$timestamp❌ ${task.name} - 失败\n');
    if (_showTaskDetails) {
      Logger.error('   错误: $error');
    }
  }

  /// 更新进度条
  void _updateProgressBar() {
    if (!_showProgressBar) return;

    final completed = _tasks
        .where(
          (t) =>
              t.status == TaskStatus.completed ||
              t.status == TaskStatus.failed ||
              t.status == TaskStatus.skipped,
        )
        .length;

    final progressBar = _buildProgressBar(completed, _tasks.length);
    stdout.write('\r$progressBar');

    // 如果全部完成，换行
    if (completed == _tasks.length) {
      stdout.write('\n');
    }
  }

  /// 构建进度条
  String _buildProgressBar(int current, int total) {
    const barLength = 30;
    final percentage = total > 0 ? (current / total * 100).round() : 0;
    final filledLength = (current / total * barLength).round();

    final bar = '█' * filledLength + '░' * (barLength - filledLength);
    return '进度: [$bar] $percentage% ($current/$total)';
  }

  /// 显示最终总结
  void _showFinalSummary(String? customSummary) {
    final completed =
        _tasks.where((t) => t.status == TaskStatus.completed).length;
    final failed = _tasks.where((t) => t.status == TaskStatus.failed).length;
    final skipped = _tasks.where((t) => t.status == TaskStatus.skipped).length;

    Logger.subtitle('执行总结');

    if (customSummary != null) {
      Logger.info(customSummary);
      Logger.newLine();
    }

    Logger.keyValue('总任务数', '${_tasks.length}');
    Logger.keyValue('成功完成', '$completed');
    if (failed > 0) {
      Logger.keyValue('执行失败', '$failed');
    }
    if (skipped > 0) {
      Logger.keyValue('跳过执行', '$skipped');
    }

    if (_startTime != null && _endTime != null) {
      final totalDuration = _endTime!.difference(_startTime!);
      Logger.keyValue('总耗时', _formatDuration(totalDuration));
    }

    Logger.newLine();

    // 显示失败任务详情
    if (failed > 0) {
      Logger.subtitle('失败任务详情');
      for (final task in _tasks.where((t) => t.status == TaskStatus.failed)) {
        Logger.error('❌ ${task.name}: ${task.errorMessage}');
      }
      Logger.newLine();
    }
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  /// 格式化持续时间
  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}秒';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}分${duration.inSeconds % 60}秒';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '$hours时$minutes分';
    }
  }

  /// 获取任务统计
  Map<String, int> get taskStats {
    return {
      'total': _tasks.length,
      'completed': _tasks.where((t) => t.status == TaskStatus.completed).length,
      'failed': _tasks.where((t) => t.status == TaskStatus.failed).length,
      'skipped': _tasks.where((t) => t.status == TaskStatus.skipped).length,
      'pending': _tasks.where((t) => t.status == TaskStatus.pending).length,
    };
  }

  /// 获取所有任务
  List<ProgressTask> get tasks => List.unmodifiable(_tasks);

  /// 获取当前任务
  ProgressTask? get currentTask {
    if (_currentTaskIndex >= 0 && _currentTaskIndex < _tasks.length) {
      return _tasks[_currentTaskIndex];
    }
    return null;
  }

  /// 获取总执行时间
  Duration? get totalDuration {
    if (_startTime == null) return null;
    final end = _endTime ?? DateTime.now();
    return end.difference(_startTime!);
  }
}
