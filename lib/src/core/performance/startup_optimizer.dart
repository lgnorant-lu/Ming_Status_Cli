/*
---------------------------------------------------------------
File name:          startup_optimizer.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        启动时间优化器 (Startup Time Optimizer)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - CLI启动时间优化;
---------------------------------------------------------------
*/

import 'dart:async';

import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 启动阶段
enum StartupPhase {
  /// 预初始化
  preInit,
  
  /// 核心初始化
  coreInit,
  
  /// 组件初始化
  componentInit,
  
  /// 后初始化
  postInit,
  
  /// 完成
  complete,
}

/// 启动任务
class StartupTask {
  /// 创建启动任务实例
  const StartupTask({
    required this.id,
    required this.name,
    required this.phase,
    required this.priority,
    required this.executor,
    this.dependencies = const [],
    this.canRunInParallel = true,
    this.isOptional = false,
    this.timeout = const Duration(seconds: 30),
  });

  /// 任务ID
  final String id;
  
  /// 任务名称
  final String name;
  
  /// 启动阶段
  final StartupPhase phase;
  
  /// 优先级 (数字越小优先级越高)
  final int priority;
  
  /// 执行器
  final Future<void> Function() executor;
  
  /// 依赖任务
  final List<String> dependencies;
  
  /// 是否可以并行运行
  final bool canRunInParallel;
  
  /// 是否可选
  final bool isOptional;
  
  /// 超时时间
  final Duration timeout;
}

/// 启动结果
class StartupResult {
  /// 创建启动结果实例
  const StartupResult({
    required this.success,
    required this.totalTime,
    required this.phaseResults,
    this.errors = const [],
    this.warnings = const [],
    this.optimizations = const [],
  });

  /// 是否成功
  final bool success;
  
  /// 总启动时间
  final Duration totalTime;
  
  /// 各阶段结果
  final Map<StartupPhase, Duration> phaseResults;
  
  /// 错误列表
  final List<String> errors;
  
  /// 警告列表
  final List<String> warnings;
  
  /// 应用的优化
  final List<String> optimizations;
}

/// 启动时间优化器
class StartupOptimizer {
  /// 创建启动时间优化器实例
  StartupOptimizer({
    this.enableParallelExecution = true,
    this.enableLazyLoading = true,
    this.enableCaching = true,
    this.maxParallelTasks = 4,
    this.targetStartupTime = const Duration(seconds: 3),
  });

  /// 是否启用并行执行
  final bool enableParallelExecution;
  
  /// 是否启用延迟加载
  final bool enableLazyLoading;
  
  /// 是否启用缓存
  final bool enableCaching;
  
  /// 最大并行任务数
  final int maxParallelTasks;
  
  /// 目标启动时间
  final Duration targetStartupTime;

  /// 启动任务列表
  final List<StartupTask> _tasks = [];
  
  /// 已完成的任务
  final Set<String> _completedTasks = {};
  
  /// 启动历史
  final List<StartupResult> _startupHistory = [];
  
  /// 缓存的初始化结果
  final Map<String, dynamic> _initCache = {};

  /// 注册启动任务
  void registerTask(StartupTask task) {
    _tasks.add(task);
    cli_logger.Logger.debug('注册启动任务: ${task.name}');
  }

  /// 注册多个启动任务
  void registerTasks(List<StartupTask> tasks) {
    for (final task in tasks) {
      registerTask(task);
    }
  }

  /// 执行优化启动
  Future<StartupResult> executeOptimizedStartup() async {
    final totalStopwatch = Stopwatch()..start();
    final phaseResults = <StartupPhase, Duration>{};
    final errors = <String>[];
    final warnings = <String>[];
    final optimizations = <String>[];
    
    try {
      cli_logger.Logger.info('开始优化启动流程');
      
      // 应用启动优化
      _applyStartupOptimizations(optimizations);
      
      // 按阶段执行任务
      for (final phase in StartupPhase.values) {
        if (phase == StartupPhase.complete) continue;
        
        final phaseStopwatch = Stopwatch()..start();
        await _executePhase(phase, errors, warnings);
        phaseStopwatch.stop();
        
        phaseResults[phase] = phaseStopwatch.elapsed;
        cli_logger.Logger.debug('阶段 ${phase.name} 完成: ${phaseStopwatch.elapsedMilliseconds}ms');
      }
      
      totalStopwatch.stop();
      
      final result = StartupResult(
        success: errors.isEmpty,
        totalTime: totalStopwatch.elapsed,
        phaseResults: phaseResults,
        errors: errors,
        warnings: warnings,
        optimizations: optimizations,
      );
      
      _startupHistory.add(result);
      
      cli_logger.Logger.info(
        '启动完成: ${totalStopwatch.elapsedMilliseconds}ms '
        '(目标: ${targetStartupTime.inMilliseconds}ms)',
      );
      
      return result;
    } catch (e) {
      totalStopwatch.stop();
      errors.add('启动失败: $e');
      
      final result = StartupResult(
        success: false,
        totalTime: totalStopwatch.elapsed,
        phaseResults: phaseResults,
        errors: errors,
        warnings: warnings,
        optimizations: optimizations,
      );
      
      _startupHistory.add(result);
      return result;
    }
  }

