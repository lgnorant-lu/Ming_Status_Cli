/*
---------------------------------------------------------------
File name:          enterprise_template_creation_test.dart
Author:             lgnorant-lu
Date created:       2025/07/10
Last modified:      2025/07/10
Dart Version:       3.2+
Description:        企业级模板创建工具单元测试 (Enterprise Template Creation Unit Tests)
---------------------------------------------------------------
Change History:
    2025/07/10: Initial creation - Phase 2.3 企业级模板创建工具测试;
---------------------------------------------------------------
*/

import 'dart:io';

import 'package:ming_status_cli/src/core/creation/enterprise_template_creator.dart';
import 'package:ming_status_cli/src/core/creation/template_library_manager.dart';
import 'package:ming_status_cli/src/core/parameters/enterprise_template_parameter.dart';
import 'package:test/test.dart';

void main() {
  group('Enterprise Template Creator Tests', () {
    late EnterpriseTemplateCreator creator;
    late Directory tempDir;

    setUp(() async {
      creator = EnterpriseTemplateCreator();
      tempDir = await Directory.systemTemp.createTemp('template_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('TemplateCreationConfig should be created correctly', () {
      const config = TemplateCreationConfig(
        mode: TemplateCreationMode.fromScratch,
        minConfidence: 0.8,
        excludePatterns: ['.git/', 'build/'],
        includePatterns: ['src/', 'lib/'],
      );

      expect(config.mode, equals(TemplateCreationMode.fromScratch));
      expect(config.enableCodeAnalysis, isTrue);
      expect(config.enableParameterization, isTrue);
      expect(config.enableBestPractices, isTrue);
      expect(config.minConfidence, equals(0.8));
      expect(config.excludePatterns, hasLength(2));
      expect(config.includePatterns, hasLength(2));
    });

    test('ParameterizationSuggestion should be created correctly', () {
      final suggestion = ParameterizationSuggestion(
        filePath: 'lib/main.dart',
        lineNumber: 10,
        originalValue: 'MyApp',
        suggestedParameter: EnterpriseTemplateParameter(
          name: 'app_name',
          enterpriseType: EnterpriseParameterType.string,
          description: '应用名称',
          defaultValue: 'MyApp',
        ),
        confidence: 0.9,
        reason: '应用名称应该参数化',
        context: 'class MyApp extends StatelessWidget',
        alternatives: [],
      );

      expect(suggestion.filePath, equals('lib/main.dart'));
      expect(suggestion.lineNumber, equals(10));
      expect(suggestion.originalValue, equals('MyApp'));
      expect(suggestion.suggestedParameter.name, equals('app_name'));
      expect(suggestion.confidence, equals(0.9));
      expect(suggestion.reason, equals('应用名称应该参数化'));
      expect(suggestion.context, equals('class MyApp extends StatelessWidget'));
    });

    test('EnterpriseTemplateCreator should create template from scratch',
        () async {
      const config = TemplateCreationConfig(
        mode: TemplateCreationMode.fromScratch,
      );

      final result = await creator.createTemplate(
        templateName: 'test_template',
        config: config,
      );

      expect(result.success, isTrue);
      expect(result.templatePath, isNotEmpty);
      expect(result.metadata, isNotNull);
      expect(result.metadata!.name, equals('test_template'));
      expect(result.metadata!.version, equals('1.0.0'));
      expect(result.errors, isEmpty);
    });

    test('EnterpriseTemplateCreator should create template from project',
        () async {
      // 创建测试项目结构
      final projectDir = Directory('${tempDir.path}/test_project');
      await projectDir.create(recursive: true);

      // 创建pubspec.yaml
      final pubspecFile = File('${projectDir.path}/pubspec.yaml');
      await pubspecFile.writeAsString('''
name: test_project
description: A test Flutter project.
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  http: ^0.13.0
''');

      // 创建main.dart
      final mainFile = File('${projectDir.path}/lib/main.dart');
      await mainFile.parent.create(recursive: true);
      await mainFile.writeAsString('''
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test App',
      home: Scaffold(
        appBar: AppBar(title: Text('Test App')),
        body: Center(child: Text('Hello World')),
      ),
    );
  }
}
''');

      final config = TemplateCreationConfig(
        mode: TemplateCreationMode.fromProject,
        sourcePath: projectDir.path,
        outputPath: '${tempDir.path}/output_template',
      );

      final result = await creator.createTemplate(
        templateName: 'project_template',
        config: config,
      );

      expect(result.success, isTrue);
      expect(result.templatePath, equals('${tempDir.path}/output_template'));
      expect(result.metadata, isNotNull);
      expect(result.suggestions, isNotEmpty);

      // 检查是否有应用名称的参数化建议
      final appNameSuggestions = result.suggestions
          .where((s) =>
              s.originalValue.contains('Test App') ||
              s.originalValue.contains('test_project'),)
          .toList();
      expect(appNameSuggestions, isNotEmpty);
    });

    test('EnterpriseTemplateCreator should analyze project correctly',
        () async {
      // 创建测试项目
      final projectDir = Directory('${tempDir.path}/analyze_project');
      await projectDir.create(recursive: true);

      // 创建配置文件
      final configFile = File('${projectDir.path}/config.yaml');
      await configFile.writeAsString('''
app_name: TestApp
version: 1.0.0
database_host: localhost
database_port: 5432
''');

      // 创建JSON配置
      final jsonFile = File('${projectDir.path}/settings.json');
      await jsonFile.writeAsString('''
{
  "api_url": "https://api.example.com",
  "timeout": 30,
  "debug": true
}
''');

      final suggestions = await creator.analyzeProject(
        projectDir.path,
        analysisTypes: {
          CodeAnalysisType.structural,
          CodeAnalysisType.syntactic,
          CodeAnalysisType.dependency,
        },
        minConfidence: 0.5,
      );

      expect(suggestions, isNotEmpty);

      // 检查是否检测到配置值
      final configSuggestions = suggestions
          .where((s) =>
              s.filePath.contains('config.yaml') ||
              s.filePath.contains('settings.json'),)
          .toList();
      expect(configSuggestions, isNotEmpty);
    });

    test('EnterpriseTemplateCreator should handle invalid config', () async {
      const config = TemplateCreationConfig(
        mode: TemplateCreationMode.fromProject,
        sourcePath: '/nonexistent/path',
      );

      final result = await creator.createTemplate(
        templateName: 'invalid_template',
        config: config,
      );

      expect(result.success, isFalse);
      expect(result.errors, isNotEmpty);
      expect(result.errors.first, contains('源项目路径不存在'));
    });

    test('EnterpriseTemplateCreator should merge custom metadata', () async {
      const config = TemplateCreationConfig(
        mode: TemplateCreationMode.fromScratch,
      );

      final customMetadata = {
        'author': 'Custom Author',
        'description': 'Custom Description',
        'tags': ['custom', 'test'],
        'custom_field': 'custom_value',
      };

      final result = await creator.createTemplate(
        templateName: 'custom_template',
        config: config,
        customMetadata: customMetadata,
      );

      expect(result.success, isTrue);
      expect(result.metadata!.author, equals('Custom Author'));
      expect(result.metadata!.description, equals('Custom Description'));
      expect(result.metadata!.tags, contains('custom'));
      expect(result.metadata!.metadata['custom_field'], equals('custom_value'));
    });
  });

  group('Template Library Manager Tests', () {
    late TemplateLibraryManager manager;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('library_test_');
      manager = TemplateLibraryManager(libraryPath: tempDir.path);
      await manager.initialize();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('TemplateLibraryEntry should be created correctly', () {
      final entry = TemplateLibraryEntry(
        id: 'test_template',
        name: 'Test Template',
        sourceType: TemplateSourceType.local,
        sourceUrl: '/path/to/template',
        description: 'A test template',
        author: 'Test Author',
        category: 'test',
        tags: ['test', 'example'],
        versions: [
          TemplateVersion(
            version: '1.0.0',
            releaseDate: DateTime.now(),
            changelog: 'Initial release',
          ),
        ],
        currentVersion: '1.0.0',
        downloadCount: 100,
        rating: 4.5,
        lastUpdated: DateTime.now(),
      );

      expect(entry.id, equals('test_template'));
      expect(entry.name, equals('Test Template'));
      expect(entry.sourceType, equals(TemplateSourceType.local));
      expect(entry.description, equals('A test template'));
      expect(entry.author, equals('Test Author'));
      expect(entry.category, equals('test'));
      expect(entry.tags, hasLength(2));
      expect(entry.versions, hasLength(1));
      expect(entry.downloadCount, equals(100));
      expect(entry.rating, equals(4.5));
      expect(entry.latestVersion, isNotNull);
      expect(entry.latestVersion!.version, equals('1.0.0'));
    });

    test('TemplateLibraryManager should add and retrieve templates', () async {
      final template = TemplateLibraryEntry(
        id: 'flutter_app',
        name: 'Flutter App Template',
        sourceType: TemplateSourceType.local,
        sourceUrl: '/templates/flutter_app',
        description: 'Basic Flutter application template',
        author: 'Flutter Team',
        category: 'mobile',
        tags: ['flutter', 'mobile', 'app'],
        versions: [
          TemplateVersion(
            version: '1.0.0',
            releaseDate: DateTime.now(),
          ),
        ],
        rating: 4.8,
      );

      final addResult = await manager.addTemplate(template);
      expect(addResult, isTrue);

      final retrievedTemplate = await manager.getTemplate('flutter_app');
      expect(retrievedTemplate, isNotNull);
      expect(retrievedTemplate!.name, equals('Flutter App Template'));
      expect(retrievedTemplate.category, equals('mobile'));
      expect(retrievedTemplate.tags, contains('flutter'));
    });

    test('TemplateLibraryManager should search templates correctly', () async {
      // 添加多个模板
      final templates = [
        TemplateLibraryEntry(
          id: 'flutter_mobile',
          name: 'Flutter Mobile App',
          sourceType: TemplateSourceType.local,
          sourceUrl: '/templates/flutter_mobile',
          category: 'mobile',
          tags: ['flutter', 'mobile'],
          rating: 4.5,
          downloadCount: 1000,
          versions: [
            TemplateVersion(version: '1.0.0', releaseDate: DateTime.now()),
          ],
        ),
        TemplateLibraryEntry(
          id: 'react_web',
          name: 'React Web App',
          sourceType: TemplateSourceType.git,
          sourceUrl: 'https://github.com/example/react-template',
          category: 'web',
          tags: ['react', 'web'],
          rating: 4.2,
          downloadCount: 800,
          versions: [
            TemplateVersion(version: '2.0.0', releaseDate: DateTime.now()),
          ],
        ),
        TemplateLibraryEntry(
          id: 'vue_spa',
          name: 'Vue SPA Template',
          sourceType: TemplateSourceType.local,
          sourceUrl: '/templates/vue_spa',
          category: 'web',
          tags: ['vue', 'spa', 'web'],
          rating: 4,
          downloadCount: 600,
          versions: [
            TemplateVersion(version: '1.5.0', releaseDate: DateTime.now()),
          ],
        ),
      ];

      for (final template in templates) {
        await manager.addTemplate(template);
      }

      // 搜索所有模板
      final allTemplates = await manager.searchTemplates(
        const TemplateLibraryQuery(),
      );
      expect(allTemplates, hasLength(3));

      // 按分类搜索
      final mobileTemplates = await manager.searchTemplates(
        const TemplateLibraryQuery(category: 'mobile'),
      );
      expect(mobileTemplates, hasLength(1));
      expect(mobileTemplates.first.name, equals('Flutter Mobile App'));

      // 按标签搜索
      final webTemplates = await manager.searchTemplates(
        const TemplateLibraryQuery(tags: ['web']),
      );
      expect(webTemplates, hasLength(2));

      // 按名称模式搜索
      final reactTemplates = await manager.searchTemplates(
        const TemplateLibraryQuery(namePattern: 'react'),
      );
      expect(reactTemplates, hasLength(1));
      expect(reactTemplates.first.name, equals('React Web App'));

      // 按评分过滤
      final highRatedTemplates = await manager.searchTemplates(
        const TemplateLibraryQuery(minRating: 4.3),
      );
      expect(highRatedTemplates, hasLength(1));
      expect(highRatedTemplates.first.rating, greaterThanOrEqualTo(4.3));

      // 按下载次数排序
      final popularTemplates = await manager.searchTemplates(
        const TemplateLibraryQuery(
          sortBy: TemplateSortBy.downloadCount,
        ),
      );
      expect(popularTemplates.first.downloadCount, equals(1000));
      expect(popularTemplates.last.downloadCount, equals(600));
    });

    test('TemplateLibraryManager should handle template removal', () async {
      final template = TemplateLibraryEntry(
        id: 'temp_template',
        name: 'Temporary Template',
        sourceType: TemplateSourceType.local,
        sourceUrl: '/templates/temp',
        versions: [
          TemplateVersion(version: '1.0.0', releaseDate: DateTime.now()),
        ],
      );

      await manager.addTemplate(template);

      final beforeRemoval = await manager.getTemplate('temp_template');
      expect(beforeRemoval, isNotNull);

      final removeResult = await manager.removeTemplate('temp_template');
      expect(removeResult, isTrue);

      final afterRemoval = await manager.getTemplate('temp_template');
      expect(afterRemoval, isNull);
    });

    test('TemplateLibraryManager should download local template', () async {
      // 创建源模板目录
      final sourceDir = Directory('${tempDir.path}/source_template');
      await sourceDir.create(recursive: true);

      final sourceFile = File('${sourceDir.path}/template.yaml');
      await sourceFile.writeAsString('''
name: test_template
version: 1.0.0
description: Test template
''');

      final template = TemplateLibraryEntry(
        id: 'download_test',
        name: 'Download Test Template',
        sourceType: TemplateSourceType.local,
        sourceUrl: sourceDir.path,
        versions: [
          TemplateVersion(
            version: '1.0.0',
            releaseDate: DateTime.now(),
          ),
        ],
      );

      await manager.addTemplate(template);

      final downloadResult = await manager.downloadTemplate(
        templateId: 'download_test',
        version: '1.0.0',
        targetPath: '${tempDir.path}/downloaded_template',
      );

      expect(downloadResult.success, isTrue);
      expect(downloadResult.localPath,
          equals('${tempDir.path}/downloaded_template'),);
      expect(downloadResult.version, equals('1.0.0'));

      // 验证文件是否被复制
      final downloadedFile =
          File('${tempDir.path}/downloaded_template/template.yaml');
      expect(await downloadedFile.exists(), isTrue);
    });

    test('TemplateLibraryManager should handle download errors', () async {
      final template = TemplateLibraryEntry(
        id: 'error_template',
        name: 'Error Template',
        sourceType: TemplateSourceType.local,
        sourceUrl: '/nonexistent/path',
        versions: [
          TemplateVersion(
            version: '1.0.0',
            releaseDate: DateTime.now(),
          ),
        ],
      );

      await manager.addTemplate(template);

      final downloadResult = await manager.downloadTemplate(
        templateId: 'error_template',
        version: '1.0.0',
      );

      expect(downloadResult.success, isFalse);
      expect(downloadResult.error, isNotNull);
      expect(downloadResult.error, contains('源目录不存在'));
    });

    test('TemplateLibraryManager should handle version queries', () async {
      final template = TemplateLibraryEntry(
        id: 'versioned_template',
        name: 'Versioned Template',
        sourceType: TemplateSourceType.local,
        sourceUrl: '/templates/versioned',
        versions: [
          TemplateVersion(
            version: '1.0.0',
            releaseDate: DateTime(2023),
          ),
          TemplateVersion(
            version: '1.1.0',
            releaseDate: DateTime(2023, 6),
          ),
          TemplateVersion(
            version: '2.0.0-beta',
            releaseDate: DateTime(2023, 12),
            isStable: false,
          ),
        ],
      );

      await manager.addTemplate(template);

      final retrievedTemplate = await manager.getTemplate('versioned_template');
      expect(retrievedTemplate, isNotNull);

      // 测试最新版本获取
      final latestVersion = retrievedTemplate!.latestVersion;
      expect(latestVersion, isNotNull);
      expect(latestVersion!.version, equals('1.1.0')); // 最新稳定版本

      // 测试特定版本获取
      final specificVersion = retrievedTemplate.getVersion('2.0.0-beta');
      expect(specificVersion, isNotNull);
      expect(specificVersion!.version, equals('2.0.0-beta'));
      expect(specificVersion.isStable, isFalse);
    });
  });
}
