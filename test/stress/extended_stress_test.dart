/*
---------------------------------------------------------------
File name:          extended_stress_test.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        扩展压力测试 (Extended Stress Test)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - 大规模压力测试和长期稳定性测试;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:ming_status_cli/src/core/performance/memory_optimizer.dart';
import 'package:ming_status_cli/src/core/performance/performance_optimizer.dart';
import 'package:ming_status_cli/src/core/performance/startup_optimizer.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;
import 'package:path/path.dart' as path;

/// 压力测试配置
class StressTestConfig {
  /// 创建压力测试配置实例
  const StressTestConfig({
    this.concurrentUsers = 100,
    this.operationsPerUser = 1000,
    this.testDuration = const Duration(hours: 1),
    this.rampUpTime = const Duration(minutes: 5),
    this.maxMemoryUsage = 1024 * 1024 * 1024, // 1GB
    this.maxResponseTime = 5000, // 5秒
    this.errorThreshold = 0.05, // 5%
    this.enableMemoryProfiling = true,
    this.enablePerformanceProfiling = true,
  });

  /// 并发用户数
  final int concurrentUsers;

  /// 每用户操作数
  final int operationsPerUser;

  /// 测试持续时间
  final Duration testDuration;

  /// 加压时间
  final Duration rampUpTime;

  /// 最大内存使用
  final int maxMemoryUsage;

  /// 最大响应时间
  final int maxResponseTime;

  /// 错误阈值
  final double errorThreshold;

  /// 是否启用内存分析
  final bool enableMemoryProfiling;

  /// 是否启用性能分析
  final bool enablePerformanceProfiling;
}

/// 压力测试结果
class StressTestResult {
  /// 创建压力测试结果实例
  const StressTestResult({
    required this.success,
    required this.totalOperations,
    required this.successfulOperations,
    required this.failedOperations,
    required this.averageResponseTime,
    required this.maxResponseTime,
    required this.minResponseTime,
    required this.throughput,
    required this.errorRate,
    required this.memoryUsage,
    required this.duration,
    this.errors = const [],
    this.warnings = const [],
    this.performanceMetrics = const {},
  });

  /// 是否成功
  final bool success;

  /// 总操作数
  final int totalOperations;

  /// 成功操作数
  final int successfulOperations;

  /// 失败操作数
  final int failedOperations;

  /// 平均响应时间
  final double averageResponseTime;

  /// 最大响应时间
  final double maxResponseTime;

  /// 最小响应时间
  final double minResponseTime;

  /// 吞吐量 (操作/秒)
  final double throughput;

  /// 错误率
  final double errorRate;

  /// 内存使用情况
  final Map<String, dynamic> memoryUsage;

  /// 测试持续时间
  final Duration duration;

  /// 错误列表
  final List<String> errors;

  /// 警告列表
  final List<String> warnings;

  /// 性能指标
  final Map<String, dynamic> performanceMetrics;
}

/// 扩展压力测试器
class ExtendedStressTester {
  /// 创建扩展压力测试器实例
  ExtendedStressTester({
    required this.config,
    this.outputDirectory,
  });

  /// 测试配置
  final StressTestConfig config;

  /// 输出目录
  final String? outputDirectory;

  /// 性能优化器
  late final PerformanceOptimizer _performanceOptimizer;

  /// 内存优化器
  late final MemoryOptimizer _memoryOptimizer;

  /// 启动优化器
  late final StartupOptimizer _startupOptimizer;

  /// 测试结果
  final List<StressTestResult> _testResults = [];

  /// 是否正在运行
  bool _isRunning = false;

  /// 初始化压力测试器
  Future<void> initialize() async {
    _performanceOptimizer = PerformanceOptimizer();
    _memoryOptimizer = MemoryOptimizer();
    _startupOptimizer = StartupOptimizer();

    await _performanceOptimizer.initialize();
    await _memoryOptimizer.initialize();

    cli_logger.Logger.info('扩展压力测试器初始化完成');
  }

  /// 执行大规模并发测试
  Future<StressTestResult> runConcurrencyStressTest() async {
    cli_logger.Logger.info('开始大规模并发压力测试: ${config.concurrentUsers}个并发用户');

    final stopwatch = Stopwatch()..start();
    final operations = <Future<bool>>[];
    final responseTimes = <double>[];
    var successCount = 0;
    var failureCount = 0;
    final errors = <String>[];
    final warnings = <String>[];

    try {
      _isRunning = true;

      // 启动内存监控
      final memoryMonitor = _startMemoryMonitoring();

      // 分批启动并发用户
      final batchSize = (config.concurrentUsers / 10).ceil();
      final rampUpDelay = config.rampUpTime.inMilliseconds ~/ 10;

      for (var batch = 0; batch < 10; batch++) {
        final batchStart = batch * batchSize;
        final batchEnd =
            math.min((batch + 1) * batchSize, config.concurrentUsers);

        // 启动当前批次的用户
        for (var user = batchStart; user < batchEnd; user++) {
          operations.add(_simulateUserOperations(user, responseTimes));
        }

        // 等待加压延迟
        if (batch < 9) {
          await Future.delayed(Duration(milliseconds: rampUpDelay));
        }
      }

      cli_logger.Logger.info('所有用户已启动，等待操作完成...');

      // 等待所有操作完成
      final results = await Future.wait(operations);

      // 统计结果
      for (final success in results) {
        if (success) {
          successCount++;
        } else {
          failureCount++;
        }
      }

      stopwatch.stop();

      // 停止内存监控
      final memoryUsage = await _stopMemoryMonitoring(memoryMonitor);

      // 计算统计数据
      final totalOperations = successCount + failureCount;
      final errorRate =
          totalOperations > 0 ? failureCount / totalOperations : 0.0;
      final averageResponseTime = responseTimes.isNotEmpty
          ? responseTimes.reduce((a, b) => a + b) / responseTimes.length
          : 0.0;
      final maxResponseTime =
          responseTimes.isNotEmpty ? responseTimes.reduce(math.max) : 0.0;
      final minResponseTime =
          responseTimes.isNotEmpty ? responseTimes.reduce(math.min) : 0.0;
      final throughput =
          totalOperations / (stopwatch.elapsedMilliseconds / 1000.0);

      // 检查是否满足要求
      final success = errorRate <= config.errorThreshold &&
          averageResponseTime <= config.maxResponseTime;

      if (!success) {
        if (errorRate > config.errorThreshold) {
          errors.add('错误率过高: ${(errorRate * 100).toStringAsFixed(2)}%');
        }
        if (averageResponseTime > config.maxResponseTime) {
          errors.add('平均响应时间过长: ${averageResponseTime.toStringAsFixed(2)}ms');
        }
      }

      final result = StressTestResult(
        success: success,
        totalOperations: totalOperations,
        successfulOperations: successCount,
        failedOperations: failureCount,
        averageResponseTime: averageResponseTime,
        maxResponseTime: maxResponseTime,
        minResponseTime: minResponseTime,
        throughput: throughput,
        errorRate: errorRate,
        memoryUsage: memoryUsage,
        duration: stopwatch.elapsed,
        errors: errors,
        warnings: warnings,
      );

      _testResults.add(result);

      cli_logger.Logger.info(
        '并发压力测试完成: ${success ? '成功' : '失败'} - '
        '$totalOperations个操作, 错误率${(errorRate * 100).toStringAsFixed(2)}%',
      );

      return result;
    } catch (e) {
      stopwatch.stop();
      errors.add('测试执行失败: $e');

      final result = StressTestResult(
        success: false,
        totalOperations: 0,
        successfulOperations: 0,
        failedOperations: 0,
        averageResponseTime: 0,
        maxResponseTime: 0,
        minResponseTime: 0,
        throughput: 0,
        errorRate: 1,
        memoryUsage: {},
        duration: stopwatch.elapsed,
        errors: errors,
        warnings: warnings,
      );

      _testResults.add(result);
      return result;
    } finally {
      _isRunning = false;
    }
  }

  /// 执行长期稳定性测试
  Future<StressTestResult> runLongTermStabilityTest() async {
    cli_logger.Logger.info('开始长期稳定性测试: ${config.testDuration.inHours}小时');

    final stopwatch = Stopwatch()..start();
    final endTime = DateTime.now().add(config.testDuration);
    var totalOperations = 0;
    var successfulOperations = 0;
    var failedOperations = 0;
    final responseTimes = <double>[];
    final errors = <String>[];
    final warnings = <String>[];
    final memorySnapshots = <Map<String, dynamic>>[];

    try {
      _isRunning = true;

      // 启动持续监控
      final monitoringTimer =
          Timer.periodic(const Duration(minutes: 5), (timer) async {
        try {
          final memoryUsage = await _memoryOptimizer.getCurrentMemoryUsage();
          memorySnapshots.add(memoryUsage.toMap());

          // 检查内存泄漏
          if (memoryUsage.usedBytes > config.maxMemoryUsage) {
            warnings.add('内存使用超过阈值: ${memoryUsage.usedBytes} bytes');

            // 尝试内存优化
            await _memoryOptimizer.optimize();
          }
        } catch (e) {
          warnings.add('监控失败: $e');
        }
      });

      // 持续执行操作
      while (DateTime.now().isBefore(endTime) && _isRunning) {
        try {
          final operationStopwatch = Stopwatch()..start();

          // 模拟操作
          await _simulateOperation();

          operationStopwatch.stop();
          responseTimes.add(operationStopwatch.elapsedMilliseconds.toDouble());

          totalOperations++;
          successfulOperations++;

          // 控制操作频率
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          failedOperations++;
          errors.add('操作失败: $e');
        }
      }

      monitoringTimer.cancel();
      stopwatch.stop();

      // 计算统计数据
      final errorRate =
          totalOperations > 0 ? failedOperations / totalOperations : 0.0;
      final averageResponseTime = responseTimes.isNotEmpty
          ? responseTimes.reduce((a, b) => a + b) / responseTimes.length
          : 0.0;
      final maxResponseTime =
          responseTimes.isNotEmpty ? responseTimes.reduce(math.max) : 0.0;
      final minResponseTime =
          responseTimes.isNotEmpty ? responseTimes.reduce(math.min) : 0.0;
      final throughput =
          totalOperations / (stopwatch.elapsedMilliseconds / 1000.0);

      // 分析内存趋势
      final memoryUsage = _analyzeMemoryTrend(memorySnapshots);

      // 检查稳定性
      final success = errorRate <= config.errorThreshold &&
          averageResponseTime <= config.maxResponseTime &&
          !_hasMemoryLeak(memorySnapshots);

      if (!success) {
        if (errorRate > config.errorThreshold) {
          errors.add('长期错误率过高: ${(errorRate * 100).toStringAsFixed(2)}%');
        }
        if (_hasMemoryLeak(memorySnapshots)) {
          errors.add('检测到内存泄漏');
        }
      }

      final result = StressTestResult(
        success: success,
        totalOperations: totalOperations,
        successfulOperations: successfulOperations,
        failedOperations: failedOperations,
        averageResponseTime: averageResponseTime,
        maxResponseTime: maxResponseTime,
        minResponseTime: minResponseTime,
        throughput: throughput,
        errorRate: errorRate,
        memoryUsage: memoryUsage,
        duration: stopwatch.elapsed,
        errors: errors,
        warnings: warnings,
      );

      _testResults.add(result);

      cli_logger.Logger.info(
        '长期稳定性测试完成: ${success ? '成功' : '失败'} - '
        '运行${stopwatch.elapsed.inHours}小时, $totalOperations个操作',
      );

      return result;
    } catch (e) {
      stopwatch.stop();
      errors.add('长期测试失败: $e');

      final result = StressTestResult(
        success: false,
        totalOperations: totalOperations,
        successfulOperations: successfulOperations,
        failedOperations: failedOperations,
        averageResponseTime: 0,
        maxResponseTime: 0,
        minResponseTime: 0,
        throughput: 0,
        errorRate: 1,
        memoryUsage: {},
        duration: stopwatch.elapsed,
        errors: errors,
        warnings: warnings,
      );

      _testResults.add(result);
      return result;
    } finally {
      _isRunning = false;
    }
  }

  /// 执行大型模板库测试
  Future<StressTestResult> runLargeTemplateLibraryTest() async {
    cli_logger.Logger.info('开始大型模板库压力测试: 10000+模板');

    final stopwatch = Stopwatch()..start();
    var totalOperations = 0;
    var successfulOperations = 0;
    var failedOperations = 0;
    final responseTimes = <double>[];
    final errors = <String>[];
    final warnings = <String>[];

    try {
      _isRunning = true;

      // 创建大量模板
      const templateCount = 10000;
      cli_logger.Logger.info('创建$templateCount个测试模板...');

      for (var i = 0; i < templateCount; i++) {
        try {
          final operationStopwatch = Stopwatch()..start();

          await _createTestTemplate('template_$i');

          operationStopwatch.stop();
          responseTimes.add(operationStopwatch.elapsedMilliseconds.toDouble());

          totalOperations++;
          successfulOperations++;

          // 每1000个模板报告进度
          if ((i + 1) % 1000 == 0) {
            cli_logger.Logger.info('已创建${i + 1}个模板');
          }
        } catch (e) {
          failedOperations++;
          errors.add('创建模板失败: template_$i - $e');
        }
      }

      // 测试模板搜索性能
      cli_logger.Logger.info('测试模板搜索性能...');

      for (var i = 0; i < 1000; i++) {
        try {
          final operationStopwatch = Stopwatch()..start();

          await _searchTemplates(
              'template_${math.Random().nextInt(templateCount)}',);

          operationStopwatch.stop();
          responseTimes.add(operationStopwatch.elapsedMilliseconds.toDouble());

          totalOperations++;
          successfulOperations++;
        } catch (e) {
          failedOperations++;
          errors.add('搜索模板失败: $e');
        }
      }

      stopwatch.stop();

      // 计算统计数据
      final errorRate =
          totalOperations > 0 ? failedOperations / totalOperations : 0.0;
      final averageResponseTime = responseTimes.isNotEmpty
          ? responseTimes.reduce((a, b) => a + b) / responseTimes.length
          : 0.0;
      final maxResponseTime =
          responseTimes.isNotEmpty ? responseTimes.reduce(math.max) : 0.0;
      final minResponseTime =
          responseTimes.isNotEmpty ? responseTimes.reduce(math.min) : 0.0;
      final throughput =
          totalOperations / (stopwatch.elapsedMilliseconds / 1000.0);

      final success = errorRate <= config.errorThreshold &&
          averageResponseTime <= config.maxResponseTime;

      final result = StressTestResult(
        success: success,
        totalOperations: totalOperations,
        successfulOperations: successfulOperations,
        failedOperations: failedOperations,
        averageResponseTime: averageResponseTime,
        maxResponseTime: maxResponseTime,
        minResponseTime: minResponseTime,
        throughput: throughput,
        errorRate: errorRate,
        memoryUsage: {},
        duration: stopwatch.elapsed,
        errors: errors,
        warnings: warnings,
      );

      _testResults.add(result);

      cli_logger.Logger.info(
        '大型模板库测试完成: ${success ? '成功' : '失败'} - '
        '$totalOperations个操作, 平均响应时间${averageResponseTime.toStringAsFixed(2)}ms',
      );

      return result;
    } catch (e) {
      stopwatch.stop();
      errors.add('大型模板库测试失败: $e');

      final result = StressTestResult(
        success: false,
        totalOperations: totalOperations,
        successfulOperations: successfulOperations,
        failedOperations: failedOperations,
        averageResponseTime: 0,
        maxResponseTime: 0,
        minResponseTime: 0,
        throughput: 0,
        errorRate: 1,
        memoryUsage: {},
        duration: stopwatch.elapsed,
        errors: errors,
        warnings: warnings,
      );

      _testResults.add(result);
      return result;
    } finally {
      _isRunning = false;
    }
  }

  /// 生成压力测试报告
  Future<void> generateStressTestReport() async {
    if (outputDirectory == null) return;

    final reportDir = Directory(outputDirectory!);
    if (!await reportDir.exists()) {
      await reportDir.create(recursive: true);
    }

    final reportPath = path.join(outputDirectory!, 'stress_test_report.json');
    final report = {
      'summary': {
        'total_tests': _testResults.length,
        'successful_tests': _testResults.where((r) => r.success).length,
        'failed_tests': _testResults.where((r) => !r.success).length,
        'generated_at': DateTime.now().toIso8601String(),
      },
      'test_results': _testResults
          .map((result) => {
                'success': result.success,
                'total_operations': result.totalOperations,
                'successful_operations': result.successfulOperations,
                'failed_operations': result.failedOperations,
                'average_response_time_ms': result.averageResponseTime,
                'max_response_time_ms': result.maxResponseTime,
                'min_response_time_ms': result.minResponseTime,
                'throughput_ops_per_sec': result.throughput,
                'error_rate': result.errorRate,
                'duration_ms': result.duration.inMilliseconds,
                'errors': result.errors,
                'warnings': result.warnings,
                'memory_usage': result.memoryUsage,
              },)
          .toList(),
      'recommendations': _generateRecommendations(),
    };

    final reportFile = File(reportPath);
    await reportFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );

    cli_logger.Logger.info('压力测试报告已生成: $reportPath');
  }

  /// 模拟用户操作
  Future<bool> _simulateUserOperations(
      int userId, List<double> responseTimes,) async {
    try {
      for (var i = 0; i < config.operationsPerUser; i++) {
        final stopwatch = Stopwatch()..start();

        await _simulateOperation();

        stopwatch.stop();
        responseTimes.add(stopwatch.elapsedMilliseconds.toDouble());

        // 随机延迟模拟真实用户行为
        await Future<void>.delayed(
            Duration(milliseconds: math.Random().nextInt(100)),);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 模拟操作
  Future<void> _simulateOperation() async {
    // 模拟各种操作
    final operations = [
      () => _createTestTemplate('temp_${math.Random().nextInt(1000)}'),
      () => _searchTemplates('test'),
      () => _validateTemplate('test_template'),
      () => _generateFromTemplate('basic_template'),
    ];

    final operation = operations[math.Random().nextInt(operations.length)];
    await operation();
  }

  /// 创建测试模板
  Future<void> _createTestTemplate(String name) async {
    // 模拟模板创建
    await Future<void>.delayed(
      Duration(milliseconds: math.Random().nextInt(50) + 10),
    );
  }

  /// 搜索模板
  Future<void> _searchTemplates(String query) async {
    // 模拟模板搜索
    await Future<void>.delayed(
      Duration(milliseconds: math.Random().nextInt(30) + 5),
    );
  }

  /// 验证模板
  Future<void> _validateTemplate(String templateName) async {
    // 模拟模板验证
    await Future<void>.delayed(
      Duration(milliseconds: math.Random().nextInt(100) + 20),
    );
  }

  /// 从模板生成
  Future<void> _generateFromTemplate(String templateName) async {
    // 模拟模板生成
    await Future<void>.delayed(
      Duration(milliseconds: math.Random().nextInt(200) + 50),
    );
  }

  /// 启动内存监控
  Timer _startMemoryMonitoring() {
    return Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        await _memoryOptimizer.getCurrentMemoryUsage();
      } catch (e) {
        // 忽略监控错误
      }
    });
  }

  /// 停止内存监控
  Future<Map<String, dynamic>> _stopMemoryMonitoring(Timer timer) async {
    timer.cancel();

    try {
      final usage = await _memoryOptimizer.getCurrentMemoryUsage();
      return usage.toMap();
    } catch (e) {
      return {};
    }
  }

  /// 分析内存趋势
  Map<String, dynamic> _analyzeMemoryTrend(
    List<Map<String, dynamic>> snapshots,
  ) {
    if (snapshots.isEmpty) return {};

    final usageValues =
        snapshots.map((s) => s['used_bytes'] as int? ?? 0).toList();

    final maxUsage = usageValues.reduce(math.max);
    final minUsage = usageValues.reduce(math.min);
    final avgUsage = usageValues.reduce((a, b) => a + b) / usageValues.length;

    return {
      'max_usage_bytes': maxUsage,
      'min_usage_bytes': minUsage,
      'average_usage_bytes': avgUsage.round(),
      'trend': _calculateTrend(usageValues),
      'snapshots_count': snapshots.length,
    };
  }

  /// 检查内存泄漏
  bool _hasMemoryLeak(List<Map<String, dynamic>> snapshots) {
    if (snapshots.length < 10) return false;

    final usageValues =
        snapshots.map((s) => s['used_bytes'] as int? ?? 0).toList();

    // 简单的趋势检测：如果最后10个值的平均值比前10个值高50%以上
    final firstTen = usageValues.take(10).toList();
    final lastTen = usageValues.skip(usageValues.length - 10).toList();

    final firstAvg = firstTen.reduce((a, b) => a + b) / firstTen.length;
    final lastAvg = lastTen.reduce((a, b) => a + b) / lastTen.length;

    return (lastAvg - firstAvg) / firstAvg > 0.5;
  }

  /// 计算趋势
  String _calculateTrend(List<int> values) {
    if (values.length < 2) return 'stable';

    final first = values.first;
    final last = values.last;
    final change = (last - first) / first;

    if (change > 0.1) return 'increasing';
    if (change < -0.1) return 'decreasing';
    return 'stable';
  }

  /// 生成建议
  List<String> _generateRecommendations() {
    final recommendations = <String>[];

    if (_testResults.isEmpty) return recommendations;

    final failedTests = _testResults.where((r) => !r.success).length;
    final totalTests = _testResults.length;

    if (failedTests > 0) {
      recommendations.add('$failedTests/$totalTests个测试失败，需要优化系统稳定性');
    }

    final avgResponseTime =
        _testResults.map((r) => r.averageResponseTime).reduce((a, b) => a + b) /
            _testResults.length;

    if (avgResponseTime > config.maxResponseTime) {
      recommendations.add('平均响应时间过长，建议优化性能');
    }

    final avgErrorRate =
        _testResults.map((r) => r.errorRate).reduce((a, b) => a + b) /
            _testResults.length;

    if (avgErrorRate > config.errorThreshold) {
      recommendations.add('错误率过高，建议加强错误处理');
    }

    return recommendations;
  }

  /// 停止测试
  void stop() {
    _isRunning = false;
  }

  /// 清理资源
  void dispose() {
    stop();
    _memoryOptimizer.dispose();
    _performanceOptimizer.dispose();
  }
}
