/*
---------------------------------------------------------------
File name:          conditional_renderer.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级条件渲染引擎 (Enterprise Conditional Renderer)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.1 条件模板生成系统;
---------------------------------------------------------------
*/

import 'dart:async';

import 'package:ming_status_cli/src/core/conditional/condition_evaluator.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 条件渲染上下文
///
/// 包含条件渲染过程中需要的上下文信息
class RenderContext {
  /// 创建渲染上下文实例
  const RenderContext({
    required this.variables,
    this.functions = const {},
    this.enableDebug = false,
    this.enableCache = true,
    this.maxNestingDepth = 10,
  });

  /// 变量映射
  final Map<String, dynamic> variables;

  /// 自定义函数映射
  final Map<String, Function> functions;

  /// 是否启用调试
  final bool enableDebug;

  /// 是否启用缓存
  final bool enableCache;

  /// 最大嵌套深度
  final int maxNestingDepth;
}

/// 条件块类型
///
/// 定义不同类型的条件块
enum ConditionalBlockType {
  /// if条件块
  ifBlock,

  /// unless条件块 (if的反向)
  unlessBlock,

  /// each循环块
  eachBlock,

  /// with作用域块
  withBlock,

  /// 自定义块
  customBlock,
}

/// 条件块
///
/// 表示模板中的一个条件块
class ConditionalBlock {
  /// 创建条件块实例
  const ConditionalBlock({
    required this.type,
    required this.condition,
    required this.content,
    this.elseContent,
    this.startPosition = 0,
    this.endPosition = 0,
  });

  /// 块类型
  final ConditionalBlockType type;

  /// 条件表达式
  final String condition;

  /// 主要内容
  final String content;

  /// else内容
  final String? elseContent;

  /// 开始位置
  final int startPosition;

  /// 结束位置
  final int endPosition;
}

/// 渲染结果
///
/// 包含条件渲染的结果信息
class RenderResult {
  /// 创建渲染结果实例
  const RenderResult({
    required this.success,
    required this.content,
    this.errors = const [],
    this.warnings = const [],
    this.debugInfo = const {},
  });

  /// 创建成功结果
  factory RenderResult.success({
    required String content,
    List<String> warnings = const [],
    Map<String, dynamic> debugInfo = const {},
  }) {
    return RenderResult(
      success: true,
      content: content,
      warnings: warnings,
      debugInfo: debugInfo,
    );
  }

  /// 创建失败结果
  factory RenderResult.failure({
    required List<String> errors,
    String content = '',
    List<String> warnings = const [],
  }) {
    return RenderResult(
      success: false,
      content: content,
      errors: errors,
      warnings: warnings,
    );
  }

  /// 是否成功
  final bool success;

  /// 渲染后的内容
  final String content;

  /// 错误列表
  final List<String> errors;

  /// 警告列表
  final List<String> warnings;

  /// 调试信息
  final Map<String, dynamic> debugInfo;
}

/// 自定义条件函数类型
typedef ConditionalFunction = Future<dynamic> Function(
  List<dynamic> args,
  Map<String, dynamic> context,
);

/// 预编译模板
class CompiledTemplate {
  const CompiledTemplate({
    required this.blocks,
    required this.compiledAt,
    this.metadata = const {},
  });

  final List<ConditionalBlock> blocks;
  final DateTime compiledAt;
  final Map<String, dynamic> metadata;
}

/// 渲染性能指标
class RenderPerformanceMetrics {
  const RenderPerformanceMetrics({
    required this.renderTime,
    required this.compilationTime,
    required this.evaluationTime,
    required this.cacheHits,
    required this.cacheMisses,
    required this.blocksProcessed,
  });

  final Duration renderTime;
  final Duration compilationTime;
  final Duration evaluationTime;
  final int cacheHits;
  final int cacheMisses;
  final int blocksProcessed;
}

/// 企业级条件渲染引擎
///
/// 支持扩展Handlebars语法、嵌套条件、自定义函数、性能优化
class ConditionalRenderer {
  /// 创建条件渲染引擎实例
  ConditionalRenderer({
    required this.conditionEvaluator,
    this.enableCache = true,
    this.enablePrecompilation = true,
    this.maxCacheSize = 1000,
    this.enablePerformanceTracking = false,
  });

  /// 条件求值器
  final ConditionEvaluator conditionEvaluator;

  /// 是否启用缓存
  final bool enableCache;

  /// 是否启用预编译
  final bool enablePrecompilation;

  /// 最大缓存大小
  final int maxCacheSize;

  /// 是否启用性能追踪
  final bool enablePerformanceTracking;

