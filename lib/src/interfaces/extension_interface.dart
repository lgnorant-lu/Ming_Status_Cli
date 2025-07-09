/*
---------------------------------------------------------------
File name:          extension_interface.dart
Author:             lgnorant-lu
Date created:       2025-07-09
Last modified:      2025-07-09
Dart Version:       3.2+
Description:        Task 52.3 - 扩展接口定义
                    为Phase 2功能扩展定义标准接口
---------------------------------------------------------------
Change History:
    2025-07-09: Initial creation - 扩展接口定义;
---------------------------------------------------------------
*/

/// 扩展类型
enum ExtensionType {
  template,         // 模板扩展
  validator,        // 验证器扩展
  generator,        // 生成器扩展
  command,          // 命令扩展
  provider,         // 提供者扩展
  middleware,       // 中间件扩展
}

/// 扩展元数据
class ExtensionMetadata {

  const ExtensionMetadata({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.author,
    required this.type,
    required this.minCliVersion,
    this.maxCliVersion,
    this.dependencies = const [],
    this.configSchema,
  });

  /// 从JSON创建
  factory ExtensionMetadata.fromJson(Map<String, dynamic> json) {
    return ExtensionMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      description: json['description'] as String,
      author: json['author'] as String,
      type: ExtensionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ExtensionType.template,
      ),
      minCliVersion: json['minCliVersion'] as String,
      maxCliVersion: json['maxCliVersion'] as String?,
      dependencies: (json['dependencies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      configSchema: json['configSchema'] as Map<String, dynamic>?,
    );
  }
  /// 扩展ID
  final String id;
  
  /// 扩展名称
  final String name;
  
  /// 扩展版本
  final String version;
  
  /// 扩展描述
  final String description;
  
  /// 扩展作者
  final String author;
  
  /// 扩展类型
  final ExtensionType type;
  
  /// 最小CLI版本要求
  final String minCliVersion;
  
  /// 最大CLI版本要求
  final String? maxCliVersion;
  
  /// 依赖的其他扩展
  final List<String> dependencies;
  
  /// 扩展配置模式
  final Map<String, dynamic>? configSchema;

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'description': description,
      'author': author,
      'type': type.name,
      'minCliVersion': minCliVersion,
      'maxCliVersion': maxCliVersion,
      'dependencies': dependencies,
      'configSchema': configSchema,
    };
  }
}

/// 扩展基础接口
abstract class Extension {
  /// 扩展元数据
  ExtensionMetadata get metadata;
  
  /// 初始化扩展
  Future<void> initialize(Map<String, dynamic> config);
  
  /// 销毁扩展
  Future<void> dispose();
  
  /// 检查扩展是否兼容
  bool isCompatible(String cliVersion);
  
  /// 获取扩展状态
  ExtensionStatus get status;
}

/// 扩展状态
enum ExtensionStatus {
  uninitialized,    // 未初始化
  initializing,     // 初始化中
  active,           // 活跃
  inactive,         // 非活跃
  error,            // 错误状态
  disposed,         // 已销毁
}

/// 模板扩展接口
abstract class TemplateExtension extends Extension {
  /// 获取支持的模板类型
  List<String> get supportedTemplateTypes;
  
  /// 生成模板
  Future<Map<String, String>> generateTemplate(
    String templateType,
    Map<String, dynamic> context,
  );
  
  /// 验证模板参数
  bool validateTemplateContext(
    String templateType,
    Map<String, dynamic> context,
  );
  
  /// 获取模板配置模式
  Map<String, dynamic> getTemplateSchema(String templateType);
}

/// 验证器扩展接口
abstract class ValidatorExtension extends Extension {
  /// 获取支持的验证类型
  List<String> get supportedValidationTypes;
  
  /// 执行验证
  Future<ValidationResult> validate(
    String validationType,
    Map<String, dynamic> context,
  );
  
  /// 获取验证规则
  List<ValidationRule> getValidationRules(String validationType);
}

/// 验证结果
class ValidationResult {

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.details = const {},
  });
  /// 验证是否通过
  final bool isValid;
  
  /// 错误信息
  final List<String> errors;
  
  /// 警告信息
  final List<String> warnings;
  
  /// 验证详情
  final Map<String, dynamic> details;
}

/// 验证规则
class ValidationRule {

  const ValidationRule({
    required this.id,
    required this.name,
    required this.description,
    required this.severity,
    this.config = const {},
  });
  /// 规则ID
  final String id;
  
  /// 规则名称
  final String name;
  
  /// 规则描述
  final String description;
  
  /// 规则严重级别
  final ValidationSeverity severity;
  
  /// 规则配置
  final Map<String, dynamic> config;
}

/// 验证严重级别
enum ValidationSeverity {
  info,       // 信息
  warning,    // 警告
  error,      // 错误
  critical,   // 严重错误
}

/// 生成器扩展接口
abstract class GeneratorExtension extends Extension {
  /// 获取支持的生成类型
  List<String> get supportedGeneratorTypes;
  
