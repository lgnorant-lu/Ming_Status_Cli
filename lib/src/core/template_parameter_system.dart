/*
---------------------------------------------------------------
File name:          template_parameter_system.dart
Author:             lgnorant-lu
Date created:       2025/06/30
Last modified:      2025/06/30
Dart Version:       3.2+
Description:        模板参数系统 (Template parameter system)
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_variable_processor.dart';
import 'package:ming_status_cli/src/models/template_variable.dart';

/// 模板参数系统
class TemplateParameterSystem {
  /// 创建模板参数系统实例
  /// 
  /// [variables] 可选的初始变量定义映射
  /// [processor] 可选的变量处理器实例
  TemplateParameterSystem({
    Map<String, TemplateVariable>? variables,
    TemplateVariableProcessor? processor,
  }) : _variables = variables ?? {},
       _processor = processor ?? TemplateVariableProcessor();

  /// 变量定义映射
  final Map<String, TemplateVariable> _variables;
  
  /// 变量处理器
  final TemplateVariableProcessor _processor;

  /// 从brick.yaml数据加载参数定义
  void loadFromBrickYaml(Map<String, dynamic> brickData) {
    _variables.clear();

    // 解析vars部分
    if (brickData.containsKey('vars') && brickData['vars'] is Map) {
      final varsData = Map<String, dynamic>.from(brickData['vars'] as Map);
      
      for (final entry in varsData.entries) {
        final varName = entry.key;
        final varData = entry.value;
        
        if (varData is Map) {
          try {
            final variable = TemplateVariable.fromMap(
              varName,
              Map<String, dynamic>.from(varData),
            );
            _variables[varName] = variable;
          } catch (e) {
            throw TemplateParameterException(
              'Failed to parse variable "$varName": $e',
            );
          }
        }
      }
    }

    // 加载自定义处理器配置
    if (brickData.containsKey('ming_config') && 
        brickData['ming_config'] is Map) {
      final mingConfig = Map<String, dynamic>.from(
        brickData['ming_config'] as Map,
      );
      _loadProcessorConfig(mingConfig);
    }
  }

  /// 加载处理器配置
  void _loadProcessorConfig(Map<String, dynamic> mingConfig) {
    if (mingConfig.containsKey('custom_processors') &&
        mingConfig['custom_processors'] is List) {
      final processors = mingConfig['custom_processors'] as List;
      
      _processor.clearProcessors();
      
      for (final processorData in processors) {
        if (processorData is Map) {
          try {
            final config = VariableProcessorConfig.fromMap(
              Map<String, dynamic>.from(processorData),
            );
            _processor.addProcessor(config);
          } catch (e) {
            // 忽略无效的处理器配置，但记录警告
            continue;
          }
        }
      }
    }
  }

  /// 验证变量值集合
  TemplateParameterValidationResult validateVariables(
    Map<String, dynamic> values,
  ) {
    final errors = <String>[];
    final warnings = <String>[];
    final validatedVars = <String, dynamic>{};

    // 验证每个定义的变量
    for (final variable in _variables.values) {
      final value = values[variable.name];
      final result = variable.validateValue(value);

      if (!result.isValid) {
        errors.addAll(result.errors);
      }
      
      if (result.hasWarnings) {
        warnings.addAll(result.warnings);
      }

      // 使用有效值或默认值
      if (result.isValid || variable.optional) {
        final effectiveValue = value ?? variable.getEffectiveDefaultValue();
        validatedVars[variable.name] = effectiveValue;
      }
    }

    // 检查是否有未定义的变量
    for (final key in values.keys) {
      if (!_variables.containsKey(key)) {
        warnings.add('变量 "$key" 未在模板中定义');
      }
    }

    return TemplateParameterValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      validatedVariables: validatedVars,
    );
  }

  /// 处理变量（验证 + 转换 + 生成派生变量）
  TemplateParameterProcessingResult processVariables(
    Map<String, dynamic> inputVariables,
  ) {
    try {
      // 首先验证变量
      final validationResult = validateVariables(inputVariables);
      
      if (!validationResult.isValid) {
        return TemplateParameterProcessingResult.failure(
          validationResult.errors,
          warnings: validationResult.warnings,
        );
      }

      // 使用变量处理器处理变量
      final processingResult = _processor.processVariables(
        variables: validationResult.validatedVariables,
        variableDefinitions: _variables.values.toList(),
      );

      if (!processingResult.success) {
        return TemplateParameterProcessingResult.failure(
          processingResult.errors,
          warnings: [
            ...validationResult.warnings,
            ...processingResult.warnings,
          ],
        );
      }

      return TemplateParameterProcessingResult.success(
        processingResult.variables,
        warnings: [
          ...validationResult.warnings,
          ...processingResult.warnings,
        ],
        generatedVariables: processingResult.generatedVariables,
        originalVariables: inputVariables,
      );

    } catch (e) {
      return TemplateParameterProcessingResult.failure(
        ['变量处理过程中发生异常: $e'],
      );
    }
  }

  /// 插值变量到模板字符串
  String interpolateTemplate(String template, Map<String, dynamic> variables) {
    return _processor.interpolateVariables(template, variables);
  }

  /// 获取变量定义
  TemplateVariable? getVariableDefinition(String name) {
    return _variables[name];
  }

  /// 获取所有变量定义
  List<TemplateVariable> getAllVariableDefinitions() {
    return _variables.values.toList();
  }

  /// 获取必需变量列表
  List<TemplateVariable> getRequiredVariables() {
    return _variables.values.where((v) => !v.optional).toList();
  }

  /// 获取可选变量列表
  List<TemplateVariable> getOptionalVariables() {
    return _variables.values.where((v) => v.optional).toList();
  }

  /// 获取变量的默认值映射
  Map<String, dynamic> getDefaultValues() {
    final defaults = <String, dynamic>{};
    
    for (final variable in _variables.values) {
      // 只包含真正设置了默认值的变量
      if (variable.defaultValue != null) {
        defaults[variable.name] = variable.defaultValue;
      }
    }
    
    return defaults;
  }

  /// 获取用户提示信息
  Map<String, String> getPrompts() {
    final prompts = <String, String>{};
    
    for (final variable in _variables.values) {
      if (variable.prompt != null) {
        prompts[variable.name] = variable.prompt!;
      }
    }
    
    return prompts;
  }

  /// 生成变量摘要信息
  Map<String, dynamic> generateVariableSummary() {
    final summary = <String, dynamic>{
      'total_variables': _variables.length,
      'required_variables': getRequiredVariables().length,
      'optional_variables': getOptionalVariables().length,
      'type_distribution': <String, int>{},
      'variables_with_validation': 0,
      'variables_with_defaults': 0,
    };

    final typeDistribution = <String, int>{};
    var withValidation = 0;
    var withDefaults = 0;

    for (final variable in _variables.values) {
      // 统计类型分布
      final typeName = variable.type.name;
      typeDistribution[typeName] = (typeDistribution[typeName] ?? 0) + 1;

      // 统计验证规则
      if (variable.validation != null) {
        withValidation++;
      }

      // 统计默认值
      if (variable.defaultValue != null) {
        withDefaults++;
      }
    }

    summary['type_distribution'] = typeDistribution;
    summary['variables_with_validation'] = withValidation;
    summary['variables_with_defaults'] = withDefaults;

    return summary;
  }

  /// 添加变量定义
  void addVariable(TemplateVariable variable) {
    _variables[variable.name] = variable;
  }

  /// 移除变量定义
  void removeVariable(String name) {
    _variables.remove(name);
  }

  /// 清空所有变量定义
  void clearVariables() {
    _variables.clear();
  }

  /// 获取变量处理器
  TemplateVariableProcessor get processor => _processor;

  /// 是否有变量定义
  bool get hasVariables => _variables.isNotEmpty;

  /// 变量数量
  int get variableCount => _variables.length;
}

/// 参数验证结果
class TemplateParameterValidationResult {
  /// 创建参数验证结果实例
  /// 
  /// [isValid] 验证是否通过
  /// [errors] 错误信息列表
  /// [warnings] 警告信息列表
  /// [validatedVariables] 验证后的变量值映射
  const TemplateParameterValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.validatedVariables,
  });

  /// 是否有效
  final bool isValid;
  
  /// 错误信息
  final List<String> errors;
  
  /// 警告信息
  final List<String> warnings;
  
  /// 验证后的变量值
  final Map<String, dynamic> validatedVariables;

  /// 是否有警告
  bool get hasWarnings => warnings.isNotEmpty;

  /// 是否有错误
  bool get hasErrors => errors.isNotEmpty;
}

/// 参数处理结果
class TemplateParameterProcessingResult {
  /// 创建参数处理结果实例
  /// 
  /// [success] 处理是否成功
  /// [processedVariables] 处理后的变量映射
  /// [errors] 错误信息列表
  /// [warnings] 警告信息列表
  /// [generatedVariables] 生成的派生变量
  /// [originalVariables] 原始输入变量
  const TemplateParameterProcessingResult({
    required this.success,
    required this.processedVariables,
    this.errors = const [],
    this.warnings = const [],
    this.generatedVariables = const {},
    this.originalVariables = const {},
  });

  /// 创建成功结果
  factory TemplateParameterProcessingResult.success(
    Map<String, dynamic> processedVariables, {
    List<String> warnings = const [],
    Map<String, dynamic> generatedVariables = const {},
    Map<String, dynamic> originalVariables = const {},
  }) {
    return TemplateParameterProcessingResult(
      success: true,
      processedVariables: processedVariables,
      warnings: warnings,
      generatedVariables: generatedVariables,
      originalVariables: originalVariables,
    );
  }

  /// 创建失败结果
  factory TemplateParameterProcessingResult.failure(
    List<String> errors, {
    List<String> warnings = const [],
    Map<String, dynamic> processedVariables = const {},
  }) {
    return TemplateParameterProcessingResult(
      success: false,
      processedVariables: processedVariables,
      errors: errors,
      warnings: warnings,
    );
  }

  /// 处理是否成功
  final bool success;
  
  /// 处理后的变量
  final Map<String, dynamic> processedVariables;
  
  /// 错误信息
  final List<String> errors;
  
  /// 警告信息
  final List<String> warnings;
  
  /// 生成的派生变量
  final Map<String, dynamic> generatedVariables;
  
  /// 原始输入变量
  final Map<String, dynamic> originalVariables;

  /// 是否有警告
  bool get hasWarnings => warnings.isNotEmpty;

  /// 是否有错误
  bool get hasErrors => errors.isNotEmpty;

  /// 获取所有变量（原始 + 处理后 + 生成的）
  Map<String, dynamic> getAllVariables() {
    return <String, dynamic>{}
      ..addAll(originalVariables)
      ..addAll(processedVariables)
      ..addAll(generatedVariables);
  }
}

/// 模板参数异常
class TemplateParameterException implements Exception {
  /// 创建模板参数异常实例
  /// 
  /// [message] 错误消息
  /// [details] 可选的详细信息映射
  const TemplateParameterException(this.message, [this.details]);

  /// 错误消息
  final String message;
  
  /// 详细信息
  final Map<String, dynamic>? details;

  @override
  String toString() {
    if (details != null) {
      return 'TemplateParameterException: $message\nDetails: $details';
    }
    return 'TemplateParameterException: $message';
  }
}
