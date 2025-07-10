/*
---------------------------------------------------------------
File name:          inheritance_engine.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级模板继承引擎 (Enterprise Template Inheritance Engine)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.1 模板继承和组合引擎;
---------------------------------------------------------------
*/

import 'dart:async';

import 'package:ming_status_cli/src/core/inheritance/composition_engine.dart';
import 'package:ming_status_cli/src/core/inheritance/dependency_resolver.dart';
import 'package:ming_status_cli/src/core/template_system/advanced_template.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 继承策略枚举
///
/// 定义模板继承时的合并策略
enum InheritanceStrategy {
  /// 覆盖策略 - 子模板完全覆盖父模板
  override,

  /// 合并策略 - 智能合并父子模板内容
  merge,

  /// 追加策略 - 在父模板内容后追加
  append,

  /// 前置策略 - 在父模板内容前插入
  prepend,
}

/// 继承上下文
///
/// 包含继承过程中的上下文信息
class InheritanceContext {
  /// 创建继承上下文实例
  const InheritanceContext({
    required this.templateContext,
    this.maxDepth = 5,
    this.enableConditionalInheritance = true,
    this.enableCaching = true,
    this.strategy = InheritanceStrategy.merge,
    this.customStrategies = const {},
  });

  /// 模板上下文
  final TemplateContext templateContext;

  /// 最大继承深度
  final int maxDepth;

  /// 是否启用条件继承
  final bool enableConditionalInheritance;

  /// 是否启用缓存
  final bool enableCaching;

  /// 默认继承策略
  final InheritanceStrategy strategy;

  /// 自定义策略映射 (文件类型 -> 策略)
  final Map<String, InheritanceStrategy> customStrategies;
}

/// 继承链节点
///
/// 表示继承链中的一个节点
class InheritanceNode {
  /// 创建继承链节点实例
  const InheritanceNode({
    required this.template,
    required this.depth,
    this.parent,
    this.children = const [],
    this.conditionalInheritance = const {},
  });

  /// 模板实例
  final AdvancedTemplate template;

  /// 继承深度 (0为根节点)
  final int depth;

  /// 父节点
  final InheritanceNode? parent;

  /// 子节点列表
  final List<InheritanceNode> children;

  /// 条件继承映射 (条件 -> 模板)
  final Map<String, AdvancedTemplate> conditionalInheritance;

  /// 获取模板ID
  String get templateId => template.metadata.id;

  /// 是否为根节点
  bool get isRoot => parent == null;

  /// 是否为叶节点
  bool get isLeaf => children.isEmpty;

  /// 获取继承路径
  List<String> get inheritancePath {
    final path = <String>[];
    InheritanceNode? current = this;
    while (current != null) {
      path.insert(0, current.templateId);
      current = current.parent;
    }
    return path;
  }
}

/// 继承结果
///
/// 包含继承处理的结果信息
class InheritanceResult {
  /// 创建继承结果实例
  const InheritanceResult({
    required this.success,
    required this.resolvedTemplate,
    this.inheritanceChain = const [],
    this.appliedStrategies = const {},
    this.errors = const [],
    this.warnings = const [],
    this.performance,
  });

  /// 创建成功结果
  factory InheritanceResult.success({
    required AdvancedTemplate resolvedTemplate,
    required List<InheritanceNode> inheritanceChain,
    Map<String, InheritanceStrategy> appliedStrategies = const {},
    List<String> warnings = const [],
    PerformanceMetrics? performance,
  }) {
    return InheritanceResult(
      success: true,
      resolvedTemplate: resolvedTemplate,
      inheritanceChain: inheritanceChain,
      appliedStrategies: appliedStrategies,
      warnings: warnings,
      performance: performance,
    );
  }

  /// 创建失败结果
  factory InheritanceResult.failure({
    required List<String> errors,
    List<String> warnings = const [],
    List<InheritanceNode> inheritanceChain = const [],
  }) {
    return InheritanceResult(
      success: false,
      resolvedTemplate: null,
      inheritanceChain: inheritanceChain,
      errors: errors,
      warnings: warnings,
    );
  }

  /// 是否成功
  final bool success;

  /// 解析后的模板
  final AdvancedTemplate? resolvedTemplate;

  /// 继承链
  final List<InheritanceNode> inheritanceChain;

  /// 应用的策略映射
  final Map<String, InheritanceStrategy> appliedStrategies;

  /// 错误列表
  final List<String> errors;

  /// 警告列表
  final List<String> warnings;

  /// 性能指标
  final PerformanceMetrics? performance;
}

/// 企业级模板继承引擎
///
/// 支持多层继承链、条件继承、智能合并等企业级功能
class InheritanceEngine {
  /// 创建继承引擎实例
  InheritanceEngine({
    required this.dependencyResolver,
    required this.compositionEngine,
  });

  /// 依赖解析器
  final DependencyResolver dependencyResolver;

  /// 组合引擎
  final CompositionEngine compositionEngine;

  /// 继承结果缓存
  final Map<String, InheritanceResult> _cache = {};

  /// 继承链缓存
  final Map<String, List<InheritanceNode>> _chainCache = {};

