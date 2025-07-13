/*
---------------------------------------------------------------
File name:          configuration_manager.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        配置管理集成器 (Configuration Manager Integration)
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - 企业级模板配置管理系统;
---------------------------------------------------------------
*/

import 'dart:async';

import 'package:ming_status_cli/src/core/configuration_management/compatibility_matrix.dart';
import 'package:ming_status_cli/src/core/configuration_management/configuration_tester.dart';
import 'package:ming_status_cli/src/core/configuration_management/incremental_updater.dart';
import 'package:ming_status_cli/src/core/configuration_management/ml_models.dart';
import 'package:ming_status_cli/src/core/configuration_management/models/configuration_set.dart';
import 'package:ming_status_cli/src/core/configuration_management/models/test_result.dart';
import 'package:ming_status_cli/src/core/configuration_management/models/version_info.dart';
import 'package:ming_status_cli/src/core/configuration_management/parallel_tester.dart';
import 'package:ming_status_cli/src/core/configuration_management/smart_prefilter.dart';
import 'package:ming_status_cli/src/core/configuration_management/update_strategy.dart';
import 'package:ming_status_cli/src/core/configuration_management/version_resolver.dart';

/// 配置管理策略枚举
enum ConfigurationStrategy {
  /// 保守策略 - 优先稳定性
  conservative,

  /// 平衡策略 - 稳定性与新特性平衡
  balanced,

  /// 激进策略 - 优先新特性
  aggressive,

  /// 自动策略 - 基于ML自动选择
  automatic,
}

/// 配置管理选项
class ConfigurationOptions {
  const ConfigurationOptions({
    this.maxCombinations = 50,
    this.maxImpactThreshold = 0.7,
    this.includePrerelease = false,
    this.enableTesting = true,
    this.concurrency = 4,
    this.timeoutSeconds = 30,
    this.enableCache = true,
  });

  /// 最大测试组合数
  final int maxCombinations;

  /// 最大影响阈值
  final double maxImpactThreshold;

  /// 是否包含预发布版本
  final bool includePrerelease;

  /// 是否执行测试
  final bool enableTesting;

  /// 并发数
  final int concurrency;

  /// 超时时间（秒）
  final int timeoutSeconds;

  /// 是否启用缓存
  final bool enableCache;
}

/// 配置管理结果
class ConfigurationResult {
  const ConfigurationResult({
    required this.recommendedConfig,
    required this.candidateConfigs,
    required this.testResults,
    required this.executionTime, this.incrementalResult,
    this.metrics = const {},
  });

  /// 推荐的配置
  final ConfigurationSet recommendedConfig;

  /// 所有候选配置
  final List<ConfigurationSet> candidateConfigs;

  /// 测试结果
  final List<TestResult> testResults;

  /// 增量更新结果
  final IncrementalUpdateResult? incrementalResult;

  /// 执行时间
  final Duration executionTime;

  /// 性能指标
  final Map<String, dynamic> metrics;

  /// 获取成功率
  double get successRate {
    if (testResults.isEmpty) return 0;
    final successCount = testResults.where((r) => r.isSuccess).length;
    return successCount / testResults.length;
  }

  /// 获取最佳配置
  ConfigurationSet get bestConfig {
    if (testResults.isEmpty) return recommendedConfig;

    // 找到测试成功且优先级最高的配置
    final successfulResults = testResults.where((r) => r.isSuccess).toList();
    if (successfulResults.isEmpty) return recommendedConfig;

    successfulResults.sort(
      (a, b) =>
          b.configurationSet.priority.compareTo(a.configurationSet.priority),
    );

    return successfulResults.first.configurationSet;
  }
}

/// 配置管理器
///
/// 集成所有配置管理功能的主要接口
class ConfigurationManager {
  /// 创建配置管理器
  ConfigurationManager({
    ConfigurationOptions? options,
    IntelligentVersionResolver? versionResolver,
    CompatibilityMatrix? compatibilityMatrix,
    SmartPrefilter? prefilter,
    LayeredConfigurationTester? tester,
    ParallelTester? parallelTester,
    IncrementalUpdater? incrementalUpdater,
    ConfigurationSuccessPredictor? mlPredictor,
  })  : _options = options ?? const ConfigurationOptions(),
        _versionResolver = versionResolver ?? IntelligentVersionResolver(),
        _compatibilityMatrix = compatibilityMatrix ?? CompatibilityMatrix(),
        _prefilter = prefilter ?? SmartPrefilter(),
        _tester = tester ?? LayeredConfigurationTester(),
        _parallelTester = parallelTester ?? ParallelTester(),
        _incrementalUpdater = incrementalUpdater ?? IncrementalUpdater(),
        _mlPredictor = mlPredictor ?? ConfigurationSuccessPredictor();

