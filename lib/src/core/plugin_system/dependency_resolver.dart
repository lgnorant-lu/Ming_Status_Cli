/*
---------------------------------------------------------------
File name:          dependency_resolver.dart
Author:             lgnorant-lu
Date created:       2025-07-25
Last modified:      2025-07-25
Dart Version:       3.2+
Description:        插件依赖解析器 (Plugin dependency resolver)
---------------------------------------------------------------
Change History:
    2025-07-25: Initial creation - 插件依赖解析核心逻辑;
---------------------------------------------------------------
*/

import 'dart:collection';

/// 插件依赖信息
class PluginDependency {
  /// 依赖插件ID
  final String pluginId;

  /// 版本约束
  final String versionConstraint;

  /// 是否为可选依赖
  final bool isOptional;

  /// 依赖描述
  final String? description;

  /// 构造函数
  const PluginDependency({
    required this.pluginId,
    required this.versionConstraint,
    this.isOptional = false,
    this.description,
  });

  /// 从Map创建
  factory PluginDependency.fromMap(Map<String, dynamic> map) {
    return PluginDependency(
      pluginId: map['id'] as String,
      versionConstraint: map['version'] as String,
      isOptional: map['optional'] as bool? ?? false,
      description: map['description'] as String?,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': pluginId,
      'version': versionConstraint,
      'optional': isOptional,
      'description': description,
    };
  }

  @override
  String toString() => 'PluginDependency($pluginId: $versionConstraint)';
}

/// 依赖解析结果
class DependencyResolutionResult {
  /// 是否解析成功
  final bool isSuccess;

  /// 安装顺序（拓扑排序后的插件列表）
  final List<String> installOrder;

  /// 缺失的依赖
  final List<PluginDependency> missingDependencies;

  /// 版本冲突
  final List<String> versionConflicts;

  /// 循环依赖
  final List<List<String>> circularDependencies;

  /// 错误信息
  final List<String> errors;

  /// 警告信息
  final List<String> warnings;

  /// 构造函数
  const DependencyResolutionResult({
    required this.isSuccess,
    this.installOrder = const [],
    this.missingDependencies = const [],
    this.versionConflicts = const [],
    this.circularDependencies = const [],
    this.errors = const [],
    this.warnings = const [],
  });

  /// 创建成功结果
  factory DependencyResolutionResult.success({
    required List<String> installOrder,
    List<String> warnings = const [],
  }) {
    return DependencyResolutionResult(
      isSuccess: true,
      installOrder: installOrder,
      warnings: warnings,
    );
  }

  /// 创建失败结果
  factory DependencyResolutionResult.failure({
    List<PluginDependency> missingDependencies = const [],
    List<String> versionConflicts = const [],
    List<List<String>> circularDependencies = const [],
    List<String> errors = const [],
  }) {
    return DependencyResolutionResult(
      isSuccess: false,
      missingDependencies: missingDependencies,
      versionConflicts: versionConflicts,
      circularDependencies: circularDependencies,
      errors: errors,
    );
  }
}

/// 插件信息
class PluginInfo {
  /// 插件ID
  final String id;

  /// 插件版本
  final String version;

  /// 依赖列表
  final List<PluginDependency> dependencies;

  /// 是否已安装
  final bool isInstalled;

  /// 构造函数
  const PluginInfo({
    required this.id,
    required this.version,
    this.dependencies = const [],
    this.isInstalled = false,
  });

  /// 从Map创建
  factory PluginInfo.fromMap(Map<String, dynamic> map) {
    final dependenciesData = map['dependencies'] as List<dynamic>? ?? [];
    final dependencies = dependenciesData
        .map((dep) => PluginDependency.fromMap(dep as Map<String, dynamic>))
        .toList();

    return PluginInfo(
      id: map['id'] as String,
      version: map['version'] as String,
      dependencies: dependencies,
      isInstalled: map['isInstalled'] as bool? ?? false,
    );
  }
}

