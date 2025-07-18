/*
---------------------------------------------------------------
File name:          scaffold_config.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        模板脚手架配置类 (Template Scaffold Configuration)
---------------------------------------------------------------
Change History:
    2025/07/12: Extracted from template_scaffold.dart - 模块化重构;
---------------------------------------------------------------
*/

import 'package:ming_status_cli/src/core/template_system/template_types.dart';

/// 脚手架配置
///
/// 定义模板脚手架的配置参数
class ScaffoldConfig {
  /// 创建脚手架配置实例
  const ScaffoldConfig({
    required this.templateName,
    required this.templateType,
    required this.author,
    required this.description,
    this.subType,
    this.version = '1.0.0',
    this.outputPath = '.',
    this.platform = TemplatePlatform.crossPlatform,
    this.framework = TemplateFramework.agnostic,
    this.complexity = TemplateComplexity.simple,
    this.maturity = TemplateMaturity.development,
    this.tags = const [],
    this.dependencies = const [],
    bool? includeTests,
    bool? includeDocumentation,
    bool? includeExamples,
    this.enableGitInit = true,
  })  : includeTests = includeTests ?? complexity != TemplateComplexity.simple,
        includeDocumentation =
            includeDocumentation ?? complexity != TemplateComplexity.simple,
        includeExamples =
            includeExamples ?? complexity != TemplateComplexity.simple;

  /// 从Map创建配置
  factory ScaffoldConfig.fromMap(Map<String, dynamic> map) {
    return ScaffoldConfig(
      templateName: map['templateName'] as String,
      templateType: TemplateType.values.firstWhere(
        (e) => e.name == map['templateType'],
        orElse: () => TemplateType.basic,
      ),
      subType: map['subType'] != null
          ? TemplateSubType.values.firstWhere(
              (e) => e.name == map['subType'],
              orElse: () => TemplateSubType.component,
            )
          : null,
      author: map['author'] as String,
      description: map['description'] as String,
      version: map['version'] as String? ?? '1.0.0',
      outputPath: map['outputPath'] as String? ?? '.',
      platform: TemplatePlatform.values.firstWhere(
        (e) => e.name == map['platform'],
        orElse: () => TemplatePlatform.crossPlatform,
      ),
      framework: TemplateFramework.values.firstWhere(
        (e) => e.name == map['framework'],
        orElse: () => TemplateFramework.agnostic,
      ),
      complexity: TemplateComplexity.values.firstWhere(
        (e) => e.name == map['complexity'],
        orElse: () => TemplateComplexity.simple,
      ),
      maturity: TemplateMaturity.values.firstWhere(
        (e) => e.name == map['maturity'],
        orElse: () => TemplateMaturity.development,
      ),
      tags: List<String>.from(map['tags'] as List? ?? []),
      dependencies: List<String>.from(map['dependencies'] as List? ?? []),
      includeTests: map['includeTests'] as bool?,
      includeDocumentation: map['includeDocumentation'] as bool?,
      includeExamples: map['includeExamples'] as bool?,
      enableGitInit: map['enableGitInit'] as bool? ?? true,
    );
  }

  /// 模板名称
  final String templateName;

  /// 模板类型
  final TemplateType templateType;

  /// 模板子类型
  final TemplateSubType? subType;

  /// 作者信息
  final String author;

  /// 模板描述
  final String description;

  /// 模板版本
  final String version;

  /// 输出路径
  final String outputPath;

  /// 目标平台
  final TemplatePlatform platform;

  /// 技术框架
  final TemplateFramework framework;

  /// 复杂度等级
  final TemplateComplexity complexity;

  /// 成熟度等级
  final TemplateMaturity maturity;

  /// 标签列表
  final List<String> tags;

  /// 依赖列表
  final List<String> dependencies;

  /// 是否包含测试
  final bool includeTests;

  /// 是否包含文档
  final bool includeDocumentation;

  /// 是否包含示例
  final bool includeExamples;

  /// 是否启用Git初始化
  final bool enableGitInit;

  /// 复制配置并修改部分参数
  ScaffoldConfig copyWith({
    String? templateName,
    TemplateType? templateType,
    TemplateSubType? subType,
    String? author,
    String? description,
    String? version,
    String? outputPath,
    TemplatePlatform? platform,
    TemplateFramework? framework,
    TemplateComplexity? complexity,
    TemplateMaturity? maturity,
    List<String>? tags,
    List<String>? dependencies,
    bool? includeTests,
    bool? includeDocumentation,
    bool? includeExamples,
    bool? enableGitInit,
  }) {
    return ScaffoldConfig(
      templateName: templateName ?? this.templateName,
      templateType: templateType ?? this.templateType,
      subType: subType ?? this.subType,
      author: author ?? this.author,
      description: description ?? this.description,
      version: version ?? this.version,
      outputPath: outputPath ?? this.outputPath,
      platform: platform ?? this.platform,
      framework: framework ?? this.framework,
      complexity: complexity ?? this.complexity,
      maturity: maturity ?? this.maturity,
      tags: tags ?? this.tags,
      dependencies: dependencies ?? this.dependencies,
      includeTests: includeTests ?? this.includeTests,
      includeDocumentation: includeDocumentation ?? this.includeDocumentation,
      includeExamples: includeExamples ?? this.includeExamples,
      enableGitInit: enableGitInit ?? this.enableGitInit,
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'templateName': templateName,
      'templateType': templateType.name,
      'subType': subType?.name,
      'author': author,
      'description': description,
      'version': version,
      'outputPath': outputPath,
      'platform': platform.name,
      'framework': framework.name,
      'complexity': complexity.name,
      'maturity': maturity.name,
      'tags': tags,
      'dependencies': dependencies,
      'includeTests': includeTests,
      'includeDocumentation': includeDocumentation,
      'includeExamples': includeExamples,
      'enableGitInit': enableGitInit,
    };
  }

  @override
  String toString() {
    return 'ScaffoldConfig('
        'templateName: $templateName, '
        'templateType: $templateType, '
        'framework: $framework, '
        'platform: $platform'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScaffoldConfig &&
        other.templateName == templateName &&
        other.templateType == templateType &&
        other.subType == subType &&
        other.author == author &&
        other.description == description &&
        other.version == version &&
        other.outputPath == outputPath &&
        other.platform == platform &&
        other.framework == framework &&
        other.complexity == complexity &&
        other.maturity == maturity;
  }

  @override
  int get hashCode {
    return Object.hash(
      templateName,
      templateType,
      subType,
      author,
      description,
      version,
      outputPath,
      platform,
      framework,
      complexity,
      maturity,
    );
  }
}
