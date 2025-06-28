/*
---------------------------------------------------------------
File name:          workspace_config.dart
Author:             Ignorant-lu
Date created:       2025/06/29
Last modified:      2025/06/29
Dart Version:       3.2+
Description:        工作空间配置数据模型 (Workspace configuration data model)
---------------------------------------------------------------
Change History:
    2025/06/29: Initial creation - 基础工作空间配置模型;
---------------------------------------------------------------
*/

import 'package:json_annotation/json_annotation.dart';

part 'workspace_config.g.dart';

/// 工作空间配置类
/// 管理整个Ming Status工作空间的配置信息
@JsonSerializable()
class WorkspaceConfig {
  /// 工作空间基本信息
  final WorkspaceInfo workspace;
  
  /// 模板配置
  final TemplateConfig templates;
  
  /// 默认设置
  final DefaultSettings defaults;
  
  /// 验证规则
  final ValidationConfig validation;

  const WorkspaceConfig({
    required this.workspace,
    required this.templates,
    required this.defaults,
    required this.validation,
  });

  /// 从JSON创建实例
  factory WorkspaceConfig.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceConfigFromJson(json);

  /// 转换为JSON
  Map<String, dynamic> toJson() => _$WorkspaceConfigToJson(this);

  /// 创建默认配置
  factory WorkspaceConfig.defaultConfig() {
    return WorkspaceConfig(
      workspace: WorkspaceInfo(
        name: 'my_modules',
        version: '1.0.0',
        description: 'Ming Status模块工作空间',
      ),
      templates: TemplateConfig(
        source: TemplateSource.local,
        localPath: './templates',
        remoteRegistry: null,
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
    );
  }

  /// 拷贝并更新配置
  WorkspaceConfig copyWith({
    WorkspaceInfo? workspace,
    TemplateConfig? templates,
    DefaultSettings? defaults,
    ValidationConfig? validation,
  }) {
    return WorkspaceConfig(
      workspace: workspace ?? this.workspace,
      templates: templates ?? this.templates,
      defaults: defaults ?? this.defaults,
      validation: validation ?? this.validation,
    );
  }
}

/// 工作空间基本信息
@JsonSerializable()
class WorkspaceInfo {
  /// 工作空间名称
  final String name;
  
  /// 版本号
  final String version;
  
  /// 描述
  final String? description;

  const WorkspaceInfo({
    required this.name,
    required this.version,
    this.description,
  });

  factory WorkspaceInfo.fromJson(Map<String, dynamic> json) =>
      _$WorkspaceInfoFromJson(json);

  Map<String, dynamic> toJson() => _$WorkspaceInfoToJson(this);
}

/// 模板配置
@JsonSerializable()
class TemplateConfig {
  /// 模板来源
  final TemplateSource source;
  
  /// 本地模板路径
  final String? localPath;
  
  /// 远程模板注册表
  final String? remoteRegistry;

  const TemplateConfig({
    required this.source,
    this.localPath,
    this.remoteRegistry,
  });

  factory TemplateConfig.fromJson(Map<String, dynamic> json) =>
      _$TemplateConfigFromJson(json);

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
  /// 默认作者
  final String author;
  
  /// 默认许可证
  final String license;
  
  /// 默认Dart版本
  final String dartVersion;

  const DefaultSettings({
    required this.author,
    required this.license,
    required this.dartVersion,
  });

  factory DefaultSettings.fromJson(Map<String, dynamic> json) =>
      _$DefaultSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$DefaultSettingsToJson(this);
}

/// 验证配置
@JsonSerializable()
class ValidationConfig {
  /// 严格模式
  final bool strictMode;
  
  /// 要求测试
  final bool requireTests;
  
  /// 最小覆盖率
  final int minCoverage;

  const ValidationConfig({
    required this.strictMode,
    required this.requireTests,
    required this.minCoverage,
  });

  factory ValidationConfig.fromJson(Map<String, dynamic> json) =>
      _$ValidationConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ValidationConfigToJson(this);
} 