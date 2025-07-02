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
  /// 创建工作空间配置实例
  /// 
  /// 需要提供核心配置参数：
  /// - [workspace] 工作空间基本信息
  /// - [templates] 模板配置设置
  /// - [defaults] 默认值配置
  /// - [validation] 验证规则配置
  /// 
  /// 可选配置参数：
  /// - [environments] 环境特定配置
  /// - [collaboration] 团队协作配置
  /// - [quality] 质量保障配置
  /// - [integrations] 外部集成配置
  /// - [inheritance] 配置继承设置
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
/// 
/// 定义工作空间的核心识别信息和元数据，包括名称、版本、描述和类型。
/// 这些信息用于工作空间的管理、版本控制和团队协作。
@JsonSerializable()
class WorkspaceInfo {
  /// 创建工作空间基本信息实例
  /// 
  /// 必需参数：
  /// - [name] 工作空间名称，用于标识工作空间
  /// - [version] 版本号，遵循语义化版本规范
  /// 
  /// 可选参数：
  /// - [description] 工作空间描述，说明项目目标和特性
  /// - [type] 工作空间类型，默认为basic类型
  const WorkspaceInfo({
    required this.name,
    required this.version,
    this.description,
    this.type = WorkspaceType.basic,
  });

  /// 从JSON创建实例
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

  /// 转换为JSON格式
  Map<String, dynamic> toJson() => _$WorkspaceInfoToJson(this);
}

/// 工作空间类型枚举
enum WorkspaceType {
  /// 基础工作空间类型
  /// 
  /// 适用于个人开发或小型项目，提供基本的模块管理功能
  @JsonValue('basic')
  basic,

  /// 企业级工作空间类型
  /// 
  /// 适用于大型企业项目，提供高级质量保障和团队协作功能
  @JsonValue('enterprise')
  enterprise,

  /// 团队工作空间类型
  /// 
  /// 适用于团队开发，平衡功能性和易用性
  @JsonValue('team')
  team,
}

/// 模板配置
/// 
/// 管理模板的来源、路径和缓存策略，支持本地、远程和混合模式的模板管理。
/// 提供灵活的模板获取和更新机制。
@JsonSerializable()
class TemplateConfig {
  /// 创建模板配置实例
  /// 
  /// 必需参数：
  /// - [source] 模板来源类型（local、remote、hybrid）
  /// 
  /// 可选参数：
  /// - [localPath] 本地模板目录路径
  /// - [remoteRegistry] 远程模板注册表URL
  /// - [cacheTimeout] 缓存超时时间（秒），默认3600秒
  /// - [autoUpdate] 是否自动更新模板，默认false
  const TemplateConfig({
    required this.source,
    this.localPath,
    this.remoteRegistry,
    this.cacheTimeout = 3600,
    this.autoUpdate = false,
  });

  /// 从JSON创建实例
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

  /// 转换为JSON格式
  Map<String, dynamic> toJson() => _$TemplateConfigToJson(this);
}

/// 模板来源枚举
enum TemplateSource {
  /// 本地模板来源
  /// 
  /// 使用本地文件系统中的模板
  @JsonValue('local')
  local,

  /// 远程模板来源
  /// 
  /// 从远程注册表获取模板
  @JsonValue('remote')
  remote,

  /// 混合模板来源
  /// 
  /// 同时支持本地和远程模板
  @JsonValue('hybrid')
  hybrid,
}

/// 默认设置
/// 
/// 定义工作空间的默认值，用于新建模块时的预填充信息。
/// 包括作者信息、许可证类型、Dart版本要求和项目描述模板。
@JsonSerializable()
class DefaultSettings {
  /// 创建默认设置实例
  /// 
  /// 必需参数：
  /// - [author] 默认作者名称
  /// - [license] 默认许可证类型（如MIT、Apache-2.0等）
  /// - [dartVersion] 默认Dart版本约束
  /// 
  /// 可选参数：
  /// - [description] 默认项目描述模板
  const DefaultSettings({
    required this.author,
    required this.license,
    required this.dartVersion,
    this.description = 'A Flutter module created by Ming Status CLI',
  });

