/*
---------------------------------------------------------------
File name:          template_models.dart
Author:             lgnorant-lu
Date created:       2025/07/02
Last modified:      2025/07/02
Dart Version:       3.2+
Description:        模板模型 (Template models)
---------------------------------------------------------------
Change History:    
    2025/07/02: Initial creation - 模板模型功能;
---------------------------------------------------------------
*/

/// 模板兼容性检查结果
/// 
/// 封装模板兼容性检查的详细结果，提供多层次的反馈信息：
/// - 总体兼容性状态
/// - 阻塞性错误列表
/// - 警告信息列表  
/// - 优化建议列表
/// - 检查过程的元数据
/// 
/// 用于帮助开发者了解模板在当前环境的可用性和潜在问题。
class CompatibilityCheckResult {

  /// 创建成功结果
  CompatibilityCheckResult.success({
    List<String> warnings = const [],
    List<String> suggestions = const [],
    Map<String, dynamic> metadata = const {},
  }) : this(
      isCompatible: true,
      warnings: warnings,
      suggestions: suggestions,
      metadata: metadata,
    );

  /// 创建失败结果
  CompatibilityCheckResult.failure({
    required List<String> errors,
    List<String> warnings = const [],
    List<String> suggestions = const [],
    Map<String, dynamic> metadata = const {},
  }) : this(
      isCompatible: false,
      errors: errors,
      warnings: warnings,
      suggestions: suggestions,
      metadata: metadata,
    );
  /// 创建兼容性检查结果
  /// 
  /// 参数：
  /// - [isCompatible] 是否兼容
  /// - [errors] 错误列表
  /// - [warnings] 警告列表
  /// - [suggestions] 建议列表
  /// - [metadata] 元数据
  const CompatibilityCheckResult({
    required this.isCompatible,
    this.errors = const [],
    this.warnings = const [],
    this.suggestions = const [],
    this.metadata = const {},
  });

  /// 是否兼容
  final bool isCompatible;
  /// 错误列表
  final List<String> errors;
  /// 警告列表
  final List<String> warnings;
  /// 建议列表
  final List<String> suggestions;
  /// 元数据
  final Map<String, dynamic> metadata;
}

/// 模板版本信息
/// 
/// 描述模板对各种工具和环境的版本要求。
/// 用于版本兼容性检查，确保模板能在符合要求的环境中正常运行。
/// 
/// 支持的版本约束：
/// - 模板自身版本标识
/// - CLI工具版本范围
/// - Dart SDK版本范围  
/// - Mason构建工具版本范围
class TemplateVersionInfo {
  /// 创建模板版本信息
  /// 
  /// 参数：
  /// - [version] 模板版本
  /// - [minCliVersion] 最小CLI版本要求
  /// - [maxCliVersion] 最大CLI版本要求
  /// - [minDartVersion] 最小Dart版本要求
  /// - [maxDartVersion] 最大Dart版本要求
  /// - [minMasonVersion] 最小Mason版本要求
  /// - [maxMasonVersion] 最大Mason版本要求
  const TemplateVersionInfo({
    required this.version,
    this.minCliVersion,
    this.maxCliVersion,
    this.minDartVersion,
    this.maxDartVersion,
    this.minMasonVersion,
    this.maxMasonVersion,
  });

  /// 模板版本
  final String version;
  /// 最小CLI版本要求
  final String? minCliVersion;
  /// 最大CLI版本要求
  final String? maxCliVersion;
  /// 最小Dart版本要求
  final String? minDartVersion;
  /// 最大Dart版本要求
  final String? maxDartVersion;
  /// 最小Mason版本要求
  final String? minMasonVersion;
  /// 最大Mason版本要求
  final String? maxMasonVersion;
}

/// 模板平台信息
/// 
/// 定义模板对操作系统平台和功能特性的支持情况。
/// 用于平台兼容性检查，确保模板生成的代码能在目标平台正常运行。
/// 
/// 包含信息：
/// - 支持的操作系统平台（Windows、macOS、Linux等）
/// - 明确不支持的平台  
/// - 必需的平台功能特性
/// - 可选的增强功能特性
class TemplatePlatformInfo {
  /// 创建模板平台信息
  /// 
  /// 参数：
  /// - [supportedPlatforms] 支持的平台列表
  /// - [unsupportedPlatforms] 不支持的平台列表
  /// - [requiredFeatures] 必需功能列表
  /// - [optionalFeatures] 可选功能列表
  const TemplatePlatformInfo({
    this.supportedPlatforms = const [],
    this.unsupportedPlatforms = const [],
    this.requiredFeatures = const [],
    this.optionalFeatures = const [],
  });

