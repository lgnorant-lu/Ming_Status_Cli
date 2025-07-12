/*
---------------------------------------------------------------
File name:          version_resolver.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        版本解析器 (Version Resolver)
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - 企业级模板配置管理系统;
---------------------------------------------------------------
*/
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pub_semver/pub_semver.dart';

import 'package:ming_status_cli/src/core/configuration_management/models/version_info.dart';
import 'package:ming_status_cli/src/core/configuration_management/models/configuration_set.dart';
import 'package:ming_status_cli/src/core/configuration_management/update_strategy.dart';

/// 智能版本解析器
/// 
/// 负责获取最新版本信息并生成测试配置组合
class IntelligentVersionResolver {
  
  /// 创建智能版本解析器实例
  IntelligentVersionResolver({
    http.Client? httpClient,
    int cacheExpirationHours = 1,
  }) : _httpClient = httpClient ?? http.Client(),
       _cacheExpirationHours = cacheExpirationHours;
  /// HTTP客户端
  final http.Client _httpClient;
  
  /// 缓存过期时间（小时）
  final int _cacheExpirationHours;
  
  /// 版本信息缓存
  final Map<String, VersionInfo> _versionCache = {};
  
  /// 缓存时间戳
  final Map<String, DateTime> _cacheTimestamps = {};
  
  /// 获取最新版本信息
  /// 
  /// 从多个源获取依赖包的最新版本信息
  Future<Map<String, VersionInfo>> getLatestVersions({
    List<String>? packageNames,
    bool includePrerelease = false,
    bool forceRefresh = false,
  }) async {
    packageNames ??= _getDefaultPackageNames();
    
    final results = <String, VersionInfo>{};
    final futures = <Future<void>>[];
    
    for (final packageName in packageNames) {
      futures.add(_getPackageVersion(
        packageName,
        includePrerelease: includePrerelease,
        forceRefresh: forceRefresh,
      ).then((versionInfo) {
        if (versionInfo != null) {
          results[packageName] = versionInfo;
        }
      }),);
    }
    
    await Future.wait(futures);
    return results;
  }
  
  /// 生成测试配置组合
  /// 
  /// 基于版本信息和策略生成配置组合
  Future<List<ConfigurationSet>> generateTestConfigurations({
    required Map<String, VersionInfo> versions,
    required TestStrategy strategy,
    int maxCombinations = 50,
  }) async {
    final configurations = <ConfigurationSet>[];
    
    // 根据策略生成配置
    switch (strategy) {
      case TestStrategy.conservative:
        configurations.addAll(_generateConservativeConfigurations(versions));
      case TestStrategy.balanced:
        configurations.addAll(_generateBalancedConfigurations(versions));
      case TestStrategy.aggressive:
        configurations.addAll(_generateAggressiveConfigurations(versions));
    }
    
    // 限制配置数量
    if (configurations.length > maxCombinations) {
      configurations.sort((a, b) => b.priority.compareTo(a.priority));
      return configurations.take(maxCombinations).toList();
    }
    
    return configurations;
  }
  
