/*
---------------------------------------------------------------
File name:          smart_prefilter.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        智能预筛选器 (Smart Prefilter)
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - 企业级模板配置管理系统;
---------------------------------------------------------------
*/

import 'dart:math';

import 'package:ming_status_cli/src/core/configuration_management/models/configuration_set.dart';
import 'package:ming_status_cli/src/core/configuration_management/models/test_result.dart';
import 'package:ming_status_cli/src/core/configuration_management/models/version_info.dart';
import 'package:ming_status_cli/src/core/configuration_management/ml_models.dart';

/// 预筛选策略枚举
enum PrefilterStrategy {
  /// 基于历史数据
  historical,

  /// 基于启发式算法
  heuristic,

  /// 基于机器学习
  machineLearning,

  /// 混合策略
  hybrid,
}

/// 智能预筛选器
///
/// 减少测试组合数量，提升测试效率
class SmartPrefilter {
  /// 创建智能预筛选器
  SmartPrefilter({
    int maxCombinations = 50,
    PrefilterStrategy strategy = PrefilterStrategy.hybrid,
  })  : _maxCombinations = maxCombinations,
        _strategy = strategy {
    _initializePackagePopularity();
    _initializeSuccessPatterns();
  }

  /// 历史测试结果
  final Map<String, TestResult> _historicalResults = {};

  /// 包流行度数据
  final Map<String, double> _packagePopularity = {};

  /// 成功配置模式
  final List<ConfigurationPattern> _successPatterns = [];

  /// 最大测试组合数
  final int _maxCombinations;

  /// 预筛选策略
  final PrefilterStrategy _strategy;

  /// ML预测器
  ConfigurationSuccessPredictor? _mlPredictor;

  /// 预筛选配置组合
  ///
  /// 从大量配置组合中筛选出最有希望的组合
  List<ConfigurationSet> prefilter(List<ConfigurationSet> allCombinations) {
    if (allCombinations.length <= _maxCombinations) {
      return allCombinations;
    }

    // 计算每个配置的优先级
    final prioritizedConfigs = allCombinations.map((config) {
      final priority = calculatePriority(config);
      return _PrioritizedConfig(config, priority);
    }).toList();

    // 按优先级排序
    prioritizedConfigs.sort((a, b) => b.priority.compareTo(a.priority));

    // 应用多样性筛选
    final diverseConfigs = _applyDiversityFilter(prioritizedConfigs);

    // 返回前N个配置
    return diverseConfigs
        .take(_maxCombinations)
        .map((pc) => pc.config)
        .toList();
  }

  /// 计算配置优先级
  ///
  /// 基于多个因素计算配置的测试优先级
  double calculatePriority(ConfigurationSet config) {
    var priority = 0.0;

    switch (_strategy) {
      case PrefilterStrategy.historical:
        priority = _calculateHistoricalPriority(config);
      case PrefilterStrategy.heuristic:
        priority = _calculateHeuristicPriority(config);
      case PrefilterStrategy.machineLearning:
        priority = _calculateMLPriority(config);
      case PrefilterStrategy.hybrid:
        priority = _calculateHybridPriority(config);
    }

    return priority.clamp(0.0, 1.0);
  }

  /// 添加历史测试结果
  ///
  /// 用于改进预筛选算法
  void addHistoricalResult(TestResult result) {
    final configHash = result.configurationSet.generateHash();
    _historicalResults[configHash] = result;

    // 更新成功模式
    if (result.isSuccess) {
      _updateSuccessPatterns(result.configurationSet);
    }

    // 重新训练ML模型
    _retrainMLPredictor();
  }

  /// 初始化ML预测器
  void _initializeMLPredictor() {
    _mlPredictor = ConfigurationSuccessPredictor();

    // 如果有历史数据，立即训练
    if (_historicalResults.isNotEmpty) {
      _retrainMLPredictor();
    }
  }

  /// 重新训练ML预测器
  void _retrainMLPredictor() {
    if (_mlPredictor == null || _historicalResults.isEmpty) return;

    final historicalResults = _historicalResults.values.toList();
    _mlPredictor!.train(historicalResults);
  }

  /// 获取历史成功率
  ///
  /// 基于历史数据计算配置的成功率
  double getHistoricalSuccessRate(ConfigurationSet config) {
    final configHash = config.generateHash();
    final result = _historicalResults[configHash];

    if (result != null) {
      return result.isSuccess ? 1.0 : 0.0;
    }

    // 基于相似配置的成功率
    return _calculateSimilarConfigSuccessRate(config);
  }

  /// 计算依赖稳定性
  ///
  /// 评估配置中依赖的整体稳定性
  double calculateDependencyStability(ConfigurationSet config) {
    if (config.allDependencies.isEmpty) return 1;

    final stabilityScores = config.allDependencies.values
        .map((version) => version.calculateStabilityScore());

    return stabilityScores.reduce((a, b) => a + b) / stabilityScores.length;
  }

