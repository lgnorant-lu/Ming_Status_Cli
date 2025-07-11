/*
---------------------------------------------------------------
File name:          enterprise_parameter_validator.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级参数验证器 (Enterprise Parameter Validator)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.2 企业级参数化系统;
---------------------------------------------------------------
*/

import 'dart:convert';

import 'package:ming_status_cli/src/core/parameters/enterprise_template_parameter.dart';
import 'package:ming_status_cli/src/models/template_variable.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 验证规则类型
enum ValidationRuleType {
  /// 密码强度
  passwordStrength,

  /// 邮箱格式
  emailFormat,

  /// URL有效性
  urlValidity,

  /// 项目命名规范
  projectNaming,

  /// 版本号格式
  versionFormat,

  /// 域名格式
  domainFormat,

  /// IP地址格式
  ipAddressFormat,

  /// 端口号范围
  portRange,

  /// 文件路径格式
  filePathFormat,

  /// JSON格式
  jsonFormat,

  /// 自定义规则
  custom,
}

/// 异步验证类型
enum AsyncValidationType {
  /// API可用性检查
  apiAvailability,

  /// 域名可达性检查
  domainReachability,

  /// 数据库连接检查
  databaseConnection,

  /// 文件存在性检查
  fileExists,

  /// 目录存在性检查
  directoryExists,

  /// 网络连通性检查
  networkConnectivity,

  /// 自定义异步验证
  custom,
}

/// 验证结果严重性
enum ValidationSeverity {
  /// 信息
  info,

  /// 警告
  warning,

  /// 错误
  error,

  /// 致命错误
  fatal,
}

/// 企业级验证规则
class EnterpriseValidationRule {
  /// 创建企业级验证规则实例
  const EnterpriseValidationRule({
    required this.type,
    required this.validator,
    this.message,
    this.severity = ValidationSeverity.error,
    this.async = false,
    this.timeout = const Duration(seconds: 5),
    this.metadata = const {},
  });

  /// 验证规则类型
  final ValidationRuleType type;

  /// 验证函数
  final Future<bool> Function(dynamic value, Map<String, dynamic> context)
      validator;

  /// 验证失败消息
  final String? message;

  /// 验证严重性
  final ValidationSeverity severity;

  /// 是否为异步验证
  final bool async;

  /// 异步验证超时时间
  final Duration timeout;

  /// 额外元数据
  final Map<String, dynamic> metadata;
}

/// 跨参数验证规则
class CrossParameterValidationRule {
  /// 创建跨参数验证规则实例
  const CrossParameterValidationRule({
    required this.name,
    required this.parameters,
    required this.validator,
    this.message,
    this.severity = ValidationSeverity.error,
  });

  /// 规则名称
  final String name;

  /// 涉及的参数列表
  final List<String> parameters;

  /// 验证函数
  final bool Function(Map<String, dynamic> values) validator;

  /// 验证失败消息
  final String? message;

  /// 验证严重性
  final ValidationSeverity severity;
}

/// 企业级验证结果
class EnterpriseValidationResult extends TemplateVariableValidationResult {
  /// 创建企业级验证结果实例
  const EnterpriseValidationResult({
    required super.isValid,
    super.errors = const [],
    super.warnings = const [],
    this.infos = const [],
    this.fatals = const [],
    this.asyncResults = const {},
    this.crossParameterErrors = const [],
  });

  /// 创建成功结果
  factory EnterpriseValidationResult.success({
    List<String> warnings = const [],
    List<String> infos = const [],
  }) {
    return EnterpriseValidationResult(
      isValid: true,
      warnings: warnings,
      infos: infos,
    );
  }

  /// 创建失败结果
  factory EnterpriseValidationResult.failure({
    List<String> errors = const [],
    List<String> warnings = const [],
    List<String> infos = const [],
    List<String> fatals = const [],
    List<String> crossParameterErrors = const [],
  }) {
    return EnterpriseValidationResult(
      isValid: fatals.isEmpty && errors.isEmpty,
      errors: errors,
      warnings: warnings,
      infos: infos,
      fatals: fatals,
      crossParameterErrors: crossParameterErrors,
    );
  }

