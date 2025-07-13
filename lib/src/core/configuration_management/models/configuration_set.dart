/*
---------------------------------------------------------------
File name:          configuration_set.dart
Author:             lgnorant-lu
Date created:       2025/07/13
Last modified:      2025/07/13
Dart Version:       3.2+
Description:        配置集合模型 (Configuration Set Model)
---------------------------------------------------------------
Change History:
    2025/07/13: Initial creation - 企业级模板配置管理系统;
---------------------------------------------------------------
*/
import 'package:ming_status_cli/src/core/configuration_management/models/version_info.dart';

/// 测试层级枚举
enum TestLayer {
  /// 核心依赖 (Flutter SDK, Dart SDK)
  core,
  /// 必需依赖 (riverpod, go_router)
  essential,
  /// 可选依赖 (firebase, dio)
  optional,
  /// 开发依赖 (build_runner, lints)
  dev,
}

/// 配置集合模型
/// 
/// 表示一组依赖配置的组合，用于测试和验证
class ConfigurationSet {
  
  /// 创建配置集合实例
  const ConfigurationSet({
    required this.id,
    required this.name,
    required this.createdAt, this.description,
    this.coreDependencies = const {},
    this.essentialDependencies = const {},
    this.optionalDependencies = const {},
    this.devDependencies = const {},
    this.priority = 0.5,
    this.isTested = false,
    this.testPassed,
    this.tags = const {},
  });
  
  /// 从JSON创建配置集合实例
  factory ConfigurationSet.fromJson(Map<String, dynamic> json) {
    return ConfigurationSet(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      coreDependencies: _parseVersionInfoMap(json['coreDependencies'] as Map<String, dynamic>?),
      essentialDependencies: _parseVersionInfoMap(json['essentialDependencies'] as Map<String, dynamic>?),
      optionalDependencies: _parseVersionInfoMap(json['optionalDependencies'] as Map<String, dynamic>?),
      devDependencies: _parseVersionInfoMap(json['devDependencies'] as Map<String, dynamic>?),
      createdAt: DateTime.parse(json['createdAt'] as String),
      priority: (json['priority'] as num?)?.toDouble() ?? 0.5,
      isTested: json['isTested'] as bool? ?? false,
      testPassed: json['testPassed'] as bool?,
      tags: Set<String>.from(json['tags'] as List? ?? []),
    );
  }
  /// 配置集合ID
  final String id;
  
  /// 配置名称
  final String name;
  
  /// 配置描述
  final String? description;
  
  /// 核心依赖 (SDK版本等)
  final Map<String, VersionInfo> coreDependencies;
  
  /// 必需依赖
  final Map<String, VersionInfo> essentialDependencies;
  
  /// 可选依赖
  final Map<String, VersionInfo> optionalDependencies;
  
  /// 开发依赖
  final Map<String, VersionInfo> devDependencies;
  
  /// 配置创建时间
  final DateTime createdAt;
  
  /// 配置优先级 (0-1之间，1表示最高优先级)
  final double priority;
  
  /// 是否已测试
  final bool isTested;
  
  /// 测试通过状态
  final bool? testPassed;
  