/// 插件依赖解析器
///
/// 负责解析插件间的依赖关系，检测冲突，生成安装顺序。
class DependencyResolver {
  /// 解析插件依赖
  ///
  /// [targetPlugin] 目标插件
  /// [availablePlugins] 可用插件映射
  /// [installedPlugins] 已安装插件映射
  DependencyResolutionResult resolveDependencies({
    required PluginInfo targetPlugin,
    required Map<String, PluginInfo> availablePlugins,
    required Map<String, PluginInfo> installedPlugins,
  }) {
    try {
      // 1. 构建完整的依赖图
      final dependencyGraph = _buildDependencyGraph(
        targetPlugin,
        availablePlugins,
        installedPlugins,
      );

      // 2. 检查缺失依赖
      final missingDeps = _findMissingDependencies(
        dependencyGraph,
        availablePlugins,
      );

      if (missingDeps.isNotEmpty) {
        return DependencyResolutionResult.failure(
          missingDependencies: missingDeps,
          errors: ['存在缺失的依赖'],
        );
      }

      // 3. 检查版本冲突
      final versionConflicts = _detectVersionConflicts(
        dependencyGraph,
        availablePlugins,
        installedPlugins,
      );

      // 4. 检查循环依赖
      final circularDeps = _detectCircularDependencies(dependencyGraph);

      if (circularDeps.isNotEmpty) {
        return DependencyResolutionResult.failure(
          circularDependencies: circularDeps,
          errors: ['检测到循环依赖'],
        );
      }

      // 5. 生成安装顺序（拓扑排序）
      final installOrder = _generateInstallOrder(
        dependencyGraph,
        installedPlugins,
      );

      // 6. 生成警告信息
      final warnings = <String>[];
      if (versionConflicts.isNotEmpty) {
        warnings.addAll(versionConflicts.map((c) => '版本冲突: $c'));
      }

      return DependencyResolutionResult.success(
        installOrder: installOrder,
        warnings: warnings,
      );
    } catch (e) {
      return DependencyResolutionResult.failure(
        errors: ['依赖解析失败: $e'],
      );
    }
  }

  /// 构建依赖图
  Map<String, Set<String>> _buildDependencyGraph(
    PluginInfo targetPlugin,
    Map<String, PluginInfo> availablePlugins,
    Map<String, PluginInfo> installedPlugins,
  ) {
    final graph = <String, Set<String>>{};
    final visited = <String>{};

    void buildGraph(PluginInfo plugin) {
      if (visited.contains(plugin.id)) return;
      visited.add(plugin.id);

      graph[plugin.id] = <String>{};

      for (final dep in plugin.dependencies) {
        if (!dep.isOptional) {
          graph[plugin.id]!.add(dep.pluginId);

          // 递归构建依赖的依赖
          final depPlugin = availablePlugins[dep.pluginId] ??
              installedPlugins[dep.pluginId];
          if (depPlugin != null) {
            buildGraph(depPlugin);
          }
        }
      }
    }

    buildGraph(targetPlugin);
    return graph;
  }

  /// 查找缺失依赖
  List<PluginDependency> _findMissingDependencies(
    Map<String, Set<String>> dependencyGraph,
    Map<String, PluginInfo> availablePlugins,
  ) {
    final missing = <PluginDependency>[];

    for (final entry in dependencyGraph.entries) {
      final pluginId = entry.key;
      final deps = entry.value;

      for (final depId in deps) {
        if (!availablePlugins.containsKey(depId)) {
          missing.add(PluginDependency(
            pluginId: depId,
            versionConstraint: '*',
            description: '插件 $pluginId 的依赖',
          ));
        }
      }
    }

    return missing;
  }

  /// 检测版本冲突
  List<String> _detectVersionConflicts(
    Map<String, Set<String>> dependencyGraph,
    Map<String, PluginInfo> availablePlugins,
    Map<String, PluginInfo> installedPlugins,
  ) {
    final conflicts = <String>[];
    // TODO: 实现版本冲突检测逻辑
    return conflicts;
  }

