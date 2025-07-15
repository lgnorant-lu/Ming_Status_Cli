/*
---------------------------------------------------------------
File name:          template_scaffold_v2.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        重构后的模板脚手架生成器 (Refactored Template Scaffold Generator)
---------------------------------------------------------------
Change History:
    2025/07/12: Complete refactoring - 使用模块化生成器架构;
---------------------------------------------------------------
TODO:
    - [ ] 添加进度回调支持
    - [ ] 支持增量生成
    - [ ] 添加生成预览功能
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/assets/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/code/index.dart'
    as code_gen;
import 'package:ming_status_cli/src/core/template_creator/generators/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/docs/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/flutter/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/l10n/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/templates/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/tests/index.dart';
import 'package:ming_status_cli/src/core/template_creator/structure/index.dart';
import 'package:ming_status_cli/src/core/template_system/template_metadata.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;
import 'package:path/path.dart' as path;

/// 企业级模板脚手架生成器
///
/// 使用模块化架构，每个功能都由专门的生成器负责
///
/// 重构说明：
/// - 原始巨型文件已归档为 template_scaffold_legacy.txt
/// - 新架构使用39个专业模块，提供更好的可维护性和扩展性
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

      // 2. 生成配置文件
      final configFiles = await _generateConfigFiles(config);
      generatedFiles.addAll(configFiles);
      cli_logger.Logger.info('⚙️ 配置文件生成完成 (${configFiles.length}个文件)');

      // 3. 生成模板文件
      final templateFiles = await _generateTemplateFiles(config);
      generatedFiles.addAll(templateFiles);
      cli_logger.Logger.info('📄 模板文件生成完成 (${templateFiles.length}个文件)');

      // 4. 生成实际代码文件
      final codeFiles = await _generateCodeFiles(config);
      generatedFiles.addAll(codeFiles);
      cli_logger.Logger.info('💻 代码文件生成完成 (${codeFiles.length}个文件)');

      // 5. 生成Flutter特定文件
      if (config.framework == TemplateFramework.flutter) {
        final flutterFiles = await _generateFlutterFiles(config);
        generatedFiles.addAll(flutterFiles);
        cli_logger.Logger.info('🎯 Flutter文件生成完成 (${flutterFiles.length}个文件)');
      }

      // 5. 生成国际化文件
      final l10nFiles = await _generateL10nFiles(config);
      generatedFiles.addAll(l10nFiles);
      cli_logger.Logger.info('🌍 国际化文件生成完成 (${l10nFiles.length}个文件)');

      // 6. 生成资源文件
      final assetFiles = await _generateAssetFiles(config);
      generatedFiles.addAll(assetFiles);
      cli_logger.Logger.info('🎨 资源文件生成完成 (${assetFiles.length}个文件)');

      // 7. 生成文档
      if (config.includeDocumentation) {
        final docFiles = await _generateDocumentationFiles(config);
        generatedFiles.addAll(docFiles);
        cli_logger.Logger.info('📚 文档文件生成完成 (${docFiles.length}个文件)');
      }

      // 8. 生成测试
      if (config.includeTests) {
        final testFiles = await _generateTestFiles(config);
        generatedFiles.addAll(testFiles);
        cli_logger.Logger.info('🧪 测试文件生成完成 (${testFiles.length}个文件)');
      }

      // 9. 生成实际示例文件
      final exampleFiles = await _generateExampleFiles(config);
      generatedFiles.addAll(exampleFiles);
      cli_logger.Logger.info('📝 示例文件生成完成 (${exampleFiles.length}个文件)');

      // 10. 生成元数据文件
      await _generateMetadataFile(config);
      generatedFiles.add('template.yaml');
      cli_logger.Logger.info('📋 元数据文件生成完成');

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

  /// 创建目录结构
  Future<void> _createDirectoryStructure(ScaffoldConfig config) async {
    final structureGenerator = _getStructureCreator(config);
    final templatePath = path.join(config.outputPath, config.templateName);
    await structureGenerator.createDirectories(templatePath, config);
  }

  /// 获取结构创建器
  DirectoryCreator _getStructureCreator(ScaffoldConfig config) {
    switch (config.framework) {
      case TemplateFramework.flutter:
        return const FlutterStructureCreator();
      case TemplateFramework.dart:
      case TemplateFramework.react:
      case TemplateFramework.vue:
      case TemplateFramework.angular:
      case TemplateFramework.nodejs:
      case TemplateFramework.springBoot:
      case TemplateFramework.agnostic:
        return const DartStructureCreator();
    }
  }

  /// 生成配置文件
  Future<List<String>> _generateConfigFiles(ScaffoldConfig config) async {
    final generatedFiles = <String>[];
    final templatePath = path.join(config.outputPath, config.templateName);

    // 生成pubspec.yaml
    const pubspecGenerator = PubspecGenerator();
    final pubspecContent = pubspecGenerator.generateContent(config);
    await _writeFile(templatePath, 'pubspec.yaml', pubspecContent);
    generatedFiles.add('pubspec.yaml');

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

    // 根据框架和复杂度生成其他配置文件
    if (config.framework == TemplateFramework.flutter) {
      // 生成l10n.yaml
      const l10nConfigGenerator = L10nConfigGenerator();
      final l10nContent = l10nConfigGenerator.generateContent(config);
      await _writeFile(templatePath, 'l10n.yaml', l10nContent);
      generatedFiles.add('l10n.yaml');

      // 生成build.yaml
      if (config.complexity != TemplateComplexity.simple) {
        const buildGenerator = BuildConfigGenerator();
        final buildContent = buildGenerator.generateContent(config);
        await _writeFile(templatePath, 'build.yaml', buildContent);
        generatedFiles.add('build.yaml');
      }

      // 生成flutter_gen.yaml
      const flutterGenGenerator = FlutterGenConfigGenerator();
      final flutterGenContent = flutterGenGenerator.generateContent(config);
      await _writeFile(templatePath, 'flutter_gen.yaml', flutterGenContent);
      generatedFiles.add('flutter_gen.yaml');

      // 企业级配置文件
      if (config.complexity == TemplateComplexity.enterprise) {
        // 生成melos.yaml
        const melosGenerator = MelosConfigGenerator();
        final melosContent = melosGenerator.generateContent(config);
        await _writeFile(templatePath, 'melos.yaml', melosContent);
        generatedFiles.add('melos.yaml');

        // 生成shorebird.yaml
        const shorebirdGenerator = ShorebirdConfigGenerator();
        final shorebirdContent = shorebirdGenerator.generateContent(config);
        await _writeFile(templatePath, 'shorebird.yaml', shorebirdContent);
        generatedFiles.add('shorebird.yaml');

        // 生成firebase.json
        const firebaseGenerator = FirebaseConfigGenerator();
        final firebaseContent = firebaseGenerator.generateContent(config);
        await _writeFile(templatePath, 'firebase.json', firebaseContent);
        generatedFiles.add('firebase.json');
      }
    }

    return generatedFiles;
  }

  /// 生成模板文件
  Future<List<String>> _generateTemplateFiles(ScaffoldConfig config) async {
    final generatedFiles = <String>[];
    final templatePath =
        path.join(config.outputPath, config.templateName, 'templates');

    // 生成main.dart模板
    const mainGenerator = MainDartGenerator();
    final mainContent = mainGenerator.generateContent(config);
    await _writeFile(
      templatePath,
      mainGenerator.getOutputFileName(config),
      mainContent,
    );
    generatedFiles.add('templates/${mainGenerator.getOutputFileName(config)}');

    // 生成app.dart模板
    if (config.framework == TemplateFramework.flutter) {
      const appGenerator = AppDartGenerator();
      final appContent = appGenerator.generateContent(config);
      await _writeFile(
        templatePath,
        appGenerator.getOutputFileName(config),
        appContent,
      );
      generatedFiles.add('templates/${appGenerator.getOutputFileName(config)}');
    }

    // 生成模块定义文件
    const moduleGenerator = ModuleDartGenerator();
    final moduleContent = moduleGenerator.generateContent(config);
    await _writeFile(
      templatePath,
      moduleGenerator.getOutputFileName(config),
      moduleContent,
    );
    generatedFiles
        .add('templates/${moduleGenerator.getOutputFileName(config)}');

    // 生成主导出文件
    const exportGenerator = MainExportGenerator();
    final exportContent = exportGenerator.generateContent(config);
    await _writeFile(
      templatePath,
      exportGenerator.getOutputFileName(config),
      exportContent,
    );
    generatedFiles
        .add('templates/${exportGenerator.getOutputFileName(config)}');

    // 同时生成实际的lib文件供验证使用
    await _generateLibFiles(config, moduleGenerator, exportGenerator);
    generatedFiles.add('lib/${config.templateName}_module.dart');
    generatedFiles.add('lib/${config.templateName}.dart');

    // 生成必要的index.dart文件
    await _generateIndexFiles(config);
    generatedFiles.addAll(await _getGeneratedIndexFiles(config));

    return generatedFiles;
  }

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

  /// 生成Flutter特定文件
  Future<List<String>> _generateFlutterFiles(ScaffoldConfig config) async {
    final generatedFiles = <String>[];
    final templatePath =
        path.join(config.outputPath, config.templateName, 'templates');

    // 生成主题文件
    const themeGenerator = ThemeGenerator();
    final themeContent = themeGenerator.generateContent(config);
    await _writeFile(
      templatePath,
      themeGenerator.getOutputFileName(config),
      themeContent,
    );
    generatedFiles.add('templates/${themeGenerator.getOutputFileName(config)}');

    // 生成路由文件
    const routerGenerator = RouterGenerator();
    final routerContent = routerGenerator.generateContent(config);
    await _writeFile(
      templatePath,
      routerGenerator.getOutputFileName(config),
      routerContent,
    );
    generatedFiles
        .add('templates/${routerGenerator.getOutputFileName(config)}');

    // 生成Provider文件
    if (config.complexity != TemplateComplexity.simple) {
      const providerGenerator = ProviderGenerator();
      final providerContent = providerGenerator.generateContent(config);
      await _writeFile(
        templatePath,
        providerGenerator.getOutputFileName(config),
        providerContent,
      );
      generatedFiles
          .add('templates/${providerGenerator.getOutputFileName(config)}');
    }

    return generatedFiles;
  }

  /// 生成国际化文件
  Future<List<String>> _generateL10nFiles(ScaffoldConfig config) async {
    final generatedFiles = <String>[];
    final projectPath = path.join(config.outputPath, config.templateName);
    final templatePath = path.join(projectPath, 'templates');
    final l10nPath = path.join(projectPath, 'l10n');

    // 支持的语言列表
    final supportedLanguages = _getSupportedLanguages(config);

    for (final language in supportedLanguages) {
      final arbGenerator = ArbGenerator(
        languageCode: language['code']!,
        countryCode: language['country'],
      );
      final arbContent = arbGenerator.generateContent(config);

      // 生成模板文件到 templates/ 目录
      await _writeFile(
        templatePath,
        arbGenerator.getOutputFileName(config),
        arbContent,
      );
      generatedFiles.add('templates/${arbGenerator.getOutputFileName(config)}');

      // 生成实际的 ARB 文件到 l10n/ 目录
      final actualFileName =
          arbGenerator.getOutputFileName(config).replaceAll('.template', '');
      await _writeFile(
        l10nPath,
        actualFileName,
        arbContent,
      );
      generatedFiles.add('l10n/$actualFileName');
    }

    return generatedFiles;
  }

  /// 生成资源文件
  Future<List<String>> _generateAssetFiles(ScaffoldConfig config) async {
    final generatedFiles = <String>[];
    final templatePath =
        path.join(config.outputPath, config.templateName, 'templates');

    // 生成各种资源文件
    final assetTypes = [
      AssetType.images,
      AssetType.icons,
      AssetType.animations,
    ];

    // 根据复杂度添加额外的资源类型
    if (config.complexity != TemplateComplexity.simple) {
      assetTypes.addAll([
        AssetType.fonts,
        AssetType.colors,
      ]);
    }

    for (final assetType in assetTypes) {
      final assetGenerator = AssetGenerator(assetType: assetType);
      final assetContent = assetGenerator.generateContent(config);
      await _writeFile(
        templatePath,
        assetGenerator.getOutputFileName(config),
        assetContent,
      );
      generatedFiles
          .add('templates/${assetGenerator.getOutputFileName(config)}');
    }

    return generatedFiles;
  }

  /// 生成文档文件
  Future<List<String>> _generateDocumentationFiles(
    ScaffoldConfig config,
  ) async {
    final generatedFiles = <String>[];
    final templatePath = path.join(config.outputPath, config.templateName);

    // 生成README.md
    const readmeGenerator = ReadmeGenerator();
    final readmeContent = readmeGenerator.generateContent(config);
    await _writeFile(templatePath, 'README.md', readmeContent);
    generatedFiles.add('README.md');

    // 生成CHANGELOG.md
    final changelogContent = _generateChangelog(config);
    await _writeFile(templatePath, 'CHANGELOG.md', changelogContent);
    generatedFiles.add('CHANGELOG.md');

    return generatedFiles;
  }

  /// 生成测试文件
  Future<List<String>> _generateTestFiles(ScaffoldConfig config) async {
    final generatedFiles = <String>[];
    final templatePath =
        path.join(config.outputPath, config.templateName, 'templates');

    // 生成不同类型的测试
    final testTypes = [
      TestType.unit,
      if (config.framework == TemplateFramework.flutter) ...[
        TestType.widget,
        TestType.integration,
        TestType.golden,
      ],
      TestType.performance,
    ];

    for (final testType in testTypes) {
      final testGenerator = TestGenerator(testType: testType);
      final testContent = testGenerator.generateContent(config);
      await _writeFile(
        templatePath,
        testGenerator.getOutputFileName(config),
        testContent,
      );
      generatedFiles
          .add('templates/${testGenerator.getOutputFileName(config)}');
    }

    return generatedFiles;
  }

  /// 生成元数据文件
  Future<void> _generateMetadataFile(ScaffoldConfig config) async {
    final templatePath = path.join(config.outputPath, config.templateName);

    final metadata = TemplateMetadata(
      id: _generateTemplateId(config.templateName),
      name: config.templateName,
      version: config.version,
      author: config.author,
      description: config.description,
      type: config.templateType,
      subType: config.subType,
      tags: config.tags,
      keywords: _generateKeywords(config),
      complexity: config.complexity,
      maturity: config.maturity,
      platform: config.platform,
      framework: config.framework,
      dependencies: config.dependencies
          .map((dep) => TemplateDependency(name: dep, version: '^1.0.0'))
          .toList(),
      category: _generateCategory(config),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final metadataContent = _generateMetadataYaml(metadata);
    await _writeFile(templatePath, 'template.yaml', metadataContent);
  }

  /// 初始化Git仓库
  Future<void> _initializeGit(ScaffoldConfig config) async {
    final templatePath = path.join(config.outputPath, config.templateName);

    final result = await Process.run(
      'git',
      ['init'],
      workingDirectory: templatePath,
    );

    if (result.exitCode != 0) {
      cli_logger.Logger.warning('Git初始化失败: ${result.stderr}');
    }
  }

  /// 写入文件
  Future<void> _writeFile(
    String basePath,
    String fileName,
    String content,
  ) async {
    final file = File(path.join(basePath, fileName));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  /// 获取支持的语言列表
  List<Map<String, String?>> _getSupportedLanguages(ScaffoldConfig config) {
    switch (config.complexity) {
      case TemplateComplexity.simple:
        return [
          {'code': 'en', 'country': null},
          {'code': 'zh', 'country': null},
        ];
      case TemplateComplexity.medium:
        return [
          {'code': 'en', 'country': null},
          {'code': 'zh', 'country': null},
          {'code': 'ja', 'country': null},
          {'code': 'ko', 'country': null},
        ];
      case TemplateComplexity.complex:
      case TemplateComplexity.enterprise:
        return [
          {'code': 'en', 'country': null},
          {'code': 'zh', 'country': null},
          {'code': 'ja', 'country': null},
          {'code': 'ko', 'country': null},
          {'code': 'es', 'country': null},
          {'code': 'fr', 'country': null},
          {'code': 'de', 'country': null},
          {'code': 'ru', 'country': null},
        ];
    }
  }

  /// 生成模板ID
  String _generateTemplateId(String templateName) {
    return templateName.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '_');
  }

  /// 生成关键词
  List<String> _generateKeywords(ScaffoldConfig config) {
    final keywords = <String>[];

    // 基于框架添加关键词
    keywords.add(config.framework.name);

    // 基于平台添加关键词
    keywords.add(config.platform.name);

    // 基于类型添加关键词
    keywords.add(config.templateType.name);

    // 基于复杂度添加关键词
    keywords.add(config.complexity.name);

    // 添加通用关键词
    if (config.framework == TemplateFramework.flutter) {
      keywords.addAll(['flutter', 'dart', 'mobile', 'app']);
    } else if (config.framework == TemplateFramework.dart) {
      keywords.addAll(['dart', 'server', 'cli']);
    }

    // 合并用户提供的标签
    keywords.addAll(config.tags);

    // 去重并返回
    return keywords.toSet().toList();
  }

  /// 生成分类
  String _generateCategory(ScaffoldConfig config) {
    // 基于模板类型和框架确定分类
    if (config.templateType == TemplateType.full) {
      return 'application';
    } else if (config.templateType == TemplateType.ui) {
      return 'component';
    } else if (config.templateType == TemplateType.service) {
      return 'service';
    } else if (config.templateType == TemplateType.data) {
      return 'data';
    } else if (config.templateType == TemplateType.micro) {
      return 'microservice';
    } else if (config.templateType == TemplateType.plugin) {
      return 'plugin';
    } else if (config.templateType == TemplateType.infrastructure) {
      return 'infrastructure';
    }
    return 'basic';
  }

  /// 生成元数据YAML
  String _generateMetadataYaml(TemplateMetadata metadata) {
    final buffer = StringBuffer();

    // 基础信息
    buffer.writeln('id: ${metadata.id}');
    buffer.writeln('name: ${metadata.name}');
    buffer.writeln('version: ${metadata.version}');
    buffer.writeln('description: ${metadata.description}');
    buffer.writeln('author: ${metadata.author}');

    // 分类信息
    buffer.writeln('type: ${metadata.type.name}');
    if (metadata.subType != null) {
      buffer.writeln('subType: ${metadata.subType!.name}');
    }
    buffer.writeln('platform: ${metadata.platform.name}');
    buffer.writeln('framework: ${metadata.framework.name}');
    buffer.writeln('complexity: ${metadata.complexity.name}');
    buffer.writeln('maturity: ${metadata.maturity.name}');

    // 标签和关键词
    buffer.writeln('tags: ${_formatYamlList(metadata.tags)}');
    buffer.writeln('keywords: ${_formatYamlList(metadata.keywords)}');

    // 依赖信息
    if (metadata.dependencies.isNotEmpty) {
      buffer.writeln('dependencies:');
      for (final dep in metadata.dependencies) {
        buffer.writeln('  - name: ${dep.name}');
        buffer.writeln('    version: ${dep.version}');
        if (dep.type != DependencyType.required) {
          buffer.writeln('    type: ${dep.type.name}');
        }
        if (dep.description != null) {
          buffer.writeln('    description: ${dep.description}');
        }
      }
    } else {
      buffer.writeln('dependencies: []');
    }

    // 分类
    buffer.writeln('category: ${metadata.category ?? 'basic'}');

    // 时间戳（ISO 8601格式）
    buffer.writeln(
      'createdAt: "${metadata.createdAt.toUtc().toIso8601String()}"',
    );
    buffer.writeln(
      'updatedAt: "${metadata.updatedAt.toUtc().toIso8601String()}"',
    );

    // 参数（如果有的话）
    buffer.writeln('parameters: []');

    return buffer.toString();
  }

  /// 格式化YAML列表
  String _formatYamlList(List<String> items) {
    if (items.isEmpty) return '[]';
    if (items.length == 1) return '[${items.first}]';
    return '[${items.join(', ')}]';
  }

  /// 生成实际示例文件
  Future<List<String>> _generateExampleFiles(ScaffoldConfig config) async {
    final generatedFiles = <String>[];
    final templatePath = path.join(config.outputPath, config.templateName);

    // 生成实际的assets示例文件
    await _generateActualAssetFiles(templatePath, config, generatedFiles);

    // 生成实际的test示例文件
    if (config.includeTests) {
      await _generateActualTestFiles(templatePath, config, generatedFiles);
    }

    // 生成实际的src示例文件
    await _generateActualSourceFiles(templatePath, config, generatedFiles);

    return generatedFiles;
  }

  /// 生成实际的assets文件
  Future<void> _generateActualAssetFiles(
    String templatePath,
    ScaffoldConfig config,
    List<String> generatedFiles,
  ) async {
    // 创建assets目录结构
    final assetsPath = path.join(templatePath, 'assets');
    await Directory(path.join(assetsPath, 'images')).create(recursive: true);
    await Directory(path.join(assetsPath, 'icons')).create(recursive: true);

    // 根据复杂度创建额外的资源目录
    if (config.complexity != TemplateComplexity.simple) {
      await Directory(path.join(assetsPath, 'fonts')).create(recursive: true);
      await Directory(path.join(assetsPath, 'colors')).create(recursive: true);
    }

    // 生成示例图片占位符
    const placeholderImage = '''
<!-- 这是一个示例图片占位符 -->
<!-- 在实际使用时，请替换为真实的图片文件 -->
<!-- 建议的图片格式: PNG, JPG, WebP -->
<!-- 建议的图片尺寸: 根据用途确定 -->
''';
    await _writeFile(assetsPath, 'images/placeholder.md', placeholderImage);
    generatedFiles.add('assets/images/placeholder.md');

    // 生成示例图标占位符
    const placeholderIcon = '''
<!-- 这是一个示例图标占位符 -->
<!-- 在实际使用时，请替换为真实的图标文件 -->
<!-- 建议的图标格式: SVG, PNG -->
<!-- 建议的图标尺寸: 24x24, 48x48, 96x96 -->
''';
    await _writeFile(assetsPath, 'icons/placeholder.md', placeholderIcon);
    generatedFiles.add('assets/icons/placeholder.md');
  }

  /// 生成实际的测试文件
  Future<void> _generateActualTestFiles(
    String templatePath,
    ScaffoldConfig config,
    List<String> generatedFiles,
  ) async {
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
      testPath,
      '${config.templateName}_test.dart',
      unitTestContent,
    );
    generatedFiles.add('test/${config.templateName}_test.dart');
  }

  /// 生成实际的源代码文件
  Future<void> _generateActualSourceFiles(
    String templatePath,
    ScaffoldConfig config,
    List<String> generatedFiles,
  ) async {
    // 注意：不再在这里生成服务文件，因为ServiceGenerator已经会生成到正确的位置
    // 避免重复生成服务文件

    // 如果需要生成其他特殊的源代码文件，可以在这里添加
    // 但要确保不与现有的生成器重复
  }

  /// 转换为PascalCase
  String _toPascalCase(String input) {
    return input
        .split('_')
        .map(
          (word) =>
              word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
        )
        .join();
  }

  /// 生成CHANGELOG
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

### Technical Details
- 模板类型: ${config.templateType.displayName}
- 作者: ${config.author}
- 生成时间: ${DateTime.now().toIso8601String()}
''';
  }

  /// 生成必要的index.dart文件
  Future<void> _generateIndexFiles(ScaffoldConfig config) async {
    final indexGenerator = IndexFileGenerator();
    await indexGenerator.generateIndexFiles(config);
  }

  /// 获取生成的index.dart文件列表
  Future<List<String>> _getGeneratedIndexFiles(ScaffoldConfig config) async {
    final indexGenerator = IndexFileGenerator();
    return indexGenerator.generateIndexFiles(config);
  }

  /// 生成实际代码文件
  Future<List<String>> _generateCodeFiles(ScaffoldConfig config) async {
    final files = <String>[];
    final templatePath = path.join(config.outputPath, config.templateName);

    // 根据模板类型生成不同的代码文件
    switch (config.templateType) {
      case TemplateType.ui:
        // UI模板只生成UI相关文件
        files.addAll(await _generateUICodeFiles(templatePath, config));
      case TemplateType.service:
        // Service模板生成服务相关文件
        files.addAll(await _generateServiceCodeFiles(templatePath, config));
      case TemplateType.data:
        // Data模板生成数据相关文件
        files.addAll(await _generateDataCodeFiles(templatePath, config));
      case TemplateType.full:
        // Full模板生成所有文件
        files.addAll(await _generateFullCodeFiles(templatePath, config));
      case TemplateType.basic:
        // Basic模板只生成最基础的文件
        files.addAll(await _generateBasicCodeFiles(templatePath, config));
      case TemplateType.system:
        // System模板生成系统相关文件
        files.addAll(await _generateSystemCodeFiles(templatePath, config));
      case TemplateType.micro:
        files.addAll(await _generateMicroCodeFiles(templatePath, config));
      case TemplateType.plugin:
        files.addAll(await _generatePluginCodeFiles(templatePath, config));
      case TemplateType.infrastructure:
        files.addAll(
            await _generateInfrastructureCodeFiles(templatePath, config));
    }

    // 生成测试文件
    if (config.includeTests) {
      final testFiles = await _generateEnhancedTestFiles(templatePath, config);
      files.addAll(testFiles);
    }

    // 生成Flutter UI组件（仅Flutter项目且需要UI组件的模板类型）
    if (config.framework == TemplateFramework.flutter &&
        _shouldGenerateUIComponents(config.templateType)) {
      final uiFiles = await _generateUiComponents(templatePath, config);
      files.addAll(uiFiles);
    }

    return files;
  }

  /// 生成Micro模板的代码文件
  Future<List<String>> _generateMicroCodeFiles(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // Micro模板主要生成微服务相关文件
    const modelGenerator = code_gen.ModelGenerator();
    final modelFile = await modelGenerator.generateFile(templatePath, config);
    files.add(modelFile);

    // 根据复杂度生成Provider文件（Medium及以上）
    if (config.complexity != TemplateComplexity.simple) {
      const providerGenerator = code_gen.ProviderGenerator();
      final providerFile =
          await providerGenerator.generateFile(templatePath, config);
      files.add(providerFile);

      // 生成Service文件（Medium及以上）
      const serviceGenerator = code_gen.ServiceGenerator();
      final serviceFile =
          await serviceGenerator.generateFile(templatePath, config);
      files.add(serviceFile);

      // 生成Repository文件（Complex及以上）
      if (config.complexity != TemplateComplexity.medium) {
        const repositoryGenerator = code_gen.RepositoryGenerator();
        final repositoryFile =
            await repositoryGenerator.generateFile(templatePath, config);
        files.add(repositoryFile);
      }
    }

    // 生成Utils文件
    const utilsGenerator = code_gen.UtilsGenerator();
    final utilsFile = await utilsGenerator.generateFile(templatePath, config);
    files.add(utilsFile);

    // 生成Constants文件
    const constantsGenerator = code_gen.ConstantsGenerator();
    final constantsFile =
        await constantsGenerator.generateFile(templatePath, config);
    files.add(constantsFile);

    // 生成跨平台支持文件（所有复杂度都需要）
    const crossPlatformGenerator = code_gen.CrossPlatformGenerator();
    final crossPlatformFile =
        await crossPlatformGenerator.generateFile(templatePath, config);
    files.add(crossPlatformFile);

    // 生成平台常量文件
    const platformConstantsGenerator = code_gen.PlatformConstantsGenerator();
    final platformConstantsFile =
        await platformConstantsGenerator.generateFile(templatePath, config);
    files.add(platformConstantsFile);

    // 生成跨平台模块索引文件
    const crossPlatformIndexGenerator = code_gen.CrossPlatformIndexGenerator();
    final crossPlatformIndexFile =
        await crossPlatformIndexGenerator.generateFile(templatePath, config);
    files.add(crossPlatformIndexFile);

    // 生成Integration文件（仅enterprise复杂度）
    if (config.complexity == TemplateComplexity.enterprise) {
      const integrationGenerator = code_gen.IntegrationGenerator();
      final integrationFile =
          await integrationGenerator.generateFile(templatePath, config);
      files.add(integrationFile);
    }

    return files;
  }

  /// 生成Plugin模板的代码文件
  Future<List<String>> _generatePluginCodeFiles(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // Plugin模板主要生成插件相关文件
    const modelGenerator = code_gen.ModelGenerator();
    final modelFile = await modelGenerator.generateFile(templatePath, config);
    files.add(modelFile);

    // 根据复杂度生成Provider文件（Medium及以上）
    if (config.complexity != TemplateComplexity.simple) {
      const providerGenerator = code_gen.ProviderGenerator();
      final providerFile =
          await providerGenerator.generateFile(templatePath, config);
      files.add(providerFile);

      // 生成Service文件（Medium及以上）
      const serviceGenerator = code_gen.ServiceGenerator();
      final serviceFile =
          await serviceGenerator.generateFile(templatePath, config);
      files.add(serviceFile);

      // 生成Repository文件（Complex及以上）
      if (config.complexity != TemplateComplexity.medium) {
        const repositoryGenerator = code_gen.RepositoryGenerator();
        final repositoryFile =
            await repositoryGenerator.generateFile(templatePath, config);
        files.add(repositoryFile);
      }
    }

    // 生成Utils文件
    const utilsGenerator = code_gen.UtilsGenerator();
    final utilsFile = await utilsGenerator.generateFile(templatePath, config);
    files.add(utilsFile);

    // 生成Constants文件
    const constantsGenerator = code_gen.ConstantsGenerator();
    final constantsFile =
        await constantsGenerator.generateFile(templatePath, config);
    files.add(constantsFile);

    // 生成跨平台支持文件（所有复杂度都需要）
    const crossPlatformGenerator = code_gen.CrossPlatformGenerator();
    final crossPlatformFile =
        await crossPlatformGenerator.generateFile(templatePath, config);
    files.add(crossPlatformFile);

    // 生成平台常量文件
    const platformConstantsGenerator = code_gen.PlatformConstantsGenerator();
    final platformConstantsFile =
        await platformConstantsGenerator.generateFile(templatePath, config);
    files.add(platformConstantsFile);

    // 生成跨平台模块索引文件
    const crossPlatformIndexGenerator = code_gen.CrossPlatformIndexGenerator();
    final crossPlatformIndexFile =
        await crossPlatformIndexGenerator.generateFile(templatePath, config);
    files.add(crossPlatformIndexFile);

    // 生成Integration文件（仅enterprise复杂度）
    if (config.complexity == TemplateComplexity.enterprise) {
      const integrationGenerator = code_gen.IntegrationGenerator();
      final integrationFile =
          await integrationGenerator.generateFile(templatePath, config);
      files.add(integrationFile);
    }

    return files;
  }

  /// 生成Infrastructure模板的代码文件
  Future<List<String>> _generateInfrastructureCodeFiles(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // Infrastructure模板主要生成基础设施相关文件
    const modelGenerator = code_gen.ModelGenerator();
    final modelFile = await modelGenerator.generateFile(templatePath, config);
    files.add(modelFile);

    // 根据复杂度生成Provider文件（Medium及以上）
    if (config.complexity != TemplateComplexity.simple) {
      const providerGenerator = code_gen.ProviderGenerator();
      final providerFile =
          await providerGenerator.generateFile(templatePath, config);
      files.add(providerFile);

      // 生成Service文件（Medium及以上）
      const serviceGenerator = code_gen.ServiceGenerator();
      final serviceFile =
          await serviceGenerator.generateFile(templatePath, config);
      files.add(serviceFile);

      // 生成Repository文件（Complex及以上）
      if (config.complexity != TemplateComplexity.medium) {
        const repositoryGenerator = code_gen.RepositoryGenerator();
        final repositoryFile =
            await repositoryGenerator.generateFile(templatePath, config);
        files.add(repositoryFile);
      }
    }

    // 生成Utils文件
    const utilsGenerator = code_gen.UtilsGenerator();
    final utilsFile = await utilsGenerator.generateFile(templatePath, config);
    files.add(utilsFile);

    // 生成Constants文件
    const constantsGenerator = code_gen.ConstantsGenerator();
    final constantsFile =
        await constantsGenerator.generateFile(templatePath, config);
    files.add(constantsFile);

    // 生成跨平台支持文件（所有复杂度都需要）
    const crossPlatformGenerator = code_gen.CrossPlatformGenerator();
    final crossPlatformFile =
        await crossPlatformGenerator.generateFile(templatePath, config);
    files.add(crossPlatformFile);

    // 生成平台常量文件
    const platformConstantsGenerator = code_gen.PlatformConstantsGenerator();
    final platformConstantsFile =
        await platformConstantsGenerator.generateFile(templatePath, config);
    files.add(platformConstantsFile);

    // 生成跨平台模块索引文件
    const crossPlatformIndexGenerator = code_gen.CrossPlatformIndexGenerator();
    final crossPlatformIndexFile =
        await crossPlatformIndexGenerator.generateFile(templatePath, config);
    files.add(crossPlatformIndexFile);

    // 生成Integration文件（仅enterprise复杂度）
    if (config.complexity == TemplateComplexity.enterprise) {
      const integrationGenerator = code_gen.IntegrationGenerator();
      final integrationFile =
          await integrationGenerator.generateFile(templatePath, config);
      files.add(integrationFile);
    }

    return files;
  }

  /// 生成增强的测试文件
  Future<List<String>> _generateEnhancedTestFiles(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // 根据模板类型和复杂度决定生成哪些测试
    final testTargets = <String>[]..add('Model'); // 所有模板都有Model

    // 根据模板类型添加特定的测试目标
    switch (config.templateType) {
      case TemplateType.ui:
        // UI模板：只有复杂度不是simple时才有Provider
        if (config.complexity != TemplateComplexity.simple) {
          testTargets.add('Provider');
        }
      // UI模板不生成Service测试
      case TemplateType.service:
        // Service模板：总是有Provider和Service
        testTargets.addAll(['Provider', 'Service']);
      case TemplateType.data:
        // Data模板：根据复杂度生成测试
        if (config.complexity != TemplateComplexity.simple) {
          testTargets.add('Provider');
          // Complex和Enterprise复杂度才有Service
          if (config.complexity != TemplateComplexity.medium) {
            testTargets.add('Service');
          }
        }
      case TemplateType.full:
        // Full模板：总是有Provider和Service
        testTargets.addAll(['Provider', 'Service']);
      case TemplateType.basic:
        // Basic模板：只生成基础测试，不生成Provider和Service测试
        break;
      case TemplateType.micro:
        // Micro模板：根据复杂度生成测试
        if (config.complexity != TemplateComplexity.simple) {
          testTargets.add('Provider');
          testTargets.add('Service');
          // Complex和Enterprise复杂度才有Repository（在下面统一处理）
        }
      case TemplateType.plugin:
        // Plugin模板：根据复杂度生成测试
        if (config.complexity != TemplateComplexity.simple) {
          testTargets.add('Provider');
          testTargets.add('Service');
          // Complex和Enterprise复杂度才有Repository（在下面统一处理）
        }
      case TemplateType.infrastructure:
        // Infrastructure模板：根据复杂度生成测试
        if (config.complexity != TemplateComplexity.simple) {
          testTargets.add('Provider');
          testTargets.add('Service');
          // Complex和Enterprise复杂度才有Repository（在下面统一处理）
        }
      case TemplateType.system:
        // System模板类型：根据复杂度决定
        if (config.complexity != TemplateComplexity.simple) {
          testTargets.addAll(['Provider', 'Service']);
        }
    }

    // 根据复杂度和模板类型添加Repository
    if (config.complexity != TemplateComplexity.simple &&
        config.templateType != TemplateType.basic) {
      // Micro、Plugin、Infrastructure和Full模板只在Complex和Enterprise复杂度时有Repository
      if (config.templateType == TemplateType.micro ||
          config.templateType == TemplateType.plugin ||
          config.templateType == TemplateType.infrastructure ||
          config.templateType == TemplateType.full) {
        if (config.complexity != TemplateComplexity.medium) {
          testTargets.add('Repository');
        }
      } else {
        testTargets.add('Repository');
      }
    }

    // 所有模板都有Utils和Constants
    testTargets.addAll(['Utils', 'Constants']);

    for (final target in testTargets) {
      final testGenerator = code_gen.EnhancedTestGenerator(
        testType: code_gen.TestType.unit,
        targetClassName: target,
      );
      final testFile = await testGenerator.generateFile(templatePath, config);
      files.add(testFile);
    }

    // 生成集成测试
    if (config.complexity == TemplateComplexity.enterprise) {
      const integrationTestGenerator = code_gen.EnhancedTestGenerator(
        testType: code_gen.TestType.integration,
        targetClassName: 'Integration',
      );
      final integrationFile =
          await integrationTestGenerator.generateFile(templatePath, config);
      files.add(integrationFile);
    }

    return files;
  }

  /// 检查是否应该生成UI组件
  bool _shouldGenerateUIComponents(TemplateType templateType) {
    // 只有UI模板和Full模板才生成UI组件
    return templateType == TemplateType.ui || templateType == TemplateType.full;
  }

  /// 生成UI组件文件
  Future<List<String>> _generateUiComponents(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // 生成页面组件
    const pageGenerator = code_gen.WidgetGenerator(
      widgetType: code_gen.WidgetType.page,
    );
    final pageFile = await pageGenerator.generateFile(templatePath, config);
    files.add(pageFile);

    // 生成可复用组件
    const componentGenerator = code_gen.WidgetGenerator(
      widgetType: code_gen.WidgetType.component,
    );
    final componentFile =
        await componentGenerator.generateFile(templatePath, config);
    files.add(componentFile);

    // 生成对话框组件
    if (config.complexity != TemplateComplexity.simple) {
      const dialogGenerator = code_gen.WidgetGenerator(
        widgetType: code_gen.WidgetType.dialog,
      );
      final dialogFile =
          await dialogGenerator.generateFile(templatePath, config);
      files.add(dialogFile);
    }

    return files;
  }

  /// 生成UI模板的代码文件
  Future<List<String>> _generateUICodeFiles(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // UI模板只生成UI相关的文件
    // 生成Model文件（UI组件可能需要数据模型）
    const modelGenerator = code_gen.ModelGenerator();
    final modelFile = await modelGenerator.generateFile(templatePath, config);
    files.add(modelFile);

    // 根据复杂度决定是否生成Provider
    if (config.complexity != TemplateComplexity.simple) {
      const providerGenerator = code_gen.ProviderGenerator();
      final providerFile =
          await providerGenerator.generateFile(templatePath, config);
      files.add(providerFile);

      // 生成Repository文件
      const repositoryGenerator = code_gen.RepositoryGenerator();
      final repositoryFile =
          await repositoryGenerator.generateFile(templatePath, config);
      files.add(repositoryFile);
    }

    // 生成Utils文件
    const utilsGenerator = code_gen.UtilsGenerator();
    final utilsFile = await utilsGenerator.generateFile(templatePath, config);
    files.add(utilsFile);

    // 生成Constants文件
    const constantsGenerator = code_gen.ConstantsGenerator();
    final constantsFile =
        await constantsGenerator.generateFile(templatePath, config);
    files.add(constantsFile);

    // 生成Integration文件（仅enterprise复杂度）
    if (config.complexity == TemplateComplexity.enterprise) {
      const integrationGenerator = code_gen.IntegrationGenerator();
      final integrationFile =
          await integrationGenerator.generateFile(templatePath, config);
      files.add(integrationFile);
    }

    return files;
  }

  /// 生成Service模板的代码文件
  Future<List<String>> _generateServiceCodeFiles(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // Service模板生成服务相关文件
    const serviceGenerator = code_gen.ServiceGenerator();
    final serviceFile =
        await serviceGenerator.generateFile(templatePath, config);
    files.add(serviceFile);

    const modelGenerator = code_gen.ModelGenerator();
    final modelFile = await modelGenerator.generateFile(templatePath, config);
    files.add(modelFile);

    const providerGenerator = code_gen.ProviderGenerator();
    final providerFile =
        await providerGenerator.generateFile(templatePath, config);
    files.add(providerFile);

    // 生成Utils文件
    const utilsGenerator = code_gen.UtilsGenerator();
    final utilsFile = await utilsGenerator.generateFile(templatePath, config);
    files.add(utilsFile);

    // 生成Constants文件
    const constantsGenerator = code_gen.ConstantsGenerator();
    final constantsFile =
        await constantsGenerator.generateFile(templatePath, config);
    files.add(constantsFile);

    // 根据复杂度生成Repository文件
    if (config.complexity != TemplateComplexity.simple) {
      const repositoryGenerator = code_gen.RepositoryGenerator();
      final repositoryFile =
          await repositoryGenerator.generateFile(templatePath, config);
      files.add(repositoryFile);
    }

    // 生成Integration文件（仅enterprise复杂度）
    if (config.complexity == TemplateComplexity.enterprise) {
      const integrationGenerator = code_gen.IntegrationGenerator();
      final integrationFile =
          await integrationGenerator.generateFile(templatePath, config);
      files.add(integrationFile);
    }

    return files;
  }

  /// 生成Data模板的代码文件
  Future<List<String>> _generateDataCodeFiles(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // Data模板主要生成数据相关文件
    const modelGenerator = code_gen.ModelGenerator();
    final modelFile = await modelGenerator.generateFile(templatePath, config);
    files.add(modelFile);

    // 根据复杂度生成Provider文件（Medium及以上）
    if (config.complexity != TemplateComplexity.simple) {
      const providerGenerator = code_gen.ProviderGenerator();
      final providerFile =
          await providerGenerator.generateFile(templatePath, config);
      files.add(providerFile);

      // 生成Repository文件
      const repositoryGenerator = code_gen.RepositoryGenerator();
      final repositoryFile =
          await repositoryGenerator.generateFile(templatePath, config);
      files.add(repositoryFile);

      // 生成Service文件（Complex及以上）
      if (config.complexity != TemplateComplexity.medium) {
        const serviceGenerator = code_gen.ServiceGenerator();
        final serviceFile =
            await serviceGenerator.generateFile(templatePath, config);
        files.add(serviceFile);
      }
    }

    // 生成Utils文件
    const utilsGenerator = code_gen.UtilsGenerator();
    final utilsFile = await utilsGenerator.generateFile(templatePath, config);
    files.add(utilsFile);

    // 生成Constants文件
    const constantsGenerator = code_gen.ConstantsGenerator();
    final constantsFile =
        await constantsGenerator.generateFile(templatePath, config);
    files.add(constantsFile);

    // 生成Integration文件（仅enterprise复杂度）
    if (config.complexity == TemplateComplexity.enterprise) {
      const integrationGenerator = code_gen.IntegrationGenerator();
      final integrationFile =
          await integrationGenerator.generateFile(templatePath, config);
      files.add(integrationFile);
    }

    return files;
  }

  /// 生成Full模板的代码文件
  Future<List<String>> _generateFullCodeFiles(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // Full模板生成所有类型的文件
    const providerGenerator = code_gen.ProviderGenerator();
    final providerFile =
        await providerGenerator.generateFile(templatePath, config);
    files.add(providerFile);

    const serviceGenerator = code_gen.ServiceGenerator();
    final serviceFile =
        await serviceGenerator.generateFile(templatePath, config);
    files.add(serviceFile);

    const modelGenerator = code_gen.ModelGenerator();
    final modelFile = await modelGenerator.generateFile(templatePath, config);
    files.add(modelFile);

    // 根据复杂度生成Repository文件（Complex及以上）
    if (config.complexity != TemplateComplexity.simple &&
        config.complexity != TemplateComplexity.medium) {
      const repositoryGenerator = code_gen.RepositoryGenerator();
      final repositoryFile =
          await repositoryGenerator.generateFile(templatePath, config);
      files.add(repositoryFile);
    }

    // 生成Utils文件
    const utilsGenerator = code_gen.UtilsGenerator();
    final utilsFile = await utilsGenerator.generateFile(templatePath, config);
    files.add(utilsFile);

    // 生成Constants文件
    const constantsGenerator = code_gen.ConstantsGenerator();
    final constantsFile =
        await constantsGenerator.generateFile(templatePath, config);
    files.add(constantsFile);

    // 生成Integration文件（仅enterprise复杂度）
    if (config.complexity == TemplateComplexity.enterprise) {
      const integrationGenerator = code_gen.IntegrationGenerator();
      final integrationFile =
          await integrationGenerator.generateFile(templatePath, config);
      files.add(integrationFile);
    }

    return files;
  }

  /// 生成System模板的代码文件
  Future<List<String>> _generateSystemCodeFiles(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // System模板生成系统相关文件
    const modelGenerator = code_gen.ModelGenerator();
    final modelFile = await modelGenerator.generateFile(templatePath, config);
    files.add(modelFile);

    // 生成Utils文件
    const utilsGenerator = code_gen.UtilsGenerator();
    final utilsFile = await utilsGenerator.generateFile(templatePath, config);
    files.add(utilsFile);

    // 生成Constants文件
    const constantsGenerator = code_gen.ConstantsGenerator();
    final constantsFile =
        await constantsGenerator.generateFile(templatePath, config);
    files.add(constantsFile);

    // 根据复杂度生成额外文件
    if (config.complexity != TemplateComplexity.simple) {
      const providerGenerator = code_gen.ProviderGenerator();
      final providerFile =
          await providerGenerator.generateFile(templatePath, config);
      files.add(providerFile);

      const repositoryGenerator = code_gen.RepositoryGenerator();
      final repositoryFile =
          await repositoryGenerator.generateFile(templatePath, config);
      files.add(repositoryFile);

      const serviceGenerator = code_gen.ServiceGenerator();
      final serviceFile =
          await serviceGenerator.generateFile(templatePath, config);
      files.add(serviceFile);
    }

    // 生成跨平台支持文件
    const crossPlatformGenerator = code_gen.CrossPlatformGenerator();
    final crossPlatformFile =
        await crossPlatformGenerator.generateFile(templatePath, config);
    files.add(crossPlatformFile);

    // 生成平台常量文件
    const platformConstantsGenerator = code_gen.PlatformConstantsGenerator();
    final platformConstantsFile =
        await platformConstantsGenerator.generateFile(templatePath, config);
    files.add(platformConstantsFile);

    // 生成跨平台模块索引文件
    const crossPlatformIndexGenerator = code_gen.CrossPlatformIndexGenerator();
    final crossPlatformIndexFile =
        await crossPlatformIndexGenerator.generateFile(templatePath, config);
    files.add(crossPlatformIndexFile);

    // 生成Integration文件（仅enterprise复杂度）
    if (config.complexity == TemplateComplexity.enterprise) {
      const integrationGenerator = code_gen.IntegrationGenerator();
      final integrationFile =
          await integrationGenerator.generateFile(templatePath, config);
      files.add(integrationFile);
    }

    return files;
  }

  /// 生成基础模板的代码文件
  Future<List<String>> _generateBasicCodeFiles(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // 基础模板只生成最基本的文件
    const modelGenerator = code_gen.ModelGenerator();
    final modelFile = await modelGenerator.generateFile(templatePath, config);
    files.add(modelFile);

    // 生成Utils文件
    const utilsGenerator = code_gen.UtilsGenerator();
    final utilsFile = await utilsGenerator.generateFile(templatePath, config);
    files.add(utilsFile);

    // 生成Constants文件
    const constantsGenerator = code_gen.ConstantsGenerator();
    final constantsFile =
        await constantsGenerator.generateFile(templatePath, config);
    files.add(constantsFile);

    // 生成Integration文件（仅enterprise复杂度）
    if (config.complexity == TemplateComplexity.enterprise) {
      const integrationGenerator = code_gen.IntegrationGenerator();
      final integrationFile =
          await integrationGenerator.generateFile(templatePath, config);
      files.add(integrationFile);
    }

    return files;
  }
}