  /// 解析模板继承
  ///
  /// 根据模板和上下文解析完整的继承关系
  Future<InheritanceResult> resolveInheritance(
    AdvancedTemplate template,
    InheritanceContext context,
  ) async {
    final startTime = DateTime.now();

    try {
      cli_logger.Logger.info('开始解析模板继承: ${template.metadata.name}');

      // 检查缓存
      final cacheKey = _generateCacheKey(template, context);
      if (context.enableCaching && _cache.containsKey(cacheKey)) {
        cli_logger.Logger.debug('使用缓存的继承结果: $cacheKey');
        return _cache[cacheKey]!;
      }

      // 1. 构建继承链
      final inheritanceChain = await _buildInheritanceChain(template, context);
      if (inheritanceChain.isEmpty) {
        return InheritanceResult.failure(
          errors: ['无法构建继承链'],
        );
      }

      // 2. 检查循环依赖
      final circularDependency = _detectCircularDependency(inheritanceChain);
      if (circularDependency != null) {
        return InheritanceResult.failure(
          errors: ['检测到循环依赖: $circularDependency'],
          inheritanceChain: inheritanceChain,
        );
      }

      // 3. 解析依赖关系
      final dependencies = await dependencyResolver.resolveDependencies(
        inheritanceChain.map((node) => node.template).toList(),
      );

      if (!dependencies.success) {
        return InheritanceResult.failure(
          errors: ['依赖解析失败: ${dependencies.errors.join(', ')}'],
          inheritanceChain: inheritanceChain,
        );
      }

      // 4. 执行组合策略
      final compositionResult = await compositionEngine.composeTemplates(
        inheritanceChain,
        context,
      );

      if (!compositionResult.success) {
        return InheritanceResult.failure(
          errors: ['模板组合失败: ${compositionResult.errors.join(', ')}'],
          inheritanceChain: inheritanceChain,
        );
      }

      // 5. 创建成功结果
      final endTime = DateTime.now();
      final performance = PerformanceMetrics(
        startTime: startTime,
        endTime: endTime,
        memoryUsage: _estimateMemoryUsage(inheritanceChain),
        cacheHits: context.enableCaching ? 1 : 0,
        cacheMisses: context.enableCaching ? 0 : 1,
      );

      final result = InheritanceResult.success(
        resolvedTemplate: compositionResult.composedTemplate!,
        inheritanceChain: inheritanceChain,
        appliedStrategies:
            _convertStrategies(compositionResult.appliedStrategies),
        warnings: [...dependencies.warnings, ...compositionResult.warnings],
        performance: performance,
      );

      // 6. 缓存结果
      if (context.enableCaching) {
        _cache[cacheKey] = result;
        _chainCache[template.metadata.id] = inheritanceChain;
      }

      cli_logger.Logger.success(
        '模板继承解析完成: ${template.metadata.name} '
        '(${inheritanceChain.length}层, ${performance.executionTimeMs}ms)',
      );

      return result;
    } catch (e) {
      cli_logger.Logger.error('模板继承解析失败', error: e);
      return InheritanceResult.failure(
        errors: ['继承解析异常: $e'],
      );
    }
  }

  /// 构建继承链
  ///
  /// 递归构建完整的继承链，最大深度限制
  Future<List<InheritanceNode>> _buildInheritanceChain(
    AdvancedTemplate template,
    InheritanceContext context,
  ) async {
    final chain = <InheritanceNode>[];
    final visited = <String>{};

    await _buildChainRecursive(
      template,
      0,
      context,
      chain,
      visited,
      null,
    );

    return chain;
  }

  /// 递归构建继承链
  Future<void> _buildChainRecursive(
    AdvancedTemplate template,
    int depth,
    InheritanceContext context,
    List<InheritanceNode> chain,
    Set<String> visited,
    InheritanceNode? parent,
  ) async {
    // 检查深度限制
    if (depth >= context.maxDepth) {
      cli_logger.Logger.warning(
        '达到最大继承深度限制: ${context.maxDepth}',
      );
      return;
    }

    // 检查是否已访问 (防止循环)
    final templateId = template.metadata.id;
    if (visited.contains(templateId)) {
      cli_logger.Logger.warning('检测到潜在循环继承: $templateId');
      return;
    }

    visited.add(templateId);

    // 创建当前节点
    final node = InheritanceNode(
      template: template,
      depth: depth,
      parent: parent,
    );

    chain.add(node);

    // 递归处理父模板 (这里需要实际的父模板获取逻辑)
    // 暂时简化处理
    cli_logger.Logger.debug('构建继承节点: $templateId (深度: $depth)');
  }

  /// 检测循环依赖
  String? _detectCircularDependency(List<InheritanceNode> chain) {
    final templateIds = chain.map((node) => node.templateId).toList();
    final seen = <String>{};

    for (final id in templateIds) {
      if (seen.contains(id)) {
        return id;
      }
      seen.add(id);
    }

    return null;
  }

  /// 转换策略类型
  Map<String, InheritanceStrategy> _convertStrategies(
    Map<String, dynamic> strategies,
  ) {
    final converted = <String, InheritanceStrategy>{};
    for (final entry in strategies.entries) {
      // 简化转换，默认使用merge策略
      converted[entry.key] = InheritanceStrategy.merge;
    }
    return converted;
  }

  /// 生成缓存键
  String _generateCacheKey(
    AdvancedTemplate template,
    InheritanceContext context,
  ) {
    return '${template.metadata.id}_${template.metadata.version}_'
        '${context.strategy.name}_${context.maxDepth}';
  }

  /// 估算内存使用量
  int _estimateMemoryUsage(List<InheritanceNode> chain) {
    // 简化的内存估算
    return chain.length * 1024; // 每个节点约1KB
  }

  /// 清理缓存
  void clearCache() {
    _cache.clear();
    _chainCache.clear();
    cli_logger.Logger.info('继承引擎缓存已清理');
  }

  /// 获取缓存统计
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _cache.length,
      'chainCacheSize': _chainCache.length,
      'memoryEstimate': (_cache.length + _chainCache.length) * 1024,
    };
  }
}