  /// 信息列表
  final List<String> infos;

  /// 致命错误列表
  final List<String> fatals;

  /// 异步验证结果
  final Map<String, bool> asyncResults;

  /// 跨参数验证错误
  final List<String> crossParameterErrors;

  /// 是否有致命错误
  bool get hasFatals => fatals.isNotEmpty;

  /// 是否有跨参数错误
  bool get hasCrossParameterErrors => crossParameterErrors.isNotEmpty;

  /// 获取所有消息
  List<String> get allMessages => [
        ...infos,
        ...warnings,
        ...errors,
        ...fatals,
        ...crossParameterErrors,
      ];
}

/// 企业级参数验证器
class EnterpriseParameterValidator {
  /// 创建企业级参数验证器实例
  EnterpriseParameterValidator({
    this.enableAsyncValidation = true,
    this.asyncTimeout = const Duration(seconds: 10),
    this.enableCrossParameterValidation = true,
  }) {
    _initializeBuiltinRules();
  }

  /// 是否启用异步验证
  final bool enableAsyncValidation;

  /// 异步验证超时时间
  final Duration asyncTimeout;

  /// 是否启用跨参数验证
  final bool enableCrossParameterValidation;

  /// 内置验证规则
  final Map<ValidationRuleType, EnterpriseValidationRule> _builtinRules = {};

  /// 自定义验证规则
  final Map<String, EnterpriseValidationRule> _customRules = {};

  /// 跨参数验证规则
  final List<CrossParameterValidationRule> _crossParameterRules = [];

  /// 验证企业级参数
  Future<EnterpriseValidationResult> validateParameter(
    EnterpriseTemplateParameter parameter,
    dynamic value, {
    Map<String, dynamic> context = const {},
  }) async {
    try {
      cli_logger.Logger.debug('开始验证企业级参数: ${parameter.name}');

      final errors = <String>[];
      final warnings = <String>[];
      final infos = <String>[];
      final fatals = <String>[];
      final asyncResults = <String, bool>{};

      // 1. 基础验证 (继承自TemplateVariable)
      final baseResult = parameter.validateValue(value);
      if (!baseResult.isValid) {
        errors.addAll(baseResult.errors);
      }
      warnings.addAll(baseResult.warnings);

      // 2. 企业级验证规则
      await _validateWithEnterpriseRules(
        parameter,
        value,
        context,
        errors,
        warnings,
        infos,
        fatals,
        asyncResults,
      );

      // 3. 敏感性验证
      _validateSensitivity(parameter, value, warnings, errors);

      // 4. 复合类型验证
      if (parameter.isComposite) {
        await _validateCompositeType(parameter, value, errors, warnings);
      }

      final isValid = fatals.isEmpty && errors.isEmpty;

      cli_logger.Logger.debug(
        '参数验证完成: ${parameter.name} - '
        '有效: $isValid, 错误: ${errors.length}, 警告: ${warnings.length}',
      );

      return EnterpriseValidationResult(
        isValid: isValid,
        errors: errors,
        warnings: warnings,
        infos: infos,
        fatals: fatals,
        asyncResults: asyncResults,
      );
    } catch (e) {
      cli_logger.Logger.error('参数验证异常', error: e);
      return EnterpriseValidationResult.failure(
        fatals: ['参数验证时发生异常: $e'],
      );
    }
  }