  /// 计算版本新鲜度
  ///
  /// 评估配置中版本的新鲜度
  double calculateVersionFreshness(ConfigurationSet config) {
    if (config.allDependencies.isEmpty) return 1;

    final freshnessScores = config.allDependencies.values
        .map((version) => version.calculateFreshness());

    return freshnessScores.reduce((a, b) => a + b) / freshnessScores.length;
  }

  /// 基于历史数据计算优先级
  double _calculateHistoricalPriority(ConfigurationSet config) {
    final historicalSuccess = getHistoricalSuccessRate(config);
    final patternMatch = _calculatePatternMatch(config);

    return (historicalSuccess * 0.7) + (patternMatch * 0.3);
  }

  /// 基于启发式算法计算优先级
  double _calculateHeuristicPriority(ConfigurationSet config) {
    final stabilityScore = calculateDependencyStability(config);
    final popularityScore = _calculatePopularityScore(config);
    final complexityScore = _calculateComplexityScore(config);
    final freshnessScore = calculateVersionFreshness(config);

    return (stabilityScore * 0.3) +
        (popularityScore * 0.25) +
        (complexityScore * 0.2) +
        (freshnessScore * 0.25);
  }

  /// 基于机器学习计算优先级
  double _calculateMLPriority(ConfigurationSet config) {
    if (_mlPredictor == null) {
      _initializeMLPredictor();
    }

    return _mlPredictor?.predictSuccessRate(config) ?? 0.5;
  }

  /// 混合策略计算优先级
  double _calculateHybridPriority(ConfigurationSet config) {
    final historicalPriority = _calculateHistoricalPriority(config);
    final heuristicPriority = _calculateHeuristicPriority(config);
    final mlPriority = _calculateMLPriority(config);

    // 根据历史数据的可用性调整权重
    final historicalWeight = _historicalResults.isNotEmpty ? 0.4 : 0.0;
    const heuristicWeight = 0.4;
    const mlWeight = 0.2;

    final totalWeight = historicalWeight + heuristicWeight + mlWeight;

    return (historicalPriority * historicalWeight +
            heuristicPriority * heuristicWeight +
            mlPriority * mlWeight) /
        totalWeight;
  }

  /// 计算流行度评分
  double _calculatePopularityScore(ConfigurationSet config) {
    if (config.allDependencies.isEmpty) return 0;

    final popularityScores = config.allDependencies.keys
        .map((packageName) => _packagePopularity[packageName] ?? 0.0);

    return popularityScores.reduce((a, b) => a + b) / popularityScores.length;
  }

  /// 计算复杂度评分
  double _calculateComplexityScore(ConfigurationSet config) {
    final complexity = config.complexity;

    // 适中的复杂度得分最高
    if (complexity >= 8 && complexity <= 15) return 1;
    if (complexity < 5) return complexity / 5.0;
    if (complexity > 25) {
      return 1.0 - ((complexity - 25) / 15.0).clamp(0.0, 1.0);
    }

    return 0.8;
  }

  /// 计算相似配置成功率
  double _calculateSimilarConfigSuccessRate(ConfigurationSet config) {
    if (_historicalResults.isEmpty) return 0.5;

    var totalSimilarity = 0.0;
    var weightedSuccessRate = 0.0;

    for (final result in _historicalResults.values) {
      final similarity =
          _calculateConfigSimilarity(config, result.configurationSet);
      if (similarity > 0.3) {
        // 只考虑相似度较高的配置
        totalSimilarity += similarity;
        weightedSuccessRate += similarity * (result.isSuccess ? 1.0 : 0.0);
      }
    }

    return totalSimilarity > 0 ? weightedSuccessRate / totalSimilarity : 0.5;
  }

  /// 计算配置相似度
  double _calculateConfigSimilarity(
    ConfigurationSet config1,
    ConfigurationSet config2,
  ) {
    final deps1 = config1.allDependencies.keys.toSet();
    final deps2 = config2.allDependencies.keys.toSet();

    final intersection = deps1.intersection(deps2);
    final union = deps1.union(deps2);

    if (union.isEmpty) return 0;

    return intersection.length / union.length;
  }

  /// 计算模式匹配度
  double _calculatePatternMatch(ConfigurationSet config) {
    if (_successPatterns.isEmpty) return 0.5;

    var maxMatch = 0.0;

    for (final pattern in _successPatterns) {
      final match = pattern.calculateMatch(config);
      if (match > maxMatch) {
        maxMatch = match;
      }
    }

    return maxMatch;
  }

