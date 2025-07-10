/*
---------------------------------------------------------------
File name:          enterprise_template_creator.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级模板创建器 (Enterprise Template Creator)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.3 企业级模板创建工具;
---------------------------------------------------------------
*/

import 'dart:convert';
import 'dart:io';

import 'package:ming_status_cli/src/core/parameters/enterprise_template_parameter.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;

/// 模板元数据
class TemplateMetadata {
  /// 创建模板元数据实例
  const TemplateMetadata({
    required this.name,
    required this.version,
    this.description,
    this.author,
    this.tags = const [],
    this.parameters = const [],
    this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  /// 模板名称
  final String name;

  /// 模板版本
  final String version;

  /// 模板描述
  final String? description;

  /// 作者
  final String? author;

  /// 标签
  final List<String> tags;

  /// 参数列表
  final List<EnterpriseTemplateParameter> parameters;

  /// 创建时间
  final DateTime? createdAt;

  /// 更新时间
  final DateTime? updatedAt;

  /// 额外元数据
  final Map<String, dynamic> metadata;
}

/// 配置验证结果
class _ConfigValidationResult {
  /// 创建配置验证结果实例
  const _ConfigValidationResult({
    required this.isValid,
    this.errors = const [],
  });

  /// 是否有效
  final bool isValid;

  /// 错误列表
  final List<String> errors;
}

/// 最佳实践检查结果
class _BestPracticeResult {
  /// 创建最佳实践检查结果实例
  const _BestPracticeResult({
    this.warnings = const [],
    this.errors = const [],
  });

  /// 警告列表
  final List<String> warnings;

  /// 错误列表
  final List<String> errors;
}

/// 模板创建模式
enum TemplateCreationMode {
  /// 从零开始创建
  fromScratch,

  /// 从现有项目逆向生成
  fromProject,

  /// 基于现有模板扩展
  fromTemplate,

  /// 团队协作创建
  collaborative,
}

/// 代码分析类型
enum CodeAnalysisType {
  /// 结构分析
  structural,

  /// 语法分析
  syntactic,

  /// 语义分析
  semantic,

  /// 依赖分析
  dependency,

  /// 模式分析
  pattern,
}

/// 参数化建议
class ParameterizationSuggestion {
  /// 创建参数化建议实例
  const ParameterizationSuggestion({
    required this.filePath,
    required this.lineNumber,
    required this.originalValue,
    required this.suggestedParameter,
    required this.confidence,
    required this.reason,
    this.context,
    this.alternatives = const [],
  });

  /// 文件路径
  final String filePath;

  /// 行号
  final int lineNumber;

  /// 原始值
  final String originalValue;

  /// 建议的参数
  final EnterpriseTemplateParameter suggestedParameter;

  /// 置信度 (0.0-1.0)
  final double confidence;

  /// 建议原因
  final String reason;

  /// 上下文信息
  final String? context;

  /// 替代方案
  final List<EnterpriseTemplateParameter> alternatives;
}

/// 模板创建配置
class TemplateCreationConfig {
  /// 创建模板创建配置实例
  const TemplateCreationConfig({
    required this.mode,
    this.sourcePath,
    this.baseTemplatePath,
    this.outputPath,
    this.enableCodeAnalysis = true,
    this.enableParameterization = true,
    this.enableBestPractices = true,
    this.analysisTypes = const {
      CodeAnalysisType.structural,
      CodeAnalysisType.syntactic,
      CodeAnalysisType.dependency,
    },
    this.minConfidence = 0.7,
    this.excludePatterns = const [],
    this.includePatterns = const [],
    this.metadata = const {},
  });

  /// 创建模式
  final TemplateCreationMode mode;

  /// 源项目路径 (fromProject模式)
  final String? sourcePath;

  /// 基础模板路径 (fromTemplate模式)
  final String? baseTemplatePath;

  /// 输出路径
  final String? outputPath;

  /// 是否启用代码分析
  final bool enableCodeAnalysis;

  /// 是否启用自动参数化
  final bool enableParameterization;

  /// 是否启用最佳实践检查
  final bool enableBestPractices;

  /// 分析类型
  final Set<CodeAnalysisType> analysisTypes;

  /// 最小置信度阈值
  final double minConfidence;

  /// 排除模式
  final List<String> excludePatterns;

  /// 包含模式
  final List<String> includePatterns;

  /// 额外元数据
  final Map<String, dynamic> metadata;
}

/// 模板创建结果
class TemplateCreationResult {
  /// 创建模板创建结果实例
  const TemplateCreationResult({
    required this.success,
    required this.templatePath,
    this.metadata,
    this.suggestions = const [],
    this.warnings = const [],
    this.errors = const [],
    this.statistics,
    this.creationTime,
  });

  /// 是否成功
  final bool success;

  /// 模板路径
  final String templatePath;

  /// 模板元数据
  final TemplateMetadata? metadata;

  /// 参数化建议
  final List<ParameterizationSuggestion> suggestions;

  /// 警告信息
  final List<String> warnings;

  /// 错误信息
  final List<String> errors;

  /// 创建统计
  final Map<String, dynamic>? statistics;

  /// 创建时间
  final DateTime? creationTime;
}

/// 企业级模板创建器
class EnterpriseTemplateCreator {
  /// 创建企业级模板创建器实例
  EnterpriseTemplateCreator({
    this.enableAdvancedAnalysis = true,
    this.enableCollaboration = false,
    this.maxAnalysisDepth = 5,
    this.analysisTimeout = const Duration(minutes: 10),
  });

  /// 是否启用高级分析
  final bool enableAdvancedAnalysis;

  /// 是否启用协作功能
  final bool enableCollaboration;

  /// 最大分析深度
  final int maxAnalysisDepth;

  /// 分析超时时间
  final Duration analysisTimeout;

  /// 创建模板
  Future<TemplateCreationResult> createTemplate({
    required String templateName,
    required TemplateCreationConfig config,
    Map<String, dynamic>? customMetadata,
  }) async {
    try {
      cli_logger.Logger.info('开始创建模板: $templateName');
      final startTime = DateTime.now();

      final warnings = <String>[];
      final errors = <String>[];
      final suggestions = <ParameterizationSuggestion>[];

      // 1. 验证配置
      final configValidation = _validateConfig(config);
      if (!configValidation.isValid) {
        errors.addAll(configValidation.errors);
        return TemplateCreationResult(
          success: false,
          templatePath: '',
          errors: errors,
          creationTime: startTime,
        );
      }

      // 2. 根据模式执行不同的创建流程
      String templatePath;
      TemplateMetadata? metadata;

      switch (config.mode) {
        case TemplateCreationMode.fromScratch:
          final result = await _createFromScratch(templateName, config);
          templatePath = result.templatePath;
          metadata = result.metadata;
          suggestions.addAll(result.suggestions);
          warnings.addAll(result.warnings);
          errors.addAll(result.errors);

        case TemplateCreationMode.fromProject:
          final result = await _createFromProject(templateName, config);
          templatePath = result.templatePath;
          metadata = result.metadata;
          suggestions.addAll(result.suggestions);
          warnings.addAll(result.warnings);
          errors.addAll(result.errors);

        case TemplateCreationMode.fromTemplate:
          final result = await _createFromTemplate(templateName, config);
          templatePath = result.templatePath;
          metadata = result.metadata;
          suggestions.addAll(result.suggestions);
          warnings.addAll(result.warnings);
          errors.addAll(result.errors);

        case TemplateCreationMode.collaborative:
          final result = await _createCollaborative(templateName, config);
          templatePath = result.templatePath;
          metadata = result.metadata;
          suggestions.addAll(result.suggestions);
          warnings.addAll(result.warnings);
          errors.addAll(result.errors);
      }

      // 3. 应用自定义元数据
      if (customMetadata != null && metadata != null) {
        metadata = _mergeMetadata(metadata, customMetadata);
      }

      // 4. 最佳实践检查
      if (config.enableBestPractices) {
        final practiceResult = await _checkBestPractices(templatePath);
        warnings.addAll(practiceResult.warnings);
        errors.addAll(practiceResult.errors);
      }

      // 5. 生成统计信息
      final statistics = _generateStatistics(
        templatePath,
        suggestions,
        warnings,
        errors,
        startTime,
      );

      final success = errors.isEmpty;

      cli_logger.Logger.info(
        '模板创建${success ? '成功' : '失败'}: $templateName - '
        '${suggestions.length}个建议, ${warnings.length}个警告, ${errors.length}个错误',
      );

      return TemplateCreationResult(
        success: success,
        templatePath: templatePath,
        metadata: metadata,
        suggestions: suggestions,
        warnings: warnings,
        errors: errors,
        statistics: statistics,
        creationTime: startTime,
      );
    } catch (e) {
      cli_logger.Logger.error('模板创建异常', error: e);
      return TemplateCreationResult(
        success: false,
        templatePath: '',
        errors: ['模板创建时发生异常: $e'],
        creationTime: DateTime.now(),
      );
    }
  }

  /// 分析现有项目
  Future<List<ParameterizationSuggestion>> analyzeProject(
    String projectPath, {
    Set<CodeAnalysisType> analysisTypes = const {
      CodeAnalysisType.structural,
      CodeAnalysisType.syntactic,
      CodeAnalysisType.dependency,
    },
    double minConfidence = 0.7,
  }) async {
    try {
      cli_logger.Logger.debug('开始分析项目: $projectPath');

      final suggestions = <ParameterizationSuggestion>[];

      // 1. 结构分析
      if (analysisTypes.contains(CodeAnalysisType.structural)) {
        final structuralSuggestions = await _analyzeStructure(projectPath);
        suggestions.addAll(
            structuralSuggestions.where((s) => s.confidence >= minConfidence),);
      }

      // 2. 语法分析
      if (analysisTypes.contains(CodeAnalysisType.syntactic)) {
        final syntacticSuggestions = await _analyzeSyntax(projectPath);
        suggestions.addAll(
            syntacticSuggestions.where((s) => s.confidence >= minConfidence),);
      }

      // 3. 依赖分析
      if (analysisTypes.contains(CodeAnalysisType.dependency)) {
        final dependencySuggestions = await _analyzeDependencies(projectPath);
        suggestions.addAll(
            dependencySuggestions.where((s) => s.confidence >= minConfidence),);
      }

      // 4. 语义分析 (高级功能)
      if (enableAdvancedAnalysis &&
          analysisTypes.contains(CodeAnalysisType.semantic)) {
        final semanticSuggestions = await _analyzeSemantic(projectPath);
        suggestions.addAll(
            semanticSuggestions.where((s) => s.confidence >= minConfidence),);
      }

      // 5. 模式分析 (高级功能)
      if (enableAdvancedAnalysis &&
          analysisTypes.contains(CodeAnalysisType.pattern)) {
        final patternSuggestions = await _analyzePatterns(projectPath);
        suggestions.addAll(
            patternSuggestions.where((s) => s.confidence >= minConfidence),);
      }

      // 去重和排序
      final uniqueSuggestions = _deduplicateSuggestions(suggestions);
      uniqueSuggestions.sort((a, b) => b.confidence.compareTo(a.confidence));

      cli_logger.Logger.info(
        '项目分析完成: ${uniqueSuggestions.length}个参数化建议',
      );

      return uniqueSuggestions;
    } catch (e) {
      cli_logger.Logger.error('项目分析失败', error: e);
      return [];
    }
  }

  /// 验证配置
  _ConfigValidationResult _validateConfig(TemplateCreationConfig config) {
    final errors = <String>[];

    switch (config.mode) {
      case TemplateCreationMode.fromProject:
        if (config.sourcePath == null || config.sourcePath!.isEmpty) {
          errors.add('fromProject模式需要指定sourcePath');
        } else if (!Directory(config.sourcePath!).existsSync()) {
          errors.add('源项目路径不存在: ${config.sourcePath}');
        }

      case TemplateCreationMode.fromTemplate:
        if (config.baseTemplatePath == null ||
            config.baseTemplatePath!.isEmpty) {
          errors.add('fromTemplate模式需要指定baseTemplatePath');
        } else if (!Directory(config.baseTemplatePath!).existsSync()) {
          errors.add('基础模板路径不存在: ${config.baseTemplatePath}');
        }

      default:
        break;
    }

    if (config.minConfidence < 0.0 || config.minConfidence > 1.0) {
      errors.add('置信度阈值必须在0.0-1.0之间');
    }

    return _ConfigValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }

  /// 从零开始创建
  Future<TemplateCreationResult> _createFromScratch(
    String templateName,
    TemplateCreationConfig config,
  ) async {
    // 实现从零开始创建模板的逻辑
    // 这里提供基础实现框架

    final outputPath = config.outputPath ?? './templates/$templateName';
    final templateDir = Directory(outputPath);

    if (!await templateDir.exists()) {
      await templateDir.create(recursive: true);
    }

    // 创建基础模板结构
    await _createBasicTemplateStructure(outputPath, templateName);

    // 生成默认元数据
    final metadata = _generateDefaultMetadata(templateName, config);

    return TemplateCreationResult(
      success: true,
      templatePath: outputPath,
      metadata: metadata,
      creationTime: DateTime.now(),
    );
  }

  /// 从现有项目创建
  Future<TemplateCreationResult> _createFromProject(
    String templateName,
    TemplateCreationConfig config,
  ) async {
    final sourcePath = config.sourcePath!;
    final outputPath = config.outputPath ?? './templates/$templateName';

    final suggestions = <ParameterizationSuggestion>[];
    final warnings = <String>[];
    final errors = <String>[];

    try {
      // 1. 分析项目结构
      if (config.enableCodeAnalysis) {
        final projectSuggestions = await analyzeProject(
          sourcePath,
          analysisTypes: config.analysisTypes,
          minConfidence: config.minConfidence,
        );
        suggestions.addAll(projectSuggestions);
      }

      // 2. 复制项目文件
      await _copyProjectFiles(sourcePath, outputPath, config);

      // 3. 应用参数化建议
      if (config.enableParameterization) {
        await _applyParameterization(outputPath, suggestions);
      }

      // 4. 生成模板元数据
      final metadata = await _generateProjectMetadata(
        templateName,
        sourcePath,
        suggestions,
        config,
      );

      return TemplateCreationResult(
        success: true,
        templatePath: outputPath,
        metadata: metadata,
        suggestions: suggestions,
        warnings: warnings,
        errors: errors,
        creationTime: DateTime.now(),
      );
    } catch (e) {
      errors.add('从项目创建模板失败: $e');
      return TemplateCreationResult(
        success: false,
        templatePath: outputPath,
        suggestions: suggestions,
        warnings: warnings,
        errors: errors,
        creationTime: DateTime.now(),
      );
    }
  }

  /// 从现有模板创建
  Future<TemplateCreationResult> _createFromTemplate(
    String templateName,
    TemplateCreationConfig config,
  ) async {
    // 实现基于现有模板扩展的逻辑
    final baseTemplatePath = config.baseTemplatePath!;
    final outputPath = config.outputPath ?? './templates/$templateName';

    // 复制基础模板
    await _copyTemplateFiles(baseTemplatePath, outputPath);

    // 扩展模板功能
    final metadata =
        await _extendTemplateMetadata(baseTemplatePath, templateName, config);

    return TemplateCreationResult(
      success: true,
      templatePath: outputPath,
      metadata: metadata,
      creationTime: DateTime.now(),
    );
  }

  /// 协作创建
  Future<TemplateCreationResult> _createCollaborative(
    String templateName,
    TemplateCreationConfig config,
  ) async {
    // 实现团队协作创建的逻辑
    // 这里提供基础实现框架

    if (!enableCollaboration) {
      return TemplateCreationResult(
        success: false,
        templatePath: '',
        errors: const ['协作功能未启用'],
        creationTime: DateTime.now(),
      );
    }

    // 协作创建的具体实现
    final outputPath = config.outputPath ?? './templates/$templateName';
    final metadata = _generateDefaultMetadata(templateName, config);

    return TemplateCreationResult(
      success: true,
      templatePath: outputPath,
      metadata: metadata,
      creationTime: DateTime.now(),
    );
  }

  /// 合并元数据
  TemplateMetadata _mergeMetadata(
    TemplateMetadata original,
    Map<String, dynamic> customMetadata,
  ) {
    return TemplateMetadata(
      name: customMetadata['name']?.toString() ?? original.name,
      version: customMetadata['version']?.toString() ?? original.version,
      description:
          customMetadata['description']?.toString() ?? original.description,
      author: customMetadata['author']?.toString() ?? original.author,
      tags: customMetadata['tags'] is List
          ? List<String>.from(customMetadata['tags'] as List)
          : original.tags,
      parameters: original.parameters,
      createdAt: original.createdAt,
      updatedAt: DateTime.now(),
      metadata: {
        ...original.metadata,
        ...customMetadata,
      },
    );
  }

  /// 检查最佳实践
  Future<_BestPracticeResult> _checkBestPractices(String templatePath) async {
    final warnings = <String>[];
    final errors = <String>[];

    try {
      final templateDir = Directory(templatePath);
      if (!await templateDir.exists()) {
        errors.add('模板目录不存在: $templatePath');
        return _BestPracticeResult(warnings: warnings, errors: errors);
      }

      // 检查必需文件
      final requiredFiles = ['template.yaml', 'README.md'];
      for (final fileName in requiredFiles) {
        final file = File('$templatePath/$fileName');
        if (!await file.exists()) {
          warnings.add('缺少推荐文件: $fileName');
        }
      }

      // 检查目录结构
      final recommendedDirs = ['src', 'docs', 'tests'];
      for (final dirName in recommendedDirs) {
        final dir = Directory('$templatePath/$dirName');
        if (!await dir.exists()) {
          warnings.add('缺少推荐目录: $dirName');
        }
      }
    } catch (e) {
      errors.add('最佳实践检查失败: $e');
    }

    return _BestPracticeResult(warnings: warnings, errors: errors);
  }

  /// 生成统计信息
  Map<String, dynamic> _generateStatistics(
    String templatePath,
    List<ParameterizationSuggestion> suggestions,
    List<String> warnings,
    List<String> errors,
    DateTime startTime,
  ) {
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    return {
      'creation_duration_ms': duration.inMilliseconds,
      'suggestions_count': suggestions.length,
      'warnings_count': warnings.length,
      'errors_count': errors.length,
      'high_confidence_suggestions':
          suggestions.where((s) => s.confidence >= 0.8).length,
      'template_path': templatePath,
      'created_at': startTime.toIso8601String(),
      'completed_at': endTime.toIso8601String(),
    };
  }

  /// 结构分析
  Future<List<ParameterizationSuggestion>> _analyzeStructure(
      String projectPath,) async {
    final suggestions = <ParameterizationSuggestion>[];

    try {
      final projectDir = Directory(projectPath);
      if (!await projectDir.exists()) {
        return suggestions;
      }

      // 分析项目名称
      final projectName = projectPath.split('/').last;
      if (projectName.isNotEmpty) {
        suggestions.add(ParameterizationSuggestion(
          filePath: 'project_structure',
          lineNumber: 0,
          originalValue: projectName,
          suggestedParameter: EnterpriseTemplateParameter(
            name: 'project_name',
            enterpriseType: EnterpriseParameterType.string,
            description: '项目名称',
            defaultValue: projectName,
          ),
          confidence: 0.9,
          reason: '项目名称应该参数化',
        ),);
      }

      // 分析配置文件
      await _analyzeConfigFiles(projectPath, suggestions);
    } catch (e) {
      cli_logger.Logger.error('结构分析失败', error: e);
    }

    return suggestions;
  }

  /// 语法分析
  Future<List<ParameterizationSuggestion>> _analyzeSyntax(
      String projectPath,) async {
    final suggestions = <ParameterizationSuggestion>[];

    try {
      // 分析Dart文件
      await _analyzeDartFiles(projectPath, suggestions);

      // 分析YAML文件
      await _analyzeYamlFiles(projectPath, suggestions);

      // 分析JSON文件
      await _analyzeJsonFiles(projectPath, suggestions);
    } catch (e) {
      cli_logger.Logger.error('语法分析失败', error: e);
    }

    return suggestions;
  }

  /// 依赖分析
  Future<List<ParameterizationSuggestion>> _analyzeDependencies(
      String projectPath,) async {
    final suggestions = <ParameterizationSuggestion>[];

    try {
      // 分析pubspec.yaml依赖
      final pubspecFile = File('$projectPath/pubspec.yaml');
      if (await pubspecFile.exists()) {
        final content = await pubspecFile.readAsString();
        final lines = content.split('\n');

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.contains(':') && line.contains('^')) {
            // 检测版本号
            final parts = line.split(':');
            if (parts.length == 2) {
              final packageName = parts[0].trim();
              final version = parts[1].trim();

              suggestions.add(ParameterizationSuggestion(
                filePath: 'pubspec.yaml',
                lineNumber: i + 1,
                originalValue: version,
                suggestedParameter: EnterpriseTemplateParameter(
                  name: '${packageName}_version',
                  enterpriseType: EnterpriseParameterType.string,
                  description: '$packageName包版本',
                  defaultValue: version,
                ),
                confidence: 0.8,
                reason: '依赖版本应该参数化',
              ),);
            }
          }
        }
      }
    } catch (e) {
      cli_logger.Logger.error('依赖分析失败', error: e);
    }

    return suggestions;
  }

