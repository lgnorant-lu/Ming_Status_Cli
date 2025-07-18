/*
---------------------------------------------------------------
File name:          template_scaffold.dart
Author:             lgnorant-lu
Date created:       2025/07/18
Last modified:      2025/07/18
Dart Version:       3.2+
Description:        清理后的模板脚手架生成器 (Clean Template Scaffold Generator)
---------------------------------------------------------------
Change History:
    2025/07/18: 完全重构 - 移除1300+行死代码，保留核心功能;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/code/index.dart'
    as code_gen;
import 'package:ming_status_cli/src/core/template_creator/generators/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/docs/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/l10n/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/templates/index.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;
import 'package:path/path.dart' as path;

/// 清理后的模板脚手架生成器
///
/// 移除了1300+行死代码，只保留核心的分层生成功能
class TemplateScaffold {
  /// 创建模板脚手架生成器实例
  TemplateScaffold();

  /// 生成模板脚手架
  ///
  /// 根据配置生成完整的模板项目结构
  Future<ScaffoldResult> generateScaffold(ScaffoldConfig config) async {
    try {
      cli_logger.Logger.info('🚀 开始生成模板脚手架: ${config.templateName}');

      final generatedFiles = <String>[];
      final warnings = <String>[];

      // 1. 创建目录结构
      await _createDirectoryStructure(config);
      cli_logger.Logger.info('📁 目录结构创建完成');

      // 2. 按复杂度分层生成文件
      cli_logger.Logger.info(
          '📊 复杂度: ${config.complexity.name}, 类型: ${config.templateType.name}');

      switch (config.complexity) {
        case TemplateComplexity.simple:
          final simpleFiles = await _generateSimpleFiles(config);
          generatedFiles.addAll(simpleFiles);
          cli_logger.Logger.info('🎯 Simple文件生成完成 (${simpleFiles.length}个文件)');

        case TemplateComplexity.medium:
          final mediumFiles = await _generateMediumFiles(config);
          generatedFiles.addAll(mediumFiles);
          cli_logger.Logger.info('🎯 Medium文件生成完成 (${mediumFiles.length}个文件)');

        case TemplateComplexity.complex:
          final complexFiles = await _generateComplexFiles(config);
          generatedFiles.addAll(complexFiles);
          cli_logger.Logger.info(
              '🎯 Complex文件生成完成 (${complexFiles.length}个文件)');

        case TemplateComplexity.enterprise:
          final enterpriseFiles = await _generateEnterpriseFiles(config);
          generatedFiles.addAll(enterpriseFiles);
          cli_logger.Logger.info(
              '🎯 Enterprise文件生成完成 (${enterpriseFiles.length}个文件)');
      }

      // 11. Git初始化
      if (config.enableGitInit) {
        await _initializeGit(config);
        cli_logger.Logger.info('📦 Git仓库初始化完成');
      }

      final templatePath = path.join(config.outputPath, config.templateName);

      cli_logger.Logger.success(
        '✅ 模板脚手架生成完成: ${config.templateName} '
        '(${generatedFiles.length}个文件)',
      );

      return ScaffoldResult.success(
        templatePath: templatePath,
        generatedFiles: generatedFiles,
        warnings: warnings,
      );
    } catch (e, stackTrace) {
      cli_logger.Logger.error('❌ 模板脚手架生成失败', error: e);
      cli_logger.Logger.debug('Stack trace: $stackTrace');
      return ScaffoldResult.failure(
        errors: ['脚手架生成异常: $e'],
      );
    }
  }

  /// 创建目录结构 - 按复杂度分层
  Future<void> _createDirectoryStructure(ScaffoldConfig config) async {
    final templatePath = path.join(config.outputPath, config.templateName);

    // 按复杂度创建不同的目录结构
    switch (config.complexity) {
      case TemplateComplexity.simple:
        await _createSimpleDirectories(templatePath, config);

      case TemplateComplexity.medium:
        await _createMediumDirectories(templatePath, config);

      case TemplateComplexity.complex:
        await _createComplexDirectories(templatePath, config);

      case TemplateComplexity.enterprise:
        await _createEnterpriseDirectories(templatePath, config);
    }
  }

  // ========== 重构后的分层生成方法 ==========

  /// 生成Simple复杂度文件 (10-15个文件)
  Future<List<String>> _generateSimpleFiles(ScaffoldConfig config) async {
    final generatedFiles = <String>[];

    // 1. 基础配置文件
    final pubspecContent = await _generatePubspecContent(config);
    await _writeFile(
      path.join(config.outputPath, config.templateName),
      'pubspec.yaml',
      pubspecContent,
    );
    generatedFiles.add('pubspec.yaml');

    // 2. 核心代码文件
    final coreFiles = await _generateCoreCodeFiles(config);
    generatedFiles.addAll(coreFiles);

    // 3. README文件
    final readmeContent = await _generateReadmeContent(config);
    await _writeFile(
      path.join(config.outputPath, config.templateName),
      'README.md',
      readmeContent,
    );
    generatedFiles.add('README.md');

    // 4. template.yaml元数据文件
    final templateYamlContent = await _generateTemplateYamlContent(config);
    await _writeFile(
      path.join(config.outputPath, config.templateName),
      'template.yaml',
      templateYamlContent,
    );
    generatedFiles.add('template.yaml');

    return generatedFiles;
  }

  /// 生成Medium复杂度文件 (20-25个文件)
  Future<List<String>> _generateMediumFiles(ScaffoldConfig config) async {
    final generatedFiles = <String>[];

    // 包含Simple的所有文件
    generatedFiles.addAll(await _generateSimpleFiles(config));

    // 添加Medium特有的文件
    // 1. 国际化文件
    final l10nFiles = await _generateBasicL10nFiles(config);
    generatedFiles.addAll(l10nFiles);

    // 2. 基础测试文件
    final testFiles = await _generateBasicTestFiles(config);
    generatedFiles.addAll(testFiles);

    // 3. 基础文档
    final docFiles = await _generateBasicDocFiles(config);
    generatedFiles.addAll(docFiles);

    return generatedFiles;
  }

  /// 生成Complex复杂度文件 (30-35个文件)
  Future<List<String>> _generateComplexFiles(ScaffoldConfig config) async {
    final generatedFiles = <String>[];

    // 包含Medium的所有文件
    generatedFiles.addAll(await _generateMediumFiles(config));

    // 添加Complex特有的文件
    // 1. 完整的配置文件
    final configFiles = await _generateAdvancedConfigFiles(config);
    generatedFiles.addAll(configFiles);

    // 2. 扩展的测试文件
    final testFiles = await _generateAdvancedTestFiles(config);
    generatedFiles.addAll(testFiles);

    // 3. 基础index文件
    final indexFiles = await _generateBasicIndexFiles(config);
    generatedFiles.addAll(indexFiles);

    return generatedFiles;
  }

  /// 生成Enterprise复杂度文件 (40-50个文件)
  Future<List<String>> _generateEnterpriseFiles(ScaffoldConfig config) async {
    final generatedFiles = <String>[];

    // 包含Complex的所有文件
    generatedFiles.addAll(await _generateComplexFiles(config));

    // 添加Enterprise特有的文件
    // 1. 模板文件系统
    final templateFiles = await _generateEnterpriseTemplateFiles(config);
    generatedFiles.addAll(templateFiles);

    // 2. 完整的index文件系统
    final indexFiles = await _generateEnterpriseIndexFiles(config);
    generatedFiles.addAll(indexFiles);

    // 3. 企业级配置
    final enterpriseConfigs = await _generateEnterpriseConfigFiles(config);
    generatedFiles.addAll(enterpriseConfigs);

    return generatedFiles;
  }

  // ========== 辅助生成方法 ==========

  /// 生成pubspec.yaml内容
  Future<String> _generatePubspecContent(ScaffoldConfig config) async {
    const pubspecGenerator = PubspecGenerator();
    return pubspecGenerator.generateContent(config);
  }

  /// 生成核心代码文件
  Future<List<String>> _generateCoreCodeFiles(ScaffoldConfig config) async {
    final files = <String>[];
    final templatePath = path.join(config.outputPath, config.templateName);

    // 生成基础的Model、Utils、Constants文件
    const modelGenerator = code_gen.ModelGenerator();
    final modelFile = await modelGenerator.generateFile(templatePath, config);
    files.add(modelFile);

    const utilsGenerator = code_gen.UtilsGenerator();
    final utilsFile = await utilsGenerator.generateFile(templatePath, config);
    files.add(utilsFile);

    const constantsGenerator = code_gen.ConstantsGenerator();
    final constantsFile =
        await constantsGenerator.generateFile(templatePath, config);
    files.add(constantsFile);

    // 生成主模块文件
    const moduleGenerator = ModuleDartGenerator();
    const exportGenerator = MainExportGenerator();
    await _generateLibFiles(config, moduleGenerator, exportGenerator);
    files.add('lib/${config.templateName}_module.dart');
    files.add('lib/${config.templateName}.dart');

    return files;
  }

  /// 生成README内容
  Future<String> _generateReadmeContent(ScaffoldConfig config) async {
    const readmeGenerator = ReadmeGenerator();
    return readmeGenerator.generateContent(config);
  }

  /// 生成template.yaml内容
  Future<String> _generateTemplateYamlContent(ScaffoldConfig config) async {
    final buffer = StringBuffer()
      ..writeln('name: ${config.templateName}')
      ..writeln('version: ${config.version}')
      ..writeln('description: ${config.description}')
      ..writeln('author: ${config.author}')
      ..writeln('type: ${config.templateType.toString().split('.').last}')
      ..writeln('platform: ${config.platform.toString().split('.').last}')
      ..writeln('framework: ${config.framework.toString().split('.').last}')
      ..writeln('complexity: ${config.complexity.toString().split('.').last}')
      ..writeln('maturity: ${config.maturity.toString().split('.').last}')
      ..writeln('tags: [${config.tags.map((tag) => '"$tag"').join(', ')}]')
      ..writeln('created_at: ${DateTime.now().toIso8601String()}')
      ..writeln()
      ..writeln('# 模板依赖')
      ..writeln('dependencies:');

    // 添加依赖
    if (config.dependencies.isNotEmpty) {
      for (final dep in config.dependencies) {
        buffer.writeln('  - $dep');
      }
    } else {
      buffer.writeln('  []');
    }

    buffer
      ..writeln()
      ..writeln('# 模板配置')
      ..writeln('configuration:')
      ..writeln('  include_tests: ${config.includeTests}')
      ..writeln('  include_documentation: ${config.includeDocumentation}')
      ..writeln('  include_examples: ${config.includeExamples}')
      ..writeln('  enable_git_init: ${config.enableGitInit}')
      ..writeln()
      ..writeln('# 生成信息')
      ..writeln('generation:')
      ..writeln('  tool: Ming Status CLI')
      ..writeln('  tool_version: 1.0.0')
      ..writeln('  generated_at: ${DateTime.now().toIso8601String()}');

    return buffer.toString();
  }
}

/// 生成基础国际化文件
Future<List<String>> _generateBasicL10nFiles(ScaffoldConfig config) async {
  final generatedFiles = <String>[];
  final projectPath = path.join(config.outputPath, config.templateName);
  final l10nPath = path.join(projectPath, 'l10n');

  // 只生成中英文
  final supportedLanguages = [
    {'code': 'en', 'country': null},
    {'code': 'zh', 'country': 'CN'},
  ];

  for (final language in supportedLanguages) {
    final arbGenerator = ArbGenerator(
      languageCode: language['code']!,
      countryCode: language['country'],
    );
    final arbContent = arbGenerator.generateContent(config);
    final actualFileName = 'app_${language['code']}.arb';
    await _writeFile(l10nPath, actualFileName, arbContent);
    generatedFiles.add('l10n/$actualFileName');
  }

  // 生成l10n.yaml配置
  const l10nConfigGenerator = L10nConfigGenerator();
  final l10nContent = l10nConfigGenerator.generateContent(config);
  await _writeFile(
    path.join(config.outputPath, config.templateName),
    'l10n.yaml',
    l10nContent,
  );
  generatedFiles.add('l10n.yaml');

  return generatedFiles;
}

/// 生成基础测试文件
Future<List<String>> _generateBasicTestFiles(ScaffoldConfig config) async {
  final generatedFiles = <String>[];
  final templatePath = path.join(config.outputPath, config.templateName);
  final testPath = path.join(templatePath, 'test');

  // 生成基础单元测试
  final unitTestContent = '''
import 'package:flutter_test/flutter_test.dart';
import 'package:${config.templateName}/${config.templateName}.dart';

void main() {
  group('${config.templateName} Tests', () {
    test('should create module instance', () {
      final module = ${_toPascalCase(config.templateName)}Module.instance;
      expect(module, isNotNull);
    });

    test('should have correct module name', () {
      final module = ${_toPascalCase(config.templateName)}Module.instance;
      expect(module.isInitialized, isFalse);
    });
  });
}
''';
  await _writeFile(
      testPath, '${config.templateName}_test.dart', unitTestContent);
  generatedFiles.add('test/${config.templateName}_test.dart');

  return generatedFiles;
}

/// 生成基础文档文件
Future<List<String>> _generateBasicDocFiles(ScaffoldConfig config) async {
  final generatedFiles = <String>[];
  final templatePath = path.join(config.outputPath, config.templateName);

  // 生成CHANGELOG.md
  final changelogContent = _generateChangelog(config);
  await _writeFile(templatePath, 'CHANGELOG.md', changelogContent);
  generatedFiles.add('CHANGELOG.md');

  return generatedFiles;
}

/// 生成高级配置文件
Future<List<String>> _generateAdvancedConfigFiles(ScaffoldConfig config) async {
  final generatedFiles = <String>[];
  final templatePath = path.join(config.outputPath, config.templateName);

  // 生成.gitignore
  const gitignoreGenerator = GitignoreGenerator();
  final gitignoreContent = gitignoreGenerator.generateContent(config);
  await _writeFile(templatePath, '.gitignore', gitignoreContent);
  generatedFiles.add('.gitignore');

  // 生成analysis_options.yaml
  const analysisGenerator = AnalysisOptionsGenerator();
  final analysisContent = analysisGenerator.generateContent(config);
  await _writeFile(templatePath, 'analysis_options.yaml', analysisContent);
  generatedFiles.add('analysis_options.yaml');

  // 生成build.yaml (Flutter项目)
  if (config.framework == TemplateFramework.flutter) {
    const buildGenerator = BuildConfigGenerator();
    final buildContent = buildGenerator.generateContent(config);
    await _writeFile(templatePath, 'build.yaml', buildContent);
    generatedFiles.add('build.yaml');
  }

  return generatedFiles;
}

/// 生成高级测试文件
Future<List<String>> _generateAdvancedTestFiles(ScaffoldConfig config) async {
  final generatedFiles = <String>[];
  final templatePath = path.join(config.outputPath, config.templateName);
  final testPath = path.join(templatePath, 'test');

  // 只生成一个简单的集成测试文件
  final integrationTestContent = '''
import 'package:flutter_test/flutter_test.dart';
import 'package:${config.templateName}/${config.templateName}.dart';

void main() {
  group('${_toPascalCase(config.templateName)} Integration Tests', () {
    test('should initialize module successfully', () {
      final module = ${_toPascalCase(config.templateName)}Module.instance;
      expect(module, isNotNull);
    });

    test('should handle basic operations', () {
      // Add integration test cases here
      expect(true, isTrue);
    });
  });
}
''';

  await _writeFile(
    path.join(testPath, 'integration'),
    '${config.templateName}_integration_test.dart',
    integrationTestContent,
  );
  generatedFiles
      .add('test/integration/${config.templateName}_integration_test.dart');

  return generatedFiles;
}

/// 生成基础index文件
Future<List<String>> _generateBasicIndexFiles(ScaffoldConfig config) async {
  final generatedFiles = <String>[];
  final libPath = path.join(config.outputPath, config.templateName, 'lib');

  // 只生成核心的index文件
  final coreIndexContent = '''
// 核心功能导出
// export 'core_functionality.dart';
''';
  await _writeFile(
      path.join(libPath, 'src', 'core'), 'index.dart', coreIndexContent);
  generatedFiles.add('lib/src/core/index.dart');

  final utilsIndexContent = '''
// 工具函数导出
export '${config.templateName}_utils.dart';
''';
  await _writeFile(
      path.join(libPath, 'src', 'utils'), 'index.dart', utilsIndexContent);
  generatedFiles.add('lib/src/utils/index.dart');

  return generatedFiles;
}

/// 生成企业级模板文件
Future<List<String>> _generateEnterpriseTemplateFiles(
    ScaffoldConfig config) async {
  final generatedFiles = <String>[];
  final templatePath =
      path.join(config.outputPath, config.templateName, 'templates');

  // 生成核心模板文件
  const mainGenerator = MainDartGenerator();
  final mainContent = mainGenerator.generateContent(config);
  await _writeFile(
      templatePath, mainGenerator.getOutputFileName(config), mainContent);
  generatedFiles.add('templates/${mainGenerator.getOutputFileName(config)}');

  const moduleGenerator = ModuleDartGenerator();
  final moduleContent = moduleGenerator.generateContent(config);
  await _writeFile(
      templatePath, moduleGenerator.getOutputFileName(config), moduleContent);
  generatedFiles.add('templates/${moduleGenerator.getOutputFileName(config)}');

  return generatedFiles;
}

/// 生成企业级index文件
Future<List<String>> _generateEnterpriseIndexFiles(
    ScaffoldConfig config) async {
  final generatedFiles = <String>[];

  // 使用现有的IndexFileGenerator，但只生成必要的文件
  final indexGenerator = IndexFileGenerator();
  final indexFiles = await indexGenerator.generateIndexFiles(config);
  generatedFiles.addAll(indexFiles);

  return generatedFiles;
}

/// 生成企业级配置文件
Future<List<String>> _generateEnterpriseConfigFiles(
    ScaffoldConfig config) async {
  final generatedFiles = <String>[];
  final templatePath = path.join(config.outputPath, config.templateName);

  if (config.framework == TemplateFramework.flutter) {
    // 生成melos.yaml
    const melosGenerator = MelosConfigGenerator();
    final melosContent = melosGenerator.generateContent(config);
    await _writeFile(templatePath, 'melos.yaml', melosContent);
    generatedFiles.add('melos.yaml');

    // 生成flutter_gen.yaml
    const flutterGenGenerator = FlutterGenConfigGenerator();
    final flutterGenContent = flutterGenGenerator.generateContent(config);
    await _writeFile(templatePath, 'flutter_gen.yaml', flutterGenContent);
    generatedFiles.add('flutter_gen.yaml');
  }

  return generatedFiles;
}

// ========== 分层目录创建方法 ==========

/// 创建Simple复杂度目录结构
Future<void> _createSimpleDirectories(
    String templatePath, ScaffoldConfig config) async {
  final directories = [
    // 基础目录
    'lib',
    'lib/src',
    'lib/src/core',
    'lib/src/models',
    'lib/src/utils',
    'lib/src/constants',
  ];

  for (final dir in directories) {
    final dirPath = path.join(templatePath, dir);
    await Directory(dirPath).create(recursive: true);
  }
}

/// 创建Medium复杂度目录结构
Future<void> _createMediumDirectories(
    String templatePath, ScaffoldConfig config) async {
  // 包含Simple的所有目录
  await _createSimpleDirectories(templatePath, config);

  final additionalDirectories = [
    // 国际化目录
    'l10n',

    // 基础测试目录
    'test',
    'test/unit',

    // 基础文档目录
    'docs',
  ];

  for (final dir in additionalDirectories) {
    final dirPath = path.join(templatePath, dir);
    await Directory(dirPath).create(recursive: true);
  }
}

/// 创建Complex复杂度目录结构
Future<void> _createComplexDirectories(
    String templatePath, ScaffoldConfig config) async {
  // 包含Medium的所有目录
  await _createMediumDirectories(templatePath, config);

  final additionalDirectories = [
    // 配置目录
    'config',

    // 扩展测试目录
    'test/integration',
    'test/mocks',

    // 扩展文档目录
    'docs/api',
    'docs/guides',

    // 资源目录
    'assets',
    'assets/images',
    'assets/icons',
  ];

  // 根据模板类型添加特定目录
  final typeSpecificDirectories =
      _getTypeSpecificDirectories(config.templateType);
  additionalDirectories.addAll(typeSpecificDirectories);

  for (final dir in additionalDirectories) {
    final dirPath = path.join(templatePath, dir);
    await Directory(dirPath).create(recursive: true);
  }
}

/// 创建Enterprise复杂度目录结构
Future<void> _createEnterpriseDirectories(
    String templatePath, ScaffoldConfig config) async {
  // 包含Complex的所有目录
  await _createComplexDirectories(templatePath, config);

  final additionalDirectories = [
    // 模板系统目录
    'templates',

    // 示例目录
    'example',
    'example/lib',
    'example/lib/src',

    // 完整文档目录
    'docs/architecture',
    'docs/deployment',
    'docs/tutorials',

    // 工具目录
    'tool',

    // 二进制目录
    'bin',
  ];

  for (final dir in additionalDirectories) {
    final dirPath = path.join(templatePath, dir);
    await Directory(dirPath).create(recursive: true);
  }
}

/// 获取模板类型特定目录
List<String> _getTypeSpecificDirectories(TemplateType templateType) {
  switch (templateType) {
    case TemplateType.ui:
      return [
        'lib/src/components',
        'lib/src/widgets',
        'lib/src/themes',
      ];
    case TemplateType.service:
      return [
        'lib/src/services',
        'lib/src/api',
        'lib/src/repositories',
      ];
    case TemplateType.data:
      return [
        'lib/src/entities',
        'lib/src/datasources',
        'lib/src/repositories',
      ];
    case TemplateType.full:
      return [
        'lib/src/ui',
        'lib/src/services',
        'lib/src/api',
        'lib/src/repositories',
      ];
    default:
      return [];
  }
}

// ========== 核心辅助方法 ==========

/// 生成实际的lib文件
Future<void> _generateLibFiles(
  ScaffoldConfig config,
  ModuleDartGenerator moduleGenerator,
  MainExportGenerator exportGenerator,
) async {
  final libPath = path.join(config.outputPath, config.templateName, 'lib');

  // 生成实际的模块文件
  final moduleContent = moduleGenerator.generateContent(config);
  // 移除.template后缀，生成实际的Dart文件
  final moduleFileName = '${config.templateName}_module.dart';
  await _writeFile(libPath, moduleFileName, moduleContent);

  // 生成实际的主导出文件
  final exportContent = exportGenerator.generateContent(config);
  final exportFileName = '${config.templateName}.dart';
  await _writeFile(libPath, exportFileName, exportContent);
}

/// 写入文件
Future<void> _writeFile(String dirPath, String fileName, String content) async {
  final directory = Directory(dirPath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  final file = File(path.join(dirPath, fileName));
  await file.writeAsString(content);
}

/// 初始化Git仓库
Future<void> _initializeGit(ScaffoldConfig config) async {
  final templatePath = path.join(config.outputPath, config.templateName);

  try {
    // 初始化Git仓库
    final result = await Process.run(
      'git',
      ['init'],
      workingDirectory: templatePath,
    );

    if (result.exitCode != 0) {
      cli_logger.Logger.warning('Git初始化失败: ${result.stderr}');
    }
  } catch (e) {
    cli_logger.Logger.warning('Git初始化异常: $e');
  }
}

/// 转换为PascalCase
String _toPascalCase(String input) {
  if (input.isEmpty) return input;

  return input
      .split(RegExp(r'[_\-\s]+'))
      .map((word) => word.isEmpty
          ? ''
          : word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join('');
}

/// 生成CHANGELOG内容
String _generateChangelog(ScaffoldConfig config) {
  return '''
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [${config.version}] - ${DateTime.now().toIso8601String().split('T')[0]}

### Added
- Initial project setup
- Basic module structure
- Core functionality implementation

### Changed
- N/A

### Deprecated
- N/A

### Removed
- N/A

### Fixed
- N/A

### Security
- N/A
''';
}
