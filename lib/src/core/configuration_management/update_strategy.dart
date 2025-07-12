/*
---------------------------------------------------------------
File name:          update_strategy.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        模板配置管理系统 (Template Configuration Management System)
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - 模板配置管理系统;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/configuration_management/models/version_info.dart';
import 'package:ming_status_cli/src/core/configuration_management/models/configuration_set.dart';

/// 测试策略枚举
enum TestStrategy {
  /// 保守策略：优先稳定版本，避免风险
  conservative,

  /// 平衡策略：稳定性和新特性平衡
  balanced,

  /// 激进策略：优先最新版本，获取新特性
  aggressive,
}

/// 更新策略抽象类
///
/// 定义配置生成的策略接口
abstract class UpdateStrategy {
  /// 策略名称
  String get name;

  /// 策略描述
  String get description;

  /// 生成配置组合
  List<ConfigurationSet> generateConfigurations(
    Map<String, VersionInfo> versions, {
    int maxCombinations = 50,
  });

  /// 计算配置优先级
  double calculatePriority(ConfigurationSet config);

  /// 是否应该包含此版本
  bool shouldIncludeVersion(VersionInfo versionInfo);
}

/// 保守更新策略
///
/// 优先选择稳定、经过验证的版本
class ConservativeUpdateStrategy implements UpdateStrategy {
  @override
  String get name => 'Conservative';

  @override
  String get description =>
      'Prioritizes stable, well-tested versions to minimize risk';

  @override
  List<ConfigurationSet> generateConfigurations(
    Map<String, VersionInfo> versions, {
    int maxCombinations = 50,
  }) {
    final configurations = <ConfigurationSet>[];

    // 过滤出稳定版本
    final stableVersions = <String, VersionInfo>{};
    for (final entry in versions.entries) {
      if (shouldIncludeVersion(entry.value)) {
        stableVersions[entry.key] = entry.value;
      }
    }

    if (stableVersions.isEmpty) return configurations;

    // 生成基础稳定配置
    final baseConfig = _createBaseConfiguration(stableVersions, 'stable');
    configurations.add(baseConfig);

    // 生成分层配置
    configurations.addAll(_generateLayeredConfigurations(stableVersions));

    // 按优先级排序并限制数量
    configurations.sort((a, b) => b.priority.compareTo(a.priority));
    return configurations.take(maxCombinations).toList();
  }

  @override
  double calculatePriority(ConfigurationSet config) {
    var priority = 0.0;

    // 稳定性权重 (40%)
    priority += config.calculateStabilityScore() * 0.4;

    // 成熟度权重 (30%) - 发布时间越久越成熟
    final maturityScore = _calculateMaturityScore(config);
    priority += maturityScore * 0.3;

    // 流行度权重 (20%)
    final popularityScore = _calculatePopularityScore(config);
    priority += popularityScore * 0.2;

    // 兼容性权重 (10%)
    final compatibilityScore = _calculateCompatibilityScore(config);
    priority += compatibilityScore * 0.1;

    return priority.clamp(0.0, 1.0);
  }

  @override
  bool shouldIncludeVersion(VersionInfo versionInfo) {
    // 必须是稳定版本
    if (!versionInfo.isStable || versionInfo.isPrerelease) {
      return false;
    }

    // 稳定性评分必须高于阈值
    if (versionInfo.calculateStabilityScore() < 0.7) {
      return false;
    }

    // 发布时间不能太新（至少30天）
    final daysSincePublished =
        DateTime.now().difference(versionInfo.publishedAt).inDays;
    if (daysSincePublished < 30) {
      return false;
    }

    return true;
  }

  /// 创建基础配置
  ConfigurationSet _createBaseConfiguration(
      Map<String, VersionInfo> versions, String suffix) {
    return ConfigurationSet(
      id: 'conservative_$suffix${DateTime.now().millisecondsSinceEpoch}',
      name: 'Conservative $suffix Configuration',
      description: 'Stable and well-tested versions',
      essentialDependencies: Map.from(versions),
      createdAt: DateTime.now(),
      priority: calculatePriority(
        ConfigurationSet(
          id: 'temp',
          name: 'temp',
          essentialDependencies: versions,
          createdAt: DateTime.now(),
        ),
      ),
      tags: {'conservative', suffix, 'stable'},
    );
  }

  /// 生成分层配置
  List<ConfigurationSet> _generateLayeredConfigurations(
      Map<String, VersionInfo> versions) {
    final configurations = <ConfigurationSet>[];

    // 按重要性分层
    final coreDeps = <String, VersionInfo>{};
    final essentialDeps = <String, VersionInfo>{};
    final optionalDeps = <String, VersionInfo>{};

    for (final entry in versions.entries) {
      final packageName = entry.key;
      final versionInfo = entry.value;

      if (_isCorePackage(packageName)) {
        coreDeps[packageName] = versionInfo;
      } else if (_isEssentialPackage(packageName)) {
        essentialDeps[packageName] = versionInfo;
      } else {
        optionalDeps[packageName] = versionInfo;
      }
    }

    // 生成核心配置
    if (coreDeps.isNotEmpty) {
      configurations.add(
        _createLayeredConfiguration(
          coreDeps,
          essentialDeps,
          {},
          {},
          'core',
        ),
      );
    }

    // 生成完整配置
    if (essentialDeps.isNotEmpty) {
      configurations.add(
        _createLayeredConfiguration(
          coreDeps,
          essentialDeps,
          optionalDeps,
          {},
          'full',
        ),
      );
    }

    return configurations;
  }

  /// 创建分层配置
  ConfigurationSet _createLayeredConfiguration(
    Map<String, VersionInfo> core,
    Map<String, VersionInfo> essential,
    Map<String, VersionInfo> optional,
    Map<String, VersionInfo> dev,
    String suffix,
  ) {
    final config = ConfigurationSet(
      id: 'conservative_layered_$suffix${DateTime.now().millisecondsSinceEpoch}',
      name: 'Conservative Layered $suffix',
      description: 'Layered conservative configuration',
      coreDependencies: core,
      essentialDependencies: essential,
      optionalDependencies: optional,
      devDependencies: dev,
      createdAt: DateTime.now(),
      tags: {'conservative', 'layered', suffix},
    );

    return config.copyWith(priority: calculatePriority(config));
  }

  /// 计算成熟度评分
  double _calculateMaturityScore(ConfigurationSet config) {
    if (config.allDependencies.isEmpty) return 0;

    final scores = config.allDependencies.values.map((version) {
      final daysSincePublished =
          DateTime.now().difference(version.publishedAt).inDays;

      // 90天以上认为成熟
      if (daysSincePublished >= 90) return 1.0;

      // 30天以下认为不成熟
      if (daysSincePublished < 30) return 0.0;

      // 线性增长
      return (daysSincePublished - 30) / (90 - 30);
    });

    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// 计算流行度评分
  double _calculatePopularityScore(ConfigurationSet config) {
    if (config.allDependencies.isEmpty) return 0;

    final scores = config.allDependencies.values.map((version) {
      final downloadCount = version.downloadCount ?? 0;

      // 10万下载以上认为流行
      if (downloadCount >= 100000) return 1.0;

      // 1万下载以下认为不流行
      if (downloadCount < 10000) return 0.0;

      // 对数增长
      return (downloadCount - 10000) / (100000 - 10000);
    });

    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// 计算兼容性评分
  double _calculateCompatibilityScore(ConfigurationSet config) {
    final dependencies = config.allDependencies.values.toList();
    if (dependencies.length < 2) return 1;

    var compatiblePairs = 0;
    var totalPairs = 0;

    for (var i = 0; i < dependencies.length; i++) {
      for (var j = i + 1; j < dependencies.length; j++) {
        totalPairs++;
        if (dependencies[i].isCompatibleWith(dependencies[j])) {
          compatiblePairs++;
        }
      }
    }

    return totalPairs > 0 ? compatiblePairs / totalPairs : 1.0;
  }

  /// 检查是否为核心包
  bool _isCorePackage(String packageName) {
    const corePackages = {
      'flutter',
      'dart',
      'flutter_test',
    };
    return corePackages.contains(packageName);
  }

  /// 检查是否为必需包
  bool _isEssentialPackage(String packageName) {
    const essentialPackages = {
      'riverpod',
      'flutter_riverpod',
      'go_router',
      'dio',
      'freezed',
      'json_annotation',
    };
    return essentialPackages.contains(packageName);
  }
}

/// 平衡更新策略
///
/// 在稳定性和新特性之间寻求平衡
class BalancedUpdateStrategy implements UpdateStrategy {
  @override
  String get name => 'Balanced';

  @override
  String get description =>
      'Balances stability with new features and improvements';

  @override
  List<ConfigurationSet> generateConfigurations(
    Map<String, VersionInfo> versions, {
    int maxCombinations = 50,
  }) {
    final configurations = <ConfigurationSet>[];

    // 生成多种平衡配置
    configurations.addAll(_generateStabilityFocusedConfigs(versions));
    configurations.addAll(_generateFeatureFocusedConfigs(versions));
    configurations.addAll(_generateMixedConfigs(versions));

    // 按优先级排序并限制数量
    configurations.sort((a, b) => b.priority.compareTo(a.priority));
    return configurations.take(maxCombinations).toList();
  }

  @override
  double calculatePriority(ConfigurationSet config) {
    var priority = 0.0;

    // 稳定性权重 (30%)
    priority += config.calculateStabilityScore() * 0.3;

    // 新鲜度权重 (30%)
    priority += config.calculateFreshnessScore() * 0.3;

    // 兼容性权重 (25%)
    final compatibilityScore = _calculateCompatibilityScore(config);
    priority += compatibilityScore * 0.25;

    // 复杂度权重 (15%) - 适中的复杂度更好
    final complexityScore = _calculateComplexityScore(config);
    priority += complexityScore * 0.15;

    return priority.clamp(0.0, 1.0);
  }

  @override
  bool shouldIncludeVersion(VersionInfo versionInfo) {
    // 综合评分必须达到阈值
    final stabilityScore = versionInfo.calculateStabilityScore();
    final freshnessScore = versionInfo.calculateFreshness();
    final combinedScore = (stabilityScore + freshnessScore) / 2;

    return combinedScore >= 0.5;
  }

  /// 生成稳定性导向配置
  List<ConfigurationSet> _generateStabilityFocusedConfigs(
      Map<String, VersionInfo> versions) {
    final stableVersions = versions.entries
        .where((entry) => entry.value.calculateStabilityScore() > 0.7)
        .toList();

    if (stableVersions.isEmpty) return [];

    final config = ConfigurationSet(
      id: 'balanced_stability_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Balanced Stability-Focused',
      description: 'Balanced configuration prioritizing stability',
      essentialDependencies: Map.fromEntries(stableVersions),
      createdAt: DateTime.now(),
      tags: {'balanced', 'stability-focused'},
    );

    return [config.copyWith(priority: calculatePriority(config))];
  }

  /// 生成特性导向配置
  List<ConfigurationSet> _generateFeatureFocusedConfigs(
      Map<String, VersionInfo> versions) {
    final freshVersions = versions.entries
        .where((entry) => entry.value.calculateFreshness() > 0.6)
        .toList();

    if (freshVersions.isEmpty) return [];

    final config = ConfigurationSet(
      id: 'balanced_feature_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Balanced Feature-Focused',
      description: 'Balanced configuration with newer features',
      essentialDependencies: Map.fromEntries(freshVersions),
      createdAt: DateTime.now(),
      tags: {'balanced', 'feature-focused'},
    );

    return [config.copyWith(priority: calculatePriority(config))];
  }

  /// 生成混合配置
  List<ConfigurationSet> _generateMixedConfigs(
      Map<String, VersionInfo> versions) {
    final configs = <ConfigurationSet>[];

    // 选择平衡的版本组合
    final balancedVersions = versions.entries
        .where((entry) => shouldIncludeVersion(entry.value))
        .toList();

    if (balancedVersions.isNotEmpty) {
      final config = ConfigurationSet(
        id: 'balanced_mixed_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Balanced Mixed Configuration',
        description: 'Well-balanced mix of stability and features',
        essentialDependencies: Map.fromEntries(balancedVersions),
        createdAt: DateTime.now(),
        tags: {'balanced', 'mixed', 'recommended'},
      );

      configs.add(config.copyWith(priority: calculatePriority(config)));
    }

    return configs;
  }

  /// 计算兼容性评分
  double _calculateCompatibilityScore(ConfigurationSet config) {
    // 与保守策略相同的实现
    final dependencies = config.allDependencies.values.toList();
    if (dependencies.length < 2) return 1;

    var compatiblePairs = 0;
    var totalPairs = 0;

    for (var i = 0; i < dependencies.length; i++) {
      for (var j = i + 1; j < dependencies.length; j++) {
        totalPairs++;
        if (dependencies[i].isCompatibleWith(dependencies[j])) {
          compatiblePairs++;
        }
      }
    }

    return totalPairs > 0 ? compatiblePairs / totalPairs : 1.0;
  }

  /// 计算复杂度评分
  double _calculateComplexityScore(ConfigurationSet config) {
    final complexity = config.complexity;

    // 适中的复杂度 (10-20个依赖) 得分最高
    if (complexity >= 10 && complexity <= 20) return 1;

    // 过少或过多的依赖得分较低
    if (complexity < 5) return complexity / 5.0;
    if (complexity > 30)
      return 1.0 - ((complexity - 30) / 20.0).clamp(0.0, 1.0);

    // 其他情况线性计算
    return 0.8;
  }
}

/// 激进更新策略
///
/// 优先选择最新版本以获取新特性
class AggressiveUpdateStrategy implements UpdateStrategy {
  @override
  String get name => 'Aggressive';

  @override
  String get description =>
      'Prioritizes latest versions to get cutting-edge features';

  @override
  List<ConfigurationSet> generateConfigurations(
    Map<String, VersionInfo> versions, {
    int maxCombinations = 50,
  }) {
    final configurations = <ConfigurationSet>[];

    // 生成最新版本配置
    configurations.addAll(_generateLatestConfigs(versions));
    configurations.addAll(_generateBetaConfigs(versions));
    configurations.addAll(_generateExperimentalConfigs(versions));

    // 按优先级排序并限制数量
    configurations.sort((a, b) => b.priority.compareTo(a.priority));
    return configurations.take(maxCombinations).toList();
  }

  @override
  double calculatePriority(ConfigurationSet config) {
    var priority = 0.0;

    // 新鲜度权重 (50%)
    priority += config.calculateFreshnessScore() * 0.5;

    // 特性丰富度权重 (25%)
    final featureScore = _calculateFeatureScore(config);
    priority += featureScore * 0.25;

    // 兼容性权重 (15%)
    final compatibilityScore = _calculateCompatibilityScore(config);
    priority += compatibilityScore * 0.15;

    // 稳定性权重 (10%) - 较低权重
    priority += config.calculateStabilityScore() * 0.1;

    return priority.clamp(0.0, 1.0);
  }

  @override
  bool shouldIncludeVersion(VersionInfo versionInfo) {
    // 新鲜度是主要考虑因素
    return versionInfo.calculateFreshness() > 0.3;
  }

  /// 生成最新版本配置
  List<ConfigurationSet> _generateLatestConfigs(
      Map<String, VersionInfo> versions) {
    final config = ConfigurationSet(
      id: 'aggressive_latest_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Aggressive Latest Configuration',
      description: 'Latest stable versions with cutting-edge features',
      essentialDependencies: Map.from(versions),
      createdAt: DateTime.now(),
      tags: {'aggressive', 'latest', 'cutting-edge'},
    );

    return [config.copyWith(priority: calculatePriority(config))];
  }

  /// 生成Beta版本配置
  List<ConfigurationSet> _generateBetaConfigs(
      Map<String, VersionInfo> versions) {
    final betaVersions =
        versions.entries.where((entry) => entry.value.isPrerelease).toList();

    if (betaVersions.isEmpty) return [];

    final config = ConfigurationSet(
      id: 'aggressive_beta_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Aggressive Beta Configuration',
      description: 'Beta and pre-release versions for early access',
      essentialDependencies: Map.fromEntries(betaVersions),
      createdAt: DateTime.now(),
      tags: {'aggressive', 'beta', 'experimental'},
    );

    return [config.copyWith(priority: calculatePriority(config))];
  }

  /// 生成实验性配置
  List<ConfigurationSet> _generateExperimentalConfigs(
      Map<String, VersionInfo> versions) {
    final experimentalVersions = versions.entries
        .where((entry) => entry.value.calculateFreshness() > 0.8)
        .toList();

    if (experimentalVersions.isEmpty) return [];

    final config = ConfigurationSet(
      id: 'aggressive_experimental_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Aggressive Experimental Configuration',
      description: 'Experimental versions for bleeding-edge features',
      essentialDependencies: Map.fromEntries(experimentalVersions),
      createdAt: DateTime.now(),
      tags: {'aggressive', 'experimental', 'bleeding-edge'},
    );

    return [config.copyWith(priority: calculatePriority(config))];
  }

  /// 计算特性评分
  double _calculateFeatureScore(ConfigurationSet config) {
    // 基于版本新鲜度和描述来评估特性丰富度
    return config.calculateFreshnessScore();
  }

  /// 计算兼容性评分
  double _calculateCompatibilityScore(ConfigurationSet config) {
    // 与其他策略相同的实现
    final dependencies = config.allDependencies.values.toList();
    if (dependencies.length < 2) return 1;

    var compatiblePairs = 0;
    var totalPairs = 0;

    for (var i = 0; i < dependencies.length; i++) {
      for (var j = i + 1; j < dependencies.length; j++) {
        totalPairs++;
        if (dependencies[i].isCompatibleWith(dependencies[j])) {
          compatiblePairs++;
        }
      }
    }

    return totalPairs > 0 ? compatiblePairs / totalPairs : 1.0;
  }
}

/// 策略工厂
class UpdateStrategyFactory {
  /// 创建策略实例
  static UpdateStrategy createStrategy(TestStrategy strategy) {
    switch (strategy) {
      case TestStrategy.conservative:
        return ConservativeUpdateStrategy();
      case TestStrategy.balanced:
        return BalancedUpdateStrategy();
      case TestStrategy.aggressive:
        return AggressiveUpdateStrategy();
    }
  }

  /// 获取所有可用策略
  static List<UpdateStrategy> getAllStrategies() {
    return [
      ConservativeUpdateStrategy(),
      BalancedUpdateStrategy(),
      AggressiveUpdateStrategy(),
    ];
  }
}
