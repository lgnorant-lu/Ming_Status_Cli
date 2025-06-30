/*
---------------------------------------------------------------
File name:          workspace_config.dart
Author:             lgnorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.2+
Description:        工作空间配置数据模型 (Workspace configuration data model)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 基础工作空间配置模型;
    2025/06/29: Add testing environment config - 添加测试环境配置;
---------------------------------------------------------------
*/

import 'package:json_annotation/json_annotation.dart';

part 'workspace_config.g.dart';

/// 工作空间配置类
/// 管理整个Ming Status工作空间的配置信息
@JsonSerializable(explicitToJson: true)
class WorkspaceConfig {
  const WorkspaceConfig({
    required this.workspace,
    required this.templates,
    required this.defaults,
    required this.validation,
    this.environments,
    this.collaboration,
    this.quality,
    this.integrations,
    this.inheritance,
  });

  /// 从JSON创建实例
  factory WorkspaceConfig.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceConfigFromJson(json);

  /// 创建默认配置
  factory WorkspaceConfig.defaultConfig() {
    return const WorkspaceConfig(
      workspace: WorkspaceInfo(
        name: 'my_modules',
        version: '1.0.0',
        description: 'Ming Status模块工作空间',
      ),
      templates: TemplateConfig(
        source: TemplateSource.local,
        localPath: './templates',
      ),
      defaults: DefaultSettings(
        author: '开发者名称',
        license: 'MIT',
        dartVersion: '^3.2.0',
      ),
      validation: ValidationConfig(
        strictMode: false,
        requireTests: true,
        minCoverage: 80,
      ),
      environments: {
        'development': EnvironmentConfig(
          description: '开发环境配置',
          debug: true,
          hotReload: true,
        ),
        'testing': EnvironmentConfig(
          description: '测试环境配置',
          optimize: true,
        ),
        'production': EnvironmentConfig(
          description: '生产环境配置',
          optimize: true,
          minify: true,
        ),
      },
    );
  }

  /// 创建企业级配置
  factory WorkspaceConfig.enterpriseConfig() {
    return const WorkspaceConfig(
      workspace: WorkspaceInfo(
        name: 'enterprise_modules',
        version: '2.0.0',
        description: '企业级模块化开发工作空间',
        type: WorkspaceType.enterprise,
      ),
      templates: TemplateConfig(
        source: TemplateSource.hybrid,
        localPath: './templates',
        remoteRegistry: 'https://templates.ming.dev',
        cacheTimeout: 1800,
        autoUpdate: true,
      ),
      defaults: DefaultSettings(
        author: '企业开发团队',
        license: 'MIT',
        dartVersion: '^3.2.0',
        description: 'Enterprise Flutter module for scalable applications',
      ),
      validation: ValidationConfig(
        strictMode: true,
        requireTests: true,
        minCoverage: 90,
      ),
      collaboration: CollaborationConfig(
        teamName: 'Flutter开发团队',
        sharedSettings: true,
        configSync: ConfigSyncType.git,
        reviewRequired: true,
      ),
      quality: QualityConfig(
        codeAnalysis: CodeAnalysisConfig(
          enabled: true,
          rules: AnalysisRules.strict,
        ),
        testing: TestingConfig(
          minCoverage: 90,
          requiredTests: true,
        ),
        documentation: DocumentationConfig(
          required: true,
          format: DocumentationFormat.dartdoc,
        ),
      ),
    );
  }

  /// 工作空间基本信息
  final WorkspaceInfo workspace;

  /// 模板配置
  final TemplateConfig templates;

  /// 默认设置
  final DefaultSettings defaults;

  /// 验证规则
  final ValidationConfig validation;

  /// 环境配置
  final Map<String, EnvironmentConfig>? environments;

  /// 团队协作配置
  final CollaborationConfig? collaboration;

  /// 质量保障配置
  final QualityConfig? quality;

  /// 集成配置
  final IntegrationConfig? integrations;

