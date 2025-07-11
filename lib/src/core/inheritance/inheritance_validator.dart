/*
---------------------------------------------------------------
File name:          inheritance_validator.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级继承验证器 (Enterprise Inheritance Validator)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.1 模板继承验证系统;
---------------------------------------------------------------
*/

import 'dart:math';

import 'package:ming_status_cli/src/core/inheritance/inheritance_engine.dart';
import 'package:ming_status_cli/src/core/template_system/advanced_template.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 验证规则类型
///
/// 定义不同类型的验证规则
enum ValidationRuleType {
  /// 继承链完整性
  chainIntegrity,

  /// 参数兼容性
  parameterCompatibility,

  /// 循环依赖检查
  circularDependency,

  /// 性能影响评估
  performanceImpact,

  /// 最佳实践检查
  bestPractices,
}

/// 验证严重性级别
///
/// 定义验证问题的严重性
enum ValidationSeverity {
  /// 信息级别
  info,

  /// 警告级别
  warning,

  /// 错误级别
  error,

  /// 致命错误级别
  fatal,
}

/// 验证问题
///
/// 表示验证过程中发现的问题
class ValidationIssue {
  /// 创建验证问题实例
  const ValidationIssue({
    required this.ruleType,
    required this.severity,
    required this.message,
    required this.templateId,
    this.suggestion,
    this.details = const {},
  });

  /// 规则类型
  final ValidationRuleType ruleType;

  /// 严重性级别
  final ValidationSeverity severity;

  /// 问题描述
  final String message;

  /// 相关模板ID
  final String templateId;

  /// 修复建议
  final String? suggestion;

  /// 详细信息
  final Map<String, dynamic> details;

  @override
  String toString() {
    return '[${severity.name.toUpperCase()}] ${ruleType.name}: $message ($templateId)';
  }
}

/// 继承验证结果
///
/// 包含继承验证的完整结果
class InheritanceValidationResult {
  /// 创建继承验证结果实例
  const InheritanceValidationResult({
    required this.isValid,
    this.issues = const [],
    this.performanceMetrics,
    this.recommendations = const [],
    this.summary = const {},
  });

  /// 是否通过验证
  final bool isValid;

  /// 验证问题列表
  final List<ValidationIssue> issues;

  /// 性能指标
  final PerformanceMetrics? performanceMetrics;

  /// 优化建议列表
  final List<String> recommendations;

  /// 验证摘要
  final Map<String, dynamic> summary;

  /// 获取错误问题
  List<ValidationIssue> get errors => issues
      .where((issue) => issue.severity == ValidationSeverity.error)
      .toList();

  /// 获取警告问题
  List<ValidationIssue> get warnings => issues
      .where((issue) => issue.severity == ValidationSeverity.warning)
      .toList();

  /// 获取信息问题
  List<ValidationIssue> get infos => issues
      .where((issue) => issue.severity == ValidationSeverity.info)
      .toList();

  /// 是否有致命错误
  bool get hasFatalErrors =>
      issues.any((issue) => issue.severity == ValidationSeverity.fatal);

  /// 是否有错误
  bool get hasErrors =>
      issues.any((issue) => issue.severity == ValidationSeverity.error);

  /// 是否有警告
  bool get hasWarnings =>
      issues.any((issue) => issue.severity == ValidationSeverity.warning);
}

/// 企业级继承验证器
///
/// 继承链完整性验证、参数兼容性检查、循环依赖预防、性能影响评估
class InheritanceValidator {
  /// 创建继承验证器实例
  InheritanceValidator({
    this.maxChainDepth = 5,
    this.enablePerformanceCheck = true,
    this.enableBestPracticesCheck = true,
    this.strictMode = false,
  });

  /// 最大继承链深度
  final int maxChainDepth;

  /// 是否启用性能检查
  final bool enablePerformanceCheck;

  /// 是否启用最佳实践检查
  final bool enableBestPracticesCheck;

  /// 是否启用严格模式
  final bool strictMode;