  /// 版本解析器
  final IntelligentVersionResolver _versionResolver;

  /// 兼容性矩阵
  final CompatibilityMatrix _compatibilityMatrix;

  /// 智能预筛选器
  final SmartPrefilter _prefilter;

  /// 配置测试器
  final LayeredConfigurationTester _tester;

  /// 并行测试器
  final ParallelTester _parallelTester;

  /// 增量更新器
  final IncrementalUpdater _incrementalUpdater;

  /// ML预测器
  final ConfigurationSuccessPredictor _mlPredictor;

  /// 配置选项
  final ConfigurationOptions _options;

  /// 获取优化配置
  ///
  /// 主要的配置优化入口点
  Future<ConfigurationResult> getOptimizedConfig({
    ConfigurationSet? currentConfig,
    List<String>? packageNames,
    ConfigurationStrategy strategy = ConfigurationStrategy.balanced,
    Map<String, dynamic>? constraints,
  }) async {
    final startTime = DateTime.now();

    try {
      // 1. 获取最新版本信息
      final versions = await _versionResolver.getLatestVersions(
        packageNames: packageNames,
        includePrerelease: _options.includePrerelease,
      );

      // 2. 生成配置候选
      final candidates = await _generateCandidateConfigurations(
        versions,
        strategy,
        currentConfig,
      );

      // 如果没有候选配置且有当前配置，使用当前配置作为候选
      if (candidates.isEmpty && currentConfig != null) {
        candidates.add(currentConfig);
      }

      // 如果仍然没有候选配置，创建一个默认配置
      if (candidates.isEmpty) {
        final defaultConfig = ConfigurationSet(
          id: 'default_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Default Configuration',
          description: 'Default configuration when no candidates available',
          essentialDependencies: versions,
          createdAt: DateTime.now(),
        );
        candidates.add(defaultConfig);
      }

      // 3. 预筛选配置
      final filteredCandidates = _prefilter.prefilter(candidates);

      // 4. 兼容性检查
      final compatibleCandidates =
          filteredCandidates.where(_compatibilityMatrix.isCompatible).toList();

      // 如果没有兼容的候选配置，使用筛选后的候选配置
      if (compatibleCandidates.isEmpty && filteredCandidates.isNotEmpty) {
        compatibleCandidates.addAll(filteredCandidates);
      }

      // 5. 执行测试
      final testResults = _options.enableTesting
          ? await _parallelTester.testInParallel(compatibleCandidates)
          : <TestResult>[];

      // 6. 选择推荐配置
      final recommendedConfig = _selectRecommendedConfig(
        compatibleCandidates,
        testResults,
        strategy,
      );

      // 7. 增量更新分析
      IncrementalUpdateResult? incrementalResult;
      if (currentConfig != null) {
        incrementalResult = await _incrementalUpdater.performIncrementalUpdate(
          currentConfig: currentConfig,
          availableVersions: versions,
          maxImpactThreshold: _options.maxImpactThreshold,
          testChanges: _options.enableTesting,
        );
      }

      final executionTime = DateTime.now().difference(startTime);

      // 8. 更新ML模型
      for (final result in testResults) {
        _prefilter.addHistoricalResult(result);
      }

      return ConfigurationResult(
        recommendedConfig: recommendedConfig,
        candidateConfigs: compatibleCandidates,
        testResults: testResults,
        incrementalResult: incrementalResult,
        executionTime: executionTime,
        metrics: {
          'totalCandidates': candidates.length,
          'filteredCandidates': filteredCandidates.length,
          'compatibleCandidates': compatibleCandidates.length,
          'successfulTests': testResults.where((r) => r.isSuccess).length,
          'executionTimeMs': executionTime.inMilliseconds,
        },
      );
    } finally {
      // 清理资源
      _versionResolver.dispose();
    }
  }

  /// 检查配置兼容性
  Future<bool> checkConfigurationCompatibility(ConfigurationSet config) async {
    return _compatibilityMatrix.isCompatible(config);
  }

  /// 获取兼容性问题
  Future<List<String>> getCompatibilityIssues(ConfigurationSet config) async {
    return _compatibilityMatrix.getCompatibilityIssues(config);
  }

  /// 测试配置
  Future<TestResult> testConfiguration(ConfigurationSet config) async {
    return _tester.testConfiguration(config);
  }