  /// 配置继承设置
  final ConfigInheritance? inheritance;

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$WorkspaceConfigToJson(this);

  /// 拷贝并更新配置
  WorkspaceConfig copyWith({
    WorkspaceInfo? workspace,
    TemplateConfig? templates,
    DefaultSettings? defaults,
    ValidationConfig? validation,
    Map<String, EnvironmentConfig>? environments,
    CollaborationConfig? collaboration,
    QualityConfig? quality,
    IntegrationConfig? integrations,
    ConfigInheritance? inheritance,
  }) {
    return WorkspaceConfig(
      workspace: workspace ?? this.workspace,
      templates: templates ?? this.templates,
      defaults: defaults ?? this.defaults,
      validation: validation ?? this.validation,
      environments: environments ?? this.environments,
      collaboration: collaboration ?? this.collaboration,
      quality: quality ?? this.quality,
      integrations: integrations ?? this.integrations,
      inheritance: inheritance ?? this.inheritance,
    );
  }

  /// 根据环境配置获取特定环境的完整配置
  WorkspaceConfig getEnvironmentConfig(String environmentName) {
    final envConfig = environments?[environmentName];
    if (envConfig == null) {
      return this; // 如果环境不存在，返回原配置
    }

    // 应用环境特定的配置覆盖
    return _applyEnvironmentOverrides(envConfig);
  }

  /// 应用环境配置覆盖
  WorkspaceConfig _applyEnvironmentOverrides(EnvironmentConfig envConfig) {
    // 根据环境配置调整工作空间配置
    var updatedValidation = validation;
    final updatedTemplates = templates;

    // 如果是开发环境，可能需要不同的验证规则
    if (envConfig.debug) {
      updatedValidation = ValidationConfig(
        strictMode: false,
        requireTests: validation.requireTests,
        minCoverage: validation.minCoverage - 10, // 开发环境降低覆盖率要求
      );
    }

    // 如果是生产环境，应用优化设置
    if (envConfig.optimize) {
      updatedValidation = const ValidationConfig(
        strictMode: true,
        requireTests: true,
        minCoverage: 90, // 生产环境提高覆盖率要求
      );
    }

    return copyWith(
      validation: updatedValidation,
      templates: updatedTemplates,
    );
  }

  /// 与另一个配置合并
  WorkspaceConfig mergeWith(WorkspaceConfig other,
      {ConfigMergeStrategy strategy = ConfigMergeStrategy.override,}) {
    switch (strategy) {
      case ConfigMergeStrategy.override:
        return _mergeOverride(other);
      case ConfigMergeStrategy.merge:
        return _mergeDeep(other);
      case ConfigMergeStrategy.preserve:
        return _mergePreserve(other);
    }
  }

  /// 覆盖式合并
  WorkspaceConfig _mergeOverride(WorkspaceConfig other) {
    return WorkspaceConfig(
      workspace: other.workspace,
      templates: other.templates,
      defaults: other.defaults,
      validation: other.validation,
      environments: other.environments ?? environments,
      collaboration: other.collaboration ?? collaboration,
      quality: other.quality ?? quality,
      integrations: other.integrations ?? integrations,
      inheritance: other.inheritance ?? inheritance,
    );
  }

  /// 深度合并
  WorkspaceConfig _mergeDeep(WorkspaceConfig other) {
    // 合并环境配置
    final mergedEnvironments = <String, EnvironmentConfig>{};
    if (environments != null) {
      mergedEnvironments.addAll(environments!);
    }
    if (other.environments != null) {
      mergedEnvironments.addAll(other.environments!);
    }

    return WorkspaceConfig(
      workspace: other.workspace,
      templates: other.templates,
      defaults: _mergeDefaults(defaults, other.defaults),
      validation: _mergeValidation(validation, other.validation),
      environments: mergedEnvironments.isNotEmpty ? mergedEnvironments : null,
      collaboration: other.collaboration ?? collaboration,
      quality: other.quality ?? quality,
      integrations: other.integrations ?? integrations,
      inheritance: other.inheritance ?? inheritance,
    );
  }