  /// 渲染结果缓存
  final Map<String, RenderResult> _cache = {};

  /// 预编译模板缓存
  final Map<String, CompiledTemplate> _compiledTemplates = {};

  /// 自定义条件函数注册表
  final Map<String, ConditionalFunction> _customFunctions = {};

  /// 性能指标
  final List<RenderPerformanceMetrics> _performanceMetrics = [];

  /// 缓存统计
  final Map<String, int> _cacheStats = {
    'hits': 0,
    'misses': 0,
    'compilations': 0,
    'evictions': 0,
  };

  /// 注册自定义条件函数
  ///
  /// 允许注册自定义的条件函数供模板使用
  void registerFunction(String name, ConditionalFunction function) {
    _customFunctions[name] = function;
    cli_logger.Logger.debug('注册自定义条件函数: $name');
  }

  /// 注销自定义条件函数
  void unregisterFunction(String name) {
    _customFunctions.remove(name);
    cli_logger.Logger.debug('注销自定义条件函数: $name');
  }

  /// 获取已注册的函数列表
  List<String> getRegisteredFunctions() {
    return _customFunctions.keys.toList();
  }

  /// 预编译模板
  ///
  /// 将模板预编译为条件块列表以提高渲染性能
  Future<CompiledTemplate> compileTemplate(String template) async {
    final startTime = DateTime.now();

    try {
      final blocks = await _parseConditionalBlocks(template);
      final compiledTemplate = CompiledTemplate(
        blocks: blocks,
        compiledAt: DateTime.now(),
        metadata: {
          'originalLength': template.length,
          'blocksCount': blocks.length,
          'compilationTime':
              DateTime.now().difference(startTime).inMilliseconds,
        },
      );

      _cacheStats['compilations'] = (_cacheStats['compilations'] ?? 0) + 1;
      cli_logger.Logger.debug('模板预编译完成: ${blocks.length}个块');

      return compiledTemplate;
    } catch (e) {
      cli_logger.Logger.error('模板预编译失败', error: e);
      rethrow;
    }
  }

  /// 清理缓存
  ///
  /// 清理渲染缓存和预编译缓存
  void clearCache() {
    _cache.clear();
    _compiledTemplates.clear();
    _cacheStats.clear();
    _performanceMetrics.clear();
    cli_logger.Logger.debug('条件渲染器缓存已清理');
  }

  /// 获取缓存统计
  Map<String, dynamic> getCacheStats() {
    return {
      ..._cacheStats,
      'cacheSize': _cache.length,
      'compiledTemplatesSize': _compiledTemplates.length,
      'customFunctionsCount': _customFunctions.length,
      'performanceMetricsCount': _performanceMetrics.length,
    };
  }

  /// 获取性能指标
  List<RenderPerformanceMetrics> getPerformanceMetrics() {
    return List.unmodifiable(_performanceMetrics);
  }

  /// 渲染模板
  ///
  /// 根据上下文渲染包含条件语法的模板，支持预编译和性能追踪
  Future<RenderResult> render(
    String template,
    RenderContext context,
  ) async {
    final startTime = DateTime.now();
    var compilationTime = Duration.zero;
    var evaluationTime = Duration.zero;
    var cacheHits = 0;
    var cacheMisses = 0;
    var blocksProcessed = 0;

    try {
      cli_logger.Logger.debug('开始条件渲染: ${template.length}字符');

      // 生成缓存键
      final cacheKey = _generateCacheKey(template, context);

      // 检查缓存
      if (enableCache && context.enableCache && _cache.containsKey(cacheKey)) {
        cacheHits++;
        _cacheStats['hits'] = (_cacheStats['hits'] ?? 0) + 1;
        cli_logger.Logger.debug('使用缓存的渲染结果: $cacheKey');
        return _cache[cacheKey]!;
      }

      cacheMisses++;
      _cacheStats['misses'] = (_cacheStats['misses'] ?? 0) + 1;

      // 1. 获取或编译模板
      CompiledTemplate? compiledTemplate;
      if (enablePrecompilation && _compiledTemplates.containsKey(cacheKey)) {
        compiledTemplate = _compiledTemplates[cacheKey];
      } else {
        final compileStart = DateTime.now();
        compiledTemplate = await compileTemplate(template);
        compilationTime = DateTime.now().difference(compileStart);

        if (enablePrecompilation) {
          _compiledTemplates[cacheKey] = compiledTemplate;
          _manageCacheSize();
        }
      }

      final blocks = compiledTemplate!.blocks;
      blocksProcessed = blocks.length;

      // 2. 渲染条件块
      final evalStart = DateTime.now();
      final renderedContent = await _renderBlocks(template, blocks, context);
      evaluationTime = DateTime.now().difference(evalStart);

      // 3. 后处理
      final finalContent = await _postProcess(renderedContent, context);

      final debugInfo = context.enableDebug
          ? {
              'blocksCount': blocks.length,
              'templateLength': template.length,
              'cacheKey': cacheKey,
              'compilationTime': compilationTime.inMicroseconds,
              'evaluationTime': evaluationTime.inMicroseconds,
              'cacheHits': cacheHits,
              'cacheMisses': cacheMisses,
            }
          : <String, dynamic>{};

      final result = RenderResult.success(
        content: finalContent,
        debugInfo: debugInfo,
      );

      // 缓存结果
      if (enableCache && context.enableCache) {
        _cache[cacheKey] = result;
        _manageCacheSize();
      }

      // 记录性能指标
      if (enablePerformanceTracking) {
        final totalTime = DateTime.now().difference(startTime);
        _performanceMetrics.add(
          RenderPerformanceMetrics(
            renderTime: totalTime,
            compilationTime: compilationTime,
            evaluationTime: evaluationTime,
            cacheHits: cacheHits,
            cacheMisses: cacheMisses,
            blocksProcessed: blocksProcessed,
          ),
        );
      }

      cli_logger.Logger.debug('条件渲染完成: ${blocks.length}个条件块');
      return result;
    } catch (e) {
      cli_logger.Logger.error('条件渲染失败', error: e);
      return RenderResult.failure(
        errors: ['条件渲染异常: $e'],
      );
    }
  }

