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
    );

Map<String, dynamic> _$WorkspaceConfigToJson(WorkspaceConfig instance) =>
    <String, dynamic>{
      'workspace': instance.workspace.toJson(),
      'templates': instance.templates.toJson(),
      'defaults': instance.defaults.toJson(),
      'validation': instance.validation.toJson(),
    };

WorkspaceInfo _$WorkspaceInfoFromJson(Map<String, dynamic> json) =>
    WorkspaceInfo(
      name: json['name'] as String,
      version: json['version'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$WorkspaceInfoToJson(WorkspaceInfo instance) =>
    <String, dynamic>{
      'name': instance.name,
      'version': instance.version,
      'description': instance.description,
    };

TemplateConfig _$TemplateConfigFromJson(Map<String, dynamic> json) =>
    TemplateConfig(
      source: $enumDecode(_$TemplateSourceEnumMap, json['source']),
      localPath: json['localPath'] as String?,
      remoteRegistry: json['remoteRegistry'] as String?,
    );

Map<String, dynamic> _$TemplateConfigToJson(TemplateConfig instance) =>
    <String, dynamic>{
      'source': _$TemplateSourceEnumMap[instance.source]!,
      'localPath': instance.localPath,
      'remoteRegistry': instance.remoteRegistry,
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
    );

Map<String, dynamic> _$DefaultSettingsToJson(DefaultSettings instance) =>
    <String, dynamic>{
      'author': instance.author,
      'license': instance.license,
      'dartVersion': instance.dartVersion,
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
