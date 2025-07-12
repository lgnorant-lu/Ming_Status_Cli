/*
---------------------------------------------------------------
File name:          configuration_tester.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        配置测试器 (Configuration Tester)
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - 企业级模板配置管理系统;
---------------------------------------------------------------
*/

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:ming_status_cli/src/core/configuration_management/compatibility_matrix.dart';
import 'package:ming_status_cli/src/core/configuration_management/models/configuration_set.dart';
import 'package:ming_status_cli/src/core/configuration_management/models/test_result.dart';

/// 分层配置测试器
///
/// 执行分层测试策略，协调测试流程
class LayeredConfigurationTester {

  /// 创建分层配置测试器
  LayeredConfigurationTester({
    CompatibilityMatrix? compatibilityMatrix,
    int timeoutSeconds = 30,
    int concurrency = 4,
  })  : _compatibilityMatrix = compatibilityMatrix ?? CompatibilityMatrix(),
        _timeoutSeconds = timeoutSeconds,
        _concurrency = concurrency;
  /// 兼容性矩阵
  final CompatibilityMatrix _compatibilityMatrix;

  /// 测试超时时间（秒）
  final int _timeoutSeconds;

  /// 并发测试数量
  final int _concurrency;

  /// 测试结果缓存
  final Map<String, TestResult> _resultCache = {};

  /// 测试配置列表
  ///
  /// 并行测试多个配置并返回结果
  Future<List<TestResult>> testConfigurations(
    List<ConfigurationSet> configurations,
  ) async {
    final results = <TestResult>[];
    final futures = <Future<TestResult>>[];

    // 分批并行测试
    for (var i = 0; i < configurations.length; i += _concurrency) {
      final batch = configurations.skip(i).take(_concurrency);

      for (final config in batch) {
        futures.add(testConfiguration(config));
      }

      // 等待当前批次完成
      final batchResults = await Future.wait(futures);
      results.addAll(batchResults);
      futures.clear();
    }

    return results;
  }

  /// 测试单个配置
  ///
  /// 执行完整的分层测试流程
  Future<TestResult> testConfiguration(ConfigurationSet config) async {
    final testId = _generateTestId();
    final startTime = DateTime.now();

    // 检查缓存
    final cacheKey = config.generateHash();
    if (_resultCache.containsKey(cacheKey)) {
      final cachedResult = _resultCache[cacheKey]!;
      return cachedResult.copyWith(
        testId: testId,
        startTime: startTime,
      );
    }

    try {
      // 执行分层测试
      final layerResults = <TestLayer, bool>{};
      final logs = <String>[];
      final metrics = <String, dynamic>{};

      logs.add('开始配置测试: ${config.name}');

      // 测试核心层
      final coreResult = await _testLayer(
        TestLayer.core,
        config.getDependenciesByLayer(TestLayer.core),
        logs,
      );
      layerResults[TestLayer.core] = coreResult;

      // 测试必需层
      final essentialResult = await _testLayer(
        TestLayer.essential,
        config.getDependenciesByLayer(TestLayer.essential),
        logs,
      );
      layerResults[TestLayer.essential] = essentialResult;

      // 测试可选层
      final optionalResult = await _testLayer(
        TestLayer.optional,
        config.getDependenciesByLayer(TestLayer.optional),
        logs,
      );
      layerResults[TestLayer.optional] = optionalResult;

      // 测试开发层
      final devResult = await _testLayer(
        TestLayer.dev,
        config.getDependenciesByLayer(TestLayer.dev),
        logs,
      );
      layerResults[TestLayer.dev] = devResult;

      // 整体兼容性测试
      final compatibilityResult = _compatibilityMatrix.isCompatible(config);
      logs.add('兼容性检查: ${compatibilityResult ? '通过' : '失败'}');

      // 计算指标
      metrics['layerSuccessRate'] =
          layerResults.values.where((success) => success).length /
              layerResults.length;
      metrics['complexityScore'] = config.complexity;
      metrics['stabilityScore'] = config.calculateStabilityScore();
      metrics['freshnessScore'] = config.calculateFreshnessScore();

      // 判断整体成功
      final isSuccess = compatibilityResult &&
          layerResults[TestLayer.core] == true &&
          layerResults[TestLayer.essential] == true;

      final result = isSuccess
          ? TestResult.success(
              testId: testId,
              configurationSet: config,
              startTime: startTime,
              layerResults: layerResults,
              logs: logs,
              metrics: metrics,
            )
          : TestResult.failure(
              testId: testId,
              configurationSet: config,
              startTime: startTime,
              errorMessage:
                  _generateErrorMessage(layerResults, compatibilityResult),
              errorType: _determineErrorType(layerResults, compatibilityResult),
              layerResults: layerResults,
              logs: logs,
              metrics: metrics,
            );

      // 缓存结果
      _resultCache[cacheKey] = result;

      return result;
    } catch (e, stackTrace) {
      return TestResult.failure(
        testId: testId,
        configurationSet: config,
        startTime: startTime,
        errorMessage: 'Test execution failed: $e',
        errorType: TestErrorType.unknownError,
        stackTrace: stackTrace.toString(),
      );
    }
  }

