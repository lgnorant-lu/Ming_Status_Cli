/*
---------------------------------------------------------------
File name:          advanced_template.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级高级模板基类 (Enterprise Advanced Template Base)
---------------------------------------------------------------
Change History:    
    2025/07/10: Initial creation - Phase 2.1 高级模板系统架构;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_system/template_metadata.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';
import 'package:ming_status_cli/src/models/template_variable.dart';

/// 模板上下文
///
/// 包含模板生成过程中需要的上下文信息
class TemplateContext {
  /// 创建模板上下文实例
  const TemplateContext({
    required this.workingDirectory,
    required this.targetPlatform,
    this.environment = const {},
    this.userPreferences = const {},
    this.projectConfig = const {},
  });

  /// 工作目录
  final String workingDirectory;

  /// 目标平台
  final TemplatePlatform targetPlatform;

  /// 环境变量
  final Map<String, String> environment;

  /// 用户偏好设置
  final Map<String, dynamic> userPreferences;

  /// 项目配置
  final Map<String, dynamic> projectConfig;
}

/// 生成上下文
///
/// 包含模板生成过程中的具体参数和配置
class GenerationContext {
  /// 创建生成上下文实例
  const GenerationContext({
    required this.templateContext,
    required this.parameters,
    required this.outputPath,
    this.overwriteExisting = false,
    this.dryRun = false,
    this.hooks = const [],
  });

  /// 模板上下文
  final TemplateContext templateContext;

  /// 生成参数
  final Map<String, dynamic> parameters;

  /// 输出路径
  final String outputPath;

  /// 是否覆盖现有文件
  final bool overwriteExisting;

  /// 是否为试运行
  final bool dryRun;

  /// 生成钩子列表
  final List<GenerationHook> hooks;
}

/// 生成结果
///
/// 包含模板生成的结果信息
class GenerationResult {
  /// 创建生成结果实例
  const GenerationResult({
    required this.success,
    required this.generatedFiles,
    this.errors = const [],
    this.warnings = const [],
    this.metadata = const {},
    this.performance,
  });

  /// 创建成功结果
  factory GenerationResult.success({
    required List<String> generatedFiles,
    List<String> warnings = const [],
    Map<String, dynamic> metadata = const {},
    PerformanceMetrics? performance,
  }) {
    return GenerationResult(
      success: true,
      generatedFiles: generatedFiles,
      warnings: warnings,
      metadata: metadata,
      performance: performance,
    );
  }

  /// 创建失败结果
  factory GenerationResult.failure({
    required List<String> errors,
    List<String> warnings = const [],
    List<String> generatedFiles = const [],
    Map<String, dynamic> metadata = const {},
  }) {
    return GenerationResult(
      success: false,
      generatedFiles: generatedFiles,
      errors: errors,
      warnings: warnings,
      metadata: metadata,
    );
  }

  /// 是否成功
  final bool success;

  /// 生成的文件列表
  final List<String> generatedFiles;

  /// 错误列表
  final List<String> errors;

  /// 警告列表
  final List<String> warnings;

  /// 元数据
  final Map<String, dynamic> metadata;

  /// 性能指标
  final PerformanceMetrics? performance;
}

/// 验证结果
///
/// 包含参数验证的结果信息
class ValidationResult {
  /// 创建验证结果实例
  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.suggestions = const [],
  });

  /// 创建成功结果
  factory ValidationResult.success({
    List<String> warnings = const [],
    List<String> suggestions = const [],
  }) {
    return ValidationResult(
      isValid: true,
      warnings: warnings,
      suggestions: suggestions,
    );
  }

  /// 创建失败结果
  factory ValidationResult.failure({
    required List<String> errors,
    List<String> warnings = const [],
    List<String> suggestions = const [],
  }) {
    return ValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings,
      suggestions: suggestions,
    );
  }

  /// 是否有效
  final bool isValid;

  /// 错误列表
  final List<String> errors;

  /// 警告列表
  final List<String> warnings;

  /// 建议列表
  final List<String> suggestions;
}

/// 兼容性结果
///
/// 包含模板兼容性检查的结果信息
class CompatibilityResult {
  /// 创建兼容性结果实例
  const CompatibilityResult({
    required this.isCompatible,
    this.issues = const [],
    this.recommendations = const [],
    this.metadata = const {},
  });

  /// 是否兼容
  final bool isCompatible;

  /// 兼容性问题列表
  final List<String> issues;

  /// 推荐建议列表
  final List<String> recommendations;

  /// 元数据
  final Map<String, dynamic> metadata;
}

/// 性能指标
///
/// 包含模板生成过程的性能数据
class PerformanceMetrics {
  /// 创建性能指标实例
  const PerformanceMetrics({
    required this.startTime,
    required this.endTime,
    required this.memoryUsage,
    this.cacheHits = 0,
    this.cacheMisses = 0,
    this.fileOperations = 0,
  });

  /// 开始时间
  final DateTime startTime;

  /// 结束时间
  final DateTime endTime;

  /// 内存使用量 (字节)
  final int memoryUsage;

  /// 缓存命中次数
  final int cacheHits;

  /// 缓存未命中次数
  final int cacheMisses;

  /// 文件操作次数
  final int fileOperations;

  /// 获取执行时间 (毫秒)
  int get executionTimeMs => endTime.difference(startTime).inMilliseconds;

  /// 获取缓存命中率
  double get cacheHitRate {
    final total = cacheHits + cacheMisses;
    return total > 0 ? cacheHits / total : 0.0;
  }
}

/// 生成钩子
///
/// 在模板生成过程中执行的钩子函数
abstract class GenerationHook {
  /// 钩子名称
  String get name;

  /// 钩子优先级 (数值越小优先级越高)
  int get priority => 100;

  /// 执行钩子
  Future<void> execute(GenerationContext context);
}

/// 企业级高级模板基类
///
/// 定义企业级模板的核心接口和生命周期管理
abstract class AdvancedTemplate {
  /// 模板类型
  TemplateType get type;

  /// 模板子类型
  TemplateSubType? get subType;

  /// 模板元数据
  TemplateMetadata get metadata;

  /// 模板依赖列表
  List<TemplateDependency> get dependencies;

  /// 模板参数定义
  Map<String, TemplateVariable> get parameters;

  // === 生命周期管理 ===

  /// 初始化模板
  ///
  /// 在模板生成前调用，用于准备必要的资源和配置
  Future<void> initialize(TemplateContext context);

  /// 生成模板内容
  ///
  /// 核心生成逻辑，根据上下文和参数生成目标内容
  Future<GenerationResult> generate(GenerationContext context);

  /// 清理资源
  ///
  /// 在模板生成后调用，用于清理临时资源
  Future<void> cleanup(GenerationContext context);

  // === 验证和兼容性 ===

  /// 验证参数
  ///
  /// 验证提供的参数是否符合模板要求
  ValidationResult validateParameters(Map<String, dynamic> params);

  /// 检查兼容性
  ///
  /// 检查模板与当前环境的兼容性
  CompatibilityResult checkCompatibility(TemplateContext context);

  // === 性能监控 ===

  /// 获取性能指标
  ///
  /// 返回模板生成过程的性能数据
  PerformanceMetrics? get performanceMetrics;

  // === 辅助方法 ===

  /// 获取模板显示名称
  String get displayName => metadata.name;

  /// 获取模板描述
  String get description => metadata.description;

  /// 获取模板版本
  String get version => metadata.version;

  /// 检查是否支持指定平台
  bool supportsPlatform(TemplatePlatform platform) {
    return metadata.platform == TemplatePlatform.crossPlatform ||
        metadata.platform == platform;
  }

  /// 检查是否支持指定框架
  bool supportsFramework(TemplateFramework framework) {
    return metadata.framework == TemplateFramework.agnostic ||
        metadata.framework == framework;
  }

  /// 获取必需参数列表
  List<String> get requiredParameters {
    return parameters.entries
        .where((entry) => !entry.value.optional)
        .map((entry) => entry.key)
        .toList();
  }

  /// 获取可选参数列表
  List<String> get optionalParameters {
    return parameters.entries
        .where((entry) => entry.value.optional)
        .map((entry) => entry.key)
        .toList();
  }
}
