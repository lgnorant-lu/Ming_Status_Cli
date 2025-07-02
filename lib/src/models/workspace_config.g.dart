// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkspaceConfig _$WorkspaceConfigFromJson(Map<String, dynamic> json) =>
    WorkspaceConfig(
      workspace:
          WorkspaceInfo.fromJson(json['workspace'] as Map<String, dynamic>),
      templates:
          TemplateConfig.fromJson(json['templates'] as Map<String, dynamic>),
      defaults:
          DefaultSettings.fromJson(json['defaults'] as Map<String, dynamic>),
      validation:
          ValidationConfig.fromJson(json['validation'] as Map<String, dynamic>),
      environments: (json['environments'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, EnvironmentConfig.fromJson(e as Map<String, dynamic>)),
      ),
      collaboration: json['collaboration'] == null
          ? null
          : CollaborationConfig.fromJson(
              json['collaboration'] as Map<String, dynamic>,),
      quality: json['quality'] == null
          ? null
          : QualityConfig.fromJson(json['quality'] as Map<String, dynamic>,),
      integrations: json['integrations'] == null
          ? null
          : IntegrationConfig.fromJson(
              json['integrations'] as Map<String, dynamic>,),
      inheritance: json['inheritance'] == null
          ? null
          : ConfigInheritance.fromJson(
              json['inheritance'] as Map<String, dynamic>,),
    );

Map<String, dynamic> _$WorkspaceConfigToJson(WorkspaceConfig instance) =>
    <String, dynamic>{
      'workspace': instance.workspace.toJson(),
      'templates': instance.templates.toJson(),
      'defaults': instance.defaults.toJson(),
      'validation': instance.validation.toJson(),
      'environments':
          instance.environments?.map((k, e) => MapEntry(k, e.toJson())),
      'collaboration': instance.collaboration?.toJson(),
      'quality': instance.quality?.toJson(),
      'integrations': instance.integrations?.toJson(),
      'inheritance': instance.inheritance?.toJson(),
    };

WorkspaceInfo _$WorkspaceInfoFromJson(Map<String, dynamic> json) =>
    WorkspaceInfo(
      name: json['name'] as String,
      version: json['version'] as String,
      description: json['description'] as String?,
      type: $enumDecodeNullable(_$WorkspaceTypeEnumMap, json['type']) ??
          WorkspaceType.basic,
    );

Map<String, dynamic> _$WorkspaceInfoToJson(WorkspaceInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'version': instance.version,
      'description': instance.description,
      'type': _$WorkspaceTypeEnumMap[instance.type],
    };

const _$WorkspaceTypeEnumMap = {
  WorkspaceType.basic: 'basic',
  WorkspaceType.enterprise: 'enterprise',
  WorkspaceType.team: 'team',
};

TemplateConfig _$TemplateConfigFromJson(Map<String, dynamic> json) =>
    TemplateConfig(
      source: $enumDecode(_$TemplateSourceEnumMap, json['source']),
      localPath: json['localPath'] as String?,
      remoteRegistry: json['remoteRegistry'] as String?,
      cacheTimeout: (json['cacheTimeout'] as num?)?.toInt() ?? 3600,
      autoUpdate: json['autoUpdate'] as bool? ?? false,
    );

Map<String, dynamic> _$TemplateConfigToJson(TemplateConfig instance) =>
    <String, dynamic>{
      'source': _$TemplateSourceEnumMap[instance.source],
      'localPath': instance.localPath,
      'remoteRegistry': instance.remoteRegistry,
      'cacheTimeout': instance.cacheTimeout,
      'autoUpdate': instance.autoUpdate,
    };

const _$TemplateSourceEnumMap = {
  TemplateSource.local: 'local',
  TemplateSource.remote: 'remote',
  TemplateSource.hybrid: 'hybrid',
};

DefaultSettings _$DefaultSettingsFromJson(Map<String, dynamic> json) =>
    DefaultSettings(
      author: json['author'] as String,
      license: json['license'] as String,
      dartVersion: json['dartVersion'] as String,
      description: json['description'] as String? ??
          'A Flutter module created by Ming Status CLI',
    );

Map<String, dynamic> _$DefaultSettingsToJson(DefaultSettings instance) =>
    <String, dynamic>{
      'author': instance.author,
      'license': instance.license,
      'dartVersion': instance.dartVersion,
      'description': instance.description,
    };

ValidationConfig _$ValidationConfigFromJson(Map<String, dynamic> json) =>
    ValidationConfig(
      strictMode: json['strictMode'] as bool,
      requireTests: json['requireTests'] as bool,
      minCoverage: (json['minCoverage'] as num).toInt(),
    );

