/*
---------------------------------------------------------------
File name:          optimize_command.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        性能优化命令 (Optimize Command)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - 性能优化CLI命令;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/core/performance/memory_optimizer.dart';
import 'package:ming_status_cli/src/core/performance/performance_optimizer.dart';
import 'package:ming_status_cli/src/core/performance/startup_optimizer.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;
import 'package:ming_status_cli/src/utils/progress_manager.dart';
import 'package:path/path.dart' as path;

/// 性能优化命令
class OptimizeCommand extends Command<int> {
  /// 创建性能优化命令实例
  OptimizeCommand() {
    argParser
      ..addOption(
        'strategy',
        abbr: 's',
        help: '优化策略',
        allowed: [
          'startup',
          'memory',
          'response',
          'concurrency',
          'cache',
          'comprehensive',
        ],
        defaultsTo: 'comprehensive',
      )
      ..addFlag(
        'report',
        abbr: 'r',
        help: '生成优化报告',
        defaultsTo: true,
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: '报告输出目录',
        defaultsTo: 'reports',
      )
      ..addFlag(
        'auto',
        abbr: 'a',
        help: '启用自动优化',
      )
      ..addOption(
        'target-memory',
        help: '目标内存使用限制 (MB)',
        defaultsTo: '500',
      )
      ..addOption(
        'target-response',
        help: '目标响应时间 (ms)',
        defaultsTo: '3000',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: '显示详细输出',
      );
  }

  @override
  String get name => 'optimize';

  @override
  String get description => '执行性能优化和分析';

  @override
  String get category => '性能工具';

  @override
  String get usage => '''
执行性能优化和分析

使用方法:
  ming optimize [选项]

优化选项:
  -s, --strategy=<策略>      优化策略 (默认: comprehensive)
                            允许: startup, memory, response, concurrency, cache, comprehensive
      --target-memory=<MB>   目标内存使用限制 (默认: 500MB)
      --target-response=<ms> 目标响应时间 (默认: 3000ms)
  -a, --auto                 启用自动优化

输出选项:
  -r, --[no-]report         生成优化报告 (默认: on)
  -o, --output=<目录>       报告输出目录 (默认: reports)
  -v, --verbose             显示详细输出

优化策略说明:
  • startup       - 启动时间优化
  • memory        - 内存使用优化
  • response      - 响应时间优化
  • concurrency   - 并发性能优化
  • cache         - 缓存策略优化
  • comprehensive - 综合优化 (推荐)

示例:
  # 综合性能优化
  ming optimize

  # 专注启动时间优化
  ming optimize --strategy=startup

  # 内存优化，设置目标限制
  ming optimize --strategy=memory --target-memory=256

  # 自动优化并生成详细报告
  ming optimize --auto --verbose --output=./performance_reports

  # 响应时间优化，目标3秒内
  ming optimize --strategy=response --target-response=3000

更多信息:
  使用 'ming help optimize' 查看详细文档
''';

  /// 性能优化器
  late final PerformanceOptimizer _performanceOptimizer;

  /// 启动优化器
  late final StartupOptimizer _startupOptimizer;

  /// 内存优化器
  late final MemoryOptimizer _memoryOptimizer;

  @override
  Future<int> run() async {
    try {
      // 解析参数
      final strategy = _parseStrategy(argResults!['strategy'] as String);
      final generateReport = argResults!['report'] as bool;
      final outputDir = argResults!['output'] as String;
      final enableAuto = argResults!['auto'] as bool;
      final targetMemory =
          int.parse(argResults!['target-memory'] as String) * 1024 * 1024;
      final targetResponse =
          int.parse(argResults!['target-response'] as String);
      final verbose = argResults!['verbose'] as bool;

      // 设置详细输出
      if (verbose) {
        cli_logger.Logger.debug('启用详细输出模式');
      }

      cli_logger.Logger.info('开始性能优化...');

      // 创建进度管理器
      final progress = ProgressManager()
        ..addTasks([
          {
            'id': 'initialization',
            'name': '初始化优化器',
            'description': '初始化性能优化组件',
          },
          {
            'id': 'baseline_measurement',
            'name': '基准测量',
            'description': '测量当前性能指标',
          },
          {
            'id': 'optimization_execution',
            'name': '执行优化',
            'description': '应用性能优化策略',
          },
          {
            'id': 'result_analysis',
            'name': '结果分析',
            'description': '分析优化效果',
          },
          if (generateReport)
            {
              'id': 'report_generation',
              'name': '生成报告',
              'description': '生成性能优化报告',
            },
        ])
        ..start(title: '性能优化');

      // 1. 初始化优化器
      await progress.executeTask(() async {
        await _initializeOptimizers(targetMemory, targetResponse, enableAuto);
      });

      // 2. 基准测量
      final baselineMetrics = await progress.executeTask(() async {
        return _measureBaseline();
      });

      cli_logger.Logger.info('基准性能指标:');
      cli_logger.Logger.info('  启动时间: ${baselineMetrics.startupTime}ms');
      cli_logger.Logger.info(
        '  内存使用: ${_formatBytes(baselineMetrics.memoryUsage)}',
      );
      cli_logger.Logger.info('  响应时间: ${baselineMetrics.responseTime}ms');

      // 3. 执行优化
      final optimizationResult = await progress.executeTask(() async {
        return _executeOptimization(strategy);
      });

      // 4. 结果分析
      final analysis = await progress.executeTask(() async {
        return _analyzeResults(optimizationResult);
      });

      // 5. 生成报告
      if (generateReport) {
        await progress.executeTask(() async {
          await _generateReports(outputDir, optimizationResult, analysis);
        });
      }

      progress.complete();

      // 显示优化结果
      _displayResults(optimizationResult, analysis);

      cli_logger.Logger.success('性能优化完成');
      return 0;
    } catch (e) {
      cli_logger.Logger.error('性能优化失败', error: e);
      return 1;
    }
  }

  /// 解析优化策略
  OptimizationStrategy _parseStrategy(String strategy) {
    switch (strategy) {
      case 'startup':
        return OptimizationStrategy.startup;
      case 'memory':
        return OptimizationStrategy.memory;
      case 'response':
        return OptimizationStrategy.response;
      case 'concurrency':
        return OptimizationStrategy.concurrency;
      case 'cache':
        return OptimizationStrategy.cache;
      case 'comprehensive':
      default:
        return OptimizationStrategy.comprehensive;
    }
  }

  /// 初始化优化器
  Future<void> _initializeOptimizers(
    int targetMemory,
    int targetResponse,
    bool enableAuto,
  ) async {
    _performanceOptimizer = PerformanceOptimizer(
      enableAutoOptimization: enableAuto,
      maxMemoryUsage: targetMemory,
      targetResponseTime: targetResponse,
    );

    _startupOptimizer = StartupOptimizer(
      targetStartupTime: Duration(milliseconds: targetResponse),
    );

    _memoryOptimizer = MemoryOptimizer(
      maxMemoryUsage: targetMemory,
      enableAutoOptimization: enableAuto,
    );

    await _performanceOptimizer.initialize();
    await _memoryOptimizer.initialize();

    cli_logger.Logger.debug('优化器初始化完成');
  }

  /// 测量基准性能
  Future<PerformanceMetrics> _measureBaseline() async {
    return _performanceOptimizer.getCurrentMetrics();
  }

  /// 执行优化
  Future<OptimizationResult> _executeOptimization(
    OptimizationStrategy strategy,
  ) async {
    cli_logger.Logger.info('执行优化策略: ${strategy.name}');
    return _performanceOptimizer.optimize(strategy);
  }

  /// 分析结果
  Map<String, dynamic> _analyzeResults(OptimizationResult result) {
    final improvements = result.improvements;
    final significantImprovements = improvements.entries
        .where((entry) => entry.value.abs() > 5.0) // 改进超过5%
        .toList();

    return {
      'success': result.success,
      'total_improvements': improvements.length,
      'significant_improvements': significantImprovements.length,
      'best_improvement': significantImprovements.isNotEmpty
          ? () {
              final best = significantImprovements.reduce(
                (a, b) => a.value > b.value ? a : b,
              );
              return {'metric': best.key, 'improvement': best.value};
            }()
          : null,
      'applied_optimizations_count': result.appliedOptimizations.length,
      'recommendations_count': result.recommendations.length,
    };
  }

  /// 生成报告
  Future<void> _generateReports(
    String outputDir,
    OptimizationResult result,
    Map<String, dynamic> analysis,
  ) async {
    final reportsDir = Directory(outputDir);
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    // 生成性能优化报告
    final performanceReport = _performanceOptimizer.generateReport();
    final performanceReportPath =
        path.join(outputDir, 'performance_report.json');
    await File(performanceReportPath).writeAsString(
      _formatJson(performanceReport),
    );

    // 生成内存优化报告
    final memoryReport = _memoryOptimizer.generateMemoryReport();
    final memoryReportPath = path.join(outputDir, 'memory_report.json');
    await File(memoryReportPath).writeAsString(
      _formatJson(memoryReport),
    );

    // 生成启动优化报告
    final startupReport = _startupOptimizer.generateStartupReport();
    final startupReportPath = path.join(outputDir, 'startup_report.json');
    await File(startupReportPath).writeAsString(
      _formatJson(startupReport),
    );

    // 生成综合报告
    final comprehensiveReport = {
      'timestamp': DateTime.now().toIso8601String(),
      'optimization_result': {
        'strategy': result.strategy.name,
        'success': result.success,
        'improvements': result.improvements,
        'applied_optimizations': result.appliedOptimizations,
        'recommendations': result.recommendations,
      },
      'analysis': analysis,
      'performance_metrics': {
        'before': result.beforeMetrics.toMap(),
        'after': result.afterMetrics.toMap(),
      },
    };

    final comprehensiveReportPath =
        path.join(outputDir, 'comprehensive_report.json');
    await File(comprehensiveReportPath).writeAsString(
      _formatJson(comprehensiveReport),
    );

    cli_logger.Logger.info('报告已生成到: $outputDir');
  }

  /// 显示结果
  void _displayResults(
    OptimizationResult result,
    Map<String, dynamic> analysis,
  ) {
    cli_logger.Logger.info('\n📊 优化结果摘要:');
    cli_logger.Logger.info('  策略: ${result.strategy.name}');
    cli_logger.Logger.info('  状态: ${result.success ? '成功' : '失败'}');
    cli_logger.Logger.info('  应用的优化: ${result.appliedOptimizations.length}个');

    if (result.improvements.isNotEmpty) {
      cli_logger.Logger.info('\n📈 性能改进:');
      for (final entry in result.improvements.entries) {
        final improvement = entry.value;
        final sign = improvement > 0 ? '+' : '';
        final color = improvement > 0
            ? '🟢'
            : improvement < 0
                ? '🔴'
                : '⚪';
        cli_logger.Logger.info(
          '  $color ${entry.key}: $sign${improvement.toStringAsFixed(1)}%',
        );
      }
    }

    if (result.recommendations.isNotEmpty) {
      cli_logger.Logger.info('\n💡 建议:');
      for (final recommendation in result.recommendations) {
        cli_logger.Logger.info('  • $recommendation');
      }
    }

    final significantImprovements = analysis['significant_improvements'] as int;
    if (significantImprovements > 0) {
      cli_logger.Logger.info('\n🎯 发现 $significantImprovements 个显著改进');
    }
  }

  /// 格式化JSON
  String _formatJson(Map<String, dynamic> data) {
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// 格式化字节数
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}