  /// 验证多个参数 (支持跨参数验证)
  Future<Map<String, EnterpriseValidationResult>> validateParameters(
    List<EnterpriseTemplateParameter> parameters,
    Map<String, dynamic> values, {
    Map<String, dynamic> context = const {},
  }) async {
    final results = <String, EnterpriseValidationResult>{};

    // 1. 单独验证每个参数
    for (final parameter in parameters) {
      final value = values[parameter.name];
      results[parameter.name] = await validateParameter(
        parameter,
        value,
        context: context,
      );
    }

    // 2. 跨参数验证
    if (enableCrossParameterValidation && _crossParameterRules.isNotEmpty) {
      final crossParameterErrors = <String>[];

      for (final rule in _crossParameterRules) {
        try {
          final ruleValues = <String, dynamic>{};
          for (final paramName in rule.parameters) {
            ruleValues[paramName] = values[paramName];
          }

          if (!rule.validator(ruleValues)) {
            crossParameterErrors.add(
              rule.message ?? '跨参数验证失败: ${rule.name}',
            );
          }
        } catch (e) {
          crossParameterErrors.add('跨参数验证异常: ${rule.name} - $e');
        }
      }

      // 将跨参数错误添加到相关参数的结果中
      if (crossParameterErrors.isNotEmpty) {
        for (final rule in _crossParameterRules) {
          for (final paramName in rule.parameters) {
            if (results.containsKey(paramName)) {
              final currentResult = results[paramName]!;
              results[paramName] = EnterpriseValidationResult(
                isValid: currentResult.isValid && crossParameterErrors.isEmpty,
                errors: currentResult.errors,
                warnings: currentResult.warnings,
                infos: currentResult.infos,
                fatals: currentResult.fatals,
                asyncResults: currentResult.asyncResults,
                crossParameterErrors: crossParameterErrors,
              );
            }
          }
        }
      }
    }

    return results;
  }

  /// 添加自定义验证规则
  void addCustomRule(String name, EnterpriseValidationRule rule) {
    _customRules[name] = rule;
    cli_logger.Logger.debug('添加自定义验证规则: $name');
  }

  /// 添加跨参数验证规则
  void addCrossParameterRule(CrossParameterValidationRule rule) {
    _crossParameterRules.add(rule);
    cli_logger.Logger.debug('添加跨参数验证规则: ${rule.name}');
  }

  /// 使用企业级规则验证
  Future<void> _validateWithEnterpriseRules(
    EnterpriseTemplateParameter parameter,
    dynamic value,
    Map<String, dynamic> context,
    List<String> errors,
    List<String> warnings,
    List<String> infos,
    List<String> fatals,
    Map<String, bool> asyncResults,
  ) async {
    // 根据参数类型选择验证规则
    final rulesToApply = <EnterpriseValidationRule>[];

    switch (parameter.enterpriseType) {
      case EnterpriseParameterType.password:
        if (_builtinRules.containsKey(ValidationRuleType.passwordStrength)) {
          rulesToApply.add(_builtinRules[ValidationRuleType.passwordStrength]!);
        }

      case EnterpriseParameterType.organization:
      case EnterpriseParameterType.team:
        if (_builtinRules.containsKey(ValidationRuleType.projectNaming)) {
          rulesToApply.add(_builtinRules[ValidationRuleType.projectNaming]!);
        }

      default:
        break;
    }

    // 应用验证规则
    for (final rule in rulesToApply) {
      try {
        if (rule.async && enableAsyncValidation) {
          final result =
              await rule.validator(value, context).timeout(rule.timeout);
          asyncResults[rule.type.name] = result;

          if (!result) {
            _addValidationMessage(
              rule.message ?? '异步验证失败: ${rule.type.name}',
              rule.severity,
              errors,
              warnings,
              infos,
              fatals,
            );
          }
        } else if (!rule.async) {
          final result = await rule.validator(value, context);

          if (!result) {
            _addValidationMessage(
              rule.message ?? '验证失败: ${rule.type.name}',
              rule.severity,
              errors,
              warnings,
              infos,
              fatals,
            );
          }
        }
      } catch (e) {
        _addValidationMessage(
          '验证规则执行异常: ${rule.type.name} - $e',
          ValidationSeverity.error,
          errors,
          warnings,
          infos,
          fatals,
        );
      }
    }
  }

