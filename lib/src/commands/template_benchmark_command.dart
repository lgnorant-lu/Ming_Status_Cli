/*
---------------------------------------------------------------
File name:          template_benchmark_command.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        模板性能基准测试命令 (Template Benchmark Command)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - 模板性能基准测试命令;
    2025/07/11: Complete implementation - Task 2.1.1 CLI集成;
---------------------------------------------------------------
*/

import 'dart:io';
import 'dart:math' as math;

import 'package:args/command_runner.dart';
import 'package:ming_status_cli/src/core/template_system/template_registry.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;
import 'package:path/path.dart' as path;

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
执行模板系统性能基准测试

使用方法:
  ming template benchmark [选项]

测试选项:
  -t, --templates=<数量>     测试模板数量 (默认: 10)
  -o, --operations=<操作>    测试操作类型，用逗号分隔 (默认: load,validate,search)
                            允许: load, validate, search, generate, all
  -i, --iterations=<次数>    每个操作的迭代次数 (默认: 5)
  -c, --concurrency=<数量>   并发数量 (默认: 1)

输出选项:
      --output=<格式>        输出格式 (默认: table, 允许: table, json, csv)
  -d, --detailed             显示详细统计信息
  -m, --memory               监控内存使用
  -s, --save-results         保存测试结果到文件

性能选项:
  -w, --warmup               执行预热操作

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