  /// 按层级测试
  ///
  /// 测试特定层级的依赖
  Future<bool> testByLayer(TestLayer layer, ConfigurationSet config) async {
    final dependencies = config.getDependenciesByLayer(layer);
    final logs = <String>[];

    return _testLayer(layer, dependencies, logs);
  }

  /// 应该跳过的组合
  ///
  /// 检查是否应该跳过某个配置的测试
  Future<bool> shouldSkipCombination(ConfigurationSet config) async {
    // 检查是否有明显的兼容性问题
    final issues = _compatibilityMatrix.getCompatibilityIssues(config);
    if (issues.isNotEmpty) {
      return true;
    }

    // 检查复杂度是否过高
    if (config.complexity > 50) {
      return true;
    }

    // 检查是否有预发布版本过多
    final prereleaseCount =
        config.allDependencies.values.where((v) => v.isPrerelease).length;
    if (prereleaseCount > config.allDependencies.length * 0.5) {
      return true;
    }

    return false;
  }

  /// 获取缓存结果
  ///
  /// 从缓存中获取测试结果
  Future<TestResult?> getCachedResult(ConfigurationSet config) async {
    final cacheKey = config.generateHash();
    return _resultCache[cacheKey];
  }

  /// 清理缓存
  void clearCache() {
    _resultCache.clear();
  }

  /// 测试单个层级
  Future<bool> _testLayer(
    TestLayer layer,
    Map<String, dynamic> dependencies,
    List<String> logs,
  ) async {
    if (dependencies.isEmpty) {
      logs.add('${layer.name} 层: 无依赖，跳过');
      return true;
    }

    logs.add('${layer.name} 层: 开始测试 ${dependencies.length} 个依赖');

    try {
      // 模拟层级测试
      await _simulateLayerTest(layer, dependencies);

      logs.add('${layer.name} 层: 测试通过');
      return true;
    } catch (e) {
      logs.add('${layer.name} 层: 测试失败 - $e');
      return false;
    }
  }

  /// 模拟层级测试
  Future<void> _simulateLayerTest(
    TestLayer layer,
    Map<String, dynamic> dependencies,
  ) async {
    // 模拟测试延迟
    final random = Random();
    final delay = Duration(
      milliseconds: 100 + random.nextInt(500),
    );
    await Future<void>.delayed(delay);

    // 根据层级和依赖数量模拟成功率
    final successRate = _calculateLayerSuccessRate(layer, dependencies.length);
    final success = random.nextDouble() < successRate;

    if (!success) {
      throw Exception('Layer test failed for ${layer.name}');
    }
  }

  /// 计算层级成功率
  double _calculateLayerSuccessRate(TestLayer layer, int dependencyCount) {
    // 基础成功率
    double baseRate;
    switch (layer) {
      case TestLayer.core:
        baseRate = 0.95; // 核心层成功率最高
      case TestLayer.essential:
        baseRate = 0.90; // 必需层成功率较高
      case TestLayer.optional:
        baseRate = 0.85; // 可选层成功率中等
      case TestLayer.dev:
        baseRate = 0.80; // 开发层成功率较低
    }

    // 依赖数量影响成功率
    final complexityPenalty = (dependencyCount - 1) * 0.02;
    return (baseRate - complexityPenalty).clamp(0.5, 1.0);
  }

  /// 生成测试ID
  String _generateTestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000);
    return 'test_${timestamp}_$random';
  }

  /// 生成错误消息
  String _generateErrorMessage(
    Map<TestLayer, bool> layerResults,
    bool compatibilityResult,
  ) {
    final failedLayers = layerResults.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key.name)
        .toList();

    if (!compatibilityResult) {
      return 'Compatibility check failed';
    }

    if (failedLayers.isNotEmpty) {
      return 'Layer tests failed: ${failedLayers.join(', ')}';
    }

    return 'Unknown test failure';
  }

  /// 确定错误类型
  TestErrorType _determineErrorType(
    Map<TestLayer, bool> layerResults,
    bool compatibilityResult,
  ) {
    if (!compatibilityResult) {
      return TestErrorType.dependencyConflict;
    }

    final failedLayers = layerResults.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();

    if (failedLayers.contains(TestLayer.core)) {
      return TestErrorType.compilationError;
    }

    if (failedLayers.contains(TestLayer.essential)) {
      return TestErrorType.versionIncompatible;
    }

    return TestErrorType.runtimeError;
  }
}
