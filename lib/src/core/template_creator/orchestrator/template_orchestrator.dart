/*
---------------------------------------------------------------
File name:          template_orchestrator.dart
Author:             lgnorant-lu
Date created:       2025/07/12
Last modified:      2025/07/12
Dart Version:       3.2+
Description:        模板生成编排器 (Template Generation Orchestrator)
---------------------------------------------------------------
Change History:
    2025/07/12: Initial creation - 模块化重构主控制器;
---------------------------------------------------------------
TODO:
    - [ ] 添加并行生成支持
    - [ ] 支持生成进度回调
    - [ ] 添加生成策略模式
---------------------------------------------------------------
*/

import 'dart:io';
import 'package:ming_status_cli/src/core/template_creator/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/assets/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/code/index.dart'
    as code_gen;
import 'package:ming_status_cli/src/core/template_creator/generators/config/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/docs/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/flutter/index.dart'
    as flutter_gen;
import 'package:ming_status_cli/src/core/template_creator/generators/l10n/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/templates/index.dart';
import 'package:ming_status_cli/src/core/template_creator/generators/tests/index.dart';
import 'package:ming_status_cli/src/core/template_creator/structure/index.dart';
import 'package:ming_status_cli/src/core/template_system/template_metadata.dart';
import 'package:ming_status_cli/src/core/template_system/template_types.dart';
import 'package:ming_status_cli/src/utils/logger.dart' as cli_logger;
import 'package:path/path.dart' as path;

/// 模板生成编排器
///
/// 负责协调各个生成器模块，按照正确的顺序生成模板
class TemplateOrchestrator {
  /// 创建模板编排器实例
  const TemplateOrchestrator();

  /// 生成完整的模板项目
  ///
  /// [config] 脚手架配置
  /// 返回生成结果
  Future<ScaffoldResult> generateTemplate(ScaffoldConfig config) async {
    try {
      cli_logger.Logger.info('🚀 开始生成模板: ${config.templateName}');

      final generatedFiles = <String>[];
      final warnings = <String>[];

      // 1. 创建目录结构
      final templatePath = await _createDirectoryStructure(config);
      cli_logger.Logger.info('📁 目录结构创建完成');

      // 2. 生成配置文件
      final configFiles = await _generateConfigFiles(templatePath, config);
      generatedFiles.addAll(configFiles);
      cli_logger.Logger.info('⚙️ 配置文件生成完成 (${configFiles.length}个文件)');

      // 3. 生成模板文件
      final templateFiles = await _generateTemplateFiles(templatePath, config);
      generatedFiles.addAll(templateFiles);
      cli_logger.Logger.info('📄 模板文件生成完成 (${templateFiles.length}个文件)');

      // 4. 生成实际代码文件
      final codeFiles = await _generateCodeFiles(templatePath, config);
      generatedFiles.addAll(codeFiles);
      cli_logger.Logger.info('💻 代码文件生成完成 (${codeFiles.length}个文件)');

      // 5. 生成框架特定文件
      if (config.framework == TemplateFramework.flutter) {
        final flutterFiles = await _generateFlutterFiles(templatePath, config);
        generatedFiles.addAll(flutterFiles);
        cli_logger.Logger.info('🎯 Flutter文件生成完成 (${flutterFiles.length}个文件)');
      }

      // 5. 生成国际化文件
      final l10nFiles = await _generateL10nFiles(templatePath, config);
      generatedFiles.addAll(l10nFiles);
      cli_logger.Logger.info('🌍 国际化文件生成完成 (${l10nFiles.length}个文件)');

      // 6. 生成资源文件
      final assetFiles = await _generateAssetFiles(templatePath, config);
      generatedFiles.addAll(assetFiles);
      cli_logger.Logger.info('🎨 资源文件生成完成 (${assetFiles.length}个文件)');

      // 7. 生成文档
      if (config.includeDocumentation) {
        final docFiles =
            await _generateDocumentationFiles(templatePath, config);
        generatedFiles.addAll(docFiles);
        cli_logger.Logger.info('📚 文档文件生成完成 (${docFiles.length}个文件)');
      }

      // 8. 生成测试文件
      if (config.includeTests) {
        final testFiles = await _generateTestFiles(templatePath, config);
        generatedFiles.addAll(testFiles);
        cli_logger.Logger.info('🧪 测试文件生成完成 (${testFiles.length}个文件)');
      }

      // 9. 生成元数据文件
      await _generateMetadataFile(templatePath, config);
      generatedFiles.add('template.yaml');
      cli_logger.Logger.info('📋 元数据文件生成完成');

      // 10. 初始化Git仓库
      if (config.enableGitInit) {
        await _initializeGitRepository(templatePath);
        cli_logger.Logger.info('📦 Git仓库初始化完成');
      }

      cli_logger.Logger.success('✅ 模板生成完成! 总计生成 ${generatedFiles.length} 个文件');

      return ScaffoldResult.success(
        templatePath: templatePath,
        generatedFiles: generatedFiles,
        warnings: warnings,
      );
    } catch (e, stackTrace) {
      cli_logger.Logger.error('❌ 模板生成失败: $e');
      cli_logger.Logger.debug('堆栈跟踪: $stackTrace');

      return ScaffoldResult.failure(
        errors: ['模板生成失败: $e'],
      );
    }
  }