  /// 从JSON创建实例
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

  /// 转换为JSON格式
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
/// 
/// 定义代码质量和测试的验证规则，确保项目符合质量标准。
/// 包括严格模式、测试要求和覆盖率阈值等配置。
@JsonSerializable()
class ValidationConfig {
  /// 创建验证配置实例
  /// 
  /// 所有参数都是必需的：
  /// - [strictMode] 是否启用严格验证模式
  /// - [requireTests] 是否要求编写测试
  /// - [minCoverage] 最小测试覆盖率要求（百分比）
  const ValidationConfig({
    required this.strictMode,
    required this.requireTests,
    required this.minCoverage,
  });

  /// 从JSON创建实例
  factory ValidationConfig.fromJson(Map<String, dynamic> json) =>
      _$ValidationConfigFromJson(json);

  /// 严格模式
  final bool strictMode;

  /// 要求测试
  final bool requireTests;

  /// 最小覆盖率
  final int minCoverage;

  /// 转换为JSON格式
  Map<String, dynamic> toJson() => _$ValidationConfigToJson(this);
}

/// 环境配置
/// 
/// 定义特定环境（开发、测试、生产）的配置设置。
/// 支持环境特定的构建选项、性能设置和验证规则覆盖。
@JsonSerializable()
class EnvironmentConfig {
  /// 创建环境配置实例
  /// 
  /// 必需参数：
  /// - [description] 环境描述信息
  /// 
  /// 可选参数：
  /// - [debug] 是否启用调试模式，默认false
  /// - [hotReload] 是否启用热重载，默认false
  /// - [optimize] 是否启用构建优化，默认false
  /// - [minify] 是否启用代码压缩，默认false
  /// - [envVariables] 环境变量映射
  /// - [buildMode] 构建模式设置
  /// - [templateOverrides] 模板覆盖配置
  /// - [validationOverrides] 验证规则覆盖
  /// - [performanceSettings] 性能设置
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
      performanceSettings: PerformanceSettings(),
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

  /// 从JSON创建实例
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

  /// 转换为JSON格式
  Map<String, dynamic> toJson() => _$EnvironmentConfigToJson(this);
}

/// 团队协作配置
/// 
/// 定义团队开发中的协作设置，包括团队信息、配置共享和审查流程。
/// 支持不同的配置同步策略和团队协作模式。
@JsonSerializable()
class CollaborationConfig {
  /// 创建团队协作配置实例
  /// 
  /// 必需参数：
  /// - [teamName] 团队名称
  /// 
  /// 可选参数：
  /// - [sharedSettings] 是否启用共享设置，默认false
  /// - [configSync] 配置同步类型，默认none
  /// - [reviewRequired] 是否需要代码审查，默认false
  const CollaborationConfig({
    required this.teamName,
    this.sharedSettings = false,
    this.configSync = ConfigSyncType.none,
    this.reviewRequired = false,
  });

  /// 从JSON创建实例
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

  /// 转换为JSON格式
  Map<String, dynamic> toJson() => _$CollaborationConfigToJson(this);
}

/// 配置同步类型枚举
enum ConfigSyncType {
  /// 无同步
  /// 
  /// 不进行配置同步
  @JsonValue('none')
  none,

  /// Git同步
  /// 
  /// 通过Git仓库同步配置
  @JsonValue('git')
  git,

  /// 云端同步
  /// 
  /// 通过云服务同步配置
  @JsonValue('cloud')
  cloud,
}

/// 质量保障配置
/// 
/// 定义项目质量保障的各个方面，包括代码分析、测试和文档要求。
/// 确保项目符合企业级质量标准。
@JsonSerializable()
class QualityConfig {
  /// 创建质量保障配置实例
  /// 
  /// 所有参数都是必需的：
  /// - [codeAnalysis] 代码分析配置
  /// - [testing] 测试要求配置
  /// - [documentation] 文档标准配置
  const QualityConfig({
    required this.codeAnalysis,
    required this.testing,
    required this.documentation,
  });

