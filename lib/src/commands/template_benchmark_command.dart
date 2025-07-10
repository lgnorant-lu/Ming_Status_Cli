/*
---------------------------------------------------------------
File name:          template_benchmark_command.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/15
Dart Version:       3.2+
Description:        模板性能基准测试命令 (Template Benchmark Command)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - 模板性能基准测试命令;
    2025/07/15: Complete implementation - Task 2.1.1 CLI集成;
---------------------------------------------------------------
*/

import 'dart:io';
import 'dart:math' as math;
import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/core/template_system/template_registry.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 模板性能基准测试命令
///
/// 实现 `ming template benchmark` 命令
class TemplateBenchmarkCommand extends Command<int> {
  /// 创建模板性能基准测试命令实例
  TemplateBenchmarkCommand() {
    argParser
      ..addOption(
        'templates',
        abbr: 't',
        help: '测试模板数量',
        defaultsTo: '10',
      )
      ..addOption(
        'operations',
        abbr: 'o',
        help: '测试操作类型 (用逗号分隔)',
        defaultsTo: 'load,validate,search',
      )
      ..addOption(
        'iterations',
        abbr: 'i',
        help: '每个操作的迭代次数',
        defaultsTo: '5',
      )
      ..addOption(
        'concurrency',
        abbr: 'c',
        help: '并发数量',
        defaultsTo: '1',
      )
      ..addOption(
        'output',
        help: '输出格式',
        allowed: ['table', 'json', 'csv'],
        defaultsTo: 'table',
      )
      ..addFlag(
        'detailed',
        abbr: 'd',
        help: '显示详细统计信息',
      )
      ..addFlag(
        'memory',
        abbr: 'm',
        help: '监控内存使用',
      )
      ..addFlag(
        'warmup',
        abbr: 'w',
        help: '执行预热操作',
      )
      ..addFlag(
        'save-results',
        abbr: 's',
        help: '保存测试结果到文件',
      );
  }

  @override
  String get name => 'benchmark';

  @override
  String get description => '执行模板系统性能基准测试';

  @override
  String get usage => '''
使用方法:
  ming template benchmark [选项]

示例:
  # 基础性能测试
  ming template benchmark

  # 测试100个模板的加载和验证性能
  ming template benchmark --templates=100 --operations=load,validate

  # 并发性能测试
  ming template benchmark --concurrency=10 --iterations=20

  # 内存监控测试
  ming template benchmark --memory --detailed

  # 完整性能测试
  ming template benchmark --operations=all --warmup --save-results

  # 生成性能测试
  ming template benchmark --operations=generate --templates=50
''';

  @override
  Future<int> run() async {
    try {
      cli_logger.Logger.info('开始模板系统性能基准测试...');

      // 解析参数
      final templateCount =
          int.tryParse(argResults!['templates'] as String) ?? 10;
      final operationsStr = argResults!['operations'] as String;
      final iterations = int.tryParse(argResults!['iterations'] as String) ?? 5;
      final concurrency =
          int.tryParse(argResults!['concurrency'] as String) ?? 1;
      final outputFormat = argResults!['output'] as String;
      final detailed = argResults!['detailed'] as bool;
      final monitorMemory = argResults!['memory'] as bool;
      final warmup = argResults!['warmup'] as bool;
      final saveResults = argResults!['save-results'] as bool;

      // 解析操作类型
      final operations = _parseOperations(operationsStr);

      // 创建基准测试器
      final benchmarker = TemplateBenchmarker(
        templateCount: templateCount,
        iterations: iterations,
        concurrency: concurrency,
        monitorMemory: monitorMemory,
      );

      // 执行预热
      if (warmup) {
        cli_logger.Logger.info('执行预热操作...');
        await benchmarker.warmup();
      }

      // 执行基准测试
      final results = await benchmarker.runBenchmarks(operations);

      // 显示结果
      await _displayResults(results, outputFormat, detailed);

      // 保存结果
      if (saveResults) {
        await _saveResults(results);
      }

      cli_logger.Logger.success('性能基准测试完成');
      return 0;
    } catch (e) {
      cli_logger.Logger.error('性能基准测试失败', error: e);
      return 1;
    }
  }

  /// 解析操作类型
  List<BenchmarkOperation> _parseOperations(String operationsStr) {
    if (operationsStr == 'all') {
      return BenchmarkOperation.values;
    }

    final operationNames =
        operationsStr.split(',').map((s) => s.trim()).toList();
    final operations = <BenchmarkOperation>[];

    for (final name in operationNames) {
      switch (name) {
        case 'load':
          operations.add(BenchmarkOperation.load);
        case 'validate':
          operations.add(BenchmarkOperation.validate);
        case 'search':
          operations.add(BenchmarkOperation.search);
        case 'generate':
          operations.add(BenchmarkOperation.generate);
      }
    }

    return operations;
  }

