/*
---------------------------------------------------------------
File name:          enterprise_template_parameter.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级模板参数系统 (Enterprise Template Parameter System)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.2 企业级参数化系统;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/models/template_variable.dart';

/// 企业级参数类型
enum EnterpriseParameterType {
  /// 基础类型
  string,
  boolean,
  number,
  enumeration,
  list,

  /// 企业级类型
  organization,
  team,
  environment,
  compliance,

  /// 复合类型
  databaseConfig,
  authConfig,
  deploymentConfig,
  securityConfig,

  /// 敏感类型
  password,
  apiKey,
  certificate,
  token,
}

/// 参数敏感性级别
enum ParameterSensitivity {
  /// 公开信息
  public,

  /// 内部信息
  internal,

  /// 机密信息
  confidential,

  /// 绝密信息
  secret,
}

/// 参数依赖关系
class ParameterDependency {
  /// 创建参数依赖关系实例
  const ParameterDependency({
    required this.dependsOn,
    required this.condition,
    this.whenValue,
    this.whenCondition,
  });

  /// 依赖的参数名
  final String dependsOn;

  /// 依赖条件类型
  final DependencyCondition condition;

  /// 当依赖参数等于此值时生效
  final dynamic whenValue;

  /// 自定义条件表达式
  final String? whenCondition;
}

/// 依赖条件类型
enum DependencyCondition {
  /// 等于
  equals,

  /// 不等于
  notEquals,

  /// 包含
  contains,

  /// 不包含
  notContains,

  /// 存在
  exists,

  /// 不存在
  notExists,

  /// 自定义条件
  custom,
}

/// 参数计算规则
class ParameterComputation {
  /// 创建参数计算规则实例
  const ParameterComputation({
    required this.expression,
    this.dependencies = const [],
    this.description,
  });

  /// 计算表达式
  final String expression;

  /// 依赖的参数列表
  final List<String> dependencies;

  /// 计算描述
  final String? description;
}

/// 企业级模板参数
class EnterpriseTemplateParameter extends TemplateVariable {
  /// 创建企业级模板参数实例
  EnterpriseTemplateParameter({
    required super.name,
    required this.enterpriseType,
    super.description,
    super.defaultValue,
    super.prompt,
    super.optional = false,
    super.validation,
    super.values,
    this.sensitivity = ParameterSensitivity.public,
    this.category,
    this.group,
    this.order = 0,
    this.dependencies = const [],
    this.computation,
    this.metadata = const {},
    this.tags = const [],
    this.examples = const [],
    this.helpUrl,
  }) : super(type: _mapEnterpriseTypeToBasic(enterpriseType));

  /// 从Map创建企业级参数
  factory EnterpriseTemplateParameter.fromMap(
      String name, Map<String, dynamic> map,) {
    // 解析企业级类型
    final typeStr = map['enterprise_type']?.toString() ??
        map['type']?.toString() ??
        'string';
    final enterpriseType = _parseEnterpriseType(typeStr);

    // 解析敏感性级别
    final sensitivityStr = map['sensitivity']?.toString() ?? 'public';
    final sensitivity = _parseSensitivity(sensitivityStr);

    // 解析依赖关系
    final dependencies = <ParameterDependency>[];
    if (map['dependencies'] is List) {
      for (final dep in map['dependencies'] as List) {
        if (dep is Map<String, dynamic>) {
          dependencies.add(_parseDependency(dep));
        }
      }
    }

    // 解析计算规则
    ParameterComputation? computation;
    if (map['computation'] is Map<String, dynamic>) {
      computation =
          _parseComputation(map['computation'] as Map<String, dynamic>);
    }

    // 解析验证规则
    TemplateVariableValidation? validation;
    if (map['validation'] is Map<String, dynamic>) {
      validation = TemplateVariableValidation.fromMap(
        map['validation'] as Map<String, dynamic>,
      );
    }

    return EnterpriseTemplateParameter(
      name: name,
      enterpriseType: enterpriseType,
      description: map['description']?.toString(),
      defaultValue: map['default'],
      prompt: map['prompt']?.toString(),
      optional: map['optional'] == true,
      validation: validation,
      values: map['values'] is List
          ? List<dynamic>.from(map['values'] as List)
          : null,
      sensitivity: sensitivity,
      category: map['category']?.toString(),
      group: map['group']?.toString(),
      order: map['order'] is int ? map['order'] as int : 0,
      dependencies: dependencies,
      computation: computation,
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : const {},
      tags: map['tags'] is List
          ? List<String>.from(map['tags'] as List)
          : const [],
      examples: map['examples'] is List
          ? List<dynamic>.from(map['examples'] as List)
          : const [],
      helpUrl: map['help_url']?.toString(),
    );
  }

  /// 企业级参数类型
  final EnterpriseParameterType enterpriseType;

  /// 敏感性级别
  final ParameterSensitivity sensitivity;

  /// 参数分类
  final String? category;

  /// 参数分组
  final String? group;

  /// 显示顺序
  final int order;

  /// 参数依赖关系
  final List<ParameterDependency> dependencies;

  /// 参数计算规则
  final ParameterComputation? computation;

  /// 额外元数据
  final Map<String, dynamic> metadata;

  /// 参数标签
  final List<String> tags;

  /// 示例值
  final List<dynamic> examples;

  /// 帮助文档URL
  final String? helpUrl;

  /// 映射企业级类型到基础类型
  static TemplateVariableType _mapEnterpriseTypeToBasic(
      EnterpriseParameterType enterpriseType,) {
    switch (enterpriseType) {
      case EnterpriseParameterType.string:
      case EnterpriseParameterType.organization:
      case EnterpriseParameterType.team:
      case EnterpriseParameterType.environment:
      case EnterpriseParameterType.compliance:
      case EnterpriseParameterType.password:
      case EnterpriseParameterType.apiKey:
      case EnterpriseParameterType.certificate:
      case EnterpriseParameterType.token:
        return TemplateVariableType.string;

      case EnterpriseParameterType.boolean:
        return TemplateVariableType.boolean;

      case EnterpriseParameterType.number:
        return TemplateVariableType.number;

      case EnterpriseParameterType.enumeration:
        return TemplateVariableType.enumeration;

      case EnterpriseParameterType.list:
        return TemplateVariableType.list;

      case EnterpriseParameterType.databaseConfig:
      case EnterpriseParameterType.authConfig:
      case EnterpriseParameterType.deploymentConfig:
      case EnterpriseParameterType.securityConfig:
        return TemplateVariableType.string; // 复合类型作为JSON字符串处理
    }
  }

  /// 解析企业级参数类型
  static EnterpriseParameterType _parseEnterpriseType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'organization':
        return EnterpriseParameterType.organization;
      case 'team':
        return EnterpriseParameterType.team;
      case 'environment':
        return EnterpriseParameterType.environment;
      case 'compliance':
        return EnterpriseParameterType.compliance;
      case 'database_config':
      case 'databaseconfig':
        return EnterpriseParameterType.databaseConfig;
      case 'auth_config':
      case 'authconfig':
        return EnterpriseParameterType.authConfig;
      case 'deployment_config':
      case 'deploymentconfig':
        return EnterpriseParameterType.deploymentConfig;
      case 'security_config':
      case 'securityconfig':
        return EnterpriseParameterType.securityConfig;
      case 'password':
        return EnterpriseParameterType.password;
      case 'api_key':
      case 'apikey':
        return EnterpriseParameterType.apiKey;
      case 'certificate':
        return EnterpriseParameterType.certificate;
      case 'token':
        return EnterpriseParameterType.token;
      case 'boolean':
      case 'bool':
        return EnterpriseParameterType.boolean;
      case 'number':
      case 'int':
      case 'double':
        return EnterpriseParameterType.number;
      case 'enum':
      case 'enumeration':
        return EnterpriseParameterType.enumeration;
      case 'list':
      case 'array':
        return EnterpriseParameterType.list;
      case 'string':
      default:
        return EnterpriseParameterType.string;
    }
  }

  /// 解析敏感性级别
  static ParameterSensitivity _parseSensitivity(String sensitivityStr) {
    switch (sensitivityStr.toLowerCase()) {
      case 'internal':
        return ParameterSensitivity.internal;
      case 'confidential':
        return ParameterSensitivity.confidential;
      case 'secret':
        return ParameterSensitivity.secret;
      case 'public':
      default:
        return ParameterSensitivity.public;
    }
  }

  /// 解析依赖关系
  static ParameterDependency _parseDependency(Map<String, dynamic> map) {
    final conditionStr = map['condition']?.toString() ?? 'equals';
    final condition = _parseCondition(conditionStr);

    return ParameterDependency(
      dependsOn: map['depends_on']?.toString() ?? '',
      condition: condition,
      whenValue: map['when_value'],
      whenCondition: map['when_condition']?.toString(),
    );
  }

  /// 解析依赖条件
  static DependencyCondition _parseCondition(String conditionStr) {
    switch (conditionStr.toLowerCase()) {
      case 'not_equals':
      case 'notequals':
        return DependencyCondition.notEquals;
      case 'contains':
        return DependencyCondition.contains;
      case 'not_contains':
      case 'notcontains':
        return DependencyCondition.notContains;
      case 'exists':
        return DependencyCondition.exists;
      case 'not_exists':
      case 'notexists':
        return DependencyCondition.notExists;
      case 'custom':
        return DependencyCondition.custom;
      case 'equals':
      default:
        return DependencyCondition.equals;
    }
  }

  /// 解析计算规则
  static ParameterComputation _parseComputation(Map<String, dynamic> map) {
    return ParameterComputation(
      expression: map['expression']?.toString() ?? '',
      dependencies: map['dependencies'] is List
          ? List<String>.from(map['dependencies'] as List)
          : const [],
      description: map['description']?.toString(),
    );
  }

  /// 检查参数是否敏感
  bool get isSensitive =>
      sensitivity == ParameterSensitivity.confidential ||
      sensitivity == ParameterSensitivity.secret;

  /// 检查参数是否为复合类型
  bool get isComposite {
    switch (enterpriseType) {
      case EnterpriseParameterType.databaseConfig:
      case EnterpriseParameterType.authConfig:
      case EnterpriseParameterType.deploymentConfig:
      case EnterpriseParameterType.securityConfig:
        return true;
      case EnterpriseParameterType.string:
      case EnterpriseParameterType.boolean:
      case EnterpriseParameterType.number:
      case EnterpriseParameterType.enumeration:
      case EnterpriseParameterType.list:
      case EnterpriseParameterType.organization:
      case EnterpriseParameterType.team:
      case EnterpriseParameterType.environment:
      case EnterpriseParameterType.compliance:
      case EnterpriseParameterType.password:
      case EnterpriseParameterType.apiKey:
      case EnterpriseParameterType.certificate:
      case EnterpriseParameterType.token:
        return false;
    }
  }

  /// 检查参数是否有依赖
  bool get hasDependencies => dependencies.isNotEmpty;

  /// 检查参数是否为计算参数
  bool get isComputed => computation != null;

  /// 转换为Map
  @override
  Map<String, dynamic> toMap() {
    final baseMap = super.toMap();
    return {
      ...baseMap,
      'enterprise_type': enterpriseType.name,
      'sensitivity': sensitivity.name,
      if (category != null) 'category': category,
      if (group != null) 'group': group,
      'order': order,
      if (dependencies.isNotEmpty)
        'dependencies': dependencies
            .map((d) => {
                  'depends_on': d.dependsOn,
                  'condition': d.condition.name,
                  if (d.whenValue != null) 'when_value': d.whenValue,
                  if (d.whenCondition != null)
                    'when_condition': d.whenCondition,
                },)
            .toList(),
      if (computation != null)
        'computation': {
          'expression': computation!.expression,
          'dependencies': computation!.dependencies,
          if (computation!.description != null)
            'description': computation!.description,
        },
      if (metadata.isNotEmpty) 'metadata': metadata,
      if (tags.isNotEmpty) 'tags': tags,
      if (examples.isNotEmpty) 'examples': examples,
      if (helpUrl != null) 'help_url': helpUrl,
    };
  }

  @override
  String toString() {
    return 'EnterpriseTemplateParameter(name: $name, type: ${enterpriseType.name}, '
        'sensitivity: ${sensitivity.name}, optional: $optional)';
  }
}