  /// 验证敏感性
  void _validateSensitivity(
    EnterpriseTemplateParameter parameter,
    dynamic value,
    List<String> warnings,
    List<String> errors,
  ) {
    if (parameter.isSensitive && value != null) {
      final valueStr = value.toString();

      // 检查敏感信息是否以明文形式存储
      if (valueStr.isNotEmpty && !_isEncrypted(valueStr)) {
        warnings.add('敏感参数 ${parameter.name} 应该加密存储');
      }

      // 检查敏感信息长度
      if (parameter.sensitivity == ParameterSensitivity.secret &&
          valueStr.length < 8) {
        errors.add('绝密参数 ${parameter.name} 长度不能少于8个字符');
      }
    }
  }

  /// 验证复合类型
  Future<void> _validateCompositeType(
    EnterpriseTemplateParameter parameter,
    dynamic value,
    List<String> errors,
    List<String> warnings,
  ) async {
    if (value == null) return;

    try {
      Map<String, dynamic> config;

      if (value is String) {
        config = json.decode(value) as Map<String, dynamic>;
      } else if (value is Map) {
        config = Map<String, dynamic>.from(value);
      } else {
        errors.add('复合类型参数 ${parameter.name} 必须是JSON字符串或Map对象');
        return;
      }

      // 根据复合类型验证必需字段
      switch (parameter.enterpriseType) {
        case EnterpriseParameterType.databaseConfig:
          _validateDatabaseConfig(config, parameter.name, errors, warnings);

        case EnterpriseParameterType.authConfig:
          _validateAuthConfig(config, parameter.name, errors, warnings);

        case EnterpriseParameterType.deploymentConfig:
          _validateDeploymentConfig(config, parameter.name, errors, warnings);

        case EnterpriseParameterType.securityConfig:
          _validateSecurityConfig(config, parameter.name, errors, warnings);

        default:
          break;
      }
    } catch (e) {
      errors.add('复合类型参数 ${parameter.name} 格式无效: $e');
    }
  }

  /// 验证数据库配置
  void _validateDatabaseConfig(
    Map<String, dynamic> config,
    String paramName,
    List<String> errors,
    List<String> warnings,
  ) {
    final requiredFields = ['host', 'port', 'database', 'username'];
    for (final field in requiredFields) {
      if (!config.containsKey(field) || config[field] == null) {
        errors.add('数据库配置 $paramName 缺少必需字段: $field');
      }
    }

    // 端口号验证
    if (config['port'] is int) {
      final port = config['port'] as int;
      if (port < 1 || port > 65535) {
        errors.add('数据库配置 $paramName 端口号无效: $port');
      }
    }
  }

  /// 验证认证配置
  void _validateAuthConfig(
    Map<String, dynamic> config,
    String paramName,
    List<String> errors,
    List<String> warnings,
  ) {
    if (!config.containsKey('type')) {
      errors.add('认证配置 $paramName 缺少认证类型');
      return;
    }

    final authType = config['type'].toString().toLowerCase();
    switch (authType) {
      case 'oauth2':
        final requiredFields = ['client_id', 'client_secret', 'redirect_uri'];
        for (final field in requiredFields) {
          if (!config.containsKey(field)) {
            errors.add('OAuth2配置 $paramName 缺少必需字段: $field');
          }
        }

      case 'jwt':
        if (!config.containsKey('secret_key')) {
          errors.add('JWT配置 $paramName 缺少密钥');
        }

      default:
        warnings.add('认证配置 $paramName 使用了未知的认证类型: $authType');
    }
  }

  /// 验证部署配置
  void _validateDeploymentConfig(
    Map<String, dynamic> config,
    String paramName,
    List<String> errors,
    List<String> warnings,
  ) {
    final requiredFields = ['environment', 'region'];
    for (final field in requiredFields) {
      if (!config.containsKey(field)) {
        errors.add('部署配置 $paramName 缺少必需字段: $field');
      }
    }
  }

