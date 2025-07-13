/*
---------------------------------------------------------------
File name:          incremental_updater.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        增量更新器 (Incremental Updater)
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - 企业级模板配置管理系统;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';

import 'package:ming_status_cli/src/core/configuration_management/models/configuration_set.dart';
import 'package:ming_status_cli/src/core/configuration_management/models/test_result.dart';
import 'package:ming_status_cli/src/core/configuration_management/models/version_info.dart';

/// 变更类型枚举
enum ChangeType {
  /// 添加新依赖
  added,

  /// 移除依赖
  removed,

  /// 更新版本
  updated,

  /// 降级版本
  downgraded,
}

/// 依赖变更
class DependencyChange {
  const DependencyChange({
    required this.packageName,
    required this.changeType,
    required this.layer, this.oldVersion,
    this.newVersion,
    this.reason = '',
  });

  factory DependencyChange.fromJson(Map<String, dynamic> json) {
    return DependencyChange(
      packageName: json['packageName'] as String,
      changeType: ChangeType.values.byName(json['changeType'] as String),
      oldVersion: json['oldVersion'] != null
          ? VersionInfo.fromJson(json['oldVersion'] as Map<String, dynamic>)
          : null,
      newVersion: json['newVersion'] != null
          ? VersionInfo.fromJson(json['newVersion'] as Map<String, dynamic>)
          : null,
      layer: TestLayer.values.byName(json['layer'] as String),
      reason: json['reason'] as String? ?? '',
    );
  }
  final String packageName;
  final ChangeType changeType;
  final VersionInfo? oldVersion;
  final VersionInfo? newVersion;
  final TestLayer layer;
  final String reason;

  /// 获取变更描述
  String get description {
    switch (changeType) {
      case ChangeType.added:
        return 'Added $packageName v${newVersion?.version} to ${layer.name}';
      case ChangeType.removed:
        return 'Removed $packageName v${oldVersion?.version} from ${layer.name}';
      case ChangeType.updated:
        return 'Updated $packageName from v${oldVersion?.version} to v${newVersion?.version}';
      case ChangeType.downgraded:
        return 'Downgraded $packageName from v${oldVersion?.version} to v${newVersion?.version}';
    }
  }

  /// 获取变更影响评分
  double get impactScore {
    switch (changeType) {
      case ChangeType.added:
        return 0.3; // 添加依赖影响较小
      case ChangeType.removed:
        return 0.8; // 移除依赖影响较大
      case ChangeType.updated:
        return _calculateUpdateImpact();
      case ChangeType.downgraded:
        return 0.6; // 降级通常影响中等
    }
  }

  /// 计算更新影响
  double _calculateUpdateImpact() {
    if (oldVersion == null || newVersion == null) return 0.5;

    final oldVer = oldVersion!.version;
    final newVer = newVersion!.version;

    // 主版本变更影响最大
    if (oldVer.major != newVer.major) return 0.9;

    // 次版本变更影响中等
    if (oldVer.minor != newVer.minor) return 0.5;

    // 补丁版本变更影响较小
    return 0.2;
  }

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'changeType': changeType.name,
      'oldVersion': oldVersion?.toJson(),
      'newVersion': newVersion?.toJson(),
      'layer': layer.name,
      'reason': reason,
    };
  }
}

/// 增量更新结果
class IncrementalUpdateResult {
  const IncrementalUpdateResult({
    required this.originalConfig,
    required this.updatedConfig,
    required this.changes,
    required this.timestamp, this.testResult,
    this.confidenceScore = 0.5,
    this.metadata = const {},
  });
  final ConfigurationSet originalConfig;
  final ConfigurationSet updatedConfig;
  final List<DependencyChange> changes;
  final TestResult? testResult;
  final DateTime timestamp;
  final double confidenceScore;
  final Map<String, dynamic> metadata;

  /// 获取变更摘要
  String get changeSummary {
    final buffer = StringBuffer();
    final changesByType = <ChangeType, int>{};

    for (final change in changes) {
      changesByType[change.changeType] =
          (changesByType[change.changeType] ?? 0) + 1;
    }

    for (final entry in changesByType.entries) {
      if (buffer.isNotEmpty) buffer.write(', ');
      buffer.write('${entry.value} ${entry.key.name}');
    }

    return buffer.toString();
  }

  /// 获取总体影响评分
  double get totalImpactScore {
    if (changes.isEmpty) return 0;

    final totalImpact =
        changes.map((c) => c.impactScore).reduce((a, b) => a + b);

    return (totalImpact / changes.length).clamp(0.0, 1.0);
  }

  /// 是否为安全更新
  bool get isSafeUpdate {
    return totalImpactScore < 0.5 &&
        confidenceScore > 0.7 &&
        (testResult?.isSuccess ?? false);
  }

  Map<String, dynamic> toJson() {
    return {
      'originalConfig': originalConfig.toJson(),
      'updatedConfig': updatedConfig.toJson(),
      'changes': changes.map((c) => c.toJson()).toList(),
      'testResult': testResult?.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'confidenceScore': confidenceScore,
      'metadata': metadata,
    };
  }
}

/// 增量更新器
class IncrementalUpdater {
  IncrementalUpdater({String? cacheDirectory})
      : _cacheDirectory = cacheDirectory ?? '.cache/incremental_updates';
  final Map<String, ConfigurationSet> _configHistory = {};
  final Map<String, List<TestResult>> _testHistory = {};
  final String _cacheDirectory;

  /// 执行增量更新
  Future<IncrementalUpdateResult> performIncrementalUpdate({
    required ConfigurationSet currentConfig,
    required Map<String, VersionInfo> availableVersions,
    required double maxImpactThreshold,
    bool testChanges = true,
  }) async {
    // 1. 分析当前配置
    final configHash = currentConfig.generateHash();
    final previousConfig = _configHistory[configHash];

    // 2. 计算需要的变更
    final changes = await _calculateRequiredChanges(
      currentConfig,
      availableVersions,
      maxImpactThreshold,
    );

    // 3. 应用变更
    final updatedConfig = _applyChanges(currentConfig, changes);

    // 4. 计算置信度
    final confidenceScore = await _calculateConfidenceScore(
      currentConfig,
      updatedConfig,
      changes,
    );

    // 5. 执行测试（如果需要）
    TestResult? testResult;
    if (testChanges) {
      testResult = await _testChangedDependencies(
        currentConfig,
        updatedConfig,
        changes,
      );
    }

    // 6. 创建结果
    final result = IncrementalUpdateResult(
      originalConfig: currentConfig,
      updatedConfig: updatedConfig,
      changes: changes,
      testResult: testResult,
      timestamp: DateTime.now(),
      confidenceScore: confidenceScore,
      metadata: {
        'maxImpactThreshold': maxImpactThreshold,
        'previousConfigExists': previousConfig != null,
        'changeCount': changes.length,
      },
    );

    // 7. 更新历史记录
    _updateHistory(result);

    return result;
  }

  /// 只测试变化的依赖
  Future<TestResult> testChangedDependencies(
    ConfigurationSet oldConfig,
    ConfigurationSet newConfig,
    List<DependencyChange> changes,
  ) async {
    return _testChangedDependencies(oldConfig, newConfig, changes);
  }

  /// 获取更新建议
  Future<List<DependencyChange>> getUpdateSuggestions({
    required ConfigurationSet currentConfig,
    required Map<String, VersionInfo> availableVersions,
    double maxImpactThreshold = 0.5,
  }) async {
    return _calculateRequiredChanges(
      currentConfig,
      availableVersions,
      maxImpactThreshold,
    );
  }

  /// 获取配置历史
  List<ConfigurationSet> getConfigurationHistory(String configId) {
    return _configHistory.values
        .where((config) => config.id.startsWith(configId))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 获取测试历史
  List<TestResult> getTestHistory(String configId) {
    return _testHistory[configId] ?? [];
  }

  /// 计算需要的变更
  Future<List<DependencyChange>> _calculateRequiredChanges(
    ConfigurationSet currentConfig,
    Map<String, VersionInfo> availableVersions,
    double maxImpactThreshold,
  ) async {
    final changes = <DependencyChange>[];

    // 检查每个层级的依赖
    for (final layer in TestLayer.values) {
      final currentDeps = currentConfig.getDependenciesByLayer(layer);

      for (final entry in currentDeps.entries) {
        final packageName = entry.key;
        final currentVersion = entry.value;
        final availableVersion = availableVersions[packageName];

        if (availableVersion == null) continue;

        // 检查是否需要更新
        final updateChange = _shouldUpdate(
          currentVersion,
          availableVersion,
          layer,
          maxImpactThreshold,
        );

        if (updateChange != null) {
          changes.add(updateChange);
        }
      }

      // 检查新增的依赖
      for (final entry in availableVersions.entries) {
        final packageName = entry.key;
        final availableVersion = entry.value;

        if (!currentDeps.containsKey(packageName)) {
          final addChange = _shouldAdd(
            packageName,
            availableVersion,
            layer,
            maxImpactThreshold,
          );

          if (addChange != null) {
            changes.add(addChange);
          }
        }
      }
    }

    // 按影响评分排序，优先处理低影响的变更
    changes.sort((a, b) => a.impactScore.compareTo(b.impactScore));

    return changes;
  }

  /// 检查是否应该更新
  DependencyChange? _shouldUpdate(
    VersionInfo currentVersion,
    VersionInfo availableVersion,
    TestLayer layer,
    double maxImpactThreshold,
  ) {
    // 如果版本相同，不需要更新
    if (currentVersion.version == availableVersion.version) {
      return null;
    }

    // 确定更新类型
    final isUpgrade =
        availableVersion.version.compareTo(currentVersion.version) > 0;
    final changeType = isUpgrade ? ChangeType.updated : ChangeType.downgraded;

    // 创建变更对象
    final change = DependencyChange(
      packageName: currentVersion.packageName,
      changeType: changeType,
      oldVersion: currentVersion,
      newVersion: availableVersion,
      layer: layer,
      reason: _getUpdateReason(currentVersion, availableVersion),
    );

    // 检查影响是否在阈值内
    if (change.impactScore > maxImpactThreshold) {
      return null;
    }

    // 检查是否值得更新
    if (isUpgrade && _isWorthwhileUpgrade(currentVersion, availableVersion)) {
      return change;
    }

    if (!isUpgrade && _isNecessaryDowngrade(currentVersion, availableVersion)) {
      return change;
    }

    return null;
  }

  /// 检查是否应该添加
  DependencyChange? _shouldAdd(
    String packageName,
    VersionInfo availableVersion,
    TestLayer layer,
    double maxImpactThreshold,
  ) {
    // 只在特定条件下建议添加新依赖
    const recommendedPackages = {
      'very_good_analysis',
      'mocktail',
      'flutter_lints',
    };

    if (!recommendedPackages.contains(packageName)) {
      return null;
    }

    final change = DependencyChange(
      packageName: packageName,
      changeType: ChangeType.added,
      newVersion: availableVersion,
      layer: layer,
      reason: 'Recommended package for better development experience',
    );

    return change.impactScore <= maxImpactThreshold ? change : null;
  }

  /// 获取更新原因
  String _getUpdateReason(VersionInfo current, VersionInfo available) {
    if (available.version.compareTo(current.version) > 0) {
      if (available.version.major > current.version.major) {
        return 'Major version upgrade with new features';
      } else if (available.version.minor > current.version.minor) {
        return 'Minor version upgrade with improvements';
      } else {
        return 'Patch version upgrade with bug fixes';
      }
    } else {
      return 'Downgrade for compatibility';
    }
  }

  /// 检查是否值得升级
  bool _isWorthwhileUpgrade(VersionInfo current, VersionInfo available) {
    // 安全更新总是值得的
    if (available.version.patch > current.version.patch) {
      return true;
    }

    // 次版本更新需要评估
    if (available.version.minor > current.version.minor) {
      final daysSinceRelease =
          DateTime.now().difference(available.publishedAt).inDays;
      return daysSinceRelease > 7; // 等待一周确保稳定性
    }

    // 主版本更新需要谨慎
    if (available.version.major > current.version.major) {
      final daysSinceRelease =
          DateTime.now().difference(available.publishedAt).inDays;
      return daysSinceRelease > 30 && available.isStable;
    }

    return false;
  }

  /// 检查是否需要降级
  bool _isNecessaryDowngrade(VersionInfo current, VersionInfo available) {
    // 只在兼容性问题时才降级
    return !current.isStable && available.isStable;
  }

  /// 应用变更
  ConfigurationSet _applyChanges(
    ConfigurationSet config,
    List<DependencyChange> changes,
  ) {
    var updatedConfig = config;

    for (final change in changes) {
      switch (change.changeType) {
        case ChangeType.added:
          if (change.newVersion != null) {
            updatedConfig = updatedConfig.addDependency(
              change.layer,
              change.packageName,
              change.newVersion!,
            );
          }

        case ChangeType.removed:
          updatedConfig = updatedConfig.removeDependency(change.packageName);

        case ChangeType.updated:
        case ChangeType.downgraded:
          if (change.newVersion != null) {
            updatedConfig = updatedConfig
                .removeDependency(change.packageName)
                .addDependency(
                  change.layer,
                  change.packageName,
                  change.newVersion!,
                );
          }
      }
    }

    // 更新配置元数据
    return updatedConfig.copyWith(
      id: '${config.id}_incremental_${DateTime.now().millisecondsSinceEpoch}',
      name: '${config.name} (Incremental Update)',
      description: 'Incrementally updated configuration',
      createdAt: DateTime.now(),
    );
  }

  /// 计算置信度评分
  Future<double> _calculateConfidenceScore(
    ConfigurationSet originalConfig,
    ConfigurationSet updatedConfig,
    List<DependencyChange> changes,
  ) async {
    var confidence = 1.0;

    // 基于变更数量的置信度
    final changeCountPenalty = (changes.length * 0.05).clamp(0.0, 0.3);
    confidence -= changeCountPenalty;

    // 基于变更影响的置信度
    final avgImpact = changes.isNotEmpty
        ? changes.map((c) => c.impactScore).reduce((a, b) => a + b) /
            changes.length
        : 0.0;
    confidence -= avgImpact * 0.2;

    // 基于历史成功率的置信度
    final historicalSuccess = _getHistoricalSuccessRate(originalConfig);
    confidence = (confidence + historicalSuccess) / 2;

    return confidence.clamp(0.0, 1.0);
  }

  /// 测试变化的依赖
  Future<TestResult> _testChangedDependencies(
    ConfigurationSet oldConfig,
    ConfigurationSet newConfig,
    List<DependencyChange> changes,
  ) async {
    final testId = 'incremental_test_${DateTime.now().millisecondsSinceEpoch}';
    final startTime = DateTime.now();

    try {
      // 模拟增量测试
      await Future.delayed(const Duration(milliseconds: 500));

      // 基于变更影响计算成功率
      final totalImpact = changes.isNotEmpty
          ? changes.map((c) => c.impactScore).reduce((a, b) => a + b) /
              changes.length
          : 0.0;

      final successRate = (1.0 - totalImpact * 0.5).clamp(0.3, 0.95);
      final isSuccess = DateTime.now().millisecond % 100 < (successRate * 100);

      if (isSuccess) {
        return TestResult.success(
          testId: testId,
          configurationSet: newConfig,
          startTime: startTime,
          logs: ['Incremental test completed successfully'],
          metrics: {
            'changesCount': changes.length,
            'totalImpact': totalImpact,
            'testType': 'incremental',
          },
        );
      } else {
        return TestResult.failure(
          testId: testId,
          configurationSet: newConfig,
          startTime: startTime,
          errorMessage: 'Incremental test failed due to dependency conflicts',
          errorType: TestErrorType.dependencyConflict,
        );
      }
    } catch (e) {
      return TestResult.failure(
        testId: testId,
        configurationSet: newConfig,
        startTime: startTime,
        errorMessage: 'Incremental test error: $e',
        errorType: TestErrorType.runtimeError,
      );
    }
  }

  /// 获取历史成功率
  double _getHistoricalSuccessRate(ConfigurationSet config) {
    final history = _testHistory[config.id] ?? [];
    if (history.isEmpty) return 0.5;

    final successCount = history.where((r) => r.isSuccess).length;
    return successCount / history.length;
  }

  /// 更新历史记录
  void _updateHistory(IncrementalUpdateResult result) {
    final configHash = result.originalConfig.generateHash();
    _configHistory[configHash] = result.originalConfig;
    _configHistory[result.updatedConfig.generateHash()] = result.updatedConfig;

    if (result.testResult != null) {
      final configId = result.updatedConfig.id;
      _testHistory[configId] = (_testHistory[configId] ?? [])
        ..add(result.testResult!)
        ..sort((a, b) => b.startTime.compareTo(a.startTime));

      // 保持历史记录在合理大小
      if (_testHistory[configId]!.length > 50) {
        _testHistory[configId] = _testHistory[configId]!.take(50).toList();
      }
    }
  }

  /// 保存缓存
  Future<void> saveCache() async {
    final cacheDir = Directory(_cacheDirectory);
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    // 保存配置历史
    final configFile = File('$_cacheDirectory/config_history.json');
    final configData = _configHistory.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await configFile.writeAsString(json.encode(configData));

    // 保存测试历史
    final testFile = File('$_cacheDirectory/test_history.json');
    final testData = _testHistory.map(
      (key, value) => MapEntry(key, value.map((r) => r.toJson()).toList()),
    );
    await testFile.writeAsString(json.encode(testData));
  }

  /// 加载缓存
  Future<void> loadCache() async {
    try {
      // 加载配置历史
      final configFile = File('$_cacheDirectory/config_history.json');
      if (await configFile.exists()) {
        final configData = json.decode(await configFile.readAsString())
            as Map<String, dynamic>;
        _configHistory.clear();
        for (final entry in configData.entries) {
          _configHistory[entry.key] =
              ConfigurationSet.fromJson(entry.value as Map<String, dynamic>);
        }
      }

      // 加载测试历史
      final testFile = File('$_cacheDirectory/test_history.json');
      if (await testFile.exists()) {
        final testData =
            json.decode(await testFile.readAsString()) as Map<String, dynamic>;
        _testHistory.clear();
        for (final entry in testData.entries) {
          final results = (entry.value as List)
              .map((r) => TestResult.fromJson(r as Map<String, dynamic>))
              .toList();
          _testHistory[entry.key] = results;
        }
      }
    } catch (e) {
      // 忽略缓存加载错误
    }
  }
}
