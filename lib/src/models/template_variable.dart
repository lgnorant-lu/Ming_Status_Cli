/*
---------------------------------------------------------------
File name:          template_variable.dart
Author:             lgnorant-lu
Date created:       2025/06/30
Last modified:      2025/06/30
Dart Version:       3.2+
Description:        模板变量定义和验证系统 
                    (Template variable definition and validation system)
---------------------------------------------------------------
*/

/// 模板变量类型枚举
enum TemplateVariableType {
  /// 字符串类型
  string,
  /// 布尔类型
  boolean,
  /// 数值类型
  number,
  /// 枚举类型
  enumeration,
  /// 列表类型
  list,
}

/// 模板变量验证规则
class TemplateVariableValidation {
  /// 创建模板变量验证规则实例
  const TemplateVariableValidation({
    this.pattern,
    this.minLength,
    this.maxLength,
    this.minValue,
    this.maxValue,
    this.message,
    this.required = false,
  });

  /// 从Map创建验证规则
  factory TemplateVariableValidation.fromMap(Map<String, dynamic> map) {
    return TemplateVariableValidation(
      pattern: map['pattern']?.toString(),
      minLength: map['min_length'] is int ? map['min_length'] as int : null,
      maxLength: map['max_length'] is int ? map['max_length'] as int : null,
      minValue: map['min_value'] is num ? map['min_value'] as num : null,
      maxValue: map['max_value'] is num ? map['max_value'] as num : null,
      message: map['message']?.toString(),
      required: map['required'] == true,
    );
  }

  /// 正则表达式模式（用于字符串验证）
  final String? pattern;
  
  /// 最小长度（用于字符串和列表）
  final int? minLength;
  
  /// 最大长度（用于字符串和列表）
  final int? maxLength;
  
  /// 最小值（用于数值）
  final num? minValue;
  
  /// 最大值（用于数值）
  final num? maxValue;
  
  /// 验证失败时的错误信息
  final String? message;
  
  /// 是否必需
  final bool required;

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      if (pattern != null) 'pattern': pattern,
      if (minLength != null) 'min_length': minLength,
      if (maxLength != null) 'max_length': maxLength,
      if (minValue != null) 'min_value': minValue,
      if (maxValue != null) 'max_value': maxValue,
      if (message != null) 'message': message,
      'required': required,
    };
  }
}

/// 模板变量定义
class TemplateVariable {
  /// 创建模板变量定义实例
  const TemplateVariable({
    required this.name,
    required this.type,
    this.description,
    this.defaultValue,
    this.prompt,
    this.optional = false,
    this.validation,
    this.values,
  });

  /// 从Map创建变量定义
  factory TemplateVariable.fromMap(String name, Map<String, dynamic> map) {
    // 解析变量类型
    final typeStr = map['type']?.toString().toLowerCase() ?? 'string';
    final type = _parseVariableType(typeStr);

    // 解析验证规则
    TemplateVariableValidation? validation;
    if (map.containsKey('validation') && map['validation'] is Map) {
      validation = TemplateVariableValidation.fromMap(
        Map<String, dynamic>.from(map['validation'] as Map),
      );
    }

    // 解析可选值
    List<dynamic>? values;
    if (map.containsKey('values') && map['values'] is List) {
      values = List<dynamic>.from(map['values'] as List);
    }

    return TemplateVariable(
      name: name,
      type: type,
      description: map['description']?.toString(),
      defaultValue: map['default'],
      prompt: map['prompt']?.toString(),
      optional: map['optional'] == true,
      validation: validation,
      values: values,
    );
  }

  /// 变量名称
  final String name;
  
  /// 变量类型
  final TemplateVariableType type;
  
  /// 变量描述
  final String? description;
  
  /// 默认值
  final dynamic defaultValue;
  
  /// 用户输入提示
  final String? prompt;
  
  /// 是否可选
  final bool optional;
  
  /// 验证规则
  final TemplateVariableValidation? validation;
  
  /// 可选值列表（用于枚举和列表类型）
  final List<dynamic>? values;