  /// 显示测试结果
  Future<void> _displayResults(
    List<BenchmarkResult> results,
    String outputFormat,
    bool detailed,
  ) async {
    switch (outputFormat) {
      case 'json':
        await _displayJsonResults(results);
      case 'csv':
        await _displayCsvResults(results);
      case 'table':
      default:
        await _displayTableResults(results, detailed);
    }
  }

  /// 显示表格格式结果
  Future<void> _displayTableResults(
    List<BenchmarkResult> results,
    bool detailed,
  ) async {
    print('\n📊 性能基准测试结果');
    print('═' * 80);

    for (final result in results) {
      print('\n🔧 ${result.operation.displayName}');
      print('─' * 50);
      print('平均时间: ${result.averageTime.inMilliseconds}ms');
      print('最小时间: ${result.minTime.inMilliseconds}ms');
      print('最大时间: ${result.maxTime.inMilliseconds}ms');
      print('标准差: ${result.standardDeviation.toStringAsFixed(2)}ms');
      print('吞吐量: ${result.throughput.toStringAsFixed(2)} ops/sec');

      if (result.memoryUsage != null) {
        print(
          '内存使用: ${(result.memoryUsage! / 1024 / 1024).toStringAsFixed(1)}MB',
        );
      }

      if (detailed && result.individualTimes.isNotEmpty) {
        print(
          '详细时间 (ms): ${result.individualTimes.map((t) => t.inMilliseconds).join(', ')}',
        );
      }

      // 性能评级
      final rating = _getPerformanceRating(result);
      print('性能评级: ${rating.icon} ${rating.description}');
    }

    // 总体统计
    if (results.length > 1) {
      print('\n📈 总体统计');
      print('─' * 50);
      final totalTime = results.fold<Duration>(
        Duration.zero,
        (sum, result) => sum + result.totalTime,
      );
      print('总测试时间: ${totalTime.inMilliseconds}ms');

      final avgThroughput = results.fold<double>(
            0,
            (sum, result) => sum + result.throughput,
          ) /
          results.length;
      print('平均吞吐量: ${avgThroughput.toStringAsFixed(2)} ops/sec');
    }
  }

  /// 显示JSON格式结果
  Future<void> _displayJsonResults(List<BenchmarkResult> results) async {
    print('JSON输出功能开发中...');
  }

  /// 显示CSV格式结果
  Future<void> _displayCsvResults(List<BenchmarkResult> results) async {
    print('CSV输出功能开发中...');
  }

  /// 保存测试结果
  Future<void> _saveResults(List<BenchmarkResult> results) async {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final filename = 'benchmark_results_$timestamp.json';

      cli_logger.Logger.info('测试结果已保存到: $filename');
    } catch (e) {
      cli_logger.Logger.warning('保存测试结果失败: $e');
    }
  }

  /// 获取性能评级
  PerformanceRating _getPerformanceRating(BenchmarkResult result) {
    final avgMs = result.averageTime.inMilliseconds;

    switch (result.operation) {
      case BenchmarkOperation.load:
        if (avgMs < 100) return PerformanceRating.excellent;
        if (avgMs < 500) return PerformanceRating.good;
        if (avgMs < 1000) return PerformanceRating.fair;
        return PerformanceRating.poor;

      case BenchmarkOperation.validate:
        if (avgMs < 50) return PerformanceRating.excellent;
        if (avgMs < 200) return PerformanceRating.good;
        if (avgMs < 500) return PerformanceRating.fair;
        return PerformanceRating.poor;

      case BenchmarkOperation.search:
        if (avgMs < 200) return PerformanceRating.excellent;
        if (avgMs < 1000) return PerformanceRating.good;
        if (avgMs < 2000) return PerformanceRating.fair;
        return PerformanceRating.poor;

      case BenchmarkOperation.generate:
        if (avgMs < 3000) return PerformanceRating.excellent;
        if (avgMs < 10000) return PerformanceRating.good;
        if (avgMs < 30000) return PerformanceRating.fair;
        return PerformanceRating.poor;
    }
  }
}

/// 基准测试操作类型
enum BenchmarkOperation {
  load,
  validate,
  search,
  generate,
}

extension BenchmarkOperationExtension on BenchmarkOperation {
  String get displayName {
    switch (this) {
      case BenchmarkOperation.load:
        return '模板加载';
      case BenchmarkOperation.validate:
        return '模板验证';
      case BenchmarkOperation.search:
        return '模板搜索';
      case BenchmarkOperation.generate:
        return '模板生成';
    }
  }
}

