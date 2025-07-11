/*
---------------------------------------------------------------
File name:          async_manager.dart
Author:             lgnorant-lu
Date created:       2025/07/02
Last modified:      2025/07/02
Dart Version:       3.2+
Description:        异步管理器 (Async manager)
---------------------------------------------------------------
Change History:
    2025/07/02: Initial creation - 异步管理器功能;
---------------------------------------------------------------
*/

import 'dart:async';

import 'package:ming_status_cli/src/core/template_engine/template_models.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 用于避免unawaited警告的工具函数
void unawaited(Future<void> future) {
  // 让future在后台运行，不等待结果
}

/// 生成任务数据结构
class GenerationTask {
  /// 创建生成任务实例
  GenerationTask({
    required this.id,
    required this.templateName,
    required this.outputPath,
    required this.variables,
    required this.completer,
    this.priority = 0,
    this.hooks,
  });

  /// 任务ID
  final String id;

  /// 模板名称
  final String templateName;

  /// 输出路径
  final String outputPath;

  /// 模板变量
  final Map<String, dynamic> variables;

  /// 异步完成器
  final Completer<GenerationResult> completer;

  /// 任务优先级
  final int priority;

  /// 钩子列表
  final List<TemplateHook>? hooks;

  /// 任务创建时间
  DateTime get createdAt => DateTime.now();
}

/// Task 36.2: 异步生成和并发处理系统
class AsyncTemplateGenerationManager {
  /// 创建异步模板生成管理器实例
  AsyncTemplateGenerationManager(this.templateEngine);

  /// 模板引擎实例（使用动态类型避免循环依赖）
  final dynamic templateEngine;

  /// 最大并发生成数量
  static const int maxConcurrentGenerations = 5;

  /// 单个生成任务超时时间
  static const Duration generationTimeout = Duration(minutes: 10);

  /// 当前正在执行的生成任务
  final Map<String, Future<GenerationResult>> _activeGenerations = {};

  /// 生成任务队列
  final List<GenerationTask> _generationQueue = [];

  /// 并发控制信号量
  int _activeTasks = 0;

  /// 异步生成模板（支持并发）
  Future<GenerationResult> generateTemplateAsync({
    required String templateName,
    required String outputPath,
    required Map<String, dynamic> variables,
    List<TemplateHook>? hooks,
    int priority = 0,
    bool skipQueue = false,
  }) async {
    final taskId = _generateTaskId(templateName, outputPath);

    // 检查是否已有相同任务
    if (_activeGenerations.containsKey(taskId)) {
      cli_logger.Logger.debug('重用已有的生成任务: $taskId');
      return _activeGenerations[taskId]!;
    }

    final completer = Completer<GenerationResult>();
    final task = GenerationTask(
      id: taskId,
      templateName: templateName,
      outputPath: outputPath,
      variables: variables,
      completer: completer,
      priority: priority,
      hooks: hooks,
    );

    if (skipQueue || _activeTasks < maxConcurrentGenerations) {
      // 直接执行
      unawaited(_executeGenerationTask(task));
    } else {
      // 加入队列
      _generationQueue
        ..add(task)
        ..sort((a, b) => b.priority.compareTo(a.priority));
      cli_logger.Logger.debug(
        '任务加入队列: $taskId (队列长度: ${_generationQueue.length})',
      );
    }

    _activeGenerations[taskId] = completer.future;
    return completer.future;
  }

  /// 批量异步生成多个模板
  Future<List<GenerationResult>> generateMultipleTemplatesAsync({
    required List<TemplateGenerationSpec> specs,
    bool allowPartialFailure = true,
    Duration? timeout,
  }) async {
    try {
      cli_logger.Logger.info('开始批量异步生成 ${specs.length} 个模板');

      final futures = specs
          .map(
            (spec) => generateTemplateAsync(
              templateName: spec.templateName,
              outputPath: spec.outputPath,
              variables: spec.variables,
              hooks: spec.hooks,
              priority: spec.priority,
            ),
          )
          .toList();

      if (timeout != null) {
        final results =
            await Future.wait(futures, eagerError: !allowPartialFailure)
                .timeout(timeout);
        return results;
      } else {
        return await Future.wait(futures, eagerError: !allowPartialFailure);
      }
    } catch (e) {
      cli_logger.Logger.error('批量异步生成失败', error: e);
      rethrow;
    }
  }

  /// 并行生成多个模板（流式处理）
  Stream<GenerationResult> generateTemplatesStream({
    required List<TemplateGenerationSpec> specs,
    int? maxConcurrency,
  }) async* {
    final actualMaxConcurrency = maxConcurrency ?? maxConcurrentGenerations;

    cli_logger.Logger.info(
      '开始流式生成 ${specs.length} 个模板 (并发度: $actualMaxConcurrency)',
    );

    // 使用信号量控制并发度
    final semaphore = Semaphore(actualMaxConcurrency);

    final futures = specs.map((spec) async {
      await semaphore.acquire();
      try {
        return await generateTemplateAsync(
          templateName: spec.templateName,
          outputPath: spec.outputPath,
          variables: spec.variables,
          hooks: spec.hooks,
          priority: spec.priority,
          skipQueue: true, // 流式处理跳过队列
        );
      } finally {
        semaphore.release();
      }
    });

    // 流式返回结果
    for (final future in futures) {
      yield await future;
    }
  }

