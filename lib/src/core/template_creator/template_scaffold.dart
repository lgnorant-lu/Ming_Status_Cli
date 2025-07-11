/*
---------------------------------------------------------------
File name:          template_scaffold.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级模板脚手架生成器 (Enterprise Template Scaffold Generator)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.1 自定义模板创建工具;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/template_system/template_metadata.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;
import 'package:path/path.dart' as path;

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
    this.includeTests = true,
    this.includeDocumentation = true,
    this.includeExamples = true,
    this.enableGitInit = true,
  });

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
}

/// 脚手架生成结果
///
/// 包含脚手架生成的结果信息
class ScaffoldResult {
  /// 创建脚手架生成结果实例
  const ScaffoldResult({
    required this.success,
    required this.templatePath,
    this.generatedFiles = const [],
    this.errors = const [],
    this.warnings = const [],
  });

  /// 创建成功结果
  factory ScaffoldResult.success({
    required String templatePath,
    required List<String> generatedFiles,
    List<String> warnings = const [],
  }) {
    return ScaffoldResult(
      success: true,
      templatePath: templatePath,
      generatedFiles: generatedFiles,
      warnings: warnings,
    );
  }

  /// 创建失败结果
  factory ScaffoldResult.failure({
    required List<String> errors,
    String templatePath = '',
    List<String> warnings = const [],
  }) {
    return ScaffoldResult(
      success: false,
      templatePath: templatePath,
      errors: errors,
      warnings: warnings,
    );
  }

  /// 是否成功
  final bool success;

  /// 模板路径
  final String templatePath;

  /// 生成的文件列表
  final List<String> generatedFiles;

  /// 错误列表
  final List<String> errors;

  /// 警告列表
  final List<String> warnings;
}

/// 企业级模板脚手架生成器
///
/// 自动生成模板目录结构、配置文件、示例代码
class TemplateScaffold {
  /// 创建模板脚手架生成器实例
  TemplateScaffold();

  /// 生成模板脚手架
  ///
  /// 根据配置生成完整的模板项目结构
  Future<ScaffoldResult> generateScaffold(ScaffoldConfig config) async {
    try {
      cli_logger.Logger.info('开始生成模板脚手架: ${config.templateName}');

      // 1. 创建模板目录
      final templatePath = await _createTemplateDirectory(config);

      // 2. 生成基础文件结构
      final generatedFiles = <String>[];

      // 生成元数据文件
      await _generateMetadataFile(templatePath, config);
      generatedFiles.add('template.yaml');

      // 生成模板文件
      await _generateTemplateFiles(templatePath, config);
      generatedFiles.addAll(await _getTemplateFiles(templatePath, config));

      // 生成配置文件
      await _generateConfigFiles(templatePath, config);
      generatedFiles.addAll(['pubspec.yaml', '.gitignore']);

      // 生成文档
      if (config.includeDocumentation) {
        await _generateDocumentation(templatePath, config);
        generatedFiles.addAll(['README.md', 'CHANGELOG.md']);
      }

      // 生成测试
      if (config.includeTests) {
        await _generateTests(templatePath, config);
        generatedFiles.add('test/template_test.dart');
      }

      // 生成示例
      if (config.includeExamples) {
        await _generateExamples(templatePath, config);
        generatedFiles.add('example/example.dart');
      }

      // Git初始化
      if (config.enableGitInit) {
        await _initializeGit(templatePath);
      }

      cli_logger.Logger.success(
        '模板脚手架生成完成: ${config.templateName} '
        '(${generatedFiles.length}个文件)',
      );

      return ScaffoldResult.success(
        templatePath: templatePath,
        generatedFiles: generatedFiles,
      );
    } catch (e) {
      cli_logger.Logger.error('模板脚手架生成失败', error: e);
      return ScaffoldResult.failure(
        errors: ['脚手架生成异常: $e'],
      );
    }
  }

  /// 创建模板目录
  Future<String> _createTemplateDirectory(ScaffoldConfig config) async {
    final templatePath = path.join(config.outputPath, config.templateName);
    final templateDir = Directory(templatePath);

    if (await templateDir.exists()) {
      throw Exception('模板目录已存在: $templatePath');
    }

    await templateDir.create(recursive: true);

    // 创建子目录
    final subDirs = [
      'templates',
      'config',
      if (config.includeTests) 'test',
      if (config.includeExamples) 'example',
      if (config.includeDocumentation) 'docs',
    ];

    for (final subDir in subDirs) {
      await Directory(path.join(templatePath, subDir)).create(recursive: true);
    }

    return templatePath;
  }

  /// 生成元数据文件
  Future<void> _generateMetadataFile(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final metadata = TemplateMetadata(
      id: _generateTemplateId(config.templateName),
      name: config.templateName,
      version: config.version,
      author: config.author,
      description: config.description,
      type: config.templateType,
      subType: config.subType,
      tags: config.tags,
      complexity: config.complexity,
      maturity: config.maturity,
      platform: config.platform,
      framework: config.framework,
      dependencies: config.dependencies
          .map((dep) => TemplateDependency(name: dep, version: '^1.0.0'))
          .toList(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final metadataFile = File(path.join(templatePath, 'template.yaml'));
    await metadataFile.writeAsString(_generateMetadataYaml(metadata));
  }

  /// 生成模板文件
  Future<void> _generateTemplateFiles(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final templatesDir = path.join(templatePath, 'templates');

    // 根据模板类型生成不同的模板文件
    switch (config.templateType) {
      case TemplateType.ui:
        await _generateUITemplates(templatesDir, config);
      case TemplateType.service:
        await _generateServiceTemplates(templatesDir, config);
      case TemplateType.data:
        await _generateDataTemplates(templatesDir, config);
      case TemplateType.full:
        await _generateFullTemplates(templatesDir, config);
      case TemplateType.system:
        await _generateSystemTemplates(templatesDir, config);
      case TemplateType.basic:
        await _generateBasicTemplates(templatesDir, config);
      case TemplateType.micro:
        await _generateMicroTemplates(templatesDir, config);
      case TemplateType.plugin:
        await _generatePluginTemplates(templatesDir, config);
      case TemplateType.infrastructure:
        await _generateInfrastructureTemplates(templatesDir, config);
    }
  }

  /// 生成UI模板
  Future<void> _generateUITemplates(
    String templatesDir,
    ScaffoldConfig config,
  ) async {
    final mainFile = File(path.join(templatesDir, 'main.dart.template'));
    await mainFile.writeAsString('''
{{#if platform.flutter}}
import 'package:flutter/material.dart';

class {{componentName}} extends StatelessWidget {
  const {{componentName}}({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return {{#if subType.page}}Scaffold(
      appBar: AppBar(
        title: Text('{{title}}'),
      ),
      body: Center(
        child: Text('{{description}}'),
      ),
    ){{else}}Container(
      child: Text('{{description}}'),
    ){{/if}};
  }
}
{{else}}
// {{description}}
class {{componentName}} {
  // Implementation for {{platform.name}}
}
{{/if}}
''');
  }

  /// 生成Service模板
  Future<void> _generateServiceTemplates(
    String templatesDir,
    ScaffoldConfig config,
  ) async {
    final serviceFile = File(path.join(templatesDir, 'service.dart.template'));
    await serviceFile.writeAsString(r'''
{{#if subType.api}}
import 'dart:convert';
import 'package:http/http.dart' as http;

class {{serviceName}}Service {
  final String baseUrl;
  
  {{serviceName}}Service({required this.baseUrl});
  
  Future<Map<String, dynamic>> getData() async {
    final response = await http.get(Uri.parse('$baseUrl/{{endpoint}}'));
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }
}
{{else}}
class {{serviceName}}Service {
  // {{description}}
  
  Future<void> execute() async {
    // Implementation
  }
}
{{/if}}
''');
  }

  /// 生成配置文件
  Future<void> _generateConfigFiles(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    // 生成pubspec.yaml
    final pubspecFile = File(path.join(templatePath, 'pubspec.yaml'));
    await pubspecFile.writeAsString(_generatePubspecYaml(config));

    // 生成.gitignore
    final gitignoreFile = File(path.join(templatePath, '.gitignore'));
    await gitignoreFile.writeAsString(_generateGitignore());
  }

  /// 生成文档
  Future<void> _generateDocumentation(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    // 生成README.md
    final readmeFile = File(path.join(templatePath, 'README.md'));
    await readmeFile.writeAsString(_generateReadme(config));

    // 生成CHANGELOG.md
    final changelogFile = File(path.join(templatePath, 'CHANGELOG.md'));
    await changelogFile.writeAsString(_generateChangelog(config));
  }

  /// 生成测试
  Future<void> _generateTests(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final testFile =
        File(path.join(templatePath, 'test', 'template_test.dart'));
    await testFile.writeAsString(_generateTestFile(config));
  }

  /// 生成示例
  Future<void> _generateExamples(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final exampleFile =
        File(path.join(templatePath, 'example', 'example.dart'));
    await exampleFile.writeAsString(_generateExampleFile(config));
  }

  /// 初始化Git
  Future<void> _initializeGit(String templatePath) async {
    final result = await Process.run(
      'git',
      ['init'],
      workingDirectory: templatePath,
    );

    if (result.exitCode != 0) {
      cli_logger.Logger.warning('Git初始化失败: ${result.stderr}');
    }
  }

  /// 生成模板ID
  String _generateTemplateId(String templateName) {
    return templateName.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '_');
  }

  /// 获取模板文件列表
  Future<List<String>> _getTemplateFiles(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    // 简化实现，返回基础文件列表
    return ['templates/main.dart.template'];
  }

  // 其他模板类型的生成方法（简化实现）
  Future<void> _generateDataTemplates(
      String templatesDir, ScaffoldConfig config) async {
    // 实现数据层模板生成
  }

  Future<void> _generateFullTemplates(
      String templatesDir, ScaffoldConfig config) async {
    // 实现完整应用模板生成
  }

  Future<void> _generateSystemTemplates(
      String templatesDir, ScaffoldConfig config) async {
    // 实现系统配置模板生成
  }

  Future<void> _generateBasicTemplates(
      String templatesDir, ScaffoldConfig config) async {
    // 实现基础模板生成
  }

  Future<void> _generateMicroTemplates(
      String templatesDir, ScaffoldConfig config) async {
    // 实现微服务模板生成
  }

  Future<void> _generatePluginTemplates(
      String templatesDir, ScaffoldConfig config) async {
    // 实现插件模板生成
  }

  Future<void> _generateInfrastructureTemplates(
      String templatesDir, ScaffoldConfig config) async {
    // 实现基础设施模板生成
  }

  // 辅助方法用于生成各种配置文件内容
  String _generateMetadataYaml(TemplateMetadata metadata) {
    return '''
name: ${metadata.name}
version: ${metadata.version}
author: ${metadata.author}
description: ${metadata.description}
type: ${metadata.type.name}
${metadata.subType != null ? 'subType: ${metadata.subType!.name}' : ''}
platform: ${metadata.platform.name}
framework: ${metadata.framework.name}
complexity: ${metadata.complexity.name}
maturity: ${metadata.maturity.name}
tags: ${metadata.tags}
dependencies: ${metadata.dependencies.map((d) => '${d.name}: ${d.version}').toList()}
''';
  }

  String _generatePubspecYaml(ScaffoldConfig config) {
    return '''
name: ${config.templateName}
description: ${config.description}
version: ${config.version}

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
${config.dependencies.map((dep) => '  $dep: ^1.0.0').join('\n')}

dev_dependencies:
  test: ^1.24.0
''';
  }

  String _generateGitignore() {
    return '''
# Files and directories created by pub
.dart_tool/
.packages
build/
pubspec.lock

# IDE files
.vscode/
.idea/
*.iml

# OS files
.DS_Store
Thumbs.db
''';
  }

  String _generateReadme(ScaffoldConfig config) {
    return '''
# ${config.templateName}

${config.description}

## 使用方法

1. 安装依赖：
   ```bash
   dart pub get
   ```

2. 使用模板：
   ```bash
   ming template generate ${config.templateName}
   ```

## 特性

- 类型：${config.templateType.displayName}
- 平台：${config.platform.name}
- 框架：${config.framework.name}
- 复杂度：${config.complexity.name}

## 作者

${config.author}

## 许可证

MIT License
''';
  }

  String _generateChangelog(ScaffoldConfig config) {
    return '''
# Changelog

## [${config.version}] - ${DateTime.now().toIso8601String().split('T')[0]}

### Added
- 初始版本发布
- ${config.description}

### Features
- 支持${config.platform.name}平台
- 基于${config.framework.name}框架
- ${config.complexity.name}复杂度等级
''';
  }

  String _generateTestFile(ScaffoldConfig config) {
    return '''
import 'package:test/test.dart';

void main() {
  group('${config.templateName} Template Tests', () {
    test('should generate correctly', () {
      // TODO: 实现模板测试
      expect(true, isTrue);
    });
  });
}
''';
  }

  String _generateExampleFile(ScaffoldConfig config) {
    return '''
// ${config.templateName} 使用示例

void main() {
  print('${config.templateName} 模板示例');
  print('描述: ${config.description}');
  print('类型: ${config.templateType.displayName}');
}
''';
  }
}