  /// 管理缓存大小
  ///
  /// 当缓存超过最大大小时，清理最旧的条目
  void _manageCacheSize() {
    if (_cache.length > maxCacheSize) {
      final keysToRemove =
          _cache.keys.take(_cache.length - maxCacheSize).toList();
      for (final key in keysToRemove) {
        _cache.remove(key);
      }
      _cacheStats['evictions'] =
          (_cacheStats['evictions'] ?? 0) + keysToRemove.length;
    }

    if (_compiledTemplates.length > maxCacheSize) {
      final keysToRemove = _compiledTemplates.keys
          .take(_compiledTemplates.length - maxCacheSize)
          .toList();
      for (final key in keysToRemove) {
        _compiledTemplates.remove(key);
      }
    }
  }

  /// 生成缓存键
  ///
  /// 基于模板内容和上下文生成唯一的缓存键
  String _generateCacheKey(String template, RenderContext context) {
    final contextHash = context.variables.toString().hashCode;
    final templateHash = template.hashCode;
    return '${templateHash}_$contextHash';
  }

  /// 解析条件块
  ///
  /// 从模板中解析出所有条件块
  Future<List<ConditionalBlock>> _parseConditionalBlocks(
    String template,
  ) async {
    final blocks = <ConditionalBlock>[];

    // 正则表达式匹配条件块
    final patterns = {
      ConditionalBlockType.ifBlock: RegExp(
        r'\{\{#if\s+([^}]+)\}\}(.*?)\{\{/if\}\}',
        multiLine: true,
        dotAll: true,
      ),
      ConditionalBlockType.unlessBlock: RegExp(
        r'\{\{#unless\s+([^}]+)\}\}(.*?)\{\{/unless\}\}',
        multiLine: true,
        dotAll: true,
      ),
      ConditionalBlockType.eachBlock: RegExp(
        r'\{\{#each\s+([^}]+)\}\}(.*?)\{\{/each\}\}',
        multiLine: true,
        dotAll: true,
      ),
      ConditionalBlockType.withBlock: RegExp(
        r'\{\{#with\s+([^}]+)\}\}(.*?)\{\{/with\}\}',
        multiLine: true,
        dotAll: true,
      ),
    };

    for (final entry in patterns.entries) {
      final type = entry.key;
      final pattern = entry.value;

      final matches = pattern.allMatches(template);
      for (final match in matches) {
        final condition = match.group(1)?.trim() ?? '';
        final content = match.group(2) ?? '';

        blocks.add(
          ConditionalBlock(
            type: type,
            condition: condition,
            content: content,
            startPosition: match.start,
            endPosition: match.end,
          ),
        );
      }
    }

    // 按位置排序
    blocks.sort((a, b) => a.startPosition.compareTo(b.startPosition));

    return blocks;
  }

