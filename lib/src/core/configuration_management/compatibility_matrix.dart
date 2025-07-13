/*
---------------------------------------------------------------
File name:          compatibility_matrix.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        兼容性矩阵 (Compatibility Matrix)
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - 企业级模板配置管理系统;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/configuration_management/models/configuration_set.dart';
import 'package:ming_status_cli/src/core/configuration_management/models/version_info.dart';
import 'package:ming_status_cli/src/core/configuration_management/update_strategy.dart';
import 'package:pub_semver/pub_semver.dart';

/// 兼容性规则模型
class CompatibilityRule {
  
  /// 创建兼容性规则
  const CompatibilityRule({
    required this.packageName,
    required this.versionConstraint,
    this.requires = const {},
    this.conflicts = const {},
    this.description,
    this.priority = 0,
  });
  /// 包名
  final String packageName;
  
  /// 版本约束
  final VersionConstraint versionConstraint;
  
  /// 必需的依赖
  final Map<String, VersionConstraint> requires;
  
  /// 冲突的依赖
  final Map<String, VersionConstraint> conflicts;
  
  /// 规则描述
  final String? description;
  
  /// 规则优先级
  final int priority;
  
  /// 检查版本是否匹配此规则
  bool matches(VersionInfo versionInfo) {
    return packageName == versionInfo.packageName &&
           versionConstraint.allows(versionInfo.version);
  }
  
  /// 检查是否与其他版本信息兼容
  bool isCompatibleWith(Map<String, VersionInfo> versions) {
    // 检查必需依赖
    for (final entry in requires.entries) {
      final requiredPackage = entry.key;
      final requiredConstraint = entry.value;
      
      final versionInfo = versions[requiredPackage];
      if (versionInfo == null || 
          !requiredConstraint.allows(versionInfo.version)) {
        return false;
      }
    }
    
    // 检查冲突依赖
    for (final entry in conflicts.entries) {
      final conflictPackage = entry.key;
      final conflictConstraint = entry.value;
      
      final versionInfo = versions[conflictPackage];
      if (versionInfo != null && 
          conflictConstraint.allows(versionInfo.version)) {
        return false;
      }
    }
    
    return true;
  }
}

/// 兼容性矩阵
/// 
/// 提供快速兼容性检查和配置推荐功能
class CompatibilityMatrix {
  
  /// 创建兼容性矩阵
  CompatibilityMatrix({List<CompatibilityRule>? rules})
      : _rules = rules ?? _getDefaultRules();
  /// 兼容性规则列表
  final List<CompatibilityRule> _rules;
  
  /// 快速兼容性检查
  /// 
  /// 检查配置集合是否兼容
  bool isCompatible(ConfigurationSet config) {
    final allVersions = config.allDependencies;
    
    // 检查每个依赖的兼容性规则
    for (final versionInfo in allVersions.values) {
      final applicableRules = _getApplicableRules(versionInfo);
      
      for (final rule in applicableRules) {
        if (!rule.isCompatibleWith(allVersions)) {
          return false;
        }
      }
    }
    
    // 检查依赖间的直接冲突
    return _checkDirectConflicts(allVersions);
  }
  
  /// 生成推荐配置
  /// 
  /// 基于兼容性规则生成推荐的配置组合
  ConfigurationSet generateRecommendedConfig(
    Map<String, VersionInfo> availableVersions,
    TestStrategy strategy,
  ) {
    final recommendedVersions = <String, VersionInfo>{};
    
    // 按优先级排序包
    final sortedPackages = _sortPackagesByPriority(availableVersions.keys);
    
    for (final packageName in sortedPackages) {
      final availableVersion = availableVersions[packageName];
      if (availableVersion == null) continue;
      
      // 检查是否与已选择的版本兼容
      final testVersions = Map<String, VersionInfo>.from(recommendedVersions);
      testVersions[packageName] = availableVersion;
      
      if (_isVersionSetCompatible(testVersions)) {
        recommendedVersions[packageName] = availableVersion;
      }
    }
    
    return ConfigurationSet(
      id: 'recommended_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Recommended Configuration',
      description: 'Auto-generated compatible configuration',
      essentialDependencies: recommendedVersions,
      createdAt: DateTime.now(),
      priority: 0.9,
      tags: {'recommended', 'compatible', strategy.name},
    );
  }
  
  /// 获取兼容性问题
  /// 
  /// 返回配置中的兼容性问题列表
  List<String> getCompatibilityIssues(ConfigurationSet config) {
    final issues = <String>[];
    final allVersions = config.allDependencies;
    
    for (final versionInfo in allVersions.values) {
      final applicableRules = _getApplicableRules(versionInfo);
      
      for (final rule in applicableRules) {
        if (!rule.isCompatibleWith(allVersions)) {
          issues.add(_formatCompatibilityIssue(rule, versionInfo, allVersions));
        }
      }
    }
    
    // 检查直接冲突
    final conflicts = _findDirectConflicts(allVersions);
    issues.addAll(conflicts);
    
    return issues;
  }
  
  /// 添加自定义规则
  void addRule(CompatibilityRule rule) {
    _rules.add(rule);
    _rules.sort((a, b) => b.priority.compareTo(a.priority));
  }
  
  /// 移除规则
  void removeRule(String packageName, VersionConstraint constraint) {
    _rules.removeWhere((rule) => 
        rule.packageName == packageName && 
        rule.versionConstraint == constraint,);
  }
  
  /// 获取适用的规则
  List<CompatibilityRule> _getApplicableRules(VersionInfo versionInfo) {
    return _rules.where((rule) => rule.matches(versionInfo)).toList();
  }
  
  /// 检查直接冲突
  bool _checkDirectConflicts(Map<String, VersionInfo> versions) {
    final packages = versions.keys.toList();
    
    for (var i = 0; i < packages.length; i++) {
      for (var j = i + 1; j < packages.length; j++) {
        final version1 = versions[packages[i]]!;
        final version2 = versions[packages[j]]!;
        
        if (!version1.isCompatibleWith(version2)) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  /// 查找直接冲突
  List<String> _findDirectConflicts(Map<String, VersionInfo> versions) {
    final conflicts = <String>[];
    final packages = versions.keys.toList();
    
    for (var i = 0; i < packages.length; i++) {
      for (var j = i + 1; j < packages.length; j++) {
        final package1 = packages[i];
        final package2 = packages[j];
        final version1 = versions[package1]!;
        final version2 = versions[package2]!;
        
        if (!version1.isCompatibleWith(version2)) {
          conflicts.add(
            'Conflict between $package1 v${version1.version} '
            'and $package2 v${version2.version}',
          );
        }
      }
    }
    
    return conflicts;
  }
  
  /// 检查版本集合兼容性
  bool _isVersionSetCompatible(Map<String, VersionInfo> versions) {
    for (final versionInfo in versions.values) {
      final applicableRules = _getApplicableRules(versionInfo);
      
      for (final rule in applicableRules) {
        if (!rule.isCompatibleWith(versions)) {
          return false;
        }
      }
    }
    
    return _checkDirectConflicts(versions);
  }
  
  /// 按优先级排序包
  List<String> _sortPackagesByPriority(Iterable<String> packages) {
    final packageList = packages.toList();
    
    // 定义包的优先级
    const priorities = {
      'flutter': 100,
      'dart': 99,
      'flutter_test': 98,
      'flutter_riverpod': 90,
      'riverpod': 89,
      'go_router': 85,
      'dio': 80,
      'freezed': 75,
      'json_annotation': 70,
      'build_runner': 60,
      'json_serializable': 55,
      'very_good_analysis': 50,
    };
    
    packageList.sort((a, b) {
      final priorityA = priorities[a] ?? 0;
      final priorityB = priorities[b] ?? 0;
      return priorityB.compareTo(priorityA);
    });
    
    return packageList;
  }
  
  /// 格式化兼容性问题
  String _formatCompatibilityIssue(
    CompatibilityRule rule,
    VersionInfo versionInfo,
    Map<String, VersionInfo> allVersions,
  ) {
    final buffer = StringBuffer();
    buffer.write('${rule.packageName} v${versionInfo.version} ');
    
    // 检查缺失的必需依赖
    for (final entry in rule.requires.entries) {
      final requiredPackage = entry.key;
      final requiredConstraint = entry.value;
      final actualVersion = allVersions[requiredPackage];
      
      if (actualVersion == null) {
        buffer.write('requires $requiredPackage $requiredConstraint (missing)');
      } else if (!requiredConstraint.allows(actualVersion.version)) {
        buffer.write(
          'requires $requiredPackage $requiredConstraint '
          '(found v${actualVersion.version})',
        );
      }
    }
    
    // 检查冲突依赖
    for (final entry in rule.conflicts.entries) {
      final conflictPackage = entry.key;
      final conflictConstraint = entry.value;
      final actualVersion = allVersions[conflictPackage];
      
      if (actualVersion != null && 
          conflictConstraint.allows(actualVersion.version)) {
        buffer.write(
          'conflicts with $conflictPackage v${actualVersion.version}',
        );
      }
    }
    
    return buffer.toString();
  }
  
  /// 获取默认兼容性规则
  static List<CompatibilityRule> _getDefaultRules() {
    return [
      // Flutter SDK 规则
      CompatibilityRule(
        packageName: 'flutter',
        versionConstraint: VersionConstraint.parse('>=3.16.0'),
        requires: {
          'dart': VersionConstraint.parse('>=3.2.0'),
        },
        description: 'Flutter requires compatible Dart SDK',
        priority: 100,
      ),
      
      // Riverpod 规则
      CompatibilityRule(
        packageName: 'flutter_riverpod',
        versionConstraint: VersionConstraint.parse('^2.0.0'),
        requires: {
          'riverpod': VersionConstraint.parse('^2.0.0'),
        },
        description: 'flutter_riverpod requires compatible riverpod',
        priority: 90,
      ),
      
      // JSON 序列化规则
      CompatibilityRule(
        packageName: 'freezed',
        versionConstraint: VersionConstraint.parse('^2.0.0'),
        requires: {
          'json_annotation': VersionConstraint.parse('^4.0.0'),
          'build_runner': VersionConstraint.parse('^2.0.0'),
        },
        description: 'Freezed requires json_annotation and build_runner',
        priority: 75,
      ),
      
      // 代码生成规则
      CompatibilityRule(
        packageName: 'json_serializable',
        versionConstraint: VersionConstraint.parse('^6.0.0'),
        requires: {
          'json_annotation': VersionConstraint.parse('^4.0.0'),
          'build_runner': VersionConstraint.parse('^2.0.0'),
        },
        description: 'json_serializable requires compatible dependencies',
        priority: 70,
      ),
      
      // 测试框架规则
      CompatibilityRule(
        packageName: 'mocktail',
        versionConstraint: VersionConstraint.parse('^1.0.0'),
        conflicts: {
          'mockito': VersionConstraint.parse('>=5.0.0'),
        },
        description: 'mocktail conflicts with newer mockito versions',
        priority: 60,
      ),
    ];
  }
}
