/*
---------------------------------------------------------------
File name:          template_variable_processor.dart
Author:             lgnorant-lu
Date created:       2025/06/30
Last modified:      2025/06/30
Dart Version:       3.2+
Description:        模板变量处理器系统 (Template variable processor system)
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/models/template_variable.dart';
import 'package:ming_status_cli/src/utils/string_utils.dart';

/// 变量处理器类型
enum VariableProcessorType {
  /// snake_case转换器
  snakeCaseConverter,

  /// PascalCase转换器
  pascalCaseConverter,

  /// camelCase转换器
  camelCaseConverter,

  /// kebab-case转换器
  kebabCaseConverter,

  /// UPPER_CASE转换器
  upperCaseConverter,

  /// lower_case转换器
  lowerCaseConverter,

  /// 标题格式转换器
  titleCaseConverter,

  /// 时间戳生成器
  timestampGenerator,

  /// 路径转换器
  pathConverter,

  /// 自定义处理器
  custom,
}

/// 变量处理器配置
class VariableProcessorConfig {
  /// 创建变量处理器配置实例
  const VariableProcessorConfig({
    required this.type,
    required this.target,
    this.parameters = const {},
  });

  /// 从Map创建配置
  factory VariableProcessorConfig.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type']?.toString() ?? 'custom';
    final type = _parseProcessorType(typeStr);

    return VariableProcessorConfig(
      type: type,
      target: map['target']?.toString() ?? '',
      parameters: Map<String, dynamic>.from(map['parameters'] as Map? ?? {}),
    );
  }

  /// 处理器类型
  final VariableProcessorType type;

  /// 目标变量名称
  final String target;

  /// 处理器参数
  final Map<String, dynamic> parameters;

  /// 解析处理器类型
  static VariableProcessorType _parseProcessorType(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'snake_case_converter':
        return VariableProcessorType.snakeCaseConverter;
      case 'pascal_case_converter':
        return VariableProcessorType.pascalCaseConverter;
      case 'camel_case_converter':
        return VariableProcessorType.camelCaseConverter;
      case 'kebab_case_converter':
        return VariableProcessorType.kebabCaseConverter;
      case 'upper_case_converter':
        return VariableProcessorType.upperCaseConverter;
      case 'lower_case_converter':
        return VariableProcessorType.lowerCaseConverter;
      case 'title_case_converter':
        return VariableProcessorType.titleCaseConverter;
      case 'timestamp_generator':
        return VariableProcessorType.timestampGenerator;
      case 'path_converter':
        return VariableProcessorType.pathConverter;
      default:
        return VariableProcessorType.custom;
    }
  }
}

/// 变量处理结果
class VariableProcessingResult {
  /// 创建变量处理结果实例
  const VariableProcessingResult({
    required this.success,
    required this.variables,
    this.errors = const [],
    this.warnings = const [],
    this.generatedVariables = const {},
  });

  /// 创建成功结果
  factory VariableProcessingResult.success(
    Map<String, dynamic> variables, {
    List<String> warnings = const [],
    Map<String, dynamic> generatedVariables = const {},
  }) {
    return VariableProcessingResult(
      success: true,
      variables: variables,
      warnings: warnings,
      generatedVariables: generatedVariables,
    );
  }

  /// 创建失败结果
  factory VariableProcessingResult.failure(
    List<String> errors, {
    Map<String, dynamic> variables = const {},
    List<String> warnings = const [],
  }) {
    return VariableProcessingResult(
      success: false,
      variables: variables,
      errors: errors,
      warnings: warnings,
    );
  }

  /// 处理是否成功
  final bool success;

  /// 处理后的变量
  final Map<String, dynamic> variables;

  /// 错误信息
  final List<String> errors;

  /// 警告信息
  final List<String> warnings;

  /// 生成的额外变量
  final Map<String, dynamic> generatedVariables;
}

/// 模板变量处理器
class TemplateVariableProcessor {
  /// 创建模板变量处理器实例
  TemplateVariableProcessor({
    List<VariableProcessorConfig>? processors,
  }) : _processors = processors ?? [];

  /// 变量处理器配置列表
  final List<VariableProcessorConfig> _processors;

  /// 自定义处理器函数映射
  final Map<String, dynamic Function(String, Map<String, dynamic>)>
      _customProcessors = {};

  /// 注册自定义处理器
  void registerCustomProcessor(
    String name,
    dynamic Function(String, Map<String, dynamic>) processor,
  ) {
    _customProcessors[name] = processor;
  }

  /// 处理模板变量
  VariableProcessingResult processVariables({
    required Map<String, dynamic> variables,
    required List<TemplateVariable> variableDefinitions,
  }) {
    try {
      final processed = Map<String, dynamic>.from(variables);
      final generated = <String, dynamic>{};
      final warnings = <String>[];
      final errors = <String>[];

      // 首先验证所有变量
      for (final varDef in variableDefinitions) {
        final value = processed[varDef.name];
        final validationResult = varDef.validateValue(value);

        if (!validationResult.isValid) {
          errors.addAll(validationResult.errors);
        }

        if (validationResult.hasWarnings) {
          warnings.addAll(validationResult.warnings);
        }

        // 如果值为空且有默认值，使用默认值
        if ((value == null || _isEmptyValue(value)) &&
            varDef.defaultValue != null) {
          processed[varDef.name] = varDef.defaultValue;
        }
      }

      // 如果验证失败，直接返回
      if (errors.isNotEmpty) {
        return VariableProcessingResult.failure(errors, warnings: warnings);
      }

      // 应用变量处理器
      for (final processorConfig in _processors) {
        final targetValue = processed[processorConfig.target];
        if (targetValue != null) {
          final processedValue = _applyProcessor(
            processorConfig,
            targetValue.toString(),
            processed,
          );

          if (processedValue != null) {
            // 生成派生变量
            final derivedVariables = _generateDerivedVariables(
              processorConfig,
              targetValue.toString(),
              processedValue,
            );
            generated.addAll(derivedVariables);
          }
        }
      }

      // 生成标准派生变量
      final standardDerived = _generateStandardDerivedVariables(processed);
      generated.addAll(standardDerived);

      // 生成时间戳变量
      final timestampVars = _generateTimestampVariables();
      generated.addAll(timestampVars);

      // 合并生成的变量到结果中
      processed.addAll(generated);

      return VariableProcessingResult.success(
        processed,
        warnings: warnings,
        generatedVariables: generated,
      );
    } catch (e) {
      return VariableProcessingResult.failure(['变量处理过程中发生异常: $e']);
    }
  }

  /// 应用单个处理器
  dynamic _applyProcessor(
    VariableProcessorConfig config,
    String value,
    Map<String, dynamic> allVariables,
  ) {
    switch (config.type) {
      case VariableProcessorType.snakeCaseConverter:
        return StringUtils.toSnakeCase(value);
      case VariableProcessorType.pascalCaseConverter:
        return StringUtils.toPascalCase(value);
      case VariableProcessorType.camelCaseConverter:
        return StringUtils.toCamelCase(value);
      case VariableProcessorType.kebabCaseConverter:
        return StringUtils.toKebabCase(value);
      case VariableProcessorType.upperCaseConverter:
        return value.toUpperCase();
      case VariableProcessorType.lowerCaseConverter:
        return value.toLowerCase();
      case VariableProcessorType.titleCaseConverter:
        return _toTitleCase(value);
      case VariableProcessorType.timestampGenerator:
        return DateTime.now().toIso8601String();
      case VariableProcessorType.pathConverter:
        return value.replaceAll(RegExp(r'[^\w\-_.]'), '_');
      case VariableProcessorType.custom:
        final processorName = config.parameters['processor_name']?.toString();
        if (processorName != null &&
            _customProcessors.containsKey(processorName)) {
          return _customProcessors[processorName]!(value, config.parameters);
        }
        return value;
    }
  }

  /// 生成派生变量
  Map<String, dynamic> _generateDerivedVariables(
    VariableProcessorConfig config,
    String originalValue,
    dynamic processedValue,
  ) {
    final derived = <String, dynamic>{};
    final baseName = config.target;

    switch (config.type) {
      case VariableProcessorType.snakeCaseConverter:
        derived['${baseName}_snake_case'] = processedValue;
      case VariableProcessorType.pascalCaseConverter:
        derived['${baseName}_pascal_case'] = processedValue;
      case VariableProcessorType.camelCaseConverter:
        derived['${baseName}_camel_case'] = processedValue;
      case VariableProcessorType.kebabCaseConverter:
        derived['${baseName}_kebab_case'] = processedValue;
      case VariableProcessorType.upperCaseConverter:
        derived['${baseName}_upper_case'] = processedValue;
      case VariableProcessorType.lowerCaseConverter:
        derived['${baseName}_lower_case'] = processedValue;
      case VariableProcessorType.titleCaseConverter:
        derived['${baseName}_title_case'] = processedValue;
      case VariableProcessorType.timestampGenerator:
      case VariableProcessorType.pathConverter:
      case VariableProcessorType.custom:
        // 这些类型不生成派生变量
        break;
    }

    return derived;
  }

  /// 生成标准派生变量
  Map<String, dynamic> _generateStandardDerivedVariables(
    Map<String, dynamic> variables,
  ) {
    final derived = <String, dynamic>{};

    // 为主要的名称变量生成所有格式变体
    final nameFields = ['name', 'module_name', 'package_name', 'project_name'];

    for (final field in nameFields) {
      final value = variables[field]?.toString();
      if (value != null && value.isNotEmpty) {
        derived['${field}_snake_case'] = StringUtils.toSnakeCase(value);
        derived['${field}_pascal_case'] = StringUtils.toPascalCase(value);
        derived['${field}_camel_case'] = StringUtils.toCamelCase(value);
        derived['${field}_kebab_case'] = StringUtils.toKebabCase(value);
        derived['${field}_upper_case'] = value.toUpperCase();
        derived['${field}_lower_case'] = value.toLowerCase();
        derived['${field}_title_case'] = _toTitleCase(value);
      }
    }

    return derived;
  }

  /// 生成时间戳变量
  Map<String, dynamic> _generateTimestampVariables() {
    final now = DateTime.now();

    return {
      'generated_date': now.toIso8601String().substring(0, 10),
      'generated_time': now.toIso8601String().substring(11, 19),
      'generated_datetime': now.toIso8601String(),
      'generated_year': now.year.toString(),
      'generated_month': now.month.toString().padLeft(2, '0'),
      'generated_day': now.day.toString().padLeft(2, '0'),
      'generated_timestamp': now.millisecondsSinceEpoch.toString(),
    };
  }

  /// 变量插值处理
  String interpolateVariables(String template, Map<String, dynamic> variables) {
    var result = template;

    // 处理简单变量插值 {{variable_name}}
    final simplePattern = RegExp(r'\{\{([^}]+)\}\}');
    result = result.replaceAllMapped(simplePattern, (match) {
      final varName = match.group(1)?.trim();
      if (varName != null && variables.containsKey(varName)) {
        return variables[varName]?.toString() ?? '';
      }
      return match.group(0) ?? '';
    });

    // 处理条件插值 {{#if variable}}content{{/if}}
    final conditionalPattern = RegExp(
      r'\{\{#if\s+([^}]+)\}\}(.*?)\{\{/if\}\}',
      dotAll: true,
    );
    result = result.replaceAllMapped(conditionalPattern, (match) {
      final varName = match.group(1)?.trim();
      final content = match.group(2) ?? '';

      if (varName != null && variables.containsKey(varName)) {
        final value = variables[varName];
        // 检查条件是否为真
        if (_isTruthy(value)) {
          return interpolateVariables(content, variables);
        }
      }
      return '';
    });

    // 处理否定条件插值 {{#unless variable}}content{{/unless}}
    final unlessPattern = RegExp(
      r'\{\{#unless\s+([^}]+)\}\}(.*?)\{\{/unless\}\}',
      dotAll: true,
    );
    result = result.replaceAllMapped(unlessPattern, (match) {
      final varName = match.group(1)?.trim();
      final content = match.group(2) ?? '';

      if (varName != null) {
        final value = variables[varName];
        // 检查条件是否为假
        if (!_isTruthy(value)) {
          return interpolateVariables(content, variables);
        }
      }
      return '';
    });

    // 处理循环插值 {{#each list}}content{{/each}}
    final eachPattern = RegExp(
      r'\{\{#each\s+([^}]+)\}\}(.*?)\{\{/each\}\}',
      dotAll: true,
    );
    return result.replaceAllMapped(eachPattern, (match) {
      final varName = match.group(1)?.trim();
      final template = match.group(2) ?? '';

      if (varName != null && variables.containsKey(varName)) {
        final value = variables[varName];
        if (value is List) {
          final buffer = StringBuffer();
          for (var i = 0; i < value.length; i++) {
            final itemVariables = Map<String, dynamic>.from(variables);
            itemVariables['this'] = value[i];
            itemVariables['@index'] = i;
            itemVariables['@first'] = i == 0;
            itemVariables['@last'] = i == value.length - 1;

            buffer.write(interpolateVariables(template, itemVariables));
          }
          return buffer.toString();
        }
      }
      return '';
    });
  }

  /// 检查值是否为"真值"
  bool _isTruthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.isNotEmpty;
    if (value is num) return value != 0;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    return true;
  }

  /// 检查是否为空值
  bool _isEmptyValue(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is List) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    return false;
  }

  /// 转换为标题格式
  String _toTitleCase(String input) {
    return input
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  /// 获取处理器配置
  List<VariableProcessorConfig> get processors =>
      List.unmodifiable(_processors);

  /// 添加处理器配置
  void addProcessor(VariableProcessorConfig config) {
    _processors.add(config);
  }

  /// 移除处理器配置
  void removeProcessor(String target, VariableProcessorType type) {
    _processors.removeWhere(
      (config) => config.target == target && config.type == type,
    );
  }

  /// 清空所有处理器
  void clearProcessors() {
    _processors.clear();
  }
}