  /// 渲染条件块
  ///
  /// 根据条件求值结果渲染块内容
  Future<String> _renderBlocks(
    String template,
    List<ConditionalBlock> blocks,
    RenderContext context,
  ) async {
    var result = template;

    // 从后往前处理，避免位置偏移
    for (final block in blocks.reversed) {
      final renderedBlock = await _renderSingleBlock(block, context);

      result = result.replaceRange(
        block.startPosition,
        block.endPosition,
        renderedBlock,
      );
    }

    return result;
  }

  /// 渲染单个条件块
  ///
  /// 根据块类型和条件渲染单个块
  Future<String> _renderSingleBlock(
    ConditionalBlock block,
    RenderContext context,
  ) async {
    switch (block.type) {
      case ConditionalBlockType.ifBlock:
        return _renderIfBlock(block, context);

      case ConditionalBlockType.unlessBlock:
        return _renderUnlessBlock(block, context);

      case ConditionalBlockType.eachBlock:
        return _renderEachBlock(block, context);

      case ConditionalBlockType.withBlock:
        return _renderWithBlock(block, context);

      case ConditionalBlockType.customBlock:
        return _renderCustomBlock(block, context);
    }
  }

  /// 渲染if块
  Future<String> _renderIfBlock(
    ConditionalBlock block,
    RenderContext context,
  ) async {
    final conditionResult = await conditionEvaluator.evaluate(
      block.condition,
      context.variables,
    );

    if (conditionResult.success && conditionResult.value == true) {
      return block.content;
    } else {
      return block.elseContent ?? '';
    }
  }

  /// 渲染unless块
  Future<String> _renderUnlessBlock(
    ConditionalBlock block,
    RenderContext context,
  ) async {
    final conditionResult = await conditionEvaluator.evaluate(
      block.condition,
      context.variables,
    );

    if (conditionResult.success && conditionResult.value != true) {
      return block.content;
    } else {
      return block.elseContent ?? '';
    }
  }

  /// 渲染each块
  Future<String> _renderEachBlock(
    ConditionalBlock block,
    RenderContext context,
  ) async {
    final arrayResult = await conditionEvaluator.evaluate(
      block.condition,
      context.variables,
    );

    if (!arrayResult.success || arrayResult.value is! List) {
      return '';
    }

    final array = arrayResult.value as List;
    final buffer = StringBuffer();

    for (var i = 0; i < array.length; i++) {
      final item = array[i];
      final itemContext = RenderContext(
        variables: {
          ...context.variables,
          'this': item,
          '@index': i,
          '@first': i == 0,
          '@last': i == array.length - 1,
        },
        functions: context.functions,
        enableDebug: context.enableDebug,
        enableCache: context.enableCache,
      );

      // 递归渲染内容
      final itemResult = await render(block.content, itemContext);
      if (itemResult.success) {
        buffer.write(itemResult.content);
      }
    }

    return buffer.toString();
  }

  /// 渲染with块
  Future<String> _renderWithBlock(
    ConditionalBlock block,
    RenderContext context,
  ) async {
    final objectResult = await conditionEvaluator.evaluate(
      block.condition,
      context.variables,
    );

    if (!objectResult.success || objectResult.value is! Map) {
      return '';
    }

    final object = objectResult.value as Map<String, dynamic>;
    final withContext = RenderContext(
      variables: {
        ...context.variables,
        ...object,
      },
      functions: context.functions,
      enableDebug: context.enableDebug,
      enableCache: context.enableCache,
    );

    // 递归渲染内容
    final result = await render(block.content, withContext);
    return result.success ? result.content : '';
  }

  /// 渲染自定义块
  Future<String> _renderCustomBlock(
    ConditionalBlock block,
    RenderContext context,
  ) async {
    // 自定义块处理逻辑
    return block.content;
  }

  /// 后处理
  ///
  /// 对渲染结果进行后处理
  Future<String> _postProcess(String content, RenderContext context) async {
    // 移除多余的空行
    var processed = content.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');

    // 处理变量替换
    processed = await _processVariableSubstitution(processed, context);

    return processed;
  }

  /// 处理变量替换
  Future<String> _processVariableSubstitution(
    String content,
    RenderContext context,
  ) async {
    final variablePattern = RegExp(r'\{\{([^#/][^}]*)\}\}');

    return content.replaceAllMapped(variablePattern, (match) {
      final variableName = match.group(1)?.trim() ?? '';
      final value = _getVariableValue(variableName, context.variables);
      return value?.toString() ?? '';
    });
  }

  /// 获取变量值
  dynamic _getVariableValue(String path, Map<String, dynamic> variables) {
    final parts = path.split('.');
    dynamic current = variables;

    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }

    return current;
  }
}