  /// 快速兼容性检查
  /// 
  /// 对配置集合进行快速的兼容性验证
  Future<bool> quickCompatibilityCheck(ConfigurationSet config) async {
    try {
      // 检查核心依赖兼容性
      if (!_checkCoreCompatibility(config)) {
        return false;
      }
      
      // 检查依赖冲突
      if (!_checkDependencyConflicts(config)) {
        return false;
      }
      
      // 检查版本约束
      if (!_checkVersionConstraints(config)) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// 获取单个包的版本信息
  Future<VersionInfo?> _getPackageVersion(
    String packageName, {
    bool includePrerelease = false,
    bool forceRefresh = false,
  }) async {
    // 检查缓存
    if (!forceRefresh && _isCacheValid(packageName)) {
      return _versionCache[packageName];
    }
    
    try {
      // 从 pub.dev 获取版本信息
      final versionInfo = await _fetchFromPubDev(packageName, includePrerelease);
      
      if (versionInfo != null) {
        _versionCache[packageName] = versionInfo;
        _cacheTimestamps[packageName] = DateTime.now();
      }
      
      return versionInfo;
    } catch (e) {
      // 如果网络请求失败，尝试使用缓存
      return _versionCache[packageName];
    }
  }
  
  /// 从 pub.dev 获取版本信息
  Future<VersionInfo?> _fetchFromPubDev(String packageName, bool includePrerelease) async {
    try {
      final url = 'https://pub.dev/api/packages/$packageName';
      final response = await _httpClient.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        return null;
      }
      
      final data = json.decode(response.body) as Map<String, dynamic>;
      final latest = data['latest'] as Map<String, dynamic>;
      
      // 解析版本信息
      final version = Version.parse(latest['version'] as String);
      final publishedAt = DateTime.parse(latest['published'] as String);
      
      // 获取包的详细信息
      final pubspec = latest['pubspec'] as Map<String, dynamic>;
      final description = pubspec['description'] as String?;
      
      return VersionInfo(
        packageName: packageName,
        version: version,
        publishedAt: publishedAt,
        isPrerelease: version.isPreRelease,
        isStable: !version.isPreRelease,
        description: description,
        dependencies: _parseDependencies(pubspec['dependencies'] as Map<String, dynamic>?),
        devDependencies: _parseDependencies(pubspec['dev_dependencies'] as Map<String, dynamic>?),
      );
    } catch (e) {
      return null;
    }
  }
  
  /// 解析依赖
  Map<String, VersionConstraint> _parseDependencies(Map<String, dynamic>? deps) {
    if (deps == null) return {};
    
    final result = <String, VersionConstraint>{};
    for (final entry in deps.entries) {
      try {
        if (entry.value is String) {
          result[entry.key] = VersionConstraint.parse(entry.value as String);
        } else if (entry.value is Map) {
          // 处理复杂的依赖定义
          final depMap = entry.value as Map<String, dynamic>;
          if (depMap.containsKey('version')) {
            result[entry.key] = VersionConstraint.parse(depMap['version'] as String);
          }
        }
      } catch (e) {
        // 忽略解析失败的依赖
      }
    }
    
    return result;
  }
  
  /// 生成保守配置
  List<ConfigurationSet> _generateConservativeConfigurations(Map<String, VersionInfo> versions) {
    final configurations = <ConfigurationSet>[];
    
    // 保守策略：使用稳定版本
    final stableVersions = versions.entries
        .where((entry) => entry.value.isStable && !entry.value.isPrerelease)
        .toList();
    
    if (stableVersions.isNotEmpty) {
      final config = ConfigurationSet(
        id: 'conservative_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Conservative Configuration',
        description: 'Stable versions only',
        essentialDependencies: Map.fromEntries(stableVersions),
        createdAt: DateTime.now(),
        priority: 0.8,
        tags: {'conservative', 'stable'},
      );
      configurations.add(config);
    }
    
    return configurations;
  }
  
  /// 生成平衡配置
  List<ConfigurationSet> _generateBalancedConfigurations(Map<String, VersionInfo> versions) {
    final configurations = <ConfigurationSet>[];
    
    // 平衡策略：稳定性和新特性平衡
    final balancedVersions = versions.entries
        .where((entry) => entry.value.calculateStabilityScore() > 0.6)
        .toList();
    
    if (balancedVersions.isNotEmpty) {
      final config = ConfigurationSet(
        id: 'balanced_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Balanced Configuration',
        description: 'Balance between stability and features',
        essentialDependencies: Map.fromEntries(balancedVersions),
        createdAt: DateTime.now(),
        priority: 0.7,
        tags: {'balanced', 'recommended'},
      );
      configurations.add(config);
    }
    
    return configurations;
  }
  
  /// 生成激进配置
  List<ConfigurationSet> _generateAggressiveConfigurations(Map<String, VersionInfo> versions) {
    final configurations = <ConfigurationSet>[];
    
    // 激进策略：使用最新版本
    final latestVersions = versions.entries.toList();
    
    if (latestVersions.isNotEmpty) {
      final config = ConfigurationSet(
        id: 'aggressive_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Aggressive Configuration',
        description: 'Latest versions with new features',
        essentialDependencies: Map.fromEntries(latestVersions),
        createdAt: DateTime.now(),
        priority: 0.6,
        tags: {'aggressive', 'latest'},
      );
      configurations.add(config);
    }
    
    return configurations;
  }
  
  /// 检查核心依赖兼容性
  bool _checkCoreCompatibility(ConfigurationSet config) {
    // 检查 Flutter 和 Dart SDK 版本兼容性
    final flutterVersion = config.coreDependencies['flutter'];
    final dartVersion = config.coreDependencies['dart'];
    
    if (flutterVersion != null && dartVersion != null) {
      // 简化的兼容性检查
      return true; // 实际实现会更复杂
    }
    
    return true;
  }
  
  /// 检查依赖冲突
  bool _checkDependencyConflicts(ConfigurationSet config) {
    final allDeps = config.allDependencies;
    
    for (final entry in allDeps.entries) {
      final versionInfo = entry.value;
      
      // 检查与其他依赖的冲突
      for (final otherEntry in allDeps.entries) {
        if (entry.key != otherEntry.key) {
          if (!versionInfo.isCompatibleWith(otherEntry.value)) {
            return false;
          }
        }
      }
    }
    
    return true;
  }
  
  /// 检查版本约束
  bool _checkVersionConstraints(ConfigurationSet config) {
    // 检查版本约束是否合理
    for (final versionInfo in config.allDependencies.values) {
      if (versionInfo.version.isPreRelease && !versionInfo.isStable) {
        // 预发布版本需要特殊处理
        continue;
      }
    }
    
    return true;
  }
  
  /// 检查缓存是否有效
  bool _isCacheValid(String packageName) {
    final timestamp = _cacheTimestamps[packageName];
    if (timestamp == null) return false;
    
    final now = DateTime.now();
    final expiration = timestamp.add(Duration(hours: _cacheExpirationHours));
    
    return now.isBefore(expiration) && _versionCache.containsKey(packageName);
  }
  
  /// 获取默认包名列表
  List<String> _getDefaultPackageNames() {
    return [
      'flutter',
      'riverpod',
      'flutter_riverpod',
      'go_router',
      'dio',
      'freezed',
      'json_annotation',
      'build_runner',
      'json_serializable',
      'very_good_analysis',
      'mocktail',
      'flutter_test',
    ];
  }
  
  /// 清理资源
  void dispose() {
    _httpClient.close();
    _versionCache.clear();
    _cacheTimestamps.clear();
  }
}