  /// 保留式合并（保留原有值，只添加新值）
  WorkspaceConfig _mergePreserve(WorkspaceConfig other) {
    final mergedEnvironments = <String, EnvironmentConfig>{};
    if (environments != null) {
      mergedEnvironments.addAll(environments!);
    }
    if (other.environments != null) {
      for (final entry in other.environments!.entries) {
        if (!mergedEnvironments.containsKey(entry.key)) {
          mergedEnvironments[entry.key] = entry.value;
        }
      }
    }

    return WorkspaceConfig(
      workspace: workspace,
      templates: templates,
      defaults: defaults,
      validation: validation,
      environments: mergedEnvironments.isNotEmpty ? mergedEnvironments : null,
      collaboration: collaboration ?? other.collaboration,
      quality: quality ?? other.quality,
      integrations: integrations ?? other.integrations,
      inheritance: inheritance ?? other.inheritance,
    );
  }

  /// 合并默认设置
  DefaultSettings _mergeDefaults(DefaultSettings base, DefaultSettings other) {
    return DefaultSettings(
      author: other.author.isNotEmpty ? other.author : base.author,
      license: other.license.isNotEmpty ? other.license : base.license,
      dartVersion:
          other.dartVersion.isNotEmpty ? other.dartVersion : base.dartVersion,
      description:
          other.description.isNotEmpty ? other.description : base.description,
    );
  }

  /// 合并验证配置
  ValidationConfig _mergeValidation(
      ValidationConfig base, ValidationConfig other,) {
    return ValidationConfig(
      strictMode: other.strictMode || base.strictMode, // 采用更严格的设置
      requireTests: other.requireTests || base.requireTests,
      minCoverage: other.minCoverage > base.minCoverage
          ? other.minCoverage
          : base.minCoverage,
    );
  }
}

/// 工作空间基本信息
@JsonSerializable()
class WorkspaceInfo {
  const WorkspaceInfo({
    required this.name,
    required this.version,
    this.description,
    this.type = WorkspaceType.basic,
  });

  factory WorkspaceInfo.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceInfoFromJson(json);

  /// 工作空间名称
  final String name;

  /// 版本号
  final String version;

  /// 描述
  final String? description;

  /// 工作空间类型
  final WorkspaceType type;

  Map<String, dynamic> toJson() => _$WorkspaceInfoToJson(this);
}

/// 工作空间类型枚举
enum WorkspaceType {
  @JsonValue('basic')
  basic,

  @JsonValue('enterprise')
  enterprise,

  @JsonValue('team')
  team,
}

/// 模板配置
@JsonSerializable()
class TemplateConfig {
  const TemplateConfig({
    required this.source,
    this.localPath,
    this.remoteRegistry,
    this.cacheTimeout = 3600,
    this.autoUpdate = false,
  });

  factory TemplateConfig.fromJson(Map<String, dynamic> json) =>
      _$TemplateConfigFromJson(json);

  /// 模板来源
  final TemplateSource source;

  /// 本地模板路径
  final String? localPath;

  /// 远程模板注册表
  final String? remoteRegistry;

  /// 缓存超时时间(秒)
  final int cacheTimeout;

  /// 自动更新模板
  final bool autoUpdate;

  Map<String, dynamic> toJson() => _$TemplateConfigToJson(this);
}

/// 模板来源枚举
enum TemplateSource {
  @JsonValue('local')
  local,

  @JsonValue('remote')
  remote,

  @JsonValue('hybrid')
  hybrid,
}

/// 默认设置
@JsonSerializable()
class DefaultSettings {
  const DefaultSettings({
    required this.author,
    required this.license,
    required this.dartVersion,
    this.description = 'A Flutter module created by Ming Status CLI',
  });