Map<String, dynamic> _$ValidationConfigToJson(ValidationConfig instance) =>
    <String, dynamic>{
      'strictMode': instance.strictMode,
      'requireTests': instance.requireTests,
      'minCoverage': instance.minCoverage,
    };

EnvironmentConfig _$EnvironmentConfigFromJson(Map<String, dynamic> json) =>
    EnvironmentConfig(
      description: json['description'] as String,
      debug: json['debug'] as bool? ?? false,
      hotReload: json['hotReload'] as bool? ?? false,
      optimize: json['optimize'] as bool? ?? false,
      minify: json['minify'] as bool? ?? false,
      envVariables: (json['envVariables'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      buildMode: $enumDecodeNullable(_$BuildModeEnumMap, json['buildMode']),
      templateOverrides: json['templateOverrides'] == null
          ? null
          : TemplateOverrideConfig.fromJson(
              json['templateOverrides'] as Map<String, dynamic>,),
      validationOverrides: json['validationOverrides'] == null
          ? null
          : ValidationOverrideConfig.fromJson(
              json['validationOverrides'] as Map<String, dynamic>,),
      performanceSettings: json['performanceSettings'] == null
          ? null
          : PerformanceSettings.fromJson(
              json['performanceSettings'] as Map<String, dynamic>,),
    );

Map<String, dynamic> _$EnvironmentConfigToJson(EnvironmentConfig instance) =>
    <String, dynamic>{
      'description': instance.description,
      'debug': instance.debug,
      'hotReload': instance.hotReload,
      'optimize': instance.optimize,
      'minify': instance.minify,
      'envVariables': instance.envVariables,
      'buildMode': _$BuildModeEnumMap[instance.buildMode],
      'templateOverrides': instance.templateOverrides,
      'validationOverrides': instance.validationOverrides,
      'performanceSettings': instance.performanceSettings,
    };

const _$BuildModeEnumMap = {
  BuildMode.debug: 'debug',
  BuildMode.profile: 'profile',
  BuildMode.release: 'release',
};

CollaborationConfig _$CollaborationConfigFromJson(Map<String, dynamic> json) =>
    CollaborationConfig(
      teamName: json['teamName'] as String,
      sharedSettings: json['sharedSettings'] as bool? ?? false,
      configSync:
          $enumDecodeNullable(_$ConfigSyncTypeEnumMap, json['configSync']) ??
              ConfigSyncType.none,
      reviewRequired: json['reviewRequired'] as bool? ?? false,
    );

Map<String, dynamic> _$CollaborationConfigToJson(
      CollaborationConfig instance,) =>
    <String, dynamic>{
      'teamName': instance.teamName,
      'sharedSettings': instance.sharedSettings,
      'configSync': _$ConfigSyncTypeEnumMap[instance.configSync],
      'reviewRequired': instance.reviewRequired,
    };

const _$ConfigSyncTypeEnumMap = {
  ConfigSyncType.none: 'none',
  ConfigSyncType.git: 'git',
  ConfigSyncType.cloud: 'cloud',
};

QualityConfig _$QualityConfigFromJson(Map<String, dynamic> json) =>
    QualityConfig(
      codeAnalysis: CodeAnalysisConfig.fromJson(
          json['codeAnalysis'] as Map<String, dynamic>,),
      testing: TestingConfig.fromJson(json['testing'] as Map<String, dynamic>,),
      documentation: DocumentationConfig.fromJson(
          json['documentation'] as Map<String, dynamic>,),
    );

Map<String, dynamic> _$QualityConfigToJson(QualityConfig instance) =>
    <String, dynamic>{
      'codeAnalysis': instance.codeAnalysis,
      'testing': instance.testing,
      'documentation': instance.documentation,
    };

CodeAnalysisConfig _$CodeAnalysisConfigFromJson(Map<String, dynamic> json) =>
    CodeAnalysisConfig(
      enabled: json['enabled'] as bool,
      rules: $enumDecode(_$AnalysisRulesEnumMap, json['rules']),
    );

Map<String, dynamic> _$CodeAnalysisConfigToJson(CodeAnalysisConfig instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'rules': _$AnalysisRulesEnumMap[instance.rules],
    };

const _$AnalysisRulesEnumMap = {
  AnalysisRules.basic: 'basic',
  AnalysisRules.recommended: 'recommended',
  AnalysisRules.strict: 'strict',
};

TestingConfig _$TestingConfigFromJson(Map<String, dynamic> json) =>
    TestingConfig(
      minCoverage: (json['minCoverage'] as num).toInt(),
      requiredTests: json['requiredTests'] as bool,
    );

Map<String, dynamic> _$TestingConfigToJson(TestingConfig instance) =>
    <String, dynamic>{
      'minCoverage': instance.minCoverage,
      'requiredTests': instance.requiredTests,
    };

DocumentationConfig _$DocumentationConfigFromJson(Map<String, dynamic> json) =>
    DocumentationConfig(
      required: json['required'] as bool,
      format: $enumDecode(_$DocumentationFormatEnumMap, json['format']),
    );

Map<String, dynamic> _$DocumentationConfigToJson(
      DocumentationConfig instance,) =>
    <String, dynamic>{
      'required': instance.required,
      'format': _$DocumentationFormatEnumMap[instance.format],
    };

const _$DocumentationFormatEnumMap = {
  DocumentationFormat.dartdoc: 'dartdoc',
  DocumentationFormat.markdown: 'markdown',
  DocumentationFormat.wiki: 'wiki',
};

IntegrationConfig _$IntegrationConfigFromJson(Map<String, dynamic> json) =>
    IntegrationConfig(
      ide: json['ide'] as Map<String, dynamic>?,
      ci: json['ci'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$IntegrationConfigToJson(IntegrationConfig instance) =>
    <String, dynamic>{
      'ide': instance.ide,
      'ci': instance.ci,
    };

ConfigInheritance _$ConfigInheritanceFromJson(Map<String, dynamic> json) =>
    ConfigInheritance(
      baseConfig: json['baseConfig'] as String?,
      inheritsFrom: (json['inheritsFrom'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      mergeStrategy: $enumDecodeNullable(
            _$ConfigMergeStrategyEnumMap, json['mergeStrategy'],) ??
          ConfigMergeStrategy.merge,
      overrides: json['overrides'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ConfigInheritanceToJson(ConfigInheritance instance) =>
    <String, dynamic>{
      'baseConfig': instance.baseConfig,
      'inheritsFrom': instance.inheritsFrom,
      'mergeStrategy': _$ConfigMergeStrategyEnumMap[instance.mergeStrategy],
      'overrides': instance.overrides,
    };

const _$ConfigMergeStrategyEnumMap = {
  ConfigMergeStrategy.override: 'override',
  ConfigMergeStrategy.merge: 'merge',
  ConfigMergeStrategy.preserve: 'preserve',
};

TemplateOverrideConfig _$TemplateOverrideConfigFromJson(
      Map<String, dynamic> json,) =>
    TemplateOverrideConfig(
      templatePath: json['templatePath'] as String?,
      customVariables: (json['customVariables'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      excludeFiles: (json['excludeFiles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      includeFiles: (json['includeFiles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$TemplateOverrideConfigToJson(
      TemplateOverrideConfig instance,) =>
    <String, dynamic>{
      'templatePath': instance.templatePath,
      'customVariables': instance.customVariables,
      'excludeFiles': instance.excludeFiles,
      'includeFiles': instance.includeFiles,
    };

ValidationOverrideConfig _$ValidationOverrideConfigFromJson(
      Map<String, dynamic> json,) =>
    ValidationOverrideConfig(
      strictMode: json['strictMode'] as bool?,
      minCoverage: (json['minCoverage'] as num?)?.toInt(),
      allowWarnings: json['allowWarnings'] as bool? ?? false,
      customRules: (json['customRules'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ValidationOverrideConfigToJson(
      ValidationOverrideConfig instance,) =>
    <String, dynamic>{
      'strictMode': instance.strictMode,
      'minCoverage': instance.minCoverage,
      'allowWarnings': instance.allowWarnings,
      'customRules': instance.customRules,
    };

PerformanceSettings _$PerformanceSettingsFromJson(Map<String, dynamic> json) =>
    PerformanceSettings(
      parallelBuild: json['parallelBuild'] as bool? ?? true,
      cacheEnabled: json['cacheEnabled'] as bool? ?? true,
      maxMemoryUsage: (json['maxMemoryUsage'] as num?)?.toInt() ?? 2048,
      buildTimeout: (json['buildTimeout'] as num?)?.toInt() ?? 300,
      optimizationLevel: $enumDecodeNullable(
        _$OptimizationLevelEnumMap, json['optimizationLevel'],),
    );

Map<String, dynamic> _$PerformanceSettingsToJson(
      PerformanceSettings instance,) =>
    <String, dynamic>{
      'parallelBuild': instance.parallelBuild,
      'cacheEnabled': instance.cacheEnabled,
      'maxMemoryUsage': instance.maxMemoryUsage,
      'buildTimeout': instance.buildTimeout,
      'optimizationLevel':
          _$OptimizationLevelEnumMap[instance.optimizationLevel],
    };

const _$OptimizationLevelEnumMap = {
  OptimizationLevel.none: 'none',
  OptimizationLevel.basic: 'basic',
  OptimizationLevel.advanced: 'advanced',
  OptimizationLevel.maximum: 'maximum',
};