  /// 从JSON创建实例
  factory QualityConfig.fromJson(Map<String, dynamic> json) =>
      _$QualityConfigFromJson(json);

  /// 代码分析配置
  final CodeAnalysisConfig codeAnalysis;

  /// 测试配置
  final TestingConfig testing;

  /// 文档配置
  final DocumentationConfig documentation;

  /// 转换为JSON格式
  Map<String, dynamic> toJson() => _$QualityConfigToJson(this);
}

/// 代码分析配置
@JsonSerializable()
class CodeAnalysisConfig {
  /// 创建代码分析配置实例
  /// 
  /// 所有参数都是必需的：
  /// - [enabled] 是否启用代码分析
  /// - [rules] 分析规则级别
  const CodeAnalysisConfig({
    required this.enabled,
    required this.rules,
  });

  /// 从JSON创建实例
  factory CodeAnalysisConfig.fromJson(Map<String, dynamic> json) =>
      _$CodeAnalysisConfigFromJson(json);

  /// 启用代码分析
  final bool enabled;

  /// 分析规则
  final AnalysisRules rules;

  /// 转换为JSON格式
  Map<String, dynamic> toJson() => _$CodeAnalysisConfigToJson(this);
}

/// 分析规则枚举
enum AnalysisRules {
  /// 基础规则
  /// 
  /// 提供基本的代码质量检查
  @JsonValue('basic')
  basic,

  /// 推荐规则
  /// 
  /// 包含推荐的最佳实践检查
  @JsonValue('recommended')
  recommended,

  /// 严格规则
  /// 
  /// 提供最严格的代码质量标准
  @JsonValue('strict')
  strict,
}

/// 测试配置
@JsonSerializable()
class TestingConfig {
  /// 创建测试配置实例
  /// 
  /// 所有参数都是必需的：
  /// - [minCoverage] 最小测试覆盖率要求
  /// - [requiredTests] 是否要求编写测试
  const TestingConfig({
    required this.minCoverage,
    required this.requiredTests,
  });

  /// 从JSON创建实例
  factory TestingConfig.fromJson(Map<String, dynamic> json) =>
      _$TestingConfigFromJson(json);

  /// 最小覆盖率
  final int minCoverage;

  /// 必需测试
  final bool requiredTests;

  /// 转换为JSON格式
  Map<String, dynamic> toJson() => _$TestingConfigToJson(this);
}

/// 文档配置
@JsonSerializable()
class DocumentationConfig {
  /// 创建文档配置实例
  /// 
  /// 所有参数都是必需的：
  /// - [required] 是否要求编写文档
  /// - [format] 文档格式类型
  const DocumentationConfig({
    required this.required,
    required this.format,
  });

  /// 从JSON创建实例
  factory DocumentationConfig.fromJson(Map<String, dynamic> json) =>
      _$DocumentationConfigFromJson(json);

  /// 必需文档
  final bool required;

  /// 文档格式
  final DocumentationFormat format;

  /// 转换为JSON格式
  Map<String, dynamic> toJson() => _$DocumentationConfigToJson(this);
}

/// 文档格式枚举
enum DocumentationFormat {
  /// Dart文档格式
  /// 
  /// 使用Dart标准文档工具生成文档
  @JsonValue('dartdoc')
  dartdoc,

  /// Markdown格式
  /// 
  /// 使用Markdown格式编写文档
  @JsonValue('markdown')
  markdown,

  /// Wiki格式
  /// 
  /// 使用Wiki格式编写文档
  @JsonValue('wiki')
  wiki,
}

/// 集成配置
@JsonSerializable()
class IntegrationConfig {
  /// 创建集成配置实例
  /// 
  /// 所有参数都是可选的：
  /// - [ide] IDE集成配置映射
  /// - [ci] CI/CD集成配置映射
  const IntegrationConfig({
    this.ide,
    this.ci,
  });

  /// 从JSON创建实例
  factory IntegrationConfig.fromJson(Map<String, dynamic> json) =>
      _$IntegrationConfigFromJson(json);

  /// IDE集成配置
  final Map<String, dynamic>? ide;

  /// CI/CD集成配置
  final Map<String, dynamic>? ci;