  /// 支持的平台列表
  final List<String> supportedPlatforms;
  /// 不支持的平台列表
  final List<String> unsupportedPlatforms;
  /// 必需功能列表
  final List<String> requiredFeatures;
  /// 可选功能列表
  final List<String> optionalFeatures;
}

/// 模板依赖信息
/// 
/// 描述模板所需的外部依赖包和版本约束。
/// 用于依赖兼容性检查，确保生成的项目具有正确的依赖配置。
/// 
/// 依赖类型：
/// - 必需依赖：模板正常运行所必须的包和版本
/// - 可选依赖：提供额外功能的可选包
/// - 冲突依赖：与模板不兼容的包列表
/// 
/// 支持语义化版本约束（如 "^1.0.0", ">=2.0.0 <3.0.0"）
class TemplateDependencyInfo {
  /// 创建模板依赖信息
  /// 
  /// 参数：
  /// - [requiredDependencies] 必需依赖映射
  /// - [optionalDependencies] 可选依赖映射
  /// - [conflictingDependencies] 冲突依赖列表
  const TemplateDependencyInfo({
    this.requiredDependencies = const {},
    this.optionalDependencies = const {},
    this.conflictingDependencies = const [],
  });

  /// 必需依赖 (依赖名 -> 版本约束)
  final Map<String, String> requiredDependencies;
  /// 可选依赖 (依赖名 -> 版本约束)
  final Map<String, String> optionalDependencies;
  /// 冲突依赖列表
  final List<String> conflictingDependencies;
}

/// 钩子执行上下文
class HookContext {
  /// 创建钩子执行上下文
  const HookContext({
    required this.templateName,
    required this.outputPath,
    required this.variables,
    this.metadata = const {},
  });

  /// 模板名称
  final String templateName;
  /// 输出路径
  final String outputPath;
  /// 模板变量
  final Map<String, dynamic> variables;
  /// 元数据
  final Map<String, dynamic> metadata;
}

/// 钩子执行结果
class HookResult {
  
  /// 创建失败结果
  HookResult.failure(String message) : 
      this(success: false, message: message);
      
  /// 创建停止结果
  HookResult.stop(String message) : 
      this(
        success: true, 
        message: message, 
        shouldContinue: false,
      );
  /// 创建钩子执行结果
  const HookResult({
    required this.success,
    this.message,
    this.modifiedVariables,
    this.shouldContinue = true,
  });

  /// 执行是否成功
  final bool success;
  /// 结果消息
  final String? message;
  /// 修改后的变量
  final Map<String, dynamic>? modifiedVariables;
  /// 是否应该继续执行
  final bool shouldContinue;

  /// 成功结果的常量
  static const HookResult successResult = HookResult(success: true);
}

/// 模板生成结果
class GenerationResult {

  /// 创建失败结果
  GenerationResult.failure(String message, {String? outputPath})
    : this(
      success: false,
      outputPath: outputPath ?? '',
      message: message,
    );
  /// 创建模板生成结果
  /// 
  /// 参数：
  /// - [success] 生成是否成功
  /// - [outputPath] 输出路径
  /// - [generatedFiles] 生成的文件列表
  /// - [message] 结果消息
  /// - [duration] 生成耗时
  /// - [metadata] 结果元数据
  const GenerationResult({
    required this.success,
    required this.outputPath,
    this.generatedFiles = const [],
    this.message,
    this.duration,
    this.metadata = const {},
  });

  /// 生成是否成功
  final bool success;
  /// 输出路径
  final String outputPath;
  /// 生成的文件列表
  final List<String> generatedFiles;
  /// 结果消息
  final String? message;
  /// 生成耗时
  final Duration? duration;
  /// 结果元数据
  final Map<String, dynamic> metadata;
}

/// 模板继承配置
class TemplateInheritance {
  /// 创建模板继承配置
  const TemplateInheritance({
    required this.baseTemplate,
    this.overrides = const {},
    this.excludeFiles = const [],
  });

  /// 基础模板名称
  final String baseTemplate;
  /// 变量覆盖配置
  final Map<String, dynamic> overrides;
  /// 排除文件列表
  final List<String> excludeFiles;
}

/// 生成钩子类型枚举
enum HookType {
  /// 生成前钩子
  preGeneration,
  /// 生成后钩子
  postGeneration,
  /// 验证前钩子
  preValidation,
  /// 验证后钩子
  postValidation,
}

/// 抽象钩子基类
abstract class TemplateHook {
  /// 创建模板钩子
  const TemplateHook({required this.name});

  /// 钩子名称
  final String name;
  
  /// 执行钩子
  Future<HookResult> execute(HookContext context);
  
  /// 钩子类型
  HookType get type;
  
  /// 钩子优先级 (数值越小优先级越高)
  int get priority => 100;
}