  /// 解析变量类型字符串
  static TemplateVariableType _parseVariableType(String typeStr) {
    switch (typeStr) {
      case 'boolean':
      case 'bool':
        return TemplateVariableType.boolean;
      case 'number':
      case 'int':
      case 'double':
      case 'num':
        return TemplateVariableType.number;
      case 'enum':
      case 'enumeration':
        return TemplateVariableType.enumeration;
      case 'list':
      case 'array':
        return TemplateVariableType.list;
      case 'string':
      default:
        return TemplateVariableType.string;
    }
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
      if (prompt != null) 'prompt': prompt,
      'optional': optional,
      if (validation != null) 'validation': validation!.toMap(),
      if (values != null) 'values': values,
    };
  }

  /// 验证变量值
  TemplateVariableValidationResult validateValue(dynamic value) {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // 检查必需性
      if (!optional && (value == null || _isEmptyValue(value))) {
        return TemplateVariableValidationResult.invalid(
          ['变量 $name 是必需的，不能为空'],
        );
      }

      // 如果值为空且是可选的，则跳过其他验证
      if (optional && (value == null || _isEmptyValue(value))) {
        return TemplateVariableValidationResult.valid();
      }

      // 类型验证
      if (!_validateType(value)) {
        errors.add('变量 $name 的值类型不匹配，期望 ${type.name}');
      }

      // 执行具体的验证规则
      if (validation != null) {
        final validationErrors = _validateWithRules(value);
        errors.addAll(validationErrors);
      }

      // 枚举值验证
      if (type == TemplateVariableType.enumeration && values != null) {
        if (!values!.contains(value)) {
          errors.add('变量 $name 的值必须是以下之一: '
              '${values!.join(', ')}');
        }
      }

      // 列表类型验证
      if (type == TemplateVariableType.list && 
          values != null && value is List) {
        final invalidValues = <dynamic>[];
        for (final item in value) {
          if (!values!.contains(item)) {
            invalidValues.add(item);
          }
        }
        if (invalidValues.isNotEmpty) {
          errors.add('变量 $name 包含无效值: '
              '${invalidValues.join(', ')}');
        }
      }

      return errors.isEmpty 
          ? TemplateVariableValidationResult.valid(warnings: warnings)
          : TemplateVariableValidationResult.invalid(
              errors, 
              warnings: warnings,
          );

    } catch (e) {
      return TemplateVariableValidationResult.invalid(
        ['验证变量 $name 时发生异常: $e'],
      );
    }
  }

  /// 检查是否为空值
  bool _isEmptyValue(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is List) return value.isEmpty;
    return false;
  }

  /// 验证值类型
  bool _validateType(dynamic value) {
    switch (type) {
      case TemplateVariableType.string:
        return value is String;
      case TemplateVariableType.boolean:
        return value is bool;
      case TemplateVariableType.number:
        return value is num;
      case TemplateVariableType.enumeration:
        return true; // 枚举类型在后续验证中检查
      case TemplateVariableType.list:
        return value is List;
    }
  }

  /// 使用验证规则进行验证
  List<String> _validateWithRules(dynamic value) {
    final errors = <String>[];
    final val = validation!;

    switch (type) {
      case TemplateVariableType.string:
        if (value is String) {
          // 长度验证
          if (val.minLength != null && value.length < val.minLength!) {
            errors.add(val.message ?? '变量 $name 长度不能小于 ${val.minLength}');
          }
          if (val.maxLength != null && value.length > val.maxLength!) {
            errors.add(val.message ?? '变量 $name 长度不能大于 ${val.maxLength}');
          }
          
          // 正则表达式验证
          if (val.pattern != null) {
            try {
              final regex = RegExp(val.pattern!);
              if (!regex.hasMatch(value)) {
                errors.add(val.message ?? '变量 $name 格式不正确');
              }
            } catch (e) {
              errors.add('正则表达式验证失败: $e');
            }
          }
        }

      case TemplateVariableType.number:
        if (value is num) {
          // 数值范围验证
          if (val.minValue != null && value < val.minValue!) {
            errors.add(val.message ?? '变量 $name 不能小于 ${val.minValue}');
          }
          if (val.maxValue != null && value > val.maxValue!) {
            errors.add(val.message ?? '变量 $name 不能大于 ${val.maxValue}');
          }
        }

      case TemplateVariableType.list:
        if (value is List) {
          // 列表长度验证
          if (val.minLength != null && value.length < val.minLength!) {
            errors.add(val.message ?? '变量 $name 至少需要 ${val.minLength} 个元素');
          }
          if (val.maxLength != null && value.length > val.maxLength!) {
            errors.add(val.message ?? '变量 $name 最多只能有 ${val.maxLength} 个元素');
          }
        }

      case TemplateVariableType.boolean:
      case TemplateVariableType.enumeration:
        // 这些类型通常不需要额外的规则验证
        break;
    }

    return errors;
  }

  /// 获取适当的默认值
  dynamic getEffectiveDefaultValue() {
    if (defaultValue != null) {
      return defaultValue;
    }

    // 提供类型相关的默认值
    switch (type) {
      case TemplateVariableType.string:
        return '';
      case TemplateVariableType.boolean:
        return false;
      case TemplateVariableType.number:
        return 0;
      case TemplateVariableType.enumeration:
        return (values?.isNotEmpty ?? false) ? values!.first : null;
      case TemplateVariableType.list:
        return <dynamic>[];
    }
  }

  @override
  String toString() {
    return 'TemplateVariable(name: $name, type: ${type.name}, '
        'optional: $optional)';
  }
}

/// 变量验证结果
class TemplateVariableValidationResult {
  /// 创建变量验证结果实例
  const TemplateVariableValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  /// 创建有效结果
  factory TemplateVariableValidationResult.valid({
    List<String> warnings = const [],
  }) {
    return TemplateVariableValidationResult(
      isValid: true,
      warnings: warnings,
    );
  }

  /// 创建无效结果
  factory TemplateVariableValidationResult.invalid(
    List<String> errors, {
    List<String> warnings = const [],
  }) {
    return TemplateVariableValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings,
    );
  }

  /// 是否有效
  final bool isValid;
  
  /// 错误信息列表
  final List<String> errors;
  
  /// 警告信息列表
  final List<String> warnings;

  /// 是否有警告
  bool get hasWarnings => warnings.isNotEmpty;

  /// 是否有错误
  bool get hasErrors => errors.isNotEmpty;

  @override
  String toString() {
    return 'TemplateVariableValidationResult(isValid: $isValid, '
           'errors: ${errors.length}, warnings: ${warnings.length})';
  }
} 