  /// 语义分析 (高级功能)
  Future<List<ParameterizationSuggestion>> _analyzeSemantic(
      String projectPath,) async {
    final suggestions = <ParameterizationSuggestion>[];

    // 高级语义分析实现
    // 这里提供基础框架

    return suggestions;
  }

  /// 模式分析 (高级功能)
  Future<List<ParameterizationSuggestion>> _analyzePatterns(
      String projectPath,) async {
    final suggestions = <ParameterizationSuggestion>[];

    // 高级模式分析实现
    // 这里提供基础框架

    return suggestions;
  }

  /// 去重建议
  List<ParameterizationSuggestion> _deduplicateSuggestions(
    List<ParameterizationSuggestion> suggestions,
  ) {
    final seen = <String>{};
    final unique = <ParameterizationSuggestion>[];

    for (final suggestion in suggestions) {
      final key =
          '${suggestion.filePath}:${suggestion.lineNumber}:${suggestion.originalValue}';
      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(suggestion);
      }
    }

    return unique;
  }

  /// 分析配置文件
  Future<void> _analyzeConfigFiles(
    String projectPath,
    List<ParameterizationSuggestion> suggestions,
  ) async {
    // 分析pubspec.yaml
    final pubspecFile = File('$projectPath/pubspec.yaml');
    if (await pubspecFile.exists()) {
      final content = await pubspecFile.readAsString();
      final lines = content.split('\n');

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains('name:')) {
          final name = line.split(':')[1].trim();
          suggestions.add(ParameterizationSuggestion(
            filePath: 'pubspec.yaml',
            lineNumber: i + 1,
            originalValue: name,
            suggestedParameter: EnterpriseTemplateParameter(
              name: 'app_name',
              enterpriseType: EnterpriseParameterType.string,
              description: '应用名称',
              defaultValue: name,
            ),
            confidence: 0.9,
            reason: '应用名称应该参数化',
          ),);
        }
      }
    }
  }

  /// 分析Dart文件
  Future<void> _analyzeDartFiles(
    String projectPath,
    List<ParameterizationSuggestion> suggestions,
  ) async {
    final dartFiles = await _findFilesByExtension(projectPath, '.dart');

    for (final file in dartFiles) {
      try {
        final content = await file.readAsString();
        final lines = content.split('\n');

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];

          // 检测字符串常量
          final stringMatches =
              RegExp("'([^']+)'|" '"([^"]+)"').allMatches(line);
          for (final match in stringMatches) {
            final value = match.group(1) ?? match.group(2) ?? '';
            if (value.length > 3 && _shouldParameterize(value)) {
              suggestions.add(ParameterizationSuggestion(
                filePath: file.path.replaceFirst('$projectPath/', ''),
                lineNumber: i + 1,
                originalValue: value,
                suggestedParameter: EnterpriseTemplateParameter(
                  name: _generateParameterName(value),
                  enterpriseType: EnterpriseParameterType.string,
                  description: '字符串常量',
                  defaultValue: value,
                ),
                confidence: 0.6,
                reason: '字符串常量可以参数化',
              ),);
            }
          }
        }
      } catch (e) {
        // 忽略文件读取错误
      }
    }
  }

  /// 分析YAML文件
  Future<void> _analyzeYamlFiles(
    String projectPath,
    List<ParameterizationSuggestion> suggestions,
  ) async {
    final yamlFiles = await _findFilesByExtension(projectPath, '.yaml');
    yamlFiles.addAll(await _findFilesByExtension(projectPath, '.yml'));

    for (final file in yamlFiles) {
      try {
        final content = await file.readAsString();
        final lines = content.split('\n');

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.contains(':') && !line.trim().startsWith('#')) {
            final parts = line.split(':');
            if (parts.length >= 2) {
              final key = parts[0].trim();
              final value = parts.sublist(1).join(':').trim();

              if (value.isNotEmpty && _shouldParameterize(value)) {
                suggestions.add(ParameterizationSuggestion(
                  filePath: file.path.replaceFirst('$projectPath/', ''),
                  lineNumber: i + 1,
                  originalValue: value,
                  suggestedParameter: EnterpriseTemplateParameter(
                    name: _generateParameterName(key),
                    enterpriseType: EnterpriseParameterType.string,
                    description: 'YAML配置值',
                    defaultValue: value,
                  ),
                  confidence: 0.7,
                  reason: 'YAML配置值可以参数化',
                ),);
              }
            }
          }
        }
      } catch (e) {
        // 忽略文件读取错误
      }
    }
  }

  /// 分析JSON文件
  Future<void> _analyzeJsonFiles(
    String projectPath,
    List<ParameterizationSuggestion> suggestions,
  ) async {
    final jsonFiles = await _findFilesByExtension(projectPath, '.json');

    for (final file in jsonFiles) {
      try {
        final content = await file.readAsString();
        final data = json.decode(content);

        if (data is Map<String, dynamic>) {
          _analyzeJsonObject(
            data,
            file.path.replaceFirst('$projectPath/', ''),
            suggestions,
          );
        }
      } catch (e) {
        // 忽略JSON解析错误
      }
    }
  }

  /// 分析JSON对象
  void _analyzeJsonObject(
    Map<String, dynamic> obj,
    String filePath,
    List<ParameterizationSuggestion> suggestions, [
    String prefix = '',
  ]) {
    obj.forEach((key, value) {
      final fullKey = prefix.isEmpty ? key : '$prefix.$key';

      if (value is String && _shouldParameterize(value)) {
        suggestions.add(ParameterizationSuggestion(
          filePath: filePath,
          lineNumber: 0, // JSON文件中难以确定行号
          originalValue: value,
          suggestedParameter: EnterpriseTemplateParameter(
            name: _generateParameterName(fullKey),
            enterpriseType: EnterpriseParameterType.string,
            description: 'JSON配置值',
            defaultValue: value,
          ),
          confidence: 0.7,
          reason: 'JSON配置值可以参数化',
        ),);
      } else if (value is Map<String, dynamic>) {
        _analyzeJsonObject(value, filePath, suggestions, fullKey);
      }
    });
  }

  /// 查找指定扩展名的文件
  Future<List<File>> _findFilesByExtension(
      String path, String extension,) async {
    final files = <File>[];
    final dir = Directory(path);

    if (!await dir.exists()) {
      return files;
    }

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith(extension)) {
        files.add(entity);
      }
    }

    return files;
  }

  /// 判断是否应该参数化
  bool _shouldParameterize(String value) {
    // 排除一些不应该参数化的值
    final excludePatterns = [
      RegExp(r'^\d+$'), // 纯数字
      RegExp(r'^[a-z]+$'), // 纯小写字母
      RegExp(r'^(true|false)$'), // 布尔值
      RegExp(r'^(null|undefined)$'), // 空值
    ];

    for (final pattern in excludePatterns) {
      if (pattern.hasMatch(value)) {
        return false;
      }
    }

    return value.length > 2;
  }

  /// 生成参数名称
  String _generateParameterName(String input) {
    // 将输入转换为合适的参数名称
    return input
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]'), '_')
        .replaceAll(RegExp('_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// 创建基础模板结构
  Future<void> _createBasicTemplateStructure(
    String outputPath,
    String templateName,
  ) async {
    // 创建基础目录
    final dirs = ['src', 'docs', 'tests'];
    for (final dirName in dirs) {
      final dir = Directory('$outputPath/$dirName');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }

    // 创建基础文件
    final readmeFile = File('$outputPath/README.md');
    await readmeFile.writeAsString('''
# $templateName

这是一个由Ming Status CLI生成的模板。

## 使用方法

```bash
ming create my_project --template=$templateName
```

## 参数

请参考template.yaml文件了解可用参数。
''');

    final templateFile = File('$outputPath/template.yaml');
    await templateFile.writeAsString('''
name: $templateName
version: 1.0.0
description: $templateName模板
author: Ming Status CLI
parameters: []
''');
  }

  /// 生成默认元数据
  TemplateMetadata _generateDefaultMetadata(
    String templateName,
    TemplateCreationConfig config,
  ) {
    return TemplateMetadata(
      name: templateName,
      version: '1.0.0',
      description: '$templateName模板',
      author: 'Ming Status CLI',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      metadata: config.metadata,
    );
  }

  /// 复制项目文件
  Future<void> _copyProjectFiles(
    String sourcePath,
    String outputPath,
    TemplateCreationConfig config,
  ) async {
    final sourceDir = Directory(sourcePath);
    final outputDir = Directory(outputPath);

    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    await for (final entity in sourceDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = entity.path
            .replaceFirst(sourcePath, '')
            .replaceFirst(RegExp(r'^[/\\]'), '');

        // 检查是否应该排除
        if (_shouldExcludeFile(relativePath, config)) {
          continue;
        }

        final targetFile = File('$outputPath/$relativePath');
        final targetDir = Directory(targetFile.parent.path);

        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }

        await entity.copy(targetFile.path);
      }
    }
  }

  /// 判断是否应该排除文件
  bool _shouldExcludeFile(String filePath, TemplateCreationConfig config) {
    // 默认排除模式
    final defaultExcludes = [
      '.git/',
      '.dart_tool/',
      'build/',
      '.packages',
      'pubspec.lock',
    ];

    final allExcludes = [...defaultExcludes, ...config.excludePatterns];

    for (final pattern in allExcludes) {
      if (filePath.contains(pattern)) {
        return true;
      }
    }

    // 检查包含模式
    if (config.includePatterns.isNotEmpty) {
      for (final pattern in config.includePatterns) {
        if (filePath.contains(pattern)) {
          return false;
        }
      }
      return true; // 如果有包含模式但不匹配，则排除
    }

    return false;
  }

  /// 应用参数化建议
  Future<void> _applyParameterization(
    String templatePath,
    List<ParameterizationSuggestion> suggestions,
  ) async {
    // 这里实现参数化应用逻辑
    // 将建议的参数化应用到模板文件中

    for (final suggestion in suggestions) {
      final filePath = '$templatePath/${suggestion.filePath}';
      final file = File(filePath);

      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          final parameterName = suggestion.suggestedParameter.name;
          final newContent = content.replaceAll(
            suggestion.originalValue,
            '{{$parameterName}}',
          );
          await file.writeAsString(newContent);
        } catch (e) {
          // 忽略应用失败的情况
        }
      }
    }
  }

  /// 生成项目元数据
  Future<TemplateMetadata> _generateProjectMetadata(
    String templateName,
    String sourcePath,
    List<ParameterizationSuggestion> suggestions,
    TemplateCreationConfig config,
  ) async {
    final parameters = suggestions.map((s) => s.suggestedParameter).toList();

    return TemplateMetadata(
      name: templateName,
      version: '1.0.0',
      description: '从项目 $sourcePath 生成的模板',
      author: 'Ming Status CLI',
      tags: const ['generated', 'project'],
      parameters: parameters,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      metadata: {
        ...config.metadata,
        'source_path': sourcePath,
        'suggestions_count': suggestions.length,
      },
    );
  }

  /// 复制模板文件
  Future<void> _copyTemplateFiles(String sourcePath, String outputPath) async {
    final sourceDir = Directory(sourcePath);
    final outputDir = Directory(outputPath);

    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    await for (final entity in sourceDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = entity.path.replaceFirst('$sourcePath/', '');
        final targetFile = File('$outputPath/$relativePath');
        final targetDir = Directory(targetFile.parent.path);

        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }

        await entity.copy(targetFile.path);
      }
    }
  }

  /// 扩展模板元数据
  Future<TemplateMetadata> _extendTemplateMetadata(
    String baseTemplatePath,
    String templateName,
    TemplateCreationConfig config,
  ) async {
    // 读取基础模板的元数据
    final baseMetadataFile = File('$baseTemplatePath/template.yaml');
    TemplateMetadata? baseMetadata;

    if (await baseMetadataFile.exists()) {
      // 这里应该解析YAML文件，简化实现
      baseMetadata = TemplateMetadata(
        name: 'base_template',
        version: '1.0.0',
        description: '基础模板',
        author: 'Unknown',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    return TemplateMetadata(
      name: templateName,
      version: '1.0.0',
      description: '基于 ${baseMetadata?.name ?? 'unknown'} 扩展的模板',
      author: 'Ming Status CLI',
      tags: [...?baseMetadata?.tags, 'extended'],
      parameters: baseMetadata?.parameters ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      metadata: {
        ...?baseMetadata?.metadata,
        ...config.metadata,
        'base_template': baseTemplatePath,
      },
    );
  }
}
