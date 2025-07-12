/*
---------------------------------------------------------------
File name:          dependency_resolver.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级依赖解析器 (Enterprise Dependency Resolver)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.1 模板依赖解析系统;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_system/advanced_template.dart';
import 'package:ming_status_cli/src/core/template_system/template_metadata.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 依赖图节点
///
/// 表示依赖图中的一个节点
class DependencyNode {
  /// 创建依赖图节点实例
  DependencyNode({
    required this.template,
    this.dependencies = const [],
    this.dependents = const [],
    this.resolved = false,
  });

  /// 模板实例
  final AdvancedTemplate template;

  /// 依赖的模板列表
  final List<DependencyNode> dependencies;

  /// 依赖此模板的模板列表
  final List<DependencyNode> dependents;

  /// 是否已解析
  bool resolved;

  /// 获取模板ID
  String get templateId => template.metadata.id;

  /// 获取模板名称
  String get templateName => template.metadata.name;

  /// 获取模板版本
  String get templateVersion => template.metadata.version;
}

/// 依赖图
///
/// 表示模板间的依赖关系图
class DependencyGraph {
  /// 创建依赖图实例
  DependencyGraph() : _nodes = {};

  /// 节点映射 (模板ID -> 节点)
  final Map<String, DependencyNode> _nodes;

  /// 获取所有节点
  List<DependencyNode> get nodes => _nodes.values.toList();

  /// 获取节点数量
  int get nodeCount => _nodes.length;

  /// 是否为空
  bool get isEmpty => _nodes.isEmpty;

  /// 添加节点
  void addNode(DependencyNode node) {
    _nodes[node.templateId] = node;
  }

  /// 获取节点
  DependencyNode? getNode(String templateId) {
    return _nodes[templateId];
  }

  /// 添加依赖关系
  void addDependency(String fromId, String toId) {
    final fromNode = _nodes[fromId];
    final toNode = _nodes[toId];

    if (fromNode != null && toNode != null) {
      fromNode.dependencies.add(toNode);
      toNode.dependents.add(fromNode);
    }
  }

  /// 检测循环依赖
  List<String>? detectCycles() {
    final visited = <String>{};
    final recursionStack = <String>{};

    for (final node in _nodes.values) {
      if (!visited.contains(node.templateId)) {
        final cycle = _detectCyclesDFS(node, visited, recursionStack, []);
        if (cycle != null) {
          return cycle;
        }
      }
    }

    return null;
  }

  /// 深度优先搜索检测循环
  List<String>? _detectCyclesDFS(
    DependencyNode node,
    Set<String> visited,
    Set<String> recursionStack,
    List<String> path,
  ) {
    visited.add(node.templateId);
    recursionStack.add(node.templateId);
    path.add(node.templateId);

    for (final dependency in node.dependencies) {
      if (!visited.contains(dependency.templateId)) {
        final cycle =
            _detectCyclesDFS(dependency, visited, recursionStack, path);
        if (cycle != null) {
          return cycle;
        }
      } else if (recursionStack.contains(dependency.templateId)) {
        // 找到循环
        final cycleStart = path.indexOf(dependency.templateId);
        return path.sublist(cycleStart)..add(dependency.templateId);
      }
    }

    recursionStack.remove(node.templateId);
    path.removeLast();
    return null;
  }

  /// 拓扑排序
  List<DependencyNode> topologicalSort() {
    // final result = <DependencyNode>[];  // 未使用，注释掉
    final visited = <String>{};
    final stack = <DependencyNode>[];

    for (final node in _nodes.values) {
      if (!visited.contains(node.templateId)) {
        _topologicalSortDFS(node, visited, stack);
      }
    }

    return stack.reversed.toList();
  }

  /// 拓扑排序深度优先搜索
  void _topologicalSortDFS(
    DependencyNode node,
    Set<String> visited,
    List<DependencyNode> stack,
  ) {
    visited.add(node.templateId);

    for (final dependency in node.dependencies) {
      if (!visited.contains(dependency.templateId)) {
        _topologicalSortDFS(dependency, visited, stack);
      }
    }

    stack.add(node);
  }
}

/// 依赖解析结果
///
/// 包含依赖解析的结果信息
class DependencyResolutionResult {
  /// 创建依赖解析结果实例
  const DependencyResolutionResult({
    required this.success,
    this.dependencyGraph,
    this.resolvedOrder = const [],
    this.conflicts = const [],
    this.errors = const [],
    this.warnings = const [],
  });

  /// 创建成功结果
  factory DependencyResolutionResult.success({
    required DependencyGraph dependencyGraph,
    required List<DependencyNode> resolvedOrder,
    List<String> conflicts = const [],
    List<String> warnings = const [],
  }) {
    return DependencyResolutionResult(
      success: true,
      dependencyGraph: dependencyGraph,
      resolvedOrder: resolvedOrder,
      conflicts: conflicts,
      warnings: warnings,
    );
  }

  /// 创建失败结果
  factory DependencyResolutionResult.failure({
    required List<String> errors,
    List<String> warnings = const [],
    DependencyGraph? dependencyGraph,
  }) {
    return DependencyResolutionResult(
      success: false,
      dependencyGraph: dependencyGraph,
      errors: errors,
      warnings: warnings,
    );
  }

  /// 是否成功
  final bool success;

  /// 依赖图
  final DependencyGraph? dependencyGraph;

  /// 解析顺序
  final List<DependencyNode> resolvedOrder;

  /// 依赖冲突列表
  final List<String> conflicts;

  /// 错误列表
  final List<String> errors;

  /// 警告列表
  final List<String> warnings;
}

/// 企业级依赖解析器
///
/// 智能依赖图构建、拓扑排序、循环依赖检测、版本兼容性检查
class DependencyResolver {
  /// 创建依赖解析器实例
  DependencyResolver({
    this.enableVersionCheck = true,
    this.enableConflictResolution = true,
    this.maxResolutionDepth = 10,
  });

  /// 是否启用版本检查
  final bool enableVersionCheck;

  /// 是否启用冲突解决
  final bool enableConflictResolution;

  /// 最大解析深度
  final int maxResolutionDepth;

  /// 解析依赖关系
  ///
  /// 构建依赖图并进行拓扑排序
  Future<DependencyResolutionResult> resolveDependencies(
    List<AdvancedTemplate> templates,
  ) async {
    try {
      cli_logger.Logger.info('开始解析模板依赖关系 (${templates.length}个模板)');

      // 1. 构建依赖图
      final dependencyGraph = await _buildDependencyGraph(templates);

      // 2. 检测循环依赖
      final cycles = dependencyGraph.detectCycles();
      if (cycles != null && cycles.isNotEmpty) {
        return DependencyResolutionResult.failure(
          errors: ['检测到循环依赖: ${cycles.join(' -> ')}'],
          dependencyGraph: dependencyGraph,
        );
      }

      // 3. 版本兼容性检查
      final versionConflicts = enableVersionCheck
          ? await _checkVersionCompatibility(dependencyGraph)
          : <String>[];

      // 4. 拓扑排序
      final resolvedOrder = dependencyGraph.topologicalSort();

      // 5. 依赖冲突检查
      final dependencyConflicts =
          await _checkDependencyConflicts(dependencyGraph);

      final allConflicts = [...versionConflicts, ...dependencyConflicts];
      final warnings = <String>[];

      // 6. 冲突解决
      if (allConflicts.isNotEmpty && enableConflictResolution) {
        final resolutionResult =
            await _resolveConflicts(dependencyGraph, allConflicts);
        warnings.addAll(resolutionResult);
      }

      cli_logger.Logger.success(
        '依赖解析完成: ${resolvedOrder.length}个模板已排序, '
        '${allConflicts.length}个冲突',
      );

      return DependencyResolutionResult.success(
        dependencyGraph: dependencyGraph,
        resolvedOrder: resolvedOrder,
        conflicts: allConflicts,
        warnings: warnings,
      );
    } catch (e) {
      cli_logger.Logger.error('依赖解析失败', error: e);
      return DependencyResolutionResult.failure(
        errors: ['依赖解析异常: $e'],
      );
    }
  }

  /// 构建依赖图
  Future<DependencyGraph> _buildDependencyGraph(
    List<AdvancedTemplate> templates,
  ) async {
    final graph = DependencyGraph();

    // 添加所有节点
    for (final template in templates) {
      final node = DependencyNode(template: template);
      graph.addNode(node);
    }

    // 添加依赖关系
    for (final template in templates) {
      for (final dependency in template.dependencies) {
        final dependentNode = graph.getNode(template.metadata.id);
        final dependencyNode = graph.getNode(dependency.name);

        if (dependentNode != null && dependencyNode != null) {
          graph.addDependency(template.metadata.id, dependency.name);
        } else {
          cli_logger.Logger.warning(
            '未找到依赖模板: ${dependency.name} (被 ${template.metadata.name} 依赖)',
          );
        }
      }
    }

    cli_logger.Logger.debug('依赖图构建完成: ${graph.nodeCount}个节点');
    return graph;
  }

  /// 检查版本兼容性
  Future<List<String>> _checkVersionCompatibility(DependencyGraph graph) async {
    final conflicts = <String>[];

    for (final node in graph.nodes) {
      for (final dependency in node.dependencies) {
        // 简化的版本检查逻辑
        final requiredDep = node.template.dependencies
            .firstWhere((dep) => dep.name == dependency.templateId);

        if (!_isVersionCompatible(
          dependency.templateVersion,
          requiredDep.version,
        )) {
          conflicts.add(
            '版本冲突: ${node.templateName} 需要 ${dependency.templateName} '
            '版本 ${requiredDep.version}, 但找到版本 ${dependency.templateVersion}',
          );
        }
      }
    }

    return conflicts;
  }

  /// 检查依赖冲突
  Future<List<String>> _checkDependencyConflicts(DependencyGraph graph) async {
    final conflicts = <String>[];

    // 检查可选依赖和条件依赖
    for (final node in graph.nodes) {
      final optionalDeps = node.template.dependencies
          .where((dep) => dep.type == DependencyType.optional)
          .toList();

      for (final optionalDep in optionalDeps) {
        final depNode = graph.getNode(optionalDep.name);
        if (depNode == null) {
          cli_logger.Logger.debug(
            '可选依赖未找到: ${optionalDep.name} (${node.templateName})',
          );
        }
      }
    }

    return conflicts;
  }

  /// 解决冲突
  Future<List<String>> _resolveConflicts(
    DependencyGraph graph,
    List<String> conflicts,
  ) async {
    final resolutions = <String>[];

    for (final conflict in conflicts) {
      // 简化的冲突解决逻辑
      if (conflict.contains('版本冲突')) {
        resolutions.add('尝试使用最新兼容版本解决版本冲突');
      } else if (conflict.contains('循环依赖')) {
        resolutions.add('建议重构模板以消除循环依赖');
      }
    }

    return resolutions;
  }

  /// 检查版本兼容性
  bool _isVersionCompatible(String actualVersion, String requiredVersion) {
    // 简化的版本兼容性检查
    // 实际实现应该支持SemVer规范
    return actualVersion == requiredVersion ||
        requiredVersion.startsWith('^') ||
        requiredVersion.startsWith('~') ||
        requiredVersion.contains('>=');
  }
}