  /// 预测配置成功率
  Future<double> predictConfigurationSuccess(ConfigurationSet config) async {
    return _mlPredictor.predictSuccessRate(config);
  }

  /// 获取更新建议
  Future<List<DependencyChange>> getUpdateSuggestions({
    required ConfigurationSet currentConfig,
    double? maxImpactThreshold,
  }) async {
    final versions = await _versionResolver.getLatestVersions(
      packageNames: currentConfig.allDependencies.keys.toList(),
    );

    return _incrementalUpdater.getUpdateSuggestions(
      currentConfig: currentConfig,
      availableVersions: versions,
      maxImpactThreshold: maxImpactThreshold ?? _options.maxImpactThreshold,
    );
  }

  /// 生成候选配置
  Future<List<ConfigurationSet>> _generateCandidateConfigurations(
    Map<String, VersionInfo> versions,
    ConfigurationStrategy strategy,
    ConfigurationSet? currentConfig,
  ) async {
    final candidates = <ConfigurationSet>[];

    if (currentConfig != null) {
      // 基于当前配置生成优化候选
      final optimizedDependencies = <String, VersionInfo>{};

      // 对于当前配置中的每个依赖，尝试找到更好的版本
      for (final entry in currentConfig.allDependencies.entries) {
        final packageName = entry.key;
        final currentVersion = entry.value;

        // 如果有最新版本信息，根据策略选择版本
        if (versions.containsKey(packageName)) {
          final latestVersion = versions[packageName]!;
          optimizedDependencies[packageName] = _selectVersionByStrategy(
            currentVersion,
            latestVersion,
            strategy,
          );
        } else {
          // 保留当前版本
          optimizedDependencies[packageName] = currentVersion;
        }
      }

      // 创建优化后的配置
      final optimizedConfig = ConfigurationSet(
        id: '${strategy.name}_${DateTime.now().millisecondsSinceEpoch}',
        name: '${_getStrategyDisplayName(strategy)} Configuration',
        description:
            'Optimized configuration based on ${strategy.name} strategy',
        essentialDependencies: Map.fromEntries(
          optimizedDependencies.entries.where(
              (e) => currentConfig.essentialDependencies.containsKey(e.key),),
        ),
        devDependencies: Map.fromEntries(
          optimizedDependencies.entries
              .where((e) => currentConfig.devDependencies.containsKey(e.key)),
        ),
        createdAt: DateTime.now(),
        priority: _getStrategyPriority(strategy),
      );

      candidates.add(optimizedConfig);
    } else {
      // 如果没有当前配置，使用原有逻辑
      final testStrategy = _mapToTestStrategy(strategy);
      candidates.addAll(await _versionResolver.generateTestConfigurations(
        versions: versions,
        strategy: testStrategy,
        maxCombinations: _options.maxCombinations,
      ),);
    }

    return candidates;
  }

  /// 根据策略选择版本
  VersionInfo _selectVersionByStrategy(
    VersionInfo currentVersion,
    VersionInfo latestVersion,
    ConfigurationStrategy strategy,
  ) {
    switch (strategy) {
      case ConfigurationStrategy.conservative:
        // 保守策略：只有在新版本明显更稳定时才升级
        if (latestVersion.version.major == currentVersion.version.major &&
            latestVersion.calculateStabilityScore() >
                currentVersion.calculateStabilityScore()) {
          return latestVersion;
        }
        return currentVersion;

      case ConfigurationStrategy.balanced:
        // 平衡策略：升级到同一主版本的最新版本
        if (latestVersion.version.major == currentVersion.version.major) {
          return latestVersion;
        }
        return currentVersion;

      case ConfigurationStrategy.aggressive:
        // 激进策略：总是使用最新版本
        return latestVersion;

      case ConfigurationStrategy.automatic:
        // 自动策略：基于ML预测选择
        final currentScore = currentVersion.calculateStabilityScore();
        final latestScore = latestVersion.calculateStabilityScore();
        return latestScore > currentScore ? latestVersion : currentVersion;
    }
  }

  /// 获取策略显示名称
  String _getStrategyDisplayName(ConfigurationStrategy strategy) {
    switch (strategy) {
      case ConfigurationStrategy.conservative:
        return 'Conservative';
      case ConfigurationStrategy.balanced:
        return 'Balanced';
      case ConfigurationStrategy.aggressive:
        return 'Aggressive';
      case ConfigurationStrategy.automatic:
        return 'Automatic';
    }
  }