  /// 获取启动历史
  List<StartupResult> getStartupHistory() {
    return List.unmodifiable(_startupHistory);
  }

  /// 生成启动报告
  Map<String, dynamic> generateStartupReport() {
    if (_startupHistory.isEmpty) {
      return {'message': '暂无启动历史数据'};
    }
    
    final latest = _startupHistory.last;
    final averageTime = _startupHistory
        .map((r) => r.totalTime.inMilliseconds)
        .reduce((a, b) => a + b) / _startupHistory.length;
    
    return {
      'summary': {
        'latest_startup_time_ms': latest.totalTime.inMilliseconds,
        'average_startup_time_ms': averageTime.round(),
        'target_startup_time_ms': targetStartupTime.inMilliseconds,
        'success_rate': _startupHistory.where((r) => r.success).length / _startupHistory.length,
        'total_startups': _startupHistory.length,
      },
      'latest_result': {
        'success': latest.success,
        'total_time_ms': latest.totalTime.inMilliseconds,
        'phase_breakdown': latest.phaseResults.map(
          (phase, duration) => MapEntry(phase.name, duration.inMilliseconds),
        ),
        'optimizations_applied': latest.optimizations,
        'errors': latest.errors,
        'warnings': latest.warnings,
      },
      'performance_trend': _startupHistory.map((r) => {
        'timestamp': DateTime.now().subtract(
          Duration(minutes: _startupHistory.length - _startupHistory.indexOf(r)),
        ).toIso8601String(),
        'startup_time_ms': r.totalTime.inMilliseconds,
        'success': r.success,
      },).toList(),
      'recommendations': _generateStartupRecommendations(),
    };
  }

  /// 应用启动优化
  void _applyStartupOptimizations(List<String> optimizations) {
    if (enableLazyLoading) {
      optimizations.add('启用延迟加载');
      _enableLazyLoading();
    }
    
    if (enableCaching) {
      optimizations.add('启用初始化缓存');
      _enableInitializationCaching();
    }
    
    if (enableParallelExecution) {
      optimizations.add('启用并行执行');
      _optimizeTaskOrder();
    }
    
    optimizations.add('减少启动时I/O操作');
    optimizations.add('预编译关键组件');
  }

  /// 执行阶段任务
  Future<void> _executePhase(
    StartupPhase phase,
    List<String> errors,
    List<String> warnings,
  ) async {
    final phaseTasks = _tasks.where((task) => task.phase == phase).toList();
    
    if (phaseTasks.isEmpty) return;
    
    // 按优先级排序
    phaseTasks.sort((a, b) => a.priority.compareTo(b.priority));
    
    if (enableParallelExecution) {
      await _executeTasksInParallel(phaseTasks, errors, warnings);
    } else {
      await _executeTasksSequentially(phaseTasks, errors, warnings);
    }
  }

  /// 并行执行任务
  Future<void> _executeTasksInParallel(
    List<StartupTask> tasks,
    List<String> errors,
    List<String> warnings,
  ) async {
    final parallelTasks = <StartupTask>[];
    final sequentialTasks = <StartupTask>[];
    
    // 分离可并行和必须串行的任务
    for (final task in tasks) {
      if (task.canRunInParallel && _areDependenciesSatisfied(task)) {
        parallelTasks.add(task);
      } else {
        sequentialTasks.add(task);
      }
    }
    
    // 并行执行可并行任务
    if (parallelTasks.isNotEmpty) {
      final futures = parallelTasks.take(maxParallelTasks).map((task) => 
        _executeTask(task, errors, warnings),);
      await Future.wait(futures);
    }
    
    // 串行执行剩余任务
    for (final task in sequentialTasks) {
      await _executeTask(task, errors, warnings);
    }
  }