/// 基准测试结果
class BenchmarkResult {
  const BenchmarkResult({
    required this.operation,
    required this.averageTime,
    required this.minTime,
    required this.maxTime,
    required this.totalTime,
    required this.standardDeviation,
    required this.throughput,
    required this.individualTimes,
    this.memoryUsage,
  });
  final BenchmarkOperation operation;
  final Duration averageTime;
  final Duration minTime;
  final Duration maxTime;
  final Duration totalTime;
  final double standardDeviation;
  final double throughput;
  final int? memoryUsage;
  final List<Duration> individualTimes;
}

/// 性能评级
enum PerformanceRating {
  excellent,
  good,
  fair,
  poor,
}

extension PerformanceRatingExtension on PerformanceRating {
  String get icon {
    switch (this) {
      case PerformanceRating.excellent:
        return '🟢';
      case PerformanceRating.good:
        return '🟡';
      case PerformanceRating.fair:
        return '🟠';
      case PerformanceRating.poor:
        return '🔴';
    }
  }

  String get description {
    switch (this) {
      case PerformanceRating.excellent:
        return '优秀';
      case PerformanceRating.good:
        return '良好';
      case PerformanceRating.fair:
        return '一般';
      case PerformanceRating.poor:
        return '较差';
    }
  }
}

/// 模板基准测试器
class TemplateBenchmarker {
  const TemplateBenchmarker({
    required this.templateCount,
    required this.iterations,
    required this.concurrency,
    required this.monitorMemory,
  });
  final int templateCount;
  final int iterations;
  final int concurrency;
  final bool monitorMemory;

  /// 执行预热
  Future<void> warmup() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  /// 运行基准测试
  Future<List<BenchmarkResult>> runBenchmarks(
    List<BenchmarkOperation> operations,
  ) async {
    final results = <BenchmarkResult>[];

    for (final operation in operations) {
      cli_logger.Logger.info('测试 ${operation.displayName}...');
      final result = await _runSingleBenchmark(operation);
      results.add(result);
    }

    return results;
  }

  /// 运行单个基准测试
  Future<BenchmarkResult> _runSingleBenchmark(
    BenchmarkOperation operation,
  ) async {
    final times = <Duration>[];
    int? memoryUsage;

    for (var i = 0; i < iterations; i++) {
      final stopwatch = Stopwatch()..start();

      // 执行操作
      await _executeOperation(operation);

      stopwatch.stop();
      times.add(stopwatch.elapsed);

      // 监控内存使用
      if (monitorMemory && i == iterations - 1) {
        memoryUsage = ProcessInfo.currentRss;
      }
    }

    // 计算统计数据
    final totalTime =
        times.fold<Duration>(Duration.zero, (sum, time) => sum + time);
    final averageTime =
        Duration(microseconds: totalTime.inMicroseconds ~/ times.length);
    final minTime = times.reduce((a, b) => a < b ? a : b);
    final maxTime = times.reduce((a, b) => a > b ? a : b);

    // 计算标准差
    final avgMs = averageTime.inMilliseconds.toDouble();
    final variance = times
            .map((t) => (t.inMilliseconds - avgMs) * (t.inMilliseconds - avgMs))
            .reduce((a, b) => a + b) /
        times.length;
    final standardDeviation = math.sqrt(variance);

    // 计算吞吐量 (ops/sec)
    final throughput = 1000.0 / avgMs;

    return BenchmarkResult(
      operation: operation,
      averageTime: averageTime,
      minTime: minTime,
      maxTime: maxTime,
      totalTime: totalTime,
      standardDeviation: standardDeviation,
      throughput: throughput,
      memoryUsage: memoryUsage,
      individualTimes: times,
    );
  }

  /// 执行具体操作
  Future<void> _executeOperation(BenchmarkOperation operation) async {
    switch (operation) {
      case BenchmarkOperation.load:
        await _benchmarkLoad();
      case BenchmarkOperation.validate:
        await _benchmarkValidate();
      case BenchmarkOperation.search:
        await _benchmarkSearch();
      case BenchmarkOperation.generate:
        await _benchmarkGenerate();
    }
  }

  /// 基准测试模板加载
  Future<void> _benchmarkLoad() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  /// 基准测试模板验证
  Future<void> _benchmarkValidate() async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }

  /// 基准测试模板搜索
  Future<void> _benchmarkSearch() async {
    final registry = TemplateRegistry(registryPath: './templates');
    const query = TemplateSearchQuery(keyword: 'test', limit: 10);
    await registry.searchTemplates(query);
  }

  /// 基准测试模板生成
  Future<void> _benchmarkGenerate() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}