  /// 检测循环依赖
  List<List<String>> _detectCircularDependencies(
    Map<String, Set<String>> dependencyGraph,
  ) {
    final cycles = <List<String>>[];
    final visited = <String>{};
    final recursionStack = <String>{};

    bool hasCycle(String node, List<String> path) {
      if (recursionStack.contains(node)) {
        // 找到循环，提取循环路径
        final cycleStart = path.indexOf(node);
        cycles.add(path.sublist(cycleStart) + [node]);
        return true;
      }

      if (visited.contains(node)) return false;

      visited.add(node);
      recursionStack.add(node);
      path.add(node);

      final neighbors = dependencyGraph[node] ?? <String>{};
      for (final neighbor in neighbors) {
        if (hasCycle(neighbor, List.from(path))) {
          return true;
        }
      }

      recursionStack.remove(node);
      return false;
    }

    for (final node in dependencyGraph.keys) {
      if (!visited.contains(node)) {
        hasCycle(node, []);
      }
    }

    return cycles;
  }

  /// 生成安装顺序（拓扑排序）
  List<String> _generateInstallOrder(
    Map<String, Set<String>> dependencyGraph,
    Map<String, PluginInfo> installedPlugins,
  ) {
    final inDegree = <String, int>{};
    final queue = Queue<String>();
    final result = <String>[];

    // 初始化入度
    for (final node in dependencyGraph.keys) {
      inDegree[node] = 0;
    }

    for (final entry in dependencyGraph.entries) {
      for (final neighbor in entry.value) {
        inDegree[neighbor] = (inDegree[neighbor] ?? 0) + 1;
      }
    }

    // 将入度为0的节点加入队列
    for (final entry in inDegree.entries) {
      if (entry.value == 0) {
        queue.add(entry.key);
      }
    }

    // 拓扑排序
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      
      // 只有未安装的插件才需要安装
      if (!installedPlugins.containsKey(current)) {
        result.add(current);
      }

      final neighbors = dependencyGraph[current] ?? <String>{};
      for (final neighbor in neighbors) {
        inDegree[neighbor] = inDegree[neighbor]! - 1;
        if (inDegree[neighbor] == 0) {
          queue.add(neighbor);
        }
      }
    }

    return result;
  }

  /// 检查版本兼容性
  bool isVersionCompatible(String version, String constraint) {
    // 简化的版本兼容性检查
    if (constraint == '*' || constraint == 'any') return true;
    if (constraint.startsWith('^')) {
      // 兼容版本检查
      final constraintVersion = constraint.substring(1);
      return _isCompatibleVersion(version, constraintVersion);
    }
    if (constraint.startsWith('>=')) {
      // 最小版本检查
      final minVersion = constraint.substring(2);
      return _compareVersions(version, minVersion) >= 0;
    }
    if (constraint.startsWith('<=')) {
      // 最大版本检查
      final maxVersion = constraint.substring(2);
      return _compareVersions(version, maxVersion) <= 0;
    }
    // 精确版本匹配
    return version == constraint;
  }

  /// 比较版本号
  int _compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();

    final maxLength = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;

    for (int i = 0; i < maxLength; i++) {
      final v1Part = i < v1Parts.length ? v1Parts[i] : 0;
      final v2Part = i < v2Parts.length ? v2Parts[i] : 0;

      if (v1Part < v2Part) return -1;
      if (v1Part > v2Part) return 1;
    }

    return 0;
  }

  /// 检查兼容版本
  bool _isCompatibleVersion(String version, String baseVersion) {
    final versionParts = version.split('.').map(int.parse).toList();
    final baseParts = baseVersion.split('.').map(int.parse).toList();

    if (versionParts.isEmpty || baseParts.isEmpty) return false;

    // 主版本必须相同
    if (versionParts[0] != baseParts[0]) return false;

    // 版本必须大于等于基础版本
    return _compareVersions(version, baseVersion) >= 0;
  }
}