  factory DefaultSettings.fromJson(Map<String, dynamic> json) =>
      _$DefaultSettingsFromJson(json);

  /// 默认作者
  final String author;

  /// 默认许可证
  final String license;

  /// 默认Dart版本
  final String dartVersion;

  /// 默认描述
  final String description;

  Map<String, dynamic> toJson() => _$DefaultSettingsToJson(this);

  /// 拷贝并更新默认设置
  DefaultSettings copyWith({
    String? author,
    String? license,
    String? dartVersion,
    String? description,
  }) {
    return DefaultSettings(
      author: author ?? this.author,
      license: license ?? this.license,
      dartVersion: dartVersion ?? this.dartVersion,
      description: description ?? this.description,
    );
  }
}

/// 验证配置
@JsonSerializable()
class ValidationConfig {
  const ValidationConfig({
    required this.strictMode,
    required this.requireTests,
    required this.minCoverage,
  });

  factory ValidationConfig.fromJson(Map<String, dynamic> json) =>
      _$ValidationConfigFromJson(json);

  /// 严格模式
  final bool strictMode;

  /// 要求测试
  final bool requireTests;

  /// 最小覆盖率
  final int minCoverage;

  Map<String, dynamic> toJson() => _$ValidationConfigToJson(this);
}

/// 环境配置
@JsonSerializable()
class EnvironmentConfig {
  const EnvironmentConfig({
    required this.description,
    this.debug = false,
    this.hotReload = false,
    this.optimize = false,
    this.minify = false,
    this.envVariables,
    this.buildMode,
    this.templateOverrides,
    this.validationOverrides,
    this.performanceSettings,
  });

  /// 创建开发环境配置
  factory EnvironmentConfig.development() {
    return const EnvironmentConfig(
      description: '开发环境 - 快速迭代与调试',
      debug: true,
      hotReload: true,
      buildMode: BuildMode.debug,
      validationOverrides: ValidationOverrideConfig(
        strictMode: false,
        minCoverage: 70,
        allowWarnings: true,
      ),
      performanceSettings: PerformanceSettings(
        cacheEnabled: true,
      ),
    );
  }

  /// 创建测试环境配置
  factory EnvironmentConfig.testing() {
    return const EnvironmentConfig(
      description: '测试环境 - 质量保障与验证',
      optimize: true,
      buildMode: BuildMode.profile,
      validationOverrides: ValidationOverrideConfig(
        strictMode: true,
        minCoverage: 85,
      ),
      performanceSettings: PerformanceSettings(
        cacheEnabled: true,
        maxMemoryUsage: 4096,
      ),
    );
  }

  /// 创建生产环境配置
  factory EnvironmentConfig.production() {
    return const EnvironmentConfig(
      description: '生产环境 - 性能优化与稳定性',
      optimize: true,
      minify: true,
      buildMode: BuildMode.release,
      validationOverrides: ValidationOverrideConfig(
        strictMode: true,
        minCoverage: 90,
      ),
      performanceSettings: PerformanceSettings(
        cacheEnabled: false, // 生产环境确保最新构建
        maxMemoryUsage: 8192,
      ),
    );
  }

  factory EnvironmentConfig.fromJson(Map<String, dynamic> json) =>
      _$EnvironmentConfigFromJson(json);

  /// 环境描述
  final String description;

  /// 调试模式
  final bool debug;

  /// 热重载
  final bool hotReload;

  /// 优化构建
  final bool optimize;

  /// 代码压缩
  final bool minify;

  /// 环境变量
  final Map<String, String>? envVariables;

  /// 构建模式
  final BuildMode? buildMode;

  /// 模板覆盖配置
  final TemplateOverrideConfig? templateOverrides;

  /// 验证规则覆盖
  final ValidationOverrideConfig? validationOverrides;

  /// 性能设置
  final PerformanceSettings? performanceSettings;

  Map<String, dynamic> toJson() => _$EnvironmentConfigToJson(this);
}