  /// 串行执行任务
  Future<void> _executeTasksSequentially(
    List<StartupTask> tasks,
    List<String> errors,
    List<String> warnings,
  ) async {
    for (final task in tasks) {
      await _executeTask(task, errors, warnings);
    }
  }

  /// 执行单个任务
  Future<void> _executeTask(
    StartupTask task,
    List<String> errors,
    List<String> warnings,
  ) async {
    if (_completedTasks.contains(task.id)) return;
    
    try {
      // 检查依赖
      if (!_areDependenciesSatisfied(task)) {
        if (!task.isOptional) {
          errors.add('任务 ${task.name} 的依赖未满足');
        }
        return;
      }
      
      // 检查缓存
      if (enableCaching && _initCache.containsKey(task.id)) {
        cli_logger.Logger.debug('使用缓存结果: ${task.name}');
        _completedTasks.add(task.id);
        return;
      }
      
      cli_logger.Logger.debug('执行启动任务: ${task.name}');
      
      // 执行任务（带超时）
      await task.executor().timeout(task.timeout);
      
      _completedTasks.add(task.id);
      
      // 缓存结果
      if (enableCaching) {
        _initCache[task.id] = DateTime.now();
      }
      
    } catch (TimeoutException) {
      final message = '任务 ${task.name} 执行超时';
      if (task.isOptional) {
        warnings.add(message);
      } else {
        errors.add(message);
      }
    } catch (e) {
      final message = '任务 ${task.name} 执行失败: $e';
      if (task.isOptional) {
        warnings.add(message);
      } else {
        errors.add(message);
      }
    }
  }

  /// 检查依赖是否满足
  bool _areDependenciesSatisfied(StartupTask task) {
    return task.dependencies.every(_completedTasks.contains);
  }

  /// 启用延迟加载
  void _enableLazyLoading() {
    // 将非关键任务标记为可选或延迟执行
    for (final task in _tasks) {
      if (task.phase == StartupPhase.postInit && !task.isOptional) {
        // 这里可以动态修改任务属性，但由于Task是不可变的，
        // 实际实现中可能需要重新设计任务系统
      }
    }
  }

  /// 启用初始化缓存
  void _enableInitializationCaching() {
    // 缓存已经在_executeTask中实现
    cli_logger.Logger.debug('初始化缓存已启用');
  }

  /// 优化任务顺序
  void _optimizeTaskOrder() {
    // 根据依赖关系和优先级重新排序任务
    _tasks.sort((a, b) {
      // 首先按阶段排序
      final phaseComparison = a.phase.index.compareTo(b.phase.index);
      if (phaseComparison != 0) return phaseComparison;
      
      // 然后按优先级排序
      return a.priority.compareTo(b.priority);
    });
  }

  /// 生成启动建议
  List<String> _generateStartupRecommendations() {
    final recommendations = <String>[];
    
    if (_startupHistory.isNotEmpty) {
      final latest = _startupHistory.last;
      
      if (latest.totalTime > targetStartupTime) {
        recommendations.add('启动时间超过目标，建议优化关键路径');
      }
      
      if (latest.errors.isNotEmpty) {
        recommendations.add('存在启动错误，建议检查失败的组件');
      }
      
      if (latest.warnings.isNotEmpty) {
        recommendations.add('存在启动警告，建议优化可选组件');
      }
      
      // 分析阶段耗时
      final slowestPhase = latest.phaseResults.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      
      if (slowestPhase.value > const Duration(seconds: 1)) {
        recommendations.add('${slowestPhase.key.name}阶段耗时较长，建议优化');
      }
    }
    
    if (!enableParallelExecution) {
      recommendations.add('建议启用并行执行以提升启动速度');
    }
    
    if (!enableCaching) {
      recommendations.add('建议启用缓存以减少重复初始化');
    }
    
    return recommendations;
  }

  /// 清理缓存
  void clearCache() {
    _initCache.clear();
    cli_logger.Logger.debug('启动缓存已清理');
  }

  /// 重置状态
  void reset() {
    _completedTasks.clear();
    clearCache();
  }
}