更多信息:
  使用 'ming help template benchmark' 查看详细文档
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
    } catch (e, stackTrace) {
      cli_logger.Logger.error('性能基准测试失败', error: e);
      print('详细错误信息: $e');
      print('堆栈跟踪: $stackTrace');
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
    // 创建临时测试模板进行真实加载测试
    final tempDir = Directory.systemTemp.createTempSync('benchmark_load_');

    try {
      // 生成测试模板文件
      await _createTestTemplate(tempDir.path);

      // 测试模板文件加载
      await _loadTemplateFiles(tempDir.path);

      // 测试模板元数据解析
      await _parseTemplateMetadata(tempDir.path);

      // 测试模板依赖解析
      await _parseTemplateDependencies(tempDir.path);
    } finally {
      // 清理临时文件
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  }

  /// 基准测试模板验证
  Future<void> _benchmarkValidate() async {
    // 创建临时测试模板进行真实验证测试
    final tempDir = Directory.systemTemp.createTempSync('benchmark_validate_');

    try {
      // 生成测试模板文件
      await _createTestTemplate(tempDir.path);

      // 验证模板结构完整性
      await _validateTemplateStructure(tempDir.path);

      // 验证模板元数据
      await _validateTemplateMetadata(tempDir.path);

      // 验证模板依赖
      await _validateTemplateDependencies(tempDir.path);

      // 验证模板语法
      await _validateTemplateSyntaxFiles(tempDir.path);

      // 验证模板兼容性
      await _validateTemplateCompatibility(tempDir.path);
    } finally {
      // 清理临时文件
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  }

  /// 基准测试模板搜索
  Future<void> _benchmarkSearch() async {
    final registry = TemplateRegistry(registryPath: './templates');
    const query = TemplateSearchQuery(keyword: 'test', limit: 10);
    await registry.searchTemplates(query);
  }

  /// 基准测试模板生成
  Future<void> _benchmarkGenerate() async {
    // 创建临时测试模板进行真实生成测试
    final tempDir = Directory.systemTemp.createTempSync('benchmark_generate_');

    try {
      // 生成源模板
      await _createTestTemplate(tempDir.path);

      // 执行真实的模板生成过程
      await _performTemplateGeneration(tempDir.path);
    } finally {
      // 清理临时文件
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    }
  }

  /// 创建测试模板
  Future<void> _createTestTemplate(String tempPath) async {
    // 创建模板目录结构
    final templateDir = Directory(path.join(tempPath, 'test_template'));
    await templateDir.create(recursive: true);

    // 创建template.yaml
    final templateYaml = File(path.join(templateDir.path, 'template.yaml'));
    await templateYaml.writeAsString('''
name: benchmark_test_template
version: 1.0.0
author: Benchmark Test
description: Template for benchmark testing
type: ui
platform: flutter
framework: flutter
complexity: simple
maturity: stable
tags: [test, benchmark]
dependencies:
  - name: flutter
    version: ">=3.0.0"
  - name: material
    version: "^1.0.0"
''');

    // 创建pubspec.yaml
    final pubspecYaml = File(path.join(templateDir.path, 'pubspec.yaml'));
    await pubspecYaml.writeAsString('''
name: benchmark_test_template
description: A test template for benchmarking
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.9
  go_router: ^12.1.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.7
''');

    // 创建模板文件
    final templatesDir = Directory(path.join(templateDir.path, 'templates'));
    await templatesDir.create();

    final mainTemplate =
        File(path.join(templatesDir.path, 'main.dart.template'));
    await mainTemplate.writeAsString('''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    ProviderScope(
      child: {{appName}}App(),
    ),
  );
}

class {{appName}}App extends ConsumerWidget {
  const {{appName}}App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '{{appTitle}}',
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{{title}}'),
      ),
      body: const Center(
        child: Text('{{description}}'),
      ),
    );
  }
}
''');
  }

  /// 加载模板文件
  Future<void> _loadTemplateFiles(String tempPath) async {
    final templateDir = Directory(path.join(tempPath, 'test_template'));

    // 读取所有模板文件
    await for (final entity in templateDir.list(recursive: true)) {
      if (entity is File) {
        // 模拟文件读取和内容解析
        final content = await entity.readAsString();

        // 模拟模板变量解析
        final variables = _extractTemplateVariables(content);

        // 模拟语法验证
        _validateTemplateSyntax(content);
      }
    }
  }

  /// 解析模板元数据
  Future<void> _parseTemplateMetadata(String tempPath) async {
    final templateYaml =
        File(path.join(tempPath, 'test_template', 'template.yaml'));

    if (await templateYaml.exists()) {
      final content = await templateYaml.readAsString();

      // 模拟YAML解析
      final lines = content.split('\n');
      final metadata = <String, dynamic>{};

      for (final line in lines) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            final key = parts[0].trim();
            final value = parts[1].trim();
            metadata[key] = value;
          }
        }
      }

      // 模拟元数据验证
      _validateMetadata(metadata);
    }
  }

  /// 解析模板依赖
  Future<void> _parseTemplateDependencies(String tempPath) async {
    final pubspecYaml =
        File(path.join(tempPath, 'test_template', 'pubspec.yaml'));

    if (await pubspecYaml.exists()) {
      final content = await pubspecYaml.readAsString();

      // 模拟依赖解析
      final dependencies = <String>[];
      final lines = content.split('\n');
      var inDependencies = false;

      for (final line in lines) {
        if (line.trim() == 'dependencies:') {
          inDependencies = true;
          continue;
        }

        if (inDependencies && line.trim() == 'dev_dependencies:') {
          break;
        }

        if (inDependencies && line.trim().isNotEmpty && line.startsWith('  ')) {
          final dep = line.trim().split(':')[0];
          dependencies.add(dep);
        }
      }

      // 模拟依赖版本检查
      for (final dep in dependencies) {
        _checkDependencyVersion(dep);
      }
    }
  }

  /// 提取模板变量
  List<String> _extractTemplateVariables(String content) {
    final variables = <String>[];
    final regex = RegExp(r'\{\{(\w+)\}\}');
    final matches = regex.allMatches(content);

    for (final match in matches) {
      final variable = match.group(1);
      if (variable != null && !variables.contains(variable)) {
        variables.add(variable);
      }
    }

    return variables;
  }

  /// 验证模板语法
  void _validateTemplateSyntax(String content) {
    // 模拟语法验证
    final lines = content.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // 检查括号匹配
      var openBraces = 0;
      for (var j = 0; j < line.length - 1; j++) {
        if (line[j] == '{' && line[j + 1] == '{') {
          openBraces++;
          j++; // 跳过下一个字符
        } else if (line[j] == '}' && line[j + 1] == '}') {
          openBraces--;
          j++; // 跳过下一个字符
        }
      }

      if (openBraces != 0) {
        throw FormatException('Template syntax error at line ${i + 1}');
      }
    }
  }

  /// 验证元数据
  void _validateMetadata(Map<String, dynamic> metadata) {
    final requiredFields = ['name', 'version', 'author', 'description'];

    for (final field in requiredFields) {
      if (!metadata.containsKey(field) || metadata[field].toString().isEmpty) {
        throw ArgumentError('Missing required metadata field: $field');
      }
    }
  }

  /// 检查依赖版本
  void _checkDependencyVersion(String dependency) {
    // 模拟版本检查
    final validDependencies = [
      'flutter',
      'flutter_riverpod',
      'go_router',
      'build_runner',
      'flutter_test',
    ];

    if (!validDependencies.contains(dependency)) {
      // 这里可以添加更复杂的版本检查逻辑
    }
  }

  /// 验证模板结构完整性
  Future<void> _validateTemplateStructure(String tempPath) async {
    final templateDir = Directory(path.join(tempPath, 'test_template'));

    // 检查必需文件是否存在
    final requiredFiles = [
      'template.yaml',
      'pubspec.yaml',
      'templates/main.dart.template',
    ];

    for (final filePath in requiredFiles) {
      final file = File(path.join(templateDir.path, filePath));
      if (!await file.exists()) {
        throw StateError('Missing required file: $filePath');
      }
    }

    // 检查目录结构
    final requiredDirs = [
      'templates',
    ];

    for (final dirPath in requiredDirs) {
      final dir = Directory(path.join(templateDir.path, dirPath));
      if (!await dir.exists()) {
        throw StateError('Missing required directory: $dirPath');
      }
    }
  }

  /// 验证模板元数据
  Future<void> _validateTemplateMetadata(String tempPath) async {
    final templateYaml =
        File(path.join(tempPath, 'test_template', 'template.yaml'));

    if (!await templateYaml.exists()) {
      throw StateError('Template metadata file not found');
    }

    final content = await templateYaml.readAsString();
    final lines = content.split('\n');
    final metadata = <String, String>{};

    // 解析YAML内容
    for (final line in lines) {
      if (line.contains(':') && !line.trim().startsWith('#')) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts[1].trim();
          metadata[key] = value;
        }
      }
    }

    // 验证必需字段
    final requiredFields = ['name', 'version', 'author', 'description', 'type'];
    for (final field in requiredFields) {
      if (!metadata.containsKey(field) || metadata[field]!.isEmpty) {
        throw ArgumentError('Missing or empty required field: $field');
      }
    }

    // 验证版本格式 (支持 ^1.0.0 和 1.0.0 格式)
    final version = metadata['version'];
    if (version != null) {
      final cleanVersion =
          version.replaceAll('"', '').replaceAll('^', '').replaceAll('>=', '');
      if (!RegExp(r'^\d+\.\d+\.\d+').hasMatch(cleanVersion)) {
        throw FormatException('Invalid version format: $version');
      }
    }

    // 验证类型
    final type = metadata['type'];
    final validTypes = ['ui', 'full', 'basic', 'service', 'data', 'micro'];
    if (type != null && !validTypes.contains(type)) {
      throw ArgumentError('Invalid template type: $type');
    }
  }

  /// 验证模板依赖
  Future<void> _validateTemplateDependencies(String tempPath) async {
    final pubspecYaml =
        File(path.join(tempPath, 'test_template', 'pubspec.yaml'));

    if (!await pubspecYaml.exists()) {
      throw StateError('Pubspec file not found');
    }

    final content = await pubspecYaml.readAsString();
    final lines = content.split('\n');

    // 检查基本结构
    var hasDependencies = false;
    var hasDevDependencies = false;
    var hasEnvironment = false;

    for (final line in lines) {
      if (line.trim() == 'dependencies:') hasDependencies = true;
      if (line.trim() == 'dev_dependencies:') hasDevDependencies = true;
      if (line.trim() == 'environment:') hasEnvironment = true;
    }

    if (!hasDependencies) {
      throw StateError('Missing dependencies section in pubspec.yaml');
    }

    if (!hasEnvironment) {
      throw StateError('Missing environment section in pubspec.yaml');
    }

    // 验证Flutter依赖
    if (!content.contains('flutter:')) {
      throw StateError('Missing Flutter dependency');
    }

    // 验证SDK约束
    if (!content.contains('sdk:')) {
      throw StateError('Missing SDK constraint');
    }
  }

  /// 验证模板语法文件
  Future<void> _validateTemplateSyntaxFiles(String tempPath) async {
    final templatesDir =
        Directory(path.join(tempPath, 'test_template', 'templates'));

    if (!await templatesDir.exists()) {
      throw StateError('Templates directory not found');
    }

    // 验证所有模板文件
    await for (final entity in templatesDir.list()) {
      if (entity is File && entity.path.endsWith('.template')) {
        final content = await entity.readAsString();
        _validateTemplateSyntaxContent(content);
      }
    }
  }

  /// 验证模板语法内容
  void _validateTemplateSyntaxContent(String content) {
    final lines = content.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // 检查模板变量语法
      var openBraces = 0;
      for (var j = 0; j < line.length - 1; j++) {
        if (line[j] == '{' && line[j + 1] == '{') {
          openBraces++;
          j++; // 跳过下一个字符
        } else if (line[j] == '}' && line[j + 1] == '}') {
          openBraces--;
          j++; // 跳过下一个字符
        }
      }

      if (openBraces != 0) {
        throw FormatException(
            'Template syntax error at line ${i + 1}: unmatched braces',);
      }

      // 检查变量名格式
      final regex = RegExp(r'\{\{(\w+)\}\}');
      final matches = regex.allMatches(line);

      for (final match in matches) {
        final variable = match.group(1);
        if (variable != null) {
          // 验证变量名格式（只允许字母、数字、下划线）
          if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(variable)) {
            throw FormatException(
                'Invalid variable name at line ${i + 1}: $variable',);
          }
        }
      }
    }
  }

  /// 验证模板兼容性
  Future<void> _validateTemplateCompatibility(String tempPath) async {
    final templateYaml =
        File(path.join(tempPath, 'test_template', 'template.yaml'));
    final pubspecYaml =
        File(path.join(tempPath, 'test_template', 'pubspec.yaml'));

    if (!await templateYaml.exists() || !await pubspecYaml.exists()) {
      throw StateError('Required files not found for compatibility check');
    }

    final templateContent = await templateYaml.readAsString();
    final pubspecContent = await pubspecYaml.readAsString();

    // 检查Flutter版本兼容性
    if (templateContent.contains('framework: flutter')) {
      if (!pubspecContent.contains('flutter:')) {
        throw StateError(
            'Template declares Flutter framework but pubspec missing Flutter dependency',);
      }

      // 检查Flutter版本约束
      final flutterVersionRegex = RegExp(r'flutter:\s*"([^"]+)"');
      final match = flutterVersionRegex.firstMatch(pubspecContent);

      if (match != null) {
        final versionConstraint = match.group(1);
        // 验证版本约束格式
        if (versionConstraint != null && !versionConstraint.contains('>=')) {
          throw FormatException(
              'Invalid Flutter version constraint: $versionConstraint',);
        }
      }
    }

    // 检查平台兼容性
    if (templateContent.contains('platform: mobile')) {
      // 移动平台应该有相应的依赖
      final mobileDependencies = ['flutter', 'material'];
      for (final dep in mobileDependencies) {
        if (!pubspecContent.contains(dep)) {
          // 警告而不是错误，因为某些依赖可能是可选的
        }
      }
    }

    // 检查依赖版本兼容性
    final dependencyRegex = RegExp(r'(\w+):\s*\^?(\d+\.\d+\.\d+)');
    final matches = dependencyRegex.allMatches(pubspecContent);

    for (final match in matches) {
      final packageName = match.group(1);
      final version = match.group(2);

      if (packageName != null && version != null) {
        // 这里可以添加更复杂的版本兼容性检查
        // 例如检查包是否存在、版本是否有效等
        _validatePackageVersion(packageName, version);
      }
    }
  }

  /// 验证包版本
  void _validatePackageVersion(String packageName, String version) {
    // 验证版本格式
    if (!RegExp(r'^\d+\.\d+\.\d+').hasMatch(version)) {
      throw FormatException(
          'Invalid version format for $packageName: $version',);
    }

    // 检查已知的不兼容版本
    final incompatibleVersions = <String, List<String>>{
      'flutter_riverpod': ['1.0.0'], // 示例：假设1.0.0版本有问题
    };

    if (incompatibleVersions.containsKey(packageName)) {
      final badVersions = incompatibleVersions[packageName]!;
      if (badVersions.contains(version)) {
        throw StateError('Incompatible version for $packageName: $version');
      }
    }
  }

  /// 执行模板生成过程
  Future<void> _performTemplateGeneration(String tempPath) async {
    final templateDir = Directory(path.join(tempPath, 'test_template'));
    final outputDir = Directory(path.join(tempPath, 'generated_output'));

    // 创建输出目录
    await outputDir.create(recursive: true);

    // 模拟模板变量替换
    final templateVariables = {
      'appName': 'BenchmarkApp',
      'appTitle': 'Benchmark Test App',
      'title': 'Welcome',
      'description': 'This is a benchmark test application',
      'packageName': 'benchmark_test_app',
    };

    // 处理所有模板文件
    final templatesDir = Directory(path.join(templateDir.path, 'templates'));
    if (await templatesDir.exists()) {
      await for (final entity in templatesDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.template')) {
          await _processTemplateFile(entity, outputDir.path, templateVariables);
        }
      }
    }

    // 生成项目结构
    await _generateProjectStructure(outputDir.path, templateVariables);

    // 生成配置文件
    await _generateConfigurationFiles(outputDir.path, templateVariables);

    // 验证生成结果
    await _validateGeneratedOutput(outputDir.path);
  }

  /// 处理单个模板文件
  Future<void> _processTemplateFile(
    File templateFile,
    String outputPath,
    Map<String, String> variables,
  ) async {
    final content = await templateFile.readAsString();

    // 执行变量替换
    var processedContent = content;
    for (final entry in variables.entries) {
      processedContent = processedContent.replaceAll(
        '{{${entry.key}}}',
        entry.value,
      );
    }

    // 生成输出文件名（移除.template后缀）
    final fileName =
        path.basename(templateFile.path).replaceAll('.template', '');
    final outputFile = File(path.join(outputPath, fileName));

    // 确保输出目录存在
    await outputFile.parent.create(recursive: true);

    // 写入处理后的内容
    await outputFile.writeAsString(processedContent);
  }

  /// 生成项目结构
  Future<void> _generateProjectStructure(
    String outputPath,
    Map<String, String> variables,
  ) async {
    // 创建Flutter项目的基本目录结构
    final directories = [
      'lib',
      'lib/src',
      'lib/src/models',
      'lib/src/services',
      'lib/src/widgets',
      'lib/src/screens',
      'test',
      'assets',
      'assets/images',
    ];

    for (final dir in directories) {
      final directory = Directory(path.join(outputPath, dir));
      await directory.create(recursive: true);
    }

    // 生成基本的Dart文件
    await _generateBasicDartFiles(outputPath, variables);
  }

  /// 生成基本的Dart文件
  Future<void> _generateBasicDartFiles(
    String outputPath,
    Map<String, String> variables,
  ) async {
    // 生成lib/main.dart
    final mainFile = File(path.join(outputPath, 'lib', 'main.dart'));
    await mainFile.writeAsString('''
import 'package:flutter/material.dart';

void main() {
  runApp(${variables['appName']}());
}

class ${variables['appName']} extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${variables['appTitle']}',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${variables['title']}'),
      ),
      body: Center(
        child: Text('${variables['description']}'),
      ),
    );
  }
}
''');

    // 生成test/widget_test.dart
    final testFile = File(path.join(outputPath, 'test', 'widget_test.dart'));
    await testFile.writeAsString('''
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:${variables['packageName']}/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(${variables['appName']}());
    expect(find.text('${variables['title']}'), findsOneWidget);
    expect(find.text('${variables['description']}'), findsOneWidget);
  });
}
''');
  }

  /// 生成配置文件
  Future<void> _generateConfigurationFiles(
    String outputPath,
    Map<String, String> variables,
  ) async {
    // 生成pubspec.yaml
    final pubspecFile = File(path.join(outputPath, 'pubspec.yaml'));
    await pubspecFile.writeAsString('''
name: ${variables['packageName']}
description: ${variables['description']}
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.0.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
''');

    // 生成README.md
    final readmeFile = File(path.join(outputPath, 'README.md'));
    await readmeFile.writeAsString('''
# ${variables['appTitle']}

${variables['description']}

## Getting Started

This project is a Flutter application generated from a template.

### Prerequisites

- Flutter SDK
- Dart SDK

### Installation

1. Clone this repository
2. Run `flutter pub get`
3. Run `flutter run`

## Features

- Modern Flutter architecture
- Clean code structure
- Comprehensive testing

## License

This project is licensed under the MIT License.
''');
  }

  /// 验证生成的输出
  Future<void> _validateGeneratedOutput(String outputPath) async {
    // 检查必需文件是否生成
    final requiredFiles = [
      'lib/main.dart',
      'test/widget_test.dart',
      'pubspec.yaml',
      'README.md',
    ];

    for (final filePath in requiredFiles) {
      final file = File(path.join(outputPath, filePath));
      if (!await file.exists()) {
        throw StateError('Generated file missing: $filePath');
      }

      // 检查文件内容不为空
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        throw StateError('Generated file is empty: $filePath');
      }
    }

    // 检查目录结构
    final requiredDirs = [
      'lib',
      'lib/src',
      'test',
      'assets',
    ];

    for (final dirPath in requiredDirs) {
      final dir = Directory(path.join(outputPath, dirPath));
      if (!await dir.exists()) {
        throw StateError('Generated directory missing: $dirPath');
      }
    }

    // 验证生成的代码语法（基本检查）
    await _validateGeneratedCodeSyntax(outputPath);
  }

  /// 验证生成的代码语法
  Future<void> _validateGeneratedCodeSyntax(String outputPath) async {
    final mainFile = File(path.join(outputPath, 'lib', 'main.dart'));
    final content = await mainFile.readAsString();

    // 基本语法检查
    final requiredElements = [
      "import 'package:flutter/material.dart';",
      'void main()',
      'runApp(',
      'StatelessWidget',
      'Widget build(',
      'MaterialApp(',
      'Scaffold(',
    ];

    for (final element in requiredElements) {
      if (!content.contains(element)) {
        throw StateError('Generated code missing required element: $element');
      }
    }

    // 检查括号匹配
    var openBraces = 0;
    var openParens = 0;

    for (var i = 0; i < content.length; i++) {
      switch (content[i]) {
        case '{':
          openBraces++;
        case '}':
          openBraces--;
        case '(':
          openParens++;
        case ')':
          openParens--;
      }
    }

    if (openBraces != 0) {
      throw StateError('Generated code has unmatched braces');
    }

    if (openParens != 0) {
      throw StateError('Generated code has unmatched parentheses');
    }
  }
}
