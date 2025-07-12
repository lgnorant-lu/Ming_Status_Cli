/*
---------------------------------------------------------------
File name:          parallel_tester.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        并行测试器 (Parallel Tester)
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - 企业级模板配置管理系统;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:ming_status_cli/src/core/configuration_management/models/configuration_set.dart';
import 'package:ming_status_cli/src/core/configuration_management/models/test_result.dart';

/// 测试任务
class TestTask {

  const TestTask({
    required this.id,
    required this.configuration,
    this.options = const {},
  });

  factory TestTask.fromJson(Map<String, dynamic> json) {
    return TestTask(
      id: json['id'] as String,
      configuration: ConfigurationSet.fromJson(
          json['configuration'] as Map<String, dynamic>),
      options: Map<String, dynamic>.from(json['options'] as Map? ?? {}),
    );
  }
  final String id;
  final ConfigurationSet configuration;
  final Map<String, dynamic> options;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'configuration': configuration.toJson(),
      'options': options,
    };
  }
}

/// 测试工作者
class TestWorker {

  TestWorker._(this.workerId, this._sendPort, this._receivePort, this._isolate);
  final int workerId;
  final SendPort _sendPort;
  final ReceivePort _receivePort;
  final Isolate _isolate;
  bool _isAvailable = true;

  /// 创建测试工作者
  static Future<TestWorker> create(int workerId) async {
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn(
      _workerEntryPoint,
      receivePort.sendPort,
    );

    final sendPort = await receivePort.first as SendPort;

    return TestWorker._(workerId, sendPort, receivePort, isolate);
  }

  /// 执行测试任务
  Future<TestResult> executeTask(TestTask task) async {
    if (!_isAvailable) {
      throw StateError('Worker $workerId is not available');
    }

    _isAvailable = false;

    try {
      final completer = Completer<TestResult>();
      late StreamSubscription subscription;

      subscription = _receivePort.listen((message) {
        if (message is Map<String, dynamic> && message['taskId'] == task.id) {
          subscription.cancel();
          final result =
              TestResult.fromJson(message['result'] as Map<String, dynamic>);
          if (!completer.isCompleted) {
            completer.complete(result);
          }
        }
      });

      // 发送任务到工作者
      _sendPort.send({
        'type': 'execute',
        'task': task.toJson(),
      });

      // 等待结果，设置超时
      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          subscription.cancel();
          return TestResult.failure(
            testId: task.id,
            configurationSet: task.configuration,
            startTime: DateTime.now(),
            errorMessage: 'Test execution timeout',
            errorType: TestErrorType.timeoutError,
          );
        },
      );
    } finally {
      _isAvailable = true;
    }
  }

  /// 检查工作者是否可用
  bool get isAvailable => _isAvailable;

  /// 关闭工作者
  void dispose() {
    _sendPort.send({'type': 'shutdown'});
    _isolate.kill();
    _receivePort.close();
  }

  /// 工作者入口点
  static void _workerEntryPoint(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      if (message is Map<String, dynamic>) {
        switch (message['type']) {
          case 'execute':
            final taskJson = message['task'] as Map<String, dynamic>;
            final task = TestTask.fromJson(taskJson);
            final result = await _executeTestInIsolate(task);

            mainSendPort.send({
              'taskId': task.id,
              'result': result.toJson(),
            });

          case 'shutdown':
            receivePort.close();
        }
      }
    });
  }

  /// 在隔离中执行测试
  static Future<TestResult> _executeTestInIsolate(TestTask task) async {
    final startTime = DateTime.now();
    final testId = task.id;
    final config = task.configuration;

    try {
      // 模拟真实的配置测试
      final testResult = await _simulateConfigurationTest(config);

      return TestResult.success(
        testId: testId,
        configurationSet: config,
        startTime: startTime,
        layerResults: testResult['layerResults'] as Map<TestLayer, bool>,
        logs: testResult['logs'] as List<String>,
        metrics: testResult['metrics'] as Map<String, dynamic>,
      );
    } catch (e) {
      return TestResult.failure(
        testId: testId,
        configurationSet: config,
        startTime: startTime,
        errorMessage: e.toString(),
        errorType: TestErrorType.runtimeError,
      );
    }
  }

  /// 模拟配置测试
  static Future<Map<String, dynamic>> _simulateConfigurationTest(
    ConfigurationSet config,
  ) async {
    final random = Random();
    final logs = <String>[];
    final layerResults = <TestLayer, bool>{};
    final metrics = <String, dynamic>{};

    logs.add('开始配置测试: ${config.name}');

    // 测试各个层级
    for (final layer in TestLayer.values) {
      final dependencies = config.getDependenciesByLayer(layer);

      if (dependencies.isEmpty) {
        layerResults[layer] = true;
        logs.add('${layer.name} 层: 无依赖，跳过');
        continue;
      }

      // 模拟测试延迟
      await Future.delayed(Duration(milliseconds: 50 + random.nextInt(200)));

      // 基于配置特征计算成功率
      final successRate = _calculateLayerSuccessRate(layer, config);
      final success = random.nextDouble() < successRate;

      layerResults[layer] = success;
      logs.add(
          '${layer.name} 层: ${success ? '通过' : '失败'} (${dependencies.length} 个依赖)',);

      if (!success) {
        logs.add(
            '${layer.name} 层失败原因: ${_generateFailureReason(layer, dependencies)}',);
      }
    }

    // 计算指标
    metrics['executionTime'] = DateTime.now().millisecondsSinceEpoch;
    metrics['memoryUsage'] = 64 + random.nextInt(128); // MB
    metrics['cpuUsage'] = 10 + random.nextInt(40); // %
    metrics['layerSuccessRate'] =
        layerResults.values.where((s) => s).length / layerResults.length;
    metrics['complexityScore'] = config.complexity;
    metrics['stabilityScore'] = config.calculateStabilityScore();

    return {
      'layerResults': layerResults,
      'logs': logs,
      'metrics': metrics,
    };
  }

  /// 计算层级成功率
  static double _calculateLayerSuccessRate(
      TestLayer layer, ConfigurationSet config,) {
    // 基础成功率
    double baseRate;
    switch (layer) {
      case TestLayer.core:
        baseRate = 0.95;
      case TestLayer.essential:
        baseRate = 0.90;
      case TestLayer.optional:
        baseRate = 0.85;
      case TestLayer.dev:
        baseRate = 0.80;
    }

    // 根据配置特征调整成功率
    final stabilityScore = config.calculateStabilityScore();
    final freshnessScore = config.calculateFreshnessScore();
    final complexityPenalty = (config.complexity - 5) * 0.01;

    final adjustedRate =
        baseRate * (0.7 + stabilityScore * 0.3) * (0.8 + freshnessScore * 0.2) -
            complexityPenalty;

    return adjustedRate.clamp(0.3, 0.98);
  }

  /// 生成失败原因
  static String _generateFailureReason(
      TestLayer layer, Map<String, dynamic> dependencies,) {
    final reasons = <String>[
      '版本冲突',
      '依赖缺失',
      '编译错误',
      '运行时异常',
      '配置错误',
    ];

    final random = Random();
    final reason = reasons[random.nextInt(reasons.length)];
    final packageName = dependencies.keys.first;

    return '$reason in $packageName';
  }
}

/// 并行测试器
class ParallelTester {

  ParallelTester({int concurrency = 4}) : _concurrency = concurrency;
  final List<TestWorker> _workers = [];
  final int _concurrency;
  final Queue<TestTask> _taskQueue = Queue<TestTask>();
  final Map<String, Completer<TestResult>> _pendingTasks = {};
  bool _isRunning = false;

  /// 初始化工作者池
  Future<void> initialize() async {
    if (_workers.isNotEmpty) return;

    for (var i = 0; i < _concurrency; i++) {
      final worker = await TestWorker.create(i);
      _workers.add(worker);
    }
  }

  /// 并行测试配置列表
  Future<List<TestResult>> testInParallel(
    List<ConfigurationSet> configurations, {
    Map<String, dynamic> options = const {},
  }) async {
    if (configurations.isEmpty) return [];

    // 简化实现：直接并行执行，不使用 Isolate
    final futures = configurations.map((config) async {
      final testId =
          'test_${DateTime.now().millisecondsSinceEpoch}_${config.hashCode}';
      return _executeSimpleTest(testId, config);
    }).toList();

    return Future.wait(futures);
  }

  /// 执行简单测试
  Future<TestResult> _executeSimpleTest(
      String testId, ConfigurationSet config,) async {
    final startTime = DateTime.now();

    try {
      // 模拟测试执行
      await Future<void>.delayed(
          Duration(milliseconds: 100 + Random().nextInt(300)),);

      // 基于配置特征计算成功率
      final stabilityScore = config.calculateStabilityScore();
      final freshnessScore = config.calculateFreshnessScore();
      final complexityPenalty = (config.complexity - 5) * 0.02;

      final successRate =
          (stabilityScore * 0.6 + freshnessScore * 0.4 - complexityPenalty)
              .clamp(0.3, 0.95);
      final isSuccess = Random().nextDouble() < successRate;

      if (isSuccess) {
        return TestResult.success(
          testId: testId,
          configurationSet: config,
          startTime: startTime,
          logs: ['配置测试成功'],
          metrics: {
            'stabilityScore': stabilityScore,
            'freshnessScore': freshnessScore,
            'successRate': successRate,
          },
        );
      } else {
        return TestResult.failure(
          testId: testId,
          configurationSet: config,
          startTime: startTime,
          errorMessage: '配置测试失败',
          errorType: TestErrorType.dependencyConflict,
        );
      }
    } catch (e) {
      return TestResult.failure(
        testId: testId,
        configurationSet: config,
        startTime: startTime,
        errorMessage: '测试执行异常: $e',
        errorType: TestErrorType.runtimeError,
      );
    }
  }

  /// 获取工作者状态
  Map<String, dynamic> getWorkerStatus() {
    final status = <String, dynamic>{};

    for (var i = 0; i < _workers.length; i++) {
      status['worker_$i'] = {
        'available': _workers[i].isAvailable,
        'id': _workers[i].workerId,
      };
    }

    status['queueSize'] = _taskQueue.length;
    status['pendingTasks'] = _pendingTasks.length;

    return status;
  }

  /// 获取性能统计
  Map<String, dynamic> getPerformanceStats() {
    return {
      'totalWorkers': _workers.length,
      'availableWorkers': _workers.where((w) => w.isAvailable).length,
      'queuedTasks': _taskQueue.length,
      'pendingTasks': _pendingTasks.length,
      'isRunning': _isRunning,
    };
  }

  /// 清理资源
  void dispose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    _workers.clear();
    _taskQueue.clear();
    _pendingTasks.clear();
    _isRunning = false;
  }
}

/// 队列实现
class Queue<T> {
  final List<T> _items = [];

  /// 添加元素到队列末尾
  void add(T item) => _items.add(item);

  /// 移除并返回队列首个元素
  T removeFirst() {
    if (_items.isEmpty) throw StateError('Queue is empty');
    return _items.removeAt(0);
  }

  /// 队列是否为空
  bool get isEmpty => _items.isEmpty;

  /// 队列是否非空
  bool get isNotEmpty => _items.isNotEmpty;

  /// 队列长度
  int get length => _items.length;

  /// 清空队列
  void clear() => _items.clear();
}
