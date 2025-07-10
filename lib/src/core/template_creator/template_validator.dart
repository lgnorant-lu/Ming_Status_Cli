/*
---------------------------------------------------------------
File name:          template_validator.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级模板验证工具 (Enterprise Template Validator)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.1 模板验证和质量检查;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;
import 'package:path/path.dart' as path;

/// 验证规则类型
///
/// 定义不同类型的验证规则
enum ValidationRuleType {
  /// 结构验证
  structure,

  /// 元数据验证
  metadata,

  /// 语法验证
  syntax,

  /// 依赖验证
  dependency,

  /// 安全验证
  security,

  /// 性能验证
  performance,

  /// 最佳实践验证
  bestPractice,
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
    required this.filePath,
    this.lineNumber,
    this.suggestion,
    this.details = const {},
  });

  /// 规则类型
  final ValidationRuleType ruleType;

  /// 严重性级别
  final ValidationSeverity severity;

  /// 问题描述
  final String message;

  /// 文件路径
  final String filePath;

  /// 行号
  final int? lineNumber;

  /// 修复建议
  final String? suggestion;

  /// 详细信息
  final Map<String, dynamic> details;

  @override
  String toString() {
    final location = lineNumber != null ? '$filePath:$lineNumber' : filePath;
    return '[${severity.name.toUpperCase()}] ${ruleType.name}: $message ($location)';
  }
}

/// 模板验证结果
///
/// 包含模板验证的完整结果
class TemplateValidationResult {
  /// 创建模板验证结果实例
  const TemplateValidationResult({
    required this.isValid,
    required this.templatePath,
    this.issues = const [],
    this.recommendations = const [],
    this.summary = const {},
  });

  /// 是否通过验证
  final bool isValid;

  /// 模板路径
  final String templatePath;

  /// 验证问题列表
  final List<ValidationIssue> issues;

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

/// 验证配置
///
/// 定义验证器的配置参数
class ValidationConfig {
  /// 创建验证配置实例
  const ValidationConfig({
    this.enableStructureValidation = true,
    this.enableMetadataValidation = true,
    this.enableSyntaxValidation = true,
    this.enableDependencyValidation = true,
    this.enableSecurityValidation = true,
    this.enablePerformanceValidation = false,
    this.enableBestPracticeValidation = true,
    this.strictMode = false,
    this.maxFileSize = 1024 * 1024, // 1MB
    this.maxTemplateFiles = 100,
  });

  /// 是否启用结构验证
  final bool enableStructureValidation;

  /// 是否启用元数据验证
  final bool enableMetadataValidation;

  /// 是否启用语法验证
  final bool enableSyntaxValidation;

  /// 是否启用依赖验证
  final bool enableDependencyValidation;

  /// 是否启用安全验证
  final bool enableSecurityValidation;

  /// 是否启用性能验证
  final bool enablePerformanceValidation;

  /// 是否启用最佳实践验证
  final bool enableBestPracticeValidation;

  /// 是否启用严格模式
  final bool strictMode;

  /// 最大文件大小 (字节)
  final int maxFileSize;

  /// 最大模板文件数量
  final int maxTemplateFiles;
}

/// 企业级模板验证工具
///
/// 全面的模板质量检查、安全验证、性能分析
class TemplateValidator {
  /// 创建模板验证工具实例
  TemplateValidator({
    this.config = const ValidationConfig(),
  });

  /// 验证配置
  final ValidationConfig config;

  /// 验证模板
  ///
  /// 对模板进行全面验证
  Future<TemplateValidationResult> validateTemplate(String templatePath) async {
    try {
      cli_logger.Logger.info('开始验证模板: $templatePath');

      final issues = <ValidationIssue>[];
      final recommendations = <String>[];

      // 1. 结构验证
      if (config.enableStructureValidation) {
        issues.addAll(await _validateStructure(templatePath));
      }

      // 2. 元数据验证
      if (config.enableMetadataValidation) {
        issues.addAll(await _validateMetadata(templatePath));
      }

      // 3. 语法验证
      if (config.enableSyntaxValidation) {
        issues.addAll(await _validateSyntax(templatePath));
      }

      // 4. 依赖验证
      if (config.enableDependencyValidation) {
        issues.addAll(await _validateDependencies(templatePath));
      }

      // 5. 安全验证
      if (config.enableSecurityValidation) {
        issues.addAll(await _validateSecurity(templatePath));
      }

      // 6. 性能验证
      if (config.enablePerformanceValidation) {
        final performanceResult = await _validatePerformance(templatePath);
        issues.addAll(performanceResult.issues);
        recommendations.addAll(performanceResult.recommendations);
      }

      // 7. 最佳实践验证
      if (config.enableBestPracticeValidation) {
        final practiceResult = await _validateBestPractices(templatePath);
        issues.addAll(practiceResult.issues);
        recommendations.addAll(practiceResult.recommendations);
      }

      // 8. 生成验证摘要
      final summary = _generateValidationSummary(issues, templatePath);

      final isValid = _determineValidationResult(issues);

      cli_logger.Logger.info(
        '模板验证完成: ${isValid ? '通过' : '失败'} '
        '(${issues.length}个问题)',
      );

      return TemplateValidationResult(
        isValid: isValid,
        templatePath: templatePath,
        issues: issues,
        recommendations: recommendations,
        summary: summary,
      );
    } catch (e) {
      cli_logger.Logger.error('模板验证失败', error: e);
      return TemplateValidationResult(
        isValid: false,
        templatePath: templatePath,
        issues: [
          ValidationIssue(
            ruleType: ValidationRuleType.structure,
            severity: ValidationSeverity.fatal,
            message: '验证过程异常: $e',
            filePath: templatePath,
          ),
        ],
      );
    }
  }

  /// 验证模板结构
  Future<List<ValidationIssue>> _validateStructure(String templatePath) async {
    final issues = <ValidationIssue>[];

    // 检查模板目录是否存在
    final templateDir = Directory(templatePath);
    if (!await templateDir.exists()) {
      issues.add(ValidationIssue(
        ruleType: ValidationRuleType.structure,
        severity: ValidationSeverity.fatal,
        message: '模板目录不存在',
        filePath: templatePath,
        suggestion: '确保模板目录路径正确',
      ),);
      return issues;
    }

    // 检查必需文件
    final requiredFiles = ['template.yaml'];
    for (final fileName in requiredFiles) {
      final file = File(path.join(templatePath, fileName));
      if (!await file.exists()) {
        issues.add(ValidationIssue(
          ruleType: ValidationRuleType.structure,
          severity: ValidationSeverity.error,
          message: '缺少必需文件: $fileName',
          filePath: path.join(templatePath, fileName),
          suggestion: '创建缺少的必需文件',
        ),);
      }
    }

    // 检查推荐目录
    final recommendedDirs = ['templates', 'config'];
    for (final dirName in recommendedDirs) {
      final dir = Directory(path.join(templatePath, dirName));
      if (!await dir.exists()) {
        issues.add(ValidationIssue(
          ruleType: ValidationRuleType.structure,
          severity: ValidationSeverity.warning,
          message: '缺少推荐目录: $dirName',
          filePath: path.join(templatePath, dirName),
          suggestion: '创建推荐的目录结构',
        ),);
      }
    }

    // 检查模板文件数量
    final templateFiles = await _getTemplateFiles(templatePath);
    if (templateFiles.length > config.maxTemplateFiles) {
      issues.add(ValidationIssue(
        ruleType: ValidationRuleType.structure,
        severity: ValidationSeverity.warning,
        message: '模板文件数量过多: ${templateFiles.length}',
        filePath: templatePath,
        suggestion: '考虑拆分为多个模板或优化文件结构',
        details: {
          'fileCount': templateFiles.length,
          'maxFiles': config.maxTemplateFiles,
        },
      ),);
    }

    return issues;
  }

  /// 验证元数据
  Future<List<ValidationIssue>> _validateMetadata(String templatePath) async {
    final issues = <ValidationIssue>[];

    final metadataFile = File(path.join(templatePath, 'template.yaml'));
    if (!await metadataFile.exists()) {
      return issues; // 结构验证已经处理了这个问题
    }

    try {
      final content = await metadataFile.readAsString();

      // 检查必需字段
      final requiredFields = [
        'name',
        'version',
        'author',
        'description',
        'type',
      ];
      for (final field in requiredFields) {
        if (!content.contains('$field:')) {
          issues.add(ValidationIssue(
            ruleType: ValidationRuleType.metadata,
            severity: ValidationSeverity.error,
            message: '元数据缺少必需字段: $field',
            filePath: metadataFile.path,
            suggestion: '在template.yaml中添加缺少的字段',
          ),);
        }
      }

      // 检查版本格式
      final versionMatch = RegExp(r'version:\s*([^\n]+)').firstMatch(content);
      if (versionMatch != null) {
        final version = versionMatch.group(1)?.trim();
        if (version != null && !RegExp(r'^\d+\.\d+\.\d+').hasMatch(version)) {
          issues.add(ValidationIssue(
            ruleType: ValidationRuleType.metadata,
            severity: ValidationSeverity.warning,
            message: '版本号格式不规范: $version',
            filePath: metadataFile.path,
            suggestion: '使用SemVer格式 (x.y.z)',
          ),);
        }
      }
    } catch (e) {
      issues.add(ValidationIssue(
        ruleType: ValidationRuleType.metadata,
        severity: ValidationSeverity.error,
        message: '元数据文件解析失败: $e',
        filePath: metadataFile.path,
        suggestion: '检查YAML语法是否正确',
      ),);
    }

    return issues;
  }

  /// 验证语法
  Future<List<ValidationIssue>> _validateSyntax(String templatePath) async {
    final issues = <ValidationIssue>[];

    final templateFiles = await _getTemplateFiles(templatePath);

    for (final file in templateFiles) {
      try {
        final content = await file.readAsString();

        // 检查模板语法
        issues.addAll(await _validateTemplateSyntax(file.path, content));

        // 检查文件大小
        if (content.length > config.maxFileSize) {
          issues.add(ValidationIssue(
            ruleType: ValidationRuleType.syntax,
            severity: ValidationSeverity.warning,
            message: '文件过大: ${content.length} 字节',
            filePath: file.path,
            suggestion: '考虑拆分大文件或优化内容',
            details: {
              'fileSize': content.length,
              'maxSize': config.maxFileSize,
            },
          ),);
        }
      } catch (e) {
        issues.add(ValidationIssue(
          ruleType: ValidationRuleType.syntax,
          severity: ValidationSeverity.error,
          message: '文件读取失败: $e',
          filePath: file.path,
          suggestion: '检查文件权限和编码',
        ),);
      }
    }

    return issues;
  }

  /// 验证模板语法
  Future<List<ValidationIssue>> _validateTemplateSyntax(
    String filePath,
    String content,
  ) async {
    final issues = <ValidationIssue>[];

    // 检查未闭合的模板标签
    final openTags = RegExp(r'\{\{#(\w+)').allMatches(content);
    final closeTags = RegExp(r'\{\{/(\w+)\}\}').allMatches(content);

    final openTagNames = openTags.map((m) => m.group(1)).toSet();
    final closeTagNames = closeTags.map((m) => m.group(1)).toSet();

    final unclosedTags = openTagNames.difference(closeTagNames);
    for (final tag in unclosedTags) {
      issues.add(ValidationIssue(
        ruleType: ValidationRuleType.syntax,
        severity: ValidationSeverity.error,
        message: '未闭合的模板标签: $tag',
        filePath: filePath,
        suggestion: '添加对应的闭合标签 {{/$tag}}',
      ),);
    }

    // 检查无效的变量引用
    final variables = RegExp(r'\{\{([^#/][^}]*)\}\}').allMatches(content);
    for (final variable in variables) {
      final varName = variable.group(1)?.trim();
      if (varName != null && varName.isEmpty) {
        issues.add(ValidationIssue(
          ruleType: ValidationRuleType.syntax,
          severity: ValidationSeverity.warning,
          message: '空的变量引用',
          filePath: filePath,
          suggestion: '移除空的变量引用或添加变量名',
        ),);
      }
    }

    return issues;
  }

  /// 验证依赖
  Future<List<ValidationIssue>> _validateDependencies(
      String templatePath,) async {
    final issues = <ValidationIssue>[];

    // 检查pubspec.yaml
    final pubspecFile = File(path.join(templatePath, 'pubspec.yaml'));
    if (await pubspecFile.exists()) {
      try {
        final content = await pubspecFile.readAsString();

        // 检查依赖版本约束
        final dependencies = RegExp(r'(\w+):\s*([^\n]+)').allMatches(content);
        for (final dep in dependencies) {
          final name = dep.group(1);
          final version = dep.group(2)?.trim();

          if (version != null &&
              !version.startsWith('^') &&
              !version.startsWith('>=')) {
            issues.add(ValidationIssue(
              ruleType: ValidationRuleType.dependency,
              severity: ValidationSeverity.info,
              message: '依赖版本约束建议使用范围: $name: $version',
              filePath: pubspecFile.path,
              suggestion:
                  '使用 ^$version 或 >=$version <${_getNextMajorVersion(version)}',
            ),);
          }
        }
      } catch (e) {
        issues.add(ValidationIssue(
          ruleType: ValidationRuleType.dependency,
          severity: ValidationSeverity.warning,
          message: 'pubspec.yaml解析失败: $e',
          filePath: pubspecFile.path,
          suggestion: '检查YAML语法',
        ),);
      }
    }

    return issues;
  }

  /// 验证安全性
  Future<List<ValidationIssue>> _validateSecurity(String templatePath) async {
    final issues = <ValidationIssue>[];

    final allFiles = await _getAllFiles(templatePath);

    for (final file in allFiles) {
      try {
        final content = await file.readAsString();

        // 检查敏感信息
        final sensitivePatterns = <String, String>{
          r'password\s*[:=]\s*["\x27]?[^"\x27\s]+': '可能包含密码',
          r'api[_-]?key\s*[:=]\s*["\x27]?[^"\x27\s]+': '可能包含API密钥',
          r'secret\s*[:=]\s*["\x27]?[^"\x27\s]+': '可能包含密钥',
          r'token\s*[:=]\s*["\x27]?[^"\x27\s]+': '可能包含令牌',
        };

        for (final entry in sensitivePatterns.entries) {
          final pattern = RegExp(entry.key, caseSensitive: false);
          if (pattern.hasMatch(content)) {
            issues.add(ValidationIssue(
              ruleType: ValidationRuleType.security,
              severity: ValidationSeverity.warning,
              message: '${entry.value}，请确保不包含真实凭据',
              filePath: file.path,
              suggestion: '使用占位符或环境变量替换敏感信息',
            ),);
          }
        }
      } catch (e) {
        // 忽略二进制文件等无法读取的文件
      }
    }

    return issues;
  }

  /// 验证性能
  Future<({List<ValidationIssue> issues, List<String> recommendations})>
      _validatePerformance(
    String templatePath,
  ) async {
    final issues = <ValidationIssue>[];
    final recommendations = <String>[];

    // 检查模板文件大小分布
    final templateFiles = await _getTemplateFiles(templatePath);
    final totalSize = templateFiles.fold<int>(
      0,
      (sum, file) => sum + file.lengthSync(),
    );

    if (totalSize > 10 * 1024 * 1024) {
      // 10MB
      issues.add(ValidationIssue(
        ruleType: ValidationRuleType.performance,
        severity: ValidationSeverity.warning,
        message: '模板总大小过大: ${(totalSize / 1024 / 1024).toStringAsFixed(1)}MB',
        filePath: templatePath,
        suggestion: '考虑优化模板内容或拆分模板',
      ),);

      recommendations.add('使用模板继承减少重复内容');
      recommendations.add('移除不必要的示例文件');
    }

    return (issues: issues, recommendations: recommendations);
  }

  /// 验证最佳实践
  Future<({List<ValidationIssue> issues, List<String> recommendations})>
      _validateBestPractices(
    String templatePath,
  ) async {
    final issues = <ValidationIssue>[];
    final recommendations = <String>[];

    // 检查文档完整性
    final readmeFile = File(path.join(templatePath, 'README.md'));
    if (!await readmeFile.exists()) {
      issues.add(ValidationIssue(
        ruleType: ValidationRuleType.bestPractice,
        severity: ValidationSeverity.info,
        message: '缺少README.md文档',
        filePath: path.join(templatePath, 'README.md'),
        suggestion: '添加模板使用说明文档',
      ),);
    }

    // 检查测试文件
    final testDir = Directory(path.join(templatePath, 'test'));
    if (!await testDir.exists()) {
      issues.add(ValidationIssue(
        ruleType: ValidationRuleType.bestPractice,
        severity: ValidationSeverity.info,
        message: '缺少测试目录',
        filePath: path.join(templatePath, 'test'),
        suggestion: '添加模板测试以确保质量',
      ),);
    }

    recommendations.add('为模板添加完整的使用示例');
    recommendations.add('定期更新模板以支持最新技术栈');

    return (issues: issues, recommendations: recommendations);
  }

  /// 获取模板文件列表
  Future<List<File>> _getTemplateFiles(String templatePath) async {
    final templatesDir = Directory(path.join(templatePath, 'templates'));
    if (!await templatesDir.exists()) {
      return [];
    }

    return templatesDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.template'))
        .toList();
  }

  /// 获取所有文件列表
  Future<List<File>> _getAllFiles(String templatePath) async {
    final templateDir = Directory(templatePath);
    if (!await templateDir.exists()) {
      return [];
    }

    return templateDir.listSync(recursive: true).whereType<File>().toList();
  }

  /// 确定验证结果
  bool _determineValidationResult(List<ValidationIssue> issues) {
    if (config.strictMode) {
      return !issues.any((issue) =>
          issue.severity == ValidationSeverity.error ||
          issue.severity == ValidationSeverity.fatal,);
    } else {
      return !issues.any((issue) => issue.severity == ValidationSeverity.fatal);
    }
  }

  /// 生成验证摘要
  Map<String, dynamic> _generateValidationSummary(
    List<ValidationIssue> issues,
    String templatePath,
  ) {
    return {
      'templatePath': templatePath,
      'totalIssues': issues.length,
      'fatalErrors':
          issues.where((i) => i.severity == ValidationSeverity.fatal).length,
      'errors':
          issues.where((i) => i.severity == ValidationSeverity.error).length,
      'warnings':
          issues.where((i) => i.severity == ValidationSeverity.warning).length,
      'infos':
          issues.where((i) => i.severity == ValidationSeverity.info).length,
      'ruleTypes': issues.map((i) => i.ruleType.name).toSet().toList(),
    };
  }

  /// 获取下一个主版本号
  String _getNextMajorVersion(String version) {
    final parts = version.split('.');
    if (parts.isNotEmpty) {
      final major = int.tryParse(parts[0]) ?? 0;
      return '${major + 1}.0.0';
    }
    return '2.0.0';
  }
}
