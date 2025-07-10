/*
---------------------------------------------------------------
File name:          composition_engine.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级模板组合引擎 (Enterprise Template Composition Engine)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.1 模板组合和合并系统;
---------------------------------------------------------------
*/

import 'dart:async';

import 'package:ming_status_cli/src/core/inheritance/inheritance_engine.dart';
import 'package:ming_status_cli/src/core/template_system/advanced_template.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 文件合并策略
///
/// 定义不同文件类型的合并策略
enum FileMergeStrategy {
  /// 覆盖策略 - 子文件完全覆盖父文件
  override,

  /// 合并策略 - 智能合并文件内容
  merge,

  /// 追加策略 - 在父文件内容后追加
  append,

  /// 前置策略 - 在父文件内容前插入
  prepend,

  /// 跳过策略 - 保持父文件不变
  skip,
}

/// 组合配置
///
/// 定义模板组合的配置参数
class CompositionConfig {
  /// 创建组合配置实例
  const CompositionConfig({
    this.defaultStrategy = FileMergeStrategy.merge,
    this.fileStrategies = const {},
    this.enableAsyncProcessing = true,
    this.enableParallelProcessing = true,
    this.maxParallelTasks = 4,
    this.enableValidation = true,
  });

  /// 默认合并策略
  final FileMergeStrategy defaultStrategy;

  /// 文件特定策略映射 (文件扩展名 -> 策略)
  final Map<String, FileMergeStrategy> fileStrategies;

  /// 是否启用异步处理
  final bool enableAsyncProcessing;

  /// 是否启用并行处理
  final bool enableParallelProcessing;

  /// 最大并行任务数
  final int maxParallelTasks;

  /// 是否启用验证
  final bool enableValidation;
}

/// 组合片段
///
/// 表示模板组合中的一个片段
class CompositionFragment {
  /// 创建组合片段实例
  const CompositionFragment({
    required this.templateId,
    required this.filePath,
    required this.content,
    this.metadata = const {},
    this.priority = 0,
  });

  /// 模板ID
  final String templateId;

  /// 文件路径
  final String filePath;

  /// 文件内容
  final String content;

  /// 元数据
  final Map<String, dynamic> metadata;

  /// 优先级 (数值越大优先级越高)
  final int priority;
}

/// 插槽系统
///
/// 支持模板片段的插槽机制
class SlotSystem {
  /// 创建插槽系统实例
  SlotSystem() : _slots = {};

  /// 插槽映射 (插槽名 -> 片段列表)
  final Map<String, List<CompositionFragment>> _slots;

  /// 注册插槽
  void registerSlot(String slotName, CompositionFragment fragment) {
    _slots.putIfAbsent(slotName, () => []).add(fragment);
  }

  /// 获取插槽内容
  List<CompositionFragment> getSlotContent(String slotName) {
    return _slots[slotName] ?? [];
  }

  /// 合并插槽内容
  String mergeSlotContent(String slotName, {String separator = '\n'}) {
    final fragments = getSlotContent(slotName);
    fragments.sort((a, b) => b.priority.compareTo(a.priority));
    return fragments.map((f) => f.content).join(separator);
  }

  /// 清理插槽
  void clearSlots() {
    _slots.clear();
  }
}

/// 组合结果
///
/// 包含模板组合的结果信息
class CompositionResult {
  /// 创建组合结果实例
  const CompositionResult({
    required this.success,
    this.composedTemplate,
    this.appliedStrategies = const {},
    this.processedFiles = const [],
    this.errors = const [],
    this.warnings = const [],
    this.performance,
  });

  /// 创建成功结果
  factory CompositionResult.success({
    required AdvancedTemplate composedTemplate,
    Map<String, FileMergeStrategy> appliedStrategies = const {},
    List<String> processedFiles = const [],
    List<String> warnings = const [],
    PerformanceMetrics? performance,
  }) {
    return CompositionResult(
      success: true,
      composedTemplate: composedTemplate,
      appliedStrategies: appliedStrategies,
      processedFiles: processedFiles,
      warnings: warnings,
      performance: performance,
    );
  }

  /// 创建失败结果
  factory CompositionResult.failure({
    required List<String> errors,
    List<String> warnings = const [],
    List<String> processedFiles = const [],
  }) {
    return CompositionResult(
      success: false,
      processedFiles: processedFiles,
      errors: errors,
      warnings: warnings,
    );
  }

  /// 是否成功
  final bool success;

  /// 组合后的模板
  final AdvancedTemplate? composedTemplate;

  /// 应用的策略映射
  final Map<String, FileMergeStrategy> appliedStrategies;

  /// 处理的文件列表
  final List<String> processedFiles;

  /// 错误列表
  final List<String> errors;

  /// 警告列表
  final List<String> warnings;

  /// 性能指标
  final PerformanceMetrics? performance;
}

/// 企业级模板组合引擎
///
/// 智能文件合并、模板片段组合、插槽系统、异步并行处理
class CompositionEngine {
  /// 创建组合引擎实例
  CompositionEngine({
    this.config = const CompositionConfig(),
  });

  /// 组合配置
  final CompositionConfig config;

  /// 插槽系统
  final SlotSystem _slotSystem = SlotSystem();