  /// 验证安全配置
  void _validateSecurityConfig(
    Map<String, dynamic> config,
    String paramName,
    List<String> errors,
    List<String> warnings,
  ) {
    if (config.containsKey('encryption') && config['encryption'] == false) {
      warnings.add('安全配置 $paramName 未启用加密');
    }

    if (config.containsKey('ssl') && config['ssl'] == false) {
      warnings.add('安全配置 $paramName 未启用SSL');
    }
  }

  /// 添加验证消息到相应列表
  void _addValidationMessage(
    String message,
    ValidationSeverity severity,
    List<String> errors,
    List<String> warnings,
    List<String> infos,
    List<String> fatals,
  ) {
    switch (severity) {
      case ValidationSeverity.info:
        infos.add(message);
      case ValidationSeverity.warning:
        warnings.add(message);
      case ValidationSeverity.error:
        errors.add(message);
      case ValidationSeverity.fatal:
        fatals.add(message);
    }
  }

  /// 检查字符串是否已加密
  bool _isEncrypted(String value) {
    // 简单的加密检测逻辑
    // 实际应用中应该使用更复杂的检测算法
    return value.startsWith('enc:') ||
        value.startsWith('-----BEGIN') ||
        (value.length > 20 && !RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(value));
  }

  /// 初始化内置验证规则
  void _initializeBuiltinRules() {
    // 密码强度验证
    _builtinRules[ValidationRuleType.passwordStrength] =
        EnterpriseValidationRule(
      type: ValidationRuleType.passwordStrength,
      validator: (value, context) async {
        if (value is! String) return false;
        final password = value;

        // 密码强度检查: 至少8位，包含大小写字母、数字和特殊字符
        return password.length >= 8 &&
            RegExp('[A-Z]').hasMatch(password) &&
            RegExp('[a-z]').hasMatch(password) &&
            RegExp('[0-9]').hasMatch(password) &&
            RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
      },
      message: '密码必须至少8位，包含大小写字母、数字和特殊字符',
    );

    // 邮箱格式验证
    _builtinRules[ValidationRuleType.emailFormat] = EnterpriseValidationRule(
      type: ValidationRuleType.emailFormat,
      validator: (value, context) async {
        if (value is! String) return false;
        return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch(value);
      },
      message: '邮箱格式无效',
    );

    // URL有效性验证
    _builtinRules[ValidationRuleType.urlValidity] = EnterpriseValidationRule(
      type: ValidationRuleType.urlValidity,
      validator: (value, context) async {
        if (value is! String) return false;
        try {
          final uri = Uri.parse(value);
          return uri.hasScheme && uri.hasAuthority;
        } catch (e) {
          return false;
        }
      },
      message: 'URL格式无效',
    );

    // 项目命名规范验证
    _builtinRules[ValidationRuleType.projectNaming] = EnterpriseValidationRule(
      type: ValidationRuleType.projectNaming,
      validator: (value, context) async {
        if (value is! String) return false;
        final name = value;

        // 项目名称规范: 只能包含字母、数字、下划线和连字符，不能以数字开头
        return RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$').hasMatch(name) &&
            name.length >= 2 &&
            name.length <= 50;
      },
      message: '项目名称只能包含字母、数字、下划线和连字符，不能以数字开头，长度2-50字符',
    );

    // 版本号格式验证
    _builtinRules[ValidationRuleType.versionFormat] = EnterpriseValidationRule(
      type: ValidationRuleType.versionFormat,
      validator: (value, context) async {
        if (value is! String) return false;
        return RegExp(r'^\d+\.\d+\.\d+(-[a-zA-Z0-9]+)?$').hasMatch(value);
      },
      message: '版本号格式无效，应为 x.y.z 或 x.y.z-suffix',
    );
  }
}