  /// 验证继承链
  ///
  /// 对继承链进行全面验证
  Future<InheritanceValidationResult> validateInheritance(
    List<InheritanceNode> inheritanceChain,
    InheritanceContext context,
  ) async {
    final startTime = DateTime.now();
    final issues = <ValidationIssue>[];
    final recommendations = <String>[];

    try {
      cli_logger.Logger.info(
        '开始验证继承链 (${inheritanceChain.length}个模板)',
      );

      // 1. 继承链完整性验证
      issues.addAll(await _validateChainIntegrity(inheritanceChain));

      // 2. 参数兼容性检查
      issues.addAll(await _validateParameterCompatibility(inheritanceChain));

      // 3. 循环依赖检查
      issues.addAll(await _validateCircularDependency(inheritanceChain));

      // 4. 性能影响评估
      if (enablePerformanceCheck) {
        final performanceIssues =
            await _validatePerformanceImpact(inheritanceChain);
        issues.addAll(performanceIssues.issues);
        recommendations.addAll(performanceIssues.recommendations);
      }

      // 5. 最佳实践检查
      if (enableBestPracticesCheck) {
        final practiceIssues = await _validateBestPractices(inheritanceChain);
        issues.addAll(practiceIssues.issues);
        recommendations.addAll(practiceIssues.recommendations);
      }

      // 6. 生成验证摘要
      final summary = _generateValidationSummary(issues, inheritanceChain);

      final endTime = DateTime.now();
      final performanceMetrics = PerformanceMetrics(
        startTime: startTime,
        endTime: endTime,
        memoryUsage: _estimateValidationMemoryUsage(inheritanceChain),
      );

      final isValid = _determineValidationResult(issues);

      cli_logger.Logger.info(
        '继承验证完成: ${isValid ? '通过' : '失败'} '
        '(${issues.length}个问题, ${performanceMetrics.executionTimeMs}ms)',
      );

      return InheritanceValidationResult(
        isValid: isValid,
        issues: issues,
        performanceMetrics: performanceMetrics,
        recommendations: recommendations,
        summary: summary,
      );
    } catch (e) {
      cli_logger.Logger.error('继承验证失败', error: e);
      return InheritanceValidationResult(
        isValid: false,
        issues: [
          ValidationIssue(
            ruleType: ValidationRuleType.chainIntegrity,
            severity: ValidationSeverity.fatal,
            message: '验证过程异常: $e',
            templateId: 'unknown',
          ),
        ],
      );
    }
  }

  /// 验证继承链完整性
  Future<List<ValidationIssue>> _validateChainIntegrity(
    List<InheritanceNode> inheritanceChain,
  ) async {
    final issues = <ValidationIssue>[];

    // 检查链长度
    if (inheritanceChain.length > maxChainDepth) {
      issues.add(
        ValidationIssue(
          ruleType: ValidationRuleType.chainIntegrity,
          severity: ValidationSeverity.warning,
          message: '继承链深度超过推荐值 ($maxChainDepth)',
          templateId: inheritanceChain.last.templateId,
          suggestion: '考虑重构继承关系以减少深度',
          details: {
            'actualDepth': inheritanceChain.length,
            'maxDepth': maxChainDepth
          },
        ),
      );
    }

    // 检查链连续性
    for (var i = 1; i < inheritanceChain.length; i++) {
      final current = inheritanceChain[i];
      final previous = inheritanceChain[i - 1];

      if (current.depth != previous.depth + 1) {
        issues.add(
          ValidationIssue(
            ruleType: ValidationRuleType.chainIntegrity,
            severity: ValidationSeverity.error,
            message: '继承链深度不连续',
            templateId: current.templateId,
            suggestion: '检查继承关系定义',
            details: {
              'currentDepth': current.depth,
              'expectedDepth': previous.depth + 1,
            },
          ),
        );
      }
    }

    return issues;
  }

  /// 验证参数兼容性
  Future<List<ValidationIssue>> _validateParameterCompatibility(
    List<InheritanceNode> inheritanceChain,
  ) async {
    final issues = <ValidationIssue>[];

    for (var i = 1; i < inheritanceChain.length; i++) {
      final child = inheritanceChain[i];
      final parent = inheritanceChain[i - 1];

      // 检查必需参数
      final parentRequired = parent.template.requiredParameters.toSet();
      final childRequired = child.template.requiredParameters.toSet();

      final missingRequired = parentRequired.difference(childRequired);
      if (missingRequired.isNotEmpty) {
        issues.add(
          ValidationIssue(
            ruleType: ValidationRuleType.parameterCompatibility,
            severity: ValidationSeverity.error,
            message: '子模板缺少父模板的必需参数: ${missingRequired.join(', ')}',
            templateId: child.templateId,
            suggestion: '在子模板中添加缺少的必需参数',
            details: {'missingParameters': missingRequired.toList()},
          ),
        );
      }

      // 检查参数类型兼容性
      for (final paramName in parentRequired.intersection(childRequired)) {
        final parentParam = parent.template.parameters[paramName];
        final childParam = child.template.parameters[paramName];

        if (parentParam != null && childParam != null) {
          if (parentParam.type != childParam.type) {
            issues.add(
              ValidationIssue(
                ruleType: ValidationRuleType.parameterCompatibility,
                severity: ValidationSeverity.warning,
                message: '参数类型不匹配: $paramName',
                templateId: child.templateId,
                suggestion: '确保子模板参数类型与父模板兼容',
                details: {
                  'parameterName': paramName,
                  'parentType': parentParam.type.name,
                  'childType': childParam.type.name,
                },
              ),
            );
          }
        }
      }
    }

    return issues;
  }