/// 团队协作配置
@JsonSerializable()
class CollaborationConfig {
  const CollaborationConfig({
    required this.teamName,
    this.sharedSettings = false,
    this.configSync = ConfigSyncType.none,
    this.reviewRequired = false,
  });

  factory CollaborationConfig.fromJson(Map<String, dynamic> json) =>
      _$CollaborationConfigFromJson(json);

  /// 团队名称
  final String teamName;

  /// 共享设置
  final bool sharedSettings;

  /// 配置同步类型
  final ConfigSyncType configSync;

  /// 需要审查
  final bool reviewRequired;

  Map<String, dynamic> toJson() => _$CollaborationConfigToJson(this);
}

/// 配置同步类型
enum ConfigSyncType {
  @JsonValue('none')
  none,

  @JsonValue('git')
  git,

  @JsonValue('cloud')
  cloud,
}

/// 质量保障配置
@JsonSerializable()
class QualityConfig {
  const QualityConfig({
    required this.codeAnalysis,
    required this.testing,
    required this.documentation,
  });

  factory QualityConfig.fromJson(Map<String, dynamic> json) =>
      _$QualityConfigFromJson(json);

  /// 代码分析配置
  final CodeAnalysisConfig codeAnalysis;

  /// 测试配置
  final TestingConfig testing;

  /// 文档配置
  final DocumentationConfig documentation;

  Map<String, dynamic> toJson() => _$QualityConfigToJson(this);
}

/// 代码分析配置
@JsonSerializable()
class CodeAnalysisConfig {
  const CodeAnalysisConfig({
    required this.enabled,
    required this.rules,
  });

  factory CodeAnalysisConfig.fromJson(Map<String, dynamic> json) =>
      _$CodeAnalysisConfigFromJson(json);

  /// 启用代码分析
  final bool enabled;

  /// 分析规则
  final AnalysisRules rules;

  Map<String, dynamic> toJson() => _$CodeAnalysisConfigToJson(this);
}

/// 分析规则
enum AnalysisRules {
  @JsonValue('basic')
  basic,

  @JsonValue('recommended')
  recommended,

  @JsonValue('strict')
  strict,
}

/// 测试配置
@JsonSerializable()
class TestingConfig {
  const TestingConfig({
    required this.minCoverage,
    required this.requiredTests,
  });

  factory TestingConfig.fromJson(Map<String, dynamic> json) =>
      _$TestingConfigFromJson(json);

  /// 最小覆盖率
  final int minCoverage;

  /// 必需测试
  final bool requiredTests;

  Map<String, dynamic> toJson() => _$TestingConfigToJson(this);
}

/// 文档配置
@JsonSerializable()
class DocumentationConfig {
  const DocumentationConfig({
    required this.required,
    required this.format,
  });

  factory DocumentationConfig.fromJson(Map<String, dynamic> json) =>
      _$DocumentationConfigFromJson(json);

  /// 必需文档
  final bool required;

  /// 文档格式
  final DocumentationFormat format;

  Map<String, dynamic> toJson() => _$DocumentationConfigToJson(this);
}

/// 文档格式
enum DocumentationFormat {
  @JsonValue('dartdoc')
  dartdoc,

  @JsonValue('markdown')
  markdown,

  @JsonValue('wiki')
  wiki,
}

/// 集成配置
@JsonSerializable()
class IntegrationConfig {
  const IntegrationConfig({
    this.ide,
    this.ci,
  });

  factory IntegrationConfig.fromJson(Map<String, dynamic> json) =>
      _$IntegrationConfigFromJson(json);

  /// IDE集成配置
  final Map<String, dynamic>? ide;

  /// CI/CD集成配置
  final Map<String, dynamic>? ci;

  Map<String, dynamic> toJson() => _$IntegrationConfigToJson(this);
}