  /// 应用多样性筛选
  List<_PrioritizedConfig> _applyDiversityFilter(
    List<_PrioritizedConfig> configs,
  ) {
    final selected = <_PrioritizedConfig>[];
    final remaining = List<_PrioritizedConfig>.from(configs);

    // 选择优先级最高的配置
    if (remaining.isNotEmpty) {
      selected.add(remaining.removeAt(0));
    }

    // 选择与已选配置差异较大的配置
    while (selected.length < _maxCombinations && remaining.isNotEmpty) {
      var maxMinDistance = 0.0;
      var bestIndex = 0;

      for (var i = 0; i < remaining.length; i++) {
        final candidate = remaining[i];
        var minDistance = double.infinity;

        for (final selectedConfig in selected) {
          final distance = _calculateConfigDistance(
            candidate.config,
            selectedConfig.config,
          );
          if (distance < minDistance) {
            minDistance = distance;
          }
        }

        if (minDistance > maxMinDistance) {
          maxMinDistance = minDistance;
          bestIndex = i;
        }
      }

      selected.add(remaining.removeAt(bestIndex));
    }

    return selected;
  }

  /// 计算配置距离
  double _calculateConfigDistance(
    ConfigurationSet config1,
    ConfigurationSet config2,
  ) {
    final deps1 = config1.allDependencies.keys.toSet();
    final deps2 = config2.allDependencies.keys.toSet();

    final union = deps1.union(deps2);
    final intersection = deps1.intersection(deps2);

    if (union.isEmpty) return 1;

    return 1.0 - (intersection.length / union.length);
  }

  /// 初始化包流行度数据
  void _initializePackagePopularity() {
    _packagePopularity.addAll({
      'flutter': 1.0,
      'flutter_test': 0.95,
      'flutter_riverpod': 0.9,
      'riverpod': 0.85,
      'go_router': 0.8,
      'dio': 0.85,
      'freezed': 0.75,
      'json_annotation': 0.8,
      'build_runner': 0.7,
      'json_serializable': 0.75,
      'very_good_analysis': 0.6,
      'mocktail': 0.65,
    });
  }

  /// 初始化成功模式
  void _initializeSuccessPatterns() {
    // 添加一些已知的成功模式
    _successPatterns.addAll([
      ConfigurationPattern(
        name: 'Basic Flutter App',
        requiredPackages: {'flutter', 'flutter_test'},
        optionalPackages: {'very_good_analysis'},
        weight: 0.9,
      ),
      ConfigurationPattern(
        name: 'Riverpod State Management',
        requiredPackages: {'flutter', 'flutter_riverpod', 'riverpod'},
        optionalPackages: {'go_router'},
        weight: 0.85,
      ),
      ConfigurationPattern(
        name: 'JSON Serialization',
        requiredPackages: {'json_annotation', 'build_runner'},
        optionalPackages: {'freezed', 'json_serializable'},
        weight: 0.8,
      ),
    ]);
  }

  /// 更新成功模式
  void _updateSuccessPatterns(ConfigurationSet config) {
    // 简化的模式学习 - 实际实现会更复杂
    final packageNames = config.allDependencies.keys.toSet();

    // 查找是否有匹配的现有模式
    var foundMatch = false;
    for (final pattern in _successPatterns) {
      if (pattern.requiredPackages.intersection(packageNames).length >=
          pattern.requiredPackages.length * 0.8) {
        pattern.weight = (pattern.weight + 0.1).clamp(0.0, 1.0);
        foundMatch = true;
        break;
      }
    }

    // 如果没有匹配的模式，创建新模式
    if (!foundMatch && packageNames.length >= 3) {
      final newPattern = ConfigurationPattern(
        name: 'Auto-generated Pattern ${_successPatterns.length + 1}',
        requiredPackages: packageNames.take(3).toSet(),
        optionalPackages: packageNames.skip(3).toSet(),
        weight: 0.6,
      );
      _successPatterns.add(newPattern);
    }
  }
}

/// 优先级配置包装类
class _PrioritizedConfig {
  _PrioritizedConfig(this.config, this.priority);
  final ConfigurationSet config;
  final double priority;
}

/// 配置模式类
class ConfigurationPattern {
  ConfigurationPattern({
    required this.name,
    required this.requiredPackages,
    this.optionalPackages = const {},
    this.weight = 1.0,
  });
  final String name;
  final Set<String> requiredPackages;
  final Set<String> optionalPackages;
  double weight;

  /// 计算与配置的匹配度
  double calculateMatch(ConfigurationSet config) {
    final configPackages = config.allDependencies.keys.toSet();

    // 检查必需包的匹配度
    final requiredMatches = requiredPackages.intersection(configPackages);
    final requiredMatchRate = requiredMatches.length / requiredPackages.length;

    // 检查可选包的匹配度
    final optionalMatches = optionalPackages.intersection(configPackages);
    final optionalMatchRate = optionalPackages.isNotEmpty
        ? optionalMatches.length / optionalPackages.length
        : 1.0;

    // 综合匹配度
    final matchScore = (requiredMatchRate * 0.8) + (optionalMatchRate * 0.2);

    return matchScore * weight;
  }
}