  /// 验证循环依赖
  Future<List<ValidationIssue>> _validateCircularDependency(
    List<InheritanceNode> inheritanceChain,
  ) async {
    final issues = <ValidationIssue>[];
    final visited = <String>{};

    for (final node in inheritanceChain) {
      if (visited.contains(node.templateId)) {
        issues.add(
          ValidationIssue(
            ruleType: ValidationRuleType.circularDependency,
            severity: ValidationSeverity.fatal,
            message: '检测到循环继承: ${node.templateId}',
            templateId: node.templateId,
            suggestion: '重构继承关系以消除循环',
            details: {'visitedTemplates': visited.toList()},
          ),
        );
        break;
      }
      visited.add(node.templateId);
    }

    return issues;
  }

  /// 验证性能影响
  Future<({List<ValidationIssue> issues, List<String> recommendations})>
      _validatePerformanceImpact(
    List<InheritanceNode> inheritanceChain,
  ) async {
    final issues = <ValidationIssue>[];
    final recommendations = <String>[];

    // 估算性能影响
    final estimatedComplexity = _calculateComplexity(inheritanceChain);

    if (estimatedComplexity > 100) {
      issues.add(
        ValidationIssue(
          ruleType: ValidationRuleType.performanceImpact,
          severity: ValidationSeverity.warning,
          message: '继承链复杂度较高，可能影响性能',
          templateId: inheritanceChain.last.templateId,
          suggestion: '考虑优化继承结构或启用缓存',
          details: {'complexity': estimatedComplexity},
        ),
      );

      recommendations.add('启用继承结果缓存以提升性能');
      recommendations.add('考虑将复杂继承拆分为多个简单继承');
    }

    return (issues: issues, recommendations: recommendations);
  }

  /// 验证最佳实践
  Future<({List<ValidationIssue> issues, List<String> recommendations})>
      _validateBestPractices(
    List<InheritanceNode> inheritanceChain,
  ) async {
    final issues = <ValidationIssue>[];
    final recommendations = <String>[];

    // 检查命名规范
    for (final node in inheritanceChain) {
      final templateName = node.template.metadata.name;
      if (!_isValidTemplateName(templateName)) {
        issues.add(
          ValidationIssue(
            ruleType: ValidationRuleType.bestPractices,
            severity: ValidationSeverity.info,
            message: '模板命名不符合最佳实践: $templateName',
            templateId: node.templateId,
            suggestion: '使用清晰、描述性的模板名称',
          ),
        );
      }
    }

    // 检查文档完整性
    for (final node in inheritanceChain) {
      if (node.template.metadata.description.isEmpty) {
        issues.add(
          ValidationIssue(
            ruleType: ValidationRuleType.bestPractices,
            severity: ValidationSeverity.info,
            message: '模板缺少描述信息',
            templateId: node.templateId,
            suggestion: '为模板添加清晰的描述信息',
          ),
        );
      }
    }

    recommendations.add('为所有模板提供完整的文档');
    recommendations.add('遵循一致的命名规范');

    return (issues: issues, recommendations: recommendations);
  }

  /// 计算继承复杂度
  int _calculateComplexity(List<InheritanceNode> inheritanceChain) {
    var complexity = 0;

    for (final node in inheritanceChain) {
      // 基础复杂度
      complexity += 10;

      // 参数数量影响
      complexity += node.template.parameters.length * 2;

      // 依赖数量影响
      complexity += node.template.dependencies.length * 5;

      // 深度影响
      complexity += node.depth * 3;
    }

    return complexity;
  }

  /// 验证模板名称
  bool _isValidTemplateName(String name) {
    // 简化的命名验证
    return name.isNotEmpty &&
        name.length >= 3 &&
        !name.contains(' ') &&
        RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$').hasMatch(name);
  }

  /// 确定验证结果
  bool _determineValidationResult(List<ValidationIssue> issues) {
    if (strictMode) {
      return !issues.any(
        (issue) =>
            issue.severity == ValidationSeverity.error ||
            issue.severity == ValidationSeverity.fatal,
      );
    } else {
      return !issues.any((issue) => issue.severity == ValidationSeverity.fatal);
    }
  }

  /// 生成验证摘要
  Map<String, dynamic> _generateValidationSummary(
    List<ValidationIssue> issues,
    List<InheritanceNode> inheritanceChain,
  ) {
    final summary = <String, dynamic>{};

    summary['totalTemplates'] = inheritanceChain.length;
    summary['totalIssues'] = issues.length;
    summary['fatalErrors'] =
        issues.where((i) => i.severity == ValidationSeverity.fatal).length;
    summary['errors'] =
        issues.where((i) => i.severity == ValidationSeverity.error).length;
    summary['warnings'] =
        issues.where((i) => i.severity == ValidationSeverity.warning).length;
    summary['infos'] =
        issues.where((i) => i.severity == ValidationSeverity.info).length;
    summary['maxDepth'] = inheritanceChain.isNotEmpty
        ? inheritanceChain.map((n) => n.depth).reduce(max)
        : 0;
    summary['complexity'] = _calculateComplexity(inheritanceChain);

    return summary;
  }

  /// 估算验证内存使用量
  int _estimateValidationMemoryUsage(List<InheritanceNode> inheritanceChain) {
    return inheritanceChain.length * 512; // 每个节点约512字节
  }
}