/// 配置继承设置
@JsonSerializable()
class ConfigInheritance {
  const ConfigInheritance({
    this.baseConfig,
    this.inheritsFrom,
    this.mergeStrategy = ConfigMergeStrategy.merge,
    this.overrides,
  });

  factory ConfigInheritance.fromJson(Map<String, dynamic> json) =>
      _$ConfigInheritanceFromJson(json);

  /// 基础配置路径
  final String? baseConfig;

  /// 继承来源配置列表
  final List<String>? inheritsFrom;

  /// 合并策略
  final ConfigMergeStrategy mergeStrategy;

  /// 配置覆盖项
  final Map<String, dynamic>? overrides;

  Map<String, dynamic> toJson() => _$ConfigInheritanceToJson(this);
}

/// 配置合并策略
enum ConfigMergeStrategy {
  /// 覆盖模式 - 新配置完全覆盖旧配置
  @JsonValue('override')
  override,

  /// 深度合并模式 - 递归合并配置项
  @JsonValue('merge')
  merge,

  /// 保留模式 - 保留现有值，只添加新值
  @JsonValue('preserve')
  preserve,
}

/// 构建模式
enum BuildMode {
  /// 调试模式
  @JsonValue('debug')
  debug,

  /// 性能分析模式
  @JsonValue('profile')
  profile,

  /// 发布模式
  @JsonValue('release')
  release,
}

/// 模板覆盖配置
@JsonSerializable()
class TemplateOverrideConfig {
  const TemplateOverrideConfig({
    this.templatePath,
    this.customVariables,
    this.excludeFiles,
    this.includeFiles,
  });

  factory TemplateOverrideConfig.fromJson(Map<String, dynamic> json) =>
      _$TemplateOverrideConfigFromJson(json);

  /// 自定义模板路径
  final String? templatePath;

  /// 自定义变量
  final Map<String, String>? customVariables;

  /// 排除文件列表
  final List<String>? excludeFiles;

  /// 包含文件列表
  final List<String>? includeFiles;

  Map<String, dynamic> toJson() => _$TemplateOverrideConfigToJson(this);
}

/// 验证规则覆盖配置
@JsonSerializable()
class ValidationOverrideConfig {
  const ValidationOverrideConfig({
    this.strictMode,
    this.minCoverage,
    this.allowWarnings = false,
    this.customRules,
  });

  factory ValidationOverrideConfig.fromJson(Map<String, dynamic> json) =>
      _$ValidationOverrideConfigFromJson(json);

  /// 严格模式覆盖
  final bool? strictMode;

  /// 最小覆盖率覆盖
  final int? minCoverage;

  /// 允许警告
  final bool allowWarnings;

  /// 自定义规则
  final List<String>? customRules;

  Map<String, dynamic> toJson() => _$ValidationOverrideConfigToJson(this);
}

/// 性能设置
@JsonSerializable()
class PerformanceSettings {
  const PerformanceSettings({
    this.parallelBuild = true,
    this.cacheEnabled = true,
    this.maxMemoryUsage = 2048,
    this.buildTimeout = 300,
    this.optimizationLevel,
  });

  factory PerformanceSettings.fromJson(Map<String, dynamic> json) =>
      _$PerformanceSettingsFromJson(json);

  /// 并行构建
  final bool parallelBuild;

  /// 缓存启用
  final bool cacheEnabled;

  /// 最大内存使用量(MB)
  final int maxMemoryUsage;

  /// 构建超时时间(秒)
  final int buildTimeout;

  /// 优化级别
  final OptimizationLevel? optimizationLevel;

  Map<String, dynamic> toJson() => _$PerformanceSettingsToJson(this);
}

/// 优化级别
enum OptimizationLevel {
  /// 无优化
  @JsonValue('none')
  none,

  /// 基础优化
  @JsonValue('basic')
  basic,

  /// 高级优化
  @JsonValue('advanced')
  advanced,

  /// 最大优化
  @JsonValue('maximum')
  maximum,
}