  /// 组合模板
  ///
  /// 根据继承链组合模板内容
  Future<CompositionResult> composeTemplates(
    List<InheritanceNode> inheritanceChain,
    InheritanceContext context,
  ) async {
    final startTime = DateTime.now();

    try {
      cli_logger.Logger.info(
        '开始组合模板 (${inheritanceChain.length}个模板)',
      );

      // 1. 收集所有模板片段
      final fragments = await _collectTemplateFragments(inheritanceChain);

      // 2. 按文件路径分组
      final fileGroups = _groupFragmentsByFile(fragments);

      // 3. 处理文件合并
      final mergedFiles = <String, String>{};
      final appliedStrategies = <String, FileMergeStrategy>{};
      final processedFiles = <String>[];
      final warnings = <String>[];

      for (final entry in fileGroups.entries) {
        final filePath = entry.key;
        final fileFragments = entry.value;

        try {
          final strategy = _determineFileStrategy(filePath);
          final mergedContent = await _mergeFileFragments(
            fileFragments,
            strategy,
          );

          mergedFiles[filePath] = mergedContent;
          appliedStrategies[filePath] = strategy;
          processedFiles.add(filePath);

          cli_logger.Logger.debug(
            '文件合并完成: $filePath (策略: ${strategy.name})',
          );
        } catch (e) {
          warnings.add('文件合并警告: $filePath - $e');
          cli_logger.Logger.warning('文件合并失败: $filePath - $e');
        }
      }

      // 4. 创建组合后的模板
      final composedTemplate = await _createComposedTemplate(
        inheritanceChain.first.template,
        mergedFiles,
      );

      // 5. 验证组合结果
      if (config.enableValidation) {
        final validationWarnings =
            await _validateComposedTemplate(composedTemplate);
        warnings.addAll(validationWarnings);
      }

      final endTime = DateTime.now();
      final performance = PerformanceMetrics(
        startTime: startTime,
        endTime: endTime,
        memoryUsage: _estimateMemoryUsage(mergedFiles),
        fileOperations: processedFiles.length,
      );

      cli_logger.Logger.success(
        '模板组合完成: ${processedFiles.length}个文件处理, '
        '${performance.executionTimeMs}ms',
      );

      return CompositionResult.success(
        composedTemplate: composedTemplate,
        appliedStrategies: appliedStrategies,
        processedFiles: processedFiles,
        warnings: warnings,
        performance: performance,
      );
    } catch (e) {
      cli_logger.Logger.error('模板组合失败', error: e);
      return CompositionResult.failure(
        errors: ['模板组合异常: $e'],
      );
    }
  }

  /// 收集模板片段
  Future<List<CompositionFragment>> _collectTemplateFragments(
    List<InheritanceNode> inheritanceChain,
  ) async {
    final fragments = <CompositionFragment>[];

    for (final node in inheritanceChain) {
      // 这里需要实际的模板文件读取逻辑
      // 暂时创建示例片段
      final fragment = CompositionFragment(
        templateId: node.templateId,
        filePath: 'example.dart',
        content: '// Template: ${node.template.metadata.name}\n',
        priority: node.depth,
      );

      fragments.add(fragment);
    }

    return fragments;
  }

  /// 按文件路径分组片段
  Map<String, List<CompositionFragment>> _groupFragmentsByFile(
    List<CompositionFragment> fragments,
  ) {
    final groups = <String, List<CompositionFragment>>{};

    for (final fragment in fragments) {
      groups.putIfAbsent(fragment.filePath, () => []).add(fragment);
    }

    return groups;
  }

  /// 确定文件合并策略
  FileMergeStrategy _determineFileStrategy(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    return config.fileStrategies[extension] ?? config.defaultStrategy;
  }

  /// 合并文件片段
  Future<String> _mergeFileFragments(
    List<CompositionFragment> fragments,
    FileMergeStrategy strategy,
  ) async {
    // 按优先级排序
    fragments.sort((a, b) => a.priority.compareTo(b.priority));

    switch (strategy) {
      case FileMergeStrategy.override:
        return fragments.last.content;

      case FileMergeStrategy.merge:
        return _intelligentMerge(fragments);

      case FileMergeStrategy.append:
        return fragments.map((f) => f.content).join('\n');

      case FileMergeStrategy.prepend:
        return fragments.reversed.map((f) => f.content).join('\n');

      case FileMergeStrategy.skip:
        return fragments.first.content;
    }
  }

  /// 智能合并
  String _intelligentMerge(List<CompositionFragment> fragments) {
    // 简化的智能合并逻辑
    final mergedContent = StringBuffer();

    for (final fragment in fragments) {
      mergedContent
        ..writeln('// From: ${fragment.templateId}')
        ..writeln(fragment.content)
        ..writeln();
    }

    return mergedContent.toString();
  }

  /// 创建组合后的模板
  Future<AdvancedTemplate> _createComposedTemplate(
    AdvancedTemplate baseTemplate,
    Map<String, String> mergedFiles,
  ) async {
    // 这里需要实际的模板创建逻辑
    // 暂时返回基础模板
    return baseTemplate;
  }

  /// 验证组合后的模板
  Future<List<String>> _validateComposedTemplate(
    AdvancedTemplate template,
  ) async {
    final warnings = <String>[];

    // 简化的验证逻辑
    if (template.metadata.dependencies.isEmpty) {
      warnings.add('组合后的模板没有依赖项');
    }

    return warnings;
  }

  /// 估算内存使用量
  int _estimateMemoryUsage(Map<String, String> mergedFiles) {
    return mergedFiles.values
        .map((content) => content.length)
        .fold(0, (sum, length) => sum + length);
  }

  /// 清理资源
  void cleanup() {
    _slotSystem.clearSlots();
    cli_logger.Logger.debug('组合引擎资源已清理');
  }
}