  /// 生成代码/文件
  Future<GenerationResult> generate(
    String generatorType,
    Map<String, dynamic> context,
  );
  
  /// 预览生成结果
  Future<GenerationPreview> preview(
    String generatorType,
    Map<String, dynamic> context,
  );
}

/// 生成结果
class GenerationResult {

  const GenerationResult({
    required this.files,
    required this.directories,
    required this.stats,
    this.logs = const [],
  });
  /// 生成的文件
  final Map<String, String> files;
  
  /// 生成的目录
  final List<String> directories;
  
  /// 生成统计
  final GenerationStats stats;
  
  /// 生成日志
  final List<String> logs;
}

/// 生成预览
class GenerationPreview {

  const GenerationPreview({
    required this.fileList,
    required this.directoryList,
    required this.estimatedStats,
  });
  /// 将要生成的文件列表
  final List<String> fileList;
  
  /// 将要创建的目录列表
  final List<String> directoryList;
  
  /// 预计生成统计
  final GenerationStats estimatedStats;
}

/// 生成统计
class GenerationStats {

  const GenerationStats({
    required this.fileCount,
    required this.directoryCount,
    required this.totalLines,
    required this.totalBytes,
    required this.durationMs,
  });
  /// 文件数量
  final int fileCount;
  
  /// 目录数量
  final int directoryCount;
  
  /// 总代码行数
  final int totalLines;
  
  /// 总字节数
  final int totalBytes;
  
  /// 生成耗时（毫秒）
  final int durationMs;
}

/// 命令扩展接口
abstract class CommandExtension extends Extension {
  /// 获取扩展命令列表
  List<ExtensionCommand> get commands;
  
  /// 执行命令
  Future<CommandResult> executeCommand(
    String commandName,
    List<String> args,
    Map<String, dynamic> options,
  );
}

/// 扩展命令
class ExtensionCommand {

  const ExtensionCommand({
    required this.name,
    required this.description,
    required this.usage,
    this.options = const [],
    this.arguments = const [],
  });
  /// 命令名称
  final String name;
  
  /// 命令描述
  final String description;
  
  /// 命令用法
  final String usage;
  
  /// 命令选项
  final List<CommandOption> options;
  
  /// 命令参数
  final List<CommandArgument> arguments;
}

/// 命令选项
class CommandOption {

  const CommandOption({
    required this.name,
    required this.description, this.abbr,
    this.required = false,
    this.defaultValue,
  });
  /// 选项名称
  final String name;
  
  /// 选项简写
  final String? abbr;
  
  /// 选项描述
  final String description;
  
  /// 是否必需
  final bool required;
  
  /// 默认值
  final String? defaultValue;
}

/// 命令参数
class CommandArgument {

  const CommandArgument({
    required this.name,
    required this.description,
    this.required = true,
    this.variadic = false,
  });
  /// 参数名称
  final String name;
  
  /// 参数描述
  final String description;
  
  /// 是否必需
  final bool required;
  
  /// 是否可变参数
  final bool variadic;
}

/// 命令执行结果
class CommandResult {

  const CommandResult({
    required this.success,
    required this.exitCode,
    required this.durationMs, this.output = '',
    this.error = '',
  });
  /// 执行是否成功
  final bool success;
  
  /// 退出码
  final int exitCode;
  
  /// 输出信息
  final String output;
  
  /// 错误信息
  final String error;
  
  /// 执行时间（毫秒）
  final int durationMs;
}

/// 提供者扩展接口
abstract class ProviderExtension extends Extension {
  /// 获取提供者类型
  String get providerType;
  
  /// 提供服务
  Future<T?> provide<T>(String serviceId, Map<String, dynamic> context);
  
  /// 检查是否支持服务
  bool supportsService(String serviceId);
  
  /// 获取支持的服务列表
  List<String> get supportedServices;
}

/// 中间件扩展接口
abstract class MiddlewareExtension extends Extension {
  /// 中间件优先级
  int get priority;
  
  /// 处理请求
  Future<MiddlewareResult> process(
    MiddlewareContext context,
    Future<MiddlewareResult> Function() next,
  );
}

/// 中间件上下文
class MiddlewareContext {

  MiddlewareContext({
    required this.requestType,
    required this.data,
    this.metadata = const {},
  });
  /// 请求类型
  final String requestType;
  
  /// 请求数据
  final Map<String, dynamic> data;
  
  /// 请求元数据
  final Map<String, dynamic> metadata;
}

/// 中间件结果
class MiddlewareResult {

  const MiddlewareResult({
    required this.success,
    required this.data,
    this.continueProcessing = true,
    this.error,
  });
  /// 处理是否成功
  final bool success;
  
  /// 结果数据
  final Map<String, dynamic> data;
  
  /// 是否继续处理
  final bool continueProcessing;
  
  /// 错误信息
  final String? error;
}