  /// 配置标签
  final Set<String> tags;
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coreDependencies': _versionInfoMapToJson(coreDependencies),
      'essentialDependencies': _versionInfoMapToJson(essentialDependencies),
      'optionalDependencies': _versionInfoMapToJson(optionalDependencies),
      'devDependencies': _versionInfoMapToJson(devDependencies),
      'createdAt': createdAt.toIso8601String(),
      'priority': priority,
      'isTested': isTested,
      'testPassed': testPassed,
      'tags': tags.toList(),
    };
  }
  
  /// 创建副本
  ConfigurationSet copyWith({
    String? id,
    String? name,
    String? description,
    Map<String, VersionInfo>? coreDependencies,
    Map<String, VersionInfo>? essentialDependencies,
    Map<String, VersionInfo>? optionalDependencies,
    Map<String, VersionInfo>? devDependencies,
    DateTime? createdAt,
    double? priority,
    bool? isTested,
    bool? testPassed,
    Set<String>? tags,
  }) {
    return ConfigurationSet(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coreDependencies: coreDependencies ?? this.coreDependencies,
      essentialDependencies: essentialDependencies ?? this.essentialDependencies,
      optionalDependencies: optionalDependencies ?? this.optionalDependencies,
      devDependencies: devDependencies ?? this.devDependencies,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
      isTested: isTested ?? this.isTested,
      testPassed: testPassed ?? this.testPassed,
      tags: tags ?? this.tags,
    );
  }
  
  /// 获取所有依赖
  Map<String, VersionInfo> get allDependencies {
    return {
      ...coreDependencies,
      ...essentialDependencies,
      ...optionalDependencies,
      ...devDependencies,
    };
  }
  
  /// 获取指定层级的依赖
  Map<String, VersionInfo> getDependenciesByLayer(TestLayer layer) {
    switch (layer) {
      case TestLayer.core:
        return coreDependencies;
      case TestLayer.essential:
        return essentialDependencies;
      case TestLayer.optional:
        return optionalDependencies;
      case TestLayer.dev:
        return devDependencies;
    }
  }
  
  /// 添加依赖到指定层级
  ConfigurationSet addDependency(TestLayer layer, String packageName, VersionInfo versionInfo) {
    final newDependencies = Map<String, VersionInfo>.from(getDependenciesByLayer(layer));
    newDependencies[packageName] = versionInfo;
    
    switch (layer) {
      case TestLayer.core:
        return copyWith(coreDependencies: newDependencies);
      case TestLayer.essential:
        return copyWith(essentialDependencies: newDependencies);
      case TestLayer.optional:
        return copyWith(optionalDependencies: newDependencies);
      case TestLayer.dev:
        return copyWith(devDependencies: newDependencies);
    }
  }
  
  /// 移除指定依赖
  ConfigurationSet removeDependency(String packageName) {
    return copyWith(
      coreDependencies: Map.from(coreDependencies)..remove(packageName),
      essentialDependencies: Map.from(essentialDependencies)..remove(packageName),
      optionalDependencies: Map.from(optionalDependencies)..remove(packageName),
      devDependencies: Map.from(devDependencies)..remove(packageName),
    );
  }
  
  /// 计算配置复杂度
  int get complexity {
    return coreDependencies.length +
           essentialDependencies.length +
           optionalDependencies.length +
           devDependencies.length;
  }
  
  /// 计算配置稳定性评分
  double calculateStabilityScore() {
    if (allDependencies.isEmpty) return 1;
    
    final scores = allDependencies.values.map((v) => v.calculateStabilityScore());
    return scores.reduce((a, b) => a + b) / scores.length;
  }
  
  /// 计算配置新鲜度评分
  double calculateFreshnessScore() {
    if (allDependencies.isEmpty) return 1;
    
    final scores = allDependencies.values.map((v) => v.calculateFreshness());
    return scores.reduce((a, b) => a + b) / scores.length;
  }
  
  /// 生成配置哈希（用于缓存键）
  String generateHash() {
    final dependencies = allDependencies.entries
        .map((e) => '${e.key}:${e.value.version}')
        .toList()
      ..sort();
    
    return dependencies.join(',').hashCode.toString();
  }
  
  /// 检查是否与另一个配置兼容
  bool isCompatibleWith(ConfigurationSet other) {
    // 检查所有依赖的兼容性
    for (final entry in allDependencies.entries) {
      final packageName = entry.key;
      final versionInfo = entry.value;
      
      if (other.allDependencies.containsKey(packageName)) {
        final otherVersionInfo = other.allDependencies[packageName]!;
        if (!versionInfo.isCompatibleWith(otherVersionInfo)) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  /// 合并两个配置集合
  ConfigurationSet merge(ConfigurationSet other) {
    return ConfigurationSet(
      id: '${id}_merged_${other.id}',
      name: '$name + ${other.name}',
      description: 'Merged configuration: $description + ${other.description}',
      coreDependencies: {...coreDependencies, ...other.coreDependencies},
      essentialDependencies: {...essentialDependencies, ...other.essentialDependencies},
      optionalDependencies: {...optionalDependencies, ...other.optionalDependencies},
      devDependencies: {...devDependencies, ...other.devDependencies},
      createdAt: DateTime.now(),
      priority: (priority + other.priority) / 2,
      tags: {...tags, ...other.tags},
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConfigurationSet && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() {
    return 'ConfigurationSet(id: $id, name: $name, complexity: $complexity, '
           'priority: $priority, isTested: $isTested, testPassed: $testPassed)';
  }
  
  /// 解析版本信息映射
  static Map<String, VersionInfo> _parseVersionInfoMap(Map<String, dynamic>? json) {
    if (json == null) return {};
    
    return json.map((key, value) {
      return MapEntry(key, VersionInfo.fromJson(value as Map<String, dynamic>));
    });
  }
  
  /// 版本信息映射转JSON
  static Map<String, Map<String, dynamic>> _versionInfoMapToJson(Map<String, VersionInfo> map) {
    return map.map((key, value) {
      return MapEntry(key, value.toJson());
    });
  }
}