  /// 转换为JSON格式
  Map<String, dynamic> toJson() => _$IntegrationConfigToJson(this);
}

/// 配置继承设置
@JsonSerializable()
class ConfigInheritance {
  /// 创建配置继承设置实例
  /// 
  /// 可选参数：
  /// - [baseConfig] 基础配置文件路径
  /// - [inheritsFrom] 继承来源配置列表
  /// - [mergeStrategy] 合并策略，默认为merge
  /// - [overrides] 配置覆盖项映射
  const ConfigInheritance({
    this.baseConfig,
    this.inheritsFrom,
    this.mergeStrategy = ConfigMergeStrategy.merge,
    this.overrides,
  });

  /// 从JSON创建实例
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

  /// 转换为JSON格式
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

/// 构建模式枚举
enum BuildMode {
  /// 调试模式
  /// 
  /// 用于开发调试，包含调试信息，性能较慢
  @JsonValue('debug')
  debug,

  /// 性能分析模式
  /// 
  /// 用于性能分析，包含部分调试信息和性能优化
  @JsonValue('profile')
  profile,

  /// 发布模式
  /// 
  /// 用于生产发布，完全优化，去除调试信息
  @JsonValue('release')
  release,
}

/// 模板覆盖配置
@JsonSerializable()
class TemplateOverrideConfig {
  /// 创建模板覆盖配置实例
  /// 
  /// 所有参数都是可选的：
  /// - [templatePath] 自定义模板路径
  /// - [customVariables] 自定义变量映射
  /// - [excludeFiles] 排除文件列表
  /// - [includeFiles] 包含文件列表
  const TemplateOverrideConfig({
    this.templatePath,
    this.customVariables,
    this.excludeFiles,
    this.includeFiles,
  });

  /// 从JSON创建实例
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

  /// 转换为JSON格式
  Map<String, dynamic> toJson() => _$TemplateOverrideConfigToJson(this);
}

/// 验证规则覆盖配置
@JsonSerializable()
class ValidationOverrideConfig {
  /// 创建验证规则覆盖配置实例
  /// 
  /// 可选参数：
  /// - [strictMode] 严格模式覆盖设置
  /// - [minCoverage] 最小覆盖率覆盖设置
  /// - [allowWarnings] 是否允许警告，默认false
  /// - [customRules] 自定义规则列表
  const ValidationOverrideConfig({
    this.strictMode,
    this.minCoverage,
    this.allowWarnings = false,
    this.customRules,
  });

  /// 从JSON创建实例
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

  /// 转换为JSON格式
  Map<String, dynamic> toJson() => _$ValidationOverrideConfigToJson(this);
}

/// 性能设置
@JsonSerializable()
class PerformanceSettings {
  /// 创建性能设置实例
  /// 
  /// 可选参数：
  /// - [parallelBuild] 是否启用并行构建，默认true
  /// - [cacheEnabled] 是否启用缓存，默认true
  /// - [maxMemoryUsage] 最大内存使用量(MB)，默认2048
  /// - [buildTimeout] 构建超时时间(秒)，默认300
  /// - [optimizationLevel] 优化级别设置
  const PerformanceSettings({
    this.parallelBuild = true,
    this.cacheEnabled = true,
    this.maxMemoryUsage = 2048,
    this.buildTimeout = 300,
    this.optimizationLevel,
  });

  /// 从JSON创建实例
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

  /// 转换为JSON格式
  Map<String, dynamic> toJson() => _$PerformanceSettingsToJson(this);
}

/// 优化级别枚举
enum OptimizationLevel {
  /// 无优化
  /// 
  /// 不进行任何优化，适用于快速调试
  @JsonValue('none')
  none,

  /// 基础优化
  /// 
  /// 进行基本的性能优化
  @JsonValue('basic')
  basic,

  /// 高级优化
  /// 
  /// 进行高级性能优化，平衡编译时间和运行性能
  @JsonValue('advanced')
  advanced,

  /// 最大优化
  /// 
  /// 进行最大程度的优化，可能增加编译时间
  @JsonValue('maximum')
  maximum,
}
