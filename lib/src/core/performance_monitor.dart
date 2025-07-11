/*
---------------------------------------------------------------
File name:          performance_monitor.dart
Author:             lgnorant-lu
Date created:       2025-07-09
Last modified:      2025-07-09
Dart Version:       3.2+
Description:        Task 51.3 - 性能监控和分析系统
                    实现性能指标收集、分析和优化建议
---------------------------------------------------------------
Change History:
    2025-07-09: Initial creation - 性能监控和分析系统;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ming_status_cli/src/utils/logger.dart';

/// 性能指标类型
enum PerformanceMetricType {
  memory, // 内存使用
  cpu, // CPU使用
  io, // I/O操作
  network, // 网络操作
  cache, // 缓存性能
  execution, // 执行时间
}

/// 性能指标
class PerformanceMetric {
  const PerformanceMetric({
    required this.name,
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.context = const {},
  });

  factory PerformanceMetric.fromJson(Map<String, dynamic> json) {
    return PerformanceMetric(
      name: json['name'] as String,
      type: PerformanceMetricType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      context: Map<String, dynamic>.from(json['context'] as Map? ?? {}),
    );
  }

  /// 指标名称
  final String name;

  /// 指标类型
  final PerformanceMetricType type;

  /// 指标值
  final double value;

  /// 单位
  final String unit;

  /// 时间戳
  final DateTime timestamp;

  /// 上下文信息
  final Map<String, dynamic> context;

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.name,
        'value': value,
        'unit': unit,
        'timestamp': timestamp.toIso8601String(),
        'context': context,
      };
}

/// 性能分析结果
class PerformanceAnalysis {
  const PerformanceAnalysis({
    required this.analysisTime,
    required this.overallScore,
    required this.typeScores,
    required this.bottlenecks,
    required this.recommendations,
    required this.metrics,
  });

  /// 分析时间
  final DateTime analysisTime;

  /// 总体评分 (0-100)
  final double overallScore;

  /// 各类型指标评分
  final Map<PerformanceMetricType, double> typeScores;

  /// 性能瓶颈
  final List<String> bottlenecks;

  /// 优化建议
  final List<String> recommendations;

  /// 详细指标
  final List<PerformanceMetric> metrics;

  Map<String, dynamic> toJson() => {
        'analysisTime': analysisTime.toIso8601String(),
        'overallScore': overallScore,
        'typeScores': typeScores.map((k, v) => MapEntry(k.name, v)),
        'bottlenecks': bottlenecks,
        'recommendations': recommendations,
        'metrics': metrics.map((m) => m.toJson()).toList(),
      };
}

/// 性能监控器
class PerformanceMonitor {
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();

  /// 性能指标列表
  final List<PerformanceMetric> _metrics = [];

  /// 监控开始时间
  DateTime? _startTime;

  /// 是否启用监控
  bool _isEnabled = false;

  /// 监控定时器
  Timer? _monitorTimer;

  /// 基准内存使用
  int? _baselineMemory;

  /// 启用性能监控
  void enable() {
    if (_isEnabled) return;

    _isEnabled = true;
    _startTime = DateTime.now();
    _baselineMemory = _getCurrentMemoryUsage();

    // 启动定期监控
    _monitorTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _collectSystemMetrics();
    });

    Logger.info('性能监控已启用');
  }

  /// 禁用性能监控
  void disable() {
    if (!_isEnabled) return;

    _isEnabled = false;
    _monitorTimer?.cancel();
    _monitorTimer = null;

    Logger.info('性能监控已禁用');
  }

  /// 记录性能指标
  void recordMetric(PerformanceMetric metric) {
    if (!_isEnabled) return;

    _metrics.add(metric);

    // 限制指标数量
    if (_metrics.length > 10000) {
      _metrics.removeRange(0, _metrics.length - 10000);
    }
  }

  /// 记录执行时间
  Future<T> measureExecution<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? context,
  }) async {
    if (!_isEnabled) return operation();

    final stopwatch = Stopwatch()..start();
    final startMemory = _getCurrentMemoryUsage();

    try {
      final result = await operation();
      stopwatch.stop();

      final endMemory = _getCurrentMemoryUsage();
      final memoryDelta = endMemory - startMemory;

      // 记录执行时间指标
      recordMetric(
        PerformanceMetric(
          name: '${operationName}_execution_time',
          type: PerformanceMetricType.execution,
          value: stopwatch.elapsedMilliseconds.toDouble(),
          unit: 'ms',
          timestamp: DateTime.now(),
          context: {
            'operation': operationName,
            'memory_delta': memoryDelta,
            ...?context,
          },
        ),
      );

      // 记录内存使用变化
      if (memoryDelta.abs() > 1024 * 1024) {
        // 超过1MB变化才记录
        recordMetric(
          PerformanceMetric(
            name: '${operationName}_memory_usage',
            type: PerformanceMetricType.memory,
            value: memoryDelta.toDouble(),
            unit: 'bytes',
            timestamp: DateTime.now(),
            context: {
              'operation': operationName,
              'execution_time': stopwatch.elapsedMilliseconds,
              ...?context,
            },
          ),
        );
      }

      return result;
    } catch (e) {
      stopwatch.stop();

      // 记录失败的操作
      recordMetric(
        PerformanceMetric(
          name: '${operationName}_execution_error',
          type: PerformanceMetricType.execution,
          value: stopwatch.elapsedMilliseconds.toDouble(),
          unit: 'ms',
          timestamp: DateTime.now(),
          context: {
            'operation': operationName,
            'error': e.toString(),
            ...?context,
          },
        ),
      );

      rethrow;
    }
  }

  /// 收集系统指标
  void _collectSystemMetrics() {
    final now = DateTime.now();

    // 收集内存使用指标
    final currentMemory = _getCurrentMemoryUsage();
    recordMetric(
      PerformanceMetric(
        name: 'system_memory_usage',
        type: PerformanceMetricType.memory,
        value: currentMemory.toDouble(),
        unit: 'bytes',
        timestamp: now,
      ),
    );

    // 收集进程信息
    try {
      final processInfo = ProcessInfo.currentRss;
      recordMetric(
        PerformanceMetric(
          name: 'process_rss',
          type: PerformanceMetricType.memory,
          value: processInfo.toDouble(),
          unit: 'bytes',
          timestamp: now,
        ),
      );
    } catch (e) {
      // 某些平台可能不支持
    }
  }

  /// 获取当前内存使用
  int _getCurrentMemoryUsage() {
    try {
      return ProcessInfo.currentRss;
    } catch (e) {
      // 如果无法获取，返回估算值
      return _baselineMemory ?? 0;
    }
  }

  /// 分析性能数据
  PerformanceAnalysis analyzePerformance() {
    final now = DateTime.now();
    final analysisMetrics = List<PerformanceMetric>.from(_metrics);

    if (analysisMetrics.isEmpty) {
      return PerformanceAnalysis(
        analysisTime: now,
        overallScore: 100,
        typeScores: {},
        bottlenecks: [],
        recommendations: ['启用性能监控以获取详细分析'],
        metrics: [],
      );
    }

    // 按类型分组指标
    final metricsByType = <PerformanceMetricType, List<PerformanceMetric>>{};
    for (final metric in analysisMetrics) {
      metricsByType.putIfAbsent(metric.type, () => []).add(metric);
    }

    // 计算各类型评分
    final typeScores = <PerformanceMetricType, double>{};
    final bottlenecks = <String>[];
    final recommendations = <String>[];

    for (final entry in metricsByType.entries) {
      final type = entry.key;
      final metrics = entry.value;
      final score = _calculateTypeScore(type, metrics);
      typeScores[type] = score;

      if (score < 70) {
        bottlenecks.add(_getBottleneckDescription(type, metrics));
        recommendations.addAll(_getRecommendations(type, metrics));
      }
    }

    // 计算总体评分
    final overallScore = typeScores.values.isEmpty
        ? 100.0
        : typeScores.values.reduce((a, b) => a + b) / typeScores.length;

    return PerformanceAnalysis(
      analysisTime: now,
      overallScore: overallScore,
      typeScores: typeScores,
      bottlenecks: bottlenecks,
      recommendations: recommendations,
      metrics: analysisMetrics,
    );
  }

  /// 计算类型评分
  double _calculateTypeScore(
      PerformanceMetricType type, List<PerformanceMetric> metrics) {
    if (metrics.isEmpty) return 100;

    switch (type) {
      case PerformanceMetricType.memory:
        return _calculateMemoryScore(metrics);
      case PerformanceMetricType.execution:
        return _calculateExecutionScore(metrics);
      case PerformanceMetricType.io:
        return _calculateIOScore(metrics);
      default:
        return 85; // 默认评分
    }
  }

  /// 计算内存评分
  double _calculateMemoryScore(List<PerformanceMetric> metrics) {
    final memoryUsages = metrics.map((m) => m.value).toList();
    if (memoryUsages.isEmpty) return 100;

    final maxMemory = memoryUsages.reduce((a, b) => a > b ? a : b);
    final avgMemory =
        memoryUsages.reduce((a, b) => a + b) / memoryUsages.length;

    // 基于内存使用情况评分
    if (maxMemory > 500 * 1024 * 1024) return 40; // 超过500MB
    if (maxMemory > 200 * 1024 * 1024) return 60; // 超过200MB
    if (maxMemory > 100 * 1024 * 1024) return 80; // 超过100MB
    if (avgMemory > 50 * 1024 * 1024) return 90; // 平均超过50MB

    return 95;
  }

  /// 计算执行时间评分
  double _calculateExecutionScore(List<PerformanceMetric> metrics) {
    final executionTimes = metrics.map((m) => m.value).toList();
    if (executionTimes.isEmpty) return 100;

    final maxTime = executionTimes.reduce((a, b) => a > b ? a : b);
    final avgTime =
        executionTimes.reduce((a, b) => a + b) / executionTimes.length;

    // 基于执行时间评分
    if (maxTime > 10000) return 30; // 超过10秒
    if (maxTime > 5000) return 50; // 超过5秒
    if (maxTime > 2000) return 70; // 超过2秒
    if (avgTime > 1000) return 85; // 平均超过1秒

    return 95;
  }

  /// 计算I/O评分
  double _calculateIOScore(List<PerformanceMetric> metrics) {
    // 简化的I/O评分逻辑
    return 85;
  }

  /// 获取瓶颈描述
  String _getBottleneckDescription(
      PerformanceMetricType type, List<PerformanceMetric> metrics) {
    switch (type) {
      case PerformanceMetricType.memory:
        final maxMemory =
            metrics.map((m) => m.value).reduce((a, b) => a > b ? a : b);
        return '内存使用过高: ${_formatBytes(maxMemory.toInt())}';
      case PerformanceMetricType.execution:
        final maxTime =
            metrics.map((m) => m.value).reduce((a, b) => a > b ? a : b);
        return '执行时间过长: ${maxTime.toInt()}ms';
      default:
        return '${type.name} 性能需要优化';
    }
  }

  /// 获取优化建议
  List<String> _getRecommendations(
      PerformanceMetricType type, List<PerformanceMetric> metrics) {
    switch (type) {
      case PerformanceMetricType.memory:
        return [
          '考虑使用对象池减少内存分配',
          '及时释放不需要的资源',
          '使用流式处理大数据',
          '启用垃圾回收优化',
        ];
      case PerformanceMetricType.execution:
        return [
          '优化算法复杂度',
          '使用异步操作避免阻塞',
          '考虑并行处理',
          '添加缓存机制',
        ];
      case PerformanceMetricType.io:
        return [
          '使用批量I/O操作',
          '启用I/O缓冲',
          '考虑异步I/O',
          '优化文件访问模式',
        ];
      default:
        return ['优化 ${type.name} 相关操作'];
    }
  }

  /// 格式化字节数
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 获取性能统计
  Map<String, dynamic> getPerformanceStats() {
    final analysis = analyzePerformance();

    return {
      'monitoring_enabled': _isEnabled,
      'monitoring_duration': _startTime != null
          ? DateTime.now().difference(_startTime!).inSeconds
          : 0,
      'total_metrics': _metrics.length,
      'overall_score': analysis.overallScore,
      'type_scores': analysis.typeScores.map((k, v) => MapEntry(k.name, v)),
      'bottlenecks_count': analysis.bottlenecks.length,
      'recommendations_count': analysis.recommendations.length,
      'baseline_memory':
          _baselineMemory != null ? _formatBytes(_baselineMemory!) : 'unknown',
      'current_memory': _formatBytes(_getCurrentMemoryUsage()),
    };
  }

  /// 导出性能报告
  Future<void> exportReport(String outputPath) async {
    try {
      final analysis = analyzePerformance();
      final report = {
        'export_time': DateTime.now().toIso8601String(),
        'analysis': analysis.toJson(),
        'stats': getPerformanceStats(),
      };

      final file = File(outputPath);
      await file.writeAsString(jsonEncode(report));

      Logger.info('性能报告已导出: $outputPath');
    } catch (e) {
      Logger.error('导出性能报告失败: $e');
      rethrow;
    }
  }

  /// 清理性能数据
  void clearMetrics() {
    _metrics.clear();
    Logger.info('性能指标已清理');
  }

  /// 获取指标数量
  int get metricsCount => _metrics.length;

  /// 是否正在监控
  bool get isMonitoring => _isEnabled;
}