  /// 创建目录结构
  Future<String> _createDirectoryStructure(ScaffoldConfig config) async {
    final creator = _getStructureCreator(config);
    final templatePath = path.join(config.outputPath, config.templateName);
    await creator.createDirectories(templatePath, config);
    return templatePath;
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
  Future<List<String>> _generateConfigFiles(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // 基础配置文件
    const pubspecGenerator = PubspecGenerator();
    await pubspecGenerator.generateFile(templatePath, config);
    files.add('pubspec.yaml');

    const gitignoreGenerator = GitignoreGenerator();
    await gitignoreGenerator.generateFile(templatePath, config);
    files.add('.gitignore');

    const analysisOptionsGenerator = AnalysisOptionsGenerator();
    await analysisOptionsGenerator.generateFile(templatePath, config);
    files.add('analysis_options.yaml');

    // Flutter特定配置文件
    if (config.framework == TemplateFramework.flutter) {
      const l10nConfigGenerator = L10nConfigGenerator();
      await l10nConfigGenerator.generateFile(templatePath, config);
      files.add('l10n.yaml');

      // 根据复杂度添加更多配置文件
      if (config.complexity == TemplateComplexity.medium ||
          config.complexity == TemplateComplexity.complex ||
          config.complexity == TemplateComplexity.enterprise) {
        const buildConfigGenerator = BuildConfigGenerator();
        await buildConfigGenerator.generateFile(templatePath, config);
        files.add('build.yaml');

        const flutterGenConfigGenerator = FlutterGenConfigGenerator();
        await flutterGenConfigGenerator.generateFile(templatePath, config);
        files.add('flutter_gen.yaml');
      }

      // 企业级配置文件
      if (config.complexity == TemplateComplexity.enterprise) {
        const melosConfigGenerator = MelosConfigGenerator();
        await melosConfigGenerator.generateFile(templatePath, config);
        files.add('melos.yaml');

        const shorebirdConfigGenerator = ShorebirdConfigGenerator();
        await shorebirdConfigGenerator.generateFile(templatePath, config);
        files.add('shorebird.yaml');
      }
    }

    return files;
  }

  /// 生成模板文件
  Future<List<String>> _generateTemplateFiles(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // 生成main.dart模板
    const mainGenerator = MainDartGenerator();
    await mainGenerator.generateFile(templatePath, config);
    files.add('templates/main.dart.template');

    // 生成app.dart模板（仅Flutter）
    if (config.framework == TemplateFramework.flutter) {
      const appGenerator = AppDartGenerator();
      await appGenerator.generateFile(templatePath, config);
      files.add('templates/app.dart.template');
    }

    // 生成模块定义文件
    const moduleGenerator = ModuleDartGenerator();
    await moduleGenerator.generateFile(templatePath, config);
    files.add('templates/${moduleGenerator.getOutputFileName(config)}');

    // 生成主导出文件
    const exportGenerator = MainExportGenerator();
    await exportGenerator.generateFile(templatePath, config);
    files.add('templates/${exportGenerator.getOutputFileName(config)}');

    return files;
  }

  /// 生成实际代码文件
  Future<List<String>> _generateCodeFiles(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // 生成Provider文件
    const providerGenerator = code_gen.ProviderGenerator();
    final providerFile =
        await providerGenerator.generateFile(templatePath, config);
    files.add(providerFile);

    // 生成Service文件
    const serviceGenerator = code_gen.ServiceGenerator();
    final serviceFile =
        await serviceGenerator.generateFile(templatePath, config);
    files.add(serviceFile);

    // 生成Model文件
    const modelGenerator = code_gen.ModelGenerator();
    final modelFile = await modelGenerator.generateFile(templatePath, config);
    files.add(modelFile);

    return files;
  }

  /// 生成Flutter特定文件
  Future<List<String>> _generateFlutterFiles(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // 生成主题文件
    const themeGenerator = flutter_gen.ThemeGenerator();
    await themeGenerator.generateFile(templatePath, config);
    files.add('templates/app_theme.dart.template');

    // 生成路由文件
    const routerGenerator = flutter_gen.RouterGenerator();
    await routerGenerator.generateFile(templatePath, config);
    files.add('templates/app_router.dart.template');

    // 根据复杂度生成Provider文件
    if (config.complexity == TemplateComplexity.medium ||
        config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      const providerGenerator = flutter_gen.ProviderGenerator();
      await providerGenerator.generateFile(templatePath, config);
      files.add('templates/app_providers.dart.template');
    }

    return files;
  }

  /// 生成国际化文件
  Future<List<String>> _generateL10nFiles(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // 支持的语言列表
    final languages = _getSupportedLanguages(config);

    for (final language in languages) {
      final parts = language.split('_');
      final languageCode = parts[0];
      final countryCode = parts.length > 1 ? parts[1] : null;

      final arbGenerator = ArbGenerator(
        languageCode: languageCode,
        countryCode: countryCode,
      );

      await arbGenerator.generateFile(templatePath, config);
      files.add('templates/app_$language.arb.template');
    }

    return files;
  }

  /// 生成资源文件
  Future<List<String>> _generateAssetFiles(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // 生成各种资源文件
    final assetTypes = [
      AssetType.images,
      AssetType.icons,
    ];

    // 根据复杂度添加额外的资源类型
    if (config.complexity != TemplateComplexity.simple) {
      assetTypes.addAll([
        AssetType.fonts,
        AssetType.colors,
      ]);
    }

    if (config.complexity == TemplateComplexity.complex ||
        config.complexity == TemplateComplexity.enterprise) {
      assetTypes.add(AssetType.animations);
    }

    for (final assetType in assetTypes) {
      final assetGenerator = AssetGenerator(assetType: assetType);
      await assetGenerator.generateFile(templatePath, config);
      files.add('templates/${assetType.name}_assets.template');
    }

    return files;
  }

  /// 生成文档文件
  Future<List<String>> _generateDocumentationFiles(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // 生成README文件
    const readmeGenerator = ReadmeGenerator();
    await readmeGenerator.generateFile(templatePath, config);
    files.add('templates/README.md.template');

    return files;
  }

  /// 生成测试文件
  Future<List<String>> _generateTestFiles(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final files = <String>[];

    // 基础测试类型
    final testTypes = [TestType.unit];

    // Flutter特定测试
    if (config.framework == TemplateFramework.flutter) {
      testTypes.addAll([TestType.widget, TestType.integration]);

      // 企业级测试
      if (config.complexity == TemplateComplexity.enterprise) {
        testTypes.addAll([TestType.golden, TestType.performance]);
      }
    }

    for (final testType in testTypes) {
      final testGenerator = TestGenerator(testType: testType);
      await testGenerator.generateFile(templatePath, config);
      files.add('templates/${testType.name}_test.dart.template');
    }

    return files;
  }

  /// 生成元数据文件
  Future<void> _generateMetadataFile(
    String templatePath,
    ScaffoldConfig config,
  ) async {
    final metadataPath = path.join(templatePath, 'template.yaml');
    final metadata = _createTemplateMetadata(config);
    final yamlContent = _generateMetadataYaml(metadata);
    await File(metadataPath).writeAsString(yamlContent);
  }

  /// 创建模板元数据
  TemplateMetadata _createTemplateMetadata(ScaffoldConfig config) {
    return TemplateMetadata(
      id: _generateTemplateId(config.templateName),
      name: config.templateName,
      type: config.templateType,
      subType: config.subType,
      author: config.author,
      description: config.description,
      version: config.version,
      platform: config.platform,
      framework: config.framework,
      complexity: config.complexity,
      maturity: config.maturity,
      tags: config.tags,
      keywords: _generateKeywords(config),
      dependencies: config.dependencies
          .map((dep) => TemplateDependency(name: dep, version: '^1.0.0'))
          .toList(),
      category: _generateCategory(config),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
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

  /// 初始化Git仓库
  Future<void> _initializeGitRepository(String templatePath) async {
    final result = await Process.run(
      'git',
      ['init'],
      workingDirectory: templatePath,
    );

    if (result.exitCode != 0) {
      cli_logger.Logger.warning('Git初始化失败: ${result.stderr}');
    }
  }

  /// 获取支持的语言列表
  List<String> _getSupportedLanguages(ScaffoldConfig config) {
    switch (config.complexity) {
      case TemplateComplexity.simple:
        return ['en', 'zh'];
      case TemplateComplexity.medium:
        return ['en', 'zh', 'ja', 'ko'];
      case TemplateComplexity.complex:
      case TemplateComplexity.enterprise:
        return ['en', 'zh', 'ja', 'ko', 'es', 'fr', 'de', 'ru'];
    }
  }
}