  /// 获取生成统计信息
  Map<String, dynamic> getGenerationStatistics() {
    return {
      'active_generations': _activeGenerations.length,
      'queued_tasks': _generationQueue.length,
      'active_tasks': _activeTasks,
      'max_concurrent_generations': maxConcurrentGenerations,
      'queue_utilization': _generationQueue.length / 10, // 假设队列容量为10
      'active_task_ids': _activeGenerations.keys.toList(),
      'queued_task_priorities':
          _generationQueue.map((t) => t.priority).toList(),
    };
  }

  /// 取消所有待处理的任务
  Future<void> cancelAllPendingTasks() async {
    final cancelledCount = _generationQueue.length;

    // 取消队列中的任务
    for (final task in _generationQueue) {
      task.completer.complete(GenerationResult.failure('任务已取消'));
    }
    _generationQueue.clear();

    cli_logger.Logger.info('已取消 $cancelledCount 个待处理任务');
  }

  /// 等待所有活动任务完成
  Future<void> waitForAllTasks() async {
    if (_activeGenerations.isNotEmpty) {
      cli_logger.Logger.info('等待 ${_activeGenerations.length} 个活动任务完成...');
      await Future.wait(_activeGenerations.values);
      cli_logger.Logger.info('所有活动任务已完成');
    }
  }

  // 私有方法

  /// 执行生成任务
  Future<void> _executeGenerationTask(GenerationTask task) async {
    _activeTasks++;

    try {
      cli_logger.Logger.debug('开始执行生成任务: ${task.id}');

      final result = await _performGeneration(task).timeout(generationTimeout);

      task.completer.complete(result);
    } catch (e) {
      final errorResult = GenerationResult.failure(
        '生成任务执行失败: $e',
        outputPath: task.outputPath,
      );
      task.completer.complete(errorResult);
    } finally {
      _activeTasks--;
      final _ = _activeGenerations.remove(task.id);

      // 处理下一个队列任务
      _processNextQueuedTask();
    }
  }

  /// 执行实际的模板生成
  Future<GenerationResult> _performGeneration(GenerationTask task) async {
    try {
      // 如果有钩子，使用钩子生成
      final hasHooks = task.hooks != null && task.hooks!.isNotEmpty;
      if (hasHooks) {
        final dynamic resultDynamic = await templateEngine.generateWithHooks(
          templateName: task.templateName,
          outputPath: task.outputPath,
          variables: task.variables,
          additionalHooks: task.hooks,
        );
        final result = resultDynamic as GenerationResult;
        return result;
      } else {
        // 标准生成
        final dynamic successResultDynamic =
            await templateEngine.generateModule(
          templateName: task.templateName,
          outputPath: task.outputPath,
          variables: task.variables,
        );
        final successResult = successResultDynamic as bool?;
        final success = successResult ?? false;

        return GenerationResult(
          success: success,
          outputPath: task.outputPath,
          message: success ? '模板生成成功' : '模板生成失败',
        );
      }
    } catch (e) {
      return GenerationResult.failure(
        '模板生成异常: $e',
        outputPath: task.outputPath,
      );
    }
  }

  /// 处理下一个队列任务
  void _processNextQueuedTask() {
    if (_generationQueue.isNotEmpty &&
        _activeTasks < maxConcurrentGenerations) {
      final nextTask = _generationQueue.removeAt(0);
      unawaited(_executeGenerationTask(nextTask));
    }
  }

  /// 生成任务ID
  String _generateTaskId(String templateName, String outputPath) {
    return '${templateName}_${outputPath.hashCode}';
  }
}

/// 模板生成规格
class TemplateGenerationSpec {
  /// 创建模板生成规格实例
  const TemplateGenerationSpec({
    required this.templateName,
    required this.outputPath,
    required this.variables,
    this.hooks,
    this.priority = 0,
  });

  /// 模板名称
  final String templateName;

  /// 输出路径
  final String outputPath;

  /// 模板变量映射
  final Map<String, dynamic> variables;

  /// 可选的钩子列表
  final List<TemplateHook>? hooks;

  /// 任务优先级
  final int priority;
}

/// 简单信号量实现
class Semaphore {
  /// 创建信号量实例，指定最大许可数量
  Semaphore(this.maxCount) : _currentCount = maxCount;

  /// 最大许可数量
  final int maxCount;

  /// 当前可用许可数量
  int _currentCount;

  /// 等待队列
  final List<Completer<void>> _waitQueue = [];

  /// 获取许可
  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  /// 释放许可
  void release() {
    if (_waitQueue.isNotEmpty) {
      _waitQueue.removeAt(0).complete();
    } else {
      _currentCount++;
    }
  }
}