  /// 获取策略优先级
  double _getStrategyPriority(ConfigurationStrategy strategy) {
    switch (strategy) {
      case ConfigurationStrategy.conservative:
        return 0.80;
      case ConfigurationStrategy.balanced:
        return 0.70;
      case ConfigurationStrategy.aggressive:
        return 0.60;
      case ConfigurationStrategy.automatic:
        return 0.70;
    }
  }

  /// 选择推荐配置
  ConfigurationSet _selectRecommendedConfig(
    List<ConfigurationSet> candidates,
    List<TestResult> testResults,
    ConfigurationStrategy strategy,
  ) {
    if (candidates.isEmpty) {
      throw StateError('No candidate configurations available');
    }

    // 如果没有测试结果，选择优先级最高的
    if (testResults.isEmpty) {
      candidates.sort((a, b) => b.priority.compareTo(a.priority));
      return candidates.first;
    }

    // 根据策略选择配置
    switch (strategy) {
      case ConfigurationStrategy.conservative:
        return _selectConservativeConfig(candidates, testResults);
      case ConfigurationStrategy.balanced:
        return _selectBalancedConfig(candidates, testResults);
      case ConfigurationStrategy.aggressive:
        return _selectAggressiveConfig(candidates, testResults);
      case ConfigurationStrategy.automatic:
        return _selectAutomaticConfig(candidates, testResults);
    }
  }

  /// 选择保守配置
  ConfigurationSet _selectConservativeConfig(
    List<ConfigurationSet> candidates,
    List<TestResult> testResults,
  ) {
    // 优先选择稳定性最高的成功配置
    final successfulResults = testResults.where((r) => r.isSuccess).toList();
    if (successfulResults.isEmpty) {
      return candidates.first;
    }

    successfulResults.sort(
      (a, b) => b.configurationSet
          .calculateStabilityScore()
          .compareTo(a.configurationSet.calculateStabilityScore()),
    );

    return successfulResults.first.configurationSet;
  }

  /// 选择平衡配置
  ConfigurationSet _selectBalancedConfig(
    List<ConfigurationSet> candidates,
    List<TestResult> testResults,
  ) {
    // 平衡稳定性和新鲜度
    final successfulResults = testResults.where((r) => r.isSuccess).toList();
    if (successfulResults.isEmpty) {
      return candidates.first;
    }

    successfulResults.sort((a, b) {
      final scoreA = (a.configurationSet.calculateStabilityScore() +
              a.configurationSet.calculateFreshnessScore()) /
          2;
      final scoreB = (b.configurationSet.calculateStabilityScore() +
              b.configurationSet.calculateFreshnessScore()) /
          2;
      return scoreB.compareTo(scoreA);
    });

    return successfulResults.first.configurationSet;
  }

  /// 选择激进配置
  ConfigurationSet _selectAggressiveConfig(
    List<ConfigurationSet> candidates,
    List<TestResult> testResults,
  ) {
    // 优先选择新鲜度最高的成功配置
    final successfulResults = testResults.where((r) => r.isSuccess).toList();
    if (successfulResults.isEmpty) {
      return candidates.first;
    }

    successfulResults.sort(
      (a, b) => b.configurationSet
          .calculateFreshnessScore()
          .compareTo(a.configurationSet.calculateFreshnessScore()),
    );

    return successfulResults.first.configurationSet;
  }

  /// 选择自动配置
  ConfigurationSet _selectAutomaticConfig(
    List<ConfigurationSet> candidates,
    List<TestResult> testResults,
  ) {
    // 使用ML预测选择最佳配置
    final successfulResults = testResults.where((r) => r.isSuccess).toList();
    if (successfulResults.isEmpty) {
      return candidates.first;
    }

    // 计算每个配置的ML评分
    final scoredConfigs = successfulResults.map((result) {
      final score = _mlPredictor.predictSuccessRate(result.configurationSet);
      return MapEntry(result.configurationSet, score);
    }).toList();

    scoredConfigs.sort((a, b) => b.value.compareTo(a.value));

    return scoredConfigs.first.key;
  }

  /// 映射策略枚举
  TestStrategy _mapToTestStrategy(ConfigurationStrategy strategy) {
    switch (strategy) {
      case ConfigurationStrategy.conservative:
        return TestStrategy.conservative;
      case ConfigurationStrategy.balanced:
      case ConfigurationStrategy.automatic:
        return TestStrategy.balanced;
      case ConfigurationStrategy.aggressive:
        return TestStrategy.aggressive;
    }
  }

  /// 清理资源
  void dispose() {
    _versionResolver.dispose();
    _parallelTester.dispose();
    _tester.clearCache();
  }
}
